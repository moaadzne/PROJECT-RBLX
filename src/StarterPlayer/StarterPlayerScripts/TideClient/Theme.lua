-- Theme : systeme visuel « jeu console » (docs/DIRECTION_V2.md, prime sur la bible) :
-- panneaux sombres translucides, coins de 6 a 10 px, police condensee nette, titres en MAJUSCULES espacees,
-- aucun emoji (icones dessinees, ou images de Assets.UI.Icons quand C les fournit), animations courtes et seches.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
-- Point de substitution unique des glyphes : aucune brique d'interface ne cherche une image
-- toute seule, tout passe par Glyph (voir Glyph.lua).
-- Require defensif : ce bootstrap saute en silence un module qui echoue, et Theme est une brique
-- de fondation. Si Glyph manque, l'interface continue a tourner sur les pictogrammes dessines.
local Glyph
do
	local node = script.Parent:FindFirstChild("Glyph")
	if node then
		local ok, mod = pcall(require, node)
		Glyph = if ok then mod else nil
	end
end

local Util -- injecte dans Init

local Theme = {}

---------------------------------------------------------------- Jetons
Theme.Colors = {
	-- fonds : nuit marine, presque neutre (pas de couleur bonbon)
	Plate = Color3.fromRGB(10, 14, 22),
	PlateLight = Color3.fromRGB(22, 30, 44),
	Outline = Color3.fromRGB(0, 0, 0),
	Line = Color3.fromRGB(255, 255, 255), -- filets clairs, tres transparents
	-- texte
	Text = Color3.fromRGB(242, 245, 248),
	TextDim = Color3.fromRGB(150, 162, 178),
	TextDark = Color3.fromRGB(12, 16, 24),
	TextShadow = Color3.fromRGB(0, 0, 0),
	-- accents (utilises avec parcimonie : ce qui compte seulement)
	Lagoon = Color3.fromRGB(38, 196, 196), -- turquoise du lagon
	Gold = Color3.fromRGB(240, 190, 70),
	Danger = Color3.fromRGB(235, 64, 64),
	Warning = Color3.fromRGB(245, 150, 40),
	Success = Color3.fromRGB(70, 200, 120),
	Disabled = Color3.fromRGB(70, 78, 92),
	Black = Color3.new(0, 0, 0),
	White = Color3.new(1, 1, 1),
}
-- anciens noms (modules existants) -> nouvelle palette
Theme.Colors.Night = Theme.Colors.Plate
Theme.Colors.Panel = Theme.Colors.Plate
Theme.Colors.PanelLight = Theme.Colors.PlateLight
Theme.Colors.Stroke = Theme.Colors.Line
Theme.Colors.Coral = Theme.Colors.Danger
Theme.Colors.Sunset = Theme.Colors.Warning
Theme.Colors.GoldDark = Color3.fromRGB(176, 128, 30)
Theme.Colors.Sand = Color3.fromRGB(226, 208, 170)

Theme.Transparency = {
	Plate = 0.22, -- panneau sombre translucide
	PlateStrong = 0.08,
	Line = 0.86,
	TextStroke = 0.55,
}

-- Titres et chiffres : RobotoCondensed (police native Roblox, condensee et nette : exactement le
-- style console demande par DIRECTION_V2). Rien a charger, rien a licencer.
-- Si Roblox expose la variante grasse de la famille, elle est preferee pour les titres.
local CONDENSED = Enum.Font.RobotoCondensed
local CONDENSED_BOLD = (Enum.Font :: any).RobotoCondensedBold or CONDENSED
-- Texte courant : Builder Sans (bible §5), garde en famille pour conserver le gras et le medium.
local BUILDER = "rbxasset://fonts/families/BuilderSans.json"
Theme.Fonts = {
	Title = CONDENSED_BOLD,
	Number = CONDENSED_BOLD,
	Bold = Font.new(BUILDER, Enum.FontWeight.Bold),
	Medium = Font.new(BUILDER, Enum.FontWeight.Medium),
}

