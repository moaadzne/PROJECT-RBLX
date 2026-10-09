-- Shop : boutique de lancement (GDD v2 §9). S'ouvre seulement quand le joueur appuie sur Shop (jamais de pop-up),
-- aucun compte a rebours, prix fixes.
--   - Tide Egg (produit aleatoire) : probabilites affichees AVANT l'achat, lues dans Config.Shop (jamais en dur) ;
--     remplace par « Pick a Creature » (achat direct) si state.policy.paidRandomRestricted (PolicyService, expose par A).
--   - Gamepasses : Fast Growth, Big Net, VIP Rider ; « Owned » si deja possede.
-- HYPOTHESE (a valider par A) : Config.Shop = { gamepasses = {{key, id, name, price, icon, lines}},
--   tideEgg = {id, price, odds = {{species, chance}}, goldenChance}, pick = {id, price, species = {...}} }
-- et RF PickCreature(species) appele avant l'achat de Pick a Creature (le recu ne porte pas le choix).
-- Sans id (0 ou absent), la carte s'affiche mais l'achat est desactive (« Soon »).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shop = {}

local PANEL_SIZE = Vector2.new(820, 400)
local OPEN_TIME = 0.25
local BLUR_SIZE = 14
local CARD_H = 300
local PASS_W = 150
local RANDOM_W = 260

-- Catalogue de reference (GDD §9) : textes et prix affiches tant que Config.Shop manque ; achats coupes sans id
local DEFAULT_PASSES = {
	{ key = "FastGrowth", name = "Fast Growth", price = 299, icon = "🌱", lines = { "Creatures grow", "2× faster" } },
	{ key = "BigNet", name = "Big Net", price = 149, icon = "🕸️", lines = { "Catch radius", "×1.5" } },
	{ key = "VipRider", name = "VIP Rider", price = 399, icon = "⭐", lines = { "+10% coins", "Rides +10%", "Title & trail" } },
}

local Util, Theme, Components, Store, Hud, Notifications, Config, Sfx
local player = Players.LocalPlayer
local root: Frame
local panel: CanvasGroup
local scale: UIScale
local blur: BlurEffect? = nil
local isOpen = false
local openToken = 0
local owned: { [number]: boolean } = {}
local cardsFrame: Frame
local builtFor: string? = nil -- "egg" | "pick" : la carte aleatoire suit la politique du joueur

local function shopConfig(): any
	local s = (Config :: any).Shop
	return if type(s) == "table" then s else {}
end

local function robux(price: number?): string
	return if price then "R$ " .. tostring(price) else "Soon"
end

---------------------------------------------------------------- Achat
local function buyPass(id: number?)
	if not id or id <= 0 then
		Notifications.Push({ text = "Coming soon!", color = Theme.Colors.Lagoon, icon = "🛒", key = "shop" })
		return
	end
	MarketplaceService:PromptGamePassPurchase(player, id)
end

local function buyProduct(id: number?)
	if not id or id <= 0 then
		Notifications.Push({ text = "Coming soon!", color = Theme.Colors.Lagoon, icon = "🛒", key = "shop" })
		return
	end
	MarketplaceService:PromptProductPurchase(player, id)
end

---------------------------------------------------------------- Cartes
local function passCard(def, order: number)
	local cfg = nil
	for _, p in shopConfig().gamepasses or {} do
		if p.key == def.key then
			cfg = p
		end
	end
	local id = cfg and tonumber(cfg.id)
	local price = cfg and tonumber(cfg.price) or def.price
	local card = Components.Card({
		Name = def.key,
		Size = UDim2.fromOffset(PASS_W, CARD_H),
		Icon = cfg and cfg.icon or def.icon,
		Title = cfg and cfg.name or def.name,
		Lines = cfg and cfg.lines or def.lines,
		Color = Theme.Colors.Lagoon,
		ButtonText = if id and owned[id] then "Owned" else robux(price),
		ButtonColor = if id and id > 0 then Theme.Colors.Success else Theme.Colors.Disabled,
		LayoutOrder = order,
	})
	-- parent pose apres coup : pas d'ombre soeur qui prendrait une place dans la liste
	card.Instance.Parent = cardsFrame
	card.Button.Activated:Connect(function()
		if id and owned[id] then
			return
		end
		buyPass(id)
	end)
	-- possession verifiee en arriere-plan
	if id and id > 0 and owned[id] == nil then
		task.spawn(function()
			local ok, has = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, id)
			if ok then
				owned[id] = has
				if has and card.Button.Parent then
					local label = card.Button:FindFirstChild("Label") :: TextLabel?
					if label then
						label.Text = "Owned"
					end
					Theme.SetButtonColor(card.Button, Theme.Colors.Disabled)
				end
			end
		end)
	end
