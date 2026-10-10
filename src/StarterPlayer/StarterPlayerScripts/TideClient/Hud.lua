-- Hud : HUD « jeu console » (DIRECTION_V2). Porte-monnaie (pieces + revenu), bandeau de marée (type,
-- compte a rebours, prochaine marée speciale), alerte, colonne d'etats, boutons d'action (verrou,
-- monture, boutique), classement de la Marée Royale. Aucun emoji : icones de Theme.Icon.
-- Cache tant que l'etat n'est pas charge ; Onboarding peut le retenir jusqu'a la fin de la 1re vague.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Hud = {}

local FADE_TIME = 0.25
local TICK = 0.1 -- rafraichissement du minuteur et de la barre (s)
local SIREN_AT = 3 -- s avant la vague : corne de brume + pulsation rouge
local PULSE_HZ = 1.5 -- sous la limite de 3 clignotements par seconde (bible §5)
local BIG_GAIN = 0.05 -- un gain > 5 % des pieces fait rebondir la piece
local ALERT_TIME = 4
local LEADERBOARD_ROWS = 3 -- top 3 de la Maree Royale (+ ma ligne si je suis plus bas)
local MEDALS = { Color3.fromRGB(240, 190, 70), Color3.fromRGB(200, 208, 220), Color3.fromRGB(200, 130, 75) }
local HOLD_MAX = 150 -- s : meme retenu par l'onboarding, le HUD finit par apparaitre

-- Textes d'action courts (DIRECTION_V2) ; l'alerte et la vague = fenetre de vol : les lagons sont ouverts
local PHASE_TEXT = {
	calm = "Wave in",
	warning = "Lagoons open",
	wave = "Survive",
	recede = "Lagoons closing",
}

local Util, Theme, Components, Store, Fx, Sfx, Config, Settings
local hudRoot: Frame
local fadeGroups: { CanvasGroup } = {}
local held = false
local shown = false
local fadeToken = 0

-- porte-monnaie
local coinIcon: GuiObject
local coinCounter
local incomeLabel: TextLabel
local lastCoins: number? = nil

-- marée
local tidePlate: Frame
local tideStroke: UIStroke
local tideAccent: Frame
local tideIcon: GuiObject? = nil
local tideName: TextLabel
local phaseLabel: TextLabel
local timerLabel: TextLabel
local tideBar
local specialChip: Frame
local specialText: TextLabel
local shownSecond = -1
local sirenCycle = -1

-- places reservees
local alertGroup: CanvasGroup
local alertText: TextLabel
local alertIcon: GuiObject? = nil
local alertPlate: Frame
local alertToken = 0
local actionBar: Frame
local actions: { [string]: any } = {}
local boardGroup: CanvasGroup
local boardTitle: TextLabel
local boardRows: { Frame } = {}
local leftColumn: Frame
local statuses: { [string]: Frame } = {}
local setTideIcon, setAlertIcon

---------------------------------------------------------------- Construction
local function canvas(props: { [string]: any }): CanvasGroup
	local group = Theme.Create("CanvasGroup", {
		Name = props.Name,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		Position = props.Position,
		Size = props.Size,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = props.Visible ~= false,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent or hudRoot,
	})
	return group
end

-- Icones dessinees : on remplace l'instance (une icone n'est pas un texte)
function setTideIcon(name: string, color: Color3)
	if tideIcon then
		tideIcon:Destroy()
	end
	local icon = Theme.Icon(name, 28, color)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 14, 0.5, 0)
	icon.ZIndex = 3
	icon.Parent = tidePlate
	tideIcon = icon
end

function setAlertIcon(name: string)
	if alertIcon then
		alertIcon:Destroy()
	end
	local icon = Theme.Icon(name, 30, Theme.Colors.Text)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 12, 0.5, 0)
	icon.ZIndex = 3
	icon.Parent = alertPlate
	alertIcon = icon
end

-- Colonne gauche sous le porte-monnaie : pastilles d'etat (bouclier, revanche...) puis classement
local function buildLeftColumn()
	leftColumn = Theme.Create("Frame", {
		Name = "LeftColumn",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 172),
		Size = UDim2.fromOffset(240, 260),
		Parent = hudRoot,
	})
	Theme.List(leftColumn, Enum.FillDirection.Vertical, 6)
