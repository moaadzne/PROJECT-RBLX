-- Ambience : ambiance des marées et barrieres des lagons, cote client.
--   - Maree : tween de 2 s de Lighting, Atmosphere et des effets vers Assets.FX.TidePresets.<Tide> (fournis par C,
--     un attribut "<Classe>_<Propriete>" par valeur). Exception validee par D : en jeu seulement, jamais en edition.
--     Sans preset Normal, le retour se fait vers les valeurs du demarrage.
--   - Barriere : PlotN.Barrier descend sous le sable quand l'attribut Open (sur Barrier, sinon sur PlotN) est vrai,
--     remonte quand il est faux. Le serveur fait autorite sur la collision ; le client ne fait que l'animation.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Ambience = {}

local TIDE_TWEEN = 2
local BARRIER_OPEN_TIME = 0.5
local BARRIER_CLOSE_TIME = 0.45
local BARRIER_SINK_EXTRA = 0.3 -- studs sous le sol en plus de la hauteur
local BARRIER_SOUND_RADIUS = 90

local Util, Store, Sfx
local applied: string? = nil
local baseline: { [string]: any } = {} -- valeurs du demarrage, par "<Classe>_<Propriete>"
local tideTweens: { Tween } = {}

---------------------------------------------------------------- Marée
-- Meme regle que l'outil de C : Lighting ; ColorCorrectionEffect "TideColor" sinon le premier ; sinon le premier de la classe
local function effectOf(className: string): Instance?
	if className == "Lighting" then
		return Lighting
	end
	if className == "ColorCorrectionEffect" then
		local named = Lighting:FindFirstChild("TideColor")
		if named and named:IsA("ColorCorrectionEffect") then
			return named
		end
	end
	for _, c in Lighting:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end

local function splitKey(key: string): (string?, string?)
	return key:match("^(%w+)_(%w+)$")
end

local function readProp(inst: Instance, prop: string): any
	local ok, value = pcall(function()
		return (inst :: any)[prop]
	end)
	return if ok then value else nil
end

local function presetFolder(tide: string): Instance?
	return Util.Find(ReplicatedStorage, "Assets", "FX", "TidePresets", tide)
end

-- Garde la valeur actuelle de chaque propriete qu'un preset touche (pour revenir sans preset Normal)
local function rememberBaseline()
	local presets = Util.Find(ReplicatedStorage, "Assets", "FX", "TidePresets")
	if not presets then
		return
	end
	for _, folder in presets:GetChildren() do
		for key in folder:GetAttributes() do
			if baseline[key] == nil then
				local className, prop = splitKey(key)
				local inst = className and effectOf(className)
				if inst and prop then
					baseline[key] = readProp(inst, prop)
				end
			end
		end
	end
end

