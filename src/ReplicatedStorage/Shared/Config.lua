-- Ride the Tsunami (Reef Keepers). Configuration partagee (serveur + client).
-- Tout l'equilibrage du jeu est ici : creatures, croissance, marees, mutations, zones, vague,
-- ameliorations, compagnons. Le client lit les memes chiffres (probabilites affichees).

local Config = {}

Config.GameName = "Ride the Tsunami"

Config.Rarities = {
	Common = { order = 1, label = "Common", color = Color3.fromRGB(215, 215, 215) },
	Uncommon = { order = 2, label = "Uncommon", color = Color3.fromRGB(95, 225, 125) },
	Rare = { order = 3, label = "Rare", color = Color3.fromRGB(75, 165, 255) },
	Epic = { order = 4, label = "Epic", color = Color3.fromRGB(185, 95, 255) },
	Legendary = { order = 5, label = "Legendary", color = Color3.fromRGB(255, 195, 45) },
}

-- Creatures (GDD v3, 4.2) : revenu par seconde au premier stade, sans mutation
Config.Creatures = {
	GhostCrab = { name = "Ghost Crab", rarity = "Common", income = 1 },
	CushionStar = { name = "Cushion Star", rarity = "Common", income = 2 },
	Lionfish = { name = "Lionfish", rarity = "Uncommon", income = 6 },
	HawksbillTurtle = { name = "Hawksbill Turtle", rarity = "Uncommon", income = 10 },
	BlueRingedOctopus = { name = "Blue-ringed Octopus", rarity = "Rare", income = 30 },
	LeopardRay = { name = "Leopard Ray", rarity = "Rare", income = 50 },
	GiantPacificOctopus = { name = "Giant Pacific Octopus", rarity = "Epic", income = 150 },
	LionsManeJelly = { name = "Lion's Mane Jelly", rarity = "Epic", income = 250 },
	MantaRay = { name = "Manta Ray", rarity = "Legendary", income = 800 },
	WhaleShark = { name = "Whale Shark", rarity = "Legendary", income = 1500 },
}

-- Anciens ids -> especes actuelles : tresors v1 et especes du GDD v1/v2.
-- Sert a la migration des donnees et aux modeles de repli tant que Assets.Creatures manque.
Config.LegacyItemToCreature = {
	Shell = "GhostCrab", PebbleCrab = "GhostCrab",
	Starfish = "CushionStar", SandStar = "CushionStar",
	Pearl = "Lionfish", BubblePuffer = "Lionfish",
	BlueCrab = "HawksbillTurtle", ReefHatchling = "HawksbillTurtle",
	CoralCrown = "BlueRingedOctopus", LanternSeahorse = "BlueRingedOctopus",
	GoldenCrab = "LeopardRay", CoralRay = "LeopardRay",
	TreasureChest = "GiantPacificOctopus", InkOctopus = "GiantPacificOctopus",
	AbyssCrystal = "LionsManeJelly", MoonJelly = "LionsManeJelly",
	MoonPearl = "MantaRay", StarWhaleCalf = "MantaRay",
	TideHeart = "WhaleShark", AbyssSerpent = "WhaleShark",
}

-- Stades de croissance (GDD v3, 4.3) : echelle appliquee par le client, multiplicateur de revenu
Config.Stages = {
	{ id = "Juvenile", scale = 0.6, mult = 1 },
	{ id = "Adult", scale = 0.8, mult = 2 },
	{ id = "Elder", scale = 1.0, mult = 4 },
	{ id = "Titan", scale = 1.5, mult = 8 },
}
-- Minutes cumulees depuis le depot pour atteindre Adult, Elder, Titan
Config.GrowthMinutes = {
	Common = { 3, 15, 60 },
	Uncommon = { 5, 30, 120 },
	Rare = { 10, 60, 240 },
	Epic = { 20, 120, 480 },
	Legendary = { 30, 240, 1200 },
}

-- Mutations (GDD 4.4) : tirees a l'apparition sur la plage, une seule par creature
Config.Mutations = {
	Golden = { mult = 3, label = "Golden" },
	Glow = { mult = 2, label = "Glow" },
	Storm = { mult = 5, label = "Storm" },
	Rainbow = { mult = 10, label = "Rainbow" },
}
-- Chances en % par creature apparue, selon la maree. Affichees au joueur.
-- Phase 1 : Normal + Golden seulement (Night, Storm, Rainbow en Phase 2).
Config.Tides = {
	Normal = { label = "Normal Tide", odds = { { "Golden", 0.5 } } },
	Golden = { label = "Golden Tide", odds = { { "Golden", 30 } } },
}
-- Calendrier fixe : tous les `every` cycles, une maree speciale prise dans `rotation`
Config.TideSchedule = { every = 8, rotation = { "Golden" } }
-- Variantes du Reef Codex (Normal = sans mutation)
Config.CodexVariants = { "Normal", "Golden" }
Config.Codex = { newEntryIncomeMult = 50, speciesBonus = 0.05 }