end

local function buildWallet()
	local group = canvas({ Name = "Wallet", Position = UDim2.fromOffset(12, 66), Size = UDim2.fromOffset(240, 100) })
	table.insert(fadeGroups, group)
	local plate = Theme.Plate({
		Name = "CoinsPlate",
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.fromOffset(212, 52),
		Parent = group,
	})
	coinIcon = Theme.CoinIcon(28)
	coinIcon.AnchorPoint = Vector2.new(0, 0.5)
	coinIcon.Position = UDim2.new(0, 12, 0.5, 0)
	coinIcon.ZIndex = 3
	coinIcon.Parent = plate
	coinCounter = Components.Counter({
		Name = "Coins",
		Position = UDim2.fromOffset(50, 0),
		Size = UDim2.new(1, -60, 1, 0),
		TextSize = Theme.TextSize.Huge,
		Font = Theme.Fonts.Number,
		Color = Theme.Colors.Text,
		PopOnRise = false,
		ZIndex = 3,
		Parent = plate,
	})
	local incomePlate = Theme.Plate({
		Name = "IncomePlate",
		Position = UDim2.fromOffset(4, 60),
		Size = UDim2.fromOffset(120, 30),
		Parent = group,
	})
	incomeLabel = Theme.Text({
		Name = "Income",
		Size = UDim2.fromScale(1, 1),
		Text = "+0/s",
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Number,
		TextColor3 = Theme.Colors.Gold,
		ZIndex = 2,
		Parent = incomePlate,
	})
end

local function buildTide()
	local group = canvas({
		Name = "Tide",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(330, 120),
	})
	table.insert(fadeGroups, group)
	tidePlate = Theme.Plate({
		Name = "TidePlate",
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.fromOffset(314, 64),
		Accent = Theme.Tides.Normal.color,
		Parent = group,
	})
	tideStroke = tidePlate:FindFirstChildOfClass("UIStroke") :: UIStroke
	tideAccent = tidePlate:FindFirstChild("Accent") :: Frame
	setTideIcon("wave", Theme.Tides.Normal.color)
	tideName = Theme.Text({
		Name = "TideName",
		Position = UDim2.fromOffset(52, 9),
		Size = UDim2.new(1, -160, 0, 26),
		Text = Theme.Caps(Theme.Tides.Normal.label),
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Tides.Normal.color,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = tidePlate,
	})
	phaseLabel = Theme.Text({
		Name = "Phase",
		Position = UDim2.fromOffset(52, 35),
		Size = UDim2.new(1, -160, 0, 22),
		Text = Theme.Caps(PHASE_TEXT.calm),
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = tidePlate,
	})
	timerLabel = Theme.Text({
		Name = "Timer",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 3),
		Size = UDim2.fromOffset(96, 44),
		Text = "",
		TextSize = Theme.TextSize.Huge,
		FontFace = Theme.Fonts.Number,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = tidePlate,
	})
	tideBar = Components.ProgressBar({
		Name = "TideBar",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 74),
		Size = UDim2.fromOffset(296, 4),
		Color = Theme.Tides.Normal.color,
		Parent = group,
	})
	tideBar.Label.Visible = false
	specialChip = Theme.Plate({
		Name = "NextSpecial",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(250, 28),
		Parent = group,
	})
	specialChip.Visible = false
	specialText = Theme.Text({
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		Text = "",
		TextSize = Theme.TextSize.Small,
		FontFace = Theme.Fonts.Title,
		RichText = true,
		ZIndex = 2,
		Parent = specialChip,
	})
end

-- Alerte en haut (vol de creature, etc.) : place reservee, logique au GDD v2
local function buildAlert()
	alertGroup = canvas({
		Name = "Alert",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 128),
		Size = UDim2.fromOffset(440, 64),
		Visible = false,
	})
	local plate = Theme.Plate({
		Name = "AlertPlate",
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 1, -12),
		Accent = Theme.Colors.Danger,
		Parent = alertGroup,
	})
	plate.BackgroundColor3 = Theme.Colors.Danger:Lerp(Theme.Colors.Black, 0.55)
	alertPlate = plate
	setAlertIcon("alert")
	alertText = Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(52, 0),
		Size = UDim2.new(1, -62, 1, 0),
		Text = "",
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = plate,
	})
