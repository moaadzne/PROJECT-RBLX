-- UpgradeService : achat des ameliorations (Speed, Bag, Slots) avec les pieces du jeu.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)

local UpgradeService = {}

local function buy(player, kind)
	if type(kind) ~= "string" then
		return false, "BadRequest"
	end
	local def = Config.Upgrades[kind]
	if not def then
		return false, "BadRequest"
	end
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local d = profile.data
	local level = d.levels[kind]
	if level >= def.maxLevel then
		return false, "MaxLevel"
	end
	if not DataService.TrySpend(player, Config.GetUpgradeCost(kind, level)) then
		return false, "NotEnoughCoins"
	end
	local newLevel = level + 1
	d.levels[kind] = newLevel
	d.stats.upgradesBought += 1

	if kind == "Speed" then
		PlotService.ApplySpeed(player)
	elseif kind == "Slots" then
		d.display = Stats.NormalizeDisplay(d)
		PlotService.RenderDisplay(player)
	end

	local value = Config.GetUpgradeValue(kind, newLevel)
	Net.Notify(player, "upgrade", {
		kind = kind,
		level = newLevel,
		value = value,
		text = ("%s Lv %d: %s%s"):format(def.label, newLevel, Config.Format(value), def.unit),
	})
	DataService.MarkDirty(player)
	return true, newLevel
end

function UpgradeService.Start()
	Net.Handle("BuyUpgrade", buy)
end

return UpgradeService
