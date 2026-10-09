-- Notifications : toasts empiles a droite (3 max, 2,5 s, priorite vague > recompenses > infos)
-- et recompense au centre ("+1.25K"). Branche sur Store.Notified (data.text du serveur).
-- Style console (DIRECTION_V2) : plaque sombre, trait de couleur, icone dessinee, aucun emoji.
-- Les messages du vol, de la Maree Royale et des achats sont geres par StealHud, RoyalHud et Shop.
local Notifications = {}

local MAX_VISIBLE = 3
local DEFAULT_DURATION = 2.5
local TOAST_WIDTH = 300
local TOAST_HEIGHT = 48
local TOAST_HEIGHT_2LINES = 66
local GAP = 8
local STACK_TOP = 70 -- px de design sous le haut de l'ecran
local STACK_RIGHT = 12
local REWARD_TIME = 1.8
local PRIORITY = { wave = 3, reward = 2, info = 1 }

-- Style de chaque message serveur (contrat v2.1) ; un kind absent d'ici est ignore
local KIND_STYLE = {
	welcome = { priority = "info", color = "Lagoon", icon = "info", duration = 4 },
	info = { priority = "info", color = "Lagoon", icon = "info" },
	saveOff = { priority = "wave", color = "Danger", icon = "alert", duration = 8, key = "saveOff" },
	bagFull = { priority = "info", color = "Warning", icon = "alert", key = "bagFull" },
	caught = { priority = "wave", color = "Danger", icon = "wave", duration = 4 },
	survived = { priority = "wave", color = "Success", icon = "shield", key = "survived" },
	bagLost = { priority = "wave", color = "Danger", icon = "wave" },
	deposit = { priority = "reward", color = "Lagoon", icon = "dot", key = "deposit" },
	released = { priority = "reward", color = "Gold", icon = "coin", key = "released" },
	grown = { priority = "reward", color = "Success", icon = "ride", key = "grown" },
	codex = { priority = "reward", color = "Gold", icon = "spark", key = "codex" },
	offline = { priority = "reward", color = "Gold", icon = "clock", duration = 5 },
	upgrade = { priority = "reward", color = "Success", icon = "ride" },
	hatch = { priority = "reward", color = "Warning", icon = "spark" },
	error = { priority = "info", color = "Danger", icon = "close" },
}

local Util, Theme, Config, Store, Hud
local held = {} -- messages recus pendant que le HUD est cache (intro) : rejoues a son apparition
local HELD_MAX = 4
local container: Frame
local stack: Frame
local visible = {} -- toasts affiches, le plus recent en premier
local queue = {} -- en attente (tries par priorite a l'affichage)
local rewardLabel: TextLabel
local rewardSub: TextLabel
local rewardFrame: CanvasGroup
local rewardToken = 0

---------------------------------------------------------------- Toasts
local function measureHeight(text: string): number
	-- estimation : ~0,52 em par caractere en Builder Sans 17
	local charsPerLine = math.floor((TOAST_WIDTH - 70) / (Theme.TextSize.Small * 0.52))
	return if #text > charsPerLine then TOAST_HEIGHT_2LINES else TOAST_HEIGHT
end

local function reflow()
	local y = 0
	for _, toast in visible do
		Util.Tween(toast.frame, Theme.Time.Fast, { Position = UDim2.new(1, 0, 0, y) }, Enum.EasingStyle.Quart)
		y += toast.height + GAP
	end
end

-- CanvasGroup (fondu d'un bloc) > panneau verre en retrait de 2 px (le contour n'est pas rogne)
local function buildToast(opts)
	local color = opts.color or Theme.Colors.Lagoon
	local height = measureHeight(opts.text)
	local group = Theme.Create("CanvasGroup", {
		Name = "Toast",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(TOAST_WIDTH, height),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
	})
	Theme.Plate({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
		Strong = true,
		Parent = group,
	})
	-- trait de couleur a gauche : la categorie du message
	Theme.Create("Frame", {
		Name = "Accent",
		Position = UDim2.fromOffset(1, 6),
		Size = UDim2.new(0, 3, 1, -12),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = group,
	})
	local icon: GuiObject
	if opts.rarity then
		icon = Theme.RarityBadge(opts.rarity, 24)
	else
		icon = Theme.Icon(opts.icon, 22, color)
	end
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 14, 0.5, 0)
	icon.Parent = group
	Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(48, 0),
		Size = UDim2.new(1, -58, 1, 0),
		Text = opts.text,
		TextSize = Theme.TextSize.Small,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = group,
	})
	local hit = Theme.Create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		ZIndex = 5,
		Parent = group,
	})
	return group, hit, height
