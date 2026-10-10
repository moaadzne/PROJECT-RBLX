-- tools/world/build_housing.lua
-- C : Housing joueur detaille + Guild Hall — DECISIONS_MARCHE.md §9 Pilier 4 (agent U).
-- 4 tiers (Shack->Mansion), 6 pieces, meubles/decor, visite, permissions, coffre partage.
-- Instancié sur ile guilde (slots). Upgrade cout croissant. Deco persistante.
-- Lancement manuel (execute_luau, edition). DRY_RUN = true.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Housing Tiers (prix en pieces jeu, pas Robux)
local HOUSING_TIERS = {
	{
		id = "Shack",
		name = "Cabane",
		size = Vector3.new(10, 5, 10),
		rooms = { "Main" },
		furniture = { "Bed", "Chest" },
		decor = { "Rug" },
		cost = 0,
		unlockLevel = 1,
	},
	{
		id = "Cottage",
		name = "Chaumiere",
		size = Vector3.new(16, 8, 16),
		rooms = { "Main", "Bedroom", "Kitchen", "Storage" },
		furniture = { "Bed", "Desk", "Shelf", "Chest", "CraftingTable", "Cauldron" },
		decor = { "Rug", "Plant", "Painting", "Statue" },
		cost = 5000,
		unlockLevel = 10,
	},
	{
		id = "Manor",
		name = "Manoir",
		size = Vector3.new(24, 10, 24),
		rooms = { "Main", "Bedroom", "Kitchen", "Storage", "Library", "Workshop" },
		furniture = { "Bed", "Desk", "Shelf", "Chest", "CraftingTable", "Anvil", "Cauldron", "Loom", "EnchantingTable" },
		decor = { "Rug", "Plant", "Painting", "Statue", "Aquarium", "Trophy", "Chandelier" },
		cost = 50000,
		unlockLevel = 30,
	},
	{
		id = "Mansion",
		name = "Manoir Luxueux",
		size = Vector3.new(32, 12, 32),
		rooms = { "GrandHall", "MasterBedroom", "GuestRoom", "Kitchen", "Storage", "Library", "Workshop", "Gallery" },
		furniture = { "KingBed", "Desk", "Shelf", "Chest", "CraftingTable", "Anvil", "Cauldron", "Loom", "EnchantingTable", "Forge", "AlchemyStation", "DisplayCase" },
		decor = { "Rug", "Plant", "Painting", "Statue", "Aquarium", "Trophy", "Chandelier", "Fountain", "ArmorStand", "WeaponRack" },
		cost = 200000,
		unlockLevel = 50,
	},
}

-- Guild Hall (partage guilde)
local GUILD_HALL = {
	name = "GuildHall",
	size = Vector3.new(60, 20, 60),
	rooms = { "GrandHall", "WarRoom", "Vault", "Library", "Armory", "Infirmary", "MessHall", "StrategyRoom" },
	shared = { "GuildBank", "GuildVault", "QuestBoard", "Calendar", "WarTable", "MemberList", "Roster", "Permissions" },
	upgrades = {
		{ name = "Level_1", cost = 0,       features = { "Bank", "Vault", "QuestBoard" } },
		{ name = "Level_2", cost = 100000, features = { "Calendar", "WarTable", "Armory" } },
		{ name = "Level_3", cost = 500000, features = { "Infirmary", "MessHall", "StrategyRoom", "MemberList", "Permissions" } },
	},
	permissions = { "Leader", "Officer", "Member", "Recruit" },
}

