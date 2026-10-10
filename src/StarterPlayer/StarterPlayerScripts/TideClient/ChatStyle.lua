-- ChatStyle : chat Roblox (TextChatService) a nos couleurs, police et position (VISION_TON §6.1).
-- Rien n'est remplace : on habille seulement la fenetre, la barre de saisie et les bulles. Chaque propriete est
-- posee dans un pcall (une propriete absente ou un ancien chat ne casse rien).
local TextChatService = game:GetService("TextChatService")
local UserInputService = game:GetService("UserInputService")

local ChatStyle = {}

local Theme

local function set(inst: Instance?, props: { [string]: any })
	if not inst then
		return
	end
	for key, value in props do
		pcall(function()
			(inst :: any)[key] = value
		end)
	end
end

function ChatStyle.Init(ctx)
	Theme = ctx.Theme
end

function ChatStyle.Start(_ctx)
	if TextChatService.ChatVersion ~= Enum.ChatVersion.TextChatService then
		return -- ancien chat : on n'y touche pas
	end
	local font = Theme.Fonts.Medium
	set(TextChatService:FindFirstChildOfClass("ChatWindowConfiguration"), {
		FontFace = font,
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		TextStrokeTransparency = 0.7,
		BackgroundColor3 = Theme.Colors.Plate,
		BackgroundTransparency = 0.35,
		-- PC : en bas a gauche (le porte-monnaie occupe le haut gauche) ; mobile : place par defaut,
		-- le chat s'y ouvre a la demande et le joystick occupe le bas gauche
		VerticalAlignment = if UserInputService.TouchEnabled then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		HeightScale = 0.7,
		WidthScale = 0.8,
	})
	set(TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration"), {
		FontFace = font,
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		PlaceholderColor3 = Theme.Colors.TextDim,
		BackgroundColor3 = Theme.Colors.Plate,
		BackgroundTransparency = 0.25,
	})
	set(TextChatService:FindFirstChildOfClass("BubbleChatConfiguration"), {
		FontFace = font,
		TextSize = 16,
		TextColor3 = Theme.Colors.Text,
		BackgroundColor3 = Theme.Colors.Plate,
		BackgroundTransparency = 0.15,
		TailVisible = true,
	})
end

return ChatStyle
