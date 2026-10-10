-- IconResolver : système "Font Awesome + fallback primitives"
-- Font Awesome 6 Free (SIL OFL) chargé via Glyph.lua (asset 12187624912)
-- Fallback silencieux : primitives Roblox (Frames + UIStroke) si FA indisponible.

local Theme -- injecté par Theme.Init

local IconResolver = {}

local Glyph -- chargé paresseusement

local function getGlyph()
	if Glyph == nil then
		local ok, mod = pcall(function()
			return require(script.Parent:WaitForChild("Glyph"))
		end)
		Glyph = ok and mod or false
	end
	return Glyph or nil
end

-- État mémoire
local faChecked = false
local faAvailable = false
local faFontFace: Font? = nil

-- Vérifie une fois si Font Awesome est disponible (silencieux)
local function ensureFontAwesome(): boolean
	if faChecked then
		return faAvailable
	end
	faChecked = true
	local glyph = getGlyph()
	if glyph then
		local font = glyph.GetFont()
		if font then
			faFontFace = font
			faAvailable = true
		end
	end
	return faAvailable
end

-- Renvoie true si Font Awesome est chargé (debug)
function IconResolver.IsFontAwesomeLoaded(): boolean
	return ensureFontAwesome()
end

-- Force le mode primitif (debug)
function IconResolver.ForcePrimitiveMode()
	faChecked = true
	faAvailable = false
	faFontFace = nil
end

-- Enregistre une primitive externe (icônes créatures, etc.)
function IconResolver.RegisterPrimitive(name: string, draw: (Instance, Color3, number) -> ())
	PRIMITIVES[string.lower(name)] = draw
end

-- Enregistre un alias externe
function IconResolver.RegisterAlias(from: string, to: string)
	ALIAS[string.lower(from)] = to
end

-- Marque une icône comme "toujours primitive" (silhouettes créatures : FA n'a pas ces formes)
function IconResolver.RegisterPriority(name: string)
	PRIORITY[string.lower(name)] = true
end

-- Mapping icône logique -> nom FA6 (alias vers Glyph.Codes)
local ALIAS = {
	chest = "chest",
	box = "chest",
	wave = "wave",
	water = "wave",
	shield = "shield",
	["shield-alt"] = "shield",
	star = "star",
	crown = "crown",
	arrow = "arrow",
	["arrow-right"] = "arrow",
	spark = "spark",
	bolt = "bolt",
	moon = "moon",
	lock = "lock",
	unlock = "unlock",
	coin = "coin",
	clock = "clock",
	alert = "alert",
	info = "info",
	close = "close",
	check = "check",
	net = "gem",
	dot = "star",
	shop = "chest",
	ride = "compass",
	down = "arrow-down",
	revenge = "bolt",
	trophy = "trophy",
	fire = "fire",
	key = "key",
	bag = "bag",
	users = "users",
	home = "home",
	settings = "cog",
	gear = "cog",
}

-- Primitives (fallback) — dessin Frames pur, aucune dépendance externe
local function makeBar(parent, cx, cy, w, h, rot, color, round, thickness)
	local f = Instance.new("Frame")
	f.Name = "Bar"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(cx, cy)
	f.Size = UDim2.fromScale(w, h)
	f.Rotation = rot
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.Parent = parent
	if round then
		Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
	end
	return f
end

local function makeRing(parent, cx, cy, d, color, thickness)
	local f = Instance.new("Frame")
	f.Name = "Ring"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(cx, cy)
	f.Size = UDim2.fromScale(d, d)
	f.BackgroundTransparency = 1
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.Parent = f
	return f
end

local PRIMITIVES = {}

PRIMITIVES.chest = function(p, c, t)
	makeRing(p, 0.5, 0.34, 0.36, c, t)
	local body = makeBar(p, 0.5, 0.64, 0.72, 0.5, 0, c, false)
	Instance.new("UICorner", body).CornerRadius = UDim.new(0, math.max(2, t * 2))
end

PRIMITIVES.wave = function(p, c, t)
	makeBar(p, 0.42, 0.38, 0.6, 0.13, -8, c, true)
	makeBar(p, 0.58, 0.62, 0.6, 0.13, -8, c, true)
end

PRIMITIVES.shield = function(p, c, t)
	makeBar(p, 0.5, 0.32, 0.64, 0.24, 0, c)
	makeBar(p, 0.5, 0.52, 0.46, 0.46, 45, c)
end

PRIMITIVES.star = function(p, c, t)
	makeBar(p, 0.5, 0.5, 0.5, 0.5, 45, c)
	makeBar(p, 0.5, 0.5, 0.12, 0.9, 0, c)
	makeBar(p, 0.5, 0.5, 0.9, 0.12, 0, c)
end

PRIMITIVES.crown = function(p, c, t)
	makeBar(p, 0.5, 0.74, 0.8, 0.14, 0, c)
	for _, spec in { { 0.18, 0.5, 0.22 }, { 0.5, 0.42, 0.3 }, { 0.82, 0.5, 0.22 } } do
		makeBar(p, spec[1], spec[2], spec[3], spec[3], 45, c)
	end
end

PRIMITIVES.arrow = function(p, c, t)
	makeBar(p, 0.56, 0.36, 0.5, 0.16, 40, c, true)
	makeBar(p, 0.56, 0.64, 0.5, 0.16, -40, c, true)
end

PRIMITIVES.spark = PRIMITIVES.star
PRIMITIVES.bolt = function(p, c, t)
	makeBar(p, 0.42, 0.34, 0.14, 0.46, 20, c)
	makeBar(p, 0.58, 0.66, 0.14, 0.46, 20, c)
	makeBar(p, 0.5, 0.5, 0.36, 0.12, 0, c)
end

PRIMITIVES.moon = function(p, c, t)
	makeRing(p, 0.5, 0.5, 0.7, c, t * 1.6)
end

PRIMITIVES.lock = function(p, c, t)
	makeRing(p, 0.5, 0.36, 0.42, c, t)
	local body = makeBar(p, 0.5, 0.66, 0.66, 0.44, 0, c)
	Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)
