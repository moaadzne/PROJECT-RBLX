-- CreatureService : creatures de l'ile, par anneaux autour de la crique (apparition, mutation tiree a l'apparition selon la maree),
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
local RING_MARGIN = 4
local ROYAL_BAND = 30 -- la creature royale apparait dans les 30 derniers studs de l'anneau exterieur
local RAY_HEIGHT = 120
local RAY_LENGTH = 200
local GROUND_BOB = 0.4
local GROUND_GAP = 0.6
local LEGENDARY_ORDER = 5

local rng = Random.new()
local folder = nil
local active = {} -- [model] = { species, mutation, zone (anneau), pos, owner (UserId) ?, royal ?, reef ? }
local captureHooks = {}
local zoneCounts = {} -- [anneau] = creatures partagees seulement
local towerCenters = {}
local lastBagFull = {}
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = false
-- recif de la maree extreme : il est sous l'eau cote serveur (le retrait de la mer est joue par le client)
local reefRayParams = RaycastParams.new()
reefRayParams.FilterType = Enum.RaycastFilterType.Exclude
reefRayParams.IgnoreWater = true

local spawnMaterials = {}
for _, name in ipairs(Config.Island.spawnMaterials) do
	spawnMaterials[Enum.Material[name]] = true
end

local function nearTower(x, z)
	for _, tower in ipairs(towerCenters) do
		local dx, dz = x - tower.center.X, z - tower.center.Z
		if dx * dx + dz * dz < tower.radius * tower.radius then
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

-- Sol de plage sous (x, z) : position du sol, ou nil (eau, roche, herbe, decor, trop haut ou trop bas)
function CreatureService.GroundAt(x, z)
	local hit = workspace:Raycast(Vector3.new(x, RAY_HEIGHT, z), Vector3.new(0, -RAY_LENGTH, 0), rayParams)
	if hit and hit.Instance == workspace.Terrain and spawnMaterials[hit.Material]
		and hit.Position.Y >= Config.Island.spawnYMin and hit.Position.Y <= Config.Island.spawnYMax then
		return hit.Position
	end
	return nil
end

-- Point au hasard dans un anneau [rMin, rMax] autour du centre de l'ile (surface uniforme)
local function pointInRing(rMin, rMax)
	local angle = rng:NextNumber(0, 2 * math.pi)
	local r = math.sqrt(rng:NextNumber(rMin * rMin, rMax * rMax))
	local c = Config.Island.center
	return c.X + r * math.cos(angle), c.Z + r * math.sin(angle)
end

-- Un point de sable libre dans l'anneau (pas d'eau, pas de decor, pas de tour)
function CreatureService.FindSpot(ringIndex)
	local ring = Config.Rings[ringIndex]
	for _ = 1, SPAWN_TRIES do
		local x, z = pointInRing(ring.rMin + RING_MARGIN, ring.rMax - RING_MARGIN)
		if not nearTower(x, z) and not nearCreature(x, z) then
			local ground = CreatureService.GroundAt(x, z)
			if ground then
				return ground
			end
		end
	end
	return nil
end

local function place(species, mutation, ground, zoneIndex, owner, royal, reef)
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
	active[model] = { species = species, mutation = mutation, zone = zoneIndex, pos = basePos, owner = owner, royal = royal, reef = reef }
	if reef then
		model:SetAttribute("Reef", true)
	end
	return model
end

local function spawnOne(zoneIndex, tide)
	local zone = Config.Rings[zoneIndex]
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
	if not info.owner and not info.royal and not info.reef then
		zoneCounts[info.zone] -= 1
	end
	model:Destroy()
end

local function currentTide()
	local wave = WaveService.Get()
	return wave and wave.tide or "Normal"
end

-- Remplit chaque anneau jusqu'a son maximum, avec la maree en cours
function CreatureService.FillAll(tide)
	tide = tide or currentTide()
	for i, ring in ipairs(Config.Rings) do
		local tries = ring.maxItems * 2
		while zoneCounts[i] < ring.maxItems and tries > 0 do
			spawnOne(i, tide)
			tries -= 1
		end
	end
end

-- Creatures personnelles (intro). list = {{species, mutation, ground (Vector3)}}
function CreatureService.SpawnPersonal(player, list)
	local count = 0
	for _, entry in ipairs(list) do
		if Config.Creatures[entry.species] and place(entry.species, entry.mutation or "", entry.ground, Config.RingAt(entry.ground), player.UserId) then
			count += 1
		end
	end
	return count
end

-- Emporte ce que la vague `wave` a recouvert (axe <= front, hors crique, sous sa hauteur).
-- owner = nil : vague globale ; sinon vague propre a ce joueur (intro).
function CreatureService.WashAway(wave, front, owner)
	for model, info in pairs(active) do
		if Config.WaveAxis(wave, info.pos) <= front and info.pos.Y < Config.Wave.height and not Config.InCove(info.pos) then
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
	if Config.InCove(pos) or os.clock() < profile.sweptUntil then
		return
	end

	local bagMax = Stats.BagMax(profile.data)
	local radius = Config.PickupRadius * (profile.pickupMult or 1) -- BigNet : x1,5
	local radius2 = radius * radius
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
	for i in ipairs(Config.Rings) do
		timers[i] = 0
	end
	while true do
		local dt = task.wait(SPAWN_TICK)
		local wave = WaveService.Get()
		if wave and wave.phase == "calm" then
			for i, zone in ipairs(Config.Rings) do
				timers[i] += dt
				if timers[i] >= zone.spawnEvery then
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

