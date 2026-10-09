-- Theme : palette (bible §4), polices et briques d'interface (panneaux, textes, boutons animes, icones).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Util -- injecte dans Init

local Theme = {}

---------------------------------------------------------------- Jetons
Theme.Colors = {
	-- palette de la bible §4
	Sand = Color3.fromRGB(248, 218, 158), -- #F8DA9E
	Lagoon = Color3.fromRGB(22, 160, 168), -- #16A0A8
	Coral = Color3.fromRGB(255, 122, 138), -- #FF7A8A
	Sunset = Color3.fromRGB(255, 178, 90), -- #FFB25A
	Night = Color3.fromRGB(30, 42, 68), -- #1E2A44
	-- derives
	Panel = Color3.fromRGB(30, 42, 68),
	PanelLight = Color3.fromRGB(46, 62, 96),
	Stroke = Color3.fromRGB(255, 255, 255),
	Text = Color3.fromRGB(255, 255, 255),
	TextDim = Color3.fromRGB(200, 214, 230),
	TextShadow = Color3.fromRGB(14, 20, 36),
	Gold = Color3.fromRGB(255, 204, 64),
	GoldDark = Color3.fromRGB(212, 138, 22),
	Success = Color3.fromRGB(76, 206, 120),
	Danger = Color3.fromRGB(240, 70, 84),
	Disabled = Color3.fromRGB(112, 124, 142),
	Black = Color3.new(0, 0, 0),
	White = Color3.new(1, 1, 1),
}

Theme.Transparency = {
	Panel = 0.18,
	PanelStrong = 0.05,
	Stroke = 0.78,
	TextStroke = 0.5,
}

local BUILDER = "rbxasset://fonts/families/BuilderSans.json"
Theme.Fonts = {
	Title = Font.fromEnum(Enum.Font.FredokaOne),
	Bold = Font.new(BUILDER, Enum.FontWeight.Bold),
	Medium = Font.new(BUILDER, Enum.FontWeight.Medium),
}

Theme.Radius = 14 -- coins 12-20 px (bible)
-- Tailles en px de design : le telephone est a l'echelle 0,85, donc 17 -> 14,5 px reels (minimum 14)
Theme.TextSize = { Small = 17, Body = 18, Large = 22, Huge = 34, Giant = 52 }

-- Lettre de rarete (forme + lettre : lisible sans les couleurs)
Theme.RarityLetter = { Common = "C", Uncommon = "U", Rare = "R", Epic = "E", Legendary = "L" }

-- Pictogramme de chaque tresor
Theme.ItemGlyph = {
	Shell = "🐚",
	Starfish = "⭐",
	Pearl = "⚪",
	BlueCrab = "🦀",
	CoralCrown = "👑",
	GoldenCrab = "🦀",
	TreasureChest = "💰",
	AbyssCrystal = "💎",
	MoonPearl = "🌙",
	TideHeart = "💙",
}

local HOVER_SCALE = 1.05
local PRESS_SCALE = 0.92

---------------------------------------------------------------- Accroche
-- Appelee a chaque clic de bouton (branchee sur Sfx par le bootstrap)
Theme.OnPress = function() end

function Theme.Init(ctx)
	Util = ctx.Util
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

function Theme.Corner(parent: Instance, radius: number?): UICorner
	return create("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius), Parent = parent })
end

function Theme.Round(parent: Instance): UICorner
	return create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = parent })
end

