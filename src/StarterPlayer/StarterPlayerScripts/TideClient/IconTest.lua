-- IconTest : écran de validation visuelle du système icônes/polices (H).
-- Brique de contrôle : toutes les icônes du jeu à une taille donnée, ladder typographique,
-- raretés, marées/mutations, prix boutique. Toggle F7 (ou IconTest.Toggle()).
-- N'apparaît pas tout seul en production : démarrage masqué, activation explicite.

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local IconTest = {}
local ctx
local gui, root, panel, open = nil, nil, nil, false

-- Icônes à couvrir : celles utilisées par le jeu + les 6 primitives demandées
local ICON_NAMES = {
	"chest", "box", "wave", "water", "shield", "shield-alt", "star", "crown", "arrow",
	"spark", "bolt", "moon", "lock", "unlock", "coin", "clock", "alert", "info",
	"close", "check", "revenge", "shop", "ride", "down", "net", "trophy", "fire", "key",
	"bag", "users", "home", "settings", "gem", "fish", "compass", "sword", "hammer",
}

-- Tailles de design du Theme, pour vérifier la lisibilité mobile (min 12-14 px)
local SIZE_LADDER = { 12, 14, 17, 22, 32, 48 }

function IconTest.Init(c)
	ctx = c
end

local function section(parent, text, y, width)
	local title = ctx.Theme.Title({
		Name = "Section_" .. text,
		Position = UDim2.fromOffset(0, y),
		Size = UDim2.new(1, 0, 0, 26),
		Text = text,
		TextSize = ctx.Theme.TextSize.Large,
		Parent = parent,
	})
	title.TextXAlignment = Enum.TextXAlignment.Left
	return y + 28
end

