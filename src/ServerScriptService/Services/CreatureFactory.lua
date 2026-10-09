-- CreatureFactory : clone les creatures d'Assets.Creatures, pretes a poser (plage ou bassin).
-- Repli tant que les modeles de C manquent : Assets.Items.<ancien tresor> (Config.LegacyItemToCreature),
-- puis une boule de couleur. Le client anime (tag TR_Spin) et applique stade et mutation ; le serveur ne bouge rien.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CreatureFactory = {}

local SPIN_TAG = "TR_Spin"
local SPIN_MIN, SPIN_MAX = 35, 60 -- degres par seconde
local BEACON_HEIGHT = 42
local BEACON_MIN_ORDER = 4 -- Epic et au-dessus
local BEACON_STYLE_NAMES = { "Core", "Halo" } -- Beams fournis par C dans Assets.FX.RarityBeam
local PLACEHOLDER_SIZE = 1.6

local rng = Random.new()
local restOffsets = {}
-- [species] = anciens ids : Assets.Creatures.<id du GDD v2> si C en a deja pose, puis Assets.Items.<tresor v1>
local legacyCreatures, legacyOf = {}, {}
for oldId, species in pairs(Config.LegacyItemToCreature) do
	if Config.Items[oldId] then
		legacyOf[species] = oldId
	else
		legacyCreatures[species] = oldId
	end
end

local warnedFallback = {}
local warnedNoStyle = false

local function assetFolder(name)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild(name)
end

-- Modele de la creature, ou celui de l'ancien tresor, ou nil
local function template(species)
	local creatures = assetFolder("Creatures")
	local model = creatures and (creatures:FindFirstChild(species)
		or (legacyCreatures[species] and creatures:FindFirstChild(legacyCreatures[species])))
	if model then
		return model
	end
	local items = assetFolder("Items")
	model = items and legacyOf[species] and items:FindFirstChild(legacyOf[species])
	if not warnedFallback[species] then
		warnedFallback[species] = true
		warn(("[TideRush] Assets.Creatures.%s manquant : repli sur %s"):format(
			species, model and ("Assets.Items." .. legacyOf[species]) or "une boule"))
	end
	return model
end

local function placeholder(species)
	local def = Config.Creatures[species]
	local rarity = def and Config.Rarities[def.rarity]
	local model = Instance.new("Model")
	model.Name = species
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Shape = Enum.PartType.Ball
	root.Size = Vector3.one * PLACEHOLDER_SIZE
	root.Color = rarity and rarity.color or Color3.new(1, 1, 1)
	root.Material = Enum.Material.SmoothPlastic
	root.Parent = model
	model.PrimaryPart = root
	return model
end

-- Hauteur entre le pivot du modele et le bas de sa boite : pour poser la creature sans qu'elle s'enfonce
function CreatureFactory.RestOffset(species)
	local cached = restOffsets[species]
	if cached then
		return cached
	end
	local model = template(species)
	if not model then
		return PLACEHOLDER_SIZE / 2
	end
	local boxCf, boxSize = model:GetBoundingBox()
	local offset = model:GetPivot().Position.Y - (boxCf.Position.Y - boxSize.Y / 2)
	restOffsets[species] = offset
	return offset
end

-- Beams Core et Halo fournis par C (Assets.FX.RarityBeam) ; liste vide s'ils manquent
local function beaconStyle()
	local fx = assetFolder("FX")
	local style = fx and fx:FindFirstChild("RarityBeam")
	local beams = {}
	for _, name in ipairs(BEACON_STYLE_NAMES) do
		local beam = style and style:FindFirstChild(name, true)
		if beam and beam:IsA("Beam") then
			table.insert(beams, beam)
		end
	end
	if #beams == 0 and not warnedNoStyle then
		warnedNoStyle = true
		warn("[TideRush] Assets.FX.RarityBeam (Core/Halo) introuvable : creatures Epic/Legendary sans faisceau")
	end
	return beams
end

-- Faisceau vertical pour reperer les Epic et Legendary de loin
local function addBeacon(root, color)
	local style = beaconStyle()
	if #style == 0 then
		return
	end
	local bottom = Instance.new("Attachment")
	bottom.Name = "BeamA"
	bottom.Parent = root
	local top = Instance.new("Attachment")
	top.Name = "BeamB"
	top.Position = Vector3.new(0, BEACON_HEIGHT, 0)
	top.Parent = root
	for _, source in ipairs(style) do
		local beam = source:Clone()
		beam.Attachment0 = bottom
		beam.Attachment1 = top
		beam.Color = ColorSequence.new(color)
		beam.Parent = root
	end
end

-- opts = { mutation = string, stage = number, zone = number, bob = number, beacon = boolean,
--          slot = number?, uid = string?, born = number?, owner = number?, royal = boolean?, noSpin = boolean? }
function CreatureFactory.Create(species, basePos, opts)
	local def = Config.Creatures[species]
	if not def then
		warn("[TideRush] espece inconnue : " .. tostring(species))
		return nil
	end
	local source = template(species)
	local model = if source then source:Clone() else placeholder(species)
	model.Name = species
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	-- les attributs de l'ancien tresor ne doivent pas tromper le client
	model:SetAttribute("ItemId", nil)
	local yaw = rng:NextNumber(0, 360)
	model:SetAttribute("CreatureId", species)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", opts.mutation or "")
	model:SetAttribute("Stage", opts.stage or 1)
	model:SetAttribute("Zone", opts.zone or 0)
	model:SetAttribute("BasePos", basePos)
	model:SetAttribute("BaseYaw", yaw)
	model:SetAttribute("SpinSpeed", rng:NextNumber(SPIN_MIN, SPIN_MAX))
	model:SetAttribute("Bob", opts.bob or 0)
	if opts.slot then
		model:SetAttribute("Slot", opts.slot)
	end
	if opts.uid then
		model:SetAttribute("Uid", opts.uid)
	end
	if opts.born then
		model:SetAttribute("Born", opts.born)
	end
	if opts.owner then
		model:SetAttribute("Owner", opts.owner)
	end
	if opts.royal then
		model:SetAttribute("Royal", true)
	end
	model:PivotTo(CFrame.new(basePos) * CFrame.Angles(0, math.rad(yaw), 0))

	local rarity = Config.Rarities[def.rarity]
	if opts.beacon and rarity and rarity.order >= BEACON_MIN_ORDER and model.PrimaryPart then
		addBeacon(model.PrimaryPart, rarity.color)
	end
	if not opts.noSpin then
		CollectionService:AddTag(model, SPIN_TAG)
	end
	return model
end

return CreatureFactory
