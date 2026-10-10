-- StealService : vol entre lagons (GDD 4.7). Tout est verifie cote serveur, rien n'est cru du client.
-- StartSteal(plot, slot) lance un maintien de 1 s pres du bassin ; si le voleur n'a pas bouge, il prend la creature.
-- Elle reste dans les donnees du vole jusqu'a la reussite : un crash ou un depart ne fait jamais rien perdre.
-- Reussite : le voleur rentre dans son lagon avant la fin du reflux.
-- Retour au proprietaire : il touche le voleur, fin du reflux, vague, mort, depart de l'un des deux.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local WaveService = require(Services.WaveService)
local LagoonService = require(Services.LagoonService)

local StealService = {}

local TICK = 0.1
local S = Config.Steal

local holds = {} -- [thief] = { victim, plot, slot, uid, endsAt, startPos }
local stolenHooks = {}

local function rootOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if root and humanoid and humanoid.Health > 0 then
		return root
	end
	return nil
end

local function flat(a, b)
	return Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
end

local function setCarryAttribute(player, creature)
	player:SetAttribute("Carrying", creature and (creature.id .. ":" .. creature.mut) or "")
end

-- Verifie qu'un vol est permis ; renvoie creature, victim, victimProfile ou nil, code
local function validate(thief, plot, slot)
	local profile = DataService.Get(thief)
	if not profile or not profile.loaded then
		return nil, "NotLoaded"
	end
	if not PlotService.GetIndex(thief) then
		return nil, "NoPlot"
	end
	if not LagoonService.IsWindowOpen() then
		return nil, "Closed"
	end
	if Stats.IsNewbie(profile.data) then
		return nil, "Newbie"
	end
	if profile.mountUid ~= "" then
		return nil, "Mounted"
	end
	if profile.carrying then
		return nil, "Carrying"
	end
	local victim = PlotService.OwnerOf(plot)
	if not victim or victim == thief then
		return nil, "NotStealable"
	end
	if not LagoonService.CanRaid(thief, plot) then
		return nil, "Locked"
	end
	local victimProfile = DataService.Get(victim)
	if not victimProfile or not victimProfile.loaded or victimProfile.leaving then
		return nil, "NotStealable"
	end
	local vd = victimProfile.data
	if Stats.IsNewbie(vd) then
		return nil, "Newbie"
	end
	local creature = slot <= Stats.Slots(vd) and vd.pools[slot] or nil
	if not creature then
		return nil, "NotStealable"
	end
	if victimProfile.mountUid == creature.uid then
		return nil, "Mounted"
	end
	if victimProfile.carriedOut[creature.uid] then
		return nil, "NotStealable"
	end
	local carried = 0
	for _ in pairs(victimProfile.carriedOut) do
		carried += 1
	end
	-- on laisse toujours au moins une creature au vole
	if Stats.CreatureCount(vd) - carried < 2 then
		return nil, "LastCreature"
	end
	local root = rootOf(thief)
	local pedestal = PlotService.PedestalOf(plot, slot)
	if not root or not pedestal or not PlotService.IsInPlot(plot, root.Position)
		or flat(root.Position, pedestal.Position) > S.grabRange then
		return nil, "TooFar"
	end
	return creature, victim, victimProfile
end

local function startSteal(thief, plot, slot)
	if type(plot) ~= "number" or type(slot) ~= "number" or plot ~= plot or slot ~= slot
		or plot % 1 ~= 0 or slot % 1 ~= 0 or plot < 1 or plot > Config.MaxPlayersPerServer
		or slot < 1 or slot > Config.MaxSlots then
		return false, "BadRequest"
	end
	if holds[thief] then
		return false, "Busy"
	end
	local creature, victim = validate(thief, plot, slot)
	if not creature then
		return false, victim -- victim contient le code
	end
	holds[thief] = {
		victim = victim,
		plot = plot,
		slot = slot,
		uid = creature.uid,
		endsAt = os.clock() + S.grabHold,
		startPos = rootOf(thief).Position,
	}
	return true, workspace:GetServerTimeNow() + S.grabHold
end

