-- StealHud : interface du vol entre lagons (GDD v2 §4.7, contrat v2.1). Style console, textes courts.
--   Victime : Notify stealStart (role victim) -> alerte + fleche au bord de l'ecran vers le voleur + surbrillance ;
--             stolen / recovered -> fin. Etat : shield, protectedUntil, revenge, lockActive, lockReadyAt.
--   Voleur  : invite STEAL sur les bassins des lagons ouverts -> RF StartSteal(plot, slot) -> (true, holdEndsAt) ;
--             jauge jusqu'a holdEndsAt (le serveur tranche) ; state.carrying -> « RUN HOME » + fleche vers mon lagon ;
--             stealWin / stealFail {reason, push} (recul joue ici).
--   Verrou  : bouton LOCK (RF LockLagoon) avec sa recharge. Bouclier debutant : pastille + message a 3 min de la fin.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StealHud = {}

local PROMPT_TAG = "TR_StealPrompt"
local PROMPT_DISTANCE = 8 -- Config.Steal.grabRange si present
local ALERT_TIME = 24 -- fenetre de vol (alerte + vague)
local REFRESH = 0.5 -- s : verrou, bouclier, invites
local SHIELD_WARNING = 180 -- s avant la fin du bouclier : message unique (GDD §8)
local EDGE_MARGIN = 56 -- px depuis le bord pour la fleche hors ecran

-- Textes de 6 mots au plus (VISION_TON §5)
local CODE_TEXT = {
	Closed = "Lagoons closed",
	Locked = "Lagoon locked",
	Newbie = "Protected player",
	LastCreature = "Last creature: protected",
	Mounted = "Get off first",
	Carrying = "Already carrying one",
	TooFar = "Get closer",
	NotStealable = "Can't steal this",
	Busy = "Busy",
	Cooldown = "Not ready yet",
}
local FAIL_TEXT = {
	moved = "Hold still to steal",
	touched = "Caught by the owner",
	time = "Too slow: it swam home",
	wave = "Lost to the wave",
	died = "You dropped it",
	ownerLeft = "Owner left",
	invalid = "Steal failed",
}

local Util, Theme, Components, Store, Hud, Notifications, Sfx, Fx, Config
local player = Players.LocalPlayer
local playerGui: Instance

local chase = nil -- poursuite du voleur (victime)
local homeGuide = nil -- fleche vers mon lagon (voleur qui porte)
local revengeBoard: BillboardGui? = nil
local revengeFor: number? = nil
local shieldWarned = false
local holdBar = nil -- jauge du maintien serveur
local holdToken = 0

---------------------------------------------------------------- Outils
local function plotByIndex(index: number?): Instance?
	if type(index) ~= "number" or index <= 0 then
		return nil
	end
	return Util.Find(workspace, "Map", "Plots", "Plot" .. index)
end

local function myPlot(): Instance?
	local state = Store.Get()
	return state and plotByIndex(state.plot)
end

local function plotOfUser(userId: number?): Instance?
	local p = userId and Players:GetPlayerByUserId(userId)
	return p and plotByIndex(p:GetAttribute("Plot"))
end

local function plotCenter(plot: Instance): Vector3?
	local minX, maxX = plot:GetAttribute("MinX"), plot:GetAttribute("MaxX")
	local minZ, maxZ = plot:GetAttribute("MinZ"), plot:GetAttribute("MaxZ")
	if type(minX) ~= "number" or type(maxX) ~= "number" or type(minZ) ~= "number" or type(maxZ) ~= "number" then
		return nil
	end
	return Vector3.new((minX + maxX) / 2, 2, (minZ + maxZ) / 2)
end

local function creatureName(species: any, mutation: any): string
	local name = if type(species) == "string" then Store.CreatureName(species) else "creature"
	if type(mutation) == "string" and mutation ~= "" then
		return mutation .. " " .. name
	end
	return name
end

