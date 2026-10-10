-- Codex : Knowledge Hub "jeu console" (DIRECTION_V2)
-- Onglets : Creatures | Cosmetics | (Lore | Cinematics en Phase 2+)
-- Creatures : 10 espèces × 2 variantes (Normal, Golden)
-- Cosmetics : skins créatures, mount skins, wings, housing, emotes + Vault + Battle Pass + Pity
-- Persistant via state.cosmetics (DataService) ; Notify "cosmetic" à chaque débloquage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Codex = {}
local Components, Theme, Util, Sfx, Store, CreatureData

-- Constantes d'affichage
local VISIBLE_SPECIES = { "GhostCrab", "CushionStar", "HawksbillTurtle" }
local MYSTERY_COUNT = 4

-- Sons
local POP_SOUND_ID = "rbxassetid://9114479173"
local HOVER_SOUND_ID = "rbxassetid://9114479174"

local PLACEHOLDER_COSMETICS = {
	{ id = "skin_ghost_abyssal", name = "Abyssal Ghost", type = "Creature Skin", rarity = "Epic", price = 249, owned = false, source = "Vault", lore = "Forged in the deepest trenches..." },
	{ id = "skin_cushion_corail", name = "Corail Cushion", type = "Creature Skin", rarity = "Rare", price = 199, owned = false, source = "Vault", lore = "Living coral polyps woven into starlight." },
	{ id = "skin_turtle_aurore", name = "Aurore Turtle", type = "Creature Skin", rarity = "Legendary", price = 399, owned = true, source = "Battle Pass S1", lore = "Bioluminescent shell dancing with polar lights." },
	{ id = "mount_ghost_golden", name = "Golden Ghost Trail", type = "Mount Trail", rarity = "Legendary", price = 499, owned = false, source = "Vault", lore = "A wake of molten gold in the waves." },
	{ id = "mount_cushion_neon", name = "Neon Cushion Trail", type = "Mount Trail", rarity = "Epic", price = 349, owned = false, source = "Shop", lore = "Bioluminescent particles trail behind your mount." },
	{ id = "wings_ghost", name = "Ghost Wings", type = "Wings", rarity = "Legendary", price = 449, owned = false, source = "Vault", lore = "Silent as a deep-sea current." },
	{ id = "wings_cushion", name = "Cushion Wings", type = "Wings", rarity = "Epic", price = 399, owned = false, source = "Shop", lore = "Soft bioluminescent membrane wings." },
	{ id = "wings_turtle", name = "Turtle Wings", type = "Wings", rarity = "Rare", price = 299, owned = false, source = "Shop", lore = "Sturdy leather wings inspired by the oldest mariners." },
	{ id = "housing_ghost", name = "Ghost Reef Theme", type = "Housing", rarity = "Legendary", price = 799, owned = false, source = "Guild War", lore = "Your base becomes a luminous ghost reef." },
	{ id = "housing_cushion", name = "Coral Garden Theme", type = "Housing", rarity = "Epic", price = 599, owned = false, source = "Vault", lore = "A thriving coral garden surrounds your base." },
	{ id = "emote_ghost", name = "Ghost Wave", type = "Emote", rarity = "Common", price = 49, owned = true, source = "Shop", lore = "A spectral wave crashes around you." },
	{ id = "emote_cushion", name = "Star Dance", type = "Emote", rarity = "Rare", price = 99, owned = false, source = "Shop", lore = "A slow, graceful spin like a drifting star." },
}

-- Cache local
local codexCache = {}
local codexCount = 0
local codexTotal = 0
local cosmeticsCache = {}
local isOpen = false
local panelRef = nil
local cardRefs = {}
local currentTab = "Creatures"

-- Initialise le cache cosmétiques depuis le placeholder (owned = true si le placeholder le dit)
-- Sera écrasé par state.cosmetics dès que le serveur envoie le vrai état
for _, cosmetic in ipairs(PLACEHOLDER_COSMETICS) do
	if cosmetic.owned then
		cosmeticsCache[cosmetic.id] = true
	end
end

