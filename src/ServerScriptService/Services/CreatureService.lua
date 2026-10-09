-- CreatureService : creatures de la plage (apparition, mutation tiree a l'apparition selon la maree),
-- la vague qui les emporte, la capture (10 fois/s), le Reef Codex et le depot dans les bassins.
-- Les creatures "personnelles" (attribut Owner) servent a l'intro : seul leur proprietaire peut les attraper.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local WaveService = require(Services.WaveService)
local CreatureFactory = require(Services.CreatureFactory)

local CreatureService = {}

local PICKUP_TICK = 0.1
local SPAWN_TICK = 0.5
local VERTICAL_REACH = 8 -- un joueur sur une tour n'attrape pas ce qui est en bas
local BAG_FULL_COOLDOWN = 3
local SPAWN_TRIES = 12
local EDGE_MARGIN = 6
local ZONE_MARGIN = 4
local TOWER_HALF_WIDTH = 12
local TOWER_BACK = 12
local TOWER_RAMP = 52 -- la rampe descend vers +Z jusqu'a Center.Z + 48
local RAY_HEIGHT = 80
local RAY_LENGTH = 160
local GROUND_TOLERANCE = 4
local GROUND_BOB = 0.4
local GROUND_GAP = 0.6
local LEGENDARY_ORDER = 5

local rng = Random.new()
local folder = nil
local active = {} -- [model] = { species, mutation, zone, pos, owner (UserId) ?, royal ? }
local captureHooks = {}
local zoneCounts = {} -- creatures partagees seulement
local towerCenters = {}
local lastBagFull = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false

local function nearTower(x, z)
	for _, center in ipairs(towerCenters) do
		if math.abs(x - center.X) < TOWER_HALF_WIDTH and z > center.Z - TOWER_BACK and z < center.Z + TOWER_RAMP then
			return true
		end
	end
	return false
end

local function nearCreature(x, z)
	local spacing2 = Config.CreatureSpacing * Config.CreatureSpacing
	for _, info in pairs(active) do
		local dx, dz = info.pos.X - x, info.pos.Z - z
		if dx * dx + dz * dz < spacing2 then
			return true
		end
	end
	return false
end

-- Sol de sable sous (x, z) : position du sol, ou nil (eau, decor, trop haut ou trop bas)
function CreatureService.GroundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, RAY_HEIGHT, z), Vector3.new(0, -RAY_LENGTH, 0), rayParams)
	if hit and hit.Instance == workspace.Terrain and hit.Material ~= Enum.Material.Water
		and math.abs(hit.Position.Y - Config.Beach.groundY) <= GROUND_TOLERANCE then
		return hit.Position
	end
	return nil
end

