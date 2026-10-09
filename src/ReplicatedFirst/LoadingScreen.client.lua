-- LoadingScreen : ecran de chargement maison (VISION_TON §4 et §6.1) a la place de celui de Roblox.
-- Image de la baie (id dans l'attribut LoadingImage de ReplicatedFirst, fourni par C ; sinon fond sombre),
-- titre, barre fine. Disparait quand le jeu est charge et que le personnage existe (2 s au moins, 25 s au plus) ;
-- la camera d'arrivee (TideClient/Onboarding) prend alors le relais.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

local MIN_TIME = 2
local MAX_TIME = 25
local FADE_TIME = 0.4
local OSWALD = "rbxasset://fonts/families/Oswald.json"
local BUILDER = "rbxasset://fonts/families/BuilderSans.json"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "TR_Loading"
gui.IgnoreGuiInset = true
gui.ScreenInsets = Enum.ScreenInsets.None
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false
gui.Parent = playerGui

ReplicatedFirst:RemoveDefaultLoadingScreen()

local root = Instance.new("CanvasGroup")
root.Name = "Root"
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
root.BorderSizePixel = 0
root.Parent = gui

local image = ReplicatedFirst:GetAttribute("LoadingImage")
if type(image) == "string" and image ~= "" then
	local picture = Instance.new("ImageLabel")
	picture.Name = "Bay"
	picture.Size = UDim2.fromScale(1, 1)
	picture.BackgroundTransparency = 1
	picture.Image = image
	picture.ScaleType = Enum.ScaleType.Crop
	picture.Parent = root
end

-- voile sombre en bas : le titre reste lisible sur l'image
local shade = Instance.new("Frame")
shade.Name = "Shade"
shade.AnchorPoint = Vector2.new(0, 1)
shade.Position = UDim2.fromScale(0, 1)
shade.Size = UDim2.fromScale(1, 0.45)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BorderSizePixel = 0
shade.Parent = root
local shadeGradient = Instance.new("UIGradient")
shadeGradient.Rotation = 90
shadeGradient.Transparency = NumberSequence.new(1, 0.25)
shadeGradient.Parent = shade

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0, 1)
title.Position = UDim2.new(0, 48, 1, -78)
title.Size = UDim2.new(1, -96, 0, 64)
title.BackgroundTransparency = 1
title.FontFace = Font.new(OSWALD, Enum.FontWeight.Bold)
title.Text = "RIDE THE TSUNAMI"
title.TextColor3 = Color3.fromRGB(242, 245, 248)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root
local titleSize = Instance.new("UITextSizeConstraint")
titleSize.MaxTextSize = 56
titleSize.MinTextSize = 28
titleSize.Parent = title

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0, 1)
status.Position = UDim2.new(0, 50, 1, -52)
status.Size = UDim2.new(1, -100, 0, 20)
status.BackgroundTransparency = 1
status.FontFace = Font.new(BUILDER, Enum.FontWeight.Bold)
status.Text = "LOADING"
status.TextColor3 = Color3.fromRGB(150, 162, 178)
status.TextSize = 15
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = root

local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0, 1)
track.Position = UDim2.new(0, 50, 1, -40)
track.Size = UDim2.new(1, -100, 0, 3)
track.BackgroundColor3 = Color3.new(1, 1, 1)
track.BackgroundTransparency = 0.8
track.BorderSizePixel = 0
track.Parent = root
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = Color3.fromRGB(38, 196, 196)
fill.BorderSizePixel = 0
fill.Parent = track

-- Progression : chargement du jeu + file de ressources ; jamais en arriere, jamais a 100 % avant la fin
local start = os.clock()
local shown = 0
local function ready(): boolean
	return game:IsLoaded() and player.Character ~= nil
end

while os.clock() - start < MAX_TIME do
	local elapsed = os.clock() - start
	if ready() and elapsed >= MIN_TIME then
		break
	end
	local queue = ContentProvider.RequestQueueSize
	local target = if game:IsLoaded() then 0.7 + 0.25 * math.clamp(1 - queue / 50, 0, 1) else math.clamp(elapsed / 10, 0, 0.6)
	shown = math.max(shown, math.min(target, 0.95))
	fill.Size = UDim2.fromScale(shown, 1)
	task.wait(0.1)
end

fill.Size = UDim2.fromScale(1, 1)
task.wait(0.1)
local fade = TweenService:Create(root, TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad), { GroupTransparency = 1 })
fade:Play()
fade.Completed:Wait()
gui:Destroy()
