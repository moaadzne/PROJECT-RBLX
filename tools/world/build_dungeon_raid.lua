-- tools/world/build_dungeon_raid.lua
-- C : Donjons (5 joueurs) + Raids (10/20 joueurs) — DECISIONS_MARCHE.md §9 Pilliers 3.
-- Donjon 5j : "Abysses" (Normal/Heroique/Mythique), Raid 10/20j : "Cathédrale d'Ecume", "Temple des Marees".
-- Instancing uniquement pour donjons/raids. Lancement manuel (execute_luau, edition).

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Donjons 5 joueurs (3 difficultes)
local DUNGEONS = {
	{
		id = "Abysses",
		name = "Les Abysses Oublies",
		entrance = Vector3.new(0, 5, 820), -- Ile_Abysses, pres Boss Leviathan
		size = Vector3.new(300, 80, 300),
		difficulties = { "Normal", "Heroic", "Mythic" },
		maxPlayers = 5,
		recommendedLevel = { Normal = 20, Heroic = 40, Mythic = 60 },
		bosses = { "AbyssalGuardian", "TideCaller", "DeepOne" },
		mechanics = { "TidalSurge", "PressureCrush", "DarknessZone", "AddWaves" },
		lootTables = {
			Normal  = { "Gear_Abyssal_Normal", "Mats_Abyssal_Common" },
			Heroic  = { "Gear_Abyssal_Heroic", "Mats_Abyssal_Rare", "Cosmetic_Abyssal_Trinket" },
			Mythic  = { "Gear_Abyssal_Mythic", "Mats_Abyssal_Epic", "Cosmetic_Abyssal_Mount", "Title_AbyssalConqueror" },
		},
		resetHours = 24,
		instanceName = "Dungeon_Abysses",
	},
	{
		id = "TempleTides",
		name = "Temple des Marees",
		entrance = Vector3.new(-400, 10, -500), -- Ile_Falaise
		size = Vector3.new(350, 100, 350),
		difficulties = { "Normal", "Heroic", "Mythic" },
		maxPlayers = 5,
		recommendedLevel = { Normal = 30, Heroic = 50, Mythic = 70 },
		bosses = { "TidePriestess", "WaveWalker", "MoonTideAvatar" },
		mechanics = { "TidalShift", "MoonPhase", "ReflectionPool", "TideTurn" },
		lootTables = {
			Normal  = { "Gear_Tidal_Normal", "Mats_Tidal_Common" },
			Heroic  = { "Gear_Tidal_Heroic", "Mats_Tidal_Rare", "Cosmetic_Tidal_Wings" },
			Mythic  = { "Gear_Tidal_Mythic", "Mats_Tidal_Epic", "Cosmetic_Tidal_Mount", "Title_TempleGuardian" },
		},
		resetHours = 24,
		instanceName = "Dungeon_TempleTides",
	},
	{
		id = "CoralCatacombs",
		name = "Catacombes de Corail",
		entrance = Vector3.new(-420, 5, 320), -- Ile_Recif
		size = Vector3.new(280, 70, 280),
		difficulties = { "Normal", "Heroic", "Mythic" },
		maxPlayers = 5,
		recommendedLevel = { Normal = 15, Heroic = 35, Mythic = 55 },
		bosses = { "CoralMatriarch", "ReefStalker", "PolypsQueen" },
		mechanics = { "CoralGrowth", "SporeCloud", "BleedingReef", "Symbiosis" },
		lootTables = {
			Normal  = { "Gear_Coral_Normal", "Mats_Coral_Common" },
			Heroic  = { "Gear_Coral_Heroic", "Mats_Coral_Rare", "Cosmetic_Coral_Aura" },
			Mythic  = { "Gear_Coral_Mythic", "Mats_Coral_Epic", "Cosmetic_Coral_Mount", "Title_ReefWalker" },
		},
		resetHours = 24,
		instanceName = "Dungeon_CoralCatacombs",
	},
}