-- Revenu hors ligne : part du revenu, plafond, duree minimale pour l'ecran "Pendant ton absence"
Config.Offline = { incomeRate = 0.5, maxHours = 8, minSeconds = 60 }

-- Palier visuel du lagon (attribut LagoonTier 1..5) : revenu/s minimal de chaque palier (E, GDD v3)
Config.LagoonTiers = { 0, 30, 200, 5000, 100000 }

-- Intro d'un nouveau joueur (GDD 1 ter). Positions sur la plage devant SON lagon :
-- out = studs au-dela du bord de la crique, side = decalage lateral (vers la droite en regardant la mer).
-- La vague d'intro vient de la mer en face de son lagon et s'arrete au bord de la crique.
Config.Intro = {
	waveDelay = 18, -- s entre le chargement et l'alerte de la vague d'intro
	warningTime = 2,
	travel = 9, -- s de trajet de la vague d'intro
	recedeTime = 2.5,
	creatures = {
		{ species = "GhostCrab", mutation = "", side = 0, out = 8 },
		{ species = "CushionStar", mutation = "", side = -12, out = 20 },
		{ species = "GhostCrab", mutation = "", side = 12, out = 26 },
		{ species = "GhostCrab", mutation = "", side = -4, out = 34 },
		{ species = "CushionStar", mutation = "Golden", side = 8, out = 48 },
	},
	-- decalage d'angle de la plage d'intro par rapport a l'axe crique -> lagon (0 : en face de la breche du lagon)
	angleOffset = 0,
	goldenTide = "Golden", -- deuxieme maree du joueur
	goldenCount = 5, -- creatures personnelles de cette maree, dont au moins une mutee
}

-- Monture (GDD 4.6) : especes montables a partir de minStage, vitesse x speedMult[stade]
Config.Mount = {
	species = { HawksbillTurtle = true, LeopardRay = true, MantaRay = true, WhaleShark = true },
	minStage = "Elder",
	speedMult = { Elder = 1.3, Titan = 1.6 },
	giantSurfs = true, -- au dernier stade (Titan), jamais prise par la vague : elle la surfe
}

-- Vol entre lagons (GDD 4.7). Fenetre = alerte + vague ; retour possible jusqu'a la fin du reflux.
Config.Steal = {
	grabHold = 1.0, -- s de maintien pres du bassin
	grabRange = 8, -- studs entre le voleur et le centre du bassin
	moveTolerance = 2.5, -- studs de mouvement permis pendant le maintien
	touchRange = 5, -- studs : le proprietaire "touche" le voleur
	pushStrength = 40, -- recul du voleur touche (joue par le client)
	carrySpeedMult = 0.8,
	maxCarry = 1,
	lockDurationWaves = 1,
	lockCooldownCycles = 4,
	protectAfterStolenWaves = 2,
	maxStolenPer10Min = 3,
	newbieMinutes = 15, -- de jeu cumule
	newbieMinCreatures = 4,
}

-- Maree Royale (GDD 4.8) : a chaque maree speciale
Config.Royal = {
	onSpecialTides = true,
	rewardMinutes = { 5, 3, 2 }, -- pieces = minutes de revenu du top 3
	royalMutation = "Golden",
}

-- Boutique (GDD 9). id = 0 : produit pas encore cree sur Roblox, desactive.
Config.Shop = {
	Passes = {
		FastGrowth = { id = 0, price = 299, growth = 2 },
		BigNet = { id = 0, price = 149, pickupMult = 1.5 },
		VIPRider = { id = 0, price = 399, coinBonus = 0.10, mountSpeedBonus = 0.10 },
	},
	-- aleatoire, probabilites affichees ; cache si ArePaidRandomItemsRestricted
	TideEgg = { id = 0, price = 79, odds = { { "GhostCrab", 50 }, { "CushionStar", 35 }, { "HawksbillTurtle", 15 } }, goldenChance = 10 },
	-- choix direct, montre a la place du Tide Egg si l'aleatoire est restreint
	PickCreature = { id = 0, price = 149, species = { "GhostCrab", "CushionStar", "HawksbillTurtle" } },
}