function Codex.Init(ctx)
	Components = ctx.Components
	Theme = ctx.Theme
	Util = ctx.Util
	Sfx = ctx.Sfx
	Store = ctx.Store
end

-------------------------------------------------------------- Helpers
local function getSpeciesRarity(speciesId: string): string
	local c = Config.Creatures[speciesId]
	return c and c.rarity or "Common"
end

local function getRarityColor(rarity: string): Color3
	return Theme.RarityColor(rarity)
end

local function isSpeciesVisible(speciesId: string): boolean
	for _, id in ipairs(VISIBLE_SPECIES) do
		if id == speciesId then return true end
	end
	return false
end

local function getSortedSpecies(): { string }
	local result = {}
	for speciesId, _ in pairs(Config.Creatures) do
		if isSpeciesVisible(speciesId) then
			table.insert(result, speciesId)
		end
	end
	local mysteryShown = 0
	for speciesId, _ in pairs(Config.Creatures) do
		if not isSpeciesVisible(speciesId) and mysteryShown < MYSTERY_COUNT then
			table.insert(result, "__MYSTERY__" .. mysteryShown)
			mysteryShown += 1
		end
	end
	return result
end

local function getVariantLabel(variant: string): string
	return variant == "Normal" and "NORMAL" or "GOLDEN"
end

local function isDiscovered(speciesId: string, variant: string): boolean
	local s = codexCache[speciesId]
	return s and s[variant] == true
end

local function getDiscoveredCount(): number
	local count = 0
	for speciesId, variants in pairs(codexCache) do
		for variant, discovered in pairs(variants) do
			if discovered and isSpeciesVisible(speciesId) then
				count += 1
			end
		end
	end
	return count
end

local function getTotalVisibleSlots(): number
	return #VISIBLE_SPECIES * #Config.CodexVariants
end

local function getCosmeticRarityColor(rarity: string): Color3
	return Theme.RarityColor(rarity)
end

local function isCosmeticOwned(cosmeticId: string): boolean
	return cosmeticsCache[cosmeticId] == true
end

local function getOwnedCosmeticsCount(): number
	local count = 0
	for _, owned in pairs(cosmeticsCache) do
		if owned then count += 1 end
	end
	return count
end

