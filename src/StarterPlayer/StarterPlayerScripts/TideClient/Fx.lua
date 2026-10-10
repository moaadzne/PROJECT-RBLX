-- Fx : effets visuels cote client (particules, secousse camera, flash, fondu, lueur des bords,
-- confettis UI, icones volantes). Particules : Assets.FX (contrat FX v1 de C), sinon repli integre.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Fx = {}

local DEFAULT_EMIT = 20
local SHAKE_DECAY = 1.6 -- trauma perdu par seconde
local SHAKE_MAX_ANGLE = math.rad(1.6)
local SHAKE_MAX_OFFSET = 0.35
local EDGE_DEPTH = 0.22 -- part de l'ecran couverte par la lueur des bords
-- eclats sobres (or, blanc, turquoise du lagon) : pas de couleurs bonbon (DIRECTION_V2)
local CONFETTI_COLORS = {
	Color3.fromRGB(240, 190, 70),
	Color3.fromRGB(242, 245, 248),
	Color3.fromRGB(38, 196, 196),
	Color3.fromRGB(200, 160, 80),
}

local Util, Settings, Theme
local layer: Frame -- calque plein ecran sans UIScale (icones volantes, confettis)
local flashFrame: Frame
local fadeFrame: Frame
local edges: { Frame } = {}
local worldFolder: Folder? = nil

local trauma = 0 -- secousse ponctuelle (decroit)
local rumble = 0 -- secousse continue (pilotee par la vague)

---------------------------------------------------------------- Monde
function Fx.GetWorldFolder(): Folder
	if worldFolder and worldFolder.Parent then
		return worldFolder
	end
	local f = Instance.new("Folder")
	f.Name = "TR_ClientFX"
	f.Parent = workspace
	worldFolder = f
	return f
end

local function anchorPart(cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = "FxAnchor"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = cf
	return p
end

-- Repli si Assets.FX.<name> manque : petite gerbe d'etincelles
local function fallbackEmitter(parent: Instance, color: Color3?)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Enabled = false
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.35, 0.7)
	pe.Speed = NumberRange.new(8, 16)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -20, 0)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.LightEmission = 0.7
	pe.Color = ColorSequence.new(color or Color3.new(1, 1, 1))
	pe:SetAttribute("EmitCount", 18)
	pe.Parent = parent
end

-- Porteur des emetteurs : clone du modele de C, ou part neutre + repli
local function buildHolder(name: string, cf: CFrame, color: Color3?): BasePart
	local template = Util.Find(ReplicatedStorage, "Assets", "FX", name)
	if template and template:IsA("BasePart") then
		local holder = template:Clone()
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanQuery = false
		holder.CanTouch = false
		holder.Transparency = 1
		holder.CFrame = cf
		return holder
	end
	local holder = anchorPart(cf)
	fallbackEmitter(holder, color)
	return holder
end

-- Fait jaillir un effet. opts : color (teinte les emetteurs Tintable), scale (x nombre de particules)
function Fx.Emit(name: string, at: Vector3 | CFrame, opts: { color: Color3?, scale: number? }?)
	local o = opts or {}
	local cf = if typeof(at) == "CFrame" then at else CFrame.new(at)
	local holder = buildHolder(name, cf, o.color)
	holder.Parent = Fx.GetWorldFolder()
	local mult = (o.scale or 1) * (if Settings.IsLowGraphics() then 0.5 else 1)
	local longest = 0
	for _, pe in holder:GetDescendants() do
		if pe:IsA("ParticleEmitter") then
			if o.color and pe:GetAttribute("Tintable") == true then
				pe.Color = ColorSequence.new(o.color)
			end
			pe.Enabled = false
			local base = tonumber(pe:GetAttribute("EmitCount")) or DEFAULT_EMIT
			pe:Emit(math.max(1, math.floor(base * mult)))
			longest = math.max(longest, pe.Lifetime.Max)
		end
	end
	Debris:AddItem(holder, longest + 0.5)
end

