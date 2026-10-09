-- RoyalService : Maree Royale (GDD 4.8). A chaque maree speciale, une manche pour tout le serveur pendant le cycle.
-- Score = valeur (revenu/s) des creatures attrapees et volees pendant la manche.
-- Fin du reflux : top 3 = couronne (attribut Crown) jusqu'a la manche suivante + pieces (5 / 3 / 2 min de revenu).
-- Une creature royale unique, toujours mutee, apparait au bout de la zone au debut de la manche.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local WaveService = require(Services.WaveService)
local CreatureService = require(Services.CreatureService)
local StealService = require(Services.StealService)

local RoyalService = {}

local BOARD_TICK = 1
local CROWN_TEXT = { "gold", "silver", "bronze" }

local round = nil -- { cycle, endsAt, scores = { [player] = score } }
local boardDirty = false

local function sortedTop()
	local list = {}
	if round then
		for player, score in pairs(round.scores) do
			if player.Parent then
				table.insert(list, { userId = player.UserId, name = player.DisplayName, score = score, player = player })
			end
		end
	end
	table.sort(list, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.userId < b.userId
	end)
	return list
end

local function publicTop(list)
	local out = {}
	for i, entry in ipairs(list) do
		out[i] = { userId = entry.userId, name = entry.name, score = entry.score }
	end
	return out
end

local function sendBoard()
	boardDirty = false
	if not round then
		return
	end
	Net.FireAll("RoyalBoard", { cycle = round.cycle, endsAt = round.endsAt, top = publicTop(sortedTop()) })
end

local function setCrown(player, rank)
	local profile = DataService.Get(player)
	if profile then
		profile.crown = rank
		DataService.MarkDirty(player)
	end
	if player.Parent then
		player:SetAttribute("Crown", rank)
	end
end

function RoyalService.AddScore(player, value)
	local wave = Net.GetWave()
	if not round or not wave or wave.cycle ~= round.cycle or type(value) ~= "number" or not (value > 0) then
		return
	end
	round.scores[player] = (round.scores[player] or 0) + value
	boardDirty = true
end

local function startRound(wave)
	-- les couronnes de la manche precedente tombent
	for _, player in ipairs(Players:GetPlayers()) do
		if (player:GetAttribute("Crown") or 0) ~= 0 then
			setCrown(player, 0)
		end
	end
	round = { cycle = wave.cycle, endsAt = wave.royal.endsAt, scores = {} }
	for _, player in ipairs(Players:GetPlayers()) do
		round.scores[player] = 0
	end
	CreatureService.SpawnRoyal(Config.Royal.royalMutation)
	Net.NotifyAll("royal", { phase = "start", top = {}, text = "Royal Tide! Catch and steal the most valuable creatures." })
	sendBoard()
end

local function finishRound()
	local finished = round
	local list = sortedTop()
	local top = publicTop(list)
	local now = os.time()
	local ranked = {}
	for rank = 1, math.min(#Config.Royal.rewardMinutes, #list) do
		local entry = list[rank]
		if entry.score > 0 then
			local profile = DataService.Get(entry.player)
			local coins = 0
			if profile and profile.loaded then
				coins = math.floor(Stats.Income(profile.data, now) * 60 * Config.Royal.rewardMinutes[rank])
				if coins > 0 then
					DataService.AddCoins(entry.player, coins)
				end
			end
			setCrown(entry.player, rank)
			ranked[entry.player] = { rank = rank, coins = coins }
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local mine = ranked[player]
		Net.Notify(player, "royal", {
			phase = "end",
			top = top,
			rank = mine and mine.rank or nil,
			coins = mine and mine.coins or nil,
			text = mine and ("Royal Tide: you win the %s crown! +%s"):format(CROWN_TEXT[mine.rank], Config.Format(mine.coins))
				or "Royal Tide is over.",
		})
	end
	Net.FireAll("RoyalBoard", { cycle = finished.cycle, endsAt = finished.endsAt, top = top })
	round = nil
end

function RoyalService.Forget(player)
	if round then
		round.scores[player] = nil
		boardDirty = true
	end
end

function RoyalService.Start()
	CreatureService.OnCapture(function(player, _, _, value)
		RoyalService.AddScore(player, value)
	end)
	StealService.OnStolen(function(thief, _, value)
		RoyalService.AddScore(thief, value)
	end)
	WaveService.OnPhase(function(phase, wave)
		if phase ~= "calm" then
			return
		end
		-- debut d'un cycle : la manche du cycle precedent est finie (fin du reflux)
		if round and round.cycle < wave.cycle then
			finishRound()
		end
		if wave.royal then
			startRound(wave)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(BOARD_TICK)
			if boardDirty then
				local ok, err = pcall(sendBoard)
				if not ok then
					warn("[TideRush] classement royal : " .. tostring(err))
				end
			end
		end
	end)
end

return RoyalService
