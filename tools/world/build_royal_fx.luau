-- tools/world/build_royal_fx.luau
-- C : Marée Royale (GDD §4.8). Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--  * ReplicatedStorage.Assets.FX.Crowns.Gold / Silver / Bronze : Accessory (Humanoid:AddAccessory), couronne qui flotte
--    au-dessus de la tete. Un seul modele de couronne recolore (importer d'abord le candidat de docs/SOURCING_C.md dans _DecorLib).
--  * ReplicatedStorage.Assets.FX.Royal : effet de la creature royale (meme principe que FX.RarityBeam) :
--    Core et Halo (Beams a mettre entre Root.BeamA et Root.BeamB, comme les faisceaux de rarete), Glow (PointLight, 1 par serveur),
--    Sparkle (ParticleEmitter a mettre dans Root), MiniCrown (Model ancre a placer au-dessus du modele, attribut OffsetY).

local DRY_RUN = true

local FIND_CROWN = { "crown", "couronne" }
local CROWN_WIDTH = 2.2 -- studs : plus large que la tete (1,2) pour se lire de loin
local CROWN_FLOAT = 1.2 -- ecart entre le haut de la tete et le bas de la couronne

local RANKS = {
	Gold = { color = Color3.fromHex("FFC93C"), material = Enum.Material.Foil },
	Silver = { color = Color3.fromHex("D9DEE6"), material = Enum.Material.Foil },
	Bronze = { color = Color3.fromHex("C98A4B"), material = Enum.Material.Foil },
}
local GOLD = RANKS.Gold.color

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local assets = RS:FindFirstChild("Assets")
assert(assets, "[C] ReplicatedStorage.Assets introuvable")
local lib = assets:FindFirstChild("_DecorLib")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
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

local function findCrown()
	if not lib then
		return nil
	end
	for _, pattern in FIND_CROWN do
		for _, d in lib:GetDescendants() do
			if (d:IsA("Model") or d:IsA("BasePart")) and string.find(string.lower(d.Name), pattern, 1, true) then
				return d
			end
		end
	end
	return nil
end

local function sparkle(color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Sparkle" -- texture par defaut de Roblox (etincelles)
	e.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	e.LightEmission = 0.6
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.8, 1.2)
	e.Rate = rate
	e.Speed = NumberRange.new(0.4, 0.9)
	e.SpreadAngle = Vector2.new(180, 180)
	return e
end

-- Couronne recoloree : renvoie (handle, parts) prets a etre assembles, ou nil
local function crownParts(template, rank)
	local c = template:Clone()
	for _, d in c:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			warn("[C] script retire : " .. d:GetFullName())
			d:Destroy()
		end
	end
	if c:IsA("Model") then
		c:ScaleTo(c:GetScale() * CROWN_WIDTH / math.max(c:GetExtentsSize().X, c:GetExtentsSize().Z))
	else
		c.Size *= CROWN_WIDTH / math.max(c.Size.X, c.Size.Z)
	end
	local parts = c:IsA("BasePart") and { c } or {}
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	-- la plus grosse piece = Handle, recoloree (texture retiree pour que la couleur se voie) ; les autres (pierres) gardent leur couleur
	table.sort(parts, function(a, b)
		return a.Size.Magnitude > b.Size.Magnitude
	end)
	local handle = parts[1]
	for _, d in handle:GetChildren() do
		if d:IsA("SurfaceAppearance") then
			d:Destroy()
		end
	end
	if handle:IsA("MeshPart") then
		handle.TextureID = ""
	end
	handle.Color = RANKS[rank].color
	handle.Material = RANKS[rank].material
	handle.Reflectance = 0.1
	for _, p in parts do
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.CastShadow = false
	end
	return handle, parts, c
end

local function buildCrown(template, rank)
	local handle, parts, root = crownParts(template, rank)
	local acc = Instance.new("Accessory")
	acc.Name = rank
	-- toutes les pieces sous le Handle, soudees, non ancrees (portees par le personnage)
	for _, p in parts do
		p.Anchored = false
		p.Massless = true
		if p ~= handle then
			local w = Instance.new("WeldConstraint")
			w.Part0 = handle
			w.Part1 = p
			w.Parent = p
			p.Parent = handle
		end
	end
	handle.Name = "Handle"
	handle.Parent = acc
	if root ~= handle then
		root:Destroy()
	end
	local att = Instance.new("Attachment")
	att.Name = "HatAttachment"
	att.Position = Vector3.new(0, -(handle.Size.Y / 2 + CROWN_FLOAT), 0)
	att.Parent = handle
	local fx = sparkle(RANKS[rank].color, 3)
	fx.Parent = handle
	return acc
end

local function beam(name, width, transparency)
	local b = Instance.new("Beam")
	b.Name = name
	b.Color = ColorSequence.new(GOLD)
	b.LightEmission = 1
	b.FaceCamera = true
	b.Width0 = width
	b.Width1 = width * 0.6
	b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, transparency), NumberSequenceKeypoint.new(1, 1) })
	b.Segments = 1
	return b
end

local function build()
	local fx = not DRY_RUN and folder(assets, "FX") or nil
	local template = findCrown()

	-- 1. Couronnes
	if template then
		log("couronnes a partir de " .. template:GetFullName() .. " : Gold, Silver, Bronze")
		if not DRY_RUN then
			local crowns = folder(fx, "Crowns")
			for rank in RANKS do
				replace(crowns, buildCrown(template, rank))
			end
		end
	else
		warn("[C] aucune couronne dans _DecorLib : importer un candidat de docs/SOURCING_C.md, puis relancer")
	end

	-- 2. Creature royale
	log("FX.Royal : Core, Halo, Glow, Sparkle" .. (template and ", MiniCrown" or ""))
	if not DRY_RUN then
		local royal = Instance.new("Folder")
		royal.Name = "Royal"
		royal:SetAttribute("BeamTopOffset", 42) -- comme les faisceaux de rarete (Root.BeamB a Y+42)
		beam("Core", 1.6, 0.1).Parent = royal
		beam("Halo", 5, 0.7).Parent = royal
		local glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Color = GOLD
		glow.Range = 14
		glow.Brightness = 1.5
		glow.Shadows = false
		glow.Parent = royal
		sparkle(GOLD, 8).Parent = royal
		if template then
			local _, parts, root = crownParts(template, "Gold")
			local mini = Instance.new("Model")
			mini.Name = "MiniCrown"
			mini:SetAttribute("OffsetY", 1) -- studs au-dessus du haut du modele
			for _, p in parts do
				p.Anchored = true -- dans le modele de la creature, il suit son PivotTo
				p.Parent = mini
			end
			if root:IsA("Model") then
				root:Destroy() -- pieces deja deplacees dans MiniCrown
			end
			mini.PrimaryPart = parts[1]
			mini:ScaleTo(0.5)
			mini.Parent = royal
		end
		replace(fx, royal)
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : Maree Royale (couronnes, FX royal)")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("termine. Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
