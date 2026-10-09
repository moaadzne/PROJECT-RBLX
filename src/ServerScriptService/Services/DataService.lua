-- DataService : profils joueurs en memoire, DataStore avec verrou de session par profil,
-- envoi de l'etat au client (StateChanged / GetState) et leaderstats.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)

local DataService = {}

local STORE_NAME = "TideRush_Players"
local KEY_PREFIX = "u_"
local SCHEMA_VERSION = 1
local LOAD_TRIES = 3
local AUTOSAVE_EVERY = 90
local AUTOSAVE_STAGGER = 0.5
local LOCK_STALE = AUTOSAVE_EVERY + 30 -- s sans rafraichissement : le serveur qui tenait le verrou est mort
local LOCK_WAIT = 3 -- s entre deux essais quand un autre profil tient le verrou
local LOCK_WAIT_TRIES = 10 -- ensuite on force : l'ancien profil ne pourra plus ecrire
local RELEASE_TOPIC = "TR_Release" -- demande aux autres serveurs de rendre un profil
local FINAL_SAVE_TRIES = 4
local SHUTDOWN_TIMEOUT = 25
local FLUSH_EVERY = 0.1
local KICK_MESSAGE = "You joined Tide Rush on another server."

local STAT_KEYS = { "pickups", "deposited", "sold", "caught", "wavesSurvived", "eggsHatched", "upgradesBought", "coinsEarned" }

local SESSION_ID = HttpService:GenerateGUID(false)

local store = nil
local profiles = {} -- [player] = profile
local dirty = {} -- [player] = true : etat a renvoyer au client
local loadedHooks = {}
local pendingLoads = 0

local function num(value, default, minValue, maxValue)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	if minValue and value < minValue then
		value = minValue
	end
	if maxValue and value > maxValue then
		value = maxValue
	end
	return value
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = deepCopy(v)
	end
	return out
end

-- Erreurs qui ne changeront pas en reessayant (Studio sans acces API, place non publiee)
local function isPermanent(err)
	local text = tostring(err)
	return string.find(text, "StudioAccessToApisNotAllowed", 1, true) ~= nil
		or string.find(text, "publish", 1, true) ~= nil
		or string.find(text, "403", 1, true) ~= nil
end

local function defaultData()
	local now = os.time()
	local stats = {}
	for _, key in ipairs(STAT_KEYS) do
		stats[key] = 0
	end
	return {
		v = SCHEMA_VERSION,
		coins = 0,
		levels = { Speed = 0, Bag = 0, Slots = 0 },
		display = {},
		pets = {},
		equipped = {},
		petSeq = 0,
		stats = stats,
		collection = {},
		firstJoin = now,
		lastSeen = now,
		legacy = {},
	}
end

-- Garde de cote ce que cette version ne sait pas lire : rien n'est jamais efface
local function keepLegacy(d, field, value)
	d.legacy[field] = d.legacy[field] or {}
	table.insert(d.legacy[field], value)
end

-- Valide et complete des donnees lues (DataStore = donnees externes, jamais fiables)
function DataService._Sanitize(raw)
	local d = defaultData()
	if type(raw) ~= "table" then
		d.display = Stats.NormalizeDisplay(d)
		return d
	end
	if type(raw.legacy) == "table" then
		d.legacy = deepCopy(raw.legacy)
	end
	d.coins = math.floor(num(raw.coins, 0, 0))
	if type(raw.levels) == "table" then
		for kind, def in pairs(Config.Upgrades) do
			local level = math.floor(num(raw.levels[kind], 0, 0))
			if level > def.maxLevel then
				keepLegacy(d, "levels", { kind = kind, level = level })
				level = def.maxLevel
			end
			d.levels[kind] = level
		end
	end

	local rawDisplay = type(raw.display) == "table" and raw.display or {}
	d.display = rawDisplay
	d.display = Stats.NormalizeDisplay(d)
	for slot, itemId in ipairs(rawDisplay) do
		if type(itemId) == "string" and itemId ~= "" and d.display[slot] ~= itemId then
			keepLegacy(d, "display", itemId)
		end
	end

	local seen, maxSeq = {}, 0
	if type(raw.pets) == "table" then
		for _, pet in ipairs(raw.pets) do
			if type(pet) == "table" and type(pet.uid) == "string" and not seen[pet.uid] then
				local n = tonumber(pet.uid)
				if n and n > maxSeq then
					maxSeq = n
				end
				if type(pet.id) == "string" and Config.Pets[pet.id] and #d.pets < Config.MaxPetInventory then
					seen[pet.uid] = true
					table.insert(d.pets, { uid = pet.uid, id = pet.id })
				else
					keepLegacy(d, "pets", deepCopy(pet))
				end
			end
		end
	end
	d.petSeq = math.max(math.floor(num(raw.petSeq, 0, 0)), maxSeq)
	if type(raw.equipped) == "table" then
		for _, uid in ipairs(raw.equipped) do
			if #d.equipped >= Config.MaxEquippedPets then
				break
			end
			if type(uid) == "string" and seen[uid] and not table.find(d.equipped, uid) then
				table.insert(d.equipped, uid)
			end
		end
	end

	if type(raw.stats) == "table" then
		for _, key in ipairs(STAT_KEYS) do
			d.stats[key] = math.floor(num(raw.stats[key], 0, 0))
		end
	end
	if type(raw.collection) == "table" then
		for itemId, value in pairs(raw.collection) do
			local count = math.floor(num(value, 0, 0))
			if count > 0 then
				if Config.Items[itemId] then
					d.collection[itemId] = count
				else
					keepLegacy(d, "collection", { id = itemId, count = count })
				end
			end
		end
	end
	d.firstJoin = num(raw.firstJoin, d.firstJoin, 0)
	d.lastSeen = num(raw.lastSeen, d.lastSeen, 0)
	return d
