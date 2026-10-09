-- Components : bibliotheque d'elements d'interface generiques (verre, boutons a ressort, compteur,
-- barre de progression, pilules, cartes). Independants du concept de jeu : les ecrans les assemblent.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Components = {}

local COUNTER_TIME = 0.4 -- defilement du compteur (critere T-007)
local BAR_TIME = 0.25
local SHADOW_OFFSET = 4

local Util, Theme
local create

function Components.Init(ctx)
	Util = ctx.Util
	Theme = ctx.Theme
	create = Theme.Create
end

---------------------------------------------------------------- Verre
-- Panneau "verre" : degrade bleu nuit translucide, contour clair, reflet en haut, ombre portee.
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, ZIndex, Parent, Radius, Tint (Color3), Strong (bool)
function Components.Glass(props: { [string]: any }): Frame
	local radius = props.Radius or 16
	local tint = props.Tint or Theme.Colors.Night
	local z = props.ZIndex or 1
	local frame = create("Frame", {
		Name = props.Name or "Glass",
		Size = props.Size or UDim2.fromOffset(200, 60),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = z,
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = if props.Strong then 0.04 else 0.16,
		BorderSizePixel = 0,
	})
	Theme.Corner(frame, radius)
	Theme.Gradient(frame, tint:Lerp(Theme.Colors.White, 0.14), tint:Lerp(Theme.Colors.Black, 0.12), 90).Name = "GlassFill"
	Theme.Stroke(frame, Theme.Colors.White, 0.72, 1.5)
	-- reflet : fine bande claire en haut qui s'efface vers le bas
	local shine = create("Frame", {
		Name = "Shine",
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -radius, 0.42, 0),
		Position = UDim2.fromOffset(radius / 2, 2),
		ZIndex = z,
		Parent = frame,
	})
	Theme.Corner(shine, math.max(4, radius - 4))
	create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0, 1), Parent = shine })
	if props.Parent then
		Components.Shadow(frame, radius).Parent = props.Parent
		frame.Parent = props.Parent
	end
	return frame
end

-- Ombre douce derriere un element (soeur placee juste avant lui, suit sa taille et sa position)
function Components.Shadow(target: GuiObject, radius: number?): Frame
	local shadow = create("Frame", {
		Name = target.Name .. "Shadow",
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = math.max(0, target.ZIndex - 1),
		LayoutOrder = target.LayoutOrder,
	})
	Theme.Corner(shadow, radius or 16)
	local function follow()
		shadow.Size = target.Size
		shadow.AnchorPoint = target.AnchorPoint
		shadow.Position = target.Position + UDim2.fromOffset(0, SHADOW_OFFSET)
		shadow.Visible = target.Visible
	end
	follow()
	for _, prop in { "Size", "Position", "AnchorPoint", "Visible" } do
		target:GetPropertyChangedSignal(prop):Connect(follow)
	end
	target.Destroying:Connect(function()
		shadow:Destroy()
	end)
	return shadow
end

---------------------------------------------------------------- Boutons
-- Bouton rond a icone (emoji) + libelle dessous + pastille de compteur + raccourci clavier.
-- props : Name, Icon, Label, Color, Size (cote, defaut 58), Hotkey, Position, AnchorPoint, LayoutOrder, Parent
function Components.IconButton(props: { [string]: any })
	local side = props.Size or 58
	local color = props.Color or Theme.Colors.Lagoon
	local holder = create("Frame", {
		Name = props.Name or "IconButton",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(side, side + 22),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
	})
	local button = create("TextButton", {
		Name = "Button",
		Size = UDim2.fromOffset(side, side),
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Selectable = true,
		Parent = holder,
	})
	Theme.Corner(button, math.floor(side * 0.34))
	Theme.Gradient(button, color:Lerp(Theme.Colors.White, 0.18), color:Lerp(Theme.Colors.Black, 0.3), 90).Name = "Fill"
	Theme.Stroke(button, Theme.Colors.White, 0.55, 2)
	create("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = props.Icon or "",
		TextScaled = true,
		FontFace = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.White,
		ZIndex = 2,
		Parent = button,
	}, { Theme.Padding(nil :: any, 12) })
	local label = Theme.Text({
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, side + 2),
		Size = UDim2.fromOffset(side + 24, 20),
		Text = props.Label or "",
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Title,
		Parent = holder,
	})
	local badge = Components.CountBadge(0)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, -6, 0, 6)
	badge.ZIndex = 4
	badge.Parent = button
	if props.Hotkey then
		local key = Components.KeyHint(props.Hotkey)
		key.AnchorPoint = Vector2.new(0, 1)
		key.Position = UDim2.new(0, -4, 1, 4)
		key.Parent = button
	end
	Theme.Pressable(button)
	if props.Parent then
		holder.Parent = props.Parent
	end
	local api = { Instance = holder, Button = button, Label = label, Badge = badge, Enabled = true }
	-- grise le bouton ; l'appelant teste api.Enabled dans son Activated
	function api.SetEnabled(self, enabled: boolean)
		self.Enabled = enabled
		Theme.SetButtonColor(button, if enabled then color else Theme.Colors.Disabled)
	end
	function api.SetCount(_self, n: number)
		Components.SetCountBadge(badge, n)
	end
	return api
end

-- Petite touche clavier ("E") affichee seulement au clavier sans ecran tactile
function Components.KeyHint(key: string): Frame
	local UserInputService = game:GetService("UserInputService")
	local hint = create("Frame", {
		Name = "KeyHint",
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.Colors.Night,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Visible = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled,
	})
	Theme.Corner(hint, 6)
	Theme.Stroke(hint, Theme.Colors.White, 0.5, 1)
	Theme.Text({ Size = UDim2.fromScale(1, 1), Text = key, TextSize = 14, ZIndex = 6, Parent = hint })
	return hint
end

-- Pastille rouge de compteur (cachee a 0)
function Components.CountBadge(n: number): Frame
	local badge = create("Frame", {
		Name = "CountBadge",
		Size = UDim2.fromOffset(24, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Colors.Coral,
		BorderSizePixel = 0,
	})
	Theme.Round(badge)
	Theme.Stroke(badge, Theme.Colors.White, 0.2, 2)
	Theme.Padding(badge, 0, 6)
	Theme.Text({ Name = "Count", Size = UDim2.fromScale(1, 1), AutomaticSize = Enum.AutomaticSize.X, TextSize = Theme.TextSize.Small, FontFace = Theme.Fonts.Title, Parent = badge })
	Components.SetCountBadge(badge, n)
	return badge
end

function Components.SetCountBadge(badge: Frame, n: number)
	local label = badge:FindFirstChild("Count") :: TextLabel?
	if label then
		label.Text = if n > 99 then "99+" else tostring(n)
	end
	badge.Visible = n > 0
end

---------------------------------------------------------------- Compteur qui defile
-- Nombre anime : Set(v) fait defiler en 0,4 s (Config.Format), rebond a la hausse.
-- props : Name, Size, Position, AnchorPoint, TextSize, Font, Color, XAlign, Prefix, Suffix, Parent, ZIndex, PopOnRise (defaut true)
function Components.Counter(props: { [string]: any })
	local label = Theme.Text({
		Name = props.Name or "Counter",
		Size = props.Size or UDim2.fromOffset(140, 32),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = props.Font or Theme.Fonts.Title,
		TextColor3 = props.Color or Theme.Colors.Text,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	})
	local prefix, suffix = props.Prefix or "", props.Suffix or ""
	local value = Instance.new("NumberValue")
	local shown, target = 0, 0
	local function render(v: number)
		label.Text = prefix .. Config.Format(v) .. suffix
	end
	value.Changed:Connect(function(v)
		shown = v
		render(v)
	end)
	render(0)
	local api = { Instance = label }
	function api.Set(_self, v: number, instant: boolean?)
		local rising = v > target
		target = v
		if instant or Util.ReducedMotion then
			value.Value = v
			return
		end
		value.Value = shown
		Util.Tween(value, COUNTER_TIME, { Value = v }, Enum.EasingStyle.Quad)
		if rising and props.PopOnRise ~= false then
			Theme.Pop(label, 0.1)
		end
	end
	function api.Get(_self): number
		return target
	end
	label.Destroying:Connect(function()
		value:Destroy()
	end)
	return api
end

---------------------------------------------------------------- Barre de progression
-- props : Name, Size, Position, AnchorPoint, Color, Parent, ZIndex, Text (texte centre optionnel)
function Components.ProgressBar(props: { [string]: any })
	local color = props.Color or Theme.Colors.Lagoon
	local z = props.ZIndex or 1
	local track = create("Frame", {
		Name = props.Name or "ProgressBar",
		Size = props.Size or UDim2.fromOffset(200, 14),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = z,
	})
	Theme.Round(track)
	Theme.Stroke(track, Theme.Colors.White, 0.8, 1)
	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
		ZIndex = z + 1,
		Parent = track,
	})
	Theme.Round(fill)
	local gradient = Theme.Gradient(fill, color:Lerp(Theme.Colors.White, 0.3), color, 90)
	local shine = create("Frame", {
		Name = "Shine",
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = 0.6,
		BorderSizePixel = 0,
		Size = UDim2.new(1, -6, 0.4, 0),
		Position = UDim2.fromOffset(3, 1),
		ZIndex = z + 2,
		Parent = fill,
	})
	Theme.Round(shine)
	local text = Theme.Text({
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		Text = props.Text or "",
		TextSize = Theme.TextSize.Small,
		ZIndex = z + 3,
		Parent = track,
	})
	if props.Parent then
		track.Parent = props.Parent
	end
	local progress = 0
	local api = { Instance = track, Fill = fill, Label = text }
	-- p 0..1 ; animate = false pour suivre une valeur continue (chaque frame)
	function api.Set(_self, p: number, animate: boolean?)
		progress = math.clamp(p, 0, 1)
		local size = UDim2.fromScale(progress, 1)
		if animate == false then
			fill.Size = size
		else
			Util.Tween(fill, BAR_TIME, { Size = size }, Enum.EasingStyle.Quad)
		end
		shine.Visible = progress > 0.04
	end
	function api.SetColor(_self, c: Color3)
		gradient.Color = ColorSequence.new(c:Lerp(Theme.Colors.White, 0.3), c)
	end
	function api.SetText(_self, s: string)
		text.Text = s
	end
	return api
end

---------------------------------------------------------------- Pilule et carte
-- Pilule verre horizontale : icone (Frame ou emoji) + texte principal + texte secondaire optionnel.
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, Parent, Icon (GuiObject|string), Text, SubText, Tint, ZIndex
function Components.Pill(props: { [string]: any })
	local height = props.Height or 44
	local glass = Components.Glass({
		Name = props.Name or "Pill",
		Size = props.Size or UDim2.fromOffset(180, height),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
		Radius = math.floor(height / 2),
		Tint = props.Tint,
		Parent = props.Parent,
	})
	local iconSize = height - 12
	local icon = props.Icon
	if type(icon) == "string" then
		icon = create("TextLabel", {
			BackgroundTransparency = 1,
			Text = icon,
			TextScaled = true,
			FontFace = Theme.Fonts.Bold,
			TextColor3 = Theme.Colors.White,
		})
	end
	if icon then
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 6, 0.5, 0)
		icon.Size = UDim2.fromOffset(iconSize, iconSize)
		icon.ZIndex = (props.ZIndex or 1) + 1
		icon.Parent = glass
	end
	local left = if icon then iconSize + 14 else 14
	local main = Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.new(1, -left - 12, if props.SubText then 0.62 else 1, 0),
		Text = props.Text or "",
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = (props.ZIndex or 1) + 1,
		Parent = glass,
	})
	local sub = nil
	if props.SubText then
		sub = Theme.Text({
			Name = "SubText",
			Position = UDim2.new(0, left, 0.56, 0),
			Size = UDim2.new(1, -left - 12, 0.4, 0),
			Text = props.SubText,
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = (props.ZIndex or 1) + 1,
			Parent = glass,
		})
	end
	return { Instance = glass, Icon = icon, Text = main, SubText = sub }
end

-- Carte verticale : en-tete colore avec icone, titre, lignes de texte, bouton en bas.
-- props : Name, Size, Icon, Title, Lines ({string}), Color, ButtonText, ButtonColor, LayoutOrder, Parent
function Components.Card(props: { [string]: any })
	local color = props.Color or Theme.Colors.Lagoon
	local card = Components.Glass({
		Name = props.Name or "Card",
		Size = props.Size or UDim2.fromOffset(200, 240),
		LayoutOrder = props.LayoutOrder,
		Strong = true,
		Parent = props.Parent,
	})
	local medallion = create("Frame", {
		Name = "Medallion",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 14),
		Size = UDim2.fromOffset(64, 64),
		BackgroundColor3 = Theme.Colors.White,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = card,
	})
	Theme.Round(medallion)
	Theme.Gradient(medallion, color:Lerp(Theme.Colors.White, 0.25), color:Lerp(Theme.Colors.Black, 0.25), 90)
	Theme.Stroke(medallion, Theme.Colors.White, 0.4, 2)
	create("TextLabel", {
		Name = "Icon",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = props.Icon or "",
		TextScaled = true,
		FontFace = Theme.Fonts.Bold,
		TextColor3 = Theme.Colors.White,
		ZIndex = 3,
		Parent = medallion,
	}, { Theme.Padding(nil :: any, 12) })
	local title = Theme.Text({
		Name = "Title",
		Position = UDim2.fromOffset(0, 84),
		Size = UDim2.new(1, 0, 0, 28),
		Text = props.Title or "",
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		ZIndex = 2,
		Parent = card,
	})
	local lines = {}
	for i, line in props.Lines or {} do
		lines[i] = Theme.Text({
			Name = "Line" .. i,
			Position = UDim2.fromOffset(8, 112 + (i - 1) * 22),
			Size = UDim2.new(1, -16, 0, 22),
			Text = line,
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextDim,
			RichText = true,
			ZIndex = 2,
			Parent = card,
		})
	end
	local button = Theme.Button({
		Name = "Action",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 46),
		Text = props.ButtonText or "",
		Color = props.ButtonColor or Theme.Colors.Success,
		Parent = card,
	})
	button.ZIndex = 2
	return { Instance = card, Title = title, Lines = lines, Button = button, Medallion = medallion }
end

return Components