local function grab(thief, hold)
	local creature, victim, victimProfile = validate(thief, hold.plot, hold.slot)
	if not creature or creature.uid ~= hold.uid or victim ~= hold.victim then
		Net.Notify(thief, "stealFail", { reason = "invalid", text = "Too late!" })
		return
	end
	local profile = DataService.Get(thief)
	profile.carrying = { creature = creature, victim = victim, slot = hold.slot, uid = creature.uid }
	profile.carryMult = S.carrySpeedMult
	victimProfile.carriedOut[creature.uid] = thief
	setCarryAttribute(thief, creature)
	PlotService.ApplySpeed(thief)
	local data = {
		thief = thief.UserId,
		thiefName = thief.DisplayName,
		victim = victim.UserId,
		victimName = victim.DisplayName,
		species = creature.id,
		mutation = creature.mut,
		slot = hold.slot,
	}
	local name = Config.Creatures[creature.id].name
	data.role = "victim"
	data.text = ("%s is stealing your %s! Touch them to get it back."):format(thief.DisplayName, name)
	Net.Notify(victim, "stealStart", table.clone(data))
	data.role = "thief"
	data.text = ("You grabbed %s's %s! Run home before the tide ends."):format(victim.DisplayName, name)
	Net.Notify(thief, "stealStart", data)
	PlotService.RenderDisplay(victim)
	DataService.MarkDirty(victim)
	DataService.MarkDirty(thief)
end

