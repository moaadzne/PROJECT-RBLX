-- Prompts : interface maison de toutes les invites ProximityPrompt en Style Custom (VISION_TON §6.1 ;
-- A cree les siennes en Custom, StealHud aussi). Plaque sombre, touche, ACTION en MAJUSCULES, objet en dessous,
-- jauge si HoldDuration > 0. Au doigt : toucher la plaque pilote l'invite (InputHoldBegin / InputHoldEnd).
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Prompts = {}

local SIZE = Vector2.new(190, 54)

local Theme, Components, Util, Sfx
local playerGui: Instance
local shown: { [ProximityPrompt]: any } = {}

-- Libelle court de la touche (clavier ou manette) ; rien au tactile
local function keyLabel(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType): string?
	if inputType == Enum.ProximityPromptInputType.Keyboard then
		local name = prompt.KeyboardKeyCode.Name
		return if #name <= 2 then name else string.sub(name, 1, 3)
	elseif inputType == Enum.ProximityPromptInputType.Gamepad then
		return (prompt.GamepadKeyCode.Name:gsub("^Button", ""))
	end
	return nil
end

local function build(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
	local adornee = prompt.Parent
	if not adornee or not (adornee:IsA("BasePart") or adornee:IsA("Attachment") or adornee:IsA("Model")) then
		return nil
	end
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_Prompt",
		Size = UDim2.fromOffset(SIZE.X, SIZE.Y),
		StudsOffsetWorldSpace = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		Active = true,
		ResetOnSpawn = false,
		Adornee = adornee,
	})
	local button = Theme.Create("TextButton", {
		Name = "Hit",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		Parent = gui,
	})
	local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Strong = true, Parent = button })
	local key = keyLabel(prompt, inputType)
	local left = 12
	if key then
		local hint = Theme.Create("Frame", {
			Name = "Key",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 10, 0.5, 0),
			Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = Theme.Colors.Text,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = plate,
		})
		Theme.Corner(hint, 6)
		local k = Theme.Text({
			Size = UDim2.fromScale(1, 1),
			Text = key,
			TextSize = 18,
			FontFace = Theme.Fonts.Title,
			TextColor3 = Theme.Colors.TextDark,
			ZIndex = 4,
			Parent = hint,
		})
		k:FindFirstChildOfClass("UIStroke"):Destroy()
		left = 50
	end
	Theme.Title({
		Name = "Action",
		Position = UDim2.fromOffset(left, 6),
		Size = UDim2.new(1, -left - 8, 0, 24),
		Text = prompt.ActionText,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = plate,
	})
	Theme.Text({
		Name = "Object",
		Position = UDim2.fromOffset(left, 28),
		Size = UDim2.new(1, -left - 8, 0, 18),
		Text = string.upper(prompt.ObjectText),
		TextSize = 14,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = plate,
	})
	local bar = nil
	if prompt.HoldDuration > 0 then
		bar = Components.ProgressBar({
			Name = "Hold",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -3),
			Size = UDim2.new(1, -16, 0, 3),
			Color = Theme.Colors.Lagoon,
			ZIndex = 3,
			Parent = plate,
		})
		bar.Label.Visible = false
		bar:Set(0, false)
	end
	local conns = {}
	-- toucher / cliquer la plaque : on pilote l'invite nous-memes (le style Custom n'affiche rien a toucher)
	table.insert(conns, button.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldBegin()
		end
	end))
	table.insert(conns, button.InputEnded:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			prompt:InputHoldEnd()
		end
	end))
	if bar then
		table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function()
			bar:Set(0, false)
			-- lineaire : la jauge represente le temps restant
			Util.Tween(bar.Fill, prompt.HoldDuration, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Linear)
		end))
		table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function()
			bar:Set(0, true)
		end))
	end
	table.insert(conns, prompt.Triggered:Connect(function()
		Theme.Pop(plate, 0.06)
		Sfx.Play("click")
	end))
	-- apparition seche
	local scale = Theme.GetScale(plate)
	scale.Scale = 0.9
	Util.Tween(scale, Theme.Time.Fast, { Scale = 1 }, Enum.EasingStyle.Quart)
	gui.Parent = playerGui
	return { gui = gui, conns = conns }
end

local function hide(prompt: ProximityPrompt)
	local rec = shown[prompt]
	shown[prompt] = nil
	if rec then
		for _, c in rec.conns do
			c:Disconnect()
		end
		rec.gui:Destroy()
	end
end

function Prompts.Init(ctx)
	Theme, Components, Util, Sfx = ctx.Theme, ctx.Components, ctx.Util, ctx.Sfx
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function Prompts.Start(_ctx)
	ProximityPromptService.PromptShown:Connect(function(prompt, inputType)
		if prompt.Style ~= Enum.ProximityPromptStyle.Custom or shown[prompt] then
			return
		end
		local rec = build(prompt, inputType)
		if not rec then
			return
		end
		shown[prompt] = rec
		prompt.PromptHidden:Once(function()
			hide(prompt)
		end)
	end)
end

return Prompts
