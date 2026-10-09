-- Util : outils partages cote client (signal, nettoyage, tweens, ressort, formats, coordonnees ecran).
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Util = {}

-- Reglage global "reduire les animations" (pilote par Settings)
Util.ReducedMotion = false

---------------------------------------------------------------- Signal
-- Signal Lua pur : les tables passent par reference, chaque handler tourne dans son propre thread.
local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({ _handlers = {} }, Signal)
end

function Signal:Connect(fn)
	local handler = { fn = fn, connected = true }
	local handlers = self._handlers
	table.insert(handlers, handler)
	local conn = { Connected = true }
	function conn.Disconnect()
		if not handler.connected then
			return
		end
		handler.connected = false
		conn.Connected = false
		local i = table.find(handlers, handler)
		if i then
			table.remove(handlers, i)
		end
	end
	return conn
end

function Signal:Once(fn)
	local conn
	conn = self:Connect(function(...)
		conn.Disconnect()
		fn(...)
	end)
	return conn
end

function Signal:Fire(...)
	for _, h in table.clone(self._handlers) do
		if h.connected then
			task.spawn(h.fn, ...)
		end
	end
end

Util.Signal = Signal

---------------------------------------------------------------- Maid
-- Range connexions, instances, fonctions et threads pour tout nettoyer d'un coup.
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Add(item)
	table.insert(self._tasks, item)
	return item
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for i = #tasks, 1, -1 do
		local item = tasks[i]
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			item()
		elseif kind == "thread" then
			pcall(task.cancel, item)
		elseif kind == "table" then
			if item.Disconnect then
				item:Disconnect()
			elseif item.Destroy then
				item:Destroy()
			end
		end
	end
end

Util.Maid = Maid

---------------------------------------------------------------- Tweens
local SPRINGY = {
	[Enum.EasingStyle.Back] = true,
	[Enum.EasingStyle.Elastic] = true,
	[Enum.EasingStyle.Bounce] = true,
}
local REDUCED_MAX_TIME = 0.12

-- Lance un tween et le renvoie. Avec "reduire les animations" : court et sans rebond.
function Util.Tween(
	inst: Instance,
	duration: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?,
	delay: number?
): Tween
	local easing = style or Enum.EasingStyle.Quad
	local d = duration
	if Util.ReducedMotion then
		d = math.min(d, REDUCED_MAX_TIME)
		if SPRINGY[easing] then
			easing = Enum.EasingStyle.Quad
		end
	end
	local info = TweenInfo.new(d, easing, direction or Enum.EasingDirection.Out, 0, false, delay or 0)
	local tween = TweenService:Create(inst, info, props)
	tween:Play()
	return tween
end

---------------------------------------------------------------- Ressort
-- Oscillateur amorti : speed = pulsation (rad/s), damping = 1 critique, < 1 rebondit.
local Spring = {}
Spring.__index = Spring

function Spring.new(value: number, speed: number?, damping: number?)
	return setmetatable({ p = value, v = 0, target = value, speed = speed or 18, damping = damping or 0.75 }, Spring)
end

function Spring:Update(dt: number): number
	local steps = math.max(1, math.ceil(dt / (1 / 120)))
	local h = dt / steps
	local w, z = self.speed, self.damping
	for _ = 1, steps do
		local a = -2 * z * w * self.v - w * w * (self.p - self.target)
		self.v += a * h
		self.p += self.v * h
	end
	return self.p
end

Util.Spring = Spring

---------------------------------------------------------------- Maths et formats
function Util.Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- 83 -> "1:23"
function Util.FormatTime(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- Chemin sans attente : Util.Find(game.ReplicatedStorage, "Assets", "Sounds") -> Instance?
function Util.Find(root: Instance?, ...: string): Instance?
	local node = root
	for _, name in { ... } do
		if not node then
			return nil
		end
		node = node:FindFirstChild(name)
	end
	return node
end

-- HumanoidRootPart du joueur local (nil pendant une reapparition)
function Util.LocalRoot(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

---------------------------------------------------------------- Coordonnees ecran
-- AbsolutePosition est mesure sous l'encart de la barre Roblox (GetGuiInset).
-- Viewport = pixels depuis le coin haut-gauche reel de l'ecran (Camera:WorldToViewportPoint).

-- Centre d'un GuiObject, en pixels viewport
function Util.GuiCenterViewport(obj: GuiObject): Vector2
	local inset = GuiService:GetGuiInset()
	return obj.AbsolutePosition + obj.AbsoluteSize / 2 + inset
end

-- Point viewport -> offset local dans un calque plein ecran sans UIScale
function Util.ViewportToLayer(layer: GuiObject, p: Vector2): Vector2
	local inset = GuiService:GetGuiInset()
	return p - (layer.AbsolutePosition + inset)
end

-- Position monde -> point viewport (nil si derriere la camera)
function Util.WorldToViewport(pos: Vector3): Vector2?
	local cam = workspace.CurrentCamera
	if not cam then
		return nil
	end
	local p = cam:WorldToViewportPoint(pos)
	if p.Z <= 0 then
		return nil
	end
	return Vector2.new(p.X, p.Y)
end

return Util
