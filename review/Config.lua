-- Tide Rush : configuration partagee (serveur + client)
-- Tout l'equilibrage du jeu est ici : objets, zones, vague, ameliorations, compagnons.

local Config = {}

Config.GameName = "Tide Rush"

Config.Rarities = {
	Common = { order = 1, label = "Common", color = Color3.fromRGB(215, 215, 215) },
	Uncommon = { order = 2, label = "Uncommon", color = Color3.fromRGB(95, 225, 125) },
	Rare = { order = 3, label = "Rare", color = Color3.fromRGB(75, 165, 255) },
	Epic = { order = 4, label = "Epic", color = Color3.fromRGB(185, 95, 255) },
	Legendary = { order = 5, label = "Legendary", color = Color3.fromRGB(255, 195, 45) },
}

-- Tresors : revenu par seconde une fois poses sur un socle de la base
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

-- Quand un tresor ne trouve pas de place, il est vendu : revenu x ce multiplicateur
Config.SellMultiplier = 20

-- Zones de la plage (Z diminue en s'eloignant de la base)
Config.Zones = {
	{ name = "Shallows", rarity = "Common", zMin = -150, zMax = -25, maxItems = 14, spawnEvery = 2.5, items = { { "Shell", 70 }, { "Starfish", 30 } } },
	{ name = "Coral Coast", rarity = "Uncommon", zMin = -280, zMax = -150, maxItems = 12, spawnEvery = 3.5, items = { { "Pearl", 65 }, { "BlueCrab", 35 } } },
	{ name = "Sunken Reef", rarity = "Rare", zMin = -420, zMax = -280, maxItems = 10, spawnEvery = 5, items = { { "CoralCrown", 65 }, { "GoldenCrab", 35 } } },
	{ name = "Pirate Cove", rarity = "Epic", zMin = -570, zMax = -420, maxItems = 8, spawnEvery = 8, items = { { "TreasureChest", 65 }, { "AbyssCrystal", 35 } } },
	{ name = "Abyss Shore", rarity = "Legendary", zMin = -740, zMax = -570, maxItems = 6, spawnEvery = 12, items = { { "MoonPearl", 70 }, { "TideHeart", 30 } } },
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
Config.TreasureSpacing = 7 -- ecart minimal entre deux tresors au sol (studs)
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