-- Permissions housing
local HOUSING_PERMISSIONS = {
	Owner     = { build = true,  decorate = true,  invite = true,  chest = true,  settings = true },
	CoOwner   = { build = true,  decorate = true,  invite = true,  chest = true,  settings = false },
	Friend    = { build = false, decorate = false, invite = false, chest = true,  settings = false },
	Visitor   = { build = false, decorate = false, invite = false, chest = false, settings = false },
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createHousingTemplates()
	log("  Housing Tiers (4) : Shack -> Cottage -> Manor -> Mansion")
	if DRY_RUN then return end

	local assets = RS:FindFirstChild("Assets") or Instance.new("Folder", RS)
	assets.Name = "Assets"
	local housingFolder = assets:FindFirstChild("Housing")
	if not housingFolder then
		housingFolder = Instance.new("Folder")
		housingFolder.Name = "Housing"
		housingFolder.Parent = assets
	end

	for _, tier in HOUSING_TIERS do
		local tierFolder = housingFolder:FindFirstChild(tier.id) or Instance.new("Folder")
		tierFolder.Name = tier.id
		tierFolder.Parent = housingFolder
		tierFolder:SetAttribute("Name", tier.name)
		tierFolder:SetAttribute("Size", tier.size)
		tierFolder:SetAttribute("Cost", tier.cost)
		tierFolder:SetAttribute("UnlockLevel", tier.unlockLevel)
		tierFolder:SetAttribute("RoomCount", #tier.rooms)

		for _, room in ipairs(tier.rooms) do
			local r = Instance.new("StringValue")
			r.Name = "Room_" .. room
			r.Value = room
			r.Parent = tierFolder
		end
		for _, item in ipairs(tier.furniture) do
			local f = Instance.new("StringValue")
			f.Name = "Furniture_" .. item
			f.Value = item
			f.Parent = tierFolder
		end
		for _, item in ipairs(tier.decor) do
			local d = Instance.new("StringValue")
			d.Name = "Decor_" .. item
			d.Value = item
			d.Parent = tierFolder
		end
	end
end

local function createGuildHallTemplate()
	log("  Guild Hall : 8 pieces, 7 features partages, 3 niveaux upgrade, 4 permissions")
	if DRY_RUN then return end

	local assets = RS:FindFirstChild("Assets")
	local housingFolder = assets:FindFirstChild("Housing")
	if not housingFolder then return end

	local hallFolder = housingFolder:FindFirstChild("GuildHall") or Instance.new("Folder")
	hallFolder.Name = "GuildHall"
	hallFolder.Parent = housingFolder
	hallFolder:SetAttribute("Name", GUILD_HALL.name)
	hallFolder:SetAttribute("Size", GUILD_HALL.size)
	hallFolder:SetAttribute("RoomCount", #GUILD_HALL.rooms)

	for _, room in ipairs(GUILD_HALL.rooms) do
		local r = Instance.new("StringValue")
		r.Name = "Room_" .. room
		r.Value = room
		r.Parent = hallFolder
	end
	for _, feature in ipairs(GUILD_HALL.shared) do
		local f = Instance.new("StringValue")
		f.Name = "Feature_" .. feature
		f.Value = feature
		f.Parent = hallFolder
	end
	for _, upg in ipairs(GUILD_HALL.upgrades) do
		local u = Instance.new("Folder")
		u.Name = "Upgrade_" .. upg.name
		u.Parent = hallFolder
		u:SetAttribute("Cost", upg.cost)
		for _, feat in ipairs(upg.features) do
			local f = Instance.new("StringValue")
			f.Name = "Feature_" .. feat
			f.Value = feat
			f.Parent = u
		end
	end
	for _, perm in ipairs(GUILD_HALL.permissions) do
		local p = Instance.new("StringValue")
		p.Name = "Permission_" .. perm
		p.Value = perm
		p.Parent = hallFolder
	end
end

local function createPermissionsModule()
	log("  Module Permissions (Owner/CoOwner/Friend/Visitor)")
	if DRY_RUN then return end

	local permFolder = Instance.new("Folder")
	permFolder.Name = "HousingPermissions"
	permFolder.Parent = RS

	for role, perms in HOUSING_PERMISSIONS do
		local r = Instance.new("Folder")
		r.Name = "Permission_" .. role
		r.Parent = permFolder
		for action, allowed in pairs(perms) do
			local a = Instance.new("BoolValue")
			a.Name = action
			a.Value = allowed
			a.Parent = r
		end
	end
end

local function createHousingSlotsOnGuildIslands()
	log("  Slots Housing sur iles Guilde (20 inner + 15 outer = 35 slots/guilde)")
	if DRY_RUN then return end

	-- Les slots sont crees par build_guild_islands.lua
	-- Ici on cree juste le template de slot dans Assets
	local assets = RS:FindFirstChild("Assets")
	local housingFolder = assets:FindFirstChild("Housing")
	if not housingFolder then return end

	local slotTemplate = housingFolder:FindFirstChild("SlotTemplate") or Instance.new("Folder")
	slotTemplate.Name = "SlotTemplate"
	slotTemplate.Parent = housingFolder

	local slot = Instance.new("Part")
	slot.Name = "HousingSlot"
	slot.Size = Vector3.new(22, 1, 22)
	slot.Transparency = 0.8
	slot.Material = Enum.Material.Sand
	slot.Color = Color3.fromHex("E6D2A8")
	slot.Anchored = true
	slot.CanCollide = false
	slot.Parent = slotTemplate
	slot:SetAttribute("Tier", "Empty")
	slot:SetAttribute("Owner", "")
	slot:SetAttribute("Guild", "")
end

local function run()
	log("=== HOUSING JOUEUR (4 TIERS) + GUILD HALL (3 NIVEAUX) ===")
	for _, t in HOUSING_TIERS do
		log("  " .. t.id .. " : " .. t.name .. " " .. tostring(t.size) .. " " .. #t.rooms .. " pieces, " .. #t.furniture .. " meubles, " .. #t.decor .. " decor, " .. t.cost .. " pieces, niv " .. t.unlockLevel)
	end
	log("Guild Hall : " .. #GUILD_HALL.rooms .. " pieces, " .. #GUILD_HALL.shared .. " features, 3 upgrades, 4 permissions")

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Housing 4 tiers + Guild Hall 3 niveaux")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		createHousingTemplates()
		createGuildHallTemplate()
		createPermissionsModule()
		createHousingSlotsOnGuildIslands()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Housing 4 tiers + Guild Hall 3 niveaux crees. Pret pour HousingService/GuildService.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()