-------------------------------------------------------------- Création des cartes d'espèce
local function createSpeciesCard(speciesId: string, layoutOrder: number, parent: Instance)
	local isMystery = speciesId:sub(1, 10) == "__MYSTERY__"
	local speciesData = Config.Creatures[speciesId]
	local rarity = isMystery and "Rare" or getSpeciesRarity(speciesId)
	local rarityColor = getRarityColor(rarity)

	local card = Components.Glass({
		Name = "CodexCard_" .. speciesId,
		Size = UDim2.fromOffset(280, 140),
		LayoutOrder = layoutOrder,
		Accent = rarityColor,
		Strong = true,
		Parent = parent,
	})

	local iconHolder = Theme.Create("Frame", {
		Name = "IconHolder",
		Size = UDim2.fromOffset(100, 100),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Parent = card,
	})

	if isMystery then
		local mysteryIcon = Theme.Create("ImageLabel", {
			Name = "MysteryIcon",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = "rbxassetid://10723407389",
			ImageColor3 = rarityColor,
			ImageTransparency = 0.3,
			ScaleType = Enum.ScaleType.Fit,
			Parent = iconHolder,
		})
		local question = Theme.Text({
			Name = "Question",
			Size = UDim2.fromScale(1, 1),
			Text = "?",
			TextSize = 48,
			FontFace = Theme.Fonts.Title,
			TextColor3 = rarityColor,
			TextTransparency = 0.2,
			Parent = iconHolder,
		})
		Theme.TextStroke(question, 0.3)
	else
		local icon = Theme.Icon(speciesId, 80, Theme.Colors.Text)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.fromScale(0.5, 0.5)
		icon.Parent = iconHolder
	end

	local nameLabel = Theme.Title({
		Name = "Name",
		Position = UDim2.fromOffset(130, 20),
		Size = UDim2.new(1, -150, 0, 28),
		Text = isMystery and "???" or speciesData.name,
		TextSize = Theme.TextSize.Large,
		TextColor3 = isMystery and Theme.Colors.TextDim or Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local rarityBadge = Theme.RarityBadge(rarity, 28)
	rarityBadge.Position = UDim2.fromOffset(130, 52)
	rarityBadge.Parent = card

	if not isMystery then
		local incomeLabel = Theme.Text({
			Name = "Income",
			Position = UDim2.fromOffset(170, 52),
			Size = UDim2.fromOffset(100, 28),
			Text = "+" .. Config.Format(speciesData.income) .. "/s",
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.Lagoon,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})
		Theme.TextStroke(incomeLabel)
	end

	local variantsFrame = Theme.Create("Frame", {
		Name = "Variants",
		Size = UDim2.new(1, -150, 0, 44),
		Position = UDim2.fromOffset(130, 84),
		BackgroundTransparency = 1,
		Parent = card,
	})
	Theme.List(variantsFrame, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local variantButtons = {}
	for _, variant in ipairs(Config.CodexVariants) do
		local discovered = isDiscovered(speciesId, variant)
		local vColor = Theme.Mutations[variant] and Theme.Mutations[variant].color or rarityColor
		local vLabel = getVariantLabel(variant)

		local btnHolder = Theme.Create("Frame", {
			Name = "Variant_" .. variant,
			Size = UDim2.fromOffset(110, 40),
			BackgroundTransparency = 1,
			Parent = variantsFrame,
		})

		local isMysteryVariant = isMystery or not discovered
		local btn = Components.IconButton({
			Name = "Btn_" .. variant,
			Icon = isMysteryVariant and "info" or (variant == "Golden" and "spark" or "dot"),
			Label = isMysteryVariant and "???" or vLabel,
			Color = isMysteryVariant and Theme.Colors.Disabled or vColor,
			Size = 40,
			Parent = btnHolder,
		})
		btn.Button.Size = UDim2.fromOffset(110, 40)
		btn.Label.Size = UDim2.fromOffset(110, 18)
		btn.Label.Position = UDim2.fromOffset(0, 42)
		btn.SetEnabled(btn, not isMysteryVariant)

		if isMystery or isMysteryVariant then
			btn.Button.Activated:Connect(function()
				if Sfx then Sfx.Play(HOVER_SOUND_ID) end
				if Store and Store.ShowToast then
					Store.ShowToast({ text = "DISCOVER IT BY PLAYING!", kind = "info", duration = 2 })
				end
			end)
		else
			btn.Button.Activated:Connect(function()
				if Sfx then Sfx.Play(POP_SOUND_ID) end
				Codex.OpenDetail(speciesId, variant)
			end)
		end

		btnHolder.Size = UDim2.fromOffset(0, 40)
		TweenService:Create(btnHolder, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(110, 40)
		}):Play()

		variantButtons[variant] = btn
	end

	cardRefs[speciesId] = { Instance = card, variantButtons = variantButtons }
	return card
end

-------------------------------------------------------------- Création des cartes cosmétiques
local function createCosmeticCard(cosmetic, layoutOrder: number, parent: Instance)
	local rarityColor = getCosmeticRarityColor(cosmetic.rarity)
	local owned = isCosmeticOwned(cosmetic.id)

	local card = Components.Glass({
		Name = "CosmeticCard_" .. cosmetic.id,
		Size = UDim2.fromOffset(280, 120),
		LayoutOrder = layoutOrder,
		Accent = rarityColor,
		Strong = true,
		Parent = parent,
	})

	-- Icône selon le type
	local iconHolder = Theme.Create("Frame", {
		Name = "IconHolder",
		Size = UDim2.fromOffset(80, 80),
		Position = UDim2.fromOffset(20, 20),
		BackgroundTransparency = 1,
		Parent = card,
	})

	local typeIconMap = {
		["Creature Skin"] = "spark",
		["Mount Trail"] = "ride",
		["Wings"] = "crown",
		["Housing"] = "shield",
		["Emote"] = "dot",
	}
	local iconName = typeIconMap[cosmetic.type] or "dot"
	local icon = Theme.Icon(iconName, 60, owned and rarityColor or Theme.Colors.TextDim)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Parent = iconHolder

	-- Nom
	local nameLabel = Theme.Title({
		Name = "Name",
		Position = UDim2.fromOffset(110, 16),
		Size = UDim2.new(1, -130, 0, 24),
		Text = cosmetic.name,
		TextSize = Theme.TextSize.Large,
		TextColor3 = owned and Theme.Colors.Text or Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	-- Type + Rarity
	local typeLabel = Theme.Text({
		Name = "Type",
		Position = UDim2.fromOffset(110, 42),
		Size = UDim2.new(1, -130, 0, 20),
		Text = cosmetic.type .. " · " .. cosmetic.rarity,
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Medium,
		TextColor3 = rarityColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Theme.TextStroke(typeLabel)

	-- Source
	local sourceLabel = Theme.Text({
		Name = "Source",
		Position = UDim2.fromOffset(110, 62),
		Size = UDim2.new(1, -130, 0, 18),
		Text = "SOURCE: " .. cosmetic.source,
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Theme.TextStroke(sourceLabel)

	-- Prix / Statut
	local statusLabel = Theme.Text({
		Name = "Status",
		Position = UDim2.fromOffset(110, 84),
		Size = UDim2.new(1, -130, 0, 20),
		Text = owned and "OWNED" or (Config.Format(cosmetic.price) .. " R$"),
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Title,
		TextColor3 = owned and Theme.Colors.Success or Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})
	Theme.TextStroke(statusLabel)

	-- Animation d'apparition
	card.Size = UDim2.fromOffset(280, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(280, 120)
	}):Play()

	return card
end

-------------------------------------------------------------- Panneau principal
function Codex.CreatePanel(parent: Instance)
	local screenGui = parent:FindFirstChild("CodexGui")
	if not screenGui then
		screenGui = Theme.Create("ScreenGui", {
			Name = "CodexGui",
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			Parent = parent,
		})
	end

	local backdrop = Theme.Create("Frame", {
		Name = "Backdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.6,
		Visible = false,
		ZIndex = 50,
		Parent = screenGui,
	})
	Theme.Create("UIScale", { Name = "RootScale", Scale = 1, Parent = backdrop })

	local panel = Components.Glass({
		Name = "CodexPanel",
		Size = UDim2.fromOffset(680, 460),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Accent = Theme.Colors.Lagoon,
		Strong = true,
		ZIndex = 51,
		Parent = backdrop,
	})

	panel.Size = UDim2.fromOffset(0, 0)
	panel.Visible = false

	-- Titre
	local title = Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(20, 16),
		Size = UDim2.new(1, -100, 0, 36),
		Text = "KNOWLEDGE HUB",
		TextSize = Theme.TextSize.Huge,
		TextColor3 = Theme.Colors.Lagoon,
		Parent = panel,
	})

	-- Onglets
	local tabBar = Theme.Create("Frame", {
		Name = "TabBar",
		Size = UDim2.new(1, -40, 0, 36),
		Position = UDim2.fromOffset(20, 56),
		BackgroundTransparency = 1,
		ZIndex = 52,
		Parent = panel,
	})
	Theme.List(tabBar, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local tabButtons = {}
	local tabs = { "Creatures", "Cosmetics" }
	for i, tabName in ipairs(tabs) do
		local tabBtn = Theme.Button({
			Name = "Tab_" .. tabName,
			Size = UDim2.fromOffset(120, 32),
			Text = tabName,
			Color = currentTab == tabName and Theme.Colors.Lagoon or Theme.Colors.PlateLight,
			Radius = 6,
			LayoutOrder = i,
			Parent = tabBar,
		})
		tabBtn.Activated:Connect(function()
			currentTab = tabName
			Codex.Refresh()
		end)
		tabButtons[tabName] = tabBtn
	end

	-- Compteur
	local counter = Components.Counter({
		Name = "Counter",
		Position = UDim2.new(1, -140, 0, 20),
		Size = UDim2.fromOffset(120, 36),
		AnchorPoint = Vector2.new(1, 0),
		Prefix = "",
		Suffix = " / 10",
		TextSize = Theme.TextSize.Large,
		Font = Theme.Fonts.Number,
		Color = Theme.Colors.Text,
		XAlign = Enum.TextXAlignment.Right,
		Parent = panel,
	})
	counter.Set(counter, 0, true)

	-- Barre de progression
	local progressBar = Components.ProgressBar({
		Name = "ProgressBar",
		Position = UDim2.fromOffset(20, 96),
		Size = UDim2.new(1, -40, 0, 10),
		Color = Theme.Colors.Lagoon,
		ZIndex = 52,
		Parent = panel,
	})

	-- Grille
	local grid = Theme.Create("Frame", {
		Name = "Grid",
		Size = UDim2.new(1, -40, 1, -130),
		Position = UDim2.fromOffset(20, 116),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		ZIndex = 52,
		Parent = panel,
	})

	local scroll = Theme.Create("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Colors.Lagoon,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = grid,
	})
	Theme.List(scroll, Enum.FillDirection.Vertical, 12, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

	-- Bouton fermer
	local closeBtn = Theme.Button({
		Name = "CloseBtn",
		Position = UDim2.new(1, -20, 0, 16),
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(44, 44),
		Text = "",
		Color = Theme.Colors.Danger,
		Radius = 22,
		Parent = panel,
	})
	local closeIcon = Theme.Icon("close", 24, Theme.Colors.Text)
	closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	closeIcon.Position = UDim2.fromScale(0.5, 0.5)
	closeIcon.Parent = closeBtn
	closeBtn.Activated:Connect(function()
		Codex.Close()
	end)

	panelRef = {
		Panel = panel,
		Backdrop = backdrop,
		Counter = counter,
		ProgressBar = progressBar,
		Scroll = scroll,
		TabBar = tabBar,
		TabButtons = tabButtons,
	}
	return panelRef
end

-------------------------------------------------------------- Mise à jour de l'affichage
function Codex.Refresh()
	if not panelRef then return end

	local scroll = panelRef.Scroll
	local counter = panelRef.Counter
	local progressBar = panelRef.ProgressBar
	local tabBar = panelRef.TabBar
	local tabButtons = panelRef.TabButtons

	-- Mettre à jour les couleurs des onglets
	for tabName, btn in pairs(tabButtons) do
		Theme.SetButtonColor(btn, currentTab == tabName and Theme.Colors.Lagoon or Theme.Colors.PlateLight)
	end

	-- Nettoyer les vieilles cartes
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and (child.Name:match("^CodexCard_") or child.Name:match("^CosmeticCard_")) then
			child:Destroy()
		end
	end
	table.clear(cardRefs)

	if currentTab == "Creatures" then
		local sorted = getSortedSpecies()
		for i, speciesId in ipairs(sorted) do
			createSpeciesCard(speciesId, i, scroll)
		end
		local discovered = getDiscoveredCount()
		local total = getTotalVisibleSlots()
		counter.Set(counter, discovered, false)
		progressBar.Set(progressBar, total > 0 and discovered / total or 0, true)
		progressBar.SetText(progressBar, discovered .. " / " .. total .. " SPECIES")
	elseif currentTab == "Cosmetics" then
		for i, cosmetic in ipairs(PLACEHOLDER_COSMETICS) do
			createCosmeticCard(cosmetic, i, scroll)
		end
		local owned = getOwnedCosmeticsCount()
		local totalCosmetics = #PLACEHOLDER_COSMETICS
		counter.Set(counter, owned, false)
		progressBar.Set(progressBar, totalCosmetics > 0 and owned / totalCosmetics or 0, true)
		progressBar.SetText(progressBar, owned .. " / " .. totalCosmetics .. " ITEMS")
	end

	task.wait()
	scroll.CanvasSize = UDim2.fromOffset(0, scroll.UIListLayout.AbsoluteContentSize.Y + 20)
end

-------------------------------------------------------------- Ouverture / Fermeture
function Codex.Open()
	if isOpen then return end
	isOpen = true

	if not panelRef then
		Codex.CreatePanel(game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"))
	end

	panelRef.Backdrop.Visible = true
	panelRef.Panel.Visible = true

	local scale = Theme.GetScale(panelRef.Panel)
	scale.Scale = 0
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1
	}):Play()

	Codex.Refresh()

	local conn
	conn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.Escape then
			Codex.Close()
			conn:Disconnect()
		end
	end)
end

function Codex.Close()
	if not isOpen then return end
	isOpen = false
	if panelRef then
		panelRef.Backdrop.Visible = false
		panelRef.Panel.Visible = false
	end
end

function Codex.Toggle()
	if isOpen then Codex.Close() else Codex.Open() end
end

-------------------------------------------------------------- Fiche détaillée (clic sur découvert)
function Codex.OpenDetail(speciesId: string, variant: string)
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = playerGui:FindFirstChild("CodexGui")
	if not screenGui then return end

	local speciesData = Config.Creatures[speciesId]
	if not speciesData then return end

	local rarity = getSpeciesRarity(speciesId)
	local rarityColor = getRarityColor(rarity)
	local mutationData = Config.Mutations[variant]
	local mutColor = mutationData and mutationData.color or rarityColor
	local mutLabel = getVariantLabel(variant)

	local backdrop = Theme.Create("Frame", {
		Name = "DetailBackdrop",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.7,
		ZIndex = 60,
		Parent = screenGui,
	})

	local card = Components.Card({
		Name = "DetailCard",
		Size = UDim2.fromOffset(360, 420),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Icon = speciesId,
		Title = speciesData.name .. " — " .. mutLabel,
		Color = variant == "Golden" and mutColor or rarityColor,
		Lines = {
			"RARITY: " .. rarity,
			"VARIANT: " .. mutLabel,
			"BASE INCOME: " .. Config.Format(speciesData.income) .. "/s",
			"MUTATION MULT: x" .. (mutationData and mutationData.mult or 1),
			"STAGE MULT: x1 / x2 / x4 / x8",
			"",
			"DISCOVERED: " .. (isDiscovered(speciesId, variant) and "YES" or "NO"),
		},
		ButtonText = "CLOSE",
		ButtonColor = Theme.Colors.Lagoon,
		Parent = backdrop,
	})

	card.Button.Activated:Connect(function()
		backdrop:Destroy()
	end)

	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			backdrop:Destroy()
		end
	end)

	card.Instance.Size = UDim2.fromOffset(0, 0)
	TweenService:Create(card.Instance, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(360, 420)
	}):Play()
end

-------------------------------------------------------------- Synchronisation avec le serveur
function Codex.BindToState(state)
	if state.codex then
		codexCache = state.codex
	end
	if state.codexCount then
		codexCount = state.codexCount
	end
	if state.codexTotal then
		codexTotal = state.codexTotal
	end
	if state.cosmetics then
		cosmeticsCache = state.cosmetics
	end
	Codex.Refresh()
end

function Codex.OnNotify(kind, data)
	if kind == "codex" then
		if data.species and data.variant then
			if not codexCache[data.species] then
				codexCache[data.species] = {}
			end
			codexCache[data.species][data.variant] = true
			codexCount = data.count or codexCount
			codexTotal = data.total or codexTotal

			if panelRef and cardRefs[data.species] then
				local card = cardRefs[data.species]
				if card.variantButtons[data.variant] then
					local btn = card.variantButtons[data.variant]
					btn.SetEnabled(btn, true)
					Theme.Celebrate(btn.Button, 0.15)
					if Sfx then Sfx.Play(POP_SOUND_ID) end
				end
			end
			Codex.Refresh()
		end
	elseif kind == "cosmetic" then
		if data.cosmeticId then
			cosmeticsCache[data.cosmeticId] = true
			Codex.Refresh()
		end
	end
end

return Codex