Theme.Radius = 8 -- coins de 6 a 10 px
Theme.RadiusMin, Theme.RadiusMax = 6, 10
-- Tailles en px de design (telephone a l'echelle 0,85 : 17 -> 14,5 px reels, minimum 14)
Theme.TextSize = { Small = 17, Body = 18, Large = 22, Huge = 32, Giant = 48 }

-- Durees (DIRECTION_V2 : 0,1 a 0,25 s ; celebrations seulement pour les vrais moments)
Theme.Time = { Micro = 0.1, Fast = 0.15, Normal = 0.22, Celebrate = 0.45 }

-- Lettre de rarete (forme + lettre : lisible sans les couleurs)
Theme.RarityLetter = { Common = "C", Uncommon = "U", Rare = "R", Epic = "E", Legendary = "L" }

-- Marees et mutations : couleur + icone dessinee + nom
Theme.Tides = {
	Normal = { label = "Tide", icon = "wave", color = Color3.fromRGB(110, 190, 220) },
	Golden = { label = "Golden Tide", icon = "spark", color = Color3.fromRGB(240, 190, 70) },
	Night = { label = "Night Tide", icon = "moon", color = Color3.fromRGB(120, 150, 255) },
	Storm = { label = "Storm Tide", icon = "bolt", color = Color3.fromRGB(170, 110, 255) },
	Rainbow = { label = "Rainbow Tide", icon = "spark", color = Color3.fromRGB(235, 130, 200) },
}
Theme.Mutations = {
	Golden = { label = "Golden", icon = "spark", color = Color3.fromRGB(240, 190, 70) },
	Glow = { label = "Glow", icon = "moon", color = Color3.fromRGB(80, 230, 210) },
	Storm = { label = "Storm", icon = "bolt", color = Color3.fromRGB(170, 110, 255) },
	Rainbow = { label = "Rainbow", icon = "spark", color = Color3.fromRGB(235, 130, 200) },
}

function Theme.TideStyle(tide: string?)
	return Theme.Tides[tide or "Normal"] or Theme.Tides.Normal
end

local HOVER_SCALE = 1.03
local PRESS_SCALE = 0.95
local LETTER_GAP = utf8.char(0x200A) -- espace fine : MAJUSCULES espacees (Roblox n'a pas d'interlettrage)

---------------------------------------------------------------- Accroche
-- Appelee a chaque clic de bouton (branchee sur Sfx par le bootstrap)
Theme.OnPress = function() end

function Theme.Init(ctx)
	Util = ctx.Util
end

---------------------------------------------------------------- Texte
-- "Wave in" -> "WAVE IN" avec une espace fine entre deux lettres (les chiffres et les prix restent groupes)
function Theme.Caps(text: string): string
	local upper = string.upper(text)
	local out = {}
	local prevLetter = false
	for _, code in utf8.codes(upper) do
		local isLetter = code >= 65 and code <= 90
		if isLetter and prevLetter then
			table.insert(out, LETTER_GAP)
		end
		table.insert(out, utf8.char(code))
		prevLetter = isLetter
	end
	return table.concat(out)
end

---------------------------------------------------------------- Fabrique
-- Theme.Create("Frame", {Name = "X", Parent = p}, {enfant1, enfant2})
function Theme.Create(className: string, props: { [any]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for key, value in props do
			if key == "Parent" then
				parent = value
			else
				inst[key] = value
			end
		end
	end
	if children then
		for _, child in children do
			child.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local create = Theme.Create

-- Coins toujours entre 6 et 10 px (les ronds restent ronds via Theme.Round)
function Theme.Corner(parent: Instance, radius: number?): UICorner
	local r = math.clamp(radius or Theme.Radius, Theme.RadiusMin, Theme.RadiusMax)
	return create("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

function Theme.Round(parent: Instance): UICorner
	return create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end

function Theme.Stroke(parent: Instance, color: Color3?, transparency: number?, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = color or Theme.Colors.Line,
		Transparency = transparency or Theme.Transparency.Line,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- Ombre fine du texte (lisibilite sur le sable clair), sans contour epais de dessin anime
function Theme.TextStroke(parent: Instance, transparency: number?, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = Theme.Colors.TextShadow,
		Transparency = transparency or Theme.Transparency.TextStroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

function Theme.Padding(parent: Instance?, vertical: number, horizontal: number?): UIPadding
	local h = horizontal or vertical
	return create("UIPadding", {
		PaddingTop = UDim.new(0, vertical),
		PaddingBottom = UDim.new(0, vertical),
		PaddingLeft = UDim.new(0, h),
		PaddingRight = UDim.new(0, h),
		Parent = parent,
	})
end

function Theme.Gradient(parent: Instance, top: Color3, bottom: Color3, rotation: number?): UIGradient
	return create("UIGradient", {
		Color = ColorSequence.new(top, bottom),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

function Theme.List(
	parent: Instance,
	direction: Enum.FillDirection,
	padding: number,
	hAlign: Enum.HorizontalAlignment?,
	vAlign: Enum.VerticalAlignment?
): UIListLayout
	return create("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, padding),
		HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

local function applyProps(inst: Instance, props: { [any]: any }?)
	if not props then
		return
	end
	for key, value in props do
		if key ~= "Parent" then
			inst[key] = value
		end
	end
end

-- Texte blanc, Builder Sans par defaut, ombre fine
function Theme.Text(props: { [any]: any }?): TextLabel
	local label = create("TextLabel", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		FontFace = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.Text,
		TextSize = Theme.TextSize.Body,
		Text = "",
	})
	applyProps(label, props)
	Theme.TextStroke(label)
	if props and props.Parent then
		label.Parent = props.Parent
	end
	return label
end

-- Titre : Oswald, MAJUSCULES espacees
function Theme.Title(props: { [any]: any }): TextLabel
	local p = table.clone(props)
	p.Text = Theme.Caps(props.Text or "")
	p.FontFace = props.FontFace or Theme.Fonts.Title
	return Theme.Text(p)
end

---------------------------------------------------------------- Panneaux
-- Plaque console : fond sombre translucide, filet clair de 1 px, trait de couleur fin en haut (option)
-- props : Name, Size, Position, AnchorPoint, Rotation, ZIndex, Parent, Accent (Color3), Radius, Strong (moins transparent)
function Theme.Plate(props: { [string]: any }): Frame
	local z = props.ZIndex or 1
	local plate = create("Frame", {
		Name = props.Name or "Plate",
		Size = props.Size or UDim2.fromOffset(200, 50),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Rotation = props.Rotation or 0,
		ZIndex = z,
		BackgroundColor3 = Theme.Colors.Plate,
		BackgroundTransparency = if props.Strong then Theme.Transparency.PlateStrong else Theme.Transparency.Plate,
		BorderSizePixel = 0,
	})
	Theme.Corner(plate, props.Radius)
	Theme.Stroke(plate)
	if props.Accent then
		local accent = create("Frame", {
			Name = "Accent",
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = props.Accent,
			BorderSizePixel = 0,
			ZIndex = z + 1,
			Parent = plate,
		})
		Theme.Corner(accent, 6)
	end
	if props.Parent then
		plate.Parent = props.Parent
	end
	return plate
end

-- Ancien nom
function Theme.Panel(props: { [any]: any }?): Frame
	return Theme.Plate(props or {})
end

---------------------------------------------------------------- Echelle et animations
-- UIScale unique "TR_Scale" par objet : survol, appui, Pop et ouvertures passent par lui
function Theme.GetScale(obj: GuiObject): UIScale
	local s = obj:FindFirstChild("TR_Scale")
	if s and s:IsA("UIScale") then
		return s
	end
	return create("UIScale", { Name = "TR_Scale", Scale = 1, Parent = obj })
end

-- Retour sec (gain, objet recu...) : 0,15 s, sans rebond
function Theme.Pop(obj: GuiObject, amount: number?)
	local scale = Theme.GetScale(obj)
	scale.Scale = 1 + math.min(amount or 0.06, 0.08)
	Util.Tween(scale, Theme.Time.Fast, { Scale = 1 }, Enum.EasingStyle.Quart)
end

-- Celebration : seulement les vrais moments (rarete, vol reussi, surf, couronne)
function Theme.Celebrate(obj: GuiObject, amount: number?)
	local scale = Theme.GetScale(obj)
	scale.Scale = 1 + (amount or 0.18)
	Util.Tween(scale, Theme.Time.Celebrate, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Secousse laterale courte (refus, erreur) ; aucune en "reduire les animations"
function Theme.Shake(obj: GuiObject)
	if Util.ReducedMotion then
		return
	end
	task.spawn(function()
		for _, angle in { 3, -2.5, 1.5, 0 } do
			Util.Tween(obj, 0.035, { Rotation = angle }, Enum.EasingStyle.Sine)
			task.wait(0.035)
		end
		obj.Rotation = 0
	end)
end

local function isPressInput(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA
end

-- Survol 1,03 / appui 0,95 / retour en 0,12 s + clic feutre
function Theme.Pressable(button: GuiButton)
	local scale = Theme.GetScale(button)
	button.AutoButtonColor = false
	local held, hovered = false, false
	local function settle()
		Util.Tween(scale, 0.12, { Scale = if hovered then HOVER_SCALE else 1 }, Enum.EasingStyle.Quart)
	end
	button.MouseEnter:Connect(function()
		hovered = true
		if not held then
			settle()
		end
	end)
	button.MouseLeave:Connect(function()
		hovered = false
		held = false
		settle()
	end)
	button.InputBegan:Connect(function(input)
		if isPressInput(input) then
			held = true
			Util.Tween(scale, Theme.Time.Micro * 0.8, { Scale = PRESS_SCALE }, Enum.EasingStyle.Quad)
		end
	end)
	button.InputEnded:Connect(function(input)
		if held and isPressInput(input) then
			held = false
			settle()
		end
	end)
	button.Activated:Connect(function()
		Theme.OnPress()
	end)
end

-- Texte lisible sur une couleur (sombre sur clair, clair sur sombre)
local function textOn(color: Color3): Color3
	local luminance = 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
	return if luminance > 0.55 then Theme.Colors.TextDark else Theme.Colors.Text
end

-- Bouton plein a la couleur d'accent, libelle Oswald en MAJUSCULES espacees
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, Parent, Text, TextSize, Color, Font, Radius
function Theme.Button(props: { [string]: any }): TextButton
	local color = props.Color or Theme.Colors.Lagoon
	local button = create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 44),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = color,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Selectable = true,
	})
	Theme.Corner(button, props.Radius or 6)
	Theme.Gradient(button, Theme.Colors.White, Color3.fromRGB(205, 205, 205), 90).Name = "Fill"
	local label = Theme.Text({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		Text = Theme.Caps(props.Text or ""),
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = props.Font or Theme.Fonts.Title,
		TextColor3 = textOn(color),
		ZIndex = 2,
		Parent = button,
	})
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Enabled = textOn(color) == Theme.Colors.Text
	end
	Theme.Pressable(button)
	if props.Parent then
		button.Parent = props.Parent
	end
	return button
end

-- Change la couleur d'un bouton cree par Theme.Button (et le contraste de son libelle)
function Theme.SetButtonColor(button: GuiObject, color: Color3)
	button.BackgroundColor3 = color
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.TextColor3 = textOn(color)
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Enabled = label.TextColor3 == Theme.Colors.Text
		end
	end
end

function Theme.SetButtonText(button: GuiObject, text: string)
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		label.Text = Theme.Caps(text)
	end
end

---------------------------------------------------------------- Icones (aucun emoji)
-- La resolution d'image vit dans Glyph (Assets.UI.Icons.<cle> de C). Theme ne fait plus que
-- deposer ses pictogrammes dessines dans Glyph, a l'init.

-- Trait plein en coordonnees relatives (0..1) dans l'icone
local function bar(parent: Instance, cx: number, cy: number, w: number, h: number, rot: number, color: Color3, round: boolean?)
	local f = create("Frame", {
		Name = "Bar",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(cx, cy),
		Size = UDim2.fromScale(w, h),
		Rotation = rot,
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = parent,
	})
	if round then
		Theme.Round(f)
	end
	return f
end

-- Anneau (contour) en coordonnees relatives
local function ring(parent: Instance, cx: number, cy: number, d: number, color: Color3, thickness: number)
	local f = create("Frame", {
		Name = "Ring",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(cx, cy),
		Size = UDim2.fromScale(d, d),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	Theme.Round(f)
	create("UIStroke", { Color = color, Thickness = thickness, Parent = f })
	return f
end

local DRAW = {
	lock = function(p, c, t)
		ring(p, 0.5, 0.36, 0.42, c, t)
		local body = bar(p, 0.5, 0.66, 0.66, 0.44, 0, c)
		Theme.Corner(body, 6)
	end,
	unlock = function(p, c, t)
		ring(p, 0.66, 0.3, 0.42, c, t)
		local body = bar(p, 0.5, 0.66, 0.66, 0.44, 0, c)
		Theme.Corner(body, 6)
	end,
	ride = function(p, c)
		for _, y in { 0.42, 0.68 } do
			bar(p, 0.36, y, 0.42, 0.13, -40, c, true)
			bar(p, 0.64, y, 0.42, 0.13, 40, c, true)
		end
	end,
	down = function(p, c)
		for _, y in { 0.34, 0.6 } do
			bar(p, 0.36, y, 0.42, 0.13, 40, c, true)
			bar(p, 0.64, y, 0.42, 0.13, -40, c, true)
		end
	end,
	shop = function(p, c, t)
		ring(p, 0.5, 0.34, 0.36, c, t)
		local body = bar(p, 0.5, 0.64, 0.72, 0.5, 0, c)
		Theme.Corner(body, 6)
	end,
	alert = function(p, c, t)
		local d = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.66, 0.66),
			Rotation = 45,
			BackgroundTransparency = 1,
			Parent = p,
		})
		create("UIStroke", { Color = c, Thickness = t, Parent = d })
		bar(p, 0.5, 0.44, 0.1, 0.26, 0, c)
		bar(p, 0.5, 0.66, 0.1, 0.1, 0, c)
	end,
	arrow = function(p, c)
		bar(p, 0.56, 0.36, 0.5, 0.16, 40, c, true)
		bar(p, 0.56, 0.64, 0.5, 0.16, -40, c, true)
	end,
	crown = function(p, c)
		bar(p, 0.5, 0.74, 0.8, 0.14, 0, c)
		for _, spec in { { 0.18, 0.5, 0.22 }, { 0.5, 0.42, 0.3 }, { 0.82, 0.5, 0.22 } } do
			bar(p, spec[1], spec[2], spec[3], spec[3], 45, c)
		end
	end,
	shield = function(p, c)
		bar(p, 0.5, 0.32, 0.64, 0.24, 0, c)
		bar(p, 0.5, 0.52, 0.46, 0.46, 45, c)
	end,
	revenge = function(p, c)
		bar(p, 0.5, 0.5, 0.86, 0.12, 45, c, true)
		bar(p, 0.5, 0.5, 0.86, 0.12, -45, c, true)
	end,
	close = function(p, c)
		bar(p, 0.5, 0.5, 0.7, 0.12, 45, c, true)
		bar(p, 0.5, 0.5, 0.7, 0.12, -45, c, true)
	end,
	clock = function(p, c, t)
		ring(p, 0.5, 0.5, 0.74, c, t)
		bar(p, 0.5, 0.38, 0.09, 0.26, 0, c)
		bar(p, 0.6, 0.52, 0.22, 0.09, 0, c)
	end,
	wave = function(p, c)
		bar(p, 0.42, 0.38, 0.6, 0.13, -8, c, true)
		bar(p, 0.58, 0.62, 0.6, 0.13, -8, c, true)
	end,
	spark = function(p, c)
		bar(p, 0.5, 0.5, 0.5, 0.5, 45, c)
		bar(p, 0.5, 0.5, 0.12, 0.9, 0, c)
		bar(p, 0.5, 0.5, 0.9, 0.12, 0, c)
	end,
	moon = function(p, c, t)
		ring(p, 0.5, 0.5, 0.7, c, t * 1.6)
	end,
	bolt = function(p, c)
		bar(p, 0.42, 0.34, 0.14, 0.46, 20, c)
		bar(p, 0.58, 0.66, 0.14, 0.46, 20, c)
		bar(p, 0.5, 0.5, 0.36, 0.12, 0, c)
	end,
	info = function(p, c, t)
		ring(p, 0.5, 0.5, 0.8, c, t)
		bar(p, 0.5, 0.56, 0.1, 0.3, 0, c)
		bar(p, 0.5, 0.32, 0.1, 0.1, 0, c)
	end,
	coin = function(p, c, t)
		ring(p, 0.5, 0.5, 0.8, c, t)
		bar(p, 0.5, 0.5, 0.42, 0.42, 0, c, true)
	end,
	dot = function(p, c)
		bar(p, 0.5, 0.5, 0.5, 0.5, 45, c)
	end,
	net = function(p, c, t)
		ring(p, 0.5, 0.5, 0.8, c, t)
		for _, x in { 0.38, 0.62 } do
			bar(p, x, 0.5, 0.07, 0.62, 0, c)
			bar(p, 0.5, x, 0.62, 0.07, 0, c)
		end
	end,
}
Theme.IconNames = DRAW

-- Les pictogrammes enters dans le point de substitution : c'est le seul endroit ou l'interface
-- ajoute du visuel a Glyph. Quand Moaad tranche le sort des icones, Glyph suffit.
for key, drawFn in pairs(DRAW) do
	if Glyph then
		Glyph.RegisterDraw(key, drawFn)
	end
end

-- Icone carree de `size` px. La resolution passe par Glyph : image de C si elle existe,
-- sinon le pictogramme dessine de cette cle, sinon rien du tout (aucune icone fantome).
function Theme.Icon(name: string?, size: number, color: Color3?): GuiObject
	local c = color or Theme.Colors.Text
	local key = name or "dot"
	local resolved = if Glyph then Glyph.Resolve(key) else { kind = "none" }
	if resolved.kind == "image" and resolved.image then
		return create("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			Image = resolved.image,
			ImageColor3 = c,
			ScaleType = Enum.ScaleType.Fit,
		})
	end
	local holder = create("Frame", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(size, size),
	})
	local draw = (if Glyph then Glyph.Draw(key) else nil) or DRAW[key] or DRAW.dot
	if draw then
		draw(holder, c, math.max(1.5, size * 0.09))
	end
	return holder
end

-- Recolore une icone (image ou dessin)
function Theme.SetIconColor(icon: Instance, color: Color3)
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

---------------------------------------------------------------- Rarete et pieces
function Theme.RarityColor(rarity: string?): Color3
	local r = rarity and Config.Rarities[rarity]
	return r and r.color or Theme.Colors.TextDim
end

function Theme.RarityOrder(rarity: string?): number
	local r = rarity and Config.Rarities[rarity]
	return r and r.order or 1
end

function Theme.RarityName(rarity: string?): string
	local r = rarity and Config.Rarities[rarity]
	return r and r.label or ""
end

-- Piece : disque or plat avec un anneau interieur (dessinee, aucune image externe)
function Theme.CoinIcon(size: number): Frame
	local coin = create("Frame", {
		Name = "Coin",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Theme.Colors.Gold,
		BorderSizePixel = 0,
	})
	Theme.Round(coin)
	local inner = create("Frame", {
		Name = "Inner",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.62, 0.62),
		BackgroundTransparency = 1,
		Parent = coin,
	})
	Theme.Round(inner)
	create("UIStroke", { Color = Theme.Colors.GoldDark, Thickness = math.max(1.5, size * 0.08), Parent = inner })
	return coin
end

-- Pastille de rarete : carre a coins vifs, couleur + lettre (C, U, R, E, L)
function Theme.RarityBadge(rarity: string?, size: number): Frame
	local color = Theme.RarityColor(rarity)
	local badge = create("Frame", {
		Name = "Rarity",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	})
	Theme.Corner(badge, 6)
	Theme.Text({
		Name = "Letter",
		Size = UDim2.fromScale(1, 1),
		Text = rarity and Theme.RarityLetter[rarity] or "?",
		TextSize = math.floor(size * 0.66),
		FontFace = Theme.Fonts.Title,
		TextColor3 = textOn(color),
		Parent = badge,
	})
	return badge
end

-- Racine plein ecran mise a l'echelle sans decaler les ancrages
-- (taille 1/s puis UIScale s => couvre exactement l'ecran)
function Theme.ScaledRoot(parent: Instance, getScale: () -> number): (Frame, () -> ())
	local root = create("Frame", {
		Name = "Root",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = parent,
	})
	local uiScale = create("UIScale", { Name = "RootScale", Parent = root })
	local function refresh()
		local s = math.max(0.3, getScale())
		uiScale.Scale = s
		root.Size = UDim2.fromScale(1 / s, 1 / s)
	end
	refresh()
	return root, refresh
end

return Theme
