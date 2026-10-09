-- StealHud : interface du vol entre lagons (GDD v2 §4.7). Forme du contrat PROVISOIRE (noms reserves par A) :
--   Notify "stolen" {thief (UserId), species, mutation, text}  -> on me vole : alerte + fleche vers le voleur
--   StealResult {stealId, thief, victim, species, mutation, success} -> fin du vol (des deux cotes)
--   RF StealAttempt(plot, slot) apres un maintien de 1 s sur une creature d'un lagon ouvert ; RF LockLagoon()
--   PlotN : attributs Open (barriere), LockedUntil, LockReadyAt (recharge du verrou) ; state.protection (bouclier)
-- Rien ne s'affiche tant que le serveur ne propose pas la fonction (Store.HasRemote).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local StealHud = {}

local PROMPT_TAG = "TR_StealPrompt"
local HOLD_TIME = 1.0 -- GDD : maintien de 1,0 s
local PROMPT_DISTANCE = 9
local ALERT_TIME = 24 -- la fenetre de vol (alerte + vague)
local REFRESH = 0.5 -- s : verrou, bouclier, invites
local SHIELD_WARNING = 180 -- s avant la fin du bouclier : message unique (GDD §8)
local EDGE_MARGIN = 56 -- px depuis le bord pour la fleche hors ecran

local ERROR_TEXT = {
	Locked = "This lagoon is locked!",
	TooFar = "Get closer to steal!",
	NotStealable = "This one can't be stolen.",
	Cooldown = "Not now!",
	WaveActive = "Wait for the wave!",
}

local Util, Theme, Components, Store, Hud, Notifications, Sfx, Fx
local player = Players.LocalPlayer
local playerGui: Instance

-- poursuite du voleur (cote victime)
local chase = nil -- {thief: Player, highlight, billboard, arrow}
-- revanche : {thief: UserId, plot, cycle}
local revenge = nil
local revengeBoard: BillboardGui? = nil
local shieldWarned = false

---------------------------------------------------------------- Outils
local function myPlot(): Instance?
	local state = Store.Get()
	if not state or state.plot <= 0 then
		return nil
	end
	return Util.Find(workspace, "Map", "Plots", "Plot" .. state.plot)
end

local function plotOfPlayer(p: Player?): Instance?
	local index = p and p:GetAttribute("Plot")
	if type(index) ~= "number" or index <= 0 then
		return nil
	end
	return Util.Find(workspace, "Map", "Plots", "Plot" .. index)
end

local function creatureLabel(species: any, mutation: any): string
	local name = if type(species) == "string" then Store.CreatureName(species) else "creature"
	if type(mutation) == "string" and mutation ~= "" then
		return mutation .. " " .. name
	end
	return name
end

local function stealWindowOpen(): boolean
	local phase = Store.GetWave().phase
	return phase == "warning" or phase == "wave"
end

---------------------------------------------------------------- Poursuite du voleur (victime)
local function buildThiefTag(): BillboardGui
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_ThiefTag",
		Size = UDim2.fromOffset(150, 40),
		StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
	})
	local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Accent = Theme.Colors.Danger, Parent = gui })
	Theme.Text({
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		Text = "🚨 THIEF",
		TextSize = 18,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Coral,
		ZIndex = 3,
		Parent = plate,
	})
	return gui
end

-- Fleche au bord de l'ecran quand le voleur est hors champ (calque Fx, pixels reels)
local function buildEdgeArrow(): TextLabel
	local arrow = Theme.Text({
		Name = "ThiefArrow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(56, 56),
		Text = "➤",
		TextSize = 48,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Danger,
		Visible = false,
		ZIndex = 30,
		Parent = Fx.GetLayer(),
	})
	return arrow
end

local function stopChase()
	if not chase then
		return
	end
	chase.conn:Disconnect()
	chase.highlight:Destroy()
	chase.tag:Destroy()
	chase.arrow:Destroy()
	chase = nil
	Hud.HideAlert()
