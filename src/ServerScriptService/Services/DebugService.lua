-- DebugService : ServerStorage.TR_Debug (BindableFunction), cree seulement dans Studio.
-- Exemple (execute_luau, mode Server) : game.ServerStorage.TR_Debug:Invoke("addCoins", 5000)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Services = script.Parent
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local TreasureService = require(Services.TreasureService)
local WaveService = require(Services.WaveService)
local SelfTest = require(Services.SelfTest)

local DebugService = {}

local HELP = table.concat({
	"help",
	"state [joueur]             -> etat JSON",
	"addCoins n [joueur]        -> ajoute n pieces",
	"give itemId [n] [joueur]   -> met n tresors dans le sac",
	"level kind n [joueur]      -> fixe le niveau Speed|Bag|Slots",
	"forceWave                  -> pendant le calme, l'alerte demarre tout de suite",
	"home [joueur]              -> teleport a la base",
	"treasures                  -> tresors par zone",
	"save [joueur]              -> sauvegarde immediate",
	"selftest                   -> rejoue les verifications essentielles",
}, "\n")

local function findPlayer(name)
	if type(name) == "string" then
		return Players:FindFirstChild(name)
	end
	return Players:GetPlayers()[1]
end

local function vectorsToText(value)
	if typeof(value) == "Vector3" then
		return ("%.1f, %.1f, %.1f"):format(value.X, value.Y, value.Z)
	end
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for k, v in pairs(value) do
		out[k] = vectorsToText(v)
	end
	return out
end

local commands = {}

function commands.help()
	return HELP
end

function commands.state(name)
	local player = findPlayer(name)
	local profile = player and DataService.Get(player)
	if not profile then
		return "aucun joueur"
	end
	local state = DataService.BuildState(profile)
	state.wave = WaveService.Get()
	state.position = player.Character and player.Character:GetPivot().Position
	return HttpService:JSONEncode(vectorsToText(state))
end

function commands.addCoins(amount, name)
	local player = findPlayer(name)
	if not player or type(amount) ~= "number" then
		return "usage : addCoins n [joueur]"
	end
	DataService.AddCoins(player, amount)
	return "ok"
end

function commands.give(itemId, count, name)
	local player = findPlayer(name)
	return player and TreasureService.GiveToBag(player, itemId, count) and "ok" or "echec"
end

function commands.level(kind, level, name)
	local player = findPlayer(name)
	local profile = player and DataService.Get(player)
	if not profile or not profile.data.levels[kind] or type(level) ~= "number" then
		return "usage : level Speed|Bag|Slots n [joueur]"
	end
	profile.data.levels[kind] = level
	profile.data.display = Stats.NormalizeDisplay(profile.data)
	PlotService.ApplySpeed(player)
	PlotService.RenderDisplay(player)
	DataService.MarkDirty(player)
	return "ok"
end

function commands.forceWave()
	return "phase avant : " .. tostring(WaveService.Force())
end

function commands.home(name)
	local player = findPlayer(name)
	return player and PlotService.SendHome(player) and "ok" or "echec"
end

function commands.treasures()
	return HttpService:JSONEncode(TreasureService.Counts())
end

function commands.save(name)
	local player = findPlayer(name)
	return player and DataService.Save(player) and "ok" or "echec (sauvegarde coupee ?)"
end

function commands.selftest()
	return SelfTest.Run()
end

function DebugService.Start()
	if not RunService:IsStudio() then
		return
	end
	local old = ServerStorage:FindFirstChild("TR_Debug")
	if old then
		old:Destroy()
	end
	local hook = Instance.new("BindableFunction")
	hook.Name = "TR_Debug"
	hook.OnInvoke = function(command, ...)
		local handler = commands[command]
		if not handler then
			return "commande inconnue. " .. HELP
		end
		return handler(...)
	end
	hook.Parent = ServerStorage
end

return DebugService
