-- MountService : monture (GDD 4.6) et verification de la vitesse reelle.
-- Mecanisme choisi pour resister aux exploits de vitesse : pas de VehicleSeat (le client piloterait sa vitesse).
-- La creature est un clone soude au HumanoidRootPart (Attachment "Saddle" de C), HipHeight releve,
-- et la vitesse passe uniquement par Humanoid.WalkSpeed, fixe par le serveur.
-- En plus, le serveur mesure la distance parcourue sur 1 s et ramene en arriere tout joueur trop rapide.
-- Une Giant n'est jamais prise par la vague : elle la surfe (attribut Surfing, animation cote client).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local WaveService = require(Services.WaveService)
local CreatureFactory = require(Services.CreatureFactory)

local MountService = {}

local MOUNT_NAME = "TR_Mount"
local R6_LEGS = 2
local CHECK_TICK = 1
local GUARD_TICK = 0.1

local M, G = Config.Mount, Config.SpeedGuard
local MIN_STAGE = Config.StageIndex(M.minStage)

local originalHip = {} -- [player] = HipHeight avant la monture
local history = {} -- [player] = { {t, pos}, ... } positions horizontales recentes

local function now()
	return os.time()
end

local function removeVisual(player)
	local character = player.Character
	local visual = character and character:FindFirstChild(MOUNT_NAME)
	if visual then
		visual:Destroy()
	end
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and originalHip[player] then
		humanoid.HipHeight = originalHip[player]
	end
	originalHip[player] = nil
end

