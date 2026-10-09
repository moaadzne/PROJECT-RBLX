-- LagoonService : ouverture des lagons pilotee par la vague (GDD 2, 4.7).
-- Calme et reflux : fermes. Alerte et vague : ouverts (fenetre de vol), sauf lagon verrouille ou protege.
-- Le serveur fait autorite : attributs Open / Locked / Shield sur PlotN, attribut Open et CanCollide sur PlotN.Barrier,
-- groupes de collision (le proprietaire passe toujours, la Revanche passe pendant sa fenetre),
-- et ejection 10 fois/s de tout joueur present sans droit dans un lagon ferme.
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local WaveService = require(Services.WaveService)

local LagoonService = {}

local TICK = 0.1
local EJECT_GAP = 5 -- studs devant la limite avant du lagon
local EJECT_HEIGHT = 4
local CHAR_GROUP = "TR_Char"
local BARRIER_GROUP = "TR_Barrier"

local S = Config.Steal
local groupsReady = false
local plotState = {} -- [index] = { open, shield, locked }
local barrierParts = {} -- [index] = { [part] = CanCollide d'origine }
local revengePairs = {} -- { {charIndex, barrierIndex} } ouverts pendant la fenetre

local function windowOpen(wave)
	return wave ~= nil and (wave.phase == "warning" or wave.phase == "wave")
end

function LagoonService.IsWindowOpen()
	return windowOpen(Net.GetWave())
end

-- Vols subis dans les 10 dernieres minutes
local function recentStolen(d, now)
	local count = 0
	for _, t in ipairs(d.stolenAt) do
		if now - t < 600 then
			count += 1
		end
	end
	return count
end

-- Pourquoi le lagon de ce joueur reste ferme aux voleurs : "" | "lock" | "stolen" | "cap" | "newbie"
function LagoonService.Shield(profile)
	local d = profile.data
	local wave = Net.GetWave()
	local now = os.time()
	if profile.lockCycle and wave and wave.cycle == profile.lockCycle then
		return "lock"
	end
	if now < d.protectedUntil then
		return "stolen"
	end
	if recentStolen(d, now) >= S.maxStolenPer10Min then
		return "cap"
	end
	if Stats.IsNewbie(d) then
		return "newbie"
	end
	return ""
end

local function hasRevenge(player, ownerUserId, wave)
	local profile = DataService.Get(player)
	local revenge = profile and profile.revenge
	return revenge ~= nil and wave ~= nil and revenge.userId == ownerUserId and revenge.cycle == wave.cycle
end

-- Ce joueur peut-il etre dans le lagon `index` en ce moment ?
function LagoonService.CanEnter(player, index)
	local model = PlotService.GetModel(index)
	local owner = model and model:GetAttribute("Owner")
	if not owner or owner == player.UserId then
		return true
	end
	local state = plotState[index]
	if state and state.open then
		return true
	end
	local wave = Net.GetWave()
	return windowOpen(wave) and hasRevenge(player, owner, wave)
end

-- Un lagon est-il ouvert aux voleurs pour ce joueur (fenetre + pas de bouclier, ou Revanche) ?
function LagoonService.CanRaid(player, index)
	local model = PlotService.GetModel(index)
	local owner = model and model:GetAttribute("Owner")
	if not owner or owner == player.UserId then
		return false
	end
	local wave = Net.GetWave()
	if not windowOpen(wave) then
		return false
	end
	local state = plotState[index]
	return (state ~= nil and state.open) or hasRevenge(player, owner, wave)
end

-- Groupes de collision -----------------------------------------------------------

local function setupGroups()
	local ok, err = pcall(function()
		for i = 1, Config.MaxPlayersPerServer do
			for _, name in ipairs({ CHAR_GROUP .. i, BARRIER_GROUP .. i }) do
				if not PhysicsService:IsCollisionGroupRegistered(name) then
					PhysicsService:RegisterCollisionGroup(name)
				end
			end
		end
		for i = 1, Config.MaxPlayersPerServer do
			for j = 1, Config.MaxPlayersPerServer do
				PhysicsService:CollisionGroupSetCollidable(CHAR_GROUP .. i, BARRIER_GROUP .. j, i ~= j)
			end
		end
	end)
	groupsReady = ok
	if not ok then
		warn("[TideRush] groupes de collision des lagons indisponibles : " .. tostring(err))
	end
end

local function setCharacterGroup(player, character)
	if not groupsReady then
		return
	end
	local index = PlotService.GetIndex(player)
	local group = index and (CHAR_GROUP .. index) or "Default"
	local function apply(part)
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
	for _, part in ipairs(character:GetDescendants()) do
		apply(part)
	end
	character.DescendantAdded:Connect(apply)
end

local function setRevengePair(charIndex, barrierIndex, open)
	if groupsReady then
		PhysicsService:CollisionGroupSetCollidable(CHAR_GROUP .. charIndex, BARRIER_GROUP .. barrierIndex, not open)
	end
end

-- Revanche : pendant la fenetre de son cycle, la barriere du voleur ne bloque pas le vole
local function openRevengePairs(wave)
	for player, profile in DataService.All() do
		local revenge = profile.revenge
		if revenge and revenge.cycle == wave.cycle then
			local thief = Players:GetPlayerByUserId(revenge.userId)
			local mine, theirs = PlotService.GetIndex(player), thief and PlotService.GetIndex(thief)
			if mine and theirs then
				setRevengePair(mine, theirs, true)
				table.insert(revengePairs, { mine, theirs })
			end
		end
	end
end

local function closeRevengePairs()
	for _, pair in ipairs(revengePairs) do
		setRevengePair(pair[1], pair[2], false)
	end
	table.clear(revengePairs)
end

-- Barrieres -----------------------------------------------------------------------

local function barrierOf(index)
	local model = PlotService.GetModel(index)
	return model and model:FindFirstChild("Barrier")
end

local function setupBarrier(index)
	local barrier = barrierOf(index)
	local parts = {}
	if barrier then
		for _, part in ipairs(barrier:GetDescendants()) do
			if part:IsA("BasePart") then
				parts[part] = part.CanCollide
				if groupsReady then
					part.CollisionGroup = BARRIER_GROUP .. index
				end
			end
		end
	end
	barrierParts[index] = parts
end

local function applyBarrier(index, open)
	local barrier = barrierOf(index)
	if barrier then
		barrier:SetAttribute("Open", open)
	end
	for part, collides in pairs(barrierParts[index] or {}) do
		if part.Parent then
			part.CanCollide = collides and not open
		end
	end
end

-- Etat de chaque lagon, recalcule 10 fois/s ; n'ecrit que ce qui change
local function refreshPlots()
	local wave = Net.GetWave()
	local isWindow = windowOpen(wave)
	for index = 1, Config.MaxPlayersPerServer do
		local model = PlotService.GetModel(index)
		if model then
			local ownerId = model:GetAttribute("Owner")
			local owner = ownerId and Players:GetPlayerByUserId(ownerId)
			local profile = owner and DataService.Get(owner)
			local shield = (profile and profile.loaded) and LagoonService.Shield(profile) or ""
			local open = isWindow and profile ~= nil and profile.loaded and shield == ""
			local locked = profile ~= nil and profile.lockCycle ~= nil and wave ~= nil and profile.lockCycle >= wave.cycle
			local state = plotState[index]
			if not state or state.open ~= open or state.shield ~= shield or state.locked ~= locked then
				plotState[index] = { open = open, shield = shield, locked = locked }
				model:SetAttribute("Open", open)
				model:SetAttribute("Locked", locked)
				model:SetAttribute("Shield", shield)
				applyBarrier(index, open)
			end
			if profile and (profile.shield ~= shield or profile.lockActive ~= locked) then
				profile.shield = shield
				profile.lockActive = locked
				DataService.MarkDirty(owner)
			end
		end
	end
end

local function plotAt(position)
	for index = 1, Config.MaxPlayersPerServer do
		local model = PlotService.GetModel(index)
		if model and PlotService.IsInPlot(index, position) then
			return index, model
		end
	end
	return nil, nil
end

-- Ramene devant la barriere tout joueur present sans droit dans un lagon ferme
local function ejectIntruders()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root then
			local index, model = plotAt(root.Position)
			if index and not LagoonService.CanEnter(player, index) then
				local minZ = model:GetAttribute("MinZ")
				local target = Vector3.new(root.Position.X, Config.Beach.groundY + EJECT_HEIGHT, minZ - EJECT_GAP)
				character:PivotTo(CFrame.lookAt(target, target - Vector3.zAxis))
				root.AssemblyLinearVelocity = Vector3.zero
				local profile = DataService.Get(player)
				if profile then
					profile.movedByServerAt = os.clock()
				end
			end
		end
	end
end

local function tickLoop()
	while true do
		task.wait(TICK)
		refreshPlots()
		ejectIntruders()
	end
end

-- Verrou gratuit -------------------------------------------------------------------

local function lockLagoon(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	if not PlotService.GetIndex(player) then
		return false, "NoPlot"
	end
	local d = profile.data
	local now = os.time()
	if now < d.lockReadyAt then
		return false, "Cooldown"
	end
	local wave = Net.GetWave()
	if not wave then
		return false, "Busy"
	end
	-- au reflux, la fenetre est finie : le verrou couvre la suivante
	local lockCycle = wave.cycle
	local lockEnds = wave.startTime + WaveService.CycleTime - Config.Wave.calmTime - Config.Wave.warningTime
	if wave.phase == "recede" then
		lockCycle += 1
		lockEnds += WaveService.CycleTime
	end
	profile.lockCycle = lockCycle
	d.lockReadyAt = math.ceil(lockEnds + S.lockCooldownCycles * WaveService.CycleTime)
	Net.Notify(player, "lock", {
		active = true,
		readyAt = d.lockReadyAt,
		text = "Lagoon locked for the next wave.",
	})
	DataService.MarkDirty(player)
	refreshPlots()
	return true, d.lockReadyAt
end

-- Revanche : le vole peut entrer chez son voleur pendant la prochaine fenetre
function LagoonService.GiveRevenge(victim, thief)
	local profile = DataService.Get(victim)
	local wave = Net.GetWave()
	if not profile or not wave then
		return
	end
	profile.revenge = { userId = thief.UserId, name = thief.DisplayName, cycle = wave.cycle + 1 }
	Net.Notify(victim, "revenge", {
		thief = thief.UserId,
		thiefName = thief.DisplayName,
		text = ("Revenge! %s's lagoon opens for you at the next alert."):format(thief.DisplayName),
	})
	DataService.MarkDirty(victim)
end

function LagoonService.Track(player)
	player.CharacterAdded:Connect(function(character)
		setCharacterGroup(player, character)
	end)
	if player.Character then
		setCharacterGroup(player, player.Character)
	end
end

function LagoonService.Start()
	setupGroups()
	for index = 1, Config.MaxPlayersPerServer do
		if PlotService.GetModel(index) then
			setupBarrier(index)
		end
	end
	WaveService.OnPhase(function(phase, wave)
		if phase == "warning" then
			openRevengePairs(wave)
		elseif phase == "recede" then
			closeRevengePairs()
		end
		refreshPlots()
	end)
	Net.Handle("LockLagoon", lockLagoon)
	task.spawn(function()
		while true do
			local ok, err = pcall(tickLoop)
			warn("[TideRush] boucle des lagons relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
end

return LagoonService
