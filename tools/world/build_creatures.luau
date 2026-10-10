-- tools/world/build_creatures.luau
-- K (VFX, Creature Models & Animations) : génère les 10 modèles de créatures avec 2 LODs.
-- Lance en mode édition (execute_luau). DRY_RUN = true d'abord. Ctrl+Z annule.
-- Structure cible : ReplicatedStorage.Assets.Creatures.<Species>
--   PrimaryPart = "Root" (Part invisible, Anchored, CanCollide=false)
--   LOD0 = mesh complet (Near), LOD1 = mesh simplifié ~50% triangles (Mid/Far)
--   Model.LOD configuré : distances Mobile/PC via Config.CrossPlatform
--   Attributs : CreatureId (string), Rarity (string)
--   Pour montables : Attachment "Saddle" (centre carapace, face -Z), Attachment "SurfStand" (+0.3 stud Y)
--   Échelle de référence : Adult (Config.Stages[2].scale = 0.8) = taille de base du modèle
--   Stades client : Juvenile 0.6, Adult 0.8, Elder 1.0, Titan 1.5 (Model:ScaleTo)
--   Mutations : appliquées par B via Assets.FX.Mutations.<Nom> (pas de nouveau modèle)
--   Animations : Rthro Animation Package (bundle 356) - idle/walk/swim/carry/mount/surf

local DRY_RUN = true

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[K] à lancer en mode édition, pas en Play")

local assets = RS:FindFirstChild("Assets")
assert(assets, "[K] ReplicatedStorage.Assets introuvable")

local function log(msg)
	print((DRY_RUN and "[K][DRY] " or "[K] ") .. msg)
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function replace(parent, inst)
	local old = parent:FindFirstChild(inst.Name)
	if old then
		old:Destroy()
	end
	inst.Parent = parent
end

-- Configuration des 10 espèces (ordre = rareté croissante)
local CREATURES = {
	{
		id = "GhostCrab",
		name = "Ghost Crab",
		rarity = "Common",
		mountable = false,
		size = Vector3.new(2.5, 1.2, 2.5),
		trianglesLOD0 = 1200, -- budget max 1500
		trianglesLOD1 = 600,
	},
	{
		id = "CushionStar",
		name = "Cushion Star",
		rarity = "Common",
		mountable = false,
		size = Vector3.new(2.5, 0.6, 2.5),
		trianglesLOD0 = 1000,
		trianglesLOD1 = 500,
	},
	{
		id = "Lionfish",
		name = "Lionfish",
		rarity = "Uncommon",
		mountable = false,
		size = Vector3.new(2.8, 1.5, 1.8),
		trianglesLOD0 = 1400,
		trianglesLOD1 = 700,
	},
	{
		id = "HawksbillTurtle",
		name = "Hawksbill Turtle",
		rarity = "Uncommon",
		mountable = true,
		size = Vector3.new(7.5, 2.8, 4.5),
		trianglesLOD0 = 1500,
		trianglesLOD1 = 750,
		saddleOffset = Vector3.new(0, 1.4, 0),
		surfStandOffset = Vector3.new(0, 1.7, 0),
	},
	{
		id = "BlueRingedOctopus",
		name = "Blue-ringed Octopus",
		rarity = "Rare",
		mountable = false,
		size = Vector3.new(1.8, 0.8, 1.8),
		trianglesLOD0 = 1300,
		trianglesLOD1 = 650,
	},
	{
		id = "LeopardRay",
		name = "Leopard Ray",
		rarity = "Rare",
		mountable = true,
		size = Vector3.new(5.0, 0.8, 8.0),
		trianglesLOD0 = 1400,
		trianglesLOD1 = 700,
		saddleOffset = Vector3.new(0, 0.4, 0),
		surfStandOffset = Vector3.new(0, 0.7, 0),
	},
	{
		id = "GiantPacificOctopus",
		name = "Giant Pacific Octopus",
		rarity = "Epic",
		mountable = false,
		size = Vector3.new(4.0, 1.5, 4.0),
		trianglesLOD0 = 1500,
		trianglesLOD1 = 750,
	},
	{
		id = "LionsManeJelly",
		name = "Lion's Mane Jelly",
		rarity = "Epic",
		mountable = false,
		size = Vector3.new(3.0, 4.0, 3.0),
		trianglesLOD0 = 1500,
		trianglesLOD1 = 750,
	},
	{
		id = "MantaRay",
		name = "Manta Ray",
		rarity = "Legendary",
		mountable = true,
		size = Vector3.new(10.0, 1.0, 8.0),
		trianglesLOD0 = 1500,
		trianglesLOD1 = 750,
		saddleOffset = Vector3.new(0, 0.5, 0),
		surfStandOffset = Vector3.new(0, 0.8, 0),
	},
	{
		id = "WhaleShark",
		name = "Whale Shark",
		rarity = "Legendary",
		mountable = true,
		size = Vector3.new(15.0, 4.0, 6.0),
		trianglesLOD0 = 1500,
		trianglesLOD1 = 750,
		saddleOffset = Vector3.new(0, 2.0, -1.0),
		surfStandOffset = Vector3.new(0, 2.3, -1.0),
	},
}