end

local dismiss -- declaree plus bas (mutuellement recursive avec show)

local function armTimer(toast)
	toast.token += 1
	local token = toast.token
	task.delay(toast.duration, function()
		if toast.token == token then
			dismiss(toast)
		end
	end)
end

local function show(toast)
	local frame, hit, height = buildToast(toast)
	toast.frame, toast.height = frame, height
	frame.Position = UDim2.new(1, 40, 0, 0)
	frame.Parent = stack
	table.insert(visible, 1, toast)
	hit.Activated:Connect(function()
		dismiss(toast)
	end)
	Util.Tween(frame, Theme.Time.Fast, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	reflow()
	armTimer(toast)
end

-- Toast visible de plus basse priorite (le plus ancien a egalite)
local function weakestVisible()
	local weakest, index = nil, nil
	for i = #visible, 1, -1 do
		local t = visible[i]
		if not weakest or t.rank < weakest.rank then
			weakest, index = t, i
		end
	end
	return weakest, index
end

local function popQueue()
	if #queue == 0 or #visible >= MAX_VISIBLE then
		return
	end
	local bestIndex = 1
	for i, t in queue do
		if t.rank > queue[bestIndex].rank then
			bestIndex = i
		end
	end
	show(table.remove(queue, bestIndex))
end

function dismiss(toast)
	local i = table.find(visible, toast)
	if not i then
		return
	end
	table.remove(visible, i)
	toast.token += 1
	local frame = toast.frame
	Util.Tween(frame, Theme.Time.Fast, { GroupTransparency = 1, Position = frame.Position + UDim2.fromOffset(24, 0) }, Enum.EasingStyle.Quad)
	task.delay(Theme.Time.Fast + 0.02, function()
		frame:Destroy()
	end)
	reflow()
	popQueue()
end

local function findByKey(list, key: string?)
	if not key then
		return nil
	end
	for _, t in list do
		if t.key == key then
			return t
		end
	end
	return nil
end

-- opts : {text, color?, icon?, rarity?, duration?, key?, priority? "wave"|"reward"|"info"}
function Notifications.Push(opts: { [string]: any })
	if type(opts) ~= "table" or type(opts.text) ~= "string" or opts.text == "" then
		return
	end
	-- deja en attente : on met a jour le texte au lieu d'empiler un doublon
	local queued = findByKey(queue, opts.key)
	if queued then
		queued.text = opts.text
		return
	end
	local same = findByKey(visible, opts.key)
	if same then
		local label = same.frame:FindFirstChild("Text") :: TextLabel?
		if label then
			label.Text = opts.text
		end
		Theme.Pop(same.frame, 0.04)
		armTimer(same)
		return
	end
	local toast = {
		text = opts.text,
		color = opts.color,
		icon = opts.icon,
		rarity = opts.rarity,
		key = opts.key,
		duration = opts.duration or DEFAULT_DURATION,
		rank = PRIORITY[opts.priority or "info"] or 1,
		token = 0,
	}
	if #visible < MAX_VISIBLE then
		show(toast)
		return
	end
	-- pile pleine : un message plus important chasse le plus faible, sinon il attend
	local weakest = weakestVisible()
	if weakest and toast.rank > weakest.rank then
		table.insert(queue, toast)
		dismiss(weakest)
	else
		table.insert(queue, toast)
	end
end

---------------------------------------------------------------- Recompense au centre
-- opts : {text = "+1.25K", sub = "Coins", color?} ; un nouvel appel remplace l'affichage en cours
function Notifications.Reward(opts: { [string]: any })
	if type(opts) ~= "table" or type(opts.text) ~= "string" then
		return
	end
	rewardToken += 1
	local token = rewardToken
	rewardLabel.Text = opts.text
	rewardLabel.TextColor3 = opts.color or Theme.Colors.Gold
	rewardSub.Text = Theme.Caps(opts.sub or "")
	rewardFrame.Visible = true
	local scale = Theme.GetScale(rewardFrame)
	scale.Scale = 0.85
	rewardFrame.GroupTransparency = 1
	Util.Tween(scale, Theme.Time.Normal, { Scale = 1 }, Enum.EasingStyle.Quart)
	Util.Tween(rewardFrame, 0.15, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	task.delay(REWARD_TIME, function()
		if rewardToken ~= token then
			return
		end
		Util.Tween(rewardFrame, 0.25, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		Util.Tween(scale, 0.25, { Scale = 0.9 }, Enum.EasingStyle.Quad)
		task.delay(0.26, function()
			if rewardToken == token then
				rewardFrame.Visible = false
			end
		end)
	end)
end

local function buildReward(parent: Instance)
	rewardFrame = Theme.Create("CanvasGroup", {
		Name = "Reward",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(360, 110),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		Parent = parent,
	})
	rewardLabel = Theme.Text({
		Name = "Amount",
		Size = UDim2.new(1, 0, 0, 64),
		TextSize = Theme.TextSize.Giant,
		FontFace = Theme.Fonts.Title,
		Parent = rewardFrame,
	})
	rewardSub = Theme.Text({
		Name = "Sub",
		Position = UDim2.fromOffset(0, 62),
		Size = UDim2.new(1, 0, 0, 30),
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		Parent = rewardFrame,
	})
end

---------------------------------------------------------------- Branchement serveur
local function onNotify(kind: string, data: { [string]: any })
	local style = KIND_STYLE[kind]
	if kind == "capture" then
		-- seule une nouvelle case du Codex merite un toast (le reste = retours visuels)
		if data.isNew and type(data.species) == "string" then
			local info = Store.CreatureInfo(data.species)
			local rarityKey = if type(data.rarity) == "string" then data.rarity else info and info.rarity
			-- rarete = couleur + lettre + nom (bible §5 accessibilite) ; mutation nommee aussi
			local rarity = rarityKey and Config.Rarities[rarityKey]
			local mutation = if type(data.mutation) == "string" and data.mutation ~= "" then data.mutation .. " " else ""
			local rarityName = if rarity then "  ·  " .. string.upper(rarity.label) else ""
			Notifications.Push({
				text = "NEW  " .. mutation .. Store.CreatureName(data.species) .. rarityName,
				rarity = rarityKey,
				color = Theme.RarityColor(rarityKey),
				priority = "reward",
				key = "new:" .. data.species .. ":" .. mutation,
			})
		end
		return
	end
	if kind == "welcome" and data.isNew then
		return -- nouveau joueur : aucun texte pendant les 30 premieres secondes (GDD §1 ter)
	end
	if kind == "offline" and tonumber(data.coins) and tonumber(data.coins) > 0 then
		Notifications.Reward({ text = "+" .. Config.Format(tonumber(data.coins)), sub = "While you were away" })
	end
	if not style or type(data.text) ~= "string" then
		return
	end
	local key = style.key
	if kind == "error" then
		key = "err:" .. tostring(data.code)
	end
	Notifications.Push({
		text = data.text,
		color = Theme.Colors[style.color],
		icon = style.icon,
		duration = style.duration,
		priority = style.priority,
		key = key,
	})
end

function Notifications.Init(ctx)
	Util = ctx.Util
	Theme = ctx.Theme
	Config = ctx.Config
	container = Theme.Create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 5,
		Parent = ctx.Root,
	})
	stack = Theme.Create("Frame", {
		Name = "Stack",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -STACK_RIGHT, 0, STACK_TOP),
		Size = UDim2.fromOffset(TOAST_WIDTH, (TOAST_HEIGHT_2LINES + GAP) * MAX_VISIBLE),
		Parent = container,
	})
	buildReward(container)
end

function Notifications.Start(ctx)
	Store = ctx.Store
	Hud = ctx.Hud
	Store.Notified:Connect(function(kind, data)
		-- HUD cache (intro, descente camera) : on garde les derniers messages pour son apparition
		if Hud and not Hud.IsVisible() and kind ~= "saveOff" then
			table.insert(held, { kind, data })
			if #held > HELD_MAX then
				table.remove(held, 1)
			end
			return
		end
		onNotify(kind, data)
	end)
	if Hud and Hud.Shown then
		Hud.Shown:Connect(function()
			local pending = held
			held = {}
			for i, msg in pending do
				task.delay(0.6 + i * 0.35, onNotify, msg[1], msg[2])
			end
		end)
	end
end

return Notifications
