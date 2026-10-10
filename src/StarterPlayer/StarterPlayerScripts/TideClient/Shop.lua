-- Shop : boutique de lancement (GDD v2 §9, contrat v2.1 + DECISIONS_MARCHE.md). Style console.
-- S'ouvre seulement sur demande (jamais de pop-up), aucun compte a rebours, prix fixes, "Everything here is optional".
--   - Tide Egg (aleatoire) : probabilites de Config.Shop.TideEgg.chances affichees AVANT l'achat ;
--     remplace par Pick a Creature (achat direct, RF ChoosePick avant l'achat) si state.shop.randomAllowed est faux.
--   - Gamepasses de Config.Shop.Passes : VIPRider, SpeedBoost, BagExpand, StarterPack ; "OWNED" d'apres state.passes.
--   - Rewarded Video Ads : 1 TideEgg gratuit/jour (RF ClaimRewardedAd, cooldown 24h).
--   - id = 0 dans Config : produit pas encore cree, carte affichee mais achat coupe ("SOON").
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shop = {}

local PANEL_SIZE = Vector2.new(860, 440)
local OPEN_TIME = 0.2
local BLUR_SIZE = 12
local CARD_H = 320
local PASS_W = 160
local RANDOM_W = 300

-- Textes des gamepasses (max ~6 mots par ligne) ; prix et ids viennent de Config.Shop.Passes
local PASS_INFO = {
	{ key = "VIPRider",   name = "VIP Rider",   icon = "crown", lines = { "+10% Coins", "+10% Ride Speed", "Priority Queue", "Exclusive Emote" } },
	{ key = "SpeedBoost", name = "Speed Boost", icon = "bolt",  lines = { "+15% Wave Speed", "-30% GoHome CD" } },
	{ key = "BagExpand",  name = "Bag Expand",  icon = "bag",   lines = { "+10 Inventory", "Slots" } },
	{ key = "StarterPack",name = "Starter Pack",icon = "star",  lines = { "VIP + Speed + Bag", "Best Value" } },
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
local builtKey: string? = nil

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

-------------------------------------------------------------- Cartes
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

-- Grande carte : Tide Egg (probabilites completes) ou Pick a Creature (choix de l'espece) ou Rewarded Ad
local function randomCard(randomAllowed: boolean, rewardedAdReady: boolean)
	local cfg = shopConfig()
	local isRewarded = rewardedAdReady and not randomAllowed -- si pas randomAllowed, on montre Rewarded Ad en priorité
	local cardName = if isRewarded then "RewardedAd" elseif randomAllowed then "TideEgg" else "PickCreature"
	local card = Components.Glass({
		Name = cardName,
		Size = UDim2.fromOffset(RANDOM_W, CARD_H),
		Accent = if isRewarded then Theme.Colors.Emerald else Theme.Colors.Gold,
		Strong = true,
		LayoutOrder = 0,
	})
	card.Parent = cardsFrame
	Theme.Title({
		Name = "Title",
		Position = UDim2.fromOffset(0, 12),
		Size = UDim2.new(1, 0, 0, 28),
		Text = if isRewarded then "Free Tide Egg" elseif randomAllowed then "Tide Egg" else "Pick a Creature",
		TextSize = Theme.TextSize.Large,
		TextColor3 = if isRewarded then Theme.Colors.Emerald else Theme.Colors.Gold,
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
		Color = if isRewarded then Theme.Colors.Emerald else Theme.Colors.Gold,
		Parent = card,
	})
	buy.ZIndex = 2

	if isRewarded then
		-- Rewarded Ad : 1 TideEgg gratuit/jour
		Theme.Text({
			Name = "Desc",
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 40),
			Text = "Watch a short video\nto get a free Tide Egg",
			TextSize = Theme.TextSize.Medium,
			FontFace = Theme.Fonts.Medium,
			TextColor3 = Theme.Colors.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 2,
			Parent = list,
		})
		local id = type(cfg.RewardedAd) == "table" and "RewardedAd" -- pas d'id Roblox pour les pubs
		local sellable = cfg.RewardedAd and cfg.RewardedAd.enabled == true
		Theme.SetButtonText(buy, if sellable then "CLAIM FREE" else "Soon")
		Theme.SetButtonColor(buy, if sellable then Theme.Colors.Emerald else Theme.Colors.Disabled)
		buy.Activated:Connect(function()
			if sellable then
				Store.ClaimRewardedAd()
			else
				soon()
			end
		end)
		return
	end

	if randomAllowed then
		-- Tide Egg : probabilites affichees avant l'achat
		local egg = cfg.TideEgg
		local chances = type(egg) == "table" and egg.chances or nil
		local hasOdds = type(chances) == "table" and next(chances) ~= nil
		-- Ancien format odds (tableau) en fallback
		local legacyOdds = type(egg) == "table" and egg.odds or nil
		local hasLegacy = type(legacyOdds) == "table" and #legacyOdds > 0

		if hasOdds then
			-- Nouveau format : { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 }
			local rarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }
			for _, rarity in ipairs(rarityOrder) do
				local chance = chances[rarity]
				if chance and chance > 0 then
					local row = Theme.Create("Frame", {
						Name = "Odds_" .. rarity,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 24),
						LayoutOrder = (table.find(rarityOrder, rarity) or 0) * 10,
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
						Text = string.upper(rarity),
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
		elseif hasLegacy then
			-- Ancien format : tableau de { species, chance }
			for i, o in ipairs(legacyOdds) do
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
		end

		local id = type(egg) == "table" and tonumber(egg.id) or 0
		local sellable = (id or 0) > 0 and (hasOdds or hasLegacy)
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
	for i, sp in ipairs(speciesList) do
		local info = Store.CreatureInfo(sp)
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
			for other, ob in pairs(choiceButtons) do
				local oinfo = Store.CreatureInfo(other)
				Theme.SetButtonColor(ob, if other == sp then Theme.RarityColor(oinfo and oinfo.rarity) else Theme.Colors.PlateLight)
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
	local ad = shopConfig().RewardedAd
	local adReady = ad and ad.enabled and (state.data and state.data._rewardedAdCooldown or 0) <= Store.Now()
	return (if adReady then "ad" elseif state.shop.randomAllowed then "egg" else "pick") .. table.concat(owned)
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
	local ad = shopConfig().RewardedAd
	local adReady = ad and ad.enabled and (state.data and state.data._rewardedAdCooldown or 0) <= Store.Now()
	randomCard(state.shop.randomAllowed, adReady)
	for i, info in PASS_INFO do
		passCard(info, i)
	end
end

-------------------------------------------------------------- Panneau
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
		b.Parent = cam
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

-------------------------------------------------------------- Demarrage
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
		Hud.SetAction("shop", { visible = state.loaded and state.intro == "done" })
		if isOpen then
			buildCards()
		end
	end
	Store.Changed:Connect(refresh)
	refresh(Store.Get())
	Store.Notified:Connect(function(kind, data)
		if kind ~= "purchase" then
			return
		end
		local what = if type(data.species) == "string" then Store.CreatureName(data.species) else tostring(data.product or "")
		Notifications.Push({ text = "UNLOCKED  " .. string.upper(what), color = Theme.Colors.Gold, icon = "spark", priority = "reward" })
		Sfx.Play("purchase")
	end)
end

return Shop