end

-- Grande carte : Tide Egg (probabilites completes) ou Pick a Creature (choix de l'espece)
local function randomCard(restricted: boolean)
	local cfg = shopConfig()
	local card = Components.Glass({
		Name = if restricted then "PickCreature" else "TideEgg",
		Size = UDim2.fromOffset(RANDOM_W, CARD_H),
		Strong = true,
		LayoutOrder = 0,
	})
	card.Parent = cardsFrame
	Theme.Text({
		Name = "Title",
		Position = UDim2.fromOffset(0, 10),
		Size = UDim2.new(1, 0, 0, 30),
		Text = if restricted then "🐾 Pick a Creature" else "🥚 Tide Egg",
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		ZIndex = 2,
		Parent = card,
	})
	local list = Theme.Create("Frame", {
		Name = "List",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(14, 46),
		Size = UDim2.new(1, -28, 1, -110),
		ZIndex = 2,
		Parent = card,
	})
	Theme.List(list, Enum.FillDirection.Vertical, 4)
	local buy = Theme.Button({
		Name = "Buy",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(1, -24, 0, 46),
		Parent = card,
	})
	buy.ZIndex = 2

	if not restricted then
		-- probabilites affichees avant l'achat ; sans table dans Config, pas de vente (jamais de chiffres inventes)
		local egg = cfg.tideEgg
		local odds = type(egg) == "table" and egg.odds or nil
		if type(odds) == "table" and #odds > 0 then
			for i, o in odds do
				local info = Store.CreatureInfo(o.species)
				local rarity = info and info.rarity
				local row = Theme.Text({
					Name = "Odds" .. i,
					Size = UDim2.new(1, 0, 0, 24),
					Text = Store.CreatureName(o.species) .. "  " .. tostring(o.chance) .. "%",
					TextSize = Theme.TextSize.Small,
					TextColor3 = Theme.RarityColor(rarity),
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = i,
					ZIndex = 2,
					Parent = list,
				})
				local badge = Theme.RarityBadge(rarity, 20)
				badge.AnchorPoint = Vector2.new(1, 0.5)
				badge.Position = UDim2.new(1, 0, 0.5, 0)
				badge.ZIndex = 3
				badge.Parent = row
			end
			if tonumber(egg.goldenChance) then
				Theme.Text({
					Name = "Golden",
					Size = UDim2.new(1, 0, 0, 24),
					Text = "✨ then " .. tostring(egg.goldenChance) .. "% Golden",
					TextSize = Theme.TextSize.Small,
					TextColor3 = Theme.Mutations.Golden.color,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 99,
					ZIndex = 2,
					Parent = list,
				})
			end
		else
			Theme.Text({
				Name = "NoOdds",
				Size = UDim2.new(1, 0, 0, 48),
				Text = "Odds will be shown here.",
				TextSize = Theme.TextSize.Small,
				TextColor3 = Theme.Colors.TextDim,
				TextWrapped = true,
				ZIndex = 2,
				Parent = list,
			})
		end
		local id = type(egg) == "table" and tonumber(egg.id) or nil
		local sellable = id ~= nil and id > 0 and type(odds) == "table" and #odds > 0
		local label = buy:FindFirstChild("Label") :: TextLabel
		label.Text = if sellable then robux(tonumber(egg.price)) else "Soon"
		Theme.SetButtonColor(buy, if sellable then Theme.Colors.Success else Theme.Colors.Disabled)
		buy.Activated:Connect(function()
			buyProduct(if sellable then id else nil)
		end)
		return
	end

	-- Pick a Creature : le joueur choisit l'espece, puis achat direct (Baby normal)
	local pick = cfg.pick
	local species = type(pick) == "table" and pick.species or nil
	local chosen: string? = nil
	local choiceButtons = {}
	if type(species) == "table" then
		for i, sp in species do
			local info = Store.CreatureInfo(sp)
			local b = Theme.Button({
				Name = sp,
				Size = UDim2.new(1, 0, 0, 36),
				Text = Store.CreatureName(sp),
				TextSize = Theme.TextSize.Small,
				Color = Theme.Colors.PanelLight,
				LayoutOrder = i,
				Parent = list,
			})
			b.ZIndex = 2
			choiceButtons[sp] = b
			b.Activated:Connect(function()
				chosen = sp
				for other, ob in choiceButtons do
					Theme.SetButtonColor(ob, if other == sp then Theme.RarityColor(info and info.rarity) else Theme.Colors.PanelLight)
				end
			end)
		end
	end
	local id = type(pick) == "table" and tonumber(pick.id) or nil
	local sellable = id ~= nil and id > 0 and Store.HasRemote("PickCreature")
	local label = buy:FindFirstChild("Label") :: TextLabel
	label.Text = if sellable then robux(tonumber(pick.price)) else "Soon"
	Theme.SetButtonColor(buy, if sellable then Theme.Colors.Success else Theme.Colors.Disabled)
	buy.Activated:Connect(function()
		if not sellable then
			buyProduct(nil)
			return
		end
		if not chosen then
			Theme.Shake(buy)
			Notifications.Push({ text = "Pick a creature first!", color = Theme.Colors.Sunset, icon = "🐾", key = "shop" })
			return
		end
		local callOk, ok = Store.Invoke("PickCreature", chosen)
		if callOk and ok == true then
			buyProduct(id)
		else
			Notifications.Push({ text = "Can't buy right now.", color = Theme.Colors.Danger, icon = "✖️", key = "shop" })
		end
	end)
end

local function buildCards()
	local state = Store.Get()
	local restricted = state.policy.paidRandomRestricted
	local key = if restricted then "pick" else "egg"
	if builtFor == key then
		return
	end
	builtFor = key
	for _, child in cardsFrame:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	randomCard(restricted)
	for i, def in DEFAULT_PASSES do
		passCard(def, i)
	end
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
	scale.Scale = 0.9
	Util.Tween(panel, OPEN_TIME, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	Util.Tween(scale, OPEN_TIME, { Scale = 1 }, Enum.EasingStyle.Back)
	local cam = workspace.CurrentCamera
	if cam then
		blur = blur or Instance.new("BlurEffect")
		local b = blur :: BlurEffect
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
	Util.Tween(panel, 0.18, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
	Util.Tween(scale, 0.18, { Scale = 0.94 }, Enum.EasingStyle.Quad)
	if blur then
		Util.Tween(blur, 0.18, { Size = 0 }, Enum.EasingStyle.Quad)
	end
	task.delay(0.2, function()
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
		BackgroundTransparency = 0.55,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		ZIndex = 20,
		Parent = parent,
	})
	-- clic sur le fond = fermer
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
		Position = UDim2.fromOffset(6, 6),
		Size = UDim2.new(1, -12, 1, -12),
		Accent = Theme.Colors.Gold,
		Parent = panel,
	})
	Theme.Text({
		Name = "Title",
		Position = UDim2.fromOffset(20, 10),
		Size = UDim2.new(1, -80, 0, 40),
		Text = "SHOP",
		TextSize = Theme.TextSize.Huge,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = plate,
	})
	local close = Theme.Button({
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(44, 44),
		Text = "✕",
		Color = Theme.Colors.Danger,
		Parent = plate,
	})
	close.ZIndex = 3
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
	Theme.Text({
		Name = "Note",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -70, 0, 18),
		Size = UDim2.fromOffset(300, 24),
		Text = "Everything here is optional.",
		TextSize = Theme.TextSize.Small,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = plate,
	})
end

---------------------------------------------------------------- Demarrage
function Shop.Init(ctx)
	Util, Theme, Components, Hud = ctx.Util, ctx.Theme, ctx.Components, ctx.Hud
	Notifications, Config, Sfx = ctx.Notifications, ctx.Config, ctx.Sfx
	build(ctx.Root)
	Hud.SetAction("shop", { icon = "🛒", label = "Shop", color = Theme.Colors.Gold, order = 3, hotkey = "B", visible = false })
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
		-- la politique a change pendant que le panneau est ouvert : on reconstruit
		if isOpen then
			buildCards()
		end
	end
	Store.Changed:Connect(refresh)
	refresh(Store.Get())
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(who, id, purchased)
		if who == player and purchased then
			owned[id] = true
			builtFor = nil
			if isOpen then
				buildCards()
			end
			Sfx.Play("purchase")
		end
	end)
end

return Shop