end

local function updateChase()
	if not chase then
		return
	end
	local character = chase.thief.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not chase.thief.Parent or not root then
		chase.arrow.Visible = false
		return
	end
	if chase.highlight.Adornee ~= character then
		chase.highlight.Adornee = character
		chase.tag.Adornee = root
	end
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local vp = cam.ViewportSize
	local p, onScreen = cam:WorldToViewportPoint(root.Position)
	local inside = onScreen and p.X > 0 and p.X < vp.X and p.Y > 0 and p.Y < vp.Y
	chase.arrow.Visible = not inside
	if inside then
		return
	end
	-- direction vers le voleur dans le plan de l'ecran (inversee s'il est derriere la camera)
	local center = vp / 2
	local dir = Vector2.new(p.X, p.Y) - center
	if p.Z < 0 then
		dir = -dir
	end
	if dir.Magnitude < 1 then
		dir = Vector2.new(0, -1)
	end
	dir = dir.Unit
	local half = center - Vector2.new(EDGE_MARGIN, EDGE_MARGIN)
	local k = math.min(math.abs(half.X / (if dir.X ~= 0 then dir.X else 1e-6)), math.abs(half.Y / (if dir.Y ~= 0 then dir.Y else 1e-6)))
	local pos = Util.ViewportToLayer(Fx.GetLayer(), center + dir * k)
	chase.arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
	chase.arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
end

local function startChase(thiefId: number, text: string)
	local thief = Players:GetPlayerByUserId(thiefId)
	if not thief then
		return
	end
	stopChase()
	local highlight = Instance.new("Highlight")
	highlight.Name = "TR_ThiefHighlight"
	highlight.FillColor = Theme.Colors.Danger
	highlight.FillTransparency = 0.75
	highlight.OutlineColor = Theme.Colors.Danger
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = Fx.GetWorldFolder() -- un Highlight doit etre dans le monde pour s'afficher
	local tag = buildThiefTag()
	tag.Parent = playerGui
	chase = {
		thief = thief,
		highlight = highlight,
		tag = tag,
		arrow = buildEdgeArrow(),
		conn = RunService.RenderStepped:Connect(updateChase),
	}
	Hud.ShowAlert(text, { icon = "🚨", duration = ALERT_TIME })
	Sfx.Play("alarm")
	-- securite : la poursuite s'arrete avec la fenetre de vol meme sans StealResult
	local token = chase
	task.delay(ALERT_TIME + 6, function()
		if chase == token then
			stopChase()
		end
	end)
end

---------------------------------------------------------------- Revanche
local function clearRevenge()
	revenge = nil
	Hud.SetStatus("revenge", nil)
	if revengeBoard then
		revengeBoard:Destroy()
		revengeBoard = nil
	end
end

local function showRevenge(thiefId: number)
	local thief = Players:GetPlayerByUserId(thiefId)
	local plot = plotOfPlayer(thief)
	if not thief or not plot then
		return
	end
	clearRevenge()
	revenge = { thief = thiefId, plot = plot, cycle = Store.GetWave().cycle }
	Hud.SetStatus("revenge", { icon = "⚔️", text = "Revenge on " .. thief.DisplayName, color = Theme.Colors.Sunset, order = 2 })
	-- repere au-dessus de son lagon, visible de loin
	local anchor = plot:FindFirstChild("SignAnchor", true) or plot:FindFirstChildWhichIsA("BasePart", true)
	if anchor then
		local gui = Theme.Create("BillboardGui", {
			Name = "TR_Revenge",
			Size = UDim2.fromOffset(170, 44),
			StudsOffsetWorldSpace = Vector3.new(0, 14, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			MaxDistance = 2000,
			ResetOnSpawn = false,
			Adornee = anchor,
		})
		local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Accent = Theme.Colors.Sunset, Parent = gui })
		Theme.Text({
			Name = "Text",
			Size = UDim2.fromScale(1, 1),
			Text = "⚔️ REVENGE",
			TextSize = 20,
			FontFace = Theme.Fonts.Title,
			TextColor3 = Theme.Colors.Sunset,
			ZIndex = 3,
			Parent = plate,
		})
		gui.Parent = playerGui
		revengeBoard = gui
	end
