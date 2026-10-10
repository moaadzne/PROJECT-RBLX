-- World : rendu client des creatures (le serveur ne les bouge jamais, contrat v2).
--   - flottement et rotation des modeles tagues TR_Spin (BasePos, BaseYaw en degres, SpinSpeed en degres/s, Bob en studs) ;
--   - echelle du stade (attribut Stage -> Config.Stages[stage].scale, relative a l'Adult), avec rebond quand il change ;
--   - look de mutation (attribut Mutation -> preset de C : Assets.FX.Mutations.<Mutation>) ;
--   - creature personnelle de l'intro d'un autre joueur (attribut Owner) : cachee chez moi.
-- Une seule boucle par frame, seulement pour les creatures proches de la camera.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local World = {}

local SPIN_TAG = "TR_Spin"
local ANIMATE_RADIUS = 160 -- studs : au-dela, pas d'animation
local BOB_SPEED = 2.2 -- rad/s
local GROW_TIME = 0.6
local GROW_OVERSHOOT = 1.15
local LOOK_TAG = "TR_MutationLook" -- marque les emetteurs ajoutes par le client

local Util, Settings, Store, Theme
local player = Players.LocalPlayer
local tracked: { [Model]: any } = {}
local watchDisplays

---------------------------------------------------------------- Mutation
local function mutationPreset(name: string): Instance?
	return Util.Find(ReplicatedStorage, "Assets", "FX", "Mutations", name)
end

local function applyMutation(model: Model, rec)
	local mutation = model:GetAttribute("Mutation")
	if type(mutation) ~= "string" or mutation == "" or rec.mutation == mutation then
		return
	end
	rec.mutation = mutation
	local preset = mutationPreset(mutation)
	local fallback = Theme.Mutations[mutation]
	local color = preset and preset:GetAttribute("Color") or (fallback and fallback.color)
	local materialName = preset and preset:GetAttribute("Material") or "Foil"
	local reflectance = preset and preset:GetAttribute("Reflectance")
	local applyTo = preset and preset:GetAttribute("ApplyTo") or "*"
	local material = Enum.Material.Foil
	pcall(function()
		material = (Enum.Material :: any)[materialName]
	end)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name ~= "Root" and (applyTo == "*" or part.Name == applyTo) then
			if typeof(color) == "Color3" then
				part.Color = color
			end
			part.Material = material
			if type(reflectance) == "number" then
				part.Reflectance = reflectance
			end
		end
	end
	-- etincelles du preset, dans Root (moins en graphismes bas)
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if preset and root and not Settings.IsLowGraphics() then
		for _, child in preset:GetChildren() do
			if child:IsA("ParticleEmitter") then
				local emitter = child:Clone()
				CollectionService:AddTag(emitter, LOOK_TAG)
				emitter.Parent = root
			end
		end
	end
end

---------------------------------------------------------------- Echelle du stade
local function stageOf(model: Model): number
	local stage = tonumber(model:GetAttribute("Stage"))
	return if stage then math.clamp(math.floor(stage), 1, 4) else 1
end

local function setScale(model: Model, scale: number)
	if scale > 0 and math.abs(model:GetScale() - scale) > 1e-3 then
		model:ScaleTo(scale)
	end
end

-- Rebond de croissance : grossit au-dela de la cible puis s'y pose (instantane en "reduire les animations")
local function growTo(rec, target: number)
	rec.growFrom = rec.model:GetScale()
	rec.growTo = target
	rec.growStart = os.clock()
	if Settings.Get("reducedMotion") then
		rec.growStart = nil
		setScale(rec.model, target)
	end
end

local function updateGrow(rec, now: number)
	if not rec.growStart then
		return
	end
	local t = math.clamp((now - rec.growStart) / GROW_TIME, 0, 1)
	local from, to = rec.growFrom, rec.growTo
	local scale
	if t < 0.6 then
		local k = t / 0.6
		scale = from + (to * GROW_OVERSHOOT - from) * (1 - (1 - k) ^ 2)
	else
		local k = (t - 0.6) / 0.4
		scale = to * GROW_OVERSHOOT + (to - to * GROW_OVERSHOOT) * (k * k * (3 - 2 * k))
	end
	setScale(rec.model, scale)
	if t >= 1 then
		rec.growStart = nil
		setScale(rec.model, to)
	end
end

---------------------------------------------------------------- Visibilite (intro des autres)
local function setHidden(model: Model, hidden: boolean)
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			d.LocalTransparencyModifier = if hidden then 1 else 0
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") or d:IsA("BillboardGui") then
			d.Enabled = not hidden
		end
	end
end

local function isForeignIntro(model: Model): boolean
	local owner = model:GetAttribute("Owner")
	return type(owner) == "number" and owner ~= player.UserId
end

---------------------------------------------------------------- Suivi des modeles
-- Attributs d'animation lus une fois (et a chaque changement), pas a chaque frame
local function readMotion(model: Model, rec)
	local basePos = model:GetAttribute("BasePos")
	rec.basePos = if typeof(basePos) == "Vector3" then basePos else nil
	rec.yaw = tonumber(model:GetAttribute("BaseYaw")) or 0
	rec.spin = tonumber(model:GetAttribute("SpinSpeed")) or 0
	rec.bob = tonumber(model:GetAttribute("Bob")) or 0
end

local function onStage(model: Model, rec)
	local stage = stageOf(model)
	if stage == rec.stage then
		return
	end
	local grew = stage > rec.stage
	rec.stage = stage
	if grew then
		growTo(rec, Store.StageScale(stage))
	else
		setScale(model, Store.StageScale(stage))
	end
end

local function track(model: Instance)
	if not model:IsA("Model") or tracked[model] then
		return
	end
	local rec = {
		model = model,
		phase = math.random() * math.pi * 2,
		stage = stageOf(model),
		hidden = false,
		conns = {},
	}
	tracked[model] = rec
	readMotion(model, rec)
	setScale(model, Store.StageScale(rec.stage))
	applyMutation(model, rec)
	if isForeignIntro(model) then
		rec.hidden = true
		setHidden(model, true)
	end
	table.insert(rec.conns, model.AttributeChanged:Connect(function(name)
		if name == "Stage" then
			onStage(model, rec)
		elseif name == "Mutation" then
			applyMutation(model, rec)
		elseif name == "Owner" then
			rec.hidden = isForeignIntro(model)
			setHidden(model, rec.hidden)
		else
			readMotion(model, rec)
		end
	end))
end

local function untrack(model: Instance)
	local rec = tracked[model :: Model]
	if not rec then
		return
	end
	for _, c in rec.conns do
		c:Disconnect()
	end
	tracked[model :: Model] = nil
end

local function onRender()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	local now = os.clock()
	local reduced = Settings.Get("reducedMotion")
	for model, rec in tracked do
		updateGrow(rec, now)
		local basePos = rec.basePos
		if not rec.hidden and basePos and (basePos - camPos).Magnitude < ANIMATE_RADIUS then
			local spin = if reduced then 0 else rec.spin
			local y = if reduced then 0 else math.sin(now * BOB_SPEED + rec.phase) * rec.bob
			model:PivotTo(CFrame.new(basePos + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(rec.yaw + spin * now), 0))
		end
	end
end

-- Map.Plots.PlotN.Display : arrive avec le streaming, on attend sans bloquer le reste
function watchDisplays()
	local plots = Util.Find(workspace, "Map", "Plots")
	while not plots do
		task.wait(1)
		plots = Util.Find(workspace, "Map", "Plots")
	end
	local function watchDisplay(display: Instance)
		for _, model in display:GetChildren() do
			track(model)
		end
		display.ChildAdded:Connect(track)
		display.ChildRemoved:Connect(untrack)
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
	end
	for _, plot in plots:GetChildren() do
		watchPlot(plot)
	end
	plots.ChildAdded:Connect(watchPlot)
end

---------------------------------------------------------------- Demarrage
function World.Init(ctx)
	Util, Settings, Theme = ctx.Util, ctx.Settings, ctx.Theme
end

function World.Start(ctx)
	Store = ctx.Store
	CollectionService:GetInstanceAddedSignal(SPIN_TAG):Connect(track)
	CollectionService:GetInstanceRemovedSignal(SPIN_TAG):Connect(untrack)
	for _, model in CollectionService:GetTagged(SPIN_TAG) do
		track(model)
	end
	-- creatures des bassins : suivies meme sans le tag (echelle du stade et mutation)
	task.spawn(watchDisplays)
	RunService.RenderStepped:Connect(onRender)
end

return World