local function toast(text: string, color: Color3, icon: string, priority: string?, key: string?)
	Notifications.Push({ text = string.upper(text), color = color, icon = icon, priority = priority or "info", key = key })
end

local function stealWindowOpen(): boolean
	local phase = Store.GetWave().phase
	return phase == "warning" or phase == "wave"
end

---------------------------------------------------------------- Fleche au bord de l'ecran
-- Chevron dessine, pose dans le calque Fx (pixels reels), oriente vers une cible du monde
local function newEdgeArrow(color: Color3)
	local arrow = Theme.Icon("arrow", 44, color)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Visible = false
	arrow.ZIndex = 30
	arrow.Parent = Fx.GetLayer()
	return arrow
end

-- Place la fleche si la cible est hors champ ; renvoie true si la cible est visible
local function updateEdgeArrow(arrow: GuiObject, target: Vector3): boolean
	local cam = workspace.CurrentCamera
	if not cam then
		return false
	end
	local vp = cam.ViewportSize
	local p, onScreen = cam:WorldToViewportPoint(target)
	local inside = onScreen and p.X > 0 and p.X < vp.X and p.Y > 0 and p.Y < vp.Y
	arrow.Visible = not inside
	if inside then
		return true
	end
	-- direction dans le plan de l'ecran (inversee si la cible est derriere la camera)
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
	local kx = if math.abs(dir.X) > 1e-6 then math.abs(half.X / dir.X) else math.huge
	local ky = if math.abs(dir.Y) > 1e-6 then math.abs(half.Y / dir.Y) else math.huge
	local pos = Util.ViewportToLayer(Fx.GetLayer(), center + dir * math.min(kx, ky))
	arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
	arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
	return false
end

---------------------------------------------------------------- Poursuite du voleur (victime)
local function stopChase()
	if not chase then
		return
	end
	chase.conn:Disconnect()
	chase.highlight:Destroy()
	chase.arrow:Destroy()
	chase = nil
	Hud.HideAlert()
end

local function startChase(thiefId: number?, text: string)
	stopChase()
	Hud.ShowAlert(text, { icon = "alert", color = Theme.Colors.Danger, duration = ALERT_TIME })
	Sfx.Play("theftAlert")
	local thief = thiefId and Players:GetPlayerByUserId(thiefId)
	if not thief then
		return
	end
	local highlight = Instance.new("Highlight")
	highlight.Name = "TR_ThiefHighlight"
	highlight.FillColor = Theme.Colors.Danger
	highlight.FillTransparency = 0.8
	highlight.OutlineColor = Theme.Colors.Danger
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = Fx.GetWorldFolder() -- un Highlight doit etre dans le monde pour s'afficher
	local rec = { thief = thief, highlight = highlight, arrow = newEdgeArrow(Theme.Colors.Danger) }
	rec.conn = RunService.RenderStepped:Connect(function()
		local character = thief.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not thief.Parent or not root then
			rec.arrow.Visible = false
			return
		end
		if highlight.Adornee ~= character then
			highlight.Adornee = character
		end
		updateEdgeArrow(rec.arrow, root.Position)
	end)
	chase = rec
	local token = rec
	task.delay(ALERT_TIME + 8, function()
		if chase == token then
			stopChase()
		end
	end)
end

---------------------------------------------------------------- Retour a la maison (voleur qui porte)
local function stopHomeGuide()
	if not homeGuide then
		return
	end
	homeGuide.conn:Disconnect()
	homeGuide.arrow:Destroy()
	homeGuide = nil
	Hud.HideAlert()
end

local function startHomeGuide(carrying)
	if homeGuide then
		return
	end
	Hud.ShowAlert("Run home  ·  " .. creatureName(carrying.species, carrying.mutation), {
		icon = "arrow",
		color = Theme.Colors.Lagoon,
		duration = 60,
	})
	local rec = { arrow = newEdgeArrow(Theme.Colors.Lagoon) }
	rec.conn = RunService.RenderStepped:Connect(function()
		local plot = myPlot()
		local target = plot and plotCenter(plot)
		if target then
			updateEdgeArrow(rec.arrow, target)
		else
			rec.arrow.Visible = false
		end
	end)
	homeGuide = rec
