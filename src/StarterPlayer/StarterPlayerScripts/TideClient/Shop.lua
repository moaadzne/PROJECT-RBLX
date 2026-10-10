-- Shop : boutique de lancement (GDD v2 §9, contrat v2.1). Style console. S'ouvre seulement sur demande
-- (jamais de pop-up), aucun compte a rebours, prix fixes, « Everything here is optional ».
--   - Tide Egg (aleatoire) : probabilites de Config.Shop.TideEgg affichees AVANT l'achat ;
--     odds par rarete (60/25/10/4/1) + pity counter (50 -> garantie Legendary) ;
--     remplace par Pick a Creature (achat direct, RF ChoosePick avant l'achat) si state.shop.randomAllowed est faux.
--   - Gamepasses de Config.Shop.Passes ; « OWNED » d'apres state.passes.
--   - Bundle StarterPack (VIP + Speed + Bag) valeur percue 327 -> prix 249
--   - Rewarded Ad : opt-in 1 TideEgg/jour, cooldown 24h, bouton "Regarder pour recompense"
--   - id = 0 dans Config : produit pas encore cree, carte affichee mais achat coupe (« SOON »).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shop = {}

local PANEL_SIZE = Vector2.new(800, 400)
local OPEN_TIME = 0.2
local BLUR_SIZE = 12
local CARD_H = 300
local PASS_W = 150
local RANDOM_W = 260

-- Gamepasses + Bundle (6 mots max par ligne)
local PASS_INFO = {
	{ key = "VIPRider", name = "VIP Rider", icon = "crown", lines = { "+10% coins", "+10% ride speed", "VIP title" } },
	{ key = "SpeedBoost", name = "Speed Boost", icon = "ride", lines = { "Wave speed", "+15%", "GoHome -30% cd" } },
	{ key = "BagExpand", name = "Bag Expansion", icon = "net", lines = { "+10 slots", "inventory" } },
}

-- Bundle StarterPack (valeur percue 327 -> 249)
local BUNDLE_INFO = {
	key = "StarterPack",
	name = "Starter Pack",
	icon = "chest",
	lines = { "VIP Rider", "Speed Boost", "Bag Expansion" },
	valueLines = { "Value 327", "Price 249" },
}

local Util, Theme, Components, Store, Hud, Notifications, Config, Sfx
local player = Players.LocalPlayer
local root: Frame
local panel: CanvasGroup
local scale: UIScale
local blur: BlurEffect? = nil
local isOpen = false
local openToken = 0
local cardsFrame: Frame
local builtKey: string? = nil -- la grille suit la politique du joueur et ses gamepasses

local function shopConfig(): any
	local s = (Config :: any).Shop
	return if type(s) == "table" then s else {}
end

local function priceText(price: number?): string
	return if price then "R$ " .. tostring(price) else "Soon"
end

local function soon()
	Notifications.Push({ text = "COMING SOON", color = Theme.Colors.Lagoon, icon = "info", key = "shop" })
end

---------------------------------------------------------------- Cartes
local function passCard(info, order: number)
		local cfg = (shopConfig().Passes or {})[info.key]
		local id = cfg and tonumber(cfg.id) or 0
		local price = cfg and tonumber(cfg.price)
		local owned = Store.Get().passes[info.key] == true
		local sellable = id > 0 and not owned
		local card = Components.Card({
			Name = info.key,
			Size = UDim2.fromOffset(PASS_W, CARD_H),
			Icon = info.icon,
			Title = info.name,
			Lines = info.lines,
			Color = Theme.Colors.Lagoon,
			ButtonText = if owned then "Owned" elseif id > 0 then priceText(price) else "Soon",
			ButtonColor = if sellable then Theme.Colors.Lagoon else Theme.Colors.Disabled,
			LayoutOrder = order,
		})
		card.Instance.Parent = cardsFrame
		card.Button.Activated:Connect(function()
			if owned then
				return
			elseif not sellable then
				soon()
				return
			end
			MarketplaceService:PromptGamePassPurchase(player, id)
		end)
	end

	-- Bundle StarterPack card (grande, accent Gold)
	local function bundleCard(order: number)
		local cfg = shopConfig()
		local bundle = cfg.Passes and cfg.Passes.StarterPack
		local id = bundle and tonumber(bundle.id) or 0
		local price = bundle and tonumber(bundle.price)
		local owned = Store.Get().passes.StarterPack == true
		local sellable = id > 0 and not owned
		local card = Components.Glass({
			Name = "StarterPack",
			Size = UDim2.fromOffset(RANDOM_W, CARD_H),
			Accent = Theme.Colors.Gold,
			Strong = true,
			LayoutOrder = order,
		})
		card.Parent = cardsFrame
		Theme.Title({
			Name = "Title",
			Position = UDim2.fromOffset(0, 12),
			Size = UDim2.new(1, 0, 0, 28),
			Text = BUNDLE_INFO.name,
			TextSize = Theme.TextSize.Large,
			TextColor3 = Theme.Colors.Gold,
			ZIndex = 2,
			Parent = card,
		})
		local list = Theme.Create("Frame", {
			Name = "List",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 50),
			Size = UDim2.new(1, -28, 1, -112),
			ZIndex = 2,
			Parent = card,
		})
		Theme.List(list, Enum.FillDirection.Vertical, 4)
		-- Includes
		for i, line in BUNDLE_INFO.lines do
			Theme.Text({
				Size = UDim2.new(1, 0, 0, 20),
				Text = line,
				TextSize = Theme.TextSize.Small,
				FontFace = Theme.Fonts.Medium,
				TextColor3 = Theme.Colors.Text,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = i,
				ZIndex = 3,
				Parent = list,
			})
		end
		-- Value
		for i, line in BUNDLE_INFO.valueLines do
			Theme.Text({
				Size = UDim2.new(1, 0, 0, 20),
				Text = line,
				TextSize = Theme.TextSize.Small,
				FontFace = Theme.Fonts.Title,
				TextColor3 = Theme.Colors.Gold,
				TextXAlignment = Enum.TextXAlignment.Left,
				LayoutOrder = 10 + i,
				ZIndex = 3,
				Parent = list,
			})
		end
		local buy = Theme.Button({
			Name = "Buy",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(1, -20, 0, 42),
			Color = Theme.Colors.Gold,
			Parent = card,
		})
		buy.ZIndex = 2
		Theme.SetButtonText(buy, if sellable then priceText(price) else "Soon")
		Theme.SetButtonColor(buy, if sellable then Theme.Colors.Gold else Theme.Colors.Disabled)
		buy.Activated:Connect(function()
			if owned then return elseif not sellable then soon() return end
			MarketplaceService:PromptGamePassPurchase(player, id)
		end)
	end

