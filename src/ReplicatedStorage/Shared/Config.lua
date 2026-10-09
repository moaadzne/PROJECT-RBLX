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

-- Creatures (GDD 4.2) : revenu par seconde d'un bebe sans mutation
Config.Creatures = {
	PebbleCrab = { name = "Pebble Crab", rarity = "Common", income = 1 },
	SandStar = { name = "Sand Star", rarity = "Common", income = 2 },
	BubblePuffer = { name = "Bubble Puffer", rarity = "Uncommon", income = 6 },
	ReefHatchling = { name = "Reef Hatchling", rarity = "Uncommon", income = 10 },
	LanternSeahorse = { name = "Lantern Seahorse", rarity = "Rare", income = 30 },
	CoralRay = { name = "Coral Ray", rarity = "Rare", income = 50 },
	InkOctopus = { name = "Ink Octopus", rarity = "Epic", income = 150 },
	MoonJelly = { name = "Moon Jelly", rarity = "Epic", income = 250 },
	StarWhaleCalf = { name = "Star Whale Calf", rarity = "Legendary", income = 800 },
	AbyssSerpent = { name = "Abyss Serpent", rarity = "Legendary", income = 1500 },
}

-- Anciens tresors -> especes : modeles de repli tant que Assets.Creatures manque
Config.LegacyItemToCreature = {
	Shell = "PebbleCrab", Starfish = "SandStar", Pearl = "BubblePuffer", BlueCrab = "ReefHatchling",
	CoralCrown = "LanternSeahorse", GoldenCrab = "CoralRay", TreasureChest = "InkOctopus",
	AbyssCrystal = "MoonJelly", MoonPearl = "StarWhaleCalf", TideHeart = "AbyssSerpent",
}

-- Stades de croissance (GDD 4.3) : echelle appliquee par le client, multiplicateur de revenu
Config.Stages = {
	{ id = "Baby", scale = 0.6, mult = 1 },
	{ id = "Juvenile", scale = 0.8, mult = 2 },
	{ id = "Adult", scale = 1.0, mult = 4 },
	{ id = "Giant", scale = 1.5, mult = 8 },
}
-- Minutes cumulees depuis le depot pour atteindre Juvenile, Adult, Giant
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

-- Palier visuel du lagon (attribut LagoonTier 1..5) : revenu/s minimal de chaque palier [a caler par E]
Config.LagoonTiers = { 0, 25, 250, 2500, 25000 }

-- Intro d'un nouveau joueur (GDD 1 ter). Positions relatives au centre X de sa base et a BaseLineZ.
Config.Intro = {
	waveDelay = 18, -- s entre le chargement et l'alerte de la vague d'intro
	warningTime = 2,
	startZ = -414, -- 9 s de trajet a Config.Wave.speed
	recedeTime = 2.5,
	creatures = {
		{ species = "PebbleCrab", mutation = "", dx = 0, dz = -10 },
		{ species = "SandStar", mutation = "", dx = -12, dz = -24 },
		{ species = "PebbleCrab", mutation = "", dx = 12, dz = -30 },
		{ species = "PebbleCrab", mutation = "", dx = -4, dz = -38 },
		{ species = "SandStar", mutation = "Golden", dx = 8, dz = -52 },
	},
	goldenTide = "Golden", -- deuxieme maree du joueur
	goldenCount = 5, -- creatures personnelles de cette maree, dont au moins une mutee
}

