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
local SCHEMA_VERSION = 2
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

local STAT_KEYS = {
	"pickups", "deposited", "released", "caught", "wavesSurvived", "eggsHatched", "upgradesBought", "coinsEarned",
	"mutationsFound", "offlineCoins",
}
local INTRO_NAMES = { [0] = "intro", [1] = "golden", [2] = "done" }
local MAX_RECEIPTS = 100

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
		pools = {}, -- [slot] = { uid, id, mut, born } | false
		creatureSeq = 0,
		codex = {}, -- [species] = { [variant] = true }
		introStep = 0, -- 0 intro a jouer, 1 maree Golden personnelle a venir, 2 fini
		playTime = 0, -- secondes de jeu cumulees (protection debutant)
		lockReadyAt = 0, -- heure Unix ou le verrou gratuit redevient possible
		protectedUntil = 0, -- heure Unix de fin de protection apres un vol subi
		stolenAt = {}, -- heures des vols subis recents (max 3 / 10 min)
		receipts = {}, -- PurchaseId des achats deja accordes (les plus recents)
		pets = {},
		equipped = {},
		petSeq = 0,
		stats = stats,
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

local function sanitizeLevels(d, raw)
	if type(raw.levels) ~= "table" then
		return
	end
	for kind, def in pairs(Config.Upgrades) do
		local level = math.floor(num(raw.levels[kind], 0, 0))
		if level > def.maxLevel then
			keepLegacy(d, "levels", { kind = kind, level = level })
			level = def.maxLevel
		end
		d.levels[kind] = level
	end
end

local function sanitizePets(d, raw)
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
end

local function sanitizeStats(d, raw)
	if type(raw.stats) ~= "table" then
		return
	end
	for _, key in ipairs(STAT_KEYS) do
		d.stats[key] = math.floor(num(raw.stats[key], 0, 0))
	end
end

-- Une creature deposee valide : { uid, id, mut, born }, sinon nil
local function sanitizeCreature(raw, now)
	if type(raw) ~= "table" or type(raw.uid) ~= "string" or type(raw.id) ~= "string" or not Config.Creatures[raw.id] then
		return nil
	end
	local mut = raw.mut
	if mut ~= "" and not Config.Mutations[mut] then
		return nil
	end
	local born = num(raw.born, nil, 0, now) -- jamais dans le futur (horloges de serveurs differentes)
	if not born then
		return nil
	end
	return { uid = raw.uid, id = raw.id, mut = mut, born = math.floor(born), royal = raw.royal == true or nil }
end

-- Donnees v1 (trésors) : on repart de zero, l'ancien contenu est range dans legacy.v1
local function migrateV1(d, raw)
	d.legacy.v1 = deepCopy({
		coins = raw.coins,
		levels = raw.levels,
		display = raw.display,
		collection = raw.collection,
	})
	sanitizePets(d, raw)
	sanitizeStats(d, raw)
	if type(raw.stats) == "table" then
		d.stats.released = math.floor(num(raw.stats.sold, 0, 0))
	end
	d.firstJoin = num(raw.firstJoin, d.firstJoin, 0)
	d.lastSeen = os.time() -- pas de revenu hors ligne calcule sur l'ancien jeu
end

