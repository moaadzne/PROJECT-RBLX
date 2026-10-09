-- DebugService : ServerStorage.TR_Debug (BindableFunction), cree seulement dans Studio.
-- Exemple (execute_luau, mode Server) : game.ServerStorage.TR_Debug:Invoke("addCoins", 5000)
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local CreatureService = require(Services.CreatureService)
local IntroService = require(Services.IntroService)
local StealService = require(Services.StealService)
local WaveService = require(Services.WaveService)
local SelfTest = require(Services.SelfTest)

local DebugService = {}

local HELP = table.concat({
	"help",
	"state [joueur]             -> etat JSON",
	"addCoins n [joueur]        -> ajoute n pieces",
	"give species [n] [mutation] [joueur] -> met n creatures dans le sac",
	"level kind n [joueur]      -> fixe le niveau Speed|Bag|Slots",
	"forceWave                  -> pendant le calme, l'alerte demarre tout de suite",
	"tide Normal|Golden         -> maree du prochain cycle",
	"grow minutes [joueur]      -> vieillit les creatures des bassins",
	"intro [joueur]             -> rejoue l'intro",
	"playtime minutes [joueur]  -> temps de jeu cumule (protection debutant)",
	"steal voleur vole          -> le voleur prend une creature du vole (sans protections)",
	"home [joueur]              -> teleport a la base",
	"creatures                  -> creatures par zone (+ personnelles)",
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
	state.wave = Net.GetWaveFor(player)
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

function commands.give(species, count, mutation, name)
	local player = findPlayer(name)
	return player and CreatureService.GiveToBag(player, species, count, mutation) and "ok" or "echec"
end

function commands.tide(tide)
	return WaveService.ForceTide(tide) and "ok : prochain cycle" or "usage : tide Normal|Golden"
end

-- Recule l'heure de naissance : equivaut a attendre `minutes`
function commands.grow(minutes, name)
	local player = findPlayer(name)
	local profile = player and DataService.Get(player)
	if not profile or type(minutes) ~= "number" or minutes <= 0 then
		return "usage : grow minutes [joueur]"
	end
	for _, creature in ipairs(profile.data.pools) do
		if creature then
			creature.born -= math.floor(minutes * 60)
		end
	end
	DataService.MarkDirty(player)
	return "ok"
end

function commands.playtime(minutes, name)
	local player = findPlayer(name)
	local profile = player and DataService.Get(player)
	if not profile or type(minutes) ~= "number" then
		return "usage : playtime minutes [joueur]"
	end
	profile.data.playTime = minutes * 60
	DataService.MarkDirty(player)
	return "ok"
end

function commands.steal(thiefName, victimName)
	local thief, victim = findPlayer(thiefName), Players:FindFirstChild(tostring(victimName))
	return thief and victim and StealService.ForceGrab(thief, victim) and "ok" or "usage : steal voleur vole"
end

function commands.intro(name)
	local player = findPlayer(name)
	return player and IntroService.Restart(player) and "ok" or "echec (intro deja en cours ?)"
end

function commands.level(kind, level, name)
	local player = findPlayer(name)
	local profile = player and DataService.Get(player)
	if not profile or not profile.data.levels[kind] or type(level) ~= "number" then
		return "usage : level Speed|Bag|Slots n [joueur]"
	end
	profile.data.levels[kind] = level
	profile.data.pools = Stats.NormalizePools(profile.data)
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

function commands.creatures()
	return HttpService:JSONEncode(CreatureService.Counts())
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