function Theme.Stroke(parent: Instance, color: Color3?, transparency: number?, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = color or Theme.Colors.Stroke,
		Transparency = transparency or Theme.Transparency.Stroke,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

-- Contour de texte (lisibilite sur le sable clair)
function Theme.TextStroke(parent: Instance, transparency: number?, thickness: number?): UIStroke
	return create("UIStroke", {
		Color = Theme.Colors.TextShadow,
		Transparency = transparency or Theme.Transparency.TextStroke,
		Thickness = thickness or 1.5,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		Parent = parent,
	})
end

function Theme.Padding(parent: Instance, vertical: number, horizontal: number?): UIPadding
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

-- Panneau arrondi translucide bleu nuit, leger degrade
function Theme.Panel(props: { [any]: any }?): Frame
	local frame = create("Frame", {
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = Theme.Transparency.Panel,
		BorderSizePixel = 0,
	})
	applyProps(frame, props)
	Theme.Corner(frame)
	Theme.Stroke(frame)
	Theme.Gradient(frame, Theme.Colors.PanelLight, Theme.Colors.Panel, 90).Name = "PanelFill"
	if props and props.Parent then
		frame.Parent = props.Parent
	end
	return frame
end

-- Texte blanc avec contour, Builder Sans Bold par defaut
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

---------------------------------------------------------------- Echelle et animations
-- UIScale unique "TR_Scale" par objet : survol, appui, Pop et ouvertures passent par lui
function Theme.GetScale(obj: GuiObject): UIScale
	local s = obj:FindFirstChild("TR_Scale")
	if s and s:IsA("UIScale") then
		return s
	end
	return create("UIScale", { Name = "TR_Scale", Scale = 1, Parent = obj })
end

-- Petit rebond d'echelle (gain, objet recu...)
function Theme.Pop(obj: GuiObject, amount: number?)
	local scale = Theme.GetScale(obj)
	scale.Scale = 1 + (amount or 0.12)
	Util.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- Secousse laterale (refus, erreur) ; aucune en "reduire les animations"
function Theme.Shake(obj: GuiObject)
	if Util.ReducedMotion then
		return
	end
	task.spawn(function()
		for _, angle in { 6, -5, 4, -3, 2, 0 } do
			Util.Tween(obj, 0.045, { Rotation = angle }, Enum.EasingStyle.Sine)
			task.wait(0.045)
		end
		obj.Rotation = 0
	end)
end

local function isPressInput(input: InputObject): boolean
	local t = input.UserInputType
	return t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch or input.KeyCode == Enum.KeyCode.ButtonA
end

-- Survol 1,05 / appui 0,92 / retour en ressort (Back) + son de clic
function Theme.Pressable(button: GuiButton)
	local scale = Theme.GetScale(button)
	button.AutoButtonColor = false
	local held, hovered = false, false
	local function settle()
		Util.Tween(scale, 0.3, { Scale = if hovered then HOVER_SCALE else 1 }, Enum.EasingStyle.Back)
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
			Util.Tween(scale, 0.08, { Scale = PRESS_SCALE }, Enum.EasingStyle.Quad)
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

-- Bouton plein : degrade, contour, libelle "Label"
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, Parent, Text, TextSize, Color, Font, Radius
function Theme.Button(props: { [string]: any }): TextButton
	local color = props.Color or Theme.Colors.Success
	local button = create("TextButton", {
		Name = props.Name or "Button",
		Size = props.Size or UDim2.fromOffset(160, 48),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Selectable = true,
	})
	Theme.Corner(button, props.Radius or 12)
	Theme.Stroke(button, Theme.Colors.Black, 0.65, 2)
	Theme.Gradient(button, color, color:Lerp(Theme.Colors.Black, 0.28), 90).Name = "Fill"
	Theme.Text({
		Name = "Label",
		Size = UDim2.fromScale(1, 1),
		Text = props.Text or "",
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = props.Font or Theme.Fonts.Title,
		ZIndex = 2,
		Parent = button,
	})
	Theme.Pressable(button)
	if props.Parent then
		button.Parent = props.Parent
	end
	return button
end

-- Change la couleur d'un bouton cree par Theme.Button
function Theme.SetButtonColor(button: GuiObject, color: Color3)
	local fill = button:FindFirstChild("Fill")
	if fill and fill:IsA("UIGradient") then
		fill.Color = ColorSequence.new(color, color:Lerp(Theme.Colors.Black, 0.28))
	end
end

---------------------------------------------------------------- Icones
function Theme.RarityColor(rarity: string?): Color3
	local r = rarity and Config.Rarities[rarity]
	return r and r.color or Theme.Colors.TextDim
end

function Theme.RarityOrder(rarity: string?): number
	local r = rarity and Config.Rarities[rarity]
	return r and r.order or 1
end

-- Piece d'or dessinee (aucune image externe)
function Theme.CoinIcon(size: number): Frame
	local coin = create("Frame", {
		Name = "Coin",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Theme.Colors.GoldDark,
		BorderSizePixel = 0,
	})
	Theme.Round(coin)
	Theme.Stroke(coin, Theme.Colors.Black, 0.6, 1.5)
	local face = create("Frame", {
		Name = "Face",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.74, 0.74),
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
		Parent = coin,
	})
	Theme.Round(face)
	Theme.Gradient(face, Color3.fromRGB(255, 236, 140), Theme.Colors.Gold, 135)
	local shine = create("Frame", {
		Name = "Shine",
		Position = UDim2.fromScale(0.2, 0.16),
		Size = UDim2.fromScale(0.26, 0.26),
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Parent = face,
	})
	Theme.Round(shine)
	return coin
end

-- Pastille de rarete : couleur + lettre (C, U, R, E, L)
function Theme.RarityBadge(rarity: string?, size: number): Frame
	local badge = create("Frame", {
		Name = "Rarity",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Theme.RarityColor(rarity),
		BorderSizePixel = 0,
	})
	Theme.Corner(badge, math.floor(size * 0.3))
	Theme.Stroke(badge, Theme.Colors.Black, 0.55, 1.5)
	Theme.Text({
		Name = "Letter",
		Size = UDim2.fromScale(1, 1),
		Text = rarity and Theme.RarityLetter[rarity] or "?",
		TextSize = math.floor(size * 0.62),
		FontFace = Theme.Fonts.Title,
		Parent = badge,
	})
	return badge
end

-- Icone ronde d'un tresor : fond couleur de rarete + pictogramme + lettre de rarete en coin
function Theme.ItemIcon(itemId: string?, size: number): Frame
	local item = itemId and Config.Items[itemId]
	local rarity = item and item.rarity
	local color = Theme.RarityColor(rarity)
	local icon = create("Frame", {
		Name = "ItemIcon",
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
	})
	Theme.Round(icon)
	Theme.Gradient(icon, color:Lerp(Theme.Colors.White, 0.25), color:Lerp(Theme.Colors.Black, 0.3), 90)
	Theme.Stroke(icon, Theme.Colors.Black, 0.5, 1.5)
	create("TextLabel", {
		Name = "Glyph",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = itemId and Theme.ItemGlyph[itemId] or "?",
		TextScaled = true,
		FontFace = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.White,
		Parent = icon,
	}, {
		create("UIPadding", {
			PaddingTop = UDim.new(0.16, 0),
			PaddingBottom = UDim.new(0.16, 0),
			PaddingLeft = UDim.new(0.16, 0),
			PaddingRight = UDim.new(0.16, 0),
		}),
	})
	if rarity and size >= 26 then
		local badgeSize = math.floor(size * 0.4)
		local badge = Theme.RarityBadge(rarity, badgeSize)
		badge.AnchorPoint = Vector2.new(1, 1)
		badge.Position = UDim2.new(1, 3, 1, 3)
		badge.ZIndex = 3
		for _, d in badge:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = 3
			end
		end
		badge.Parent = icon
	end
	return icon
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
