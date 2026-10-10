-- Feel : ressenti et camera maison (VISION_TON §3 « Ressenti et camera », §6.1), controles standards gardes.
--   - FOV dynamique : petite poussee en courant vite, plus en monture, plus encore en surf ;
--   - vague : grondement de camera qui monte quand le front approche du joueur, choc et son quand elle s'ecrase ;
--   - surf (attribut joueur Surfing, Giant pendant la vague) : vrai moment, bandeau SURF + son ;
--   - curseur PC maison si C fournit Assets.UI.Cursor (StringValue avec l'id de l'image).
-- « Reduire les animations » : FOV fixe, aucune secousse.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Feel = {}

local BASE_FOV = 70
local SPRINT_FOV = 5 -- en plus a pleine vitesse
local MOUNT_FOV = 4
local SURF_FOV = 10
local FOV_SPEED = 6 -- lissage (1/s)
local RUN_SPEED_REF = 30 -- studs/s pour la poussee complete
local RUMBLE_RANGE = 140 -- studs : distance au front ou la camera commence a trembler
local IMPACT_RANGE = 220 -- studs : distance a laquelle on sent le choc

local Util, Theme, Store, Fx, Sfx, Settings, Hud
local player = Players.LocalPlayer
local fov = BASE_FOV
local surfing = false
local surfLoop = nil
local impactCycle = -1

local function updateFov(dt: number)
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType == Enum.CameraType.Scriptable then
		return -- l'intro pilote la camera
	end
	local target = BASE_FOV
	if not Settings.Get("reducedMotion") then
		local root = Util.LocalRoot(player)
		if root then
			local v = root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			target += SPRINT_FOV * math.clamp((speed - 16) / (RUN_SPEED_REF - 16), 0, 1)
		end
		local mount = player:GetAttribute("Mount")
		if type(mount) == "string" and mount ~= "" then
			target += MOUNT_FOV
		end
		if surfing then
			target += SURF_FOV
		end
	end
	fov += (target - fov) * math.clamp(dt * FOV_SPEED, 0, 1)
	if math.abs(cam.FieldOfView - fov) > 0.05 then
		cam.FieldOfView = fov
	end
end

-- Grondement : plus le front est proche du joueur, plus la camera tremble (Fx coupe tout en reduit)
-- Distance sur l'axe de la vague (N/E/S/O), pas sur Z.
local function updateWave()
	local root = Util.LocalRoot(player)
	if not root then
		Fx.SetRumble(0)
		return
	end
	local distance = Store.WaveDistanceTo(root.Position)
	if distance == nil then
		Fx.SetRumble(0)
		return
	end
	local wave = Store.GetWave()
	if wave.phase == "wave" then
		Fx.SetRumble(0.55 * math.clamp(1 - distance / RUMBLE_RANGE, 0, 1))
	else
		Fx.SetRumble(0)
	end
end

local function onWave(wave, prev)
	-- la vague s'ecrase sur la limite des lagons : debut du reflux
	if wave.phase == "recede" and prev and prev.phase == "wave" and impactCycle ~= wave.cycle then
		impactCycle = wave.cycle
		local root = Util.LocalRoot(player)
		if root then
			local distance = Store.WaveDistanceTo(root.Position) or math.huge
			local k = math.clamp(1 - distance / IMPACT_RANGE, 0, 1)
			if k > 0 then
				Fx.Shake(0.7 * k)
			end
			Sfx.Play("waveImpact", { position = Store.WaveFrontPoint(4) or root.Position })
		end
	end
	if wave.phase ~= "wave" then
		Fx.SetRumble(0)
	end
end

local function setSurfing(on: boolean)
	if on == surfing then
		return
	end
	surfing = on
	if on then
		-- vrai moment : bandeau + son
		Hud.ShowAlert("Surf", { icon = "wave", color = Theme.Colors.Lagoon, duration = 3 })
		Sfx.Play("surf")
		surfLoop = Sfx.Loop("surfLoop", 1)
	elseif surfLoop then
		surfLoop:Stop(0.6)
		surfLoop = nil
	end
end

local function applyCursor()
	local node = Util.Find(ReplicatedStorage, "Assets", "UI", "Cursor")
	if node and node:IsA("StringValue") and node.Value ~= "" then
		UserInputService.MouseIcon = node.Value
	end
end

function Feel.Init(ctx)
	Util, Theme, Fx, Sfx, Settings, Hud = ctx.Util, ctx.Theme, ctx.Fx, ctx.Sfx, ctx.Settings, ctx.Hud
end

function Feel.Start(ctx)
	Store = ctx.Store
	Store.WaveChanged:Connect(onWave)
	player:GetAttributeChangedSignal("Surfing"):Connect(function()
		setSurfing(player:GetAttribute("Surfing") == true)
	end)
	RunService.RenderStepped:Connect(function(dt)
		updateFov(dt)
		updateWave()
	end)
	applyCursor()
end

return Feel
