-- CameraIntro : séquence cinématique des 30 premières secondes (GDD §1.1, DIRECTION_V2)
-- 0-1.5s   plan aérien île couchant (LoadingScreen gère l'écran de chargement)
-- 1.5-3s   fondu, caméra derrière l'avatar au lagon
-- 3-5.5s   INDICATION CROSS-PLATEFORME (2.5s) :
--          Mobile/Tablette : icône main + "APPUIE POUR AVANCER" (joystick natif visible)
--          PC/Clavier : "WASD / FLECHES  |  SHIFT = SPRINT  |  CLIC DROIT = CAMERA"
--          Gamepad : "STICK GAUCHE = BOUGER  |  A = SPRINT  |  STICK DROIT = CAMERA"
-- 3-7.6s   4 créatures, le joueur en attrape 2-3
-- 7.6-16s  mouettes fuient, vague arrive, il court chope
-- 16-29.6s place créature, barre "NEXT TIDE: GOLDEN"
-- 29.6-31.5s vague s'écrase, "YOUR BASE. YOUR CREATURE. YOUR WAVE."
-- ZÉRO texte explicatif. Flèche unique universelle. PAS de HUD avant 31.5s.
-- Détection : UserInputService.TouchEnabled + KeyboardEnabled + GamepadEnabled

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CameraIntro = {}

local player = Players.LocalPlayer

-- Timings précis (secondes) — EXACTS selon cahier des charges
local TIMELINE = {
	AERIAL_END        = 1.5,    -- 0-1.5s : plan aérien
	FADE_END          = 3.0,    -- 1.5-3s : fondu + caméra derrière
	PLATFORM_HINT_END = 5.5,    -- 3-5.5s : hint cross-platform (2.5s) — DANS explore
	EXPLORE_END       = 16.0,   -- 3-16s : explore (flèche créatures, attrape 2-3)
	ALERT_START       = 16.0,   -- 16s : début alerte (mouettes fuient, mer recule)
	ALERT_END         = 20.0,   -- 16-20s : alerte (4s total)
	SPRINT_END        = 29.0,   -- 20-29s : sprint vers lagon (9s)
	BARRIER_CROSS     = 29.6,   -- 29-29.6s : franchit barrière (0.6s)
	WAVE_CRASH_END    = 31.5,   -- 29.6-31.5s : vague s'écrase + texte final (1.9s)
	HUD_SHOW          = 31.5,
}

-- Constantes
local AERIAL_HEIGHT = 120
local AERIAL_DISTANCE = 200
local INTRO_CAMERA_HEIGHT = 5
local INTRO_CAMERA_BACK = 12
local ARROW_AHEAD = 8
local ARROW_PULSE_HZ = 1.5

local Util, Theme, Fx, Store, Hud, Settings, Config
local camera = Workspace.CurrentCamera
local introStartTime = 0
local introPhase = "awaiting" -- awaiting, aerial, fade, behind, platformHint, explore, alert, sprint, barrier, wavecrash, done
local arrowModel = nil
local arrowParts = {}
local arrowConn = nil
local captionLabel = nil
local captionStroke = nil
local captionToken = 0
local platformHintLabel = nil
local seagulls = {}
local seagullConn = nil
local skipRequested = false
local onComplete = nil
local isMobile = false

-------------------------------------------------------------------------------- Arrow au sol (flèche unique "GO THERE")
local function buildArrow()
	arrowModel = Instance.new("Model")
	arrowModel.Name = "TR_IntroArrow"
	for i = 1, 3 do
		local left = Instance.new("Part")
		left.Name = "ChevronL" .. i
		left.Anchored = true
		left.CanCollide = false
		left.CanQuery = false
		left.CanTouch = false
		left.CastShadow = false
		left.Material = Enum.Material.Neon
		left.Color = Theme.Colors.Gold
		left.Size = Vector3.new(0.45, 0.15, 1.5)
		left.Parent = arrowModel
		table.insert(arrowParts, left)

		local right = Instance.new("Part")
		right.Name = "ChevronR" .. i
		right.Anchored = true
		right.CanCollide = false
		right.CanQuery = false
		right.CanTouch = false
		right.CastShadow = false
		right.Material = Enum.Material.Neon
		right.Color = Theme.Colors.Gold
		right.Size = Vector3.new(0.45, 0.15, 1.5)
		right.Parent = arrowModel
		table.insert(arrowParts, right)
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function groundY(pos: Vector3): number
	rayParams.FilterDescendantsInstances = { player.Character, arrowModel }
	local hit = Workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
	return if hit then hit.Position.Y else pos.Y - 3
end

local function hideArrow()
	if arrowModel then
		arrowModel.Parent = nil
	end
end

local function stopArrow()
	if arrowConn then
		arrowConn:Disconnect()
		arrowConn = nil
	end
	hideArrow()
end

local function startArrow(getTarget: (Vector3) -> Vector3?)
	stopArrow()
	buildArrow()
	arrowConn = RunService.Heartbeat:Connect(function()
		if skipRequested then
			hideArrow()
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local target = root and getTarget(root.Position)
		if not root or not target then
			hideArrow()
			return
		end
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		if flat.Magnitude < 4 then
			hideArrow()
			return
		end
		local dir = flat.Unit
		local base = root.Position + dir * ARROW_AHEAD
		local ground = Vector3.new(base.X, groundY(base) + 0.25, base.Z)
		local origin = CFrame.lookAt(ground, ground + dir)
		local reduced = Settings and Settings.Get("reducedMotion")
		local clock = os.clock()
		for i = 1, 3 do
			local c = origin * CFrame.new(0, 0, -(i - 1) * 1.6)
			arrowParts[i * 2 - 1].CFrame = c * CFrame.lookAt(Vector3.new(-0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
			arrowParts[i * 2].CFrame = c * CFrame.lookAt(Vector3.new(0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
			local alpha = if reduced then 0.15 else 0.1 + 0.6 * ((clock * ARROW_PULSE_HZ - i * 0.25) % 1)
			arrowParts[i * 2 - 1].Transparency = alpha
			arrowParts[i * 2].Transparency = alpha
		end
		if not arrowModel.Parent then
			arrowModel.Parent = Fx.GetWorldFolder()
		end
	end)
end

-------------------------------------------------------------------------------- Texte unique (style console, capitales condensées)
local function ensureCaption()
	if captionLabel then return end
	captionLabel = Theme.Text({
		Name = "IntroCaption",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromOffset(800, 80),
		Text = "",
		TextSize = Theme.TextSize.Giant,
		FontFace = Theme.Fonts.Title,
		TextWrapped = true,
		Visible = false,
		ZIndex = 10,
		Parent = Theme and Theme.GetScale and Theme.GetScale(player.PlayerGui:FindFirstChild("TideOverlay") or player.PlayerGui:FindFirstChild("TideHUD")).Parent or nil,
	})
	if captionLabel then
		captionStroke = Instance.new("UIStroke")
		captionStroke.Color = Theme.Colors.TextShadow
		captionStroke.Transparency = 0.4
		captionStroke.Thickness = 2
		captionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		captionStroke.Parent = captionLabel
	end
end

local function showCaption(text: string, duration: number, scaleAmount: number?)
	captionToken += 1
	local token = captionToken
	ensureCaption()
	if not captionLabel then return end
	captionLabel.Text = Theme.Caps(text)
	captionLabel.Visible = true
	captionLabel.TextTransparency = 1
	if captionStroke then captionStroke.Transparency = 1 end
	TweenService:Create(captionLabel, TweenInfo.new(Theme.Time.Fast, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	if captionStroke then TweenService:Create(captionStroke, TweenInfo.new(Theme.Time.Fast, Enum.EasingStyle.Quad), { Transparency = 0.4 }):Play() end
	Theme.Pop(captionLabel, scaleAmount or 0.08)
	task.delay(duration, function()
		if captionToken ~= token then return end
		TweenService:Create(captionLabel, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		if captionStroke then TweenService:Create(captionStroke, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { Transparency = 1 }):Play() end
		task.delay(Theme.Time.Normal + 0.02, function()
			if captionToken == token then
				captionLabel.Visible = false
			end
		end)
	end)
end

-------------------------------------------------------------------------------- Mouettes (effet visuel seulement, côté client)
local function spawnSeagulls(center: Vector3, count: number)
	for _, g in seagulls do
		if g.Model then g.Model:Destroy() end
	end
	table.clear(seagulls)
	for i = 1, count do
		local model = Instance.new("Model")
		model.Name = "Seagull" .. i
		local body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(1.2, 0.4, 2.5)
		body.Anchored = true
		body.CanCollide = false
		body.CanQuery = false
		body.CanTouch = false
		body.Material = Enum.Material.SmoothPlastic
		body.Color = Color3.fromRGB(200, 200, 210)
		body.Parent = model
		local wingL = Instance.new("Part")
		wingL.Name = "WingL"
		wingL.Size = Vector3.new(3, 0.1, 1.5)
		wingL.Anchored = true
		wingL.CanCollide = false
		wingL.CanQuery = false
		wingL.CanTouch = false
		wingL.Material = Enum.Material.SmoothPlastic
		wingL.Color = Color3.fromRGB(180, 180, 190)
		wingL.Parent = model
		local wingR = Instance.new("Part")
		wingR.Name = "WingR"
		wingR.Size = Vector3.new(3, 0.1, 1.5)
		wingR.Anchored = true
		wingR.CanCollide = false
		wingR.CanQuery = false
		wingR.CanTouch = false
		wingR.Material = Enum.Material.SmoothPlastic
		wingR.Color = Color3.fromRGB(180, 180, 190)
		wingR.Parent = model
		model.Parent = Fx.GetWorldFolder()
		local angle = math.rad(i * (360 / count))
		local radius = 60 + math.random() * 40
		local height = 35 + math.random() * 15
		local pos = center + Vector3.new(math.cos(angle) * radius, height, math.sin(angle) * radius)
		model:PivotTo(CFrame.new(pos, center))
		table.insert(seagulls, {
			Model = model,
			Center = center,
			Radius = radius,
			Height = height,
			Angle = angle,
			Speed = 0.5 + math.random() * 0.3,
			FlapPhase = math.random() * math.pi * 2,
		})
	end
end

local function animateSeagulls(dt: number, flee: boolean)
	for _, g in seagulls do
		if not g.Model or not g.Model.Parent then continue end
		g.Angle += g.Speed * dt * (flee and 2.5 or 1)
		if flee then
			g.Radius += 40 * dt
			g.Height += 15 * dt
		end
		local pos = g.Center + Vector3.new(math.cos(g.Angle) * g.Radius, g.Height, math.sin(g.Angle) * g.Radius)
		local lookAt = g.Center
		if flee then lookAt = pos + Vector3.new(math.cos(g.Angle), 0, math.sin(g.Angle)) * 50 end
		local cf = CFrame.lookAt(pos, lookAt)
		local flap = math.sin(os.clock() * 8 + g.FlapPhase) * 0.3
		g.Model:PivotTo(cf)
		local body = g.Model:FindFirstChild("Body")
		local wingL = g.Model:FindFirstChild("WingL")
		local wingR = g.Model:FindFirstChild("WingR")
		if body then body.CFrame = cf end
		if wingL then wingL.CFrame = cf * CFrame.Angles(flap, 0, -0.5) * CFrame.new(-1.5, 0, 0) end
		if wingR then wingR.CFrame = cf * CFrame.Angles(-flap, 0, 0.5) * CFrame.new(1.5, 0, 0) end
	end
end

local function clearSeagulls()
	for _, g in seagulls do
		if g.Model then g.Model:Destroy() end
	end
	table.clear(seagulls)
end

-------------------------------------------------------------------------------- Phase: AERIAL (0-1.5s) - géré par LoadingScreen, on attend juste
-- Mais on peut faire un plan aérien si le LoadingScreen n'en fait pas

-------------------------------------------------------------------------------- Phase: FADE (1.5-3s) - fondu au noir puis caméra derrière joueur
local function runFadePhase()
	local center = Config.HubSpawn
	if Store then
		local state = Store.Get()
		if state and state.plot and state.plot > 0 then
			local plot = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Plots") and Workspace.Map.Plots:FindFirstChild("Plot" .. state.plot)
			if plot then
				local spawnPos = plot:GetAttribute("SpawnPos")
				if typeof(spawnPos) == "Vector3" then
					center = spawnPos
				end
			end
		end
	end

	-- Fondu au noir 0.4s
	local fadeGui = Instance.new("ScreenGui")
	fadeGui.Name = "TR_IntroFade"
	fadeGui.IgnoreGuiInset = true
	fadeGui.ScreenInsets = Enum.ScreenInsets.None
	fadeGui.DisplayOrder = 200
	fadeGui.ResetOnSpawn = false
	fadeGui.Parent = player.PlayerGui
	local black = Instance.new("Frame")
	black.Size = UDim2.fromScale(1, 1)
	black.BackgroundColor3 = Color3.new(0, 0, 0)
	black.BackgroundTransparency = 1
	black.Parent = fadeGui

	TweenService:Create(black, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { BackgroundTransparency = 0 }):Play()
	task.wait(0.4)

	-- Caméra derrière le joueur
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		camera.CameraType = Enum.CameraType.Scriptable
		local lookAt = root.Position + Vector3.new(0, 1.5, 0)
		local camPos = root.Position - root.CFrame.LookVector * INTRO_CAMERA_BACK + Vector3.new(0, INTRO_CAMERA_HEIGHT, 0)
		camera.CFrame = CFrame.lookAt(camPos, lookAt)
	end

	-- Fondu depuis le noir
	TweenService:Create(black, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
	task.wait(0.6)
	fadeGui:Destroy()
end

-------------------------------------------------------------------------------- Phase: PLATFORM HINT (3-5.5s) - indication cross-plateforme
local function runPlatformHintPhase()
	-- Détection plateforme robuste (DECISIONS_MARCHE.md §7)
	local touchEnabled = UserInputService.TouchEnabled
	local keyboardEnabled = UserInputService.KeyboardEnabled
	local gamepadEnabled = UserInputService.GamepadEnabled

	-- Priorité : Gamepad > Touch > Keyboard
	-- Si gamepad connecté -> UI gamepad
	-- Sinon si touch seulement (pas clavier) -> UI mobile
	-- Sinon -> UI clavier/souris
	local platformType = "keyboard"
	if gamepadEnabled then
		platformType = "gamepad"
	elseif touchEnabled and not keyboardEnabled then
		platformType = "mobile"
	end

	isMobile = (platformType == "mobile")

	-- Création du label d'indication avec icône
	platformHintLabel = Instance.new("TextLabel")
	platformHintLabel.Name = "PlatformHint"
	platformHintLabel.AnchorPoint = Vector2.new(0.5, 1)
	platformHintLabel.Position = UDim2.fromScale(0.5, 0.92)
	platformHintLabel.Size = UDim2.fromOffset(700, 60)
	platformHintLabel.BackgroundTransparency = 1
	platformHintLabel.FontFace = Theme.Fonts.Title
	platformHintLabel.TextSize = Theme.TextSize.Large
	platformHintLabel.TextColor3 = Theme.Colors.Text
	platformHintLabel.TextTransparency = 1
	platformHintLabel.TextWrapped = true
	platformHintLabel.ZIndex = 10
	platformHintLabel.Parent = player.PlayerGui:FindFirstChild("TideOverlay") or player.PlayerGui:FindFirstChild("TideHUD")

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.TextShadow
	stroke.Transparency = 0.4
	stroke.Thickness = 1.5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	stroke.Parent = platformHintLabel

	-- Texte selon plateforme (DIRECTION_V2 : capitales condensées, pas d'emoji, icônes dessinées)
	-- Mobile: icône main (tap) + texte | PC: clavier + shift + clic droit | Gamepad: sticks + boutons
	local hintText = ""
	if platformType == "mobile" then
		hintText = Theme.Caps("Appuie pour avancer")
	elseif platformType == "gamepad" then
		hintText = Theme.Caps("Stick Gauche = Bouger  |  A = Sprint  |  Stick Droit = Camera")
	else
		hintText = Theme.Caps("WASD / Fleches = Bouger  |  Shift = Sprint  |  Clic Droit = Camera")
	end
	platformHintLabel.Text = hintText

	-- Animation d'apparition
	TweenService:Create(platformHintLabel, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { Transparency = 0.4 }):Play()
	Theme.Pop(platformHintLabel, 0.08)

	-- Attendre 2.5s
	task.wait(2.5)

	-- Fondu de sortie
	TweenService:Create(platformHintLabel, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
	task.delay(Theme.Time.Normal + 0.02, function()
		if platformHintLabel then platformHintLabel:Destroy() platformHintLabel = nil end
	end)
end

-------------------------------------------------------------------------------- Phase: EXPLORE (3-16s) - flèche vers créatures, le joueur attrape
local function runExplorePhase()
	-- Flèche vers le lagon / créatures les plus proches
	startArrow(function(from)
		local rect = getLagoonRect()
		if not rect then return nil end
		local x = math.clamp(from.X, rect.minX, rect.maxX)
		local z = math.clamp(from.Z, rect.minZ, rect.maxZ)
		if x == from.X and z == from.Z then return nil end
		return Vector3.new(x, rect.y, z)
	end)

	-- Mouettes apparaissent vers 7.6s (quand la première vague d'intro approche)
	task.delay(7.6 - 3.0, function()
		if introPhase ~= "explore" then return end
		local center = getLagoonCenter()
		if center then spawnSeagulls(center, 8) end
	end)

	-- Attendre que le joueur attrape des créatures (détecté via Store.WaveChanged ou Notify capture)
	-- On laisse le temps au joueur - max jusqu'à 16s
	local exploreEndTime = introStartTime + TIMELINE.EXPLORE_END
	while introPhase == "explore" and os.clock() - introStartTime < TIMELINE.EXPLORE_END do
		task.wait(0.1)
	end
	stopArrow()
end

-------------------------------------------------------------------------------- Phase: ALERT (16-20s) - mouettes fuient, mer se retire, "RUN"
local function runAlertPhase()
	local alertStartTime = os.clock()
	local alertDuration = TIMELINE.ALERT_END - TIMELINE.ALERT_START -- 4s

	-- Mouettes fuient + caméra secousse + "RUN" — tout en parallèle sur 4s
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	
	-- Afficher "RUN" immédiatement (1.5s)
	showCaption("RUN", 1.5, 0.12)

	-- Boucle 4s : mouettes fuient + caméra shake
	while introPhase == "alert" and os.clock() - alertStartTime < alertDuration do
		animateSeagulls(0.03, true)
		if root then
			local shake = Vector3.new(
				(math.random() - 0.5) * 0.4,
				(math.random() - 0.5) * 0.15,
				(math.random() - 0.5) * 0.4
			)
			local lookAt = root.Position + Vector3.new(0, 1.5, 0) + shake
			local camPos = root.Position - root.CFrame.LookVector * 10 + Vector3.new(0, 3, 0) + shake
			camera.CFrame = CFrame.lookAt(camPos, lookAt)
		end
		task.wait(0.03)
	end

	clearSeagulls()
end

-------------------------------------------------------------------------------- Phase: SPRINT (20-29s) - course vers le lagon
local function runSprintPhase()
	-- Flèche vers le lagon (barrière)
	startArrow(function(from)
		local plot = getPlotInstance()
		if not plot then return nil end
		local barrier = plot:FindFirstChild("Barrier")
		if barrier then
			local center = barrier:GetAttribute("Center")
			if typeof(center) == "Vector3" then return center end
		end
		return getLagoonCenter()
	end)

	-- Caméra suit le joueur, plus bas, tremblement léger, embruns
	local sprintEndTime = introStartTime + TIMELINE.SPRINT_END
	while introPhase == "sprint" and os.clock() < sprintEndTime do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local shake = Vector3.new(
				(math.random() - 0.5) * 0.5,
				(math.random() - 0.5) * 0.2,
				(math.random() - 0.5) * 0.5
			)
			local lookAt = root.Position + Vector3.new(0, 1.2, 0) + shake
			local camPos = root.Position - root.CFrame.LookVector * 8 + Vector3.new(0, 2.5, 0) + shake
			camera.CFrame = CFrame.lookAt(camPos, lookAt)
		end
		task.wait(0.03)
	end
	stopArrow()
end

-------------------------------------------------------------------------------- Phase: BARRIER (29-29.6s) - franchit barrière, créatures plongent, "NEXT TIDE: GOLDEN"
local function runBarrierPhase()
	-- La barrière s'enfonce (animée par B via PlotN.Barrier.Open)
	-- Les créatures du sac plongent dans les cuvettes (splash)
	-- Afficher "NEXT TIDE: GOLDEN" dès le franchissement
	showCaption("NEXT TIDE: GOLDEN", 2.5, 0.05)
	task.wait(0.6)
end

-------------------------------------------------------------------------------- Phase: WAVECRASH (29.6-31.5s) - vague s'écrase, texte final
local function runWaveCrashPhase()
	-- Texte final : "YOUR BASE. YOUR CREATURE. YOUR WAVE." (1.9s total)
	showCaption("YOUR BASE. YOUR CREATURE. YOUR WAVE.", 1.9, 0.1)

	-- Caméra shake final synchronisé sur le texte
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		local t0 = os.clock()
		while os.clock() - t0 < 1.9 do
			local shake = Vector3.new(
				(math.random() - 0.5) * 1.5,
				(math.random() - 0.5) * 0.5,
				(math.random() - 0.5) * 1.5
			)
			local lookAt = root.Position + Vector3.new(0, 1.5, 0) + shake
			local camPos = root.Position - root.CFrame.LookVector * 12 + Vector3.new(0, 5, 0) + shake
			camera.CFrame = CFrame.lookAt(camPos, lookAt)
			task.wait(0.03)
		end
	end
end

-------------------------------------------------------------------------------- Helpers monde
local function getPlotInstance(): Instance?
	if not Store then return nil end
	local state = Store.Get()
	if not state or state.plot <= 0 then return nil end
	return Util.Find(Workspace, "Map", "Plots", "Plot" .. state.plot)
end

local function getLagoonRect(): { minX: number, maxX: number, minZ: number, maxZ: number, y: number }?
	local plot = getPlotInstance()
	if not plot then return nil end
	local minX, maxX = plot:GetAttribute("MinX"), plot:GetAttribute("MaxX")
	local minZ, maxZ = plot:GetAttribute("MinZ"), plot:GetAttribute("MaxZ")
	if type(minX) ~= "number" or type(maxX) ~= "number" or type(minZ) ~= "number" or type(maxZ) ~= "number" then return nil end
	local spawnPos = plot:GetAttribute("SpawnPos")
	local y = if typeof(spawnPos) == "Vector3" then spawnPos.Y else 0
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, y = y }
end

local function getLagoonCenter(): Vector3?
	local r = getLagoonRect()
	if not r then return nil end
	return Vector3.new((r.minX + r.maxX) / 2, r.y, (r.minZ + r.maxZ) / 2)
end

-------------------------------------------------------------------------------- Input skip (Échap/Start/toucher/click = passer)
local function setupSkip()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		local t = input.UserInputType
		local k = input.KeyCode
		-- Touch, click, any keyboard key, gamepad button, OR specifically Escape/Start
		if t == Enum.UserInputType.Touch 
			or t == Enum.UserInputType.MouseButton1 
			or t == Enum.UserInputType.Keyboard 
			or t == Enum.UserInputType.Gamepad1
			or k == Enum.KeyCode.Escape
			or k == Enum.KeyCode.ButtonStart then
			skipRequested = true
		end
	end)
end

-------------------------------------------------------------------------------- Séquence principale
function CameraIntro.Play(callback)
	onComplete = callback
	introStartTime = os.clock()
	introPhase = "aerial"
	setupSkip()

	-- Vérifier reducedMotion
	if Settings and Settings.Get("reducedMotion") then
		camera.CameraType = Enum.CameraType.Custom
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then camera.CameraSubject = humanoid end
		if onComplete then onComplete() end
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable

	-- Phase AERIAL : plan aérien île couchant (0-1.5s)
	-- Le LoadingScreen a déjà fait le plan aérien, on attend juste
	local aerialEndTime = introStartTime + TIMELINE.AERIAL_END
	while introPhase == "aerial" and os.clock() < aerialEndTime and not skipRequested do
		task.wait(0.03)
	end
	if skipRequested then goto finish end

	introPhase = "fade"
	runFadePhase()
	if skipRequested then goto finish end

	-- Phase EXPLORE : 3-16s (flèche vers créatures, joueur attrape 2-3)
	-- Le hint cross-platform (3-5.5s) tourne EN PARALLÈLE au début d'explore
	introPhase = "explore"
	local exploreStartTime = os.clock()
	
	-- Lancer le hint cross-platform en tâche parallèle (3-5.5s)
	task.spawn(function()
		task.wait(3.0 - (os.clock() - introStartTime)) -- attendre jusqu'à 3s absolu
		if introPhase == "explore" and not skipRequested then
			runPlatformHintPhase()
		end
	end)
	
	runExplorePhase() -- bloque jusqu'à 16s ou skip
	if skipRequested then goto finish end

	-- Phase ALERT : 16-20s (mouettes fuient, mer recule, "RUN")
	introPhase = "alert"
	runAlertPhase()
	if skipRequested then goto finish end

	-- Phase SPRINT : 20-29s (course vers lagon, flèche barrière)
	introPhase = "sprint"
	runSprintPhase()
	if skipRequested then goto finish end

	-- Phase BARRIER : 29-29.6s (franchit barrière, créatures plongent)
	introPhase = "barrier"
	runBarrierPhase()
	if skipRequested then goto finish end

	-- Phase WAVECRASH : 29.6-31.5s (vague s'écrase, texte final)
	introPhase = "wavecrash"
	runWaveCrashPhase()

::finish::
	-- Nettoyage
	stopArrow()
	clearSeagulls()
	if captionLabel then captionLabel:Destroy() end
	if platformHintLabel then platformHintLabel:Destroy() platformHintLabel = nil end
	camera.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then camera.CameraSubject = humanoid end

	if onComplete then
		onComplete()
		onComplete = nil
	end
	introPhase = "done"
end

function CameraIntro.Init(ctx)
	Util, Theme, Fx, Settings, Config = ctx.Util, ctx.Theme, ctx.Fx, ctx.Settings, ctx.Config
	Hud = ctx.Hud
	Store = ctx.Store
end

function CameraIntro.Cleanup()
	stopArrow()
	clearSeagulls()
	if captionLabel then captionLabel:Destroy() captionLabel = nil end
	if arrowModel then arrowModel:Destroy() arrowModel = nil end
end

return CameraIntro