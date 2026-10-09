-- Store : etat client (snapshot serveur + vague du joueur) et appels reseau (contrat des remotes v2 de A,
-- review/review_context.md). Seul module qui touche ReplicatedStorage.Remotes. Les ecrans lisent
-- Store.Get() / Store.GetWave() et ecoutent les signaux. Studio sans serveur : mode demo (etat simule).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Store = {}

local INVOKE_TIMEOUT = 8 -- secondes avant d'abandonner un appel serveur
local GETSTATE_TIMEOUT = 4 -- premier contact : court, pour basculer vite en demo dans Studio
local GETSTATE_ATTEMPTS = 5
local ATTRIBUTE_SETTLE = 0.15 -- delai avant de relire les attributs de vague
local PHASES = { calm = true, warning = true, wave = true, recede = true }
local INTRO_STEPS = { intro = true, golden = true, done = true }
local STAGE_IDS = { "Baby", "Juvenile", "Adult", "Giant" }
-- Croissance du GDD §4.3 (minutes cumulees vers Juvenile, Adult, Giant), tant que Config.GrowthMinutes manque
local GROWTH_FALLBACK = {
	Common = { 3, 15, 60 },
	Uncommon = { 5, 30, 120 },
	Rare = { 10, 60, 240 },
	Epic = { 20, 120, 480 },
	Legendary = { 30, 240, 1200 },
}
-- RemoteEvents en plus des trois de base (contrat v2.1)
local OPTIONAL_EVENTS = { "RoyalBoard" }

local Util
local remotes: Instance? = nil
local state
local wave
local busy: { [string]: boolean } = {}
local demoActive = false
local clockOffset = 0 -- state.serverNow - GetServerTimeNow (normalement ~0)
local waveEventSeen = false -- apres le 1er WaveState, les attributs (vague globale) ne font plus foi

---------------------------------------------------------------- Normalisation
local function num(v: any, default: number): number
	local n = tonumber(v)
	if n == nil or n ~= n then
		return default
	end
	return n
end

local function optString(v: any): string?
	if type(v) == "string" and v ~= "" then
		return v
	end
	return nil
end

local function optNumber(v: any): number?
	local n = tonumber(v)
	if n == nil or n ~= n then
		return nil
	end
	return n
end

