-- SelfTest : rejoue d'un coup les verifications essentielles (TR_Debug "selftest", Studio, pendant un playtest).
-- Calculs purs (Config, depot, donnees) + etat vivant (vague, tresors, bases) + attaques sur les remotes.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local TreasureService = require(Services.TreasureService)
local WaveService = require(Services.WaveService)

local SelfTest = {}

local SPIN_TAG = "TR_Spin"
local BEACON_MIN_ORDER = 4
local MIN_SPACING = 6
local RATE_BURST = 50
local GETSTATE_BURST = 20
local HOME_BURST = 5
local MAX_FAIL_LINES = 5

local function phaseKnown(phase)
	return phase == "calm" or phase == "warning" or phase == "wave" or phase == "recede"
end

local function checkConfig(check)
	local items = ReplicatedStorage.Assets.Items
	for id, def in pairs(Config.Items) do
		local model = items:FindFirstChild(id)
		check(model ~= nil and model.PrimaryPart ~= nil and Config.Rarities[def.rarity] ~= nil, "objet " .. id)
	end
	for i, zone in ipairs(Config.Zones) do
		for _, entry in ipairs(zone.items) do
			check(Config.Items[entry[1]] ~= nil, ("zone %d : %s"):format(i, tostring(entry[1])))
		end
	end
	for _, egg in ipairs(Config.Eggs) do
		for _, entry in ipairs(egg.odds) do
			check(Config.Pets[entry[1]] ~= nil, egg.id .. " : " .. tostring(entry[1]))
		end
	end
	check(Config.GetUpgradeValue("Speed", Config.Upgrades.Speed.maxLevel) == 40, "Speed max = 40")
	check(Config.GetUpgradeValue("Bag", Config.Upgrades.Bag.maxLevel) == 10, "Bag max = 10")
	check(Config.GetUpgradeValue("Slots", Config.Upgrades.Slots.maxLevel) == Config.MaxSlots, "Slots max = MaxSlots")
end

local function checkDeposit(check)
	local d, placed, sold = Stats.Deposit({ "", "", "" }, 3, { "Shell", "Pearl" })
	check(#placed == 2 and #sold == 0 and d[3] == "", "pose dans les socles vides")
	d, placed, sold = Stats.Deposit({ "Shell", "Starfish", "Pearl" }, 3, { "TideHeart" })
	check(#placed == 1 and placed[1].slot == 1 and d[1] == "TideHeart" and #sold == 1 and sold[1] == "Shell",
		"remplace le plus faible et le vend")
	d, placed, sold = Stats.Deposit({ "Pearl", "Pearl" }, 2, { "Pearl" })
	check(#placed == 0 and #sold == 1, "egalite : le tresor pose reste")
	d, placed, sold = Stats.Deposit({ "", "" }, 2, { "Shell", "Shell", "MoonPearl" })
	check(#placed == 2 and #sold == 1 and sold[1] == "Shell" and table.find(d, "MoonPearl") ~= nil, "garde les meilleurs")
	check(Stats.SellValue("Shell") == Config.Items.Shell.income * Config.SellMultiplier, "vente = revenu x SellMultiplier")
end

local function checkSanitize(check)
	local inputs = table.pack(nil, "x", 42, {})
	for i = 1, inputs.n do
		local d = DataService._Sanitize(inputs[i])
		check(d.coins == 0 and #d.display == Stats.Slots(d) and d.levels.Speed == 0, "donnees vides #" .. i)
	end
	local d = DataService._Sanitize({
		coins = -5,
		levels = { Speed = 999, Bag = "x" },
		display = { "Nope", 3, "Shell" },
		pets = { { uid = 1 }, { uid = "7", id = "CrabBuddy" }, { uid = "8", id = "Ghost" } },
		equipped = { "7", "7", "99" },
		stats = { pickups = 0 / 0 },
		collection = { Shell = 2, Ghost = 1 },
	})
	check(d.coins == 0, "pieces negatives -> 0")
	check(d.levels.Speed == Config.Upgrades.Speed.maxLevel and d.levels.Bag == 0, "niveaux bornes")
	check(#d.display == Stats.Slots(d) and d.display[1] == "" and d.display[3] == "Shell", "socles valides")
	check(#d.pets == 1 and #d.equipped == 1 and d.petSeq >= 8, "compagnons valides")
	check(d.stats.pickups == 0 and d.collection.Shell == 2, "NaN -> 0, collection gardee")
	check(d.legacy.display ~= nil and d.legacy.pets ~= nil and d.legacy.collection ~= nil and d.legacy.levels ~= nil,
		"inconnus gardes dans legacy")
end

local function checkRemotes(check)
	for _, remote in ipairs(ReplicatedStorage.Remotes:GetChildren()) do
		if remote:IsA("RemoteFunction") then
			check(Net.IsHandled(remote.Name), "handler " .. remote.Name)
		end
	end
end

local function checkWave(check)
	local wave = WaveService.Get()
	check(wave ~= nil, "etat publie")
	if not wave then
		return
	end
	local remote = ReplicatedStorage.Remotes.WaveState
	check(remote:GetAttribute("Phase") == wave.phase and remote:GetAttribute("StartTime") == wave.startTime
		and remote:GetAttribute("Cycle") == wave.cycle, "attributs = etat")
	check(phaseKnown(wave.phase) and wave.phaseEnd > wave.phaseStart, "phase " .. tostring(wave.phase))
	check(WaveService.FrontZ(wave.startTime) == Config.Wave.startZ, "front au depart = startZ")
	check(WaveService.FrontZ(wave.startTime + 1000) == Config.Wave.endZ, "front borne a endZ")
end

local function checkTreasures(check)
	local folder = workspace:FindFirstChild("Treasures")
	check(folder ~= nil, "workspace.Treasures")
	if not folder then
		return
	end
	local counts, total = TreasureService.Counts(), 0
	for i, zone in ipairs(Config.Zones) do
		total += counts[i]
		check(counts[i] > 0 and counts[i] <= zone.maxItems, ("zone %d : %d/%d"):format(i, counts[i], zone.maxItems))
	end
	local models = folder:GetChildren()
	check(#models == total, ("%d modeles pour %d comptes"):format(#models, total))
	for index, model in ipairs(models) do
		local def = Config.Items[model:GetAttribute("ItemId")]
		local pos = model:GetAttribute("BasePos")
		check(def ~= nil and CollectionService:HasTag(model, SPIN_TAG)
			and model.ModelStreamingMode == Enum.ModelStreamingMode.Atomic and typeof(pos) == "Vector3"
			and type(model:GetAttribute("BaseYaw")) == "number" and type(model:GetAttribute("SpinSpeed")) == "number"
			and type(model:GetAttribute("Bob")) == "number" and model:GetAttribute("Zone") == Config.ZoneAt(pos.Z)
			and model:GetAttribute("Rarity") == def.rarity, "attributs " .. model.Name)
		if def and Config.Rarities[def.rarity].order >= BEACON_MIN_ORDER then
			local root = model.PrimaryPart
			check(root ~= nil and root:FindFirstChild("BeamA") ~= nil and root:FindFirstChild("BeamB") ~= nil
				and root:FindFirstChild("Core") ~= nil and root:FindFirstChild("Halo") ~= nil, "faisceau " .. model.Name)
		end
		for other = index + 1, #models do
			local otherPos = models[other]:GetAttribute("BasePos")
			if typeof(pos) == "Vector3" and typeof(otherPos) == "Vector3" then
				local gap = Vector2.new(pos.X - otherPos.X, pos.Z - otherPos.Z).Magnitude
				check(gap >= MIN_SPACING, ("ecart %.1f studs"):format(gap))
			end
		end
	end
end

local function checkPlots(check)
	local used = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local profile = DataService.Get(player)
		local index = PlotService.GetIndex(player)
		check(profile ~= nil and profile.loaded, player.Name .. " charge")
		check(index ~= nil and not used[index], player.Name .. " a une base a lui")
		local model = index and PlotService.GetModel(index)
		if model and profile then
			used[index] = true
			local d = profile.data
			local slots = Stats.Slots(d)
			check(model:GetAttribute("Owner") == player.UserId, "Owner base " .. index)
			check(model:GetAttribute("OwnerName") == player.DisplayName, "OwnerName base " .. index)
			for slot = 1, Config.MaxSlots do
				local shown = model.Display:FindFirstChild("Slot" .. slot)
				local want = slot <= slots and d.display[slot] or ""
				check((shown and shown:GetAttribute("ItemId") or "") == want, ("socle %d affiche %s"):format(slot, want))
				local lock = model.Pedestals["Pedestal" .. slot]:FindFirstChild("LockGui")
				check(lock ~= nil and lock.Enabled == (slot > slots), ("cadenas socle %d"):format(slot))
			end
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			check(humanoid ~= nil and humanoid.WalkSpeed == Stats.WalkSpeed(d), "WalkSpeed " .. player.Name)
		end
	end
	for index = 1, Config.MaxPlayersPerServer do
		local model = PlotService.GetModel(index)
		check(model ~= nil, "base " .. index .. " existe")
		if model and not used[index] then
			check(model:GetAttribute("Owner") == nil and model:GetAttribute("OwnerName") == nil,
				"base libre " .. index)
		end
	end
end

local function checkAttacks(check)
	local player = Players:GetPlayers()[1]
	local profile = player and DataService.Get(player)
	if not profile or not profile.loaded then
		check(false, "aucun joueur charge pour attaquer les remotes")
		return
	end
	local coins = profile.data.coins
	local levels = table.clone(profile.data.levels)
	local cases = {
		{ "BuyUpgrade", table.pack(123), "BadRequest" },
		{ "BuyUpgrade", table.pack("Foo"), "BadRequest" },
		{ "BuyUpgrade", table.pack(nil), "BadRequest" },
		{ "BuyUpgrade", table.pack(string.rep("a", 100000)), "BadRequest" },
		{ "HatchEgg", table.pack(0 / 0), "BadRequest" },
		{ "HatchEgg", table.pack("Nope"), "BadRequest" },
		{ "EquipPet", table.pack(nil, nil), "BadRequest" },
		{ "EquipPet", table.pack("best", false), "BadRequest" },
		{ "EquipPet", table.pack("999999", true), "UnknownPet" },
	}
	for _, case in ipairs(cases) do
		local ok, code = Net.Invoke(case[1], player, table.unpack(case[2], 1, case[2].n))
		check(ok == false and code == case[3], ("%s -> %s %s"):format(case[1], tostring(ok), tostring(code)))
	end
	local sameLevels = true
	for kind, level in pairs(levels) do
		sameLevels = sameLevels and profile.data.levels[kind] == level
	end
	check(profile.data.coins == coins and sameLevels, "aucun gain apres les attaques")

	local limited = 0
	for _ = 1, RATE_BURST do
		local _, code = Net.Invoke("BuyUpgrade", player, "Foo")
		if code == "RateLimited" then
			limited += 1
		end
	end
	check(limited > 0, ("rafale de %d appels : %d limites"):format(RATE_BURST, limited))

	local shapeOk = true
	for _ = 1, GETSTATE_BURST do
		local state, wave = Net.Invoke("GetState", player)
		shapeOk = shapeOk and (state == nil or type(state) == "table") and type(wave) == "table"
	end
	check(shapeOk, "GetState garde la forme (state|nil, wave) meme limite")

	local successes = 0
	for _ = 1, HOME_BURST do
		if Net.Invoke("GoHome", player) == true then
			successes += 1
		end
	end
	check(successes <= 1, ("GoHome en rafale : %d succes"):format(successes))
end

local SECTIONS = {
	{ "config", checkConfig },
	{ "depot", checkDeposit },
	{ "donnees", checkSanitize },
	{ "remotes", checkRemotes },
	{ "vague", checkWave },
	{ "tresors", checkTreasures },
	{ "bases", checkPlots },
	{ "attaques", checkAttacks },
}

function SelfTest.Run()
	local lines, totalFails = {}, 0
	for _, section in ipairs(SECTIONS) do
		local name, run = section[1], section[2]
		local passed, fails = 0, {}
		local function check(ok, label)
			if ok then
				passed += 1
			else
				table.insert(fails, label)
			end
		end
		local ok, err = pcall(run, check)
		if not ok then
			table.insert(fails, "plantage : " .. tostring(err))
		end
		totalFails += #fails
		if #fails == 0 then
			table.insert(lines, ("PASS %s (%d)"):format(name, passed))
		else
			table.insert(lines, ("FAIL %s (%d ok, %d ko)"):format(name, passed, #fails))
			for i = 1, math.min(#fails, MAX_FAIL_LINES) do
				table.insert(lines, "   - " .. fails[i])
			end
			if #fails > MAX_FAIL_LINES then
				table.insert(lines, ("   ... %d autres"):format(#fails - MAX_FAIL_LINES))
			end
		end
	end
	table.insert(lines, 1, ("SELFTEST %s : %d echec(s)"):format(totalFails == 0 and "OK" or "KO", totalFails))
	return table.concat(lines, "\n")
end

return SelfTest