-- Rewarded Ad card (opt-in 1 TideEgg/jour)
local function rewardedAdCard(order: number)
	local state = Store.Get()
	local cfg = shopConfig()
	local ad = cfg.RewardedAd
	if not ad or not ad.enabled then return end
	
	local card = Components.Glass({
		Name = "RewardedAd",
		Size = UDim2.fromOffset(PASS_W, CARD_H),
		Accent = Theme.Colors.Lagoon,
		Strong = true,
		LayoutOrder = order,
	})
	card.Parent = cardsFrame
	Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 28),
		Text = "Free Tide Egg",
		TextSize = Theme.TextSize.Large,
		TextColor3 = Theme.Colors.Lagoon,
		ZIndex = 2,
		Parent = card,
	})
	Theme.Text({
		Name = "Desc",
		Position = UDim2.fromOffset(14, 50),
		Size = UDim2.new(1, -28, 0, 60),
		Text = "Watch a short ad\nGet 1 Tide Egg\nOnce per day",
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = card,
	})
	local watch = Theme.Button({
		Name = "Watch",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 42),
		Color = Theme.Colors.Lagoon,
		Text = "Watch for Reward",
		TextSize = Theme.TextSize.Small,
		Parent = card,
	})
	watch.ZIndex = 2
	watch.Activated:Connect(function()
		if state.lastRewardedAd and (Store.Now() - state.lastRewardedAd) < (ad.cooldownHours or 24) * 3600 then
			Notifications.Push({ text = "COME BACK TOMORROW", color = Theme.Colors.Warning, icon = "clock", key = "shop" })
			return
		end
		MarketplaceService:PromptProductPurchase(player, ad.id or 0)
	end)