end

-- Boutons d'action en bas a droite, au-dessus du bouton de saut sur mobile
local function buildActions()
	local touch = UserInputService.TouchEnabled
	actionBar = Theme.Create("Frame", {
		Name = "Actions",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = if touch then UDim2.new(1, -24, 1, -150) else UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(300, 84),
		Parent = hudRoot,
	})
	Theme.List(actionBar, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom)
	Theme.GetScale(actionBar)
end

-- Classement de la Marée Royale : place reservee a gauche, sous le porte-monnaie
local function buildLeaderboard()
	boardGroup = canvas({
		Name = "RoyalTide",
		Parent = leftColumn,
		LayoutOrder = 100,
		-- titre (40) + top 3 + ma ligne (28 chacune) + marges de la plaque (6 + 6) + bas (4)
		Size = UDim2.fromOffset(230, 40 + (LEADERBOARD_ROWS + 1) * 28 + 16),
		Visible = false,
	})
	table.insert(fadeGroups, boardGroup)
	local plate = Theme.Plate({
		Name = "BoardPlate",
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(1, -16, 1, -12),
		Accent = Theme.Colors.Gold,
		Parent = boardGroup,
	})
	local crown = Theme.Icon("crown", 20, Theme.Colors.Gold)
	crown.Position = UDim2.fromOffset(12, 13)
	crown.ZIndex = 3
	crown.Parent = plate
	boardTitle = Theme.Text({
		Name = "Title",
		Position = UDim2.fromOffset(40, 10),
		Size = UDim2.new(1, -52, 0, 26),
		Text = Theme.Caps("Royal Tide"),
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Gold,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = plate,
	})
	for i = 1, LEADERBOARD_ROWS + 1 do
		local row = Theme.Create("Frame", {
			Name = "Row" .. i,
			BackgroundColor3 = Theme.Colors.White,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(8, 40 + (i - 1) * 28),
			Size = UDim2.new(1, -16, 0, 26),
			Visible = false,
			ZIndex = 3,
			Parent = plate,
		})
		Theme.Corner(row, 6)
		Theme.Text({
			Name = "Rank",
			Size = UDim2.new(0, 28, 1, 0),
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Title,
			ZIndex = 4,
			Parent = row,
		})
		Theme.Text({
			Name = "Player",
			Position = UDim2.fromOffset(30, 0),
			Size = UDim2.new(1, -100, 1, 0),
			TextSize = Theme.TextSize.Small,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 4,
			Parent = row,
		})
		Theme.Text({
			Name = "Score",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -6, 0, 0),
			Size = UDim2.new(0, 64, 1, 0),
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Title,
			TextColor3 = Theme.Colors.Gold,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 4,
			Parent = row,
		})
		boardRows[i] = row
	end
end

---------------------------------------------------------------- Mise a jour
local function onState(state, prev)
	if not state.loaded then
		return
	end
	local instant = lastCoins == nil or not shown
	coinCounter:Set(state.coins, instant)
	if lastCoins and state.coins - lastCoins > math.max(10, lastCoins * BIG_GAIN) then
		Theme.Pop(coinIcon, 0.08)
	end
	lastCoins = state.coins
	incomeLabel.Text = "+" .. Config.Format(state.income) .. "/s"
	if prev and state.income > prev.income and prev.loaded then
		Theme.Pop(incomeLabel, 0.06)
	end
end

local function applyTide(wave)
	local style = Theme.TideStyle(wave.tide)
	setTideIcon(style.icon, style.color)
	tideName.Text = Theme.Caps(style.label)
	tideName.TextColor3 = style.color
	tideAccent.BackgroundColor3 = style.color
	tideBar:SetColor(style.color)
	local ns = wave.nextSpecial
	local cycles = if ns and ns.cycle then ns.cycle - wave.cycle else nil
	-- pendant la marée speciale elle-meme, le bandeau suffit
	if ns and cycles and cycles >= 1 and not (wave.tide == ns.tide and wave.tide ~= "Normal") then
		local nsStyle = Theme.TideStyle(ns.tide)
		local hex = nsStyle.color:ToHex()
		local waves = if cycles == 1 then "NEXT WAVE" else ("IN %d WAVES"):format(cycles)
		specialText.Text = ('<font color="#%s">%s</font>  %s'):format(hex, string.upper(nsStyle.label), waves)
		specialChip.Visible = true
	else
		specialChip.Visible = false
	end
