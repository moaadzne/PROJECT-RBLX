-- NameTags : etiquette maison au-dessus des autres joueurs (VISION_TON §6.1 ; A met DisplayDistanceType = None).
-- Nom, couronne de la Maree Royale (attribut Crown 1..3), VIP, bouclier debutant (Newbie), et en rouge la
-- creature volee portee (Carrying "Espece:Mutation") : le voleur se repere de loin. Pas d'etiquette sur soi.
local Players = game:GetService("Players")

local NameTags = {}

local MAX_DISTANCE = 90
local MEDALS = { Color3.fromRGB(240, 190, 70), Color3.fromRGB(200, 208, 220), Color3.fromRGB(200, 130, 75) }

local Theme, Store
local localPlayer = Players.LocalPlayer
local playerGui: Instance
local tags: { [Player]: any } = {}

local function carryingText(value: any): string?
	if type(value) ~= "string" or value == "" then
		return nil
	end
	local species, mutation = value:match("^([^:]*):?(.*)$")
	local name = string.upper(Store.CreatureName(species or value))
	if mutation and mutation ~= "" then
		name = string.upper(mutation) .. " " .. name
	end
	return name
end

local function refresh(p: Player)
	local rec = tags[p]
	if not rec then
		return
	end
	local crown = tonumber(p:GetAttribute("Crown")) or 0
	local carrying = carryingText(p:GetAttribute("Carrying"))
	rec.name.Text = p.DisplayName
	-- ligne du haut : couronne, VIP, bouclier
	rec.crown.Visible = crown >= 1 and crown <= 3
	if rec.crown.Visible then
		local color = MEDALS[crown]
		Theme.SetIconColor(rec.crownIcon, color)
		rec.crownText.Text = "#" .. crown
		rec.crownText.TextColor3 = color
	end
	rec.vip.Visible = p:GetAttribute("VIP") == true
	rec.shield.Visible = p:GetAttribute("Newbie") == true
	-- voleur : plaque rouge sous le nom
	rec.thief.Visible = carrying ~= nil
	if carrying then
		rec.thiefText.Text = "THIEF  ·  " .. carrying
	end
end

local function build(p: Player, head: BasePart)
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_NameTag_" .. p.UserId,
		Size = UDim2.fromOffset(220, 74),
		StudsOffsetWorldSpace = Vector3.new(0, 2.4, 0),
		MaxDistance = MAX_DISTANCE,
		LightInfluence = 0,
		AlwaysOnTop = false,
		ResetOnSpawn = false,
		Adornee = head,
	})
	-- ligne du haut : pastilles centrees
	local row = Theme.Create("Frame", {
		Name = "Badges",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 22),
		Parent = gui,
	})
	Theme.List(row, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local crown = Theme.Plate({ Name = "Crown", Size = UDim2.fromOffset(52, 22), Strong = true, Parent = row })
	crown.LayoutOrder = 1
	local crownIcon = Theme.Icon("crown", 14, MEDALS[1])
	crownIcon.AnchorPoint = Vector2.new(0, 0.5)
	crownIcon.Position = UDim2.new(0, 6, 0.5, 0)
	crownIcon.Parent = crown
	local crownText = Theme.Text({
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -24, 1, 0),
		TextSize = 15,
		FontFace = Theme.Fonts.Number,
		Parent = crown,
	})
	local vip = Theme.Plate({ Name = "VIP", Size = UDim2.fromOffset(36, 22), Strong = true, Parent = row })
	vip.LayoutOrder = 2
	Theme.Text({ Size = UDim2.fromScale(1, 1), Text = "VIP", TextSize = 14, FontFace = Theme.Fonts.Title, TextColor3 = Theme.Colors.Gold, Parent = vip })
	local shield = Theme.Plate({ Name = "Shield", Size = UDim2.fromOffset(26, 22), Strong = true, Parent = row })
	shield.LayoutOrder = 3
	local shieldIcon = Theme.Icon("shield", 14, Theme.Colors.Lagoon)
	shieldIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	shieldIcon.Position = UDim2.fromScale(0.5, 0.5)
	shieldIcon.Parent = shield
	-- nom
	local name = Theme.Text({
		Name = "Name",
		Position = UDim2.fromOffset(0, 22),
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 18,
		FontFace = Theme.Fonts.Bold,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = gui,
	})
	-- voleur
	local thief = Theme.Plate({
		Name = "Thief",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 48),
		Size = UDim2.fromOffset(200, 24),
		Strong = true,
		Accent = Theme.Colors.Danger,
		Parent = gui,
	})
	thief.BackgroundColor3 = Theme.Colors.Danger:Lerp(Theme.Colors.Black, 0.5)
	local thiefText = Theme.Text({
		Size = UDim2.fromScale(1, 1),
		TextSize = 14,
		FontFace = Theme.Fonts.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = thief,
	})
	gui.Parent = playerGui
	local old = tags[p]
	if old then
		old.gui:Destroy()
	end
	tags[p] = {
		gui = gui,
		name = name,
		crown = crown,
		crownIcon = crownIcon,
		crownText = crownText,
		vip = vip,
		shield = shield,
		thief = thief,
		thiefText = thiefText,
	}
	refresh(p)
end

local function track(p: Player)
	if p == localPlayer then
		return
	end
	local function onCharacter(character: Model)
		local head = character:WaitForChild("Head", 10)
		if head and head:IsA("BasePart") and p.Parent then
			build(p, head)
		end
	end
	if p.Character then
		task.spawn(onCharacter, p.Character)
	end
	p.CharacterAdded:Connect(onCharacter)
	p.AttributeChanged:Connect(function(attr)
		if attr == "Crown" or attr == "VIP" or attr == "Newbie" or attr == "Carrying" then
			refresh(p)
		end
	end)
	p:GetPropertyChangedSignal("DisplayName"):Connect(function()
		refresh(p)
	end)
end

function NameTags.Init(ctx)
	Theme = ctx.Theme
	playerGui = localPlayer:WaitForChild("PlayerGui")
end

function NameTags.Start(ctx)
	Store = ctx.Store
	for _, p in Players:GetPlayers() do
		track(p)
	end
	Players.PlayerAdded:Connect(track)
	Players.PlayerRemoving:Connect(function(p)
		local rec = tags[p]
		if rec then
			rec.gui:Destroy()
			tags[p] = nil
		end
	end)
end

return NameTags
