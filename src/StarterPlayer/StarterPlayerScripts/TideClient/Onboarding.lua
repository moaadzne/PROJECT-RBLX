-- Onboarding (GDD §1.1, DIRECTION_V2) :
-- Les 30 premières secondes sont gérées par CameraIntro (séquence cinématique complète).
-- Après 31.5s : HUD apparaît, une flèche guide vers la tour la plus proche (calme seulement).
-- ZÉRO texte explicatif. Flèche unique. PAS de HUD avant 31.5s.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Onboarding = {}

local TOWER_HINT_TIME = 12
local HUD_FALLBACK = 120 -- filet de sécurité : HUD forcé au bout de 2 min

local Util, Theme, Fx, Store, Hud, Settings, Config
local player = Players.LocalPlayer
local introDone = false
local firstWaveDone = false

-------------------------------------------------------------- Reperes du monde
local function plotInstance(): Instance?
	local state = Store.Get()
	if not state or state.plot <= 0 then
		return nil
	end
	return Util.Find(workspace, "Map", "Plots", "Plot" .. state.plot)
end

local function nearestTower(from: Vector3): Vector3?
	local towers = Util.Find(workspace, "Map", "Towers")
	if not towers then return nil end
	local best, bestDist = nil, math.huge
	for _, tower in towers:GetChildren() do
		local center = tower:GetAttribute("Center")
		if typeof(center) == "Vector3" then
			local d = (center - from).Magnitude
			if d < bestDist then best, bestDist = center, d end
		end
	end
	return best
end

-------------------------------------------------------------- Deroulement post-intro
-- Contrat v2 : state.intro = "intro" -> "golden" -> "done"
local function isNewPlayer(state): boolean
	return state.intro == "intro"
end

local function waitLoaded()
	local state = Store.Get()
	local t0 = os.clock()
	while not (state and state.loaded) and os.clock() - t0 < 20 do
		task.wait(0.2)
		state = Store.Get()
	end
	return if state and state.loaded then state else nil
end

local function waitIntro()
	while not introDone do task.wait(0.1) end
end

-- Après la 1re vague : HUD en fondu, puis flèche vers la tour la plus proche (pendant le calme)
local function finishFirstWave(promiseGolden: boolean)
	if firstWaveDone then return end
	firstWaveDone = true
	waitIntro()
	if Hud then Hud.SetVisible(true, true) end
	task.wait(0.6)
	-- La promesse Golden n'est affichée que si le serveur l'annonce vraiment
	-- (le texte "NEXT TIDE: GOLDEN" a déjà été montré par CameraIntro à 29.6s)
	-- On ne remet pas de texte ici pour éviter la redondance
	task.wait(0.8)
	-- Flèche vers la tour la plus proche (uniquement pendant le calme)
	startArrow(function(from)
		local wave = Store.GetWave()
		if wave.phase ~= "calm" then return nil end
		return nearestTower(from)
	end)
	task.delay(TOWER_HINT_TIME, stopArrow)
end

local function goldenNext(wave): boolean
	local state = Store.Get()
	return wave.tide == "Golden" or (state ~= nil and state.intro ~= "done")
end

local function guideNewPlayer()
	local sawWave = false
	local conn
	local function onWave(wave)
		if firstWaveDone then return end
		if wave.phase == "warning" or wave.phase == "wave" then
			if not sawWave then sawWave = true end
		elseif sawWave then
			if conn then conn:Disconnect() end
			task.spawn(finishFirstWave, goldenNext(wave))
		end
	end
	conn = Store.WaveChanged:Connect(onWave)
	onWave(Store.GetWave())
	-- Filet de sécurité : le HUD arrive quoi qu'il se passe
	task.delay(HUD_FALLBACK, function()
		if not firstWaveDone then
			if conn then conn:Disconnect() end
			finishFirstWave(false)
		end
	end)
end

-------------------------------------------------------------- Flèche au sol (réutilisée post-intro)
local arrowModel: Model
local arrowParts: { BasePart } = {}
local arrowConn: RBXScriptConnection? = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local CHEVRONS = 3
local ARROW_AHEAD = 8
local ARROW_SPACING = 1.6
local ARROW_HIDE_NEAR = 4
local PULSE_HZ = 1.5
local ARM_LEFT = CFrame.lookAt(Vector3.new(-0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
local ARM_RIGHT = CFrame.lookAt(Vector3.new(0.45, 0, -0.1), Vector3.new(0, 0, -0.7))
local ARM_SIZE = Vector3.new(0.45, 0.15, 1.5)

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
	rayParams.FilterDescendantsInstances = { player.Character, arrowModel }
	local hit = workspace:Raycast(pos + Vector3.new(0, 6, 0), Vector3.new(0, -40, 0), rayParams)
	return if hit then hit.Position.Y else pos.Y - 3
end

local function hideArrow()
	if arrowModel then arrowModel.Parent = nil end
end

local function stopArrow()
	if arrowConn then arrowConn:Disconnect() arrowConn = nil end
	hideArrow()
end

local function startArrow(getTarget: (Vector3) -> Vector3?)
	stopArrow()
	buildArrow()
	arrowConn = RunService.Heartbeat:Connect(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local target = root and getTarget(root.Position)
		if not root or not target then hideArrow() return end
		local flat = Vector3.new(target.X - root.Position.X, 0, target.Z - root.Position.Z)
		if flat.Magnitude < ARROW_HIDE_NEAR then hideArrow() return end
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
			local alpha = if reduced then 0.15 else 0.1 + 0.6 * ((clock * PULSE_HZ - i * 0.25) % 1)
			arrowParts[i * 2 - 1].Transparency = alpha
			arrowParts[i * 2].Transparency = alpha
		end
		if not arrowModel.Parent then arrowModel.Parent = Fx.GetWorldFolder() end
	end)
end

-------------------------------------------------------------- Démarrage
function Onboarding.Init(ctx)
	Util, Theme, Fx, Settings, Config = ctx.Util, ctx.Theme, ctx.Fx, ctx.Settings, ctx.Config
	Hud = ctx.Hud
	if Hud then Hud.Hold() end
end

function Onboarding.Start(ctx)
	Store = ctx.Store

	-- 1. Lancer la séquence cinématique de 30s (CameraIntro)
	local CameraIntro = ctx.CameraIntro
	task.spawn(function()
		if CameraIntro and CameraIntro.Play then
			CameraIntro.Play(function()
				introDone = true
			end)
		else
			warn("[Onboarding] CameraIntro manquant, fallback immédiat")
			introDone = true
		end
	end)

	-- 2. Attendre chargement + détecter nouveau joueur
	local state = waitLoaded()
	if state and isNewPlayer(state) then
		guideNewPlayer()
	else
		waitIntro()
		if Hud then Hud.SetVisible(true, true) end
	end
end

return Onboarding