end

local function onWave(wave, prev)
	applyTide(wave)
	phaseLabel.Text = Theme.Caps(PHASE_TEXT[wave.phase] or "")
	phaseLabel.TextColor3 = if wave.phase == "warning" or wave.phase == "wave" then Theme.Colors.Danger else Theme.Colors.TextDim
	shownSecond = -1
	if wave.phase == "warning" and (not prev or prev.phase ~= "warning") then
		Theme.Pop(tidePlate, 0.05)
		Sfx.Play("rumble") -- grondement : la vague arrive dans 7 s
	end
	if wave.phase ~= "warning" then
		tideStroke.Color = Theme.Colors.Outline
		Fx.SetEdgeGlow(Theme.Colors.Danger, 0)
	end
end

-- Secondes avant le depart de la vague (calme + alerte) ou avant la fin de la phase
local function timeLeft(wave): number
	if wave.phase == "calm" or wave.phase == "warning" then
		return math.max(0, wave.startTime - Store.Now())
	end
	return Store.WaveTimeLeft()
end

local accum = 0
local function onHeartbeat(dt: number)
	if not shown then
		return
	end
	local wave = Store.GetWave()
	local left = timeLeft(wave)
	-- pulsation d'alerte : chaque frame, mais seulement pendant les dernieres secondes
	if wave.phase == "warning" and left <= SIREN_AT then
		if sirenCycle ~= wave.cycle then
			sirenCycle = wave.cycle
			Sfx.Play("horn") -- corne de brume a -3 s (son de C)
		end
		local pulse = if Settings.Get("reducedMotion") then 0.5 else 0.5 + 0.5 * math.sin(os.clock() * PULSE_HZ * 2 * math.pi)
		tideStroke.Color = Theme.Colors.Outline:Lerp(Theme.Colors.Danger, pulse)
		Fx.SetEdgeGlow(Theme.Colors.Danger, 0.35 + 0.45 * pulse)
	end
	accum += dt
	if accum < TICK then
		return
	end
	accum = 0
	local second = math.ceil(left)
	if second ~= shownSecond then
		shownSecond = second
		timerLabel.Text = if wave.phase == "recede" then "" else Util.FormatTime(left)
		timerLabel.TextColor3 = if wave.phase == "warning" or wave.phase == "wave" then Theme.Colors.Danger else Theme.Colors.Text
	end
	if wave.phase == "calm" or wave.phase == "warning" then
		local cfg = Config.Wave
		local total = cfg.calmTime + cfg.warningTime
		tideBar:Set(1 - left / total, false)
	else
		tideBar:Set(1 - Store.WaveProgress(), false)
	end
end

