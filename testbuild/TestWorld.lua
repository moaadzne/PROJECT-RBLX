-- TestWorld : ile de TEST generee au demarrage du serveur (version de test seulement, pas la carte finale de C).
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local TestWorld = {}

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function assets()
	local a = ReplicatedStorage:FindFirstChild("Assets") or Instance.new("Folder")
	a.Name = "Assets"
	a.Parent = ReplicatedStorage
	local fx = a:FindFirstChild("FX") or Instance.new("Folder")
	fx.Name = "FX"
	fx.Parent = a
	for _, n in ipairs({ "Mutations", "TidePresets", "Royal" }) do
		if not fx:FindFirstChild(n) then
			local f = Instance.new("Folder")
			f.Name = n
			f.Parent = fx
		end
	end
	for _, n in ipairs({ "Sounds", "Creatures", "Items" }) do
		if not a:FindFirstChild(n) then
			local f = Instance.new("Folder")
			f.Name = n
			f.Parent = a
		end
	end
	if not a:FindFirstChild("Wave") then
		local m = Instance.new("Model")
		m.Name = "Wave"
		local h, t = Config.Wave.height, Config.Wave.thickness or 40
		local body = part({ Name = "Body", Size = Vector3.new(Config.Island.size + 200, h, t), Material = Enum.Material.Glass,
			Color = Color3.fromRGB(20, 120, 150), Transparency = 0.25, CanCollide = false, CastShadow = false }, m)
		part({ Name = "Foam", Size = Vector3.new(Config.Island.size + 200, 3, t + 4), Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(240, 250, 255), CanCollide = false, CFrame = body.CFrame * CFrame.new(0, h / 2, 0) }, m)
		part({ Name = "Crest", Size = Vector3.new(Config.Island.size + 200, 4, 6), Material = Enum.Material.SmoothPlastic,
			Color = Color3.fromRGB(255, 255, 255), CanCollide = false, CFrame = body.CFrame * CFrame.new(0, h / 2 + 2, t / 2) }, m)
		m.PrimaryPart = body
		m.Parent = a
	end
end

function TestWorld.Build()
	assets()
	if Workspace:FindFirstChild("Map") then
		return
	end
	local c = Config.Island.center
	local half = Config.Island.size / 2
	local terrain = Workspace.Terrain
	terrain:Clear()
	terrain:FillBlock(CFrame.new(c + Vector3.new(0, -10, 0)), Vector3.new(Config.Island.size + 500, 20, Config.Island.size + 500), Enum.Material.Water)
	terrain:FillCylinder(CFrame.new(c + Vector3.new(0, -3, 0)), 10, half, Enum.Material.Sand)
	terrain:FillCylinder(CFrame.new(c + Vector3.new(0, -2, 0)), 8, Config.Island.coveRadius, Enum.Material.Grass)

	local map = Instance.new("Folder")
	map.Name = "Map"
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = map
	local towers = Instance.new("Folder")
	towers.Name = "Towers"
	towers.Parent = map

	-- 8 lagons en anneau dans la crique
	local lagoonR, ringR = 14, 46
	for i = 1, 8 do
		local a = (i - 1) * math.pi / 4
		local center = c + Vector3.new(math.cos(a) * ringR, 2, math.sin(a) * ringR)
		local plot = Instance.new("Model")
		plot.Name = "Plot" .. i
		plot:SetAttribute("Index", i)
		plot:SetAttribute("Center", center)
		plot:SetAttribute("Radius", lagoonR)
		plot:SetAttribute("SpawnPos", center)
		part({ Name = "Water", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, lagoonR * 2, lagoonR * 2),
			CFrame = CFrame.new(center + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
			Material = Enum.Material.Glass, Color = Color3.fromRGB(30, 170, 175), Transparency = 0.3, CanCollide = false }, plot)
		local peds = Instance.new("Folder")
		peds.Name = "Pedestals"
		peds.Parent = plot
		for s = 1, 10 do
			local pa = (s - 1) * math.pi / 5
			local pos = center + Vector3.new(math.cos(pa) * 9, 1, math.sin(pa) * 9)
			local ped = part({ Name = "Pedestal" .. s, Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 4, 4),
				CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2), Material = Enum.Material.Slate,
				Color = Color3.fromRGB(90, 80, 70) }, peds)
			ped:SetAttribute("Slot", s)
			local gui = Instance.new("BillboardGui")
			gui.Name = "LockGui"
			gui.Size = UDim2.fromOffset(70, 26)
			gui.StudsOffset = Vector3.new(0, 3, 0)
			gui.Enabled = false
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0.3
			label.TextScaled = true
			label.Parent = gui
			gui.Parent = ped
		end
		local display = Instance.new("Folder")
		display.Name = "Display"
		display.Parent = plot
		local barrier = Instance.new("Model")
		barrier.Name = "Barrier"
		barrier:SetAttribute("Open", false)
		for b = 1, 14 do
			local ba = (b - 1) * math.pi * 2 / 14
			local pos = center + Vector3.new(math.cos(ba) * (lagoonR + 1), 3, math.sin(ba) * (lagoonR + 1))
			part({ Name = "Coral" .. b, Size = Vector3.new(6.5, 6, 2), CFrame = CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)),
				Material = Enum.Material.Rock, Color = Color3.fromRGB(205, 110, 110) }, barrier)
		end
		barrier.Parent = plot
		plot.Parent = plots
	end

	-- 8 tours SAFE (plateforme au-dessus de la vague) avec echelle
	local platY = Config.Wave.height + 4
	for i = 1, 8 do
		local a = (i - 1) * math.pi / 4 + math.pi / 8
		local base = c + Vector3.new(math.cos(a) * 200, 2, math.sin(a) * 200)
		local tower = Instance.new("Model")
		tower.Name = "Tower" .. i
		tower:SetAttribute("Center", base)
		tower:SetAttribute("PlatformRadius", 10)
		part({ Name = "Pillar", Size = Vector3.new(4, platY - 2, 4), CFrame = CFrame.new(base + Vector3.new(0, (platY - 2) / 2, 0)),
			Material = Enum.Material.Wood, Color = Color3.fromRGB(120, 85, 55) }, tower)
		part({ Name = "Platform", Size = Vector3.new(20, 2, 20), CFrame = CFrame.new(base + Vector3.new(0, platY - 1, 0)),
			Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(150, 105, 65) }, tower)
		local truss = Instance.new("TrussPart")
		truss.Anchored = true
		truss.Size = Vector3.new(2, math.floor((platY) / 2) * 2, 2)
		truss.CFrame = CFrame.new(base + Vector3.new(3, truss.Size.Y / 2, 0))
		truss.Parent = tower
		tower.Parent = towers
	end
	map.Parent = Workspace

	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Position = c + Vector3.new(0, 3, 0)
	spawn.Parent = Workspace

	Lighting.ClockTime = 17.2
	Lighting.Brightness = 2.5
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere")
		atm.Density = 0.28
		atm.Color = Color3.fromRGB(255, 200, 160)
		atm.Decay = Color3.fromRGB(120, 140, 170)
		atm.Parent = Lighting
	end
end

return TestWorld
