-- Settings : reglages du joueur (graphismes, volume, reduire les animations, taille de l'interface).
-- Locaux pour l'instant : le menu Reglages et leur sauvegarde arrivent en Phase 2.
local Settings = {}

local Util

local DEFAULTS = {
	graphics = "Auto", -- "Auto" | "Low" | "High"
	volume = 0.8, -- 0..1, multiplie tous les sons du jeu
	reducedMotion = false, -- pas de secousse ni de rebond, animations courtes
	uiScale = 1, -- 0.8..1.25, multiplie l'echelle automatique
}
local QUALITY_REFRESH = 2 -- secondes entre deux lectures de la qualite Roblox

local values = table.clone(DEFAULTS)
local lowQualityCache = false
local lowQualityReadAt = -math.huge

function Settings.Init(ctx)
	Util = ctx.Util
	Settings.Changed = Util.Signal.new() -- (key, value)
end

function Settings.Get(key: string): any
	return values[key]
end

function Settings.Set(key: string, value: any)
	if DEFAULTS[key] == nil or values[key] == value then
		return
	end
	values = table.clone(values)
	values[key] = value
	if key == "reducedMotion" then
		Util.ReducedMotion = value == true
	end
	Settings.Changed:Fire(key, value)
end

-- Qualite choisie dans le menu Roblox (appel frequent : relue au plus toutes les 2 s)
local function robloxQualityIsLow(): boolean
	local now = os.clock()
	if now - lowQualityReadAt < QUALITY_REFRESH then
		return lowQualityCache
	end
	lowQualityReadAt = now
	local ok, level = pcall(function()
		return UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end)
	lowQualityCache = ok and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= 3
	return lowQualityCache
end

-- Graphismes bas : moins de particules et d'effets
function Settings.IsLowGraphics(): boolean
	local mode = values.graphics
	if mode == "Low" then
		return true
	elseif mode == "High" then
		return false
	end
	return robloxQualityIsLow()
end

return Settings
