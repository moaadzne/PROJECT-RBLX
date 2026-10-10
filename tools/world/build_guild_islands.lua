-- tools/world/build_guild_islands.lua
-- C : Îles de Guilde instanciées + Housing joueur + Bases + Production — DECISIONS_MARCHE.md §9 Pillier 4.
-- Guilde : Hall + Banque + Coffre + Quêtes + Calendrier + Guerre + Territoire.
-- Housing : Maison + Jardin + Atelier + Coffre + Deco + Visite.
-- Instancing : 1 ile par guilde (streaming), bases PvP sur iles contestees.
-- Lancement manuel (execute_luau, edition). DRY_RUN = true.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Templates d'îles de guilde (streaming instancié par guilde)
local GUILD_ISLAND_TEMPLATE = {
	name = "GuildIsland_Template",
	center = Vector3.new(0, 0, 0), -- sera positionné dynamiquement
	radius = 200,
	biome = "Hub",
	height = 30,
	zones = {
		{ name = "Hall",          pos = Vector3.new(0, 0, 0),      size = Vector3.new(60, 20, 60),  buildings = { "GuildHall", "Bank", "Vault", "QuestBoard", "Calendar", "WarTable" } },
		{ name = "Housing_Inner", pos = Vector3.new(-80, 0, -80),  size = Vector3.new(120, 10, 120), slots = 20,  type = "Housing" },
		{ name = "Housing_Outer", pos = Vector3.new(80, 0, 80),    size = Vector3.new(100, 10, 100), slots = 15,  type = "Housing" },
		{ name = "Workshop",      pos = Vector3.new(100, 0, -50),  size = Vector3.new(40, 15, 40),  buildings = { "Forge", "Alchemy", "Enchanting", "Dock" } },
		{ name = "Defense",       pos = Vector3.new(-100, 0, 50),  size = Vector3.new(30, 20, 30),  buildings = { "Tower", "Wall", "Cannon", "Barracks" } },
		{ name = "Production",    pos = Vector3.new(-50, 0, 100),  size = Vector3.new(50, 10, 50),  buildings = { "Farm", "Mine", "Fishery", "Lumber" } },
		{ name = "Dock",          pos = Vector3.new(0, 0, -150),   size = Vector3.new(80, 10, 30),  buildings = { "Shipyard", "Market", "Travel" } },
		{ name = "Training",      pos = Vector3.new(-120, 0, -20), size = Vector3.new(60, 10, 60),  buildings = { "Arena", "TargetRange", "Library" } },
	},
	-- PvP zones (îles contestées séparées)
	pvpIslands = {
		{ name = "Contested_Isle_1", center = Vector3.new(1200, 0, 0), radius = 300, resource = "AbyssalOre" },
		{ name = "Contested_Isle_2", center = Vector3.new(-1200, 0, 0), radius = 300, resource = "TidalEssence" },
		{ name = "Contested_Isle_3", center = Vector3.new(0, 0, -1200), radius = 300, resource = "StormCrystal" },
		{ name = "Contested_Isle_4", center = Vector3.new(0, 0, 1200), radius = 300, resource = "LeviathanScale" },
	},
}