end

local function ownsLock(lock, profile)
	return type(lock) == "table" and lock.s == SESSION_ID and lock.p == profile.token
end

-- Prend le verrou de session et lit l'enregistrement.
-- Renvoie "ok", record | "locked" | "error", message
local function claim(profile, force)
	local status = "error"
	local ok, result = pcall(function()
		return store:UpdateAsync(profile.key, function(record)
			if type(record) ~= "table" then
				record = {}
			end
			local lock = record.lock
			local now = os.time()
			if not force and type(lock) == "table" and not ownsLock(lock, profile)
				and type(lock.t) == "number" and now - lock.t < LOCK_STALE then
				status = "locked"
				return nil
			end
			status = "ok"
			record.lock = { s = SESSION_ID, p = profile.token, j = game.JobId, t = now }
			return record
		end)
	end)
	if not ok then
		return "error", result
	end
	return status, result
end

-- Rend le verrou sans toucher aux donnees (seulement s'il est a ce profil)
local function releaseLock(profile)
	local ok, err = pcall(function()
		store:UpdateAsync(profile.key, function(record)
			if type(record) ~= "table" or not ownsLock(record.lock, profile) then
				return nil
			end
			record.lock = nil
			return record
		end)
	end)
	if not ok then
		warn(("[TideRush] liberation du verrou %s impossible : %s"):format(profile.key, tostring(err)))
	end
end

-- Demande au serveur qui tient ce profil de le sauvegarder et de le rendre
local function requestRelease(key)
	local ok, err = pcall(function()
		MessagingService:PublishAsync(RELEASE_TOPIC, key)
	end)
	if not ok and not RunService:IsStudio() then
		warn("[TideRush] demande de liberation non envoyee : " .. tostring(err))
	end
end

local function loadRecord(profile)
	if not store then
		return nil, "DataStore indisponible"
	end
	local errors, waits = 0, 0
	while profile.player.Parent and not profile.leaving do
		local status, result = claim(profile, waits >= LOCK_WAIT_TRIES)
		if status == "ok" then
			return result
		elseif status == "locked" then
			if waits == 0 then
				requestRelease(profile.key)
			end
			waits += 1
			task.wait(LOCK_WAIT)
		else
			if isPermanent(result) then
				return nil, result
			end
			errors += 1
			warn(("[TideRush] chargement %s, essai %d/%d : %s"):format(profile.key, errors, LOAD_TRIES, tostring(result)))
			if errors >= LOAD_TRIES then
				releaseLock(profile) -- au cas ou une ecriture serait passee malgre l'erreur
				return nil, result
			end
			task.wait(2 ^ errors)
		end
	end
	return nil, "parti"
end

-- Sauvegarde ; release = true rend le verrou (depart, fermeture).
-- Renvoie "ok" | "error" | "lockLost" | "skipped"
local function save(profile, release)
	while profile.saving do
		task.wait(0.1)
	end
	if not store or not profile.saveEnabled or profile.released then
		return "skipped"
	end
	profile.saving = true
	profile.data.lastSeen = os.time()
	local snapshot = deepCopy(profile.data)
	local lockLost = false
	local ok, err = pcall(function()
		store:UpdateAsync(profile.key, function(record)
			if type(record) ~= "table" or not ownsLock(record.lock, profile) then
				lockLost = true
				return nil
			end
			lockLost = false
			record.data = snapshot
			record.lock = if release then nil else { s = SESSION_ID, p = profile.token, j = game.JobId, t = os.time() }
			return record
		end)
	end)
	profile.saving = false
	if not ok then
		warn(("[TideRush] sauvegarde %s echouee : %s"):format(profile.key, tostring(err)))
		return "error"
	end
	if lockLost then
		-- un autre profil a repris ce joueur : on n'ecrit plus jamais par-dessus
		profile.saveEnabled = false
		warn(("[TideRush] verrou perdu pour %s : sauvegarde coupee"):format(profile.key))
		if profile.player.Parent and not profile.leaving then
			Net.Notify(profile.player, "saveOff", { text = "Your progress is now saved on another server." })
		end
		return "lockLost"
	end
	if release then
		profile.released = true
	end
	return "ok"
end

local function setupLeaderstats(player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local coins = Instance.new("StringValue")
	coins.Name = "Coins"
	coins.Value = "0"
	coins.Parent = folder
	local income = Instance.new("StringValue")
	income.Name = "Income"
	income.Value = "0/s"
	income.Parent = folder
	folder.Parent = player
end

function DataService.BuildState(profile)
	local d = profile.data
	local pets = {}
	for _, pet in ipairs(d.pets) do
		table.insert(pets, { uid = pet.uid, id = pet.id })
	end
	return {
		loaded = profile.loaded,
		saveEnabled = profile.saveEnabled,
		coins = d.coins,
		income = Stats.Income(d),
		baseIncome = Stats.BaseIncome(d),
		petBoost = Stats.PetBoost(d),
		bag = table.clone(profile.bag),
		bagMax = Stats.BagMax(d),
		levels = table.clone(d.levels),
		slots = Stats.Slots(d),
		display = table.clone(d.display),
		plot = profile.plot,
		walkSpeed = Stats.WalkSpeed(d),
		homeReadyAt = profile.homeReadyAt,
		pets = pets,
		equipped = table.clone(d.equipped),
		stats = table.clone(d.stats),
		collection = table.clone(d.collection),
	}
end

local function push(player)
	local profile = profiles[player]
	if not profile or not player.Parent then
		return
	end
	local state = DataService.BuildState(profile)
	Net.SendState(player, state)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Coins.Value = Config.Format(state.coins)
		leaderstats.Income.Value = Config.Format(state.income) .. "/s"
	end
	player:SetAttribute("Pets", Stats.EquippedIds(profile.data))
end

function DataService.Get(player)
	return profiles[player]
end

function DataService.All()
	return pairs(profiles)
end

function DataService.OnLoaded(callback)
	table.insert(loadedHooks, callback)
end

function DataService.MarkDirty(player)
	if profiles[player] then
		dirty[player] = true
	end
end

-- Pieces gagnees : entiers seulement, la fraction est reportee au tour suivant
function DataService.AddCoins(player, amount)
	local profile = profiles[player]
	if not profile or not profile.loaded or type(amount) ~= "number" or not (amount > 0) or amount == math.huge then
		return
	end
	local total = amount + profile.coinCarry
	local whole = math.floor(total)
	profile.coinCarry = total - whole
	if whole > 0 then
		profile.data.coins += whole
		profile.data.stats.coinsEarned += whole
		DataService.MarkDirty(player)
	end
end

function DataService.TrySpend(player, cost)
	local profile = profiles[player]
	if not profile or not profile.loaded or profile.data.coins < cost then
		return false
	end
	profile.data.coins -= cost
	DataService.MarkDirty(player)
	return true
end

function DataService.Save(player)
	local profile = profiles[player]
	return profile ~= nil and profile.loaded and save(profile, false) == "ok"
end

local function onLoaded(profile, record, err)
	local player = profile.player
	local isNew = false
	if record and type(record.data) == "table" and num(record.data.v, 0) > SCHEMA_VERSION then
		-- donnees d'une version plus recente du jeu : on ne les ecrase pas
		warn(("[TideRush] donnees de %s en version %s : session sans sauvegarde"):format(player.Name, tostring(record.data.v)))
		releaseLock(profile)
		record = nil
	end
	if record then
		isNew = record.data == nil
		profile.data = DataService._Sanitize(record.data)
		profile.saveEnabled = true
	else
		warn(("[TideRush] donnees de %s non chargees (%s) : cette session ne sauvegardera pas"):format(player.Name, tostring(err)))
	end
	profile.loaded = true
	player:SetAttribute("Loaded", true)
	for _, hook in ipairs(loadedHooks) do
		task.spawn(hook, player, profile)
	end
	if not profile.saveEnabled then
		Net.Notify(player, "saveOff", { text = "Your progress can't be saved right now. Rejoin later to keep it." })
	elseif isNew then
		Net.Notify(player, "welcome", { text = "Welcome to Tide Rush! Grab treasures and beat the wave." })
	else
		Net.Notify(player, "welcome", { text = "Welcome back!" })
	end
	DataService.MarkDirty(player)
end

-- Cree le profil tout de suite, charge les donnees en tache de fond
function DataService.Track(player)
	local existing = profiles[player]
	if existing then
		return existing
	end
	local profile = {
		player = player,
		key = KEY_PREFIX .. player.UserId,
		token = HttpService:GenerateGUID(false),
		data = DataService._Sanitize(nil),
		loaded = false,
		saveEnabled = false,
		saving = false,
		released = false,
		leaving = false,
		bag = {},
		plot = 0,
		homeReadyAt = 0,
		coinCarry = 0,
		sweptUntil = 0,
	}
	profiles[player] = profile
	setupLeaderstats(player)
	pendingLoads += 1
	task.defer(function()
		local ok, err = pcall(function()
			local record, loadErr = loadRecord(profile)
			if profile.leaving then
				-- parti pendant le chargement : on rend le verrou, rien d'autre
				if record then
					releaseLock(profile)
				end
				return
			end
			onLoaded(profile, record, loadErr)
		end)
		pendingLoads -= 1
		if not ok then
			warn(("[TideRush] chargement de %s interrompu : %s"):format(player.Name, tostring(err)))
		end
	end)
	return profile
end

-- Depart du joueur : derniere sauvegarde (reessayee) + verrou rendu. Peut attendre le DataStore.
function DataService.Release(player)
	local profile = profiles[player]
	if not profile or profile.leaving then
		return
	end
	profile.leaving = true
	dirty[player] = nil
	if profile.loaded then
		for attempt = 1, FINAL_SAVE_TRIES do
			if save(profile, true) ~= "error" or attempt == FINAL_SAVE_TRIES then
				break
			end
			task.wait(math.min(2 ^ attempt, 4))
		end
	end
	profiles[player] = nil
end

-- Un autre serveur veut ce joueur : on sauvegarde, on rend le verrou, on le deconnecte d'ici
local function onReleaseRequest(message)
	local key = message.Data
	for player, profile in pairs(profiles) do
		if profile.key == key and profile.loaded and not profile.leaving then
			task.spawn(function()
				DataService.Release(player)
				if player.Parent then
					player:Kick(KICK_MESSAGE)
				end
			end)
		end
	end
end

local function flushLoop()
	while true do
		task.wait(FLUSH_EVERY)
		for player in pairs(dirty) do
			dirty[player] = nil
			local ok, err = pcall(push, player)
			if not ok then
				warn("[TideRush] envoi d'etat : " .. tostring(err))
			end
		end
	end
end

local function autosaveLoop()
	while true do
		task.wait(AUTOSAVE_EVERY)
		local list = {}
		for _, profile in pairs(profiles) do
			table.insert(list, profile)
		end
		for _, profile in ipairs(list) do
			if profile.loaded and profile.saveEnabled and not profile.leaving then
				task.spawn(save, profile, false)
				task.wait(AUTOSAVE_STAGGER)
			end
		end
	end
end

local function onClose()
	for player in pairs(table.clone(profiles)) do
		task.spawn(DataService.Release, player)
	end
	local deadline = os.clock() + SHUTDOWN_TIMEOUT
	while (next(profiles) ~= nil or pendingLoads > 0) and os.clock() < deadline do
		task.wait(0.1)
	end
end

function DataService.Start()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[TideRush] DataStore indisponible : " .. tostring(result))
	end
	-- SubscribeAsync peut attendre longtemps (place non publiee) : jamais dans le fil de demarrage
	task.spawn(function()
		local subscribed, subErr = pcall(function()
			MessagingService:SubscribeAsync(RELEASE_TOPIC, onReleaseRequest)
		end)
		if not subscribed and not RunService:IsStudio() then
			warn("[TideRush] abonnement aux demandes de liberation impossible : " .. tostring(subErr))
		end
	end)
	Net.Handle("GetState", function(player)
		local profile = profiles[player]
		return profile and DataService.BuildState(profile) or nil, Net.GetWave()
	end, function()
		return nil, Net.GetWave()
	end)
	task.spawn(flushLoop)
	task.spawn(autosaveLoop)
	game:BindToClose(onClose)
end

return DataService
