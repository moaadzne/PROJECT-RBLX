-- VERSION DE TEST : rendu simple de la vague sur son axe (N/E/S/W), en attendant le vrai rendu de B (P1-16)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("WaveState")

local h, t = Config.Wave.height, Config.Wave.thickness or 40
local width = Config.Island.size + 300
local model = Instance.new("Model")
model.Name = "TestWave"
local function mk(name, size, color, transparency, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Size = size
	p.Color = color
	p.Transparency = transparency
	p.Material = material
	p.Parent = model
	return p
end
local body = mk("Body", Vector3.new(width, h, t), Color3.fromRGB(25, 120, 150), 0.2, Enum.Material.Glass)
local crest = mk("Crest", Vector3.new(width, 4, t * 0.6), Color3.fromRGB(245, 250, 255), 0, Enum.Material.SmoothPlastic)
model.Parent = workspace
local hidden = CFrame.new(0, -500, 0)

local wave = nil
remote.OnClientEvent:Connect(function(w)
	if type(w) == "table" then
		wave = w
	end
end)

RunService.RenderStepped:Connect(function()
	local w = wave
	if not w or typeof(w.dir) ~= "Vector3" or (w.phase ~= "wave" and w.phase ~= "recede") then
		body.CFrame = hidden
		crest.CFrame = hidden
		return
	end
	local now = workspace:GetServerTimeNow()
	local d = Config.WaveFrontD(w, now)
	if w.phase == "recede" then
		local k = math.clamp((now - (w.phaseStart or now)) / (Config.Wave.recedeTime or 2.5), 0, 1)
		local reach = Config.Island.size / 2 + Config.Island.seaMargin
		d = d - (d + reach) * k
	end
	local pos = Config.Island.center + w.dir * (d - t / 2) + Vector3.new(0, h / 2 - 2, 0)
	local cf = CFrame.lookAt(pos, pos + w.dir)
	body.CFrame = cf
	crest.CFrame = cf * CFrame.new(0, h / 2, -t * 0.3)
end)