-- La creature retourne chez son proprietaire (elle n'a jamais quitte ses donnees)
local function giveBack(thief, reason, push)
	local profile = DataService.Get(thief)
	local carrying = profile and profile.carrying
	if not carrying then
		return
	end
	profile.carrying = nil
	profile.carryMult = 1
	profile.movedByServerAt = os.clock() -- le recul joue par le client ne compte pas comme un exces de vitesse
	if thief.Parent then
		setCarryAttribute(thief, nil)
		PlotService.ApplySpeed(thief)
		Net.Notify(thief, "stealFail", {
			reason = reason,
			push = push,
			text = reason == "touched" and "Caught! The creature went home." or "The creature swam back home.",
		})
		DataService.MarkDirty(thief)
	end
	local victim = carrying.victim
	local victimProfile = DataService.Get(victim)
	if victimProfile and victimProfile.carriedOut[carrying.uid] == thief then
		victimProfile.carriedOut[carrying.uid] = nil
		if victim.Parent and not victimProfile.leaving then
			Net.Notify(victim, "recovered", {
				species = carrying.creature.id,
				mutation = carrying.creature.mut,
				slot = carrying.slot,
				reason = reason,
				text = ("Your %s is back!"):format(Config.Creatures[carrying.creature.id].name),
			})
			PlotService.RenderDisplay(victim)
			DataService.MarkDirty(victim)
		end
	end
end

-- Le voleur est rentre : la creature passe chez lui, avec son stade et sa mutation
local function succeed(thief, profile)
	local carrying = profile.carrying
	local victim = carrying.victim
	local victimProfile = DataService.Get(victim)
	if not victimProfile or victimProfile.carriedOut[carrying.uid] ~= thief then
		giveBack(thief, "invalid")
		return
	end
	local vd = victimProfile.data
	local creature, slot = Stats.FindCreature(vd, carrying.uid)
	if not creature then
		giveBack(thief, "invalid")
		return
	end
	local now = os.time()
	-- cote vole
	victimProfile.carriedOut[carrying.uid] = nil
	vd.pools[slot] = false
	table.insert(vd.stolenAt, now)
	local wave = Net.GetWave()
	local cycleEnds = wave and (wave.startTime + WaveService.CycleTime - Config.Wave.calmTime - Config.Wave.warningTime) or now
	vd.protectedUntil = math.ceil(math.max(now, cycleEnds) + S.protectAfterStolenWaves * WaveService.CycleTime)
	LagoonService.GiveRevenge(victim, thief)
	Net.Notify(victim, "stolen", {
		thief = thief.UserId,
		thiefName = thief.DisplayName,
		species = creature.id,
		mutation = creature.mut,
		protectedUntil = vd.protectedUntil,
		text = ("%s stole your %s. Your lagoon is protected for 2 waves."):format(thief.DisplayName, Config.Creatures[creature.id].name),
	})
	PlotService.RenderDisplay(victim)
	DataService.MarkDirty(victim)

	-- cote voleur : nouvel uid chez lui, meme espece, mutation, naissance et statut royal
	local d = profile.data
	profile.carrying = nil
	profile.carryMult = 1
	setCarryAttribute(thief, nil)
	PlotService.ApplySpeed(thief)
	d.creatureSeq += 1
	local mine = { uid = tostring(d.creatureSeq), id = creature.id, mut = creature.mut, born = creature.born, royal = creature.royal }
	local speed = Stats.GrowthSpeed(d)
	local newPools, placed, released = Stats.Deposit(d.pools, Stats.Slots(d), { mine }, now, speed, DataService.LockedUids(profile))
	d.pools = newPools
	for _, entry in ipairs(released) do
		local coins = Stats.ReleaseValue(entry.creature.id, entry.creature.mut)
		d.stats.released += 1
		DataService.AddCoins(thief, coins)
		Net.Notify(thief, "released", {
			species = entry.creature.id,
			mutation = entry.creature.mut,
			coins = coins,
			slot = entry.slot,
			text = ("Released %s +%s"):format(Config.Creatures[entry.creature.id].name, Config.Format(coins)),
		})
	end
	Net.Notify(thief, "stealWin", {
		victim = victim.UserId,
		victimName = victim.DisplayName,
		species = mine.id,
		mutation = mine.mut,
		slot = placed[1] and placed[1].slot or nil,
		text = ("You stole %s's %s!"):format(victim.DisplayName, Config.Creatures[mine.id].name),
	})
	PlotService.RenderDisplay(thief)
	DataService.MarkDirty(thief)
	local value = Stats.CreatureIncome(mine, now, speed)
	for _, hook in ipairs(stolenHooks) do
		task.spawn(function()
			local ok, err = pcall(hook, thief, mine, value)
			if not ok then
				warn("[TideRush] crochet de vol : " .. tostring(err))
			end
		end)
	end
end

local function tickHolds()
	local now = os.clock()
	for thief, hold in pairs(holds) do
		local root = rootOf(thief)
		if not root or flat(root.Position, hold.startPos) > S.moveTolerance then
			holds[thief] = nil
			Net.Notify(thief, "stealFail", { reason = "moved", text = "Stay still to grab it!" })
		elseif now >= hold.endsAt then
			holds[thief] = nil
			grab(thief, hold)
		end
	end
end

local function tickCarriers()
	local wave = Net.GetWave()
	for thief, profile in DataService.All() do
		local carrying = profile.carrying
		if carrying and profile.loaded and not profile.leaving then
			local root = rootOf(thief)
			local victimRoot = rootOf(carrying.victim)
			if not root then
				giveBack(thief, "died")
			elseif PlotService.IsInOwnPlot(thief, root.Position) then
				succeed(thief, profile)
			elseif victimRoot and flat(root.Position, victimRoot.Position) <= S.touchRange then
				local away = Vector3.new(root.Position.X - victimRoot.Position.X, 0, root.Position.Z - victimRoot.Position.Z)
				local push = away.Magnitude > 0.01 and away.Unit * S.pushStrength or Vector3.zero
				giveBack(thief, "touched", push)
			elseif not wave or wave.phase == "calm" then
				-- le reflux est fini : le voleur n'est pas rentre a temps
				giveBack(thief, "time")
			end
		end
	end
end

local function tickLoop()
	while true do
		task.wait(TICK)
		tickHolds()
		tickCarriers()
	end
end

-- callback(thief, creature, value) quand un vol reussit (Maree Royale)
function StealService.OnStolen(callback)
	table.insert(stolenHooks, callback)
end

-- Debug : le voleur prend tout de suite une creature du vole, sans les protections
function StealService.ForceGrab(thief, victim)
	local profile, victimProfile = DataService.Get(thief), DataService.Get(victim)
	if not profile or not victimProfile or profile.carrying or thief == victim then
		return false
	end
	for slot, creature in ipairs(victimProfile.data.pools) do
		if creature and victimProfile.mountUid ~= creature.uid and not victimProfile.carriedOut[creature.uid] then
			profile.carrying = { creature = creature, victim = victim, slot = slot, uid = creature.uid }
			profile.carryMult = S.carrySpeedMult
			victimProfile.carriedOut[creature.uid] = thief
			setCarryAttribute(thief, creature)
			PlotService.ApplySpeed(thief)
			PlotService.RenderDisplay(victim)
			DataService.MarkDirty(victim)
			DataService.MarkDirty(thief)
			return true
		end
	end
	return false
end

-- Depart d'un joueur : tout vol en cours qui le concerne est annule (a appeler avant DataService.Release)
function StealService.Forget(player)
	holds[player] = nil
	for thief, hold in pairs(holds) do
		if hold.victim == player then
			holds[thief] = nil
		end
	end
	giveBack(player, "thiefLeft")
	for thief, profile in DataService.All() do
		if profile.carrying and profile.carrying.victim == player then
			giveBack(thief, "ownerLeft")
		end
	end
end

function StealService.Start()
	Net.Handle("StartSteal", startSteal)
	-- pris par la vague sur la plage : la creature retourne chez son proprietaire
	WaveService.OnCaught(function(player)
		holds[player] = nil
		giveBack(player, "wave")
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(tickLoop)
			warn("[TideRush] boucle de vol relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
end

return StealService