end

---------------------------------------------------------------- Resultats
local function onStolen(data)
	local thief = tonumber(data.thief)
	local text = if type(data.text) == "string" then data.text else "Someone is stealing your " .. creatureLabel(data.species, data.mutation) .. "!"
	if thief then
		startChase(thief, text)
	else
		Hud.ShowAlert(text, { icon = "🚨", duration = ALERT_TIME })
	end
end

local function onResult(result)
	local me = player.UserId
	local label = creatureLabel(result.species, result.mutation)
	if tonumber(result.victim) == me then
		stopChase()
		if result.success == true then
			Notifications.Push({ text = "Your " .. label .. " was stolen! Revenge is ready.", color = Theme.Colors.Danger, icon = "💔", priority = "wave", duration = 4 })
			if tonumber(result.thief) then
				showRevenge(tonumber(result.thief) :: number)
			end
		else
			Notifications.Push({ text = "You got your " .. label .. " back!", color = Theme.Colors.Success, icon = "🛡️", priority = "wave" })
			Sfx.Play("purchase")
		end
	elseif tonumber(result.thief) == me then
		if result.success == true then
			Notifications.Push({ text = "Stolen: " .. label .. "!", color = Theme.Colors.Gold, icon = "😈", priority = "reward" })
			Fx.Flash(Theme.Colors.Gold, 0.25, 0.4)
		else
			Notifications.Push({ text = label .. " went back home.", color = Theme.Colors.TextDim, icon = "↩️", priority = "info" })
		end
	end
end

---------------------------------------------------------------- Maintien pour voler (voleur)
local prompts: { [Instance]: ProximityPrompt } = {}

local function foreignPlotOf(model: Instance): (Instance?, number?)
	local display = model.Parent
	local plot = display and display.Parent
	if not plot or not display or display.Name ~= "Display" then
		return nil, nil
	end
	local owner = plot:GetAttribute("Owner")
	if owner == nil or owner == player.UserId then
		return nil, nil
	end
	return plot, tonumber(plot:GetAttribute("Index")) or tonumber((plot.Name:match("%d+")))
end

local function addPrompt(model: Instance)
	if prompts[model] or not model:IsA("Model") then
		return
	end
	local plot, index = foreignPlotOf(model)
	local slot = tonumber(model:GetAttribute("Slot"))
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not plot or not index or not slot or not root then
		return
	end
	local species = model:GetAttribute("CreatureId")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TR_Steal"
	prompt.ActionText = "Steal"
	prompt.ObjectText = if type(species) == "string" then Store.CreatureName(species) else ""
	prompt.HoldDuration = HOLD_TIME
	prompt.MaxActivationDistance = PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = false
	prompt:SetAttribute("Plot", index)
	prompt:SetAttribute("Slot", slot)
	prompt:AddTag(PROMPT_TAG)
	prompt.Triggered:Connect(function()
		local ok, code = Store.StealAttempt(index, slot)
		if not ok and code ~= "NoRemote" then
			Notifications.Push({ text = ERROR_TEXT[code] or "Can't steal right now.", color = Theme.Colors.Danger, icon = "✖️", key = "steal-err" })
			Sfx.Play("deny")
		end
	end)
	prompt.Parent = root
	prompts[model] = prompt
end

local function removePrompt(model: Instance)
	local prompt = prompts[model]
	if prompt then
		prompt:Destroy()
		prompts[model] = nil
	end
end