-- creature du contrat v2 : {uid, species, mutation ("" = aucune), born, stage 1..4, nextStageAt (0 si Giant), income}
-- -> {uid?, species, mutation?, born?, stage?, nextStageAt?, income} ou false (bassin vide)
local function creatureEntry(raw: any): any
	if type(raw) == "string" then -- ancien serveur v1 : simple id
		return if raw ~= "" then { species = raw, income = 0 } else false
	end
	if type(raw) ~= "table" then
		return false
	end
	local species = optString(raw.species)
	if not species then
		return false
	end
	local stage = optNumber(raw.stage)
	return {
		uid = if raw.uid ~= nil then tostring(raw.uid) else nil,
		species = species,
		mutation = optString(raw.mutation),
		born = optNumber(raw.born),
		stage = if stage then math.clamp(math.floor(stage), 1, #STAGE_IDS) else nil,
		nextStageAt = optNumber(raw.nextStageAt),
		income = num(raw.income, 0),
		royal = raw.royal == true,
		mounted = raw.mounted == true, -- monture active : le bassin s'affiche vide
		carried = raw.carried == true, -- portee par un voleur : le bassin s'affiche vide
	}
end

local function normalizePools(raw: any, slots: number): { any }
	local src = if type(raw.pools) == "table" then raw.pools else raw.display -- display = v1
	src = type(src) == "table" and src or {}
	local pools = {}
	for i = 1, slots do
		pools[i] = creatureEntry(src[i])
	end
	return pools
end

-- sac : {{species, mutation}} (v2) ou {"id"} (v1)
local function normalizeBag(v: any): { { species: string, mutation: string? } }
	local out = {}
	if type(v) == "table" then
		for _, x in ipairs(v) do
			if type(x) == "string" and x ~= "" then
				table.insert(out, { species = x })
			elseif type(x) == "table" and optString(x.species) then
				table.insert(out, { species = x.species, mutation = optString(x.mutation) })
			end
		end
	end
	return out
end

local function defaultState()
	return {
		loaded = false,
		saveEnabled = true,
		serverNow = nil,
		coins = 0,
		income = 0,
		baseIncome = 0,
		petBoost = 0,
		codexBonus = 0,
		bag = {},
		bagMax = Config.GetUpgradeValue("Bag", 0),
		levels = { Speed = 0, Bag = 0, Slots = 0 },
		slots = Config.GetUpgradeValue("Slots", 0),
		pools = {},
		plot = 0,
		lagoonTier = 1,
		walkSpeed = Config.GetUpgradeValue("Speed", 0),
		homeReadyAt = 0,
		intro = "done",
		codex = {},
		codexCount = 0,
		codexTotal = 0,
		pets = {},
		equipped = {},
		stats = {},
		newbie = false,
		playTime = 0,
		mount = nil,
		carrying = false,
		lockActive = false,
		lockReadyAt = 0,
		shield = "",
		protectedUntil = 0,
		revenge = false,
		crown = 0,
		passes = {},
		shop = { randomAllowed = false },
	}
end


local function normalizePets(rawPets: any, rawEquipped: any)
	local pets, equipped = {}, {}
	if type(rawPets) == "table" then
		for _, p in ipairs(rawPets) do
			if type(p) == "table" and p.uid ~= nil and type(p.id) == "string" then
				table.insert(pets, { uid = tostring(p.uid), id = p.id })
			end
		end
	end
	if type(rawEquipped) == "table" then
		for _, uid in ipairs(rawEquipped) do
			table.insert(equipped, tostring(uid))
		end
	end
	return pets, equipped
end

-- carrying : false, ou {species, mutation, victim (UserId), victimName}
local function normalizeCarrying(v: any): any
	if type(v) ~= "table" or not optString(v.species) then
		return false
	end
	return {
		species = v.species,
		mutation = optString(v.mutation),
		victim = optNumber(v.victim),
		victimName = if type(v.victimName) == "string" then v.victimName else "",
	}
end

-- revenge : false, ou {userId, name}
local function normalizeRevenge(v: any): any
	if type(v) ~= "table" or optNumber(v.userId) == nil then
		return false
	end
	return { userId = optNumber(v.userId), name = if type(v.name) == "string" then v.name else "" }
end

-- Snapshot brut du serveur -> nouvelle table propre (types garantis ; re-normaliser un etat propre ne change rien)
local function normalizeState(raw: any)
	if type(raw) ~= "table" then
		return nil
	end
	local base = defaultState()
	local levels = type(raw.levels) == "table" and raw.levels or {}
	local slots = math.floor(num(raw.slots, base.slots))
	local pets, equipped = normalizePets(raw.pets, raw.equipped)
	return {
		loaded = raw.loaded == true,
		saveEnabled = raw.saveEnabled ~= false,
		serverNow = optNumber(raw.serverNow),
		coins = num(raw.coins, 0),
		income = num(raw.income, 0),
		baseIncome = num(raw.baseIncome, 0),
		petBoost = num(raw.petBoost, 0),
		codexBonus = num(raw.codexBonus, 0),
		bag = normalizeBag(raw.bag),
		bagMax = math.floor(num(raw.bagMax, base.bagMax)),
		levels = {
			Speed = math.floor(num(levels.Speed, 0)),
			Bag = math.floor(num(levels.Bag, 0)),
			Slots = math.floor(num(levels.Slots, 0)),
		},
		slots = slots,
		pools = normalizePools(raw, slots),
		plot = math.floor(num(raw.plot, 0)),
		lagoonTier = math.clamp(math.floor(num(raw.lagoonTier, 1)), 1, 5),
		walkSpeed = num(raw.walkSpeed, base.walkSpeed),
		homeReadyAt = num(raw.homeReadyAt, 0),
		intro = if INTRO_STEPS[raw.intro] then raw.intro else "done",
		codex = type(raw.codex) == "table" and raw.codex or {},
		codexCount = math.floor(num(raw.codexCount, 0)),
		codexTotal = math.floor(num(raw.codexTotal, 0)),
		pets = pets,
		equipped = equipped,
		stats = type(raw.stats) == "table" and table.clone(raw.stats) or {},
		-- PolicyService expose par A (bascule Tide Egg -> Pick a Creature) ; absent = prudence (restreint)
		-- v2.1 : vol, monture, Maree Royale, boutique
		newbie = raw.newbie == true,
		playTime = num(raw.playTime, 0),
		mount = if raw.mount ~= nil and raw.mount ~= "" and raw.mount ~= false then tostring(raw.mount) else nil,
		carrying = normalizeCarrying(raw.carrying),
		lockActive = raw.lockActive == true,
		lockReadyAt = num(raw.lockReadyAt, 0),
		shield = if type(raw.shield) == "string" then raw.shield else "",
		protectedUntil = num(raw.protectedUntil, 0),
		revenge = normalizeRevenge(raw.revenge),
		crown = math.clamp(math.floor(num(raw.crown, 0)), 0, 3),
		passes = type(raw.passes) == "table" and table.clone(raw.passes) or {},
		-- absent = prudence : pas d'achat aleatoire (Pick a Creature)
		shop = { randomAllowed = type(raw.shop) == "table" and raw.shop.randomAllowed == true },
	}
end

local function normalizeWave(raw: any)
	if type(raw) ~= "table" or not PHASES[raw.phase] then
		return nil
	end
	-- prochaine marée speciale du calendrier global : {tide, cycle}
	local nextSpecial = nil
	local ns = raw.nextSpecial
	if type(ns) == "table" and optString(ns.tide) then
		nextSpecial = { tide = ns.tide, cycle = optNumber(ns.cycle) }
	end
	-- Maree Royale (reserve) : {active, endsAt}
	local royal = nil
	if type(raw.royal) == "table" then
		royal = { active = raw.royal.active == true, endsAt = num(raw.royal.endsAt, 0) }
	end
	return {
		phase = raw.phase,
		phaseStart = num(raw.phaseStart, 0),
		phaseEnd = num(raw.phaseEnd, 0),
		startTime = num(raw.startTime, 0),
		cycle = math.floor(num(raw.cycle, 0)),
		tide = optString(raw.tide) or "Normal",
		nextSpecial = nextSpecial,
		intro = raw.intro == true,
		startZ = optNumber(raw.startZ), -- vague d'intro seulement
		speed = optNumber(raw.speed),
		royal = royal,
	}
end

---------------------------------------------------------------- Mise a jour
local function setState(raw: any)
	local nextState = normalizeState(raw)
	if not nextState then
		return
	end
	if nextState.serverNow then
		clockOffset = nextState.serverNow - Store.Now()
	end
	local prev = state
	state = nextState
	Store.Changed:Fire(state, prev)
end

local function setWave(raw: any)
	local nextWave = normalizeWave(raw)
	if not nextWave then
		return
	end
	local prev = wave
	-- rien de neuf (evenement en double ou attributs relus)
	if
		prev.phase == nextWave.phase
		and prev.phaseEnd == nextWave.phaseEnd
		and prev.startTime == nextWave.startTime
		and prev.tide == nextWave.tide
		and prev.intro == nextWave.intro
	then
		return
	end
	wave = nextWave
	Store.WaveChanged:Fire(wave, prev)
end

-- Attributs = vague GLOBALE : seulement avant le 1er WaveState (la vague du joueur peut differer : intro, Golden perso)
local function readWaveAttributes(ev: Instance)
	if waveEventSeen or ev:GetAttribute("Phase") == nil then
		return
	end
	setWave({
		phase = ev:GetAttribute("Phase"),
		phaseStart = ev:GetAttribute("PhaseStart"),
		phaseEnd = ev:GetAttribute("PhaseEnd"),
		startTime = ev:GetAttribute("StartTime"),
		cycle = ev:GetAttribute("Cycle"),
		tide = ev:GetAttribute("Tide"),
	})
end

---------------------------------------------------------------- Mode demo (Studio sans serveur)
-- Especes du mode demo : celles du GDD si Config les a deja, sinon les anciens tresors
local DEMO_SPECIES = if (Config :: any).Creatures then { "PebbleCrab", "SandStar", "ReefHatchling" } else { "Shell", "Starfish", "Pearl" }

local function demoCreature(uid: string, species: string, mutation: string, ageMinutes: number)
	local now = Store.Now()
	local born = now - ageMinutes * 60
	local entry = { uid = uid, species = species, mutation = mutation, born = born, income = 2 }
	local stage, _, left = Store.CreatureStage(creatureEntry(entry), now)
	entry.stage = stage
	entry.nextStageAt = if left then now + left else 0
	return entry
end

local function demoState()
	return {
		loaded = true,
		saveEnabled = true,
		serverNow = Store.Now(),
		coins = 1250,
		income = 12,
		baseIncome = 12,
		bag = { { species = DEMO_SPECIES[1], mutation = "" } },
		bagMax = 2,
		levels = { Speed = 1, Bag = 0, Slots = 0 },
		slots = 5,
		pools = {
			demoCreature("1", DEMO_SPECIES[2], "", 1.5),
			demoCreature("2", DEMO_SPECIES[1], "Golden", 20),
			demoCreature("3", DEMO_SPECIES[3], "", 120),
			false,
			false,
		},
		plot = 1,
		lagoonTier = 1,
		walkSpeed = 18,
		intro = "done",
		stats = { pickups = 3 },
		newbie = true,
		playTime = 12 * 60,
		mount = "",
		shop = { randomAllowed = true },
	}
end

local function demoWaveLoop()
	local cfg = Config.Wave
	local travel = (cfg.endZ - cfg.startZ) / cfg.speed
	local cycle = 0
	while demoActive do
		cycle += 1
		local t0 = Store.Now()
		local calmEnd = t0 + cfg.calmTime
		local warnEnd = calmEnd + cfg.warningTime
		local waveEnd = warnEnd + travel
		local steps = {
			{ "calm", t0, calmEnd },
			{ "warning", calmEnd, warnEnd },
			{ "wave", warnEnd, waveEnd },
			{ "recede", waveEnd, waveEnd + cfg.recedeTime },
		}
		-- une marée doree (avec Maree Royale) tous les 3 cycles, annoncee a l'avance
		local golden = cycle % 3 == 0
		local nextGolden = cycle + (3 - cycle % 3)
		for _, step in steps do
			if not demoActive then
				return
			end
			setWave({
				phase = step[1],
				phaseStart = step[2],
				phaseEnd = step[3],
				startTime = warnEnd,
				cycle = cycle,
				tide = if golden then "Golden" else "Normal",
				nextSpecial = { tide = "Golden", cycle = if golden then cycle + 3 else nextGolden },
				royal = if golden then { active = true, endsAt = waveEnd + cfg.recedeTime } else nil,
			})
			task.wait(math.max(0, step[3] - Store.Now()))
		end
	end
end

local function demoIncomeLoop()
	while demoActive do
		task.wait(1)
		if not demoActive then
			return
		end
		local nextState = table.clone(state)
		nextState.coins = state.coins + state.income
		nextState.serverNow = Store.Now()
		setState(nextState)
	end
end

local function startDemo()
	if demoActive or not RunService:IsStudio() then
		return
	end
	demoActive = true
	setState(demoState())
	task.spawn(demoWaveLoop)
	task.spawn(demoIncomeLoop)
end

-- Une vraie donnee du serveur arrete la demo
local function stopDemo()
	demoActive = false
end

function Store.IsDemo(): boolean
	return demoActive
end

---------------------------------------------------------------- API lecture
function Store.Get()
	return state
end

function Store.GetWave()
	return wave
end

function Store.Now(): number
	return workspace:GetServerTimeNow()
end

-- Horloge des heures du contrat (Unix serveur), recalee par state.serverNow
function Store.ServerClock(): number
	return Store.Now() + clockOffset
end

-- Secondes restantes dans la phase en cours
function Store.WaveTimeLeft(): number
	return math.max(0, wave.phaseEnd - Store.Now())
end

-- Progression 0..1 dans la phase en cours
function Store.WaveProgress(): number
	local span = wave.phaseEnd - wave.phaseStart
	if span <= 0 then
		return 0
	end
	return math.clamp((Store.Now() - wave.phaseStart) / span, 0, 1)
end

-- Z du front de vague, formule du contrat (nil quand la vague ne roule pas)
function Store.WaveFrontZ(now: number?): number?
	if wave.phase ~= "wave" and wave.phase ~= "recede" then
		return nil
	end
	local cfg = Config.Wave
	local t = now or Store.Now()
	local startZ = wave.startZ or cfg.startZ
	local speed = wave.speed or cfg.speed
	return math.min(cfg.endZ, startZ + speed * math.max(0, t - wave.startTime))
end

-- Fiche d'une espece : Config.Creatures (v2) puis Config.Items (v1). nil si inconnue.
function Store.CreatureInfo(species: string?): { name: string, rarity: string?, [string]: any }?
	if type(species) ~= "string" then
		return nil
	end
	local creatures = (Config :: any).Creatures
	local info = (creatures and creatures[species]) or Config.Items[species]
	if type(info) == "table" then
		return info
	end
	return nil
end

-- Nom affichable, meme pour une espece absente de Config ("PebbleCrab" -> "Pebble Crab")
function Store.CreatureName(species: string): string
	local info = Store.CreatureInfo(species)
	if info and type(info.name) == "string" then
		return info.name
	end
	return (species:gsub("(%l)(%u)", "%1 %2"))
end

function Store.StageId(stage: number): string
	local stages = (Config :: any).Stages
	local s = stages and stages[stage]
	if type(s) == "table" and type(s.id) == "string" then
		return s.id
	end
	return STAGE_IDS[stage] or STAGE_IDS[1]
end

-- Echelle visuelle d'un stade, relative a l'Adult (Config.Stages : 0.6 / 0.8 / 1 / 1.5)
function Store.StageScale(stage: number): number
	local stages = (Config :: any).Stages
	local s = stages and stages[stage]
	if type(s) == "table" and type(s.scale) == "number" then
		return s.scale
	end
	return ({ 0.6, 0.8, 1, 1.5 })[stage] or 1
end

local function growthMarks(species: string): { number }
	local info = Store.CreatureInfo(species)
	local growthTable = (Config :: any).GrowthMinutes or GROWTH_FALLBACK
	local growth = growthTable[info and info.rarity or "Common"] or growthTable.Common or GROWTH_FALLBACK.Common
	-- seuils en secondes : Baby 0, Juvenile, Adult, Giant
	return { 0, growth[1] * 60, growth[2] * 60, growth[3] * 60 }
end

-- Stade d'une creature (entree de state.pools) : (stade 1..4, progression 0..1 vers le suivant, secondes restantes ou nil)
-- Le serveur fait foi (stage, nextStageAt) ; born sert a placer le debut du stade, avec la meme vitesse de
-- croissance que le serveur (bonus compris), deduite de nextStageAt.
function Store.CreatureStage(entry: any, now: number?): (number, number, number?)
	local t = now or Store.ServerClock()
	local marks = growthMarks(entry.species)
	local maxStage = #marks
	local stage = entry.stage
	if not stage then
		if not entry.born then
			return 1, 0, nil
		end
		-- pas de stade serveur (demo) : calcule depuis born
		local age = math.max(0, t - entry.born)
		stage = 1
		for i = 2, maxStage do
			if age >= marks[i] then
				stage = i
			end
		end
		if stage >= maxStage then
			return maxStage, 1, nil
		end
		return stage, math.clamp((age - marks[stage]) / (marks[stage + 1] - marks[stage]), 0, 1), marks[stage + 1] - age
	end
	if stage >= maxStage or entry.nextStageAt == 0 then
		return maxStage, 1, nil
	end
	local nextAt = entry.nextStageAt
	if not nextAt then
		return stage, 0, nil
	end
	local left = math.max(0, nextAt - t)
	local stageStart
	if entry.born and marks[stage + 1] > 0 then
		local speedFactor = (nextAt - entry.born) / marks[stage + 1] -- 1 = vitesse normale, 0.5 = croissance x2
		stageStart = entry.born + marks[stage] * speedFactor
	else
		stageStart = nextAt - (marks[stage + 1] - marks[stage])
	end
	local span = nextAt - stageStart
	local progress = if span > 0 then math.clamp((t - stageStart) / span, 0, 1) else 1
	return stage, progress, left
end

-- Prochaine amelioration la moins chere (nil si tout est au maximum)
function Store.NextUpgrade(): { kind: string, level: number, cost: number }?
	local best = nil
	for _, kind in ipairs(Config.UpgradeOrder) do
		local up = Config.Upgrades[kind]
		local level = state.levels[kind] or 0
		if level < up.maxLevel then
			local cost = Config.GetUpgradeCost(kind, level)
			if not best or cost < best.cost then
				best = { kind = kind, level = level, cost = cost }
			end
		end
	end
	return best
end

---------------------------------------------------------------- API appels serveur
-- Appel RemoteFunction protege : jamais bloque plus de `timeout`, un seul appel a la fois par remote.
-- Renvoie (appelOk, ...retours serveur). appelOk = false -> 2e valeur = "NoRemote" | "Busy" | "Timeout" | "Error".
local function invoke(name: string, timeout: number, ...: any): (boolean, ...any)
	local rf = remotes and remotes:FindFirstChild(name)
	if not rf or not rf:IsA("RemoteFunction") then
		return false, "NoRemote"
	end
	if busy[name] then
		return false, "Busy"
	end
	busy[name] = true
	local args = table.pack(...)
	local caller = coroutine.running()
	local finished = false
	local result

	local function finish(res)
		if finished then
			return
		end
		finished = true
		result = res
		busy[name] = false
		-- reveille l'appelant seulement s'il attend deja (sinon il lit result directement)
		if coroutine.status(caller) == "suspended" then
			task.spawn(caller)
		end
	end

	task.spawn(function()
		local res = table.pack(pcall(function()
			return rf:InvokeServer(table.unpack(args, 1, args.n))
		end))
		finish(if res[1] then res else table.pack(false, "Error"))
	end)
	task.delay(timeout, function()
		finish(table.pack(false, "Timeout"))
	end)

	if not finished then
		coroutine.yield()
	end
	return table.unpack(result, 1, result.n)
end

function Store.Invoke(name: string, ...: any): (boolean, ...any)
	return invoke(name, INVOKE_TIMEOUT, ...)
end

-- Raccourci : (ok, valeur ou code d'erreur) pour les RF qui repondent (true, x) | (false, code)
local function call(name: string, ...: any): (boolean, any)
	local callOk, ok, value = Store.Invoke(name, ...)
	if not callOk then
		return false, ok
	end
	return ok == true, value
end

function Store.BuyUpgrade(kind: string): (boolean, any)
	return call("BuyUpgrade", kind)
end

function Store.GoHome(): (boolean, any)
	return call("GoHome")
end

-- Reserves (GDD v2, forme provisoire du contrat) : renvoient (false, "NoRemote") tant que A ne les cree pas
-- Contrat v2.1 : StartSteal -> (true, holdEndsAt) ; le serveur prend la creature a holdEndsAt si on n'a pas bouge
function Store.StartSteal(plot: number, slot: number): (boolean, any)
	return call("StartSteal", plot, slot)
end

-- Mode demo : la monture et le verrou sont simules localement
local function demoPatch(patch: { [string]: any })
	local nextState = table.clone(state)
	for k, v in patch do
		nextState[k] = v
	end
	setState(nextState)
end

-- Mount(uid) monte ; Mount(nil) descend (contrat v2.1)
function Store.Mount(uid: string?): (boolean, any)
	if demoActive then
		demoPatch({ mount = uid or "" })
		return true, nil
	end
	return call("Mount", uid)
end

function Store.ChoosePick(species: string): (boolean, any)
	return call("ChoosePick", species)
end

-- Creatures montables de mes bassins (Config.Mount : especes, stade minimum), la plus grande d'abord
function Store.Mountables(): { any }
	local mountCfg = (Config :: any).Mount
	if type(mountCfg) ~= "table" then
		return {}
	end
	local minStage = table.find(STAGE_IDS, mountCfg.minStage or "Adult") or 3
	local out = {}
	for _, entry in state.pools do
		if entry and entry.uid and not entry.carried and mountCfg.species[entry.species] and (entry.stage or 1) >= minStage then
			table.insert(out, entry)
		end
	end
	table.sort(out, function(a, b)
		if (a.stage or 0) ~= (b.stage or 0) then
			return (a.stage or 0) > (b.stage or 0)
		end
		return a.income > b.income
	end)
	return out
end

-- LockLagoon -> (true, readyAt)
function Store.LockLagoon(): (boolean, any)
	if demoActive then
		local readyAt = Store.Now() + 240
		demoPatch({ lockActive = true, lockReadyAt = readyAt, shield = "lock" })
		return true, readyAt
	end
	return call("LockLagoon")
end

-- Le serveur propose-t-il cette fonction ? (les boutons d'une fonction absente restent caches)
function Store.HasRemote(name: string): boolean
	if demoActive then
		return true
	end
	return remotes ~= nil and remotes:FindFirstChild(name) ~= nil
end

---------------------------------------------------------------- Demarrage
function Store.Init(ctx)
	Util = ctx.Util
	Store.Changed = Util.Signal.new() -- (state, prevState)
	Store.WaveChanged = Util.Signal.new() -- (wave, prevWave)
	Store.Notified = Util.Signal.new() -- (kind, data)
	Store.RoyalBoard = Util.Signal.new() -- (board) {cycle, endsAt, top = {{userId, name, score}}}
	state = defaultState()
	wave = { phase = "calm", phaseStart = 0, phaseEnd = 0, startTime = 0, cycle = 0, tide = "Normal", intro = false }
end

-- Studio uniquement : pilotage depuis execute_luau (client)
--   Players.LocalPlayer.TR_ClientDebug:Fire("state", {coins = 500, intro = "intro"})   fusionne avec l'etat courant
--   Players.LocalPlayer.TR_ClientDebug:Fire("wave", {phase = "warning", phaseStart = t, phaseEnd = t + 7, startTime = t + 7, tide = "Golden"})
--   Players.LocalPlayer.TR_ClientDebug:Fire("notify", "capture", {species = "SandStar", mutation = "Golden", isNew = true, text = "..."})
--   Players.LocalPlayer.TR_ClientDebug:Fire("notify", "stealStart", {role = "victim", thief = 123, thiefName = "Kai", species = "SandStar", text = "..."})
--   Players.LocalPlayer.TR_ClientDebug:Fire("royal", {cycle = 3, endsAt = t, top = {{userId = 1, name = "Moaad", score = 1200}}})
--   Players.LocalPlayer.TR_ClientDebug:Fire("demo", true | false)
local function setupDebug()
	if not RunService:IsStudio() then
		return
	end
	local ev = Instance.new("BindableEvent")
	ev.Name = "TR_ClientDebug"
	ev.Event:Connect(function(kind, payload, extra)
		if kind == "state" and type(payload) == "table" then
			local merged = table.clone(state)
			for k, v in payload do
				merged[k] = v
			end
			merged.loaded = if payload.loaded == nil then true else payload.loaded
			setState(merged)
		elseif kind == "wave" then
			waveEventSeen = true
			setWave(payload)
		elseif kind == "notify" and type(payload) == "string" then
			Store.Notified:Fire(payload, type(extra) == "table" and extra or {})
		elseif kind == "royal" and type(payload) == "table" then
			Store.RoyalBoard:Fire(payload)
		elseif kind == "demo" then
			if payload then
				startDemo()
			else
				stopDemo()
			end
		end
	end)
	ev.Parent = Players.LocalPlayer
end

local function connectWaveEvent(waveEv: RemoteEvent)
	waveEv.OnClientEvent:Connect(function(raw)
		stopDemo()
		waveEventSeen = true
		setWave(raw)
	end)
	readWaveAttributes(waveEv)
	-- Les attributs arrivent un par un : une seule relecture un peu apres (l'evenement fait foi)
	local pendingRead = false
	waveEv.AttributeChanged:Connect(function()
		if pendingRead or waveEventSeen then
			return
		end
		pendingRead = true
		task.delay(ATTRIBUTE_SETTLE, function()
			pendingRead = false
			readWaveAttributes(waveEv)
		end)
	end)
end

-- RemoteEvents reserves : branches a leur creation par le serveur
local function connectOptional(ev: Instance)
	if not ev:IsA("RemoteEvent") or not table.find(OPTIONAL_EVENTS, ev.Name) then
		return
	end
	ev.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if ev.Name == "RoyalBoard" then
			Store.RoyalBoard:Fire(payload)
		end
	end)
end

local function connectEvents(folder: Instance)
	local stateEv = folder:WaitForChild("StateChanged", 10)
	local waveEv = folder:WaitForChild("WaveState", 10)
	local notifyEv = folder:WaitForChild("Notify", 10)
	if stateEv and stateEv:IsA("RemoteEvent") then
		stateEv.OnClientEvent:Connect(function(raw)
			stopDemo()
			setState(raw)
		end)
	end
	if waveEv and waveEv:IsA("RemoteEvent") then
		connectWaveEvent(waveEv)
	end
	if notifyEv and notifyEv:IsA("RemoteEvent") then
		notifyEv.OnClientEvent:Connect(function(kind, data)
			if type(kind) == "string" then
				Store.Notified:Fire(kind, type(data) == "table" and data or {})
			end
		end)
	end
	for _, child in folder:GetChildren() do
		connectOptional(child)
	end
	folder.ChildAdded:Connect(connectOptional)
end

-- Demande l'etat initial ; sans reponse dans Studio, bascule en demo et continue d'essayer
local function fetchInitialState(folder: Instance)
	folder:WaitForChild("GetState", 5)
	for attempt = 1, GETSTATE_ATTEMPTS do
		local timeout = if attempt == 1 then GETSTATE_TIMEOUT else INVOKE_TIMEOUT
		local callOk, s, w = invoke("GetState", timeout)
		if callOk then
			stopDemo()
			-- un StateChanged plus recent a pu arriver pendant l'appel : pas de retour en arriere
			if s and not (state.loaded and type(s) == "table" and s.loaded ~= true) then
				setState(s)
			end
			if w then
				waveEventSeen = true
				setWave(w)
			end
			return
		end
		startDemo()
		task.wait(attempt)
	end
end

function Store.Start(_ctx)
	setupDebug()
	local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not folder then
		startDemo()
		return
	end
	remotes = folder
	-- Ecoute d'abord, puis demande l'etat : aucun message perdu
	connectEvents(folder)
	task.spawn(fetchInitialState, folder)
end

return Store