-- Valide et complete des donnees lues (DataStore = donnees externes, jamais fiables)
function DataService._Sanitize(raw)
	local d = defaultData()
	if type(raw) ~= "table" then
		d.pools = Stats.NormalizePools(d)
		return d
	end
	if type(raw.legacy) == "table" then
		d.legacy = deepCopy(raw.legacy)
	end
	if num(raw.v, 1) < SCHEMA_VERSION then
		migrateV1(d, raw)
		d.pools = Stats.NormalizePools(d)
		return d
	end

	local now = os.time()
	d.coins = math.floor(num(raw.coins, 0, 0))
	sanitizeLevels(d, raw)
	sanitizePets(d, raw)
	sanitizeStats(d, raw)

	local slots = Stats.Slots(d)
	local seenUid, maxSeq = {}, 0
	local rawPools = type(raw.pools) == "table" and raw.pools or {}
	for slot = 1, math.max(slots, #rawPools) do
		local value = rawPools[slot]
		if value then
			local creature = sanitizeCreature(value, now)
			if creature and not seenUid[creature.uid] and slot <= slots then
				seenUid[creature.uid] = true
				d.pools[slot] = creature
				local n = tonumber(creature.uid)
				if n and n > maxSeq then
					maxSeq = n
				end
			else
				keepLegacy(d, "pools", deepCopy(value))
			end
		end
	end
	d.pools = Stats.NormalizePools(d)
	d.creatureSeq = math.max(math.floor(num(raw.creatureSeq, 0, 0)), maxSeq)

	if type(raw.codex) == "table" then
		for species, variants in pairs(raw.codex) do
			if type(species) == "string" and Config.Creatures[species] and type(variants) == "table" then
				for variant, value in pairs(variants) do
					if value == true and (variant == "Normal" or Config.Mutations[variant]) then
						d.codex[species] = d.codex[species] or {}
						d.codex[species][variant] = true
					end
				end
			else
				keepLegacy(d, "codex", { species = species, variants = deepCopy(variants) })
			end
		end
	end
	d.introStep = math.floor(num(raw.introStep, 0, 0, 2))
	d.playTime = math.floor(num(raw.playTime, 0, 0))
	d.lockReadyAt = num(raw.lockReadyAt, 0, 0, now + 3600)
	d.protectedUntil = num(raw.protectedUntil, 0, 0, now + 3600)
	if type(raw.stolenAt) == "table" then
		for _, t in ipairs(raw.stolenAt) do
			local at = num(t, nil, now - 600, now)
			if at and type(t) == "number" and t >= now - 600 then
				table.insert(d.stolenAt, at)
			end
		end
	end
	if type(raw.receipts) == "table" then
		for _, id in ipairs(raw.receipts) do
			if type(id) == "string" and #d.receipts < MAX_RECEIPTS then
				table.insert(d.receipts, id)
			end
		end
	end
	d.firstJoin = num(raw.firstJoin, d.firstJoin, 0)
	d.lastSeen = num(raw.lastSeen, d.lastSeen, 0, now)
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
	snapshot._growth = nil -- champs passagers (gamepass), recalcules a chaque connexion
	snapshot._passBonus = nil
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

-- Creatures qu'un depot ne doit jamais remplacer : la monture, celles qu'un voleur porte
function DataService.LockedUids(profile)
	local locked = {}
	if profile.mountUid ~= "" then
		locked[profile.mountUid] = true
	end
	for uid in pairs(profile.carriedOut) do
		locked[uid] = true
	end
	return locked
end

-- Creature telle que le client la recoit (contrat v2.1)
function DataService.CreatureView(profile, creature, now)
	local speed = Stats.GrowthSpeed(profile.data)
	local stage, nextStageAt = Stats.Stage(creature, now, speed)
	return {
		uid = creature.uid,
		species = creature.id,
		mutation = creature.mut,
		born = creature.born,
		stage = stage,
		nextStageAt = nextStageAt,
		income = Stats.CreatureIncome(creature, now, speed),
		royal = creature.royal == true,
		mounted = profile.mountUid == creature.uid,
		carried = profile.carriedOut[creature.uid] ~= nil,
	}
end

function DataService.BuildState(profile)
	local d = profile.data
	local now = os.time()
	local pets = {}
	for _, pet in ipairs(d.pets) do
		table.insert(pets, { uid = pet.uid, id = pet.id })
	end
	local pools = {}
	for slot, creature in ipairs(d.pools) do
		pools[slot] = creature and DataService.CreatureView(profile, creature, now) or false
	end
	local bag = {}
	for i, entry in ipairs(profile.bag) do
		bag[i] = { species = entry.species, mutation = entry.mutation }
	end
	local codex = {}
	for species, variants in pairs(d.codex) do
		codex[species] = table.clone(variants)
	end
	local income = Stats.Income(d, now)
	return {
		loaded = profile.loaded,
		saveEnabled = profile.saveEnabled,
		serverNow = workspace:GetServerTimeNow(),
		coins = d.coins,
		income = income,
		baseIncome = Stats.BaseIncome(d, now),
		petBoost = Stats.PetBoost(d),
		codexBonus = Stats.CodexBonus(d),
		bag = bag,
		bagMax = Stats.BagMax(d),
		levels = table.clone(d.levels),
		slots = Stats.Slots(d),
		pools = pools,
		plot = profile.plot,
		lagoonTier = Stats.LagoonTier(income),
		walkSpeed = Stats.WalkSpeed(d),
		homeReadyAt = profile.homeReadyAt,
		intro = INTRO_NAMES[d.introStep] or "done",
		newbie = Stats.IsNewbie(d),
		playTime = math.floor(d.playTime),
		mount = profile.mountUid,
		carrying = profile.carrying and {
			species = profile.carrying.creature.id,
			mutation = profile.carrying.creature.mut,
			victim = profile.carrying.victim.UserId,
			victimName = profile.carrying.victim.DisplayName,
		} or false,
		lockActive = profile.lockActive,
		lockReadyAt = d.lockReadyAt,
		shield = profile.shield,
		protectedUntil = d.protectedUntil,
		revenge = profile.revenge and { userId = profile.revenge.userId, name = profile.revenge.name } or false,
		crown = profile.crown,
		passes = {
			FastGrowth = profile.passes.FastGrowth == true,
			BigNet = profile.passes.BigNet == true,
			VIPRider = profile.passes.VIPRider == true,
		},
		shop = { randomAllowed = profile.randomAllowed },
		codex = codex,
		codexCount = Stats.CodexCount(d),
		codexTotal = Stats.CodexTotal(),
		pets = pets,
		equipped = table.clone(d.equipped),
		stats = table.clone(d.stats),
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
	local carried = {}
	for i, entry in ipairs(profile.bag) do
		carried[i] = entry.species .. ":" .. entry.mutation
	end
	player:SetAttribute("Bag", table.concat(carried, ","))
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

-- Revenu hors ligne (GDD 5.1) : part du revenu depuis lastSeen, croissance comprise, plafonne
local function payOffline(profile)
	local d = profile.data
	local now = os.time()
	local seconds = math.min(math.max(0, now - d.lastSeen), Config.Offline.maxHours * 3600)
	if seconds < Config.Offline.minSeconds then
		return
	end
	local coins = math.floor(Stats.IncomeBetween(d, d.lastSeen, d.lastSeen + seconds) * Config.Offline.incomeRate)
	d.lastSeen = now
	if coins <= 0 then
		return
	end
	DataService.AddCoins(profile.player, coins)
	d.stats.offlineCoins += coins
	Net.Notify(profile.player, "offline", {
		seconds = seconds,
		coins = coins,
		text = ("While you were away, your reef earned %s coins."):format(Config.Format(coins)),
	})
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
	if profile.saveEnabled and not isNew then
		payOffline(profile)
	end
	for _, hook in ipairs(loadedHooks) do
		task.spawn(hook, player, profile)
	end
	if not profile.saveEnabled then
		Net.Notify(player, "saveOff", { text = "Your progress can't be saved right now. Rejoin later to keep it." })
	elseif isNew then
		Net.Notify(player, "welcome", { isNew = true, text = "Welcome, Keeper!" })
	else
		Net.Notify(player, "welcome", { isNew = false, text = "Welcome back, Keeper!" })
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
		introActive = false, -- vague d'intro personnelle en cours (IntroService)
		mountUid = "", -- monture active (MountService)
		mountMult = 1,
		carryMult = 1, -- ralenti quand il porte une creature volee (StealService)
		carriedOut = {}, -- [uid] = voleur : creatures de ce joueur portees par un voleur
		passes = {}, -- [nom] = true (ShopService)
		randomAllowed = false, -- achat aleatoire permis (PolicyService), faux tant que pas verifie
		carrying = nil, -- { creature, victim, slot } : creature volee portee (StealService)
		lockCycle = nil, -- cycle dont la fenetre est verrouillee (LagoonService)
		lockActive = false,
		shield = "",
		revenge = nil, -- { userId, name, cycle } (LagoonService)
		crown = 0, -- Maree Royale (RoyalService)
		surfing = false, -- sur une Giant pendant la vague (MountService)
		movedByServerAt = 0, -- os.clock du dernier teleport serveur (verification de vitesse)
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
		return profile and DataService.BuildState(profile) or nil, Net.GetWaveFor(player)
	end, function(player)
		return nil, Net.GetWaveFor(player)
	end)
	task.spawn(flushLoop)
	task.spawn(autosaveLoop)
	game:BindToClose(onClose)
end

return DataService