local function build()
	local Theme = ctx.Theme
	Theme = ctx.Theme
	local layer = Instance.new("ScreenGui")
	layer.Name = "TideIconTest"
	layer.ResetOnSpawn = false
	layer.IgnoreGuiInset = true
	layer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	layer.DisplayOrder = 90
	layer.Enabled = false
	layer.Parent = ctx.Gui.Parent
	gui = layer

	-- Fond assombri
	local backdrop = Instance.new("TextButton")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Theme.Colors.Black
	backdrop.BackgroundTransparency = 0.35
	backdrop.Text = ""
	backdrop.AutoButtonColor = false
	backdrop.Parent = layer

	-- Panneau scrollable
	panel = Theme.Plate({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(820, 560),
		Strong = true,
		Accent = Theme.Colors.Lagoon,
		Radius = 10,
	})
	panel.Parent = layer

	local cornerBadge = Theme.Text({
		Name = "FAMode",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 10),
		Size = UDim2.fromOffset(340, 22),
		Text = "",
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextDim,
		Parent = panel,
	})
	cornerBadge.Text = if ctx.IconResolver.IsFontAwesomeLoaded()
		then "Font Awesome 6 Free : actif"
		else "Font Awesome indisponible : primitives Roblox"
	cornerBadge.TextXAlignment = Enum.TextXAlignment.Right
	cornerBadge.ZIndex = 6

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(14, 38)
	scroll.Size = UDim2.new(1, -28, 1, -52)
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.ScrollBarImageColor3 = Theme.Colors.TextDim
	scroll.Parent = panel

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.Size = UDim2.new(1, -16, 0, 0)
	content.AutomaticSize = Enum.AutomaticSize.Y
	content.Position = UDim2.fromOffset(8, 0)
	content.Parent = scroll
	Theme.List(content, Enum.FillDirection.Vertical, 18)

	------------------------------------------------------------- Icônes
	local icons = Instance.new("Frame")
	icons.Name = "Icons"
	icons.BackgroundTransparency = 1
	icons.Size = UDim2.new(1, 0, 0, 210)
	icons.Parent = content

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(84, 84)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.FillDirection = Enum.FillDirection.Horizontal
	grid.FillDirectionMaxCells = 0
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = icons

	for i, name in ICON_NAMES do
		local cell = Instance.new("Frame")
		cell.Name = "Icon_" .. name
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = i
		cell.Parent = icons

		local icon = Theme.Icon(name, 40, Theme.Colors.Text)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = cell

		local label = Theme.Text({
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -2),
			Size = UDim2.new(1, 0, 0, 16),
			Text = name,
			TextSize = 12,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = cell,
		})
	end

	------------------------------------------------------------- Ladder typo
	local typo = Instance.new("Frame")
	typo.Name = "Typo"
	typo.BackgroundTransparency = 1
	typo.Size = UDim2.new(1, 0, 0, 250)
	typo.Parent = content
	Theme.List(typo, Enum.FillDirection.Vertical, 6)

	for _, size in SIZE_LADDER do
		local row = Instance.new("Frame")
		row.Name = "Size_" .. size
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, math.max(size + 10, 24))
		row.Parent = typo

		local num = Instance.new("TextLabel")
		num.Name = "Value"
		num.BackgroundTransparency = 1
		num.Size = UDim2.fromOffset(70, math.max(size + 10, 24))
		num.Font = Theme.Fonts.Number
		num.Text = size .. " pt"
		num.TextSize = math.clamp(size, 12, 24)
		num.TextColor3 = Theme.Colors.TextDim
		num.TextXAlignment = Enum.TextXAlignment.Left
		num.Parent = row

		local sample = Theme.Title({
			Name = "Sample",
			Position = UDim2.fromOffset(80, 0),
			Size = UDim2.new(1, -160, 1, 0),
			Text = "Wave in 5s — Steal & Ride",
			TextSize = size,
			Parent = row,
		})
		sample.TextXAlignment = Enum.TextXAlignment.Left
		sample.FontFace = if size >= 22 then Theme.Fonts.Title else Theme.Fonts.Body
	end

	------------------------------------------------------------- Raretés
	local rarities = Instance.new("Frame")
	rarities.Name = "Rarities"
	rarities.BackgroundTransparency = 1
	rarities.Size = UDim2.new(1, 0, 0, 74)
	rarities.Parent = content

	local rGrid = Instance.new("UIGridLayout")
	rGrid.CellSize = UDim2.fromOffset(120, 64)
	rGrid.CellPadding = UDim2.fromOffset(10, 10)
	rGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rGrid.SortOrder = Enum.SortOrder.LayoutOrder
	rGrid.Parent = rarities

	local order = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
	for i, rarity in order do
		local cell = Instance.new("Frame")
		cell.Name = "R_" .. rarity
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = i
		cell.Parent = rarities
		local badge = Theme.RarityBadge(rarity, 44)
		badge.AnchorPoint = Vector2.new(0, 0.5)
		badge.Position = UDim2.new(0, 4, 0.5, 0)
		badge.Parent = cell
		Theme.Text({
			Name = "Label",
			Position = UDim2.fromOffset(56, 0),
			Size = UDim2.new(1, -60, 1, 0),
			Text = Theme.RarityName(rarity),
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.RarityColor(rarity),
			Parent = cell,
		})
	end

	------------------------------------------------------------- Marées / mutations
	local tides = Instance.new("Frame")
	tides.Name = "Tides"
	tides.BackgroundTransparency = 1
	tides.Size = UDim2.new(1, 0, 0, 74)
	tides.Parent = content

	local tGrid = Instance.new("UIGridLayout")
	tGrid.CellSize = UDim2.fromOffset(160, 64)
	tGrid.CellPadding = UDim2.fromOffset(10, 10)
	tGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tGrid.SortOrder = Enum.SortOrder.LayoutOrder
	tGrid.Parent = tides

	local tideKeys = { "Normal", "Golden", "Night", "Storm", "Rainbow" }
	for i, key in tideKeys do
		local style = Theme.TideStyle(key)
		local cell = Instance.new("Frame")
		cell.Name = "T_" .. key
		cell.BackgroundTransparency = 1
		cell.LayoutOrder = i
		cell.Parent = tides
		local icon = Theme.Icon(style.icon, 34, style.color)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 6, 0.5, 0)
		icon.Parent = cell
		Theme.Text({
			Name = "Label",
			Position = UDim2.fromOffset(48, 0),
			Size = UDim2.new(1, -52, 1, 0),
			Text = style.label,
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = style.color,
			Parent = cell,
		})
	end

	------------------------------------------------------------- Prix boutique
	local prices = Instance.new("Frame")
	prices.Name = "Prices"
	prices.BackgroundTransparency = 1
	prices.Size = UDim2.new(1, 0, 0, 168)
	prices.Parent = content

	local pGrid = Instance.new("UIGridLayout")
	pGrid.CellSize = UDim2.fromOffset(126, 78)
	pGrid.CellPadding = UDim2.fromOffset(10, 10)
	pGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
	pGrid.SortOrder = Enum.SortOrder.LayoutOrder
	pGrid.Parent = prices

	local shopRows = {
		{ "VIP Rider", "chest", 79 },
		{ "Speed Boost", "wave", 149 },
		{ "Bag Expansion", "crown", 99 },
		{ "Starter Pack", "star", 249 },
		{ "Tide Egg", "spark", 199 },
		{ "Pick a Creature", "arrow", 399 },
	}
	for i, row in shopRows do
		local card = Instance.new("Frame")
		card.Name = "P_" .. row[1]
		card.BackgroundTransparency = 1
		card.LayoutOrder = i
		card.Parent = prices
		local icon = Theme.Icon(row[2], 30, Theme.Colors.Gold)
		icon.AnchorPoint = Vector2.new(0.5, 0)
		icon.Position = UDim2.new(0.5, 0, 0, 2)
		icon.Parent = card
		Theme.Text({
			Name = "Name",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 36),
			Size = UDim2.new(1, 0, 0, 18),
			Text = row[1],
			TextSize = 12,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.TextDim,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
		Theme.CoinIcon(20).Position = UDim2.new(0, 2, 0, 54)
		local coin = ctx.Gui:FindFirstChild("__dummy")
		Theme.Text({
			Name = "Price",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 52),
			Size = UDim2.new(1, 0, 0, 24),
			Text = (row[3] .. " R$"),
			TextSize = Theme.TextSize.Large,
			FontFace = Theme.Fonts.Number,
			TextColor3 = Theme.Colors.Gold,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = card,
		})
	end

	return panel, layer
end

function IconTest.Start(c)
	task.spawn(function()
		panel, layer = build()
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			if input.KeyCode == Enum.KeyCode.F7 then
				IconTest.Toggle()
			end
		end)
	end)
end

function IconTest.Toggle()
	open = not open
	if gui then
		gui.Enabled = open
	end
	return open
end

return IconTest