-- Verification serveur de la vitesse reelle (anti speed hack) : distance horizontale sur `window` s
Config.SpeedGuard = { window = 1.0, tolerance = 1.35, slack = 10, surfSpeed = 60 }

-- Anciens tresors : gardes seulement pour les modeles de repli (Assets.Items) et l'ancien client
Config.Items = {
	Shell = { name = "Seashell", rarity = "Common", income = 1 },
	Starfish = { name = "Starfish", rarity = "Common", income = 2 },
	Pearl = { name = "Pearl", rarity = "Uncommon", income = 6 },
	BlueCrab = { name = "Blue Crab", rarity = "Uncommon", income = 10 },
	CoralCrown = { name = "Coral Crown", rarity = "Rare", income = 30 },
	GoldenCrab = { name = "Golden Crab", rarity = "Rare", income = 50 },
	TreasureChest = { name = "Treasure Chest", rarity = "Epic", income = 150 },
	AbyssCrystal = { name = "Abyss Crystal", rarity = "Epic", income = 250 },
	MoonPearl = { name = "Moon Pearl", rarity = "Legendary", income = 800 },
	TideHeart = { name = "Tide Heart", rarity = "Legendary", income = 1500 },
}

-- Creature relachee (lagon plein) : revenu bebe (mutation comprise) x ce multiplicateur
Config.SellMultiplier = 20

-- Ile ouverte (GDD 3 bis, version de lancement). Centre de l'ile et de la crique = Config.Island.center.
-- Dans la crique (coveRadius) : les 8 lagons, a l'abri de la vague, pas de capture.
-- La vague traverse l'ile dans une direction par cycle (N/E/S/W), jamais deux fois de suite la meme.
Config.Island = {
	center = Vector3.new(0, 0, 0),
	size = 600,
	seaMargin = 30, -- la vague part et finit a size/2 + seaMargin du centre
	coveRadius = 70,
	waveDirections = { "N", "E", "S", "W" },
	noRepeatDirection = true,
	seaY = 0, -- niveau du sable au bord de l'eau
	-- apparitions seulement sur la plage : materiaux de C (Sand sec, Mud recolore en sable mouille),
	-- et sous la hauteur de la vague (sinon une creature serait hors de danger)
	spawnMaterials = { "Sand", "Mud" },
	spawnYMin = -2,
	spawnYMax = 16,
	towerRadius = 16, -- pas d'apparition si pres d'une tour (Center ; PlatformRadius + 4 si plus grand)
}
-- Direction dans laquelle AVANCE la vague "venue du" nord, de l'est... (N = venue de -Z, avance vers +Z)
Config.WaveTravel = {
	N = Vector3.new(0, 0, 1),
	S = Vector3.new(0, 0, -1),
	E = Vector3.new(-1, 0, 0),
	W = Vector3.new(1, 0, 0),
}