-- Un point de sable libre dans la zone (pas d'eau, pas de decor, pas de tour)
function CreatureService.FindSpot(zoneIndex)
	local zone = Config.Zones[zoneIndex]
	for _ = 1, SPAWN_TRIES do
		local x = rng:NextNumber(Config.Beach.xMin + EDGE_MARGIN, Config.Beach.xMax - EDGE_MARGIN)
		local z = rng:NextNumber(zone.zMin + ZONE_MARGIN, zone.zMax - ZONE_MARGIN)
		if not nearTower(x, z) and not nearCreature(x, z) then
			local ground = CreatureService.GroundAt(x, z)
			if ground then
				return ground
			end
		end
	end
	return nil
end

local function place(species, mutation, ground, zoneIndex, owner, royal)
	local basePos = ground + Vector3.new(0, CreatureFactory.RestOffset(species) + GROUND_BOB + GROUND_GAP, 0)
	local model = CreatureFactory.Create(species, basePos, {
		mutation = mutation,
		stage = 1,
		zone = zoneIndex,
		bob = GROUND_BOB,
		beacon = true,
		owner = owner,
		royal = royal,
	})
	if not model then
		return nil
	end
	model.Parent = folder
	active[model] = { species = species, mutation = mutation, zone = zoneIndex, pos = basePos, owner = owner, royal = royal }
	return model
end

local function spawnOne(zoneIndex, tide)
	local zone = Config.Zones[zoneIndex]
	local spot = CreatureService.FindSpot(zoneIndex)
	if not spot then
		return false
	end
	local species = Stats.PickWeighted(zone.creatures, rng)
	if not place(species, Stats.RollMutation(tide, rng), spot, zoneIndex, nil) then
		return false
	end
	zoneCounts[zoneIndex] += 1
	return true
end

local function remove(model, info)
	active[model] = nil
	if not info.owner and not info.royal then
		zoneCounts[info.zone] -= 1
	end
	model:Destroy()
end

local function currentTide()
	local wave = WaveService.Get()
	return wave and wave.tide or "Normal"
end

-- Remplit chaque zone ouverte jusqu'a son maximum, avec la maree en cours
function CreatureService.FillAll(tide)
	tide = tide or currentTide()
	for i, zone in ipairs(Config.Zones) do
		if zone.open then
			local tries = zone.maxItems * 2
			while zoneCounts[i] < zone.maxItems and tries > 0 do
				spawnOne(i, tide)
				tries -= 1
			end
		end
	end
end

-- Creatures personnelles (intro). list = {{species, mutation, ground (Vector3)}}
function CreatureService.SpawnPersonal(player, list)
	local count = 0
	for _, entry in ipairs(list) do
		if Config.Creatures[entry.species] and place(entry.species, entry.mutation or "", entry.ground, Config.ZoneAt(entry.ground.Z), player.UserId) then
			count += 1
		end
	end
	return count
end

-- Emporte ce que la vague a recouvert (Z <= front). owner = nil : vague globale ; sinon vague propre a ce joueur.
function CreatureService.WashAway(front, owner)
	for model, info in pairs(active) do
		if info.pos.Z <= front then
			if owner then
				if info.owner == owner then
					remove(model, info)
				end
			else
				local ownerPlayer = info.owner and Players:GetPlayerByUserId(info.owner)
				local ownerProfile = ownerPlayer and DataService.Get(ownerPlayer)
				-- les creatures d'un joueur en pleine intro attendent sa propre vague
				if not (ownerProfile and ownerProfile.introActive) then
					remove(model, info)
				end
			end
		end
	end
end

-- Codex : nouvelle case -> pieces ; renvoie true si la case est nouvelle
local function recordCodex(player, profile, species, mutation)
	local d = profile.data
	local variant = Stats.Variant(mutation)
	local variants = d.codex[species]
	if variants and variants[variant] then
		return false
	end
	variants = variants or {}
	variants[variant] = true
	d.codex[species] = variants
	local coins = Config.Creatures[species].income * Config.Codex.newEntryIncomeMult
	DataService.AddCoins(player, coins)
	local rowComplete = Stats.CodexRowComplete(d, species)
	Net.Notify(player, "codex", {
		species = species,
		variant = variant,
		coins = coins,
		count = Stats.CodexCount(d),
		total = Stats.CodexTotal(),
		rowComplete = rowComplete,
		text = rowComplete and ("%s complete! +%d%% income"):format(Config.Creatures[species].name, math.floor(Config.Codex.speciesBonus * 100 + 0.5))
			or ("New in your Reef Codex: %s%s"):format(mutation ~= "" and (mutation .. " ") or "", Config.Creatures[species].name),
	})
	return true
end

local function collect(player, profile, model, info)
	remove(model, info)

	local d = profile.data
	table.insert(profile.bag, { species = info.species, mutation = info.mutation, royal = info.royal })
	d.stats.pickups += 1
	if info.mutation ~= "" then
		d.stats.mutationsFound += 1
	end
	local isNew = recordCodex(player, profile, info.species, info.mutation)

	local def = Config.Creatures[info.species]
	local bagMax = Stats.BagMax(d)
	Net.Notify(player, "capture", {
		species = info.species,
		mutation = info.mutation,
		rarity = def.rarity,
		position = info.pos,
		bagCount = #profile.bag,
		bagMax = bagMax,
		isNew = isNew,
		text = ("%s%s (%d/%d)"):format(info.mutation ~= "" and (info.mutation .. " ") or "", def.name, #profile.bag, bagMax),
	})
	for _, hook in ipairs(captureHooks) do
		task.spawn(hook, player, info.species, info.mutation, Stats.BabyIncome(info.species, info.mutation))
	end
	local rarity = Config.Rarities[def.rarity]
	if info.royal then
		Net.NotifyAll("info", { text = ("%s caught the Royal %s!"):format(player.DisplayName, def.name) }, player)
	elseif rarity and rarity.order >= LEGENDARY_ORDER then
		Net.NotifyAll("info", { text = ("%s caught a %s!"):format(player.DisplayName, def.name) }, player)
	end
	DataService.MarkDirty(player)
end

local function newCreature(d, entry, now)
	d.creatureSeq += 1
	return { uid = tostring(d.creatureSeq), id = entry.species, mut = entry.mutation, born = now, royal = entry.royal }
end

local function release(player, d, creature, slot)
	local coins = Stats.ReleaseValue(creature.id, creature.mut)
	d.stats.released += 1
	DataService.AddCoins(player, coins)
	Net.Notify(player, "released", {
		species = creature.id,
		mutation = creature.mut,
		coins = coins,
		slot = slot,
		text = ("Released %s +%s"):format(Config.Creatures[creature.id].name, Config.Format(coins)),
	})
end

local function deposit(player, profile)
	local d = profile.data
	local now = os.time()
	local newcomers = {}
	for _, entry in ipairs(profile.bag) do
		table.insert(newcomers, newCreature(d, entry, now))
	end
	profile.bag = {}
	local newPools, placed, released = Stats.Deposit(d.pools, Stats.Slots(d), newcomers, now,
		Stats.GrowthSpeed(d), DataService.LockedUids(profile))
	d.pools = newPools
	d.stats.deposited += #placed

	for _, entry in ipairs(released) do
		release(player, d, entry.creature, entry.slot)
	end
	if #placed > 0 then
		local list = {}
		for _, entry in ipairs(placed) do
			table.insert(list, { slot = entry.slot, species = entry.creature.id, mutation = entry.creature.mut })
		end
		Net.Notify(player, "deposit", {
			placed = list,
			text = ("%d creature%s in your reef"):format(#placed, #placed > 1 and "s" or ""),
		})
	end
	PlotService.RenderDisplay(player)
	DataService.MarkDirty(player)
end

local function tickPlayer(player, profile)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end
	local pos = root.Position
	if #profile.bag > 0 and PlotService.IsInOwnPlot(player, pos) then
		deposit(player, profile)
		return
	end
	if pos.Z >= Config.BaseLineZ or os.clock() < profile.sweptUntil then
		return
	end

	local bagMax = Stats.BagMax(profile.data)
	local radius2 = Config.PickupRadius * Config.PickupRadius
	for model, info in pairs(active) do
		local dx, dz = info.pos.X - pos.X, info.pos.Z - pos.Z
		if dx * dx + dz * dz <= radius2 and math.abs(info.pos.Y - pos.Y) <= VERTICAL_REACH
			and (info.owner == nil or info.owner == player.UserId) then
			if #profile.bag >= bagMax then
				local now = os.clock()
				if now - (lastBagFull[player] or 0) >= BAG_FULL_COOLDOWN then
					lastBagFull[player] = now
					Net.Notify(player, "bagFull", { bagMax = bagMax, text = "Bag full! Bring them home." })
				end
				return
			end
			collect(player, profile, model, info)
		end
	end
end

local function pickupLoop()
	while true do
		task.wait(PICKUP_TICK)
		for player, profile in DataService.All() do
			if profile.loaded and not profile.leaving then
				local ok, err = pcall(tickPlayer, player, profile)
				if not ok then
					warn(("[TideRush] capture %s : %s"):format(player.Name, tostring(err)))
				end
			end
		end
	end
end

-- Pendant le calme seulement : la plage se recharge
local function spawnLoop()
	local timers = {}
	for i in ipairs(Config.Zones) do
		timers[i] = 0
	end
	while true do
		local dt = task.wait(SPAWN_TICK)
		local wave = WaveService.Get()
		if wave and wave.phase == "calm" then
			for i, zone in ipairs(Config.Zones) do
				timers[i] += dt
				if zone.open and timers[i] >= zone.spawnEvery then
					timers[i] = 0
					if zoneCounts[i] < zone.maxItems then
						local ok, err = pcall(spawnOne, i, wave.tide)
						if not ok then
							warn("[TideRush] apparition de creature : " .. tostring(err))
						end
					end
				end
			end
		end
	end
end

-- callback(player, species, mutation, value) a chaque capture (Maree Royale)
function CreatureService.OnCapture(callback)
	table.insert(captureHooks, callback)
end

-- Creature royale : unique sur la plage, au bout de la derniere zone ouverte, toujours mutee
function CreatureService.SpawnRoyal(mutation)
	for _, info in pairs(active) do
		if info.royal then
			return false
		end
	end
	local zoneIndex, best, bestIncome = nil, nil, -1
	for i, zone in ipairs(Config.Zones) do
		if zone.open then
			zoneIndex = i
			for _, entry in ipairs(zone.creatures) do
				local income = Config.Creatures[entry[1]].income
				if income > bestIncome then
					best, bestIncome = entry[1], income
				end
			end
		end
	end
	if not zoneIndex then
		return false
	end
	local zone = Config.Zones[zoneIndex]
	for _ = 1, SPAWN_TRIES do
		local x = rng:NextNumber(Config.Beach.xMin + EDGE_MARGIN, Config.Beach.xMax - EDGE_MARGIN)
		local z = rng:NextNumber(zone.zMin + ZONE_MARGIN, zone.zMin + ZONE_MARGIN * 4)
		local ground = not nearTower(x, z) and CreatureService.GroundAt(x, z)
		if ground and place(best, mutation, ground, zoneIndex, nil, true) then
			return true
		end
	end
	return false
end

function CreatureService.Counts()
	local personal, royal = 0, 0
	for _, info in pairs(active) do
		if info.owner then
			personal += 1
		elseif info.royal then
			royal += 1
		end
	end
	local counts = table.clone(zoneCounts)
	counts.personal = personal
	counts.royal = royal
	return counts
end

-- Debug : met des creatures dans le sac
function CreatureService.GiveToBag(player, species, count, mutation)
	local profile = DataService.Get(player)
	mutation = mutation or ""
	if not profile or not Config.Creatures[species] or (mutation ~= "" and not Config.Mutations[mutation]) then
		return false
	end
	for _ = 1, count or 1 do
		table.insert(profile.bag, { species = species, mutation = mutation })
	end
	DataService.MarkDirty(player)
	return true
end

function CreatureService.Forget(player)
	lastBagFull[player] = nil
	local userId = player.UserId
	for model, info in pairs(active) do
		if info.owner == userId then
			remove(model, info)
		end
	end
end

function CreatureService.Start()
	folder = workspace:FindFirstChild("Creatures")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Creatures"
		folder.Parent = workspace
	end
	-- l'ancien dossier des tresors n'a plus de sens
	local oldTreasures = workspace:FindFirstChild("Treasures")
	if oldTreasures then
		oldTreasures:Destroy()
	end
	rayParams.FilterDescendantsInstances = { folder }
	for i in ipairs(Config.Zones) do
		zoneCounts[i] = 0
	end
	local towers = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Towers")
	if towers then
		for _, tower in ipairs(towers:GetChildren()) do
			local center = tower:GetAttribute("Center")
			if typeof(center) == "Vector3" then
				table.insert(towerCenters, center)
			end
		end
	end
	-- maree basse : la plage se couvre ; la vague emporte tout au passage de son front
	WaveService.OnCalm(function(_, tide)
		CreatureService.FillAll(tide)
	end)
	WaveService.OnFront(function(_, front)
		CreatureService.WashAway(front, nil)
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(pickupLoop)
			warn("[TideRush] boucle de capture relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(spawnLoop)
			warn("[TideRush] boucle d'apparition relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
end

return CreatureService