end
local function randomCard(randomAllowed: boolean)
	local cfg = shopConfig()
	local card = Components.Glass({
		Name = if randomAllowed then "TideEgg" else "PickCreature",
		Size = UDim2.fromOffset(RANDOM_W, CARD_H),
		Accent = Theme.Colors.Gold,
		Strong = true,
		LayoutOrder = 0,
	})
	card.Parent = cardsFrame
	Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 28),
		Text = if randomAllowed then "Tide Egg" else "Pick a Creature",
		TextSize = Theme.TextSize.Large,
		TextColor3 = Theme.Colors.Gold,
		ZIndex = 2,
		Parent = card,
	})
	local list = Theme.Create("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 50),
		Size = UDim2.new(1, -28, 1, -112),
		ZIndex = 2,
		Parent = card,
	})
	Theme.List(list, Enum.FillDirection.Vertical, 4)
	local buy = Theme.Button({
		Name = "Buy",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -20, 0, 42),
		Color = Theme.Colors.Gold,
		Parent = card,
	})
	buy.ZIndex = 2

	if randomAllowed then
		-- probabilites affichees avant l'achat ; sans table dans Config, pas de vente (jamais de chiffres inventes)
		local egg = cfg.TideEgg
		local odds = type(egg) == "table" and egg.odds or nil
		local hasOdds = type(odds) == "table" and #odds > 0
		if hasOdds then
			for i, o in odds do
				local species, chance = o[1], o[2]
				local info = Store.CreatureInfo(species)
				local rarity = info and info.rarity
				local row = Theme.Create("Frame", {
					Name = "Odds" .. i,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 24),
					LayoutOrder = i,
					ZIndex = 2,
					Parent = list,
				})
				local badge = Theme.RarityBadge(rarity, 20)
				badge.AnchorPoint = Vector2.new(0, 0.5)
				badge.Position = UDim2.new(0, 0, 0.5, 0)
				badge.ZIndex = 3
				badge.Parent = row
				Theme.Text({
					Position = UDim2.fromOffset(28, 0),
					Size = UDim2.new(1, -80, 1, 0),
					Text = string.upper(Store.CreatureName(species)),
					TextSize = Theme.TextSize.Small,
					FontFace = Theme.Fonts.Title,
					TextColor3 = Theme.RarityColor(rarity),
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 3,
					Parent = row,
				})
				Theme.Text({
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 0, 0, 0),
					Size = UDim2.new(0, 60, 1, 0),
					Text = tostring(chance) .. "%",
					TextSize = Theme.TextSize.Small,
					FontFace = Theme.Fonts.Number,
					TextXAlignment = Enum.TextXAlignment.Right,
					ZIndex = 3,
					Parent = row,
				})
			end
			if tonumber(egg.goldenChance) then
				Theme.Text({
					Name = "Golden",
					Size = UDim2.new(1, 0, 0, 24),
					Text = "THEN " .. tostring(egg.goldenChance) .. "% GOLDEN",
					TextSize = Theme.TextSize.Small,
					FontFace = Theme.Fonts.Title,
					TextColor3 = Theme.Mutations.Golden.color,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 99,
					ZIndex = 2,
					Parent = list,
				})
			end
			-- Pity counter (Legendary guaranteed at 50)
			local state = Store.Get()
			local pity = state.tideEggPity or 0
			Theme.Text({
				Name = "Pity",
				Size = UDim2.new(1, 0, 0, 20),
				Text = "PITY: " .. pity .. " / 50 (LEGENDARY GUARANTEED)",
				TextSize = Theme.TextSize.Small,
				FontFace = Theme.Fonts.Title,
				TextColor3 = if pity >= 45 then Theme.Colors.Danger else Theme.Colors.Gold,
				TextXAlignment = Enum.TextXAlignment.Center,
				LayoutOrder = 100,
				ZIndex = 2,
				Parent = list,
			})
		end
		local id = type(egg) == "table" and tonumber(egg.id) or 0
		local sellable = (id or 0) > 0 and hasOdds
		Theme.SetButtonText(buy, if sellable then priceText(tonumber(egg.price)) else "Soon")
		Theme.SetButtonColor(buy, if sellable then Theme.Colors.Gold else Theme.Colors.Disabled)
		buy.Activated:Connect(function()
			if sellable then
				MarketplaceService:PromptProductPurchase(player, id)
			else
				soon()
			end
		end)
		return
	end

	-- Pick a Creature : le joueur choisit l'espece, ChoosePick, puis achat direct
	local pick = cfg.PickCreature
	local speciesList = type(pick) == "table" and pick.species or {}
	local chosen: string? = nil
	local choiceButtons = {}
	for i, sp in speciesList do
		local b = Theme.Button({
			Name = sp,
			Size = UDim2.new(1, 0, 0, 34),
			Text = Store.CreatureName(sp),
			TextSize = Theme.TextSize.Small,
			Color = Theme.Colors.PlateLight,
			LayoutOrder = i,
			Parent = list,
		})
		b.ZIndex = 2
		choiceButtons[sp] = b
		b.Activated:Connect(function()
			chosen = sp
			for other, ob in choiceButtons do
				local info = Store.CreatureInfo(other)
				Theme.SetButtonColor(ob, if other == sp then Theme.RarityColor(info and info.rarity) else Theme.Colors.PlateLight)
			end
		end)
	end
	local id = type(pick) == "table" and tonumber(pick.id) or 0
	local sellable = (id or 0) > 0
	Theme.SetButtonText(buy, if sellable then priceText(tonumber(pick.price)) else "Soon")
	Theme.SetButtonColor(buy, if sellable then Theme.Colors.Gold else Theme.Colors.Disabled)
	buy.Activated:Connect(function()
		if not sellable then
			soon()
			return
		end
		if not chosen then
			Theme.Shake(buy)
			Notifications.Push({ text = "PICK A CREATURE FIRST", color = Theme.Colors.Warning, icon = "info", key = "shop" })
			return
		end
		local ok = Store.ChoosePick(chosen)
		if ok then
			MarketplaceService:PromptProductPurchase(player, id)
		else
			Notifications.Push({ text = "CAN'T BUY RIGHT NOW", color = Theme.Colors.Danger, icon = "close", key = "shop" })
		end
	end)