-- Clone soude sous le joueur : la selle (Saddle) vient a la hauteur des hanches
local function buildVisual(player, creature, stage)
	removeVisual(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local model = CreatureFactory.Create(creature.id, root.Position, {
		mutation = creature.mut,
		stage = stage,
		zone = 0,
		bob = 0,
		beacon = false,
		uid = creature.uid,
		royal = creature.royal,
		noSpin = true,
	})
	if not model then
		return false
	end
	model.Name = MOUNT_NAME
	pcall(function()
		model:ScaleTo(Config.Stages[stage].scale)
	end)
	local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	if not primary then
		model:Destroy()
		return false
	end
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
			if part ~= primary then
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = primary
				weld.Part1 = part
				weld.Parent = part
			end
		end
	end

	local pivot = model:GetPivot()
	local boxCf, boxSize = model:GetBoundingBox()
	local bottomY = boxCf.Position.Y - boxSize.Y / 2
	local saddle = primary:FindFirstChild("Saddle")
	local saddleWorld = if saddle and saddle:IsA("Attachment")
		then saddle.WorldCFrame
		else CFrame.new(boxCf.Position + Vector3.new(0, boxSize.Y / 2, 0)) * pivot.Rotation
	local saddleHeight = saddleWorld.Position.Y - bottomY
	-- la selle se pose sur les hanches du joueur, dans sa direction
	local hip = root.CFrame * CFrame.new(0, -root.Size.Y / 2, 0)
	model:PivotTo(hip * pivot:ToObjectSpace(saddleWorld):Inverse())
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = primary
	weld.Parent = primary

	originalHip[player] = humanoid.HipHeight
	humanoid.HipHeight = if humanoid.RigType == Enum.HumanoidRigType.R15
		then saddleHeight
		else math.max(0, saddleHeight - R6_LEGS)
	model.Parent = character
	return true
end

local function setAttributes(player, profile, creature, stage)
	player:SetAttribute("Mount", creature and creature.id or "")
	player:SetAttribute("MountStage", stage or 0)
	local wave = Net.GetWave()
	player:SetAttribute("Surfing", profile.surfing and wave ~= nil and wave.phase == "wave")
end

function MountService.Dismount(player)
	local profile = DataService.Get(player)
	if not profile or profile.mountUid == "" then
		return
	end
	profile.mountUid = ""
	profile.mountStage = nil
	profile.mountMult = 1
	profile.surfing = false
	removeVisual(player)
	if player.Parent then
		setAttributes(player, profile, nil, nil)
		PlotService.ApplySpeed(player)
		PlotService.RenderDisplay(player)
		DataService.MarkDirty(player)
	end
end

local function speedMult(profile, stage)
	local vip = profile.passes.VIPRider and Config.Shop.Passes.VIPRider.mountSpeedBonus or 0
	return (M.speedMult[Config.Stages[stage].id] or 1) * (1 + vip)
end

local function applyMount(player, profile, creature, stage)
	profile.mountUid = creature.uid
	profile.mountStage = stage
	profile.mountMult = speedMult(profile, stage)
	profile.surfing = M.giantSurfs and stage == #Config.Stages
	if not buildVisual(player, creature, stage) then
		profile.mountUid = ""
		profile.mountStage = nil
		profile.mountMult = 1
		profile.surfing = false
		return false
	end
	setAttributes(player, profile, creature, stage)
	PlotService.ApplySpeed(player)
	PlotService.RenderDisplay(player)
	DataService.MarkDirty(player)
	return true
end

local function mount(player, uid)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	if uid == nil then
		MountService.Dismount(player)
		return true
	end
	if type(uid) ~= "string" then
		return false, "BadRequest"
	end
	if profile.carrying then
		return false, "Carrying"
	end
	local d = profile.data
	local creature = Stats.FindCreature(d, uid)
	if not creature then
		return false, "NotMountable"
	end
	if not M.species[creature.id] then
		return false, "NotMountable"
	end
	if profile.carriedOut[uid] then
		return false, "Busy"
	end
	local stage = Stats.Stage(creature, now(), Stats.GrowthSpeed(d))
	if stage < MIN_STAGE then
		return false, "TooYoung"
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false, "Busy"
	end
	if profile.mountUid ~= "" then
		MountService.Dismount(player)
	end
	if not applyMount(player, profile, creature, stage) then
		return false, "Busy"
	end
	return true
end

-- Chaque seconde : la monture grandit (Adult -> Giant), ou elle a disparu (creature ou visuel)
local function checkMounts()
	for player, profile in DataService.All() do
		if profile.loaded and not profile.leaving and profile.mountUid ~= "" then
			local creature = Stats.FindCreature(profile.data, profile.mountUid)
			local character = player.Character
			if not creature or not (character and character:FindFirstChild(MOUNT_NAME)) then
				MountService.Dismount(player)
			else
				local stage = Stats.Stage(creature, now(), Stats.GrowthSpeed(profile.data))
				if stage ~= profile.mountStage then
					applyMount(player, profile, creature, stage)
				end
			end
		end
	end
end

-- Verification de vitesse -------------------------------------------------------------

local function allowedSpeed(profile)
	local wave = Net.GetWave()
	local speed = PlotService.SpeedOf(profile)
	if profile.surfing and wave and wave.phase == "wave" then
		speed = math.max(speed, G.surfSpeed)
	end
	return speed
end

local function guardPlayer(player, profile, clock)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or clock - profile.movedByServerAt < G.window then
		history[player] = nil
		return
	end
	local samples = history[player]
	if not samples then
		samples = {}
		history[player] = samples
	end
	local pos = Vector3.new(root.Position.X, 0, root.Position.Z)
	table.insert(samples, { t = clock, pos = pos })
	while #samples > 1 and clock - samples[1].t > G.window do
		table.remove(samples, 1)
	end
	local oldest = samples[1]
	local elapsed = clock - oldest.t
	if elapsed < G.window * 0.5 then
		return
	end
	local limit = allowedSpeed(profile) * elapsed * G.tolerance + G.slack
	if (pos - oldest.pos).Magnitude > limit then
		-- trop rapide : retour a la derniere position sure, a la hauteur actuelle
		local back = Vector3.new(oldest.pos.X, root.Position.Y, oldest.pos.Z)
		character:PivotTo(CFrame.new(back) * root.CFrame.Rotation)
		root.AssemblyLinearVelocity = Vector3.zero
		profile.movedByServerAt = clock
		history[player] = nil
		warn(("[TideRush] vitesse anormale pour %s : %.0f studs en %.1f s"):format(player.Name, (pos - oldest.pos).Magnitude, elapsed))
	end
end

local function guardLoop()
	while true do
		task.wait(GUARD_TICK)
		local clock = os.clock()
		for player, profile in DataService.All() do
			if profile.loaded and not profile.leaving then
				guardPlayer(player, profile, clock)
			end
		end
	end
end

function MountService.Track(player)
	player.CharacterAdded:Connect(function(character)
		-- nouveau personnage : plus de monture (mort, reset)
		originalHip[player] = nil
		history[player] = nil
		local profile = DataService.Get(player)
		if profile and profile.mountUid ~= "" then
			MountService.Dismount(player)
		end
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				MountService.Dismount(player)
			end)
		end
	end)
end

function MountService.Forget(player)
	originalHip[player] = nil
	history[player] = nil
end

function MountService.Start()
	Net.Handle("Mount", mount)
	WaveService.OnPhase(function()
		for player, profile in DataService.All() do
			if profile.mountUid ~= "" and player.Parent then
				player:SetAttribute("Surfing", profile.surfing and Net.GetWave().phase == "wave")
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_TICK)
			local ok, err = pcall(checkMounts)
			if not ok then
				warn("[TideRush] montures : " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(guardLoop)
			warn("[TideRush] verification de vitesse relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
end

return MountService