end

---------------------------------------------------------------- Revanche
local function setRevenge(revenge)
	local userId = if revenge then revenge.userId else nil
	if userId == revengeFor then
		return
	end
	revengeFor = userId
	if revengeBoard then
		revengeBoard:Destroy()
		revengeBoard = nil
	end
	if not revenge then
		Hud.SetStatus("revenge", nil)
		return
	end
	Hud.SetStatus("revenge", { icon = "revenge", text = "Revenge: " .. revenge.name, color = Theme.Colors.Warning, order = 2 })
	-- repere au-dessus du lagon du voleur, visible de loin
	local plot = plotOfUser(userId)
	local anchor = plot and (plot:FindFirstChild("SignAnchor", true) or plot:FindFirstChildWhichIsA("BasePart", true))
	if not anchor then
		return
	end
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_Revenge",
		Size = UDim2.fromOffset(150, 36),
		StudsOffsetWorldSpace = Vector3.new(0, 14, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 2000,
		ResetOnSpawn = false,
		Adornee = anchor,
	})
	local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Accent = Theme.Colors.Warning, Strong = true, Parent = gui })
	local icon = Theme.Icon("revenge", 18, Theme.Colors.Warning)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.Parent = plate
	Theme.Title({
		Name = "Text",
		Position = UDim2.fromOffset(34, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Text = "Revenge",
		TextSize = 18,
		TextColor3 = Theme.Colors.Warning,
		ZIndex = 3,
		Parent = plate,
	})
	gui.Parent = playerGui
	revengeBoard = gui
end

---------------------------------------------------------------- Jauge du maintien (le serveur tranche)
local function buildHoldBar(parent: Instance)
	local frame = Theme.Plate({
		Name = "StealHold",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.62, 0),
		Size = UDim2.fromOffset(220, 44),
		Accent = Theme.Colors.Danger,
		Strong = true,
		Parent = parent,
	})
	frame.Visible = false
	Theme.Title({
		Name = "Text",
		Position = UDim2.fromOffset(0, 4),
		Size = UDim2.new(1, 0, 0, 22),
		Text = "Stealing",
		TextSize = Theme.TextSize.Small,
		TextColor3 = Theme.Colors.Text,
		ZIndex = 3,
		Parent = frame,
	})
	local bar = Components.ProgressBar({
		Name = "Gauge",
		Position = UDim2.fromOffset(12, 30),
		Size = UDim2.new(1, -24, 0, 5),
		Color = Theme.Colors.Danger,
		ZIndex = 3,
		Parent = frame,
	})
	bar.Label.Visible = false
	holdBar = { frame = frame, bar = bar }
end

local function stopHold(failed: boolean)
	holdToken += 1
	if not holdBar or not holdBar.frame.Visible then
		return
	end
	if failed then
		Theme.Shake(holdBar.frame)
		task.delay(0.15, function()
			holdBar.frame.Visible = false
		end)
	else
		holdBar.frame.Visible = false
	end
end