local function applyTide(tide: string)
	if tide == applied then
		return
	end
	local folder = presetFolder(tide)
	local values: { [string]: any }
	if folder then
		values = folder:GetAttributes()
	elseif tide == "Normal" or not presetFolder("Normal") then
		values = baseline -- pas de preset : retour a la lumiere du demarrage
	else
		values = (presetFolder("Normal") :: Instance):GetAttributes()
	end
	applied = tide
	for _, tween in tideTweens do
		tween:Cancel()
	end
	tideTweens = {}
	-- regroupe les proprietes par instance : un tween par instance
	local byInstance: { [Instance]: { [string]: any } } = {}
	for key, value in values do
		local className, prop = splitKey(key)
		local inst = className and effectOf(className)
		if inst and prop and readProp(inst, prop) ~= nil and typeof(readProp(inst, prop)) == typeof(value) then
			byInstance[inst] = byInstance[inst] or {}
			byInstance[inst][prop] = value
		end
	end
	local info = TweenInfo.new(TIDE_TWEEN, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for inst, props in byInstance do
		local ok, tween = pcall(TweenService.Create, TweenService, inst, info, props)
		if ok then
			tween:Play()
			table.insert(tideTweens, tween)
		end
	end
end

---------------------------------------------------------------- Barrieres
local barriers: { [Instance]: any } = {}
local trackBarrier

local function barrierOpen(plot: Instance, barrier: Instance): boolean
	local v = barrier:GetAttribute("Open")
	if v == nil then
		v = plot:GetAttribute("Open")
	end
	return v == true
end

local function pivotOf(barrier: Instance): CFrame?
	if barrier:IsA("Model") or barrier:IsA("BasePart") then
		local ok, cf = pcall(function()
			return (barrier :: any):GetPivot()
		end)
		return if ok then cf else nil
	end
	return nil
end

-- Hauteur de la barriere (0 tant qu'un modele n'a pas encore de parties : streaming)
local function heightOf(barrier: Instance): number
	if barrier:IsA("Model") then
		local ok, _, size = pcall(barrier.GetBoundingBox, barrier)
		return if ok and size then size.Y else 0
	elseif barrier:IsA("BasePart") then
		return barrier.Size.Y
	end
	return 0
end

local function setBarrier(rec, open: boolean, animate: boolean)
	if rec.open == open then
		return
	end
	rec.open = open
	local target = if open then rec.closed * CFrame.new(0, -(rec.height + BARRIER_SINK_EXTRA), 0) else rec.closed
	if rec.tween then
		rec.tween:Cancel()
	end
	if not animate then
		rec.value.Value = target
		return
	end
	local style = if open then Enum.EasingStyle.Quad else Enum.EasingStyle.Back
	rec.tween = Util.Tween(rec.value, if open then BARRIER_OPEN_TIME else BARRIER_CLOSE_TIME, { Value = target }, style)
	local cam = workspace.CurrentCamera
	if cam and (cam.CFrame.Position - rec.closed.Position).Magnitude < BARRIER_SOUND_RADIUS then
		Sfx.Play(if open then "barrierOpen" else "barrierClose", { position = rec.closed.Position })
	end
end

function trackBarrier(plot: Instance, barrier: Instance)
	if barriers[barrier] then
		return
	end
	local closed = pivotOf(barrier)
	if not closed or heightOf(barrier) <= 0 then
		-- pas encore streamee : on reessaie quand une partie arrive
		local conn
		conn = barrier.DescendantAdded:Connect(function()
			if heightOf(barrier) > 0 then
				conn:Disconnect()
				trackBarrier(plot, barrier)
			end
		end)
		return
	end
	-- position construite par C = barriere fermee (le serveur ne la deplace jamais)
	local value = Instance.new("CFrameValue")
	value.Value = closed
	local rec = { closed = closed, height = heightOf(barrier), value = value, open = false, tween = nil, conns = {} }
	barriers[barrier] = rec
	table.insert(rec.conns, value.Changed:Connect(function(cf)
		if barrier.Parent then
			(barrier :: any):PivotTo(cf)
		end
	end))
	local function refresh()
		setBarrier(rec, barrierOpen(plot, barrier), true)
	end
	table.insert(rec.conns, barrier:GetAttributeChangedSignal("Open"):Connect(refresh))
	table.insert(rec.conns, plot:GetAttributeChangedSignal("Open"):Connect(refresh))
	table.insert(rec.conns, barrier.AncestryChanged:Connect(function()
		if not barrier:IsDescendantOf(workspace) then
			for _, c in rec.conns do
				c:Disconnect()
			end
			value:Destroy()
			barriers[barrier] = nil
		end
	end))
	setBarrier(rec, barrierOpen(plot, barrier), false)
end

local function watchPlot(plot: Instance)
	local barrier = plot:FindFirstChild("Barrier")
	if barrier then
		trackBarrier(plot, barrier)
	end
	plot.ChildAdded:Connect(function(child)
		if child.Name == "Barrier" then
			trackBarrier(plot, child)
		end
	end)
end

local function watchBarriers()
	local plots = Util.Find(workspace, "Map", "Plots")
	while not plots do
		task.wait(1)
		plots = Util.Find(workspace, "Map", "Plots")
	end
	for _, plot in plots:GetChildren() do
		watchPlot(plot)
	end
	plots.ChildAdded:Connect(watchPlot)
end

---------------------------------------------------------------- Demarrage
function Ambience.Init(ctx)
	Util, Sfx = ctx.Util, ctx.Sfx
end

function Ambience.Start(ctx)
	Store = ctx.Store
	rememberBaseline()
	applied = "Normal" -- la lumiere de la carte est celle de la maree normale
	Store.WaveChanged:Connect(function(wave)
		applyTide(wave.tide)
	end)
	applyTide(Store.GetWave().tide)
	task.spawn(watchBarriers)
end

return Ambience