-- Housing player (template par joueur, instancié sur sa guilde)
local HOUSING_SLOT = {
	name = "PlayerHouse",
	footprint = Vector3.new(20, 10, 20),
	rooms = { "Main", "Bedroom", "Workshop", "Storage", "Garden", "Balcony" },
	furniture = { "Bed", "Desk", "Shelf", "Chest", "CraftingTable", "Anvil", "Cauldron", "Loom" },
	decor = { "Rug", "Painting", "Plant", "Statue", "Aquarium", "Trophy" },
	upgradeTiers = { { name = "Shack",     size = Vector3.new(10, 5, 10),  rooms = 2, cost = 0 },
	                  { name = "Cottage",   size = Vector3.new(16, 8, 16),  rooms = 4, cost = 5000 },
	                  { name = "Manor",     size = Vector3.new(24, 10, 24), rooms = 6, cost = 50000 },
	                  { name = "Mansion",   size = Vector3.new(32, 12, 32), rooms = 8, cost = 200000 } },
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createGuildIslandTemplate()
	log("  Template Ile Guilde (instancié par guilde) + 4 iles PvP contestees")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "GuildIsland_Template"
	folder.Parent = Workspace

	-- Zones principales
	for _, zone in GUILD_ISLAND_TEMPLATE.zones do
		local zoneFolder = Instance.new("Folder")
		zoneFolder.Name = "Zone_" .. zone.name
		zoneFolder.Parent = Workspace

		for _, building in ipairs(zone.buildings or {}) do
			local b = Instance.new("Part")
			b.Name = building
			b.Size = Vector3.new(20, 15, 20)
			b.Material = Enum.Material.Wood
			b.Color = Color3.fromHex("7D6E60")
			b.Anchored = true
			b.Parent = Workspace
		end
		if zone.slots then
			for i = 1, zone.slots do
				local slot = Instance.new("Part")
				slot.Name = "HousingSlot_" .. i
				slot.Size = Vector3.new(22, 1, 22)
				slot.Transparency = 0.8
				slot.Material = Enum.Material.Sand
				slot.Color = Color3.fromHex("E6D2A8")
				slot.Anchored = true
				slot.CanCollide = false
				slot.Parent = Workspace
				slot:SetAttribute("HousingTier", "Empty")
			end
		end
		if zone.buildings then
			for _, bname in ipairs(zone.buildings) do
				local b = Instance.new("StringValue")
				b.Name = "Building_" .. bname
				b.Value = bname
				b.Parent = Workspace
			end
		end
	end

	-- PvP Islands (contestées)
	for _, pvp in GUILD_ISLAND_TEMPLATE.pvpIslands do
		local pvpFolder = Instance.new("Folder")
		pvpFolder.Name = "PvPIsland_" .. pvp.name
		pvpFolder.Parent = Workspace

		local marker = Instance.new("Part")
		marker.Name = "PvP_Island_Marker"
		marker.Size = Vector3.new(50, 20, 50)
		marker.Color = Color3.fromHex("FF3333")
		marker.Material = Enum.Material.Neon
		marker.Anchored = true
		marker.CanCollide = false
		marker.Parent = Workspace
		marker:SetAttribute("Resource", pvp.resource)
		marker:SetAttribute("Contested", true)

		log("  PvP Isle : " .. pvp.name .. " -> resource " .. pvp.resource)
	end
end

local function createPlayerHousingTemplate()
	log("  Template Housing Joueur (4 tiers, 6 pieces, meubles/decor)")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "PlayerHousing_Template"
	folder.Parent = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder", ReplicatedStorage)

	for _, tier in HOUSING_SLOT.upgradeTiers do
		local t = Instance.new("Folder")
		t.Name = "Tier_" .. tier.name
		t.Parent = Workspace
		t:SetAttribute("Size", tier.size)
		t:SetAttribute("Rooms", #tier.rooms)
		t:SetAttribute("Cost", tier.cost)
		for _, room in ipairs(tier.rooms) do
			local r = Instance.new("StringValue")
			r.Name = "Room_" .. room
			r.Value = room
			r.Parent = Workspace
		end
	end

	-- Meubles/decor catalog
	local catalog = Instance.new("Folder")
	catalog.Name = "FurnitureCatalog"
	catalog.Parent = Workspace
	for _, item in ipairs(HOUSING_SLOT.furniture) do
		local f = Instance.new("StringValue")
		f.Name = "Furniture_" .. item
		f.Value = item
		f.Parent = Workspace
	end
	for _, item in ipairs(HOUSING_SLOT.decor) do
		local d = Instance.new("StringValue")
		d.Name = "Decor_" .. item
		d.Value = item
		d.Parent = Workspace
	end
end

local function createWarTerritorySystem()
	log("  Systeme Territoires + Guerres Guilde (4 iles contestees, ressources uniques)")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "WarTerritorySystem"
	folder.Parent = Workspace

	for _, pvp in GUILD_ISLAND_TEMPLATE.pvpIslands do
		local t = Instance.new("Folder")
		t.Name = "Territory_" .. pvp.name
		t.Parent = Workspace
		t:SetAttribute("Resource", pvp.resource)
		t:SetAttribute("Contested", true)
		t:SetAttribute("ControlPoints", 3)
		t:SetAttribute("CaptureTime", 300) -- 5 min par point
		t:SetAttribute("WarDuration", 3600) -- 1h guerre
		t:SetAttribute("CooldownHours", 24)
		t:SetAttribute("GuildSizeMin", 10)
		t:SetAttribute("MaxParticipants", 50)
	end
end

local function run()
	log("=== GUILD ISLANDS + HOUSING + WAR TERRITORIES ===")
	log("  Template Guilde : 8 zones (Hall, Housing x2, Workshop, Defense, Production, Dock, Training)")
	log("  Housing : 4 tiers (Shack->Mansion), 6 pieces, 8 meubles, 6 decor")
	log("  PvP Iles : 4 iles contestees, ressources uniques (AbyssalOre, TidalEssence, StormCrystal, LeviathanScale)")

	if DRY_RUN then
		print("[C][DRY] DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Guild Islands + Housing + War Territories")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		createGuildIslandTemplate()
		createPlayerHousingTemplate()
		createWarTerritorySystem()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		print("[C] Guild Islands + Housing + War Territories crees. Pret pour GuildService/HousingService/WarService.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()