local function refreshPrompts()
	local can = Store.HasRemote("StealAttempt") and stealWindowOpen()
	local state = Store.Get()
	if state and (state.protection.active or state.mount ~= nil) then
		can = false -- bouclier debutant (il ne peut pas voler non plus) ou monte : il faut descendre
	end
	for model, prompt in prompts do
		local plot = foreignPlotOf(model)
		local open = plot ~= nil and plot:GetAttribute("Open") ~= false -- attribut absent : le serveur tranchera
		prompt.Enabled = can and open
	end
end

local function watchDisplays()
	local plots = Util.Find(workspace, "Map", "Plots")
	while not plots do
		task.wait(1)
		plots = Util.Find(workspace, "Map", "Plots")
	end
	local function watchDisplay(display: Instance)
		for _, m in display:GetChildren() do
			addPrompt(m)
		end
		display.ChildAdded:Connect(addPrompt)
		display.ChildRemoved:Connect(removePrompt)
	end
	local function watchPlot(plot: Instance)
		local display = plot:FindFirstChild("Display")
		if display then
			watchDisplay(display)
		end
		plot.ChildAdded:Connect(function(child)
			if child.Name == "Display" then
				watchDisplay(child)
			end
		end)
		-- changement de proprietaire : on recree les invites de ce lagon
		plot:GetAttributeChangedSignal("Owner"):Connect(function()
			local d = plot:FindFirstChild("Display")
			if d then
				for _, m in d:GetChildren() do
					removePrompt(m)
					addPrompt(m)
				end
			end
		end)
	end
	for _, plot in plots:GetChildren() do
		watchPlot(plot)
	end
	plots.ChildAdded:Connect(watchPlot)
end

-- Rendu console de l'invite (Style Custom) : bouton a maintenir + jauge, utilisable au doigt
local function buildPromptGui(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_StealPromptGui",
		Size = UDim2.fromOffset(170, 64),
		StudsOffsetWorldSpace = Vector3.new(0, 4, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Active = true,
		ResetOnSpawn = false,
		Adornee = prompt.Parent,
	})
	local button = Theme.Create("TextButton", {
		Name = "Hold",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		Parent = gui,
	})
	local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Accent = Theme.Colors.Coral, Parent = button })
	local key = if inputType == Enum.ProximityPromptInputType.Keyboard then "[E] " else ""
	Theme.Text({
		Name = "Text",
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, 0, 0, 30),
		Text = key .. "HOLD TO STEAL",
		TextSize = 18,
		FontFace = Theme.Fonts.Title,
		TextColor3 = Theme.Colors.Coral,
		ZIndex = 3,
		Parent = plate,
	})
	local bar = Components.ProgressBar({
		Name = "Gauge",
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 0, 12),
		Color = Theme.Colors.Coral,
		ZIndex = 3,
		Parent = plate,
	})
	bar.Label.Visible = false
	bar:Set(0, false)
	-- toucher : on pilote l'invite nous-memes
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end)
	local holding = false
	local conns = {}
	table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
		holding = true
		bar:Set(0, false)
		Util.Tween(bar.Fill, prompt.HoldDuration, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
	end))
	table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
		holding = false
		bar:Set(0, true)
	end))
	-- GDD : le maintien s'interrompt si on bouge
	table.insert(conns, RunService.Heartbeat:Connect(function()
		if not holding then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
			holding = false
			prompt:InputHoldEnd()
			prompt.Enabled = false
			prompt.Enabled = true
			bar:Set(0, true)
			Theme.Shake(plate)
		end
	end))
	gui.Parent = playerGui
	return gui, conns
end