-- Couleurs de base par rareté (pour placeholder visuel)
local RARITY_COLORS = {
	Common = Color3.fromRGB(215, 215, 215),
	Uncommon = Color3.fromRGB(95, 225, 125),
	Rare = Color3.fromRGB(75, 165, 255),
	Epic = Color3.fromRGB(185, 95, 255),
	Legendary = Color3.fromRGB(255, 195, 45),
}

-- Matériaux par rareté (pour placeholder)
local RARITY_MATERIALS = {
	Common = Enum.Material.Sand,
	Uncommon = Enum.Material.Slate,
	Rare = Enum.Material.CorrodedMetal,
	Epic = Enum.Material.Foil,
	Legendary = Enum.Material.Foil,
}

-- Créer un modèle LOD (LOD0 = full, LOD1 = simplified placeholder)
local function createLODModel(def, lodLevel)
	local model = Instance.new("Model")
	model.Name = def.id .. (lodLevel == 0 and "_LOD0" or "_LOD1")

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(0.2, 0.2, 0.2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.CanQuery = false
	root.Massless = true
	root.Parent = model

	-- Body placeholder (différent selon LOD)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = def.size
	body.Color = RARITY_COLORS[def.rarity] or Color3.new(1, 1, 1)
	body.Material = RARITY_MATERIALS[def.rarity] or Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.CanTouch = false
	body.CanQuery = false
	body.Massless = true
	body.CFrame = CFrame.new(0, def.size.Y / 2, 0)
	body.Parent = model

	-- Marquer le niveau LOD
	model:SetAttribute("LODLevel", lodLevel)
	model:SetAttribute("TargetTriangles", lodLevel == 0 and def.trianglesLOD0 or def.trianglesLOD1)

	-- Attributs requis (sur LOD0 seulement, LOD1 hérite via le parent final)
	if lodLevel == 0 then
		model:SetAttribute("CreatureId", def.id)
		model:SetAttribute("Rarity", def.rarity)
		model.PrimaryPart = root

		-- Attachments pour montables
		if def.mountable and def.saddleOffset and def.surfStandOffset then
			local saddle = Instance.new("Attachment")
			saddle.Name = "Saddle"
			saddle.Position = def.saddleOffset
			saddle.Axis = Vector3.new(0, 0, -1)
			saddle.SecondaryAxis = Vector3.new(0, 1, 0)
			saddle.Parent = root

			local surfStand = Instance.new("Attachment")
			surfStand.Name = "SurfStand"
			surfStand.Position = def.surfStandOffset
			surfStand.Axis = Vector3.new(0, 0, -1)
			surfStand.SecondaryAxis = Vector3.new(0, 1, 0)
			surfStand.Parent = root

			log(string.format("  %s LOD0 : Saddle à %s, SurfStand à %s", def.id, tostring(def.saddleOffset), tostring(def.surfStandOffset)))
		end
	end

	return model
end

-- Assembler le modèle final avec LOD0 + LOD1 + config Model.LOD
local function assembleCreatureModel(def)
	local lod0 = createLODModel(def, 0)
	local lod1 = createLODModel(def, 1)

	-- Le modèle final = LOD0 (contient Root, Body, Saddle, SurfStand)
	-- LOD1 sera parenté sous LOD0 et activé via Model.LOD
	lod1.Parent = lod0
	lod1.Name = "LOD1"

	-- Configurer Model.LOD (Roblox automatique si MeshPart.RenderFidelity = Automatic)
	-- Ici on prépare : le mesh réel doit avoir MeshPart.RenderFidelity = Automatic
	-- et on ajoute un script de config LOD distances au modèle
	local lodConfig = Instance.new("Folder")
	lodConfig.Name = "LODConfig"
	lodConfig.Parent = lod0

	-- Distances Mobile (plus agressives)
	local mobileNear = Instance.new("NumberValue")
	mobileNear.Name = "MobileNear"
	mobileNear.Value = 80
	mobileNear.Parent = lodConfig

	local mobileMid = Instance.new("NumberValue")
	mobileMid.Name = "MobileMid"
	mobileMid.Value = 160
	mobileMid.Parent = lodConfig

	local mobileFar = Instance.new("NumberValue")
	mobileFar.Name = "MobileFar"
	mobileFar.Value = 300
	mobileFar.Parent = lodConfig

	-- Distances PC (plus généreuses)
	local pcNear = Instance.new("NumberValue")
	pcNear.Name = "PCNear"
	pcNear.Value = 120
	pcNear.Parent = lodConfig

	local pcMid = Instance.new("NumberValue")
	pcMid.Name = "PCMid"
	pcMid.Value = 250
	pcMid.Parent = lodConfig

	local pcFar = Instance.new("NumberValue")
	pcFar.Name = "PCFar"
	pcFar.Value = 500
	pcFar.Parent = lodConfig

	return lod0
end

local function build()
	local creaturesFolder = not DRY_RUN and folder(assets, "Creatures") or nil

	for _, def in ipairs(CREATURES) do
		log(string.format("Créature : %s (%s) %s | LOD0:%d tri / LOD1:%d tri",
			def.name, def.rarity, def.mountable and "[MONTABLE]" or "", def.trianglesLOD0, def.trianglesLOD1))
		local model = assembleCreatureModel(def)
		if creaturesFolder then
			replace(creaturesFolder, model)
		end
	end

	-- Dossier pour les animations Rthro (bundle 356) - à importer manuellement
	if not DRY_RUN then
		local animFolder = folder(assets, "Animations")
		local rthroFolder = folder(animFolder, "RthroBundle356")
		log("Dossier Animations/RthroBundle356 créé. Importer les 6 animations manuellement.")
	end

	-- Mettre à jour Config.CrossPlatform avec les distances LOD différenciées
	if not DRY_RUN then
		local config = RS:FindFirstChild("Shared") and RS.Shared:FindFirstChild("Config")
		if config and config:IsA("ModuleScript") then
			log("NOTE : Mettre à jour Config.CrossPlatform.LODDistancesMobile/PC manuellement dans Config.lua")
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a été modifié. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("K : 10 modèles créatures (LOD0 + LOD1 + distances Mobile/PC)")
	assert(rec, "[K] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("Structure LOD créée. Prochaines étapes :")
		log("1. Importer vrais meshes dans Assets.Creatures.<Species> (remplace Body LOD0)")
		log("2. Créer LOD1 simplifié (~50% triangles) ou laisser Roblox auto-générer via MeshPart.RenderFidelity=Automatic")
		log("3. MeshPart.RenderFidelity = Enum.RenderFidelity.Automatic sur tous les MeshParts")
		log("4. Vérifier Saddle/SurfStand sur les 4 montables (tortue, raie léopard, raie manta, requin-baleine)")
		log("5. Importer Rthro Animation Pack 356 : Idle, Walk, Swim, Carry, Mount, Surf")
		log("6. Lancer build_mutation_fx.luau + build_royal_fx.luau")
		log("7. CreatureRenderer : lire UserInputService.TouchEnabled pour choisir distances Mobile/PC")
	else
		warn("[K] erreur, tout est annulé : " .. tostring(err))
	end
end