-- Maree extreme : creatures rares sur le recif decouvert (n'importe quel sol sous l'eau, dans le disque du recif)
function CreatureService.SpawnReef(center, radius, tide)
	local e = Config.ExtremeTide
	local tideName = tide or e.mutationTide
	-- promesse de la maree extreme (decision du 09/10) : au moins une espece mutee sur le recif.
	-- Meme parade que l'intro (IntroService, startGolden) : on tire d'abord toutes les mutations,
	-- puis on impose la premiere chance de la maree si aucune n'a mute. Elles sont consommees dans
	-- l'ordre par les apparitions reussies, donc la garantie tient meme si la mer refuse du sol.
	local mutations = {}
	for _ = 1, e.count do
		table.insert(mutations, Stats.RollMutation(tideName, rng))
	end
	local anyMutated = false
	for _, mutation in ipairs(mutations) do
		anyMutated = anyMutated or mutation ~= ""
	end
	-- meme repli que Stats.RollMutation : une maree inconnue ne doit pas faire planter le recif
	local odds = (Config.Tides[tideName] or Config.Tides.Normal).odds
	if not anyMutated and mutations[1] and odds[1] then
		mutations[1] = odds[1][1]
	end

	local count = 0
	for _ = 1, e.count * SPAWN_TRIES do
		if count >= e.count then
			break
		end
		local angle = rng:NextNumber(0, 2 * math.pi)
		local r = math.sqrt(rng:NextNumber(0, radius * radius))
		local x, z = center.X + r * math.cos(angle), center.Z + r * math.sin(angle)
		if not nearCreature(x, z) then
			local hit = workspace:Raycast(Vector3.new(x, RAY_HEIGHT, z), Vector3.new(0, -RAY_LENGTH, 0), reefRayParams)
			if hit then
				local species = Stats.PickWeighted(e.creatures, rng)
				local mutation = mutations[count + 1] or ""
				if place(species, mutation, hit.Position, Config.RingAt(hit.Position), nil, nil, true) then
					count += 1
				end
			end
		end
	end
	return count
end

-- La mer revient : les creatures du recif encore la repartent
function CreatureService.ClearReef()
	for model, info in pairs(active) do
		if info.reef then
			remove(model, info)
		end
	end
end

-- callback(player, species, mutation, value) a chaque capture (Maree Royale)
function CreatureService.OnCapture(callback)
	table.insert(captureHooks, callback)
end

-- Creature royale : unique sur l'ile, au bord de l'anneau exterieur, toujours mutee
function CreatureService.SpawnRoyal(mutation)
	for _, info in pairs(active) do
		if info.royal then
			return false
		end
	end
	local best, bestIncome = nil, -1
	for _, ring in ipairs(Config.Rings) do
		for _, entry in ipairs(ring.creatures) do
			local income = Config.Creatures[entry[1]].income
			if income > bestIncome then
				best, bestIncome = entry[1], income
			end
		end
	end
	local zoneIndex = #Config.Rings
	local zone = Config.Rings[zoneIndex]
	if not zone or not best then
		return false
	end
	for _ = 1, SPAWN_TRIES do
		local x, z = pointInRing(math.max(zone.rMin, zone.rMax - ROYAL_BAND), zone.rMax - RING_MARGIN)
		local ground = not nearTower(x, z) and CreatureService.GroundAt(x, z)
		if ground and place(best, mutation, ground, zoneIndex, nil, true) then
			return true
		end
	end
	return false
end

function CreatureService.Counts()
	local personal, royal, reef = 0, 0, 0
	for _, info in pairs(active) do
		if info.owner then
			personal += 1
		elseif info.royal then
			royal += 1
		elseif info.reef then
			reef += 1
		end
	end
	local counts = table.clone(zoneCounts)
	counts.personal = personal
	counts.royal = royal
	counts.reef = reef
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
	for i in ipairs(Config.Rings) do
		zoneCounts[i] = 0
	end
	local towers = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Towers")
	if towers then
		for _, tower in ipairs(towers:GetChildren()) do
			local center = tower:GetAttribute("Center")
			local platform = tower:GetAttribute("PlatformRadius")
			if typeof(center) == "Vector3" then
				local radius = Config.Island.towerRadius
				if type(platform) == "number" then
					radius = math.max(radius, platform + 4)
				end
				table.insert(towerCenters, { center = center, radius = radius })
			end
		end
	end
	-- maree basse : la plage se couvre ; la vague emporte tout au passage de son front
	WaveService.OnCalm(function(_, tide)
		CreatureService.FillAll(tide)
		local extreme = WaveService.Get().extreme
		if extreme then
			-- maree extreme : la mer se retire, le recif se couvre de creatures rares, puis la mer les reprend
			local clock = workspace:GetServerTimeNow()
			task.delay(math.max(0, extreme.revealAt - clock), function()
				local count = CreatureService.SpawnReef(extreme.center, extreme.radius)
				Net.NotifyAll("extreme", {
					endsAt = extreme.endsAt,
					count = count,
					text = "The sea pulls back... something surfaces on the reef!",
				})
			end)
			task.delay(math.max(0, extreme.endsAt - clock), CreatureService.ClearReef)
		end
	end)
	WaveService.OnFront(function(_, front)
		CreatureService.WashAway(WaveService.Get(), front, nil)
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
