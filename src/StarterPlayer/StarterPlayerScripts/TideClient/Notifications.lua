-- Notifications : toasts empiles a droite (3 max, 2,5 s, priorite vague > recompenses > infos)
-- et toast de recompense au centre ("+1.25K"). Branche sur Store.Notified (data.text du serveur).
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

-- Style de chaque message serveur (contrat v1) ; un kind inconnu est ignore
local KIND_STYLE = {
	welcome = { priority = "info", color = "Lagoon", icon = "🌴", duration = 4 },
	info = { priority = "info", color = "Lagoon", icon = "ℹ️" },
	saveOff = { priority = "wave", color = "Danger", icon = "⚠️", duration = 8, key = "saveOff" },
	bagFull = { priority = "info", color = "Sunset", icon = "🎒", key = "bagFull" },
	caught = { priority = "wave", color = "Danger", icon = "🌊", duration = 4 },
	survived = { priority = "wave", color = "Success", icon = "🏆", key = "survived" },
	bagLost = { priority = "wave", color = "Coral", icon = "💧" },
	deposit = { priority = "reward", color = "Lagoon", icon = "🏝️", key = "deposit" },
	sold = { priority = "reward", color = "Gold", icon = "💰", key = "sold" },
	upgrade = { priority = "reward", color = "Success", icon = "⬆️" },
	hatch = { priority = "reward", color = "Sunset", icon = "🥚" },
	error = { priority = "info", color = "Danger", icon = "✖️" },
}

local Util, Theme, Config
local container: Frame
local stack: Frame
local visible = {} -- toasts affiches, le plus recent en premier
local queue = {} -- en attente (tries par priorite a l'affichage)
local rewardLabel: TextLabel
local rewardSub: TextLabel
local rewardFrame: Frame
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
		Util.Tween(toast.frame, 0.25, { Position = UDim2.new(1, 0, 0, y) }, Enum.EasingStyle.Quad)
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
	local panel = Theme.Create("Frame", {
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -4, 1, -4),
		BackgroundColor3 = Theme.Colors.White,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Parent = group,
	})
	Theme.Corner(panel, 14)
	Theme.Gradient(panel, Theme.Colors.PanelLight, Theme.Colors.Night, 90)
	Theme.Stroke(panel, Theme.Colors.White, 0.72, 1.5)
	local accent = Theme.Create("Frame", {
		Name = "Accent",
		Position = UDim2.fromOffset(6, 8),
		Size = UDim2.new(0, 5, 1, -16),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Parent = group,
	})
	Theme.Round(accent)
	local icon: GuiObject
	if opts.rarity then
		icon = Theme.RarityBadge(opts.rarity, 30)
	else
		icon = Theme.Create("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(30, 30),
			Text = opts.icon or "•",
			TextScaled = true,
			FontFace = Theme.Fonts.Bold,
			TextColor3 = color,
		})
	end
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 16, 0.5, 0)
	icon.Parent = group
	Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(56, 0),
		Size = UDim2.new(1, -66, 1, 0),
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
	Util.Tween(frame, 0.3, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
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
	Util.Tween(frame, 0.2, { GroupTransparency = 1, Position = frame.Position + UDim2.fromOffset(30, 0) }, Enum.EasingStyle.Quad)
	task.delay(0.22, function()
		frame:Destroy()
	end)
	reflow()
	popQueue()
end

local function findByKey(key: string?)
	if not key then
		return nil
	end
	for _, t in visible do
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
	local same = findByKey(opts.key)
	if same then
		local label = same.frame:FindFirstChild("Text") :: TextLabel?
		if label then
			label.Text = opts.text
		end
		Theme.Pop(same.frame, 0.06)
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
	rewardSub.Text = opts.sub or ""
	rewardFrame.Visible = true
	local scale = Theme.GetScale(rewardFrame)
	scale.Scale = 0.6
	rewardFrame.GroupTransparency = 1
	Util.Tween(scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
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
	Theme.TextStroke(rewardLabel, 0.2, 3)
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
	if kind == "pickup" then
		-- seul un tresor jamais vu merite un toast (le reste = retours visuels)
		local item = Config.Items[data.itemId]
		if data.isNew and item then
			Notifications.Push({
				text = "New treasure: " .. item.name .. "!",
				rarity = item.rarity,
				color = Theme.RarityColor(item.rarity),
				priority = "reward",
				key = "new:" .. tostring(data.itemId),
			})
		end
		return
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
	ctx.Store.Notified:Connect(onNotify)
end

return Notifications