end

PRIMITIVES.unlock = function(p, c, t)
	makeRing(p, 0.66, 0.3, 0.42, c, t)
	local body = makeBar(p, 0.5, 0.66, 0.66, 0.44, 0, c)
	Instance.new("UICorner", body).CornerRadius = UDim.new(0, 6)
end

PRIMITIVES.coin = function(p, c, t)
	makeRing(p, 0.5, 0.5, 0.8, c, t)
	makeBar(p, 0.5, 0.5, 0.42, 0.42, 0, c, true)
end

PRIMITIVES.clock = function(p, c, t)
	makeRing(p, 0.5, 0.5, 0.74, c, t)
	makeBar(p, 0.5, 0.38, 0.09, 0.26, 0, c)
	makeBar(p, 0.6, 0.52, 0.22, 0.09, 0, c)
end

PRIMITIVES.alert = function(p, c, t)
	local d = Instance.new("Frame")
	d.AnchorPoint = Vector2.new(0.5, 0.5)
	d.Position = UDim2.fromScale(0.5, 0.5)
	d.Size = UDim2.fromScale(0.66, 0.66)
	d.Rotation = 45
	d.BackgroundTransparency = 1
	d.Parent = p
	local s = Instance.new("UIStroke")
	s.Color = c
	s.Thickness = t
	s.Parent = d
	makeBar(p, 0.5, 0.44, 0.1, 0.26, 0, c)
	makeBar(p, 0.5, 0.66, 0.1, 0.1, 0, c)
end

PRIMITIVES.info = function(p, c, t)
	makeRing(p, 0.5, 0.5, 0.8, c, t)
	makeBar(p, 0.5, 0.56, 0.1, 0.3, 0, c)
	makeBar(p, 0.5, 0.32, 0.1, 0.1, 0, c)
end

PRIMITIVES.close = function(p, c, t)
	makeBar(p, 0.5, 0.5, 0.7, 0.12, 45, c, true)
	makeBar(p, 0.5, 0.5, 0.7, 0.12, -45, c, true)
end

PRIMITIVES.check = function(p, c, t)
	makeBar(p, 0.4, 0.55, 0.3, 0.12, 45, c, true)
	makeBar(p, 0.62, 0.42, 0.55, 0.12, -45, c, true)
end

PRIMITIVES.revenge = PRIMITIVES.bolt
PRIMITIVES.shop = PRIMITIVES.chest
PRIMITIVES.box = PRIMITIVES.chest
PRIMITIVES.water = PRIMITIVES.wave
PRIMITIVES["shield-alt"] = PRIMITIVES.shield
PRIMITIVES["arrow-right"] = PRIMITIVES.arrow
PRIMITIVES.ride = function(p, c)
	for _, y in { 0.42, 0.68 } do
		makeBar(p, 0.36, y, 0.42, 0.13, -40, c, true)
		makeBar(p, 0.64, y, 0.42, 0.13, 40, c, true)
	end