---------------------------------------------------------------- API
-- Affiche ou cache tout le HUD (fondu de 0,5 s si animate)
function Hud.SetVisible(visible: boolean, animate: boolean?)
	if visible == shown then
		return
	end
	shown = visible
	fadeToken += 1
	local token = fadeToken
	local scale = Theme.GetScale(actionBar)
	if visible then
		hudRoot.Visible = true
		Hud.Shown:Fire()
		shownSecond = -1
		for _, group in fadeGroups do
			if animate then
				group.GroupTransparency = 1
				Util.Tween(group, FADE_TIME, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
			else
				group.GroupTransparency = 0
			end
		end
		if animate then
			scale.Scale = 0.6
			Util.Tween(scale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
		end
	else
		Fx.SetEdgeGlow(Theme.Colors.Danger, 0)
		if not animate then
			hudRoot.Visible = false
			return
		end
		for _, group in fadeGroups do
			Util.Tween(group, FADE_TIME * 0.6, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
		end
		task.delay(FADE_TIME * 0.6, function()
			if fadeToken == token then
				hudRoot.Visible = false
			end
		end)
	end
end

function Hud.IsVisible(): boolean
	return shown
end

-- Onboarding : empeche l'apparition automatique au chargement (a appeler dans Init)
function Hud.Hold()
	held = true
end

-- Alerte en haut de l'ecran. opts : icon (nom Theme.Icon), color (fond), duration (s)
function Hud.ShowAlert(text: string, opts: { icon: string?, color: Color3?, duration: number? }?)
	local o = opts or {}
	alertToken += 1
	local token = alertToken
	alertText.Text = string.upper(text)
	setAlertIcon(o.icon or "alert")
	alertPlate.BackgroundColor3 = (o.color or Theme.Colors.Danger):Lerp(Theme.Colors.Black, 0.55)
	local accent = alertPlate:FindFirstChild("Accent") :: Frame?
	if accent then
		accent.BackgroundColor3 = o.color or Theme.Colors.Danger
	end
	alertGroup.Visible = true
	alertGroup.GroupTransparency = 1
	Util.Tween(alertGroup, Theme.Time.Fast, { GroupTransparency = 0 }, Enum.EasingStyle.Quad)
	Theme.Pop(alertGroup, 0.05)
	Theme.Shake(alertGroup)
	task.delay(o.duration or ALERT_TIME, function()
		if alertToken == token then
			Hud.HideAlert()
		end
	end)
end

function Hud.HideAlert()
	alertToken += 1
	local token = alertToken
	Util.Tween(alertGroup, Theme.Time.Normal, { GroupTransparency = 1 }, Enum.EasingStyle.Quad)
	task.delay(Theme.Time.Normal + 0.02, function()
		if alertToken == token then
			alertGroup.Visible = false
		end
	end)
end

-- Bouton d'action (cree au premier appel). id : "mount", "lock"...
-- opts : visible, icon (nom Theme.Icon), label, color (accent), enabled, order, hotkey, onActivated (fonction)
function Hud.SetAction(id: string, opts: { [string]: any })
	local action = actions[id]
	if not action then
		action = Components.IconButton({
			Name = id,
			Icon = opts.icon or "dot",
			Label = opts.label or id,
			Color = opts.color,
			Hotkey = opts.hotkey,
			Size = 62,
			LayoutOrder = opts.order or 0,
			Parent = actionBar,
		})
		action.Instance.Visible = false
		local function activate()
			if not action.Enabled then
				Theme.Shake(action.Button)
				return
			end
			if action.OnActivated then
				task.spawn(action.OnActivated)
			end
		end
		action.Button.Activated:Connect(activate)
		-- raccourci clavier affiche par la KeyHint
		local keyCode = opts.hotkey and (Enum.KeyCode :: any)[opts.hotkey]
		if keyCode then
			UserInputService.InputBegan:Connect(function(input, processed)
				if not processed and input.KeyCode == keyCode and shown and action.Instance.Visible then
					Theme.Pop(action.Button, 0.05)
					activate()
				end
			end)
		end
		actions[id] = action
	end
	if opts.icon then
		action:SetIcon(opts.icon)
	end
	if opts.label then
		action:SetLabel(opts.label)
	end
	if opts.color then
		action:SetAccent(opts.color)
	end
	if opts.enabled ~= nil then
		action:SetEnabled(opts.enabled)
	end
	if opts.onActivated then
		action.OnActivated = opts.onActivated
	end
	if opts.visible ~= nil and action.Instance.Visible ~= opts.visible then
		action.Instance.Visible = opts.visible
		if opts.visible then
			Theme.Pop(action.Button, 0.06)
		end
	end
	return action
end

-- Pastille d'etat dans la colonne gauche (bouclier debutant, revanche...). opts = nil pour l'enlever.
-- opts : icon (nom Theme.Icon), text, color (couleur du texte et du trait), order
function Hud.SetStatus(id: string, opts: { icon: string?, text: string, color: Color3?, order: number? }?)
	local chip = statuses[id]
	if not opts then
		if chip then
			chip:Destroy()
			statuses[id] = nil
		end
		return
	end
	local color = opts.color or Theme.Colors.Text
	if not chip then
		chip = Theme.Plate({
			Name = "Status_" .. id,
			Size = UDim2.fromOffset(220, 32),
			Accent = color,
		})
		chip.LayoutOrder = opts.order or 10
		Theme.Text({
			Name = "Text",
			Position = UDim2.fromOffset(34, 2),
			Size = UDim2.new(1, -42, 1, -2),
			TextSize = Theme.TextSize.Small,
			FontFace = Theme.Fonts.Title,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 3,
			Parent = chip,
		})
		chip.Parent = leftColumn
		statuses[id] = chip
		Theme.Pop(chip, 0.05)
	end
	-- icone (recreee si le nom ou la couleur change)
	local iconKey = (opts.icon or "dot") .. color:ToHex()
	if chip:GetAttribute("IconKey") ~= iconKey then
		chip:SetAttribute("IconKey", iconKey)
		local old = chip:FindFirstChild("Icon")
		if old then
			old:Destroy()
		end
		local icon = Theme.Icon(opts.icon or "dot", 18, color)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 10, 0.5, 1)
		icon.ZIndex = 3
		icon.Parent = chip
	end
	local label = chip:FindFirstChild("Text") :: TextLabel
	label.Text = string.upper(opts.text)
	label.TextColor3 = color
	local accent = chip:FindFirstChild("Accent") :: Frame?
	if accent then
		accent.BackgroundColor3 = color
	end
end

-- Bouton d'action deja cree (nil sinon)
function Hud.GetAction(id: string)
	return actions[id]
end

-- Classement : rows = {{name, score, isMe}} tries, nil pour cacher. Le joueur hors top 5 s'ajoute en 6e ligne.
function Hud.SetLeaderboard(rows: { { name: string, score: number, isMe: boolean? } }?, title: string?)
	if not rows then
		boardGroup.Visible = false
		return
	end
	boardTitle.Text = Theme.Caps(title or "Royal Tide")
	local me = nil
	for i, r in rows do
		if r.isMe then
			me = i
		end
	end
	for i, row in boardRows do
		local index = i
		if i == LEADERBOARD_ROWS + 1 then
			index = if me and me > LEADERBOARD_ROWS then me else 0
		end
		local r = rows[index]
		row.Visible = r ~= nil
		if r then
			local rankLabel = row:FindFirstChild("Rank") :: TextLabel
			local nameLabel = row:FindFirstChild("Player") :: TextLabel
			local scoreLabel = row:FindFirstChild("Score") :: TextLabel
			rankLabel.Text = tostring(index)
			rankLabel.TextColor3 = MEDALS[index] or Theme.Colors.Text
			nameLabel.Text = r.name
			scoreLabel.Text = Config.Format(r.score)
			row.BackgroundTransparency = if r.isMe then 0.75 else 1
		end
	end
	boardGroup.Visible = true
	if shown then
		boardGroup.GroupTransparency = 0
	end
end

---------------------------------------------------------------- Demarrage
function Hud.Init(ctx)
	Util, Theme, Components = ctx.Util, ctx.Theme, ctx.Components
	Fx, Sfx, Config, Settings = ctx.Fx, ctx.Sfx, ctx.Config, ctx.Settings
	Hud.Shown = Util.Signal.new() -- le HUD vient d'apparaitre (Notifications rejoue ses messages)
	hudRoot = Theme.Create("Frame", {
		Name = "Hud",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Visible = false,
		Parent = ctx.Root,
	})
	buildWallet()
	buildTide()
	buildAlert()
	buildActions()
	buildLeftColumn()
	buildLeaderboard()
	-- boutons d'action, crees caches (StealHud, MountButton, Shop les pilotent)
	Hud.SetAction("mount", { icon = "ride", label = "Ride", color = Theme.Colors.Lagoon, order = 2, hotkey = "R", visible = false })
	Hud.SetAction("lock", { icon = "lock", label = "Lock", color = Theme.Colors.Warning, order = 1, hotkey = "L", visible = false })
end

function Hud.Start(ctx)
	Store = ctx.Store
	Store.Changed:Connect(onState)
	Store.WaveChanged:Connect(onWave)
	onWave(Store.GetWave(), nil)
	RunService.Heartbeat:Connect(onHeartbeat)
	local function reveal(state)
		if state.loaded and not held and not shown then
			Hud.SetVisible(true, true)
		end
	end
	Store.Changed:Connect(reveal)
	onState(Store.Get(), nil)
	reveal(Store.Get())
	task.delay(HOLD_MAX, function()
		if not shown then
			Hud.SetVisible(true, true)
		end
	end)
end

return Hud
