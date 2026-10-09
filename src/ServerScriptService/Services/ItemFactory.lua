-- ItemFactory : clone les tresors d'Assets.Items, prets a poser (plage ou socle).
-- Le client les fait tourner et flotter (tag TR_Spin) ; le serveur ne les bouge jamais.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ItemFactory = {}

local SPIN_TAG = "TR_Spin"
local SPIN_MIN, SPIN_MAX = 35, 60 -- degres par seconde
local BEACON_HEIGHT = 42
local BEACON_MIN_ORDER = 4 -- Epic et au-dessus
local BEACON_STYLE_NAMES = { "Core", "Halo" } -- Beams fournis par C dans Assets.FX.RarityBeam

local rng = Random.new()
local restOffsets = {}

local function template(itemId)
	local items = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Items")
	return items and items:FindFirstChild(itemId)
end

-- Hauteur entre le pivot du modele et le bas de sa boite : pour poser l'objet sans qu'il s'enfonce
function ItemFactory.RestOffset(itemId)
	local cached = restOffsets[itemId]
	if cached then
		return cached
	end
	local model = template(itemId)
	if not model then
		return 1
	end
	local boxCf, boxSize = model:GetBoundingBox()
	local offset = model:GetPivot().Position.Y - (boxCf.Position.Y - boxSize.Y / 2)
	restOffsets[itemId] = offset
	return offset
end

local warnedNoStyle = false

-- Beams Core et Halo fournis par C (Assets.FX.RarityBeam) ; liste vide s'ils manquent
local function beaconStyle()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local fx = assets and assets:FindFirstChild("FX")
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
		warn("[TideRush] Assets.FX.RarityBeam (Core/Halo) introuvable : tresors Epic/Legendary sans faisceau")
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

-- opts = { zone = number, bob = number, slot = number?, beacon = boolean }
function ItemFactory.Create(itemId, basePos, opts)
	local def = Config.Items[itemId]
	local source = template(itemId)
	if not def or not source then
		warn("[TideRush] modele de tresor introuvable : " .. tostring(itemId))
		return nil
	end
	local model = source:Clone()
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		end
	end
	local yaw = rng:NextNumber(0, 360)
	model:SetAttribute("ItemId", itemId)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Zone", opts.zone or 0)
	model:SetAttribute("BasePos", basePos)
	model:SetAttribute("BaseYaw", yaw)
	model:SetAttribute("SpinSpeed", rng:NextNumber(SPIN_MIN, SPIN_MAX))
	model:SetAttribute("Bob", opts.bob or 0)
	if opts.slot then
		model:SetAttribute("Slot", opts.slot)
	end
	model:PivotTo(CFrame.new(basePos) * CFrame.Angles(0, math.rad(yaw), 0))

	local rarity = Config.Rarities[def.rarity]
	if opts.beacon and rarity and rarity.order >= BEACON_MIN_ORDER and model.PrimaryPart then
		addBeacon(model.PrimaryPart, rarity.color)
	end
	CollectionService:AddTag(model, SPIN_TAG)
	return model
end

return ItemFactory
