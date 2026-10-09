-- Tide Rush : point d'entree serveur. Demarre les services, puis gere l'arrivee et le depart des joueurs.
local Players = game:GetService("Players")

local Services = script.Parent:WaitForChild("Services")
local Net = require(Services.Net)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local CreatureService = require(Services.CreatureService)
local IntroService = require(Services.IntroService)
local LagoonService = require(Services.LagoonService)
local WaveService = require(Services.WaveService)
local UpgradeService = require(Services.UpgradeService)
local PetService = require(Services.PetService)
local DebugService = require(Services.DebugService)

-- WaveService en dernier : ses crochets (OnCalm, OnFront) sont branches avant le premier cycle
for _, service in ipairs({
	DataService, PlotService, CreatureService, IntroService, LagoonService,
	UpgradeService, PetService, WaveService, DebugService,
}) do
	service.Start()
end

local function onPlayerAdded(player)
	DataService.Track(player) -- profil cree tout de suite, donnees chargees en fond
	PlotService.Assign(player)
	LagoonService.Track(player)
	Net.SendWave(player)
end

local function onPlayerRemoving(player)
	PlotService.Release(player)
	CreatureService.Forget(player)
	IntroService.Forget(player)
	WaveService.Forget(player)
	Net.Forget(player)
	DataService.Release(player) -- derniere sauvegarde : attend le DataStore, donc en dernier
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end