---------------------------------------------------------------- Camera
-- Secousse ponctuelle : amount 0..1 (s'ajoute, plafonne a 1) ; coupee si "reduire les animations"
function Fx.Shake(amount: number)
	if Settings.Get("reducedMotion") then
		return
	end
	trauma = math.min(1, trauma + amount)
end

-- Secousse continue 0..1 (la vague qui approche). 0 pour arreter.
function Fx.SetRumble(level: number)
	rumble = math.clamp(level, 0, 1)
end

local function onCameraStep(dt: number)
	trauma = math.max(0, trauma - SHAKE_DECAY * dt)
	local level = math.max(trauma, if Settings.IsLowGraphics() then rumble * 0.5 else rumble)
	if level <= 0.001 or Settings.Get("reducedMotion") then
		return
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local k = level * level
	local t = os.clock() * 22
	local rx = math.noise(t, 1.3) * SHAKE_MAX_ANGLE * k
	local ry = math.noise(t, 7.1) * SHAKE_MAX_ANGLE * k
	local rz = math.noise(t, 13.7) * SHAKE_MAX_ANGLE * k * 0.6
	local ox = math.noise(t, 21.9) * SHAKE_MAX_OFFSET * k
	local oy = math.noise(t, 31.3) * SHAKE_MAX_OFFSET * k
	cam.CFrame = cam.CFrame * CFrame.new(ox, oy, 0) * CFrame.Angles(rx, ry, rz)
end

---------------------------------------------------------------- Ecran
-- Flash plein ecran : monte a `strength` puis s'efface en `duration` secondes
function Fx.Flash(color: Color3?, strength: number?, duration: number?)
	flashFrame.BackgroundColor3 = color or Color3.new(1, 1, 1)
	flashFrame.BackgroundTransparency = 1 - math.clamp(strength or 0.6, 0, 1)
	Util.Tween(flashFrame, duration or 0.35, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quad)
end

-- Fondu au noir : alpha 1 = ecran noir, 0 = transparent. Renvoie le tween.
function Fx.Fade(alpha: number, duration: number?): Tween
	local target = 1 - math.clamp(alpha, 0, 1)
	return Util.Tween(fadeFrame, duration or 0.3, { BackgroundTransparency = target }, Enum.EasingStyle.Quad)
end

-- Lueur sur les bords de l'ecran (danger) : alpha 0..1, appele chaque frame par la vague
function Fx.SetEdgeGlow(color: Color3, alpha: number)
	local a = math.clamp(alpha, 0, 1)
	for _, edge in edges do
		edge.BackgroundColor3 = color
		edge.BackgroundTransparency = 1 - a * 0.55
		edge.Visible = a > 0.01
	end
end

function Fx.GetLayer(): Frame
	return layer
end

-- Confettis UI depuis un point viewport (ex. Util.GuiCenterViewport(bouton))
function Fx.Confetti(fromViewport: Vector2, count: number?)
	local n = count or 26
	if Settings.IsLowGraphics() then
		n = math.floor(n / 2)
	end
	if Settings.Get("reducedMotion") then
		n = math.floor(n / 3)
	end
	local origin = Util.ViewportToLayer(layer, fromViewport)
	for i = 1, n do
		local size = math.random(6, 11)
		local piece = Instance.new("Frame")
		piece.Name = "Confetti"
		piece.BorderSizePixel = 0
		piece.AnchorPoint = Vector2.new(0.5, 0.5)
		piece.Size = UDim2.fromOffset(size, math.floor(size * 0.6))
		piece.Position = UDim2.fromOffset(origin.X, origin.Y)
		piece.BackgroundColor3 = CONFETTI_COLORS[(i % #CONFETTI_COLORS) + 1]
		piece.Rotation = math.random(0, 360)
		piece.ZIndex = 20
		piece.Parent = layer
		local angle = math.rad(math.random(200, 340)) -- vers le haut, en eventail
		local peak = origin + Vector2.new(math.cos(angle), math.sin(angle)) * math.random(70, 170)
		local fall = peak + Vector2.new(math.random(-30, 30), math.random(60, 120))
		local up = math.random(28, 40) / 100
		Util.Tween(piece, up, {
			Position = UDim2.fromOffset(peak.X, peak.Y),
			Rotation = piece.Rotation + math.random(-180, 180),
		}, Enum.EasingStyle.Quad)
		Util.Tween(piece, 0.7, {
			Position = UDim2.fromOffset(fall.X, fall.Y),
			BackgroundTransparency = 1,
		}, Enum.EasingStyle.Quad, Enum.EasingDirection.In, up)
		Debris:AddItem(piece, up + 0.8)
	end
end

-- Fait voler un element d'interface d'un point viewport vers une cible du HUD, en arc.
-- element : GuiObject deja construit (reparente dans le calque, detruit a l'arrivee).
function Fx.FlyTo(element: GuiObject, fromViewport: Vector2, target: GuiObject, duration: number?, onArrive: (() -> ())?)
	local d = duration or 0.5
	local from = Util.ViewportToLayer(layer, fromViewport)
	element.AnchorPoint = Vector2.new(0.5, 0.5)
	element.Position = UDim2.fromOffset(from.X, from.Y)
	element.ZIndex = math.max(element.ZIndex, 15)
	element.Parent = layer
	local scale = Theme.GetScale(element)
	scale.Scale = 0.4
	Util.Tween(scale, 0.12, { Scale = 1.15 }, Enum.EasingStyle.Back)
	task.spawn(function()
		local to = Util.ViewportToLayer(layer, Util.GuiCenterViewport(target))
		-- arc : passe au-dessus du trajet direct
		local mid = (from + to) / 2 + Vector2.new(0, -math.min(120, (to - from).Magnitude * 0.35))
		local half = d / 2
		Util.Tween(element, half, { Position = UDim2.fromOffset(mid.X, mid.Y) }, Enum.EasingStyle.Sine)
		task.wait(half)
		if not element.Parent then
			return
		end
		to = Util.ViewportToLayer(layer, Util.GuiCenterViewport(target))
		Util.Tween(element, half, { Position = UDim2.fromOffset(to.X, to.Y) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Util.Tween(scale, half, { Scale = 0.55 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.wait(half)
		element:Destroy()
		if onArrive then
			onArrive()
		end
	end)
end

---------------------------------------------------------------- Construction
local function fullFrame(name: string, color: Color3, z: number, parent: Instance): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = color
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Size = UDim2.fromScale(1, 1)
	f.ZIndex = z
	f.Active = false
	f.Parent = parent
	return f
end

-- 4 bandes en degrade (transparence) collees aux bords
local function buildEdges(parent: Instance)
	local specs = {
		{ UDim2.fromScale(1, EDGE_DEPTH), UDim2.fromScale(0, 0), 90 },
		{ UDim2.fromScale(1, EDGE_DEPTH), UDim2.fromScale(0, 1 - EDGE_DEPTH), 270 },
		{ UDim2.fromScale(EDGE_DEPTH * 0.6, 1), UDim2.fromScale(0, 0), 0 },
		{ UDim2.fromScale(EDGE_DEPTH * 0.6, 1), UDim2.fromScale(1 - EDGE_DEPTH * 0.6, 0), 180 },
	}
	for i, spec in specs do
		local edge = fullFrame("Edge" .. i, Color3.new(1, 0, 0), 25, parent)
		edge.Size = spec[1]
		edge.Position = spec[2]
		edge.Visible = false
		local g = Instance.new("UIGradient")
		g.Rotation = spec[3]
		g.Transparency = NumberSequence.new(0, 1)
		g.Parent = edge
		table.insert(edges, edge)
	end
end

function Fx.Init(ctx)
	Util = ctx.Util
	Settings = ctx.Settings
	Theme = ctx.Theme
	local overlay = ctx.Overlay
	layer = fullFrame("FxLayer", Color3.new(0, 0, 0), 10, overlay)
	buildEdges(overlay)
	flashFrame = fullFrame("Flash", Color3.new(1, 1, 1), 30, overlay)
	fadeFrame = fullFrame("Fade", Color3.new(0, 0, 0), 40, overlay)
end

function Fx.Start(_ctx)
	RunService:BindToRenderStep("TR_CameraShake", Enum.RenderPriority.Camera.Value + 1, onCameraStep)
end

return Fx