local function startHold(holdEndsAt: number)
	holdToken += 1
	local token = holdToken
	local duration = math.max(0.05, holdEndsAt - Store.ServerClock())
	holdBar.frame.Visible = true
	holdBar.bar:Set(0, false)
	-- progression lineaire : elle represente le temps, pas une animation decorative
	Util.Tween(holdBar.bar.Fill, duration, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
	task.delay(duration + 1.5, function()
		if holdToken == token then
			stopHold(false) -- ni stealStart ni stealFail : on range la jauge
		end
	end)
end

---------------------------------------------------------------- Invites STEAL (voleur)
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

local function onStealPressed(index: number, slot: number)
	local ok, value = Store.StartSteal(index, slot)
	if ok and type(value) == "number" then
		startHold(value)
	elseif not ok and value ~= "NoRemote" then
		toast(CODE_TEXT[value] or "Can't steal now", Theme.Colors.Danger, "close", "info", "steal-err")
		Sfx.Play("deny")
	end
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
	local steal = (Config :: any).Steal
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "TR_Steal"
	prompt.ActionText = "STEAL"
	prompt.ObjectText = if type(species) == "string" then string.upper(Store.CreatureName(species)) else ""
	prompt.HoldDuration = 0 -- le maintien de 1 s est compte par le serveur (StartSteal)
	prompt.MaxActivationDistance = if type(steal) == "table" and steal.grabRange then steal.grabRange else PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.Enabled = false
	prompt:AddTag(PROMPT_TAG)
	prompt.Triggered:Connect(function()
		onStealPressed(index, slot)
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

-- Le serveur verifie tout ; ici on n'affiche l'invite que quand elle a une chance d'aboutir
local function refreshPrompts()
	local state = Store.Get()
	local can = Store.HasRemote("StartSteal")
		and stealWindowOpen()
		and state.loaded
		and not state.newbie
		and state.mount == nil
		and not state.carrying
	local revengeOn = if state.revenge then state.revenge.userId else nil
	for model, prompt in prompts do
		local plot = foreignPlotOf(model)
		local open = false
		if plot then
			open = plot:GetAttribute("Open") == true or (revengeOn ~= nil and plot:GetAttribute("Owner") == revengeOn)
		end
		local hidden = model:GetAttribute("Mounted") == true or model:GetAttribute("Carried") == true
		prompt.Enabled = can and open and not hidden
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

---------------------------------------------------------------- Verrou et bouclier
local function refreshLock(state)
	local plot = myPlot()
	-- un debutant ne peut pas etre vole : le verrou n'apparait qu'a la fin de sa protection
	local available = Store.HasRemote("LockLagoon") and plot ~= nil and state.loaded and (not state.newbie or shieldWarned)
	local lock = Hud.SetAction("lock", { visible = available })
	if not available then
		return
	end
	local now = Store.ServerClock()
	if state.lockActive then
		Hud.SetAction("lock", { icon = "lock", label = "Locked", color = Theme.Colors.Success, enabled = false })
	elseif now < state.lockReadyAt then
		Hud.SetAction("lock", { icon = "clock", label = Util.FormatTime(state.lockReadyAt - now), color = Theme.Colors.Disabled, enabled = false })
	else
		Hud.SetAction("lock", { icon = "unlock", label = "Lock", color = Theme.Colors.Warning, enabled = true })
	end
	return lock
end

local function newbieLeft(state): number?
	local steal = (Config :: any).Steal
	local minutes = type(steal) == "table" and tonumber(steal.newbieMinutes) or nil
	if not minutes then
		return nil
	end
	return math.max(0, minutes * 60 - state.playTime)
end

local function refreshShield(state)
	local shield = state.shield
	if shield == "" or not state.loaded then
		Hud.SetStatus("shield", nil)
		return
	end
	local now = Store.ServerClock()
	local text
	if shield == "newbie" then
		local left = newbieLeft(state)
		text = if left then "Protected  " .. Util.FormatTime(left) else "Protected"
		-- GDD §8 : un seul message, 3 min avant la fin, avec le verrou mis en avant
		if left and left <= SHIELD_WARNING and not shieldWarned then
			shieldWarned = true
			toast("Shield ends in 3 min", Theme.Colors.Warning, "shield", "wave")
			task.defer(function()
				local lock = Hud.GetAction("lock")
				if lock and lock.Instance.Visible then
					Theme.Celebrate(lock.Button, 0.15)
				end
			end)
		end
	elseif shield == "stolen" then
		local left = state.protectedUntil - now
		text = if left > 0 then "Protected  " .. Util.FormatTime(left) else "Protected"
	elseif shield == "cap" then
		text = "Auto-locked"
	else
		text = "Lagoon locked"
	end
	Hud.SetStatus("shield", { icon = "shield", text = text, color = Theme.Colors.Lagoon, order = 1 })
end

local function onLockPressed()
	local ok, code = Store.LockLagoon()
	if ok then
		Sfx.Play("barrierClose")
		toast("Lagoon locked", Theme.Colors.Success, "lock", "info", "lock")
	else
		Sfx.Play("deny")
		toast(CODE_TEXT[code] or "Can't lock now", Theme.Colors.Danger, "close", "info", "lock")
	end
	refreshLock(Store.Get())
end

---------------------------------------------------------------- Messages du serveur
local function knockback(push: any)
	if typeof(push) ~= "Vector3" then
		return
	end
	local root = Util.LocalRoot(player)
	if root then
		root.AssemblyLinearVelocity += push
	end
	Fx.Shake(0.25)
end

local function onNotify(kind: string, data)
	if kind == "stealStart" then
		stopHold(false)
		if data.role == "victim" then
			local thiefName = if type(data.thiefName) == "string" then data.thiefName else "Thief"
			startChase(tonumber(data.thief), thiefName .. " has your " .. creatureName(data.species, data.mutation))
		elseif data.role == "thief" then
			Sfx.Play("steal")
			Fx.Flash(Theme.Colors.Danger, 0.15, 0.2)
		end
	elseif kind == "stealWin" then
		-- vrai moment : celebration
		Sfx.Play("royalWin")
		Notifications.Reward({ text = "STOLEN", sub = creatureName(data.species, data.mutation), color = Theme.Colors.Gold })
		Fx.Confetti(workspace.CurrentCamera.ViewportSize / 2, 18)
	elseif kind == "stolen" then
		stopChase()
		local thiefName = if type(data.thiefName) == "string" then data.thiefName else "A thief"
		toast(thiefName .. " stole your " .. creatureName(data.species, data.mutation), Theme.Colors.Danger, "alert", "wave")
	elseif kind == "stealFail" then
		stopHold(true)
		knockback(data.push)
		toast(FAIL_TEXT[data.reason] or "Steal failed", Theme.Colors.Danger, "close", "wave", "steal-fail")
	elseif kind == "recovered" then
		stopChase()
		toast(creatureName(data.species, data.mutation) .. " recovered", Theme.Colors.Success, "shield", "wave")
		Sfx.Play("splash")
	elseif kind == "revenge" then
		local name = if type(data.thiefName) == "string" then data.thiefName else ""
		toast("Revenge on " .. name, Theme.Colors.Warning, "revenge", "wave")
	end
end

local function onState(state)
	if not state.loaded then
		return
	end
	if state.carrying then
		startHomeGuide(state.carrying)
	else
		stopHomeGuide()
	end
	setRevenge(state.revenge or nil)
	refreshShield(state)
	refreshLock(state)
end

---------------------------------------------------------------- Demarrage
function StealHud.Init(ctx)
	Util, Theme, Components, Hud, Notifications = ctx.Util, ctx.Theme, ctx.Components, ctx.Hud, ctx.Notifications
	Sfx, Fx, Config = ctx.Sfx, ctx.Fx, ctx.Config
	playerGui = player:WaitForChild("PlayerGui")
	buildHoldBar(ctx.Root)
end

function StealHud.Start(ctx)
	Store = ctx.Store
	Hud.SetAction("lock", { onActivated = onLockPressed })
	Store.Notified:Connect(onNotify)
	Store.Changed:Connect(onState)
	Store.WaveChanged:Connect(refreshPrompts)
	onState(Store.Get())
	task.spawn(watchDisplays)
	while true do
		task.wait(REFRESH)
		local state = Store.Get()
		if state.loaded then
			refreshShield(state)
			refreshLock(state)
		end
		refreshPrompts()
	end
end

return StealHud