-- Maree extreme (GDD 6 bis, P1-37) : environ 1 fois par heure, pendant le calme d'un cycle, la mer se retire
-- plus loin et revele le recif (Map.Reef, attributs Center + Radius, construit par C ; sinon `reef` ci-dessous).
-- Des creatures rares y apparaissent pendant revealTime secondes, puis la mer revient et les reprend.
-- Annoncee seulement par un signe (cote client, d'apres wave.extreme). Chiffres de depart [a caler par E].
Config.ExtremeTide = {
	everyCycles = 58, -- un cycle dure environ 1 min : 58 cycles, environ 1 h
	offset = 29, -- cycle % everyCycles == offset (jamais en meme temps qu'une maree speciale tous les 8)
	revealDelay = 5, -- s apres le debut du calme : la mer se retire
	revealTime = 25, -- s pendant lesquelles le recif est decouvert (fini avant l'alerte)
	count = 6,
	creatures = { { "HawksbillTurtle", 70 }, { "Lionfish", 30 } },
	mutationTide = "Golden", -- chances de mutation des creatures du recif
	reef = { center = Vector3.new(0, 0, 335), radius = 30 }, -- repli : recif au sud (+Z)
}

-- Anneaux de rarete autour de la crique (distance horizontale au centre). La plage se remplit au debut
-- du calme, puis se recharge toutes les spawnEvery secondes pendant le calme ; la vague emporte tout.
-- maxItems et spawnEvery : premiers reglages selon la surface de chaque anneau [a caler par E].
Config.Rings = {
	{ name = "Cove Beach", rarity = "Common", rMin = 70, rMax = 150, maxItems = 18, spawnEvery = 2, creatures = { { "GhostCrab", 100 } } },
	{ name = "Dunes", rarity = "Common", rMin = 150, rMax = 225, maxItems = 16, spawnEvery = 2.5, creatures = { { "GhostCrab", 40 }, { "CushionStar", 60 } } },
	{ name = "Outer Shore", rarity = "Uncommon", rMin = 225, rMax = 300, maxItems = 12, spawnEvery = 3.5, creatures = { { "CushionStar", 60 }, { "HawksbillTurtle", 40 } } },
}

Config.HubSpawn = Vector3.new(0, 1, 96)

-- La vague
Config.Wave = {
	calmTime = 35, -- secondes de calme
	warningTime = 7, -- alerte avant la vague
	speed = 46, -- studs par seconde ; trajet de -(size/2 + seaMargin) a +(size/2 + seaMargin) sur son axe
	height = 30, -- hauteur : plateformes des tours a height + 4 (34), construites par C d'apres cette valeur
	thickness = 40,
	recedeTime = 2.5,
	caughtDelay = 0.8, -- secondes entre la prise par la vague et le retour a la base
}

-- Ameliorations (achetees avec les pieces du jeu)
Config.UpgradeOrder = { "Speed", "Bag", "Slots" }
Config.Upgrades = {
	-- icon = "" : pas d'emoji (DIRECTION_V2), l'interface de B fournit ses icones d'apres `key`
	Speed = { key = "speed", label = "Speed", icon = "", unit = "", base = 16, step = 2, maxLevel = 12, baseCost = 50, costMult = 2.0 },
	Bag = { key = "bag", label = "Bag", icon = "", unit = " slots", base = 2, step = 1, maxLevel = 8, baseCost = 75, costMult = 2.2 },
	Slots = { key = "slots", label = "Pools", icon = "", unit = " pools", base = 5, step = 1, maxLevel = 5, baseCost = 200, costMult = 3.0 },
}
Config.MaxSlots = 10

-- Compagnons marins (bonus de revenus) et oeufs (achetes avec les pieces du jeu uniquement)
Config.Pets = {
	CrabBuddy = { name = "Crab Buddy", rarity = "Common", boost = 0.10, color = Color3.fromRGB(255, 110, 90) },
	Turtle = { name = "Sea Turtle", rarity = "Uncommon", boost = 0.20, color = Color3.fromRGB(90, 200, 120) },
	Seahorse = { name = "Seahorse", rarity = "Rare", boost = 0.35, color = Color3.fromRGB(255, 190, 80) },
	Dolphin = { name = "Dolphin", rarity = "Epic", boost = 0.60, color = Color3.fromRGB(110, 170, 255) },
	Octopus = { name = "Octopus", rarity = "Epic", boost = 1.00, color = Color3.fromRGB(200, 110, 255) },
	GoldenWhale = { name = "Golden Whale", rarity = "Legendary", boost = 2.00, color = Color3.fromRGB(255, 205, 60) },
	KrakenJr = { name = "Kraken Jr.", rarity = "Legendary", boost = 4.00, color = Color3.fromRGB(60, 230, 210) },
}
Config.Eggs = {
	{ id = "ShellEgg", name = "Shell Egg", cost = 2500, color = Color3.fromRGB(255, 226, 190), odds = { { "CrabBuddy", 50 }, { "Turtle", 30 }, { "Seahorse", 15 }, { "Dolphin", 5 } } },
	{ id = "CoralEgg", name = "Coral Egg", cost = 60000, color = Color3.fromRGB(255, 132, 162), odds = { { "Turtle", 45 }, { "Seahorse", 30 }, { "Dolphin", 18 }, { "Octopus", 6 }, { "GoldenWhale", 1 } } },
	{ id = "AbyssEgg", name = "Abyss Egg", cost = 1500000, color = Color3.fromRGB(125, 95, 225), odds = { { "Dolphin", 45 }, { "Octopus", 35 }, { "GoldenWhale", 15 }, { "KrakenJr", 5 } } },
}
Config.MaxEquippedPets = 3
Config.MaxPetInventory = 40

Config.PickupRadius = 6
Config.CreatureSpacing = 7 -- ecart minimal entre deux creatures au sol (studs)
Config.HomeCooldown = 20
Config.MaxPlayersPerServer = 8

function Config.GetUpgradeValue(kind: string, level: number): number
	local u = Config.Upgrades[kind]
	return u.base + u.step * level
end

function Config.GetUpgradeCost(kind: string, level: number): number
	local u = Config.Upgrades[kind]
	return math.floor(u.baseCost * u.costMult ^ level)
end

function Config.GetEgg(id: string)
	for _, egg in ipairs(Config.Eggs) do
		if egg.id == id then
			return egg
		end
	end
	return nil
end

-- Stade (1..4) d'une creature deposee a `born`, et heure du stade suivant (0 si dernier stade).
-- Fonction pure, partagee : le client calcule la meme progression que le serveur.
-- speed = vitesse de croissance (2 avec FastGrowth), 1 par defaut.
function Config.StageAt(rarity: string, born: number, now: number, speed: number?): (number, number)
	local minutes = Config.GrowthMinutes[rarity] or Config.GrowthMinutes.Common
	local rate = speed or 1
	local age = math.max(0, now - born) * rate
	for i, threshold in ipairs(minutes) do
		local at = threshold * 60
		if age < at then
			return i, born + at / rate
		end
	end
	return #minutes + 1, 0
end

function Config.StageIndex(id: string): number
	for i, stage in ipairs(Config.Stages) do
		if stage.id == id then
			return i
		end
	end
	return #Config.Stages
end

-- Type de maree d'un cycle (1, 2, 3...) : calendrier deterministe
function Config.TideFor(cycle: number): string
	local schedule = Config.TideSchedule
	if cycle > 0 and cycle % schedule.every == 0 then
		local n = cycle // schedule.every
		return schedule.rotation[(n - 1) % #schedule.rotation + 1]
	end
	return "Normal"
end

function Config.IsExtremeCycle(cycle: number): boolean
	local e = Config.ExtremeTide
	return cycle > 0 and cycle % e.everyCycles == e.offset
end

-- Prochaine maree speciale apres le cycle donne : { tide, cycle }
function Config.NextSpecial(cycle: number)
	local every = Config.TideSchedule.every
	local nextCycle = (cycle // every + 1) * every
	return { tide = Config.TideFor(nextCycle), cycle = nextCycle }
end

-- Distance horizontale au centre de l'ile
function Config.IslandDistance(position: Vector3): number
	local c = Config.Island.center
	return Vector2.new(position.X - c.X, position.Z - c.Z).Magnitude
end

function Config.InCove(position: Vector3): boolean
	return Config.IslandDistance(position) <= Config.Island.coveRadius
end

-- Index d'anneau (1..n) pour une position, 0 = crique ou hors anneaux
function Config.RingAt(position: Vector3): number
	local r = Config.IslandDistance(position)
	for i, ring in ipairs(Config.Rings) do
		if r >= ring.rMin and r < ring.rMax then
			return i
		end
	end
	return 0
end

-- Position du front de la vague sur son axe : d = (p - centre) . dir. startD/endD/speed du wave si presents.
function Config.WaveFrontD(wave, t: number): number
	local reach = Config.Island.size / 2 + Config.Island.seaMargin
	local startD = wave.startD or -reach
	local endD = wave.endD or reach
	return math.min(endD, startD + (wave.speed or Config.Wave.speed) * (t - wave.startTime))
end

function Config.WaveAxis(wave, position: Vector3): number
	local c = Config.Island.center
	return (position.X - c.X) * wave.dir.X + (position.Z - c.Z) * wave.dir.Z
end

local function trimZeros(s: string): string
	if string.find(s, "%.") then
		s = (string.gsub(s, "0+$", ""))
		s = (string.gsub(s, "%.$", ""))
	end
	return s
end

-- 1234 -> 1.23K, 5600000 -> 5.6M
function Config.Format(n: number): string
	n = math.floor(n)
	local a = math.abs(n)
	local units = { { 1e15, "Q" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }
	for _, u in ipairs(units) do
		if a >= u[1] then
			local v = n / u[1]
			local s
			-- on tronque (pas d'arrondi) pour eviter "1000K"
			if math.abs(v) >= 100 then
				s = tostring(math.floor(v))
			elseif math.abs(v) >= 10 then
				s = trimZeros(string.format("%.1f", math.floor(v * 10) / 10))
			else
				s = trimZeros(string.format("%.2f", math.floor(v * 100) / 100))
			end
			return s .. u[2]
		end
	end
	return tostring(n)
end

return Config
