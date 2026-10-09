-- Onboarding (GDD §1 ter et §8) :
--   1. arrivee : la camera descend du ciel sur le lagon du joueur (vue large tant que ca charge, tap = passer) ;
--   2. nouveau joueur : aucun HUD jusqu'a la fin de sa 1re vague, puis fondu ; sinon HUD apres la descente ;
--   3. pendant la 1re vague : fleche lumineuse au sol vers le lagon (pas de texte) ;
--   4. apres : une ligne de texte, puis la fleche montre la tour la plus proche.
-- La vague d'intro (wave.intro, 18 s, sans capture) et la marée Golden personnelle sont cote serveur (A).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Onboarding = {}

local INTRO_HEIGHT = 110 -- studs au-dessus du lagon
local INTRO_BACK = 70 -- recul cote terre (+Z) : on voit le lagon, la plage et la mer
local INTRO_TIME = 2.4
local INTRO_WAIT_MAX = 8 -- s en vue large au plus (chargement, streaming)
local LOADED_WAIT = 20
local HUD_FALLBACK = 120 -- un nouveau joueur voit le HUD au plus tard 2 min apres l'arrivee
local CAPTION_TIME = 4
local TOWER_HINT_TIME = 12
local ARROW_AHEAD = 6 -- studs devant le joueur
local ARROW_SPACING = 1.6
local ARROW_HIDE_NEAR = 4
local CHEVRONS = 3
local PULSE_HZ = 1.5
-- bras d'un chevron (repere local, l'avant est -Z) : pointe en (0, 0, -0.7), extremites en (+-0.9, 0, 0.5)
local ARM_LEFT = CFrame.lookAt(Vector3.new(-0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
local ARM_RIGHT = CFrame.lookAt(Vector3.new(0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
local ARM_SIZE = Vector3.new(0.45, 0.15, 1.5)

local Util, Theme, Fx, Store, Hud, Settings, Config
local player = Players.LocalPlayer
local introDone = false
local firstWaveDone = false

---------------------------------------------------------------- Reperes du monde
local function plotInstance(): Instance?
	local state = Store.Get()
	if not state or state.plot <= 0 then
		return nil
	end
	return Util.Find(workspace, "Map", "Plots", "Plot" .. state.plot)
end

-- Rectangle du lagon (attributs MinX/MaxX/MinZ/MaxZ de la base)
local function lagoonRect(): { minX: number, maxX: number, minZ: number, maxZ: number, y: number }?
	local plot = plotInstance()
	if not plot then
		return nil
	end
	local minX, maxX = plot:GetAttribute("MinX"), plot:GetAttribute("MaxX")
	local minZ, maxZ = plot:GetAttribute("MinZ"), plot:GetAttribute("MaxZ")
	if type(minX) ~= "number" or type(maxX) ~= "number" or type(minZ) ~= "number" or type(maxZ) ~= "number" then
		return nil
	end
	local spawnPos = plot:GetAttribute("SpawnPos")
	local y = if typeof(spawnPos) == "Vector3" then spawnPos.Y else 0
	return { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ, y = y }
end

local function lagoonCenter(): Vector3?
	local r = lagoonRect()
	if not r then
		return nil
	end
	return Vector3.new((r.minX + r.maxX) / 2, r.y, (r.minZ + r.maxZ) / 2)
end

-- Point du lagon le plus proche du joueur (nil s'il y est deja)
local function lagoonTarget(from: Vector3): Vector3?
	local r = lagoonRect()
	if not r then
		return nil
	end
	local x = math.clamp(from.X, r.minX, r.maxX)
	local z = math.clamp(from.Z, r.minZ, r.maxZ)
	if x == from.X and z == from.Z then
		return nil
	end
	return Vector3.new(x, r.y, z)
end

local function nearestTower(from: Vector3): Vector3?
	local towers = Util.Find(workspace, "Map", "Towers")
	if not towers then
		return nil
	end
	local best, bestDist = nil, math.huge
	for _, tower in towers:GetChildren() do
		local center = tower:GetAttribute("Center")
		if typeof(center) == "Vector3" then
			local d = (center - from).Magnitude
			if d < bestDist then
				best, bestDist = center, d
			end
		end
	end
	return best
end

---------------------------------------------------------------- Camera d'arrivee
local function wideShot(center: Vector3): CFrame
	return CFrame.lookAt(center + Vector3.new(0, INTRO_HEIGHT, INTRO_BACK), center)
end

local function runIntro()
	local cam = workspace.CurrentCamera
	if not cam or Settings.Get("reducedMotion") then
		return
	end
	local skip = false
	local inputConn = UserInputService.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Keyboard or t == Enum.UserInputType.Gamepad1 then
			skip = true
		end
	end)
	local shot = Instance.new("CFrameValue")
	shot.Value = wideShot(lagoonCenter() or Config.HubSpawn)
	cam.CameraType = Enum.CameraType.Scriptable
	-- ecrit chaque frame apres les scripts camera de Roblox : rien ne peut reprendre la main pendant l'intro
	RunService:BindToRenderStep("TR_Intro", Enum.RenderPriority.Camera.Value + 2, function()
		cam.CFrame = shot.Value
	end)

	-- vue large tant que le lagon ou le personnage manquent (chargement masque, jamais d'ecran noir)
	local waitStart = os.clock()
	local framed = lagoonCenter() ~= nil
	while not skip and os.clock() - waitStart < INTRO_WAIT_MAX do
		local center = lagoonCenter()
		if center and not framed then
			framed = true
			Util.Tween(shot, 0.8, { Value = wideShot(center) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		end
		if center and Util.LocalRoot(player) then
			break
		end
		task.wait(0.1)
	end

	-- descente jusque derriere le personnage
	local root = Util.LocalRoot(player)
	if not skip and root then
		local look = root.Position + Vector3.new(0, 1.5, 0)
		local endPos = root.Position - root.CFrame.LookVector * 12 + Vector3.new(0, 5, 0)
		local tween = Util.Tween(shot, INTRO_TIME, { Value = CFrame.lookAt(endPos, look) }, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local t0 = os.clock()
		while not skip and os.clock() - t0 < INTRO_TIME do
			task.wait()
		end
		tween:Cancel()
	end

	RunService:UnbindFromRenderStep("TR_Intro")
	inputConn:Disconnect()
	shot:Destroy()
	cam.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		cam.CameraSubject = humanoid
	end
end

---------------------------------------------------------------- Fleche au sol
local arrowModel: Model
local arrowParts: { BasePart } = {}
local arrowConn: RBXScriptConnection? = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function buildArrow()
	arrowModel = Instance.new("Model")
	arrowModel.Name = "TR_GuideArrow"
	for _ = 1, CHEVRONS * 2 do
		local p = Instance.new("Part")
		p.Name = "Chevron"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Theme.Colors.Gold
		p.Size = ARM_SIZE
		p.Parent = arrowModel
		table.insert(arrowParts, p)
	end
end

local function groundY(pos: Vector3): number
	rayParams.FilterDescendantsInstances = { player.Character, arrowModel } :: { Instance }
	local hit = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
	return if hit then hit.Position.Y else pos.Y - 3
end

local function hideArrow()
	arrowModel.Parent = nil
end

local function stopArrow()
	if arrowConn then
		arrowConn:Disconnect()
		arrowConn = nil
	end
	hideArrow()
end

-- getTarget(depuis) -> point a montrer, ou nil pour cacher la fleche
local function startArrow(getTarget: (Vector3) -> Vector3?)
	stopArrow()
	arrowConn = RunService.Heartbeat:Connect(function()
		local root = Util.LocalRoot(player)
		local target = root and getTarget(root.Position)
		if not root or not target then
			hideArrow()
			return
		end
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		if flat.Magnitude < ARROW_HIDE_NEAR then
			hideArrow()
			return
		end
		local dir = flat.Unit
		local base = root.Position + dir * ARROW_AHEAD
		local ground = Vector3.new(base.X, groundY(base) + 0.25, base.Z)
		local origin = CFrame.lookAt(ground, ground + dir)
		local reduced = Settings.Get("reducedMotion")
		local clock = os.clock()
		for i = 1, CHEVRONS do
			local c = origin * CFrame.new(0, 0, -(i - 1) * ARROW_SPACING)
			arrowParts[i * 2 - 1].CFrame = c * ARM_LEFT
			arrowParts[i * 2].CFrame = c * ARM_RIGHT
			-- vague de lumiere de l'arriere vers l'avant (1,5 Hz)
			local alpha = if reduced then 0.15 else 0.1 + 0.6 * ((clock * PULSE_HZ - i * 0.25) % 1)
			arrowParts[i * 2 - 1].Transparency = alpha
			arrowParts[i * 2].Transparency = alpha
		end
		if not arrowModel.Parent then
			arrowModel.Parent = Fx.GetWorldFolder()
		end
	end)
end

---------------------------------------------------------------- Texte unique
local captionLabel: TextLabel
local captionStroke: UIStroke
local captionToken = 0

local function caption(text: string, duration: number)
	captionToken += 1
	local token = captionToken
	captionLabel.Text = text
	captionLabel.Visible = true
	captionLabel.TextTransparency = 1
	captionStroke.Transparency = 1
	Util.Tween(captionLabel, 0.4, { TextTransparency = 0 }, Enum.EasingStyle.Quad)
	Util.Tween(captionStroke, 0.4, { Transparency = 0 }, Enum.EasingStyle.Quad)
	Theme.Pop(captionLabel, 0.12)
	task.delay(duration, function()
		if captionToken ~= token then
			return
		end
		Util.Tween(captionLabel, 0.4, { TextTransparency = 1 }, Enum.EasingStyle.Quad)
		Util.Tween(captionStroke, 0.4, { Transparency = 1 }, Enum.EasingStyle.Quad)
		task.delay(0.42, function()
			if captionToken == token then
				captionLabel.Visible = false
			end
		end)
	end)
end

---------------------------------------------------------------- Deroulement
-- Contrat v2 : state.intro = "intro" (sequence en cours) -> "golden" (sa maree Golden perso) -> "done"
local function isNewPlayer(state): boolean
	return state.intro == "intro"
end

local function waitLoaded()
	local state = Store.Get()
	local t0 = os.clock()
	while not (state and state.loaded) and os.clock() - t0 < LOADED_WAIT do
		task.wait(0.2)
		state = Store.Get()
	end
	return if state and state.loaded then state else nil
end

local function waitIntro()
	while not introDone do
		task.wait(0.1)
	end
end

-- Fin de la 1re vague : HUD en fondu, une phrase, puis la fleche vers la tour la plus proche
local function finishFirstWave(promiseGolden: boolean)
	if firstWaveDone then
		return
	end
	firstWaveDone = true
	stopArrow()
	waitIntro()
	if Hud then
		Hud.SetVisible(true, true)
	end
	task.wait(0.6)
	-- la promesse doree n'est affichee que si le serveur l'annonce vraiment
	caption(if promiseGolden then "They grow. The next tide is GOLDEN!" else "They grow while you play!", CAPTION_TIME)
	task.wait(CAPTION_TIME + 0.8)
	caption("Towers keep you safe too.", CAPTION_TIME)
	startArrow(function(from)
		local wave = Store.GetWave()
		if wave.phase ~= "calm" then
			return nil
		end
		return nearestTower(from)
	end)
	task.delay(TOWER_HINT_TIME, stopArrow)
end

-- Le contrat garantit une maree Golden personnelle apres la vague d'intro : la promesse est tenue
local function goldenNext(wave): boolean
	local state = Store.Get()
	return wave.tide == "Golden" or (state ~= nil and state.intro ~= "done")
end

local function guideNewPlayer()
	local sawWave = false
	local conn
	local function onWave(wave)
		if firstWaveDone then
			return
		end
		if wave.phase == "warning" or wave.phase == "wave" then
			if not sawWave then
				sawWave = true
				startArrow(lagoonTarget)
			end
		elseif sawWave then
			-- la vague est passee (recede ou calm)
			if conn then
				conn:Disconnect()
			end
			task.spawn(finishFirstWave, goldenNext(wave))
		end
	end
	conn = Store.WaveChanged:Connect(onWave)
	onWave(Store.GetWave())
	-- filet de securite : le HUD arrive quoi qu'il se passe
	task.delay(HUD_FALLBACK, function()
		if not firstWaveDone then
			if conn then
				conn:Disconnect()
			end
			finishFirstWave(false)
		end
	end)
end

---------------------------------------------------------------- Demarrage
function Onboarding.Init(ctx)
	Util, Theme, Fx, Settings, Config = ctx.Util, ctx.Theme, ctx.Fx, ctx.Settings, ctx.Config
	Hud = ctx.Hud
	if Hud then
		Hud.Hold()
	end
	buildArrow()
	captionLabel = Theme.Text({
		Name = "Caption",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.72),
		Size = UDim2.fromOffset(760, 64),
		Text = "",
		TextSize = Theme.TextSize.Huge,
		FontFace = Theme.Fonts.Title,
		TextWrapped = true,
		Visible = false,
		ZIndex = 8,
		Parent = ctx.Root,
	})
	captionStroke = captionLabel:FindFirstChildOfClass("UIStroke") :: UIStroke
	captionStroke.Thickness = 3
end

function Onboarding.Start(ctx)
	Store = ctx.Store
	task.spawn(function()
		local ok, err = pcall(runIntro)
		if not ok then
			warn("[Onboarding] intro : " .. tostring(err))
			RunService:UnbindFromRenderStep("TR_Intro")
			local cam = workspace.CurrentCamera
			if cam then
				cam.CameraType = Enum.CameraType.Custom
			end
		end
		introDone = true
	end)
	local state = waitLoaded()
	if state and isNewPlayer(state) then
		guideNewPlayer()
	else
		waitIntro()
		if Hud then
			Hud.SetVisible(true, true)
		end
	end
end

return Onboarding