end
PRIMITIVES.down = function(p, c)
	for _, y in { 0.34, 0.6 } do
		makeBar(p, 0.36, y, 0.42, 0.13, 40, c, true)
		makeBar(p, 0.64, y, 0.42, 0.13, -40, c, true)
	end
end
PRIMITIVES.net = PRIMITIVES.coin
PRIMITIVES.trophy = function(p, c, t)
	makeBar(p, 0.5, 0.34, 0.5, 0.3, 0, c)
	makeBar(p, 0.5, 0.62, 0.2, 0.2, 0, c)
	makeBar(p, 0.5, 0.74, 0.4, 0.1, 0, c)
end

-- Fallback ultime : point
local DOT = function(p, c)
	makeBar(p, 0.5, 0.5, 0.5, 0.5, 45, c)
end

-- Icônes qui ignorent Font Awesome (silhouettes créatures : FA6 n'a pas ces formes)
local PRIORITY: { [string]: boolean } = {}

function IconResolver.Resolve(name: string?, size: number, color: Color3?): GuiObject
	local c = color or (Theme and Theme.Colors and Theme.Colors.Text) or Color3.new(1, 1, 1)
	local key = string.lower(name or "dot")
	local thickness = math.max(1.5, size * 0.09)

	-- 1. Font Awesome si disponible (sauf icônes marquées "primitive only")
	if not PRIORITY[key] and ensureFontAwesome() then
		local glyph = getGlyph()
		local faName = ALIAS[key] or key
		local code = glyph and glyph.Code(faName)
		if code and faFontFace then
			local label = Instance.new("TextLabel")
			label.Name = "Icon_FA_" .. faName
			label.BackgroundTransparency = 1
			label.Size = UDim2.fromOffset(size, size)
			label.FontFace = faFontFace
			label.Text = code
			label.TextSize = math.floor(size * 0.85)
			label.TextColor3 = c
			label.TextXAlignment = Enum.TextXAlignment.Center
			label.TextYAlignment = Enum.TextYAlignment.Center
			return label
		end
	end

	-- 2. Primitive Roblox
	local primitive = PRIMITIVES[key] or PRIMITIVES[ALIAS[key] or ""] or DOT
	local holder = Instance.new("Frame")
	holder.Name = "Icon_Prim_" .. key
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(size, size)
	primitive(holder, c, thickness)
	return holder
end

-- Raccourcis
function IconResolver.Chest(size: number, color: Color3?)
	return IconResolver.Resolve("chest", size, color)
end
function IconResolver.Wave(size: number, color: Color3?)
	return IconResolver.Resolve("wave", size, color)
end
function IconResolver.Shield(size: number, color: Color3?)
	return IconResolver.Resolve("shield", size, color)
end
function IconResolver.Star(size: number, color: Color3?)
	return IconResolver.Resolve("star", size, color)
end
function IconResolver.Crown(size: number, color: Color3?)
	return IconResolver.Resolve("crown", size, color)
end
function IconResolver.Arrow(size: number, color: Color3?)
	return IconResolver.Resolve("arrow", size, color)
end

-- Remplace une icône existante par la version résolue (préserve position/ancrage)
function IconResolver.Replace(icon: Instance, name: string, size: number?, color: Color3?): GuiObject
	local useSize = size
	if not useSize then
		local ax = icon.AbsoluteSize
		useSize = if ax.X > 0 then ax.X else 32
	end
	local fresh = IconResolver.Resolve(name, useSize, color)
	fresh.Name = icon.Name
	fresh.AnchorPoint = icon.AnchorPoint
	fresh.Position = icon.Position
	fresh.ZIndex = icon.ZIndex
	fresh.LayoutOrder = icon:IsA("GuiObject") and icon.LayoutOrder or 0
	if icon:IsA("GuiObject") then
		fresh.Size = icon.Size
	end
	fresh.Parent = icon.Parent
	icon:Destroy()
	return fresh
end

-- Recolore une icône (TextLabel FA, ImageLabel, ou Frame primitif)
function IconResolver.SetIconColor(icon: Instance, color: Color3)
	if icon:IsA("TextLabel") then
		icon.TextColor3 = color
		return
	end
	if icon:IsA("ImageLabel") then
		icon.ImageColor3 = color
		return
	end
	for _, d in icon:GetDescendants() do
		if d:IsA("UIStroke") then
			d.Color = color
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
			d.BackgroundColor3 = color
		end
	end
end

-- Initialisation (appelée par Theme.Init)
function IconResolver.Init(ctx)
	Theme = ctx.Theme
end

return IconResolver