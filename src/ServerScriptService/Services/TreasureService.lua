-- TreasureService : apparition des tresors sur la plage, ramassage (10 fois/s),
-- depot automatique quand le joueur entre dans sa base.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local ItemFactory = require(Services.ItemFactory)

local TreasureService = {}

local PICKUP_TICK = 0.1
local SPAWN_TICK = 0.5
local VERTICAL_REACH = 8 -- un joueur sur une tour ne ramasse pas ce qui est en bas
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
local active = {} -- [model] = { itemId, zone, pos }
local zoneCounts = {}
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

local function nearTreasure(x, z)
	for _, info in pairs(active) do
		local dx, dz = info.pos.X - x, info.pos.Z - z
		if dx * dx + dz * dz < Config.TreasureSpacing * Config.TreasureSpacing then
			return true
		end
	end
	return false
end

-- Un point de sable libre dans la zone (pas d'eau, pas de decor, pas de tour)
local function findSpot(zone)
	for _ = 1, SPAWN_TRIES do
		local x = rng:NextNumber(Config.Beach.xMin + EDGE_MARGIN, Config.Beach.xMax - EDGE_MARGIN)
		local z = rng:NextNumber(zone.zMin + ZONE_MARGIN, zone.zMax - ZONE_MARGIN)
		if not nearTower(x, z) and not nearTreasure(x, z) then
			local hit = workspace:Raycast(Vector3.new(x, RAY_HEIGHT, z), Vector3.new(0, -RAY_LENGTH, 0), rayParams)
			if hit and hit.Instance == workspace.Terrain and hit.Material ~= Enum.Material.Water
				and math.abs(hit.Position.Y - Config.Beach.groundY) <= GROUND_TOLERANCE then
				return hit.Position
			end
		end
	end
	return nil
end

local function spawnOne(zoneIndex)
	local zone = Config.Zones[zoneIndex]
	local spot = findSpot(zone)
	if not spot then
		return false
	end
	local itemId = Stats.PickWeighted(zone.items, rng)
	local basePos = spot + Vector3.new(0, ItemFactory.RestOffset(itemId) + GROUND_BOB + GROUND_GAP, 0)
	local model = ItemFactory.Create(itemId, basePos, { zone = zoneIndex, bob = GROUND_BOB, beacon = true })
	if not model then
		return false
	end
	model.Parent = folder
	active[model] = { itemId = itemId, zone = zoneIndex, pos = basePos }
	zoneCounts[zoneIndex] += 1
	return true
end

local function collect(player, profile, model, info)
	active[model] = nil
	zoneCounts[info.zone] -= 1
	model:Destroy()

	local d = profile.data
	table.insert(profile.bag, info.itemId)
	d.stats.pickups += 1
	local isNew = (d.collection[info.itemId] or 0) == 0
	d.collection[info.itemId] = (d.collection[info.itemId] or 0) + 1

	local def = Config.Items[info.itemId]
	local bagMax = Stats.BagMax(d)
	Net.Notify(player, "pickup", {
		itemId = info.itemId,
		rarity = def.rarity,
		position = info.pos,
		bagCount = #profile.bag,
		bagMax = bagMax,
		isNew = isNew,
		text = ("%s%s (%d/%d)"):format(isNew and "New! " or "", def.name, #profile.bag, bagMax),
	})
	local rarity = Config.Rarities[def.rarity]
	if rarity and rarity.order >= LEGENDARY_ORDER then
		Net.NotifyAll("info", { text = ("%s found a %s!"):format(player.DisplayName, def.name) }, player)
	end
	DataService.MarkDirty(player)
end

local function deposit(player, profile)
	local d = profile.data
	local bag = profile.bag
	profile.bag = {}
	local newDisplay, placed, sold = Stats.Deposit(d.display, Stats.Slots(d), bag)
	d.display = newDisplay
	d.stats.deposited += #placed

	local soldCoins = 0
	for _, itemId in ipairs(sold) do
		local value = Stats.SellValue(itemId)
		soldCoins += value
		Net.Notify(player, "sold", {
			itemId = itemId,
			coins = value,
			text = ("Sold %s +%s"):format(Config.Items[itemId].name, Config.Format(value)),
		})
	end
	d.stats.sold += #sold
	if soldCoins > 0 then
		DataService.AddCoins(player, soldCoins)
	end

	if #placed > 0 then
		local items, slots = {}, {}
		for _, entry in ipairs(placed) do
			table.insert(items, entry.id)
			table.insert(slots, entry.slot)
		end
		Net.Notify(player, "deposit", {
			items = items,
			slots = slots,
			text = ("%d treasure%s placed"):format(#placed, #placed > 1 and "s" or ""),
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
		if dx * dx + dz * dz <= radius2 and math.abs(info.pos.Y - pos.Y) <= VERTICAL_REACH then
			if #profile.bag >= bagMax then
				local now = os.clock()
				if now - (lastBagFull[player] or 0) >= BAG_FULL_COOLDOWN then
					lastBagFull[player] = now
					Net.Notify(player, "bagFull", { bagMax = bagMax, text = "Bag full! Bring it home." })
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
					warn(("[TideRush] ramassage %s : %s"):format(player.Name, tostring(err)))
				end
			end
		end
	end
end

local function spawnLoop()
	local timers = {}
	for i in ipairs(Config.Zones) do
		timers[i] = 0
	end
	while true do
		local dt = task.wait(SPAWN_TICK)
		for i, zone in ipairs(Config.Zones) do
			timers[i] += dt
			if timers[i] >= zone.spawnEvery then
				timers[i] = 0
				if zoneCounts[i] < zone.maxItems then
					local ok, err = pcall(spawnOne, i)
					if not ok then
						warn("[TideRush] apparition de tresor : " .. tostring(err))
					end
				end
			end
		end
	end
end

-- Remplit chaque zone jusqu'a son maximum
function TreasureService.FillAll()
	for i, zone in ipairs(Config.Zones) do
		local tries = zone.maxItems * 2
		while zoneCounts[i] < zone.maxItems and tries > 0 do
			spawnOne(i)
			tries -= 1
		end
	end
end

function TreasureService.Counts()
	return table.clone(zoneCounts)
end

-- Debug : met des tresors dans le sac
function TreasureService.GiveToBag(player, itemId, count)
	local profile = DataService.Get(player)
	if not profile or not Config.Items[itemId] then
		return false
	end
	for _ = 1, count or 1 do
		table.insert(profile.bag, itemId)
	end
	DataService.MarkDirty(player)
	return true
end

function TreasureService.Forget(player)
	lastBagFull[player] = nil
end

function TreasureService.Start()
	folder = workspace:FindFirstChild("Treasures")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Treasures"
		folder.Parent = workspace
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
	TreasureService.FillAll()
	task.spawn(function()
		while true do
			local ok, err = pcall(pickupLoop)
			warn("[TideRush] boucle de ramassage relancee : " .. tostring(ok and "fin" or err))
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

return TreasureService
