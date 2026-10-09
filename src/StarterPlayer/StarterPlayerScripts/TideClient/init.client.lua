-- TideClient : point d'entree client (LocalScript dans StarterPlayerScripts).
-- Cree les ScreenGuis, charge les modules enfants dans l'ordre, puis Init() et Start() de chacun.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Ordre de chargement : les briques d'abord, les ecrans ensuite (un module absent est saute)
local FOUNDATION = { "Util", "Theme", "Settings", "Store", "Sfx", "Fx", "Components" }
local SCREENS = { "Notifications", "Hud", "PoolBillboards", "World", "Ambience", "StealHud", "RoyalHud", "MountButton", "Shop", "Onboarding" } -- Onboarding apres Hud (Hud.Hold)

-- Echelle de l'interface : 1 = ecran de design 900 x 480 (telephone paysage 844 x 390 -> 0,85)
local DESIGN_SIZE = Vector2.new(900, 480)
local SCALE_MIN, SCALE_MAX = 0.85, 1.3

-- Elements Roblox par defaut inutiles ici (pas d'outils, pas de vie, classement maison)
local HIDDEN_CORE_GUI = { Enum.CoreGuiType.PlayerList, Enum.CoreGuiType.Backpack, Enum.CoreGuiType.Health }

local playerGui = player:WaitForChild("PlayerGui")

local function newScreenGui(name: string, order: number, insets: Enum.ScreenInsets): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = insets
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = order
	gui.Parent = playerGui
	return gui
end

-- HUD : respecte les encoches, passe sous la barre Roblox (contournee a la main)
local hud = newScreenGui("TideHUD", 5, Enum.ScreenInsets.DeviceSafeInsets)
-- Effets plein ecran (flash, fondu, icones volantes), au-dessus du HUD
local overlay = newScreenGui("TideOverlay", 20, Enum.ScreenInsets.None)

for _, kind in HIDDEN_CORE_GUI do
	pcall(StarterGui.SetCoreGuiEnabled, StarterGui, kind, false)
end

local ctx = {
	Config = Config,
	Player = player,
	Gui = hud,
	Overlay = overlay,
}

local function loadModules(names: { string })
	for _, name in names do
		local moduleScript = script:FindFirstChild(name)
		if moduleScript and moduleScript:IsA("ModuleScript") then
			local ok, mod = xpcall(require, debug.traceback, moduleScript)
			if ok then
				ctx[name] = mod
			else
				warn(("[TideClient] require %s : %s"):format(name, tostring(mod)))
			end
		end
	end
end

local function initAll(names: { string })
	for _, name in names do
		local mod = ctx[name]
		if mod and mod.Init then
			local ok, err = xpcall(mod.Init, debug.traceback, ctx)
			if not ok then
				warn(("[TideClient] %s.Init : %s"):format(name, tostring(err)))
			end
		end
	end
end

local function startAll(names: { string })
	for _, name in names do
		local mod = ctx[name]
		if mod and mod.Start then
			task.spawn(function()
				local ok, err = xpcall(mod.Start, debug.traceback, ctx)
				if not ok then
					warn(("[TideClient] %s.Start : %s"):format(name, tostring(err)))
				end
			end)
		end
	end
end

local function uiScale(): number
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or DESIGN_SIZE
	local fit = math.min(vp.X / DESIGN_SIZE.X, vp.Y / DESIGN_SIZE.Y)
	local userScale = if ctx.Settings then ctx.Settings.Get("uiScale") else 1
	return math.clamp(fit, SCALE_MIN, SCALE_MAX) * userScale
end

-- Racine commune des ecrans, remise a l'echelle quand l'ecran ou le reglage change
local function buildRoot()
	local root, refresh = ctx.Theme.ScaledRoot(hud, uiScale)
	ctx.Root = root
	local function watchCamera(cam: Camera?)
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
		end
		refresh()
	end
	watchCamera(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera(workspace.CurrentCamera)
	end)
	if ctx.Settings and ctx.Settings.Changed then
		ctx.Settings.Changed:Connect(function(key)
			if key == "uiScale" then
				refresh()
			end
		end)
	end
end

loadModules(FOUNDATION)
loadModules(SCREENS)
initAll(FOUNDATION)
if ctx.Theme then
	buildRoot()
	initAll(SCREENS)
else
	warn("[TideClient] Theme indisponible : interface non construite")
end

-- Son de clic de tous les boutons
if ctx.Theme and ctx.Sfx then
	ctx.Theme.OnPress = function()
		ctx.Sfx.Play("click")
	end
end

startAll(FOUNDATION)
startAll(SCREENS)