end

local function gridKey(state): string
	local owned = {}
	for _, info in PASS_INFO do
		table.insert(owned, if state.passes[info.key] then "1" else "0")
	end
	local bundle = state.passes.StarterPack and "1" or "0"
	return (if state.shop.randomAllowed then "egg" else "pick") .. table.concat(owned) .. bundle
end

local function buildCards()
	local state = Store.Get()
	local key = gridKey(state)
	if builtKey == key then
		return
	end
	builtKey = key
	for _, child in cardsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	randomCard(state.shop.randomAllowed)
	bundleCard(0)
	for i, info in PASS_INFO do
		passCard(info, i)
	end
	rewardedAdCard(99)
end

---------------------------------------------------------------- Panneau
function Shop.Open()
	if isOpen then
		return
	end
	isOpen = true
	openToken += 1
	buildCards()
	root.Visible = true
	panel.GroupTransparency = 1
	scale.Scale = 0.94
	Util.Tween(panel, OPEN_TIME, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	Util.Tween(scale, OPEN_TIME, { Scale = 1 }, Enum.EasingStyle.Quart)
	local cam = workspace.CurrentCamera
	if cam then
		local b = blur or Instance.new("BlurEffect")
		blur = b
		b.Name = "TR_ShopBlur"
		b.Size = 0
		b.Parent = cam -- effets client dans la camera, jamais dans Lighting
		Util.Tween(b, OPEN_TIME, { Size = BLUR_SIZE }, Enum.EasingStyle.Quad)
	end
	Sfx.Play("whoosh")
end

function Shop.Close()
	if not isOpen then
		return
	end
	isOpen = false
	openToken += 1
	local token = openToken
	Util.Tween(panel, Theme.Time.Fast, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
	Util.Tween(scale, Theme.Time.Fast, { Scale = 0.96 }, Enum.EasingStyle.Quad)
	if blur then
		Util.Tween(blur, Theme.Time.Fast, { Size = 0 }, Enum.EasingStyle.Quad)
	end
	task.delay(Theme.Time.Fast + 0.02, function()
		if openToken == token then
			root.Visible = false
			if blur then
				blur.Parent = nil
			end
		end
	end)
end

local function build(parent: Instance)
	root = Theme.Create("Frame", {
		Name = "Shop",
		BackgroundColor3 = Theme.Colors.Black,
		BackgroundTransparency = 0.5,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	-- toucher le fond = fermer
	local backdrop = Theme.Create("TextButton", {
		Name = "Backdrop",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 20,
		Parent = root,
	})
	backdrop.Activated:Connect(Shop.Close)
	panel = Theme.Create("CanvasGroup", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(PANEL_SIZE.X, PANEL_SIZE.Y),
		BackgroundTransparency = 1,
		ZIndex = 21,
		Parent = root,
	})
	scale = Theme.GetScale(panel)
	local plate = Theme.Plate({
		Name = "Plate",
		Position = UDim2.fromOffset(2, 2),
		Size = UDim2.new(1, -4, 1, -4),
		Strong = true,
		Parent = panel,
	})
	Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(20, 12),
		Size = UDim2.new(0, 200, 0, 36),
		Text = "Shop",
		TextSize = Theme.TextSize.Huge,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = plate,
	})
	Theme.Text({
		Name = "Note",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -70, 0, 20),
		Size = UDim2.fromOffset(300, 24),
		Text = "Everything here is optional.",
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Medium,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = plate,
	})
	local close = Theme.Create("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Theme.Colors.PlateLight,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 3,
		Parent = plate,
	})
	Theme.Corner(close, 6)
	local x = Theme.Icon("close", 22, Theme.Colors.Text)
	x.AnchorPoint = Vector2.new(0.5, 0.5)
	x.Position = UDim2.fromScale(0.5, 0.5)
	x.ZIndex = 4
	x.Parent = close
	Theme.Pressable(close)
	close.Activated:Connect(Shop.Close)
	cardsFrame = Theme.Create("Frame", {
		Name = "Cards",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -16),
		Size = UDim2.new(1, -24, 0, CARD_H + 8),
		ZIndex = 3,
		Parent = plate,
	})
	Theme.List(cardsFrame, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
end

---------------------------------------------------------------- Demarrage
function Shop.Init(ctx)
	Util, Theme, Components, Hud = ctx.Util, ctx.Theme, ctx.Components, ctx.Hud
	Notifications, Config, Sfx = ctx.Notifications, ctx.Config, ctx.Sfx
	build(ctx.Root)
	Hud.SetAction("shop", { icon = "shop", label = "Shop", color = Theme.Colors.Gold, order = 3, hotkey = "B", visible = false })
end

function Shop.Start(ctx)
	Store = ctx.Store
	Hud.SetAction("shop", {
		onActivated = function()
			if isOpen then
				Shop.Close()
			else
				Shop.Open()
			end
		end,
	})
	local function refresh(state)
		-- pas de boutique pendant l'intro (GDD §1 ter)
		Hud.SetAction("shop", { visible = state.loaded and state.intro == "done" })
		if isOpen then
			buildCards() -- politique ou gamepasses changes pendant que le panneau est ouvert
		end
	end
	Store.Changed:Connect(refresh)
	refresh(Store.Get())
	Store.Notified:Connect(function(kind, data)
		if kind ~= "purchase" then
			return
		end
		-- achat accorde : un vrai moment, mais sobre
		local what = if type(data.species) == "string" then Store.CreatureName(data.species) else tostring(data.product or "")
		Notifications.Push({ text = "UNLOCKED  " .. string.upper(what), color = Theme.Colors.Gold, icon = "spark", priority = "reward" })
		Sfx.Play("purchase")
	end)
end

return Shop
