-- SelfTest : rejoue d'un coup les verifications essentielles (TR_Debug "selftest", Studio, pendant un playtest).
-- Calculs purs (Config, croissance, marees, depot, donnees) + etat vivant (vague, plage, lagons) + attaques sur les remotes.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local CreatureService = require(Services.CreatureService)
local WaveService = require(Services.WaveService)

local SelfTest = {}

local SPIN_TAG = "TR_Spin"
local MIN_SPACING = 6
local RATE_BURST = 50
local GETSTATE_BURST = 20
local HOME_BURST = 5
local MAX_FAIL_LINES = 5
local T0 = 1700000000 -- heure fixe pour les calculs purs

local function phaseKnown(phase)
	return phase == "calm" or phase == "warning" or phase == "wave" or phase == "recede"
end

local function creature(id, mut, born, uid)
	return { uid = uid or "1", id = id, mut = mut or "", born = born or T0 }
end

local function checkConfig(check)
	for id, def in pairs(Config.Creatures) do
		check(Config.Rarities[def.rarity] ~= nil and type(def.income) == "number" and def.income > 0, "espece " .. id)
		check(Config.GrowthMinutes[def.rarity] ~= nil and #Config.GrowthMinutes[def.rarity] == #Config.Stages - 1,
			"croissance " .. def.rarity)
	end
	for itemId, species in pairs(Config.LegacyItemToCreature) do
		check(Config.Creatures[species] ~= nil and Config.Creatures[itemId] == nil, "ancien id " .. itemId)
	end
	local opened = 0
	for i, zone in ipairs(Config.Zones) do
		opened += zone.open and 1 or 0
		for _, entry in ipairs(zone.creatures) do
			check(Config.Creatures[entry[1]] ~= nil, ("zone %d : %s"):format(i, tostring(entry[1])))
		end
	end
	check(opened >= 1, "au moins une zone ouverte")
	for tide, def in pairs(Config.Tides) do
		local total = 0
		for _, entry in ipairs(def.odds) do
			check(Config.Mutations[entry[1]] ~= nil and entry[2] > 0, ("maree %s : %s"):format(tide, tostring(entry[1])))
			total += entry[2]
		end
		check(total <= 100, ("maree %s : %s %% au total"):format(tide, tostring(total)))
	end
	for _, tide in ipairs(Config.TideSchedule.rotation) do
		check(Config.Tides[tide] ~= nil, "calendrier : " .. tide)
	end
	for _, variant in ipairs(Config.CodexVariants) do
		check(variant == "Normal" or Config.Mutations[variant] ~= nil, "variante " .. variant)
	end
	check(Config.Tides[Config.Intro.goldenTide] ~= nil, "maree de l'intro")
	for _, entry in ipairs(Config.Intro.creatures) do
		check(Config.Creatures[entry.species] ~= nil and (entry.mutation == "" or Config.Mutations[entry.mutation] ~= nil),
			"intro : " .. entry.species)
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

