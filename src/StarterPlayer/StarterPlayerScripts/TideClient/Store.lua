-- Store : etat client (snapshot serveur + vague) et appels reseau (contrat remotes v1 de A).
-- Seul module qui touche ReplicatedStorage.Remotes. Les ecrans lisent Store.Get() / Store.GetWave().
-- Studio sans serveur : donnees factices (mode demo) pour travailler l'interface.
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
local STAGE_IDS = { "Baby", "Juvenile", "Adult", "Giant" }
-- Croissance du GDD §4.3 (minutes cumulees vers Juvenile, Adult, Giant), tant que Config.GrowthMinutes manque
local GROWTH_FALLBACK = {
	Common = { 3, 15, 60 },
	Uncommon = { 5, 30, 120 },
	Rare = { 10, 60, 240 },
	Epic = { 20, 120, 480 },
	Legendary = { 30, 240, 1200 },
}

-- Especes du mode demo : celles du GDD si Config les a deja, sinon les anciens tresors
local DEMO_SPECIES = if (Config :: any).Creatures then { "PebbleCrab", "SandStar", "BubblePuffer" } else { "Shell", "Starfish", "Pearl" }

-- Donnees factices du mode demo (Studio uniquement), forme v2 du GDD : display[i] = {id, mut, born}
local function demoState()
	local now = workspace:GetServerTimeNow()
	return {
		loaded = true,
		saveEnabled = true,
		coins = 1250,
		income = 12,
		baseIncome = 12,
		bag = { DEMO_SPECIES[1] },
		bagMax = 2,
		levels = { Speed = 1, Bag = 0, Slots = 0 },
		slots = 5,
		display = {
			{ id = DEMO_SPECIES[2], born = now - 100 },
			{ id = DEMO_SPECIES[1], mut = "Golden", born = now - 20 * 60 },
			{ id = DEMO_SPECIES[3], born = now - 2 * 3600 },
			"",
			"",
		},
		plot = 1,
		walkSpeed = 18,
		stats = { pickups = 3 },
	}
end

local Util
local remotes: Instance? = nil
local state
local wave
local busy: { [string]: boolean } = {}
local demoActive = false
local clockOffset = 0 -- horloge des donnees (os.time serveur) - GetServerTimeNow

---------------------------------------------------------------- Normalisation
local function num(v: any, default: number): number
	local n = tonumber(v)
	if n == nil or n ~= n then
		return default
	end
	return n
end

local function stringList(v: any): { string }
	local out = {}
	if type(v) == "table" then
		for _, x in ipairs(v) do
			if type(x) == "string" then
				table.insert(out, x)
			end
		end
	end
	return out
end

local function defaultState()
	return {
		loaded = false,
		saveEnabled = true,
		coins = 0,
		income = 0,
		baseIncome = 0,
		petBoost = 0,
		bag = {},
		bagMax = Config.GetUpgradeValue("Bag", 0),
		levels = { Speed = 0, Bag = 0, Slots = 0 },
		slots = Config.GetUpgradeValue("Slots", 0),
		display = {},
		pools = {},
		plot = 0,
		walkSpeed = Config.GetUpgradeValue("Speed", 0),
		homeReadyAt = 0,
		pets = {},
		equipped = {},
		stats = {},
		collection = {},
	}
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

