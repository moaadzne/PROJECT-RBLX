-- IntroService : les premieres minutes d'un nouveau joueur (GDD 1 ter).
-- 1. Creatures personnelles sur la plage en face de son lagon, puis vague d'intro propre a lui, 18 s apres le chargement :
--    elle ne peut pas le prendre (il garde son sac) mais emporte ses creatures restees sur le sable.
-- 2. Au calme global suivant : maree Golden personnelle, avec des creatures personnelles dont au moins une mutee.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local WaveService = require(Services.WaveService)
local CreatureService = require(Services.CreatureService)

local IntroService = {}

local TICK = 0.1
local SHALLOWS = 1 -- premier anneau autour de la crique

local rng = Random.new()
local goldenCycle = {} -- [player] = cycle de sa maree Golden personnelle

local function now()
	return workspace:GetServerTimeNow()
end

local function alive(player, profile)
	return player.Parent ~= nil and not profile.leaving and DataService.Get(player) == profile
end

-- Attend jusqu'a t ; false si le joueur est parti entre-temps
local function waitUntil(player, profile, t)
	while now() < t do
		if not alive(player, profile) then
			return false
		end
		task.wait(TICK)
	end
	return alive(player, profile)
end

-- Direction de la crique vers le lagon du joueur (vers la mer en face de chez lui)
local function outwardOf(player)
	local index = PlotService.GetIndex(player)
	return index and PlotService.OutwardOf(index) or Vector3.new(0, 0, -1)
end

local function introCreatures(player)
	local outward = outwardOf(player)
	local right = outward:Cross(Vector3.yAxis)
	local c = Config.Island.center
	local list = {}
	for _, entry in ipairs(Config.Intro.creatures) do
		local p = c + outward * (Config.Island.coveRadius + entry.out) + right * entry.side
		local ground = CreatureService.GroundAt(p.X, p.Z) or Vector3.new(p.X, Config.Island.seaY, p.Z)
		table.insert(list, { species = entry.species, mutation = entry.mutation, ground = ground })
	end
	return list
end

local function runIntro(player, profile)
	local W, I = Config.Wave, Config.Intro
	local t0 = now()
	local alertAt = t0 + I.waveDelay
	local departure = alertAt + I.warningTime
	local arrival = departure + I.travel
	-- vague propre au joueur : elle vient de la mer en face de son lagon et s'arrete au bord de la crique
	local dir = -outwardOf(player)
	local endD = -Config.Island.coveRadius
	local startD = endD - W.speed * I.travel
	local function personalWave(phase, phaseStart, phaseEnd)
		local global = Net.GetWave()
		return {
			phase = phase,
			phaseStart = phaseStart,
			phaseEnd = phaseEnd,
			startTime = departure,
			cycle = 0,
			tide = "Normal",
			nextSpecial = global and global.nextSpecial or Config.NextSpecial(0),
			direction = "",
			dir = dir,
			startD = startD,
			endD = endD,
			nextDirection = global and global.nextDirection or nil,
			intro = true,
		}
	end

	profile.introActive = true
	CreatureService.SpawnPersonal(player, introCreatures(player))
	Net.SetPersonalWave(player, personalWave("calm", t0, alertAt))
	local finished = false
	if waitUntil(player, profile, alertAt) then
		Net.SetPersonalWave(player, personalWave("warning", alertAt, departure))
		if waitUntil(player, profile, departure) then
			local wave = personalWave("wave", departure, arrival)
			Net.SetPersonalWave(player, wave)
			while alive(player, profile) do
				local t = now()
				CreatureService.WashAway(wave, Config.WaveFrontD(wave, t), player.UserId)
				if t >= arrival then
					break
				end
				task.wait(TICK)
			end
			if alive(player, profile) then
				Net.SetPersonalWave(player, personalWave("recede", arrival, arrival + I.recedeTime))
				finished = waitUntil(player, profile, arrival + I.recedeTime)
			end
		end
	end
	profile.introActive = false
	if not finished then
		return -- parti pendant l'intro : elle rejouera a la prochaine connexion
	end
	profile.data.introStep = 1
	DataService.MarkDirty(player)
	Net.SetPersonalWave(player, nil) -- retour sur la vague globale
	Net.Notify(player, "info", { text = "They grow while you're away. The next tide will be golden!" })
end

function IntroService.Begin(player, profile)
	if profile.introActive then
		return false
	end
	task.spawn(function()
		local ok, err = pcall(runIntro, player, profile)
		if not ok then
			profile.introActive = false
			warn(("[TideRush] intro de %s : %s"):format(player.Name, tostring(err)))
		end
	end)
	return true
end

local function startGolden(player, profile, cycle, tide)
	local I = Config.Intro
	profile.data.introStep = 2
	DataService.MarkDirty(player)
	goldenCycle[player] = cycle
	if tide ~= I.goldenTide then
		Net.SetPersonalTide(player, I.goldenTide)
	end
	local list = {}
	for _ = 1, I.goldenCount do
		local spot = CreatureService.FindSpot(SHALLOWS)
		if spot then
			local species = Stats.PickWeighted(Config.Rings[SHALLOWS].creatures, rng)
			table.insert(list, { species = species, mutation = Stats.RollMutation(I.goldenTide, rng), ground = spot })
		end
	end
	-- promesse de l'intro : au moins une creature mutee dans cette maree
	local anyMutated = false
	for _, entry in ipairs(list) do
		anyMutated = anyMutated or entry.mutation ~= ""
	end
	local odds = Config.Tides[I.goldenTide].odds
	if not anyMutated and list[1] and odds[1] then
		list[1].mutation = odds[1][1]
	end
	CreatureService.SpawnPersonal(player, list)
	Net.Notify(player, "info", { text = "A Golden Tide, just for you!" })
end

local function onCalm(cycle, tide)
	for player, profile in DataService.All() do
		if profile.loaded and not profile.leaving then
			local golden = goldenCycle[player]
			if golden and cycle > golden then
				goldenCycle[player] = nil
				Net.SetPersonalTide(player, nil)
			end
			if profile.data.introStep == 1 and not profile.introActive then
				startGolden(player, profile, cycle, tide)
			end
		end
	end
end

-- Debug : rejoue l'intro depuis le debut
function IntroService.Restart(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false
	end
	profile.data.introStep = 0
	DataService.MarkDirty(player)
	return IntroService.Begin(player, profile)
end

function IntroService.Forget(player)
	goldenCycle[player] = nil
end

function IntroService.Start()
	DataService.OnLoaded(function(player, profile)
		if profile.data.introStep == 0 then
			IntroService.Begin(player, profile)
		end
	end)
	WaveService.OnCalm(onCalm)
end

return IntroService