-- Monture (GDD 4.6) : especes montables a partir de minStage, vitesse x speedMult[stade]
Config.Mount = {
	species = { ReefHatchling = true, CoralRay = true, StarWhaleCalf = true, AbyssSerpent = true },
	minStage = "Adult",
	speedMult = { Adult = 1.3, Giant = 1.6 },
	giantSurfs = true, -- une Giant n'est jamais prise par la vague
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
	TideEgg = { id = 0, price = 79, odds = { { "PebbleCrab", 50 }, { "SandStar", 35 }, { "ReefHatchling", 15 } }, goldenChance = 10 },
	-- choix direct, montre a la place du Tide Egg si l'aleatoire est restreint
	PickCreature = { id = 0, price = 149, species = { "PebbleCrab", "SandStar", "ReefHatchling" } },
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

-- Zones de la plage (Z diminue en s'eloignant de la base)
-- open = false : zone fermee (Phase 1 = Shallows seule). La plage se remplit au debut du calme,
-- puis se recharge toutes les spawnEvery secondes pendant le calme ; la vague emporte tout.
Config.Zones = {
	{ name = "Shallows", rarity = "Common", open = true, zMin = -150, zMax = -25, maxItems = 14, spawnEvery = 2.5, creatures = { { "PebbleCrab", 60 }, { "SandStar", 30 }, { "ReefHatchling", 10 } } },
	{ name = "Coral Coast", rarity = "Uncommon", open = false, zMin = -280, zMax = -150, maxItems = 12, spawnEvery = 3.5, creatures = { { "BubblePuffer", 65 }, { "ReefHatchling", 35 } } },
	{ name = "Sunken Reef", rarity = "Rare", open = false, zMin = -420, zMax = -280, maxItems = 10, spawnEvery = 5, creatures = { { "LanternSeahorse", 65 }, { "CoralRay", 35 } } },
	{ name = "Wreck Cove", rarity = "Epic", open = false, zMin = -570, zMax = -420, maxItems = 8, spawnEvery = 8, creatures = { { "InkOctopus", 65 }, { "MoonJelly", 35 } } },
	{ name = "Abyss Shore", rarity = "Legendary", open = false, zMin = -740, zMax = -570, maxItems = 6, spawnEvery = 12, creatures = { { "StarWhaleCalf", 70 }, { "AbyssSerpent", 30 } } },
}

Config.Beach = { xMin = -116, xMax = 116, groundY = 0 }
Config.BaseLineZ = 0 -- tout ce qui est au-dela (Z > 0) est la zone des bases, a l'abri
Config.HubSpawn = Vector3.new(0, 1, 96)

-- La vague
Config.Wave = {
	calmTime = 35, -- secondes de calme
	warningTime = 7, -- alerte avant la vague
	startZ = -800, -- depart (au large)
	endZ = 0, -- s'arrete a la limite des bases
	speed = 46, -- studs par seconde
	height = 22, -- hauteur : les tours sont a 26
	thickness = 40,
	recedeTime = 2.5,
	caughtDelay = 0.8, -- secondes entre la prise par la vague et le retour a la base
}

-- Ameliorations (achetees avec les pieces du jeu)
Config.UpgradeOrder = { "Speed", "Bag", "Slots" }
Config.Upgrades = {
	Speed = { key = "speed", label = "Speed", icon = "⚡", unit = "", base = 16, step = 2, maxLevel = 12, baseCost = 50, costMult = 2.0 },
	Bag = { key = "bag", label = "Bag", icon = "🎒", unit = " slots", base = 2, step = 1, maxLevel = 8, baseCost = 75, costMult = 2.2 },
	Slots = { key = "slots", label = "Base", icon = "🏝", unit = " spots", base = 5, step = 1, maxLevel = 5, baseCost = 200, costMult = 3.0 },
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

-- Prochaine maree speciale apres le cycle donne : { tide, cycle }
function Config.NextSpecial(cycle: number)
	local every = Config.TideSchedule.every
	local nextCycle = (cycle // every + 1) * every
	return { tide = Config.TideFor(nextCycle), cycle = nextCycle }
end

-- Index de zone (1..5) pour une position Z, 0 = base / hors zone
function Config.ZoneAt(z: number): number
	for i, zone in ipairs(Config.Zones) do
		if z <= zone.zMax and z > zone.zMin then
			return i
		end
	end
	if z <= Config.Zones[#Config.Zones].zMin then
		return #Config.Zones
	end
	return 0
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