-- Une creature, quelle que soit la forme recue (contrat v2 pas encore fige) :
--   v1 "itemId" ; GDD {id, mut, stage, nextStageAt, born} ; A {species, mutation, bornAt} (via creatures[uid])
-- -> {species, mutation?, bornAt?, stage? (1..4), nextStageAt?, uid?} ou false (bassin vide)
local function creatureEntry(raw: any, uid: string?): any
	if type(raw) == "string" then
		return if raw ~= "" then { species = raw, uid = uid } else false
	end
	if type(raw) ~= "table" then
		return false
	end
	local species = optString(raw.species) or optString(raw.id)
	if not species then
		return false
	end
	local stage = raw.stage
	if type(stage) == "string" then
		stage = table.find(STAGE_IDS, stage)
	end
	stage = optNumber(stage)
	return {
		species = species,
		mutation = optString(raw.mutation) or optString(raw.mut),
		bornAt = optNumber(raw.bornAt) or optNumber(raw.born),
		stage = if stage then math.clamp(math.floor(stage), 1, #STAGE_IDS) else nil,
		nextStageAt = optNumber(raw.nextStageAt),
		uid = uid or (if raw.uid ~= nil then tostring(raw.uid) else nil),
	}
end

-- Bassins 1..slots : forme GDD (display = entrees) ou forme A (pools = uids + creatures[uid])
local function normalizePools(raw: any, slots: number): { any }
	local creatures = type(raw.creatures) == "table" and raw.creatures or nil
	local src = if creatures and type(raw.pools) == "table" then raw.pools else raw.display
	src = type(src) == "table" and src or {}
	local pools = {}
	for i = 1, slots do
		local v = src[i]
		if creatures and (type(v) == "string" or type(v) == "number") and creatures[v] ~= nil then
			pools[i] = creatureEntry(creatures[v], tostring(v))
		else
			pools[i] = creatureEntry(v, nil)
		end
	end
	return pools
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

-- Snapshot brut du serveur -> nouvelle table propre (types garantis)
local function normalizeState(raw: any)
	if type(raw) ~= "table" then
		return nil
	end
	local base = defaultState()
	local levels = type(raw.levels) == "table" and raw.levels or {}
	local slots = math.floor(num(raw.slots, base.slots))
	local pets, equipped = normalizePets(raw.pets, raw.equipped)
	local pools = normalizePools(raw, slots)
	local display = {}
	for i, entry in pools do
		display[i] = if entry then entry.species else ""
	end
	return {
		loaded = raw.loaded == true,
		saveEnabled = raw.saveEnabled ~= false,
		coins = num(raw.coins, 0),
		income = num(raw.income, 0),
		baseIncome = num(raw.baseIncome, 0),
		petBoost = num(raw.petBoost, 0),
		bag = stringList(raw.bag),
		bagMax = math.floor(num(raw.bagMax, base.bagMax)),
		levels = {
			Speed = math.floor(num(levels.Speed, 0)),
			Bag = math.floor(num(levels.Bag, 0)),
			Slots = math.floor(num(levels.Slots, 0)),
		},
		slots = slots,
		display = display, -- ids (compatibilite v1)
		pools = pools, -- entrees completes (Store.CreatureStage)
		serverNow = optNumber(raw.serverNow),
		tutorialDone = if type(raw.tutorialDone) == "boolean" then raw.tutorialDone else nil,
		plot = math.floor(num(raw.plot, 0)),
		walkSpeed = num(raw.walkSpeed, base.walkSpeed),
		homeReadyAt = num(raw.homeReadyAt, 0),
		pets = pets,
		equipped = equipped,
		stats = type(raw.stats) == "table" and table.clone(raw.stats) or {},
		collection = type(raw.collection) == "table" and table.clone(raw.collection) or {},
	}
end

local function normalizeWave(raw: any)
	if type(raw) ~= "table" or not PHASES[raw.phase] then
		return nil
	end
	-- prochaine marée speciale (forme libre en attendant le contrat v2) : {tide, cycles?, at?}
	local nextSpecial = nil
	local ns = raw.nextSpecial
	if type(ns) == "table" then
		local tide = optString(ns.tide) or optString(ns.tideType)
		if tide then
			nextSpecial = { tide = tide, cycles = optNumber(ns.cycles) or optNumber(ns.inCycles), at = optNumber(ns.at) }
		end
	end
	return {
		phase = raw.phase,
		phaseStart = num(raw.phaseStart, 0),
		phaseEnd = num(raw.phaseEnd, 0),
		startTime = num(raw.startTime, 0),
		cycle = math.floor(num(raw.cycle, 0)),
		tide = optString(raw.tide) or optString(raw.tideType) or "Normal",
		nextSpecial = nextSpecial,
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
	-- rien de neuf (l'evenement et les attributs portent la meme info)
	if
		prev.phase == nextWave.phase
		and prev.phaseEnd == nextWave.phaseEnd
		and prev.startTime == nextWave.startTime
		and prev.tide == nextWave.tide
	then
		return
	end
	wave = nextWave
	Store.WaveChanged:Fire(wave, prev)
end

local function readWaveAttributes(ev: Instance)
	if ev:GetAttribute("Phase") == nil then
		return
	end
	setWave({
		phase = ev:GetAttribute("Phase"),
		phaseStart = ev:GetAttribute("PhaseStart"),
		phaseEnd = ev:GetAttribute("PhaseEnd"),
		startTime = ev:GetAttribute("StartTime"),
		cycle = ev:GetAttribute("Cycle"),
		tide = ev:GetAttribute("Tide") or ev:GetAttribute("TideType"),
	})
end

---------------------------------------------------------------- Mode demo (Studio sans serveur)
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
		-- une marée doree tous les 3 cycles, annoncee a l'avance
		local tide = if cycle % 3 == 0 then "Golden" else "Normal"
		local nextSpecial = { tide = "Golden", cycles = (3 - cycle % 3) % 3 }
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
				tide = tide,
				nextSpecial = if tide == "Golden" then nil else nextSpecial,
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
		-- repasse par la forme brute : display redevient la liste des entrees
		local nextState = table.clone(state)
		nextState.display = state.pools
		nextState.coins = state.coins + state.income
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
	return math.min(cfg.endZ, cfg.startZ + cfg.speed * math.max(0, t - wave.startTime))
end

-- Horloge des donnees de croissance (os.time du serveur ; recale par state.serverNow s'il est fourni)
function Store.ServerClock(): number
	return Store.Now() + clockOffset
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
	return STAGE_IDS[stage] or STAGE_IDS[1]
end

-- Stade d'une creature (entree de state.pools) : (stade 1..4, progression 0..1 vers le suivant, secondes restantes ou nil au max)
-- Calcule depuis bornAt (croissance hors ligne sans timer), sinon depuis stage + nextStageAt envoyes par le serveur.
function Store.CreatureStage(entry: any, now: number?): (number, number, number?)
	local t = now or Store.ServerClock()
	local info = Store.CreatureInfo(entry.species)
	local growthTable = (Config :: any).GrowthMinutes or GROWTH_FALLBACK
	local growth = growthTable[info and info.rarity or "Common"] or growthTable.Common
	-- seuils en secondes : Baby 0, Juvenile, Adult, Giant
	local marks = { 0, growth[1] * 60, growth[2] * 60, growth[3] * 60 }
	local maxStage = #marks
	if entry.bornAt then
		local age = math.max(0, t - entry.bornAt)
		local stage = 1
		for i = 2, maxStage do
			if age >= marks[i] then
				stage = i
			end
		end
		if stage >= maxStage then
			return maxStage, 1, nil
		end
		local span = marks[stage + 1] - marks[stage]
		return stage, math.clamp((age - marks[stage]) / span, 0, 1), marks[stage + 1] - age
	end
	local stage = entry.stage or 1
	if stage >= maxStage then
		return maxStage, 1, nil
	end
	if entry.nextStageAt then
		local span = marks[stage + 1] - marks[stage]
		local left = math.max(0, entry.nextStageAt - t)
		return stage, math.clamp(1 - left / span, 0, 1), left
	end
	return stage, 0, nil
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

-- Raccourcis : renvoient (ok, valeur ou code d'erreur)
function Store.BuyUpgrade(kind: string): (boolean, any)
	local callOk, ok, value = Store.Invoke("BuyUpgrade", kind)
	if not callOk then
		return false, ok
	end
	return ok == true, value
end

function Store.GoHome(): (boolean, any)
	local callOk, ok, code = Store.Invoke("GoHome")
	if not callOk then
		return false, ok
	end
	return ok == true, code
end

---------------------------------------------------------------- Demarrage
function Store.Init(ctx)
	Util = ctx.Util
	Store.Changed = Util.Signal.new() -- (state, prevState)
	Store.WaveChanged = Util.Signal.new() -- (wave, prevWave)
	Store.Notified = Util.Signal.new() -- (kind, data)
	state = defaultState()
	wave = { phase = "calm", phaseStart = 0, phaseEnd = 0, startTime = 0, cycle = 0 }
end

-- Studio uniquement : pilotage depuis execute_luau (client)
--   Players.LocalPlayer.TR_ClientDebug:Fire("state", {coins = 500})       fusionne avec l'etat courant
--   Players.LocalPlayer.TR_ClientDebug:Fire("wave", {phase = "warning", phaseStart = t, phaseEnd = t + 7, startTime = t + 7})
--   Players.LocalPlayer.TR_ClientDebug:Fire("notify", "pickup", {itemId = "Pearl", rarity = "Uncommon"})
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
			merged.display = state.pools -- garde les dates de naissance
			for k, v in payload do
				merged[k] = v
			end
			merged.loaded = if payload.loaded == nil then true else payload.loaded
			setState(merged)
		elseif kind == "wave" then
			setWave(payload)
		elseif kind == "notify" and type(payload) == "string" then
			Store.Notified:Fire(payload, type(extra) == "table" and extra or {})
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

local function connectWaveEvent(waveEv: Instance)
	waveEv.OnClientEvent:Connect(function(raw)
		stopDemo()
		setWave(raw)
	end)
	readWaveAttributes(waveEv)
	-- Les attributs arrivent un par un : une seule relecture un peu apres (l'evenement fait foi)
	local pendingRead = false
	waveEv.AttributeChanged:Connect(function()
		if pendingRead then
			return
		end
		pendingRead = true
		task.delay(ATTRIBUTE_SETTLE, function()
			pendingRead = false
			readWaveAttributes(waveEv)
		end)
	end)
end

local function connectEvents()
	local stateEv = remotes:WaitForChild("StateChanged", 10)
	local waveEv = remotes:WaitForChild("WaveState", 10)
	local notifyEv = remotes:WaitForChild("Notify", 10)
	if stateEv then
		stateEv.OnClientEvent:Connect(function(raw)
			stopDemo()
			setState(raw)
		end)
	end
	if waveEv then
		connectWaveEvent(waveEv)
	end
	if notifyEv then
		notifyEv.OnClientEvent:Connect(function(kind, data)
			if type(kind) == "string" then
				Store.Notified:Fire(kind, type(data) == "table" and data or {})
			end
		end)
	end
end

-- Demande l'etat initial ; sans reponse dans Studio, bascule en demo et continue d'essayer
local function fetchInitialState()
	remotes:WaitForChild("GetState", 5)
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
	remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not remotes then
		startDemo()
		return
	end
	-- Ecoute d'abord, puis demande l'etat : aucun message perdu
	connectEvents()
	task.spawn(fetchInitialState)
end

return Store
