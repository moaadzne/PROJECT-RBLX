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

-- Donnees factices du mode demo (Studio uniquement)
local DEMO_STATE = {
	loaded = true,
	saveEnabled = true,
	coins = 1250,
	income = 12,
	baseIncome = 12,
	bag = { "Shell" },
	bagMax = 2,
	levels = { Speed = 1, Bag = 0, Slots = 0 },
	slots = 5,
	display = { "Starfish", "Shell", "Shell", "", "" },
	plot = 1,
	walkSpeed = 18,
}

local Util
local remotes: Instance? = nil
local state
local wave
local busy: { [string]: boolean } = {}
local demoActive = false

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
		plot = 0,
		walkSpeed = Config.GetUpgradeValue("Speed", 0),
		homeReadyAt = 0,
		pets = {},
		equipped = {},
		stats = {},
		collection = {},
	}
end

local function normalizeDisplay(rawDisplay: any, slots: number): { string }
	local src = type(rawDisplay) == "table" and rawDisplay or {}
	local display = {}
	for i = 1, slots do
		local id = src[i]
		display[i] = (type(id) == "string" and Config.Items[id]) and id or ""
	end
	return display
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
		display = normalizeDisplay(raw.display, slots),
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
	return {
		phase = raw.phase,
		phaseStart = num(raw.phaseStart, 0),
		phaseEnd = num(raw.phaseEnd, 0),
		startTime = num(raw.startTime, 0),
		cycle = math.floor(num(raw.cycle, 0)),
	}
end

---------------------------------------------------------------- Mise a jour
local function setState(raw: any)
	local nextState = normalizeState(raw)
	if not nextState then
		return
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
	if prev.phase == nextWave.phase and prev.phaseEnd == nextWave.phaseEnd and prev.startTime == nextWave.startTime then
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
		for _, step in steps do
			if not demoActive then
				return
			end
			setWave({ phase = step[1], phaseStart = step[2], phaseEnd = step[3], startTime = warnEnd, cycle = cycle })
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
		setState(nextState)
	end
end

local function startDemo()
	if demoActive or not RunService:IsStudio() then
		return
	end
	demoActive = true
	setState(DEMO_STATE)
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