local function checkGrowth(check)
	local stage, nextAt = Config.StageAt("Common", T0, T0)
	check(stage == 1 and nextAt == T0 + 3 * 60, "Juvenile au depot")
	stage = Config.StageAt("Common", T0, T0 + 3 * 60)
	check(stage == 2, "Adult a 3 min")
	stage, nextAt = Config.StageAt("Common", T0, T0 + 10 ^ 9)
	check(stage == #Config.Stages and nextAt == 0, "Titan pour toujours")
	stage = Config.StageAt("Common", T0, T0 - 500)
	check(stage == 1, "horloge qui recule : Juvenile")
	local previous = 0
	for minute = 0, 1300, 7 do
		local s = Config.StageAt("Legendary", T0, T0 + minute * 60)
		check(s >= previous, "stade monotone")
		previous = s
	end
	local d = DataService._Sanitize(nil)
	d.pools[1] = creature("GhostCrab", "Golden", T0)
	check(Stats.CreatureIncome(d.pools[1], T0) == 3, "Golden Juvenile = 1 x 3")
	check(Stats.CreatureIncome(d.pools[1], T0 + 3600) == 24, "Golden Titan = 1 x 3 x 8")
	-- 3 min bebe (x1) puis 2 min Juvenile (x2), revenu de base 3/s
	check(math.abs(Stats.IncomeBetween(d, T0, T0 + 300) - (3 * 180 + 6 * 120)) < 1e-6, "revenu entre deux heures")
	check(Stats.IncomeBetween(d, T0, T0) == 0, "duree nulle")
	check(Stats.LagoonTier(0) == 1 and Stats.LagoonTier(10 ^ 12) == #Config.LagoonTiers, "paliers du lagon")
end

local function checkTides(check)
	check(Config.TideFor(1) == "Normal", "cycle 1 normal")
	local every = Config.TideSchedule.every
	check(Config.TideFor(every) == Config.TideSchedule.rotation[1], "premiere speciale")
	local next = Config.NextSpecial(1)
	check(next.cycle == every and next.tide == Config.TideSchedule.rotation[1], "prochaine speciale")
	check(Config.NextSpecial(every).cycle == 2 * every, "speciale suivante")
	local rng = Random.new(1)
	local golden = 0
	for _ = 1, 2000 do
		local mutation = Stats.RollMutation("Golden", rng)
		check(mutation == "" or Config.Mutations[mutation] ~= nil, "mutation connue")
		golden += mutation == "Golden" and 1 or 0
	end
	check(golden > 450 and golden < 750, ("Golden Tide : %d/2000 dorees (30 %% attendu)"):format(golden))
	check(Stats.RollMutation("Inconnue", rng) ~= nil, "maree inconnue -> Normal")
end

local function checkDeposit(check)
	local pools, placed, released = Stats.Deposit({ false, false, false }, 3,
		{ creature("GhostCrab", "", T0, "1"), creature("CushionStar", "", T0, "2") }, T0)
	check(#placed == 2 and #released == 0 and pools[3] == false, "bassins libres d'abord")
	pools, placed, released = Stats.Deposit(
		{ creature("GhostCrab", "", T0, "1"), creature("CushionStar", "", T0, "2") }, 2,
		{ creature("CushionStar", "Golden", T0, "3") }, T0)
	check(#placed == 1 and placed[1].slot == 1 and pools[1].uid == "3" and #released == 1
		and released[1].creature.uid == "1" and released[1].slot == 1, "remplace la plus faible et la relache")
	pools, placed, released = Stats.Deposit(
		{ creature("GhostCrab", "", T0 - 3600, "1") }, 1, { creature("CushionStar", "", T0, "2") }, T0)
	check(#placed == 0 and #released == 1 and released[1].creature.uid == "2" and pools[1].uid == "1",
		"un Titan n'est pas ecrase par un Juvenile")
	pools, placed, released = Stats.Deposit({ creature("CushionStar", "", T0, "1") }, 1,
		{ creature("CushionStar", "", T0, "2") }, T0)
	check(#placed == 0 and #released == 1 and pools[1].uid == "1", "egalite : la creature posee reste")
	check(Stats.ReleaseValue("CushionStar", "Golden") == 2 * 3 * Config.SellMultiplier, "relache = Juvenile x SellMultiplier")
end

local function checkSanitize(check)
	local inputs = table.pack(nil, "x", 42, {})
	for i = 1, inputs.n do
		local d = DataService._Sanitize(inputs[i])
		check(d.coins == 0 and #d.pools == Stats.Slots(d) and d.levels.Speed == 0 and d.introStep == 0,
			"donnees vides #" .. i)
	end
	local future = os.time() + 10 ^ 6
	local d = DataService._Sanitize({
		v = 2,
		coins = -5,
		levels = { Speed = 999, Bag = "x" },
		pools = {
			{ uid = "4", id = "PebbleCrab", mut = "", born = future },
			false,
			{ uid = "4", id = "SandStar", mut = "", born = 1 },
			{ uid = "9", id = "Ghost", mut = "", born = 1 },
			{ uid = "5", id = "SandStar", mut = "Plaid", born = 1 },
		},
		creatureSeq = 2,
		codex = { PebbleCrab = { Normal = true, Golden = "x" }, Ghost = { Normal = true } },
		introStep = 7,
		pets = { { uid = 1 }, { uid = "7", id = "CrabBuddy" }, { uid = "8", id = "Ghost" } },
		equipped = { "7", "7", "99" },
		stats = { pickups = 0 / 0 },
	})
	check(d.coins == 0, "pieces negatives -> 0")
	check(d.levels.Speed == Config.Upgrades.Speed.maxLevel and d.levels.Bag == 0, "niveaux bornes")
	check(#d.pools == Stats.Slots(d) and d.pools[1] and d.pools[1].born <= os.time() and d.pools[2] == false
		and d.pools[3] == false and d.pools[4] == false and d.pools[5] == false, "bassins valides, naissance jamais future")
	check(d.creatureSeq >= 4, "compteur d'uid >= plus grand uid")
	check(d.pools[1] and d.pools[1].id == "GhostCrab", "ancien id d'espece traduit (PebbleCrab -> GhostCrab)")
	check(d.codex.GhostCrab and d.codex.GhostCrab.Normal == true and d.codex.GhostCrab.Golden == nil
		and d.codex.Ghost == nil and d.codex.PebbleCrab == nil, "codex valide, ancien id traduit")
	check(d.introStep == 2, "introStep borne")
	check(#d.pets == 1 and #d.equipped == 1 and d.petSeq >= 8, "compagnons valides")
	check(d.stats.pickups == 0, "NaN -> 0")
	check(d.legacy.pools ~= nil and #d.legacy.pools == 3 and d.legacy.pets ~= nil and d.legacy.codex ~= nil
		and d.legacy.levels ~= nil, "inconnus gardes dans legacy")

	local v1 = {
		v = 1,
		coins = 5000,
		levels = { Speed = 3, Bag = 1, Slots = 2 },
		display = { "Shell", "", "TideHeart" },
		collection = { Shell = 4 },
		pets = { { uid = "1", id = "Turtle" } },
		equipped = { "1" },
		stats = { pickups = 12, sold = 3 },
		firstJoin = 123,
	}
	local migrated = DataService._Sanitize(v1)
	check(migrated.v == 2 and migrated.coins == 0 and migrated.levels.Slots == 0 and migrated.pools[1] == false,
		"v1 -> v2 repart de zero")
	check(migrated.legacy.v1 and migrated.legacy.v1.coins == 5000 and migrated.legacy.v1.display[3] == "TideHeart"
		and migrated.legacy.v1.collection.Shell == 4, "v1 range dans legacy.v1")
	check(#migrated.pets == 1 and migrated.stats.pickups == 12 and migrated.stats.released == 3
		and migrated.firstJoin == 123, "v1 : compagnons, compteurs et firstJoin gardes")
	local again = DataService._Sanitize(migrated)
	check(again.legacy.v1 and again.legacy.v1.coins == 5000 and again.coins == 0 and #again.pets == 1,
		"deuxieme passage identique")
end

local function checkRemotes(check)
	for _, remote in ipairs(ReplicatedStorage.Remotes:GetChildren()) do
		if remote:IsA("RemoteFunction") then
			check(Net.IsHandled(remote.Name), "handler " .. remote.Name)
		end
	end
	for _, name in ipairs({ "StateChanged", "WaveState", "Notify" }) do
		check(ReplicatedStorage.Remotes:FindFirstChild(name) ~= nil, "remote " .. name)
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
		and remote:GetAttribute("Cycle") == wave.cycle and remote:GetAttribute("Tide") == wave.tide, "attributs = etat")
	check(phaseKnown(wave.phase) and wave.phaseEnd > wave.phaseStart, "phase " .. tostring(wave.phase))
	check(Config.Tides[wave.tide] ~= nil and type(wave.nextSpecial) == "table"
		and wave.nextSpecial.cycle > wave.cycle, "maree " .. tostring(wave.tide))
	check(WaveService.FrontZ(wave.startTime) == Config.Wave.startZ, "front au depart = startZ")
	check(WaveService.FrontZ(wave.startTime + 1000) == Config.Wave.endZ, "front borne a endZ")
end

local function checkCreatures(check)
	local folder = workspace:FindFirstChild("Creatures")
	check(folder ~= nil, "workspace.Creatures")
	if not folder then
		return
	end
	local wave = WaveService.Get()
	local counts, total = CreatureService.Counts(), 0
	for i, zone in ipairs(Config.Zones) do
		total += counts[i]
		if zone.open and wave and wave.phase == "calm" then
			check(counts[i] > 0 and counts[i] <= zone.maxItems, ("zone %d : %d/%d"):format(i, counts[i], zone.maxItems))
		elseif not zone.open then
			check(counts[i] == 0, ("zone fermee %d vide"):format(i))
		end
	end
	local models = folder:GetChildren()
	local expected = total + counts.personal + counts.royal
	check(#models == expected, ("%d modeles pour %d comptes"):format(#models, expected))
	check(counts.royal <= 1, "une seule creature royale")
	for index, model in ipairs(models) do
		local species = model:GetAttribute("CreatureId")
		local def = Config.Creatures[species]
		local mutation = model:GetAttribute("Mutation")
		local pos = model:GetAttribute("BasePos")
		check(def ~= nil and CollectionService:HasTag(model, SPIN_TAG)
			and model.ModelStreamingMode == Enum.ModelStreamingMode.Atomic and typeof(pos) == "Vector3"
			and (mutation == "" or Config.Mutations[mutation] ~= nil) and model:GetAttribute("Stage") == 1
			and type(model:GetAttribute("BaseYaw")) == "number" and type(model:GetAttribute("SpinSpeed")) == "number"
			and type(model:GetAttribute("Bob")) == "number" and model:GetAttribute("Rarity") == (def and def.rarity),
			"attributs " .. model.Name)
		if typeof(pos) == "Vector3" and model:GetAttribute("Owner") == nil and not model:GetAttribute("Royal") then
			check(model:GetAttribute("Zone") == Config.ZoneAt(pos.Z) and pos.Z < Config.BaseLineZ, "zone " .. model.Name)
			for other = index + 1, #models do
				local otherPos = models[other]:GetAttribute("BasePos")
				if typeof(otherPos) == "Vector3" and models[other]:GetAttribute("Owner") == nil
					and not models[other]:GetAttribute("Royal") then
					local gap = Vector2.new(pos.X - otherPos.X, pos.Z - otherPos.Z).Magnitude
					check(gap >= MIN_SPACING, ("ecart %.1f studs"):format(gap))
				end
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
			check(model:GetAttribute("LagoonTier") == Stats.LagoonTier(Stats.Income(d, os.time())), "LagoonTier base " .. index)
			for slot = 1, Config.MaxSlots do
				local shown = model.Display:FindFirstChild("Slot" .. slot)
				local want = slot <= slots and d.pools[slot] or nil
				check((shown and shown:GetAttribute("Uid")) == (want and want.uid),
					("bassin %d affiche %s"):format(slot, want and want.id or "rien"))
				if shown and want then
					check(shown:GetAttribute("CreatureId") == want.id and shown:GetAttribute("Mutation") == want.mut
						and shown:GetAttribute("Stage") == Stats.Stage(want, os.time(), Stats.GrowthSpeed(d)), ("attributs bassin %d"):format(slot))
				end
				local lock = model.Pedestals["Pedestal" .. slot]:FindFirstChild("LockGui")
				check(lock ~= nil and lock.Enabled == (slot > slots), ("cadenas socle %d"):format(slot))
			end
			local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			check(humanoid ~= nil and humanoid.WalkSpeed == PlotService.SpeedOf(profile), "WalkSpeed " .. player.Name)
		end
	end
	for index = 1, Config.MaxPlayersPerServer do
		local model = PlotService.GetModel(index)
		check(model ~= nil, "base " .. index .. " existe")
		if model and not used[index] then
			check(model:GetAttribute("Owner") == nil and model:GetAttribute("OwnerName") == nil
				and model:GetAttribute("LagoonTier") == nil, "base libre " .. index)
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
		{ "StartSteal", table.pack("1", 1), "BadRequest" },
		{ "StartSteal", table.pack(1.5, 1), "BadRequest" },
		{ "StartSteal", table.pack(0 / 0, 0 / 0), "BadRequest" },
		{ "StartSteal", table.pack(99, 1), "BadRequest" },
		{ "Mount", table.pack(123), "BadRequest" },
		{ "Mount", table.pack("nope"), "NotMountable" },
		{ "ChoosePick", table.pack("Ghost"), "BadRequest" },
		{ "ChoosePick", table.pack({}), "BadRequest" },
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
	{ "croissance", checkGrowth },
	{ "marees", checkTides },
	{ "depot", checkDeposit },
	{ "donnees", checkSanitize },
	{ "remotes", checkRemotes },
	{ "vague", checkWave },
	{ "creatures", checkCreatures },
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
