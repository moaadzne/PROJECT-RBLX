-- WaveService : cycle de la vague (calm, warning, wave, recede), simulee en maths, et type de maree du cycle.
-- Le serveur ne bouge aucune piece : les clients dessinent la vague a partir de WaveState.
-- Crochets : OnCalm(cycle, tide) au debut du calme, OnFront(prevFront, front) a chaque tick de la vague.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)

local WaveService = {}

local W = Config.Wave
local TRAVEL_TIME = (W.endZ - W.startZ) / W.speed
local CATCH_TICK = 0.1
local WAIT_TICK = 0.1
local SWEPT_EXTRA = 0.5 -- pas de ramassage pendant qu'on est emporte
local R6_FEET = 3

local cycle = 0
local wave = nil
local skipCalm = false
local forcedTide = nil -- debug : maree du prochain cycle
local cycleTide = "Normal"
local caught = {} -- [player] = true pendant la vague en cours
local exposed = {} -- [player] = true si sur la plage pendant la vague
local calmHooks = {}
local frontHooks = {}
local phaseHooks = {}
local caughtHooks = {}

local function now()
	return workspace:GetServerTimeNow()
end

-- Les heures sont planifiees a l'avance : clients et serveur calculent la meme vague
local function publish(phase, phaseStart, phaseEnd, startTime)
	wave = {
		phase = phase,
		phaseStart = phaseStart,
		phaseEnd = phaseEnd,
		startTime = startTime,
		cycle = cycle,
		tide = cycleTide,
		nextSpecial = Config.NextSpecial(cycle),
	}
	if Config.Royal.onSpecialTides and cycleTide ~= "Normal" then
		wave.royal = { active = true, endsAt = startTime + TRAVEL_TIME + W.recedeTime }
	end
	Net.SetWave(wave)
	for _, hook in ipairs(phaseHooks) do
		local ok, err = pcall(hook, phase, wave)
		if not ok then
			warn("[TideRush] crochet de phase : " .. tostring(err))
		end
	end
end

local function runHooks(hooks, ...)
	for _, hook in ipairs(hooks) do
		local ok, err = pcall(hook, ...)
		if not ok then
			warn("[TideRush] crochet de vague : " .. tostring(err))
		end
	end
end

local function waitUntil(t, canSkip)
	while now() < t do
		if canSkip and skipCalm then
			break
		end
		task.wait(WAIT_TICK)
	end
end

function WaveService.FrontZ(t)
	return math.min(W.endZ, W.startZ + W.speed * (t - wave.startTime))
end

local function feetY(humanoid, root)
	if humanoid.RigType == Enum.HumanoidRigType.R15 then
		return root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	end
	return root.Position.Y - R6_FEET
end

local function sweep(player, profile)
	caught[player] = true
	for _, hook in ipairs(caughtHooks) do
		local ok, err = pcall(hook, player, profile)
		if not ok then
			warn("[TideRush] crochet de prise : " .. tostring(err))
		end
	end
	local lost = profile.bag
	profile.bag = {}
	profile.sweptUntil = os.clock() + W.caughtDelay + SWEPT_EXTRA
	profile.data.stats.caught += 1
	Net.Notify(player, "caught", {
		lost = #lost,
		items = lost,
		text = if #lost > 0
			then ("The wave took %d treasure%s!"):format(#lost, #lost > 1 and "s" or "")
			else "Swept away by the wave!",
	})
	DataService.MarkDirty(player)
	task.delay(W.caughtDelay, function()
		if player.Parent then
			PlotService.SendHome(player)
		end
	end)
end

-- Attrape les joueurs dans le corps de la vague balaye depuis le dernier tick
local function checkPlayers(prevFront, front)
	for player, profile in DataService.All() do
		-- pendant son intro, le joueur vit sa propre vague : la vague globale ne le prend pas
		if profile.loaded and not profile.leaving and not profile.introActive and not caught[player] then
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and humanoid.Health > 0 then
				local pos = root.Position
				if pos.Z < Config.BaseLineZ then
					exposed[player] = true
					-- sur une Giant, il surfe la crete : jamais pris
					if not profile.surfing and pos.Z <= front and pos.Z >= prevFront - W.thickness
						and feetY(humanoid, root) < W.height then
						sweep(player, profile)
					end
				end
			end
		end
	end
end

local function rewardSurvivors()
	for player in pairs(exposed) do
		local profile = DataService.Get(player)
		if not caught[player] and player.Parent and profile and profile.loaded then
			profile.data.stats.wavesSurvived += 1
			Net.Notify(player, "survived", { text = "You survived the wave!" })
			DataService.MarkDirty(player)
		end
	end
end

local function runCycle()
	cycle += 1
	skipCalm = false
	cycleTide = forcedTide or Config.TideFor(cycle)
	forcedTide = nil
	local calmStart = now()
	local departure = calmStart + W.calmTime + W.warningTime
	publish("calm", calmStart, calmStart + W.calmTime, departure)
	runHooks(calmHooks, cycle, wave.tide)
	waitUntil(calmStart + W.calmTime, true)
	if skipCalm then
		departure = now() + W.warningTime
	end

	publish("warning", departure - W.warningTime, departure, departure)
	waitUntil(departure)

	local arrival = departure + TRAVEL_TIME
	publish("wave", departure, arrival, departure)
	table.clear(caught)
	table.clear(exposed)
	local prevFront = W.startZ
	while true do
		local t = now()
		local front = WaveService.FrontZ(t)
		checkPlayers(prevFront, front)
		runHooks(frontHooks, prevFront, front)
		prevFront = front
		if t >= arrival then
			break
		end
		task.wait(CATCH_TICK)
	end
	rewardSurvivors()

	publish("recede", arrival, arrival + W.recedeTime, departure)
	waitUntil(arrival + W.recedeTime)
end

-- Debug : pendant le calme, l'alerte demarre tout de suite
function WaveService.Force()
	if wave and wave.phase == "calm" then
		skipCalm = true
	end
	return wave and wave.phase
end

-- Debug : maree du prochain cycle (Normal, Golden...)
function WaveService.ForceTide(tide)
	if not Config.Tides[tide] then
		return false
	end
	forcedTide = tide
	return true
end

function WaveService.Get()
	return wave
end

function WaveService.OnCalm(callback)
	table.insert(calmHooks, callback)
end

function WaveService.OnFront(callback)
	table.insert(frontHooks, callback)
end

-- callback(phase, wave) a chaque changement de phase de la vague globale
function WaveService.OnPhase(callback)
	table.insert(phaseHooks, callback)
end

-- callback(player, profile) quand la vague prend un joueur (avant que son sac soit vide)
function WaveService.OnCaught(callback)
	table.insert(caughtHooks, callback)
end

-- Duree d'un cycle complet (calme + alerte + trajet + reflux), en secondes
WaveService.CycleTime = W.calmTime + W.warningTime + TRAVEL_TIME + W.recedeTime

function WaveService.Forget(player)
	caught[player] = nil
	exposed[player] = nil
end

function WaveService.Start()
	task.spawn(function()
		while true do
			local ok, err = pcall(runCycle)
			if not ok then
				warn("[TideRush] cycle de vague : " .. tostring(err))
				task.wait(1)
			end
		end
	end)
end

return WaveService