-- Raids 10/20 joueurs
local RAIDS = {
	{
		id = "CathedralOfFoam",
		name = "Cathédrale d'Ecume",
		entrance = Vector3.new(0, 15, 880), -- Ile_Abysses, au-dela Leviathan
		size = Vector3.new(500, 150, 500),
		sizes = { ["10"] = 10, ["20"] = 20 },
		recommendedLevel = { ["10"] = 60, ["20"] = 80 },
		bosses = { "FoamArchbishop", "TidalChoir", "AbyssalLeviathan_Aspect" },
		mechanics = { "FoamTide", "HarmonicResonance", "SacramentWave", "ChoirOfTheDeep", "FinalHymn" },
		phases = { 10 = 4, ["20"] = 5 },
		enrageMinutes = { ["10"] = 15, ["20"] = 20 },
		lootTables = {
			["10"] = { "Gear_Cathedral_10", "Mats_Cathedral_Epic", "Cosmetic_Cathedral_Wings_10", "Title_CathedralChoir" },
			["20"] = { "Gear_Cathedral_20", "Mats_Cathedral_Legendary", "Cosmetic_Cathedral_Mount_20", "Title_CathedralConqueror" },
		},
		resetHours = 168, -- hebdo
		instanceName = "Raid_CathedralOfFoam",
	},
	{
		id = "TempleOfTides",
		name = "Temple des Marees Ancestrales",
		entrance = Vector3.new(-450, 20, -480), -- Ile_Falaise, sommet
		size = Vector3.new(450, 120, 450),
		sizes = { ["10"] = 10, ["20"] = 20 },
		recommendedLevel = { ["10"] = 70, ["20"] = 90 },
		bosses = { "TideOracle", "MoonWeaver", "AncientTideKing" },
		mechanics = { "TidePrediction", "MoonWeave", "AncestralJudgment", "TideReversal", "FinalTide" },
		phases = { 10 = 5, ["20"] = 6 },
		enrageMinutes = { ["10"] = 18, ["20"] = 22 },
		lootTables = {
			["10"] = { "Gear_Temple_10", "Mats_Temple_Epic", "Cosmetic_Temple_Crown_10", "Title_TempleOracle" },
			["20"] = { "Gear_Temple_20", "Mats_Temple_Legendary", "Cosmetic_Temple_Mount_20", "Title_TempleConqueror" },
		},
		resetHours = 168,
		instanceName = "Raid_TempleOfTides",
	},
	{
		id = "BlackTideRaid",
		name = "Maree Noire - Eveil du Leviathan",
		entrance = Vector3.new(0, 0, 900), -- Epicentre Ile_Abysses
		size = Vector3.new(600, 200, 600),
		sizes = { ["20"] = 20 }, -- 20 joueurs seulement
		recommendedLevel = { ["20"] = 100 },
		bosses = { "Leviathan_TrueForm", "AbyssalGenerals", "TideItself" },
		mechanics = { "WorldShatter", "TidalApocalypse", "AbyssalDominion", "FinalStand", "LeviathansWrath" },
		phases = { ["20"] = 6 },
		enrageMinutes = { ["20"] = 25 },
		lootTables = {
			["20"] = { "Gear_Leviathan_True", "Mats_Leviathan_Mythic", "Cosmetic_Leviathan_TrueForm", "Title_LeviathanSlayer", "Mount_Leviathan_Adult" },
		},
		resetHours = 672, -- 4 semaines (evenement mensuel)
		instanceName = "Raid_BlackTide",
		isWorldEvent = true,
	},
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createDungeonInstance(dungeon)
	log("  Donjon : " .. dungeon.id .. " @ " .. tostring(dungeon.entrance) .. " (" .. #dungeon.difficulties .. " difficultes)")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "Dungeon_" .. dungeon.id
	folder.Parent = Workspace

	-- Point d'entree (visible dans le monde)
	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(12, 16, 12)
	entrance.CFrame = CFrame.new(dungeon.entrance)
	entrance.Material = Enum.Material.Neon
	entrance.Color = Color3.fromHex("4FD1C5")
	entrance.Anchored = true
	entrance.CanCollide = false
	entrance.Parent = folder

	-- Marqueur pour le serveur (DungeonService)
	folder:SetAttribute("DungeonId", dungeon.id)
	folder:SetAttribute("InstanceName", dungeon.instanceName)
	folder:SetAttribute("MaxPlayers", dungeon.maxPlayers)
	folder:SetAttribute("ResetHours", dungeon.resetHours)
	folder:SetAttribute("EntrancePos", dungeon.entrance)

	-- Difficultes
	for _, diff in ipairs(dungeon.difficulties) do
		local d = Instance.new("StringValue")
		d.Name = "Difficulty_" .. diff
		d.Value = diff
		d.Parent = folder
	end

	-- Boss list
	for _, boss in ipairs(dungeon.bosses) do
		local b = Instance.new("StringValue")
		b.Name = "Boss_" .. boss
		b.Value = boss
		b.Parent = folder
	end

	-- Mecaniques
	for _, mech in ipairs(dungeon.mechanics) do
		local m = Instance.new("StringValue")
		m.Name = "Mechanic_" .. mech
		m.Value = mech
		m.Parent = folder
	end
end

local function createRaidInstance(raid)
	log("  Raid : " .. raid.id .. " @ " .. tostring(raid.entrance) .. " (" .. raid.sizes["10"] .. "/" .. raid.sizes["20"] .. " joueurs)")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "Raid_" .. raid.id
	folder.Parent = Workspace

	local entrance = Instance.new("Part")
	entrance.Name = "Entrance"
	entrance.Size = Vector3.new(20, 24, 20)
	entrance.CFrame = CFrame.new(raid.entrance)
	entrance.Material = Enum.Material.Neon
	entrance.Color = Color3.fromHex("FF6B35")
	entrance.Anchored = true
	entrance.CanCollide = false
	entrance.Parent = folder

	folder:SetAttribute("RaidId", raid.id)
	folder:SetAttribute("InstanceName", raid.instanceName)
	folder:SetAttribute("Sizes", table.concat({ tostring(raid.sizes["10"]), tostring(raid.sizes["20"]) }, "/"))
	folder:SetAttribute("ResetHours", raid.resetHours)
	folder:SetAttribute("EntrancePos", raid.entrance)
	folder:SetAttribute("IsWorldEvent", raid.isWorldEvent or false)

	for sizeKey, size in pairs(raid.sizes) do
		local s = Instance.new("StringValue")
		s.Name = "Size_" .. sizeKey
		s.Value = sizeKey
		s.Parent = folder
	end

	for _, boss in ipairs(raid.bosses) do
		local b = Instance.new("StringValue")
		b.Name = "Boss_" .. boss
		b.Value = boss
		b.Parent = folder
	end

	for _, mech in ipairs(raid.mechanics) do
		local m = Instance.new("StringValue")
		m.Name = "Mechanic_" .. mech
		m.Value = mech
		m.Parent = folder
	end

	if raid.isWorldEvent then
		folder:SetAttribute("WorldEvent", true)
		folder:SetAttribute("EventName", "Eveil du Leviathan - Maree Noire")
	end
end

local function run()
	log("=== DONJONS 5J + RAIDS 10/20J (INSTANCING) ===")
	for _, d in DUNGEONS do
		log("  Donjon : " .. d.id .. " (" .. #d.difficulties .. " diff) @ " .. tostring(d.entrance))
	end
	for _, r in RAIDS do
		log("  Raid : " .. r.id .. " (" .. r.sizes["10"] .. "/" .. r.sizes["20"] .. "j) @ " .. tostring(r.entrance))
	end

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Donjons 5j + Raids 10/20j (instancing)")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		for _, d in DUNGEONS do
			createDungeonInstance(d)
		end
		for _, r in RAIDS do
			createRaidInstance(r)
		end
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Donjons + Raids creees. Instancing pret pour DungeonService/RaidService.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()