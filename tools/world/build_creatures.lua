-- tools/world/build_creatures.lua
-- C : pipeline 10 créatures + Rtho animations + mutations shader (DECISIONS_MARCHE.md agent K).
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
-- Crée : ReplicatedStorage.Assets.Creatures.<Id> (Model, PrimaryPart Root, Attachments Saddle/SurfStand).
-- Mutations : MaterialVariant + ColorShift + Trail (pas nouveaux mesh). K livre les modèles.
-- Config.Creatures (10 espèces) fait foi pour les IDs, raretés, revenus.
-- Cross-platform : LOD distance, triangles ≤ 1500 (sauf montable 3000), texture ≤ 512 (montable 1024).

local DRY_RUN = true

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Roster Config.Creatures (10 espèces, fait foi)
local ROSTER = {
	{ id = "GhostCrab",        name = "Ghost Crab",        rarity = "Common",    income = 1,   mountable = false, scale = 1.0 },
	{ id = "CushionStar",      name = "Cushion Star",      rarity = "Common",    income = 2,   mountable = false, scale = 1.0 },
	{ id = "Lionfish",         name = "Lionfish",          rarity = "Uncommon",  income = 6,   mountable = false, scale = 1.0 },
	{ id = "HawksbillTurtle",  name = "Hawksbill Turtle",  rarity = "Uncommon",  income = 10,  mountable = true,  scale = 1.0 }, -- montable Elder+
	{ id = "BlueRingedOctopus",name = "Blue-ringed Octopus",rarity = "Rare",     income = 30,  mountable = false, scale = 1.0 },
	{ id = "LeopardRay",       name = "Leopard Ray",       rarity = "Rare",      income = 50,  mountable = false, scale = 1.0 },
	{ id = "GiantPacificOctopus",name="Giant Pacific Octopus",rarity="Epic",    income = 150, mountable = false, scale = 1.2 },
	{ id = "LionsManeJelly",   name = "Lion's Mane Jelly", rarity = "Epic",      income = 250, mountable = false, scale = 1.2 },
	{ id = "MantaRay",         name = "Manta Ray",         rarity = "Legendary", income = 800, mountable = true,  scale = 1.3 }, -- montable Elder+
	{ id = "WhaleShark",       name = "Whale Shark",       rarity = "Legendary", income = 1500, mountable = true,  scale = 1.5 }, -- montable Elder+ (Titan surfe)
}

-- Mutations (shader/material, PAS nouveaux mesh) — build_mutation_fx.lua crée les presets
local MUTATIONS = { "Golden", "Night", "Storm", "Rainbow" }

-- Rthro Animation Package (bundle 356, gratuit, Roblox)
local RTHRO_ANIMATIONS = {
	idle = "rbxassetid://2510196951",      -- Rthro Idle
	walk = "rbxassetid://2510197257",      -- Rthro Walk
	swim = "rbxassetid://2510197759",      -- Rthro Swim (adapte pour creatures aquatiques)
	carry = "rbxassetid://2510201471",     -- Rthro Carry
	mount = "rbxassetid://2510198475",     -- Rthro Mount
	surf = "rbxassetid://2510202577",      -- Rthro Surf (adapte pour Titan)
}

-- Cross-platform LOD distances (Config.CrossPlatform)
local LOD_DISTANCES = {
	mobile = { 80, 160, 300 },
	pc = { 120, 250, 500 },
}

-- Budgets triangles/textures
local BUDGETS = {
	standard = { triangles = 1500, texture = 512 },
	mountable = { triangles = 3000, texture = 1024 },
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createCreatureModel(spec)
	-- K doit fournir les modèles (generate_mesh, Store, ou modéliste).
	-- Ici on crée la STRUCTURE standard. Les meshparts viennent de K.
	local model = Instance.new("Model")
	model.Name = spec.id
	model.PrimaryPart = nil -- sera mis après

	-- Root invisible (PrimaryPart)
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 1, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Anchored = true
	root.Massless = true
	root.Parent = model

	-- Attributs serveur
	model:SetAttribute("CreatureId", spec.id)
	model:SetAttribute("Rarity", spec.rarity)
	model:SetAttribute("BaseIncome", spec.income)
	model:SetAttribute("Mountable", spec.mountable)
	model:SetAttribute("BaseScale", spec.scale)

	-- Attachments standard
	local saddle = Instance.new("Attachment")
	saddle.Name = "Saddle"
	saddle.Position = Vector3.new(0, 0, 0) -- centre carapace, sera ajuste par K
	saddle.Axis = Vector3.new(0, 0, -1)   -- face -Z
	saddle.Parent = root

	local surfStand = Instance.new("Attachment")
	surfStand.Name = "SurfStand"
	surfStand.Position = Vector3.new(0, 0.3, 0) -- 0.3 stud au-dessus Saddle
	surfStand.Parent = root

	-- Rthro AnimationController + Animator (côté client le chargera)
	-- Ici on met juste les IDs en attributs pour le client
	model:SetAttribute("RthroIdle", RTHRO_ANIMATIONS.idle)
	model:SetAttribute("RthroWalk", RTHRO_ANIMATIONS.walk)
	model:SetAttribute("RthroSwim", RTHRO_ANIMATIONS.swim)
	model:SetAttribute("RthroCarry", RTHRO_ANIMATIONS.carry)
	model:SetAttribute("RthroMount", RTHRO_ANIMATIONS.mount)
	model:SetAttribute("RthroSurf", RTHRO_ANIMATIONS.surf)

	-- Cross-platform LOD distances (lus par CreatureRenderer cote client)
	model:SetAttribute("LODMobile", table.concat(LOD_DISTANCES.mobile, ","))
	model:SetAttribute("LODPC", table.concat(LOD_DISTANCES.pc, ","))

	-- Budget triangles/texture (verification cote K)
	model:SetAttribute("MaxTriangles", spec.mountable and BUDGETS.mountable.triangles or BUDGETS.standard.triangles)
	model:SetAttribute("MaxTextureSize", spec.mountable and BUDGETS.mountable.texture or BUDGETS.standard.texture)

	-- Mutations : attributs pour le client (build_mutation_fx.lua cree les presets)
	for _, mut in MUTATIONS do
		model:SetAttribute("Mutation_" .. mut, "ready") -- le client appliquera le preset
	end

	-- Placeholder visuel (K le remplacera par le vrai mesh)
	-- On met un Part simple pour que le modèle ne soit pas vide en edition
	local placeholder = Instance.new("Part")
	placeholder.Name = "Body_Placeholder"
	placeholder.Size = Vector3.new(4 * spec.scale, 2 * spec.scale, 6 * spec.scale)
	placeholder.Material = Enum.Material.SmoothPlastic
	placeholder.Color = Color3.fromHex("888888")
	placeholder.Anchored = true
	placeholder.CanCollide = false
	placeholder.CanQuery = false
	placeholder.CanTouch = false
	placeholder.Massless = true
	placeholder.CFrame = CFrame.new(0, 0, 0)
	placeholder.Parent = model
	-- Marqueur pour K : ce part doit être remplacé
	placeholder:SetAttribute("ReplaceByK", true)

	-- PrimaryPart
	model.PrimaryPart = root

	return model
end

local function run()
	local assets = RS:FindFirstChild("Assets")
	assert(assets, "[C] ReplicatedStorage.Assets introuvable")

	local creaturesFolder = assets:FindFirstChild("Creatures")
	if not creaturesFolder then
		if not DRY_RUN then
			creaturesFolder = Instance.new("Folder")
			creaturesFolder.Name = "Creatures"
			creaturesFolder.Parent = assets
		else
			log("DRY_RUN : dossier Assets.Creatures sera cree")
		end
	end

	if DRY_RUN then
		log("DRY_RUN : 10 créatures → Assets.Creatures.<Id>")
		for _, spec in ROSTER do
			local budget = spec.mountable and "montable (3000 tri, 1024 tex)" or "standard (1500 tri, 512 tex)"
			log(string.format("  %-22s %-15s %s  montable=%s  scale=%.1f  %s",
				spec.id, spec.rarity, spec.name, tostring(spec.mountable), spec.scale, budget))
		end
		log("Mutations : " .. table.concat(MUTATIONS, ", ") .. " (shader/material, pas nouveaux mesh)")
		log("Rthro anims : bundle 356 (idle/walk/swim/carry/mount/surf)")
		log("LOD : mobile 80/160/300, PC 120/250/500 (Config.CrossPlatform)")
		return
	end

	if not creaturesFolder then
		creaturesFolder = Instance.new("Folder")
		creaturesFolder.Name = "Creatures"
		creaturesFolder.Parent = assets
	end

	local rec = CHS:TryBeginRecording("C : 10 créatures + Rthro + mutations")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		for _, spec in ROSTER do
			local old = creaturesFolder:FindFirstChild(spec.id)
			if old then
				log("remplace " .. spec.id .. " existant")
				old:Destroy()
			end
			local model = createCreatureModel(spec)
			model.Parent = creaturesFolder
			log("creee : " .. spec.id .. " (" .. spec.rarity .. ")")
		end
	end)

	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("10 créatures creees dans Assets.Creatures. K doit remplacer les placeholders par les vrais mesh.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()