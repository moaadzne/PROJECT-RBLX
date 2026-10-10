-- Components : briques d'interface generiques, style « jeu console » (DIRECTION_V2) : panneaux sombres
-- translucides, boutons a icone dessinee (aucun emoji), compteur, barre, pastilles, cartes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Components = {}

local COUNTER_TIME = 0.25 -- defilement du compteur
local BAR_TIME = 0.15

local Util, Theme
local create

function Components.Init(ctx)
	Util = ctx.Util
	Theme = ctx.Theme
	create = Theme.Create
end

---------------------------------------------------------------- Panneau
-- Panneau sombre translucide (ancien nom « Glass », garde pour les ecrans existants).
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, ZIndex, Parent, Radius, Accent (Color3), Strong (bool)
function Components.Glass(props: { [string]: any }): Frame
	local plate = Theme.Plate({
		Name = props.Name or "Panel",
		Size = props.Size or UDim2.fromOffset(200, 60),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		Radius = props.Radius,
		Accent = props.Accent,
		Strong = props.Strong,
	})
	plate.LayoutOrder = props.LayoutOrder or 0
	if props.Parent then
		plate.Parent = props.Parent
	end
	return plate
end

---------------------------------------------------------------- Boutons
-- Bouton carre a icone dessinee + libelle en MAJUSCULES dessous + pastille de compteur + touche clavier.
-- props : Name, Icon (nom d'icone Theme), Label, Color (accent), Size (cote, defaut 58), Hotkey, Position,
--         AnchorPoint, LayoutOrder, Parent
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
		BackgroundColor3 = Theme.Colors.Plate,
		BackgroundTransparency = Theme.Transparency.Plate,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Selectable = true,
		Parent = holder,
	})
	Theme.Corner(button, 8)
	local stroke = Theme.Stroke(button)
	-- trait d'accent en bas : la couleur de la fonction, sans remplir tout le bouton
	local accent = create("Frame", {
		Name = "Accent",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 0),
		Size = UDim2.new(1, -16, 0, 3),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = 2,
		Parent = button,
	})
	Theme.Round(accent)
	local iconSize = math.floor(side * 0.5)
	local icon = Theme.Icon(props.Icon, iconSize, Theme.Colors.Text)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.46)
	icon.ZIndex = 2
	icon.Parent = button
	local label = Theme.Text({
		Name = "Label",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, side + 2),
		Size = UDim2.fromOffset(side + 30, 20),
		Text = Theme.Caps(props.Label or ""),
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Title,
		Parent = holder,
	})
	local badge = Components.CountBadge(0)
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.new(1, -4, 0, 4)
	badge.ZIndex = 4
	badge.Parent = button
	if props.Hotkey then
		local key = Components.KeyHint(props.Hotkey)
		key.AnchorPoint = Vector2.new(0, 0)
		key.Position = UDim2.fromOffset(3, 3)
		key.Parent = button
	end
	Theme.Pressable(button)
	if props.Parent then
		holder.Parent = props.Parent
	end
	local api = { Instance = holder, Button = button, Label = label, Badge = badge, Icon = icon, Enabled = true }
	-- grise le bouton ; l'appelant teste api.Enabled dans son Activated
	function api.SetEnabled(self, enabled: boolean)
		self.Enabled = enabled
		accent.BackgroundColor3 = if enabled then color else Theme.Colors.Disabled
		Theme.SetIconColor(self.Icon, if enabled then Theme.Colors.Text else Theme.Colors.TextDim)
		stroke.Transparency = if enabled then Theme.Transparency.Line else 0.95
	end
	function api.SetIcon(self, name: string)
		if self.IconName == name then
			return
		end
		self.IconName = name
		local old = self.Icon
		local fresh = Theme.Icon(name, iconSize, if self.Enabled then Theme.Colors.Text else Theme.Colors.TextDim)
		fresh.AnchorPoint = old.AnchorPoint
		fresh.Position = old.Position
		fresh.ZIndex = 2
		fresh.Parent = button
		old:Destroy()
		self.Icon = fresh
	end
	function api.SetLabel(_self, text: string)
		label.Text = Theme.Caps(text)
	end
	function api.SetAccent(_self, c: Color3)
		color = c
		accent.BackgroundColor3 = c
	end
	function api.SetCount(_self, n: number)
		Components.SetCountBadge(badge, n)
	end
	api.IconName = props.Icon
	return api
end

-- Petite touche clavier ("E") affichee seulement au clavier sans ecran tactile
function Components.KeyHint(key: string): Frame
	local hint = create("Frame", {
		Name = "KeyHint",
		Size = UDim2.fromOffset(18, 18),
		BackgroundColor3 = Theme.Colors.Text,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ZIndex = 5,
		Visible = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled,
	})
	Theme.Corner(hint, 6)
	local label = Theme.Text({
		Size = UDim2.fromScale(1, 1),
		Text = key,
		TextSize = 14,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.TextDark,
		ZIndex = 6,
		Parent = hint,
	})
	label:FindFirstChildOfClass("UIStroke"):Destroy()
	return hint
end

-- Pastille de compteur (cachee a 0)
function Components.CountBadge(n: number): Frame
	local badge = create("Frame", {
		Name = "CountBadge",
		Size = UDim2.fromOffset(22, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Theme.Colors.Danger,
		BorderSizePixel = 0,
	})
	Theme.Round(badge)
	Theme.Padding(badge, 0, 6)
	Theme.Text({
		Name = "Count",
		Size = UDim2.fromScale(1, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Number,
		Parent = badge,
	})
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
-- Nombre anime : Set(v) defile en 0,25 s (Config.Format).
-- props : Name, Size, Position, AnchorPoint, TextSize, Font, Color, XAlign, Prefix, Suffix, Parent, ZIndex, PopOnRise (defaut true)
function Components.Counter(props: { [string]: any })
	local label = Theme.Text({
		Name = props.Name or "Counter",
		Size = props.Size or UDim2.fromOffset(140, 32),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = props.Font or Theme.Fonts.Number,
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
		Util.Tween(value, COUNTER_TIME, { Value = v }, Enum.EasingStyle.Quart)
		if rising and props.PopOnRise ~= false then
			Theme.Pop(label, 0.05)
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
-- Barre plate et fine. props : Name, Size, Position, AnchorPoint, Color, Parent, ZIndex, Text (optionnel)
function Components.ProgressBar(props: { [string]: any })
	local color = props.Color or Theme.Colors.Lagoon
	local z = props.ZIndex or 1
	local track = create("Frame", {
		Name = props.Name or "ProgressBar",
		Size = props.Size or UDim2.fromOffset(200, 8),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = z,
	})
	Theme.Corner(track, 6)
	local fill = create("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		ZIndex = z + 1,
		Parent = track,
	})
	Theme.Corner(fill, 6)
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
	-- p 0..1 ; animate = false pour suivre une valeur continue
	function api.Set(_self, p: number, animate: boolean?)
		progress = math.clamp(p, 0, 1)
		local size = UDim2.fromScale(progress, 1)
		if animate == false then
			fill.Size = size
		else
			Util.Tween(fill, BAR_TIME, { Size = size }, Enum.EasingStyle.Quart)
		end
	end
	function api.SetColor(_self, c: Color3)
		fill.BackgroundColor3 = c
	end
	function api.SetText(_self, s: string)
		text.Text = s
	end
	return api
end

---------------------------------------------------------------- Pilule et carte
-- Ligne : icone (nom d'icone ou GuiObject) + texte principal + texte secondaire optionnel.
-- props : Name, Size, Position, AnchorPoint, LayoutOrder, Parent, Icon, IconColor, Text, SubText, Accent, ZIndex, Height
function Components.Pill(props: { [string]: any })
	local height = props.Height or 40
	local z = props.ZIndex or 1
	local panel = Components.Glass({
		Name = props.Name or "Pill",
		Size = props.Size or UDim2.fromOffset(180, height),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = z,
		Accent = props.Accent,
		Parent = props.Parent,
	})
	local iconSize = height - 16
	local icon = props.Icon
	if type(icon) == "string" then
		icon = Theme.Icon(icon, iconSize, props.IconColor)
	end
	if icon then
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 10, 0.5, 0)
		icon.ZIndex = z + 1
		icon.Parent = panel
	end
	local left = if icon then iconSize + 20 else 12
	local main = Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(left, 0),
		Size = UDim2.new(1, -left - 10, if props.SubText then 0.62 else 1, 0),
		Text = props.Text or "",
		TextSize = props.TextSize or Theme.TextSize.Large,
		FontFace = Theme.Fonts.Number,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = z + 1,
		Parent = panel,
	})
	local sub = nil
	if props.SubText then
		sub = Theme.Text({
			Name = "SubText",
			Position = UDim2.new(0, left, 0.56, 0),
			Size = UDim2.new(1, -left - 10, 0.4, 0),
			Text = props.SubText,
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = z + 1,
			Parent = panel,
		})
	end
	return { Instance = panel, Icon = icon, Text = main, SubText = sub }
end

-- Carte verticale : icone, titre en MAJUSCULES, lignes de texte, bouton en bas.
-- props : Name, Size, Icon (nom), Title, Lines ({string}), Color, ButtonText, ButtonColor, LayoutOrder, Parent
function Components.Card(props: { [string]: any })
	local color = props.Color or Theme.Colors.Lagoon
	local card = Components.Glass({
		Name = props.Name or "Card",
		Size = props.Size or UDim2.fromOffset(200, 240),
		LayoutOrder = props.LayoutOrder,
		Accent = color,
		Strong = true,
		Parent = props.Parent,
	})
	local icon = Theme.Icon(props.Icon, 40, color)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, 18)
	icon.ZIndex = 2
	icon.Parent = card
	local title = Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, 28),
		Text = props.Title or "",
		TextSize = Theme.TextSize.Large,
		ZIndex = 2,
		Parent = card,
	})
	local lines = {}
	for i, line in props.Lines or {} do
		lines[i] = Theme.Text({
			Name = "Line" .. i,
			Position = UDim2.fromOffset(8, 100 + (i - 1) * 22),
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
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 42),
		Text = props.ButtonText or "",
		Color = props.ButtonColor or Theme.Colors.Lagoon,
		Parent = card,
	})
	button.ZIndex = 2
	return { Instance = card, Title = title, Lines = lines, Button = button, Icon = icon }
end

return Components