---------------------------------------------------------------- Verrou et bouclier
local function refreshLock()
	local state = Store.Get()
	local plot = myPlot()
	local available = Store.HasRemote("LockLagoon") and plot ~= nil and state.loaded
	local lock = Hud.SetAction("lock", { visible = available })
	if not available or not plot then
		return
	end
	local now = Store.Now()
	local lockedUntil = tonumber(plot:GetAttribute("LockedUntil")) or 0
	local readyAt = tonumber(plot:GetAttribute("LockReadyAt")) or 0
	if now < lockedUntil then
		Hud.SetAction("lock", { icon = "🔒", label = Util.FormatTime(lockedUntil - now), enabled = false })
		lock.Label.TextColor3 = Theme.Colors.Success
	elseif now < readyAt then
		Hud.SetAction("lock", { icon = "⏳", label = Util.FormatTime(readyAt - now), enabled = false })
		lock.Label.TextColor3 = Theme.Colors.TextDim
	else
		Hud.SetAction("lock", { icon = "🔓", label = "Lock", enabled = true })
		lock.Label.TextColor3 = Theme.Colors.Text
	end
end

local function refreshShield()
	local state = Store.Get()
	local p = state and state.protection
	if not p or not p.active then
		Hud.SetStatus("shield", nil)
		return
	end
	local left = if p.endsAt then p.endsAt - Store.ServerClock() else nil
	local text = if left and left > 0 then "Beginner shield " .. Util.FormatTime(left) else "Beginner shield"
	Hud.SetStatus("shield", { icon = "🛡️", text = text, color = Theme.Colors.Lagoon, order = 1 })
	-- GDD §8 : un seul message, 3 min avant la fin, avec le verrou mis en avant
	if left and left <= SHIELD_WARNING and not shieldWarned then
		shieldWarned = true
		Notifications.Push({
			text = "In 3 min, thieves can visit your lagoon during the wave. And you can steal too!",
			color = Theme.Colors.Sunset,
			icon = "🛡️",
			priority = "wave",
			duration = 6,
		})
		local lock = Hud.GetAction("lock")
		if lock and lock.Instance.Visible then
			Theme.Pop(lock.Button, 0.3)
		end
	end
end

local function onLockPressed()
	local ok, code = Store.LockLagoon()
	if ok then
		Sfx.Play("purchase")
		Notifications.Push({ text = "Lagoon locked for the next wave!", color = Theme.Colors.Success, icon = "🔒", key = "lock" })
	else
		Sfx.Play("deny")
		Notifications.Push({ text = ERROR_TEXT[code] or "Can't lock right now.", color = Theme.Colors.Danger, icon = "✖️", key = "lock" })
	end
	refreshLock()
end

---------------------------------------------------------------- Demarrage
function StealHud.Init(ctx)
	Util, Theme, Hud, Notifications = ctx.Util, ctx.Theme, ctx.Hud, ctx.Notifications
	Sfx, Fx = ctx.Sfx, ctx.Fx
	Components = ctx.Components
	playerGui = player:WaitForChild("PlayerGui")
end

function StealHud.Start(ctx)
	Store = ctx.Store
	Hud.SetAction("lock", { onActivated = onLockPressed })
	Store.Notified:Connect(function(kind, data)
		if kind == "stolen" then
			onStolen(data)
		end
	end)
	Store.StealResult:Connect(onResult)
	Store.WaveChanged:Connect(function(wave)
		refreshPrompts()
		-- la revanche vaut pour l'alerte suivante : on l'efface une fois cette vague passee
		if revenge and wave.phase == "calm" and wave.cycle > revenge.cycle + 1 then
			clearRevenge()
		end
	end)
	-- invites personnalisees (Style Custom)
	local shown: { [ProximityPrompt]: any } = {}
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if not prompt:HasTag(PROMPT_TAG) or shown[prompt] then
			return
		end
		local gui, conns = buildPromptGui(prompt, inputType)
		shown[prompt] = { gui = gui, conns = conns }
		prompt.PromptHidden:Once(function()
			local rec = shown[prompt]
			shown[prompt] = nil
			if rec then
				for _, c in rec.conns do
					c:Disconnect()
				end
				rec.gui:Destroy()
			end
		end)
	end)
	task.spawn(watchDisplays)
	while true do
		refreshLock()
		refreshShield()
		refreshPrompts()
		task.wait(REFRESH)
	end
end

return StealHud
