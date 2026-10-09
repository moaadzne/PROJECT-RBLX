-- Stats : calculs purs (revenu, croissance, depot, mutations, Codex, hors ligne, tirages).
-- Aucun effet de bord, aucune horloge lue ici : `now` est toujours passe en argument.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Stats = {}

function Stats.BagMax(data)
	return Config.GetUpgradeValue("Bag", data.levels.Bag)
end

function Stats.Slots(data)
	return math.min(Config.MaxSlots, Config.GetUpgradeValue("Slots", data.levels.Slots))
end

function Stats.WalkSpeed(data)
	return Config.GetUpgradeValue("Speed", data.levels.Speed)
end

-- Creatures ----------------------------------------------------------------

function Stats.Rarity(species)
	local def = Config.Creatures[species]
	return def and def.rarity or "Common"
end

function Stats.MutationMult(mutation)
	local def = Config.Mutations[mutation]
	return def and def.mult or 1
end

-- Revenu d'un bebe (mutation comprise), sert au prix de relache et a la comparaison au depot
function Stats.BabyIncome(species, mutation)
	local def = Config.Creatures[species]
	return (def and def.income or 0) * Stats.MutationMult(mutation)
end

function Stats.ReleaseValue(species, mutation)
	return Stats.BabyIncome(species, mutation) * Config.SellMultiplier
end

-- Champs passagers poses sur data par ShopService (jamais relus du DataStore) :
-- _growth = vitesse de croissance (FastGrowth), _passBonus = bonus de pieces (VIPRider)
function Stats.GrowthSpeed(data)
	return data._growth or 1
end

-- Stade (1..4) et heure du stade suivant (0 si Giant)
function Stats.Stage(creature, now, speed)
	return Config.StageAt(Stats.Rarity(creature.id), creature.born, now, speed)
end

-- Revenu/s d'une creature deposee (stade et mutation), sans bonus
function Stats.CreatureIncome(creature, now, speed)
	local stage = Stats.Stage(creature, now, speed)
	return Stats.BabyIncome(creature.id, creature.mut) * Config.Stages[stage].mult
end

function Stats.CreatureCount(data)
	local count = 0
	for _, creature in ipairs(data.pools) do
		if creature then
			count += 1
		end
	end
	return count
end

-- Protection debutant : peu de temps de jeu ou peu de creatures (ni voler ni etre vole)
function Stats.IsNewbie(data)
	return data.playTime < Config.Steal.newbieMinutes * 60 or Stats.CreatureCount(data) < Config.Steal.newbieMinCreatures
end

function Stats.FindCreature(data, uid)
	for slot, creature in ipairs(data.pools) do
		if creature and creature.uid == uid then
			return creature, slot
		end
	end
	return nil, nil
end

-- Codex ---------------------------------------------------------------------

function Stats.Variant(mutation)
	return if mutation ~= nil and mutation ~= "" then mutation else "Normal"
end

function Stats.CodexTotal()
	local species = 0
	for _ in pairs(Config.Creatures) do
		species += 1
	end
	return species * #Config.CodexVariants
end

function Stats.CodexCount(data)
	local count = 0
	for _, variants in pairs(data.codex) do
		for _, variant in ipairs(Config.CodexVariants) do
			if variants[variant] then
				count += 1
			end
		end
	end
	return count
end

function Stats.CodexRowComplete(data, species)
	local variants = data.codex[species]
	if not variants then
		return false
	end
	for _, variant in ipairs(Config.CodexVariants) do
		if not variants[variant] then
			return false
		end
	end
	return true
end

-- Bonus permanent : +speciesBonus par ligne d'espece complete
function Stats.CodexBonus(data)
	local rows = 0
	for species in pairs(data.codex) do
		if Stats.CodexRowComplete(data, species) then
			rows += 1
		end
	end
	return rows * Config.Codex.speciesBonus
end

-- Compagnons -------------------------------------------------------------------

function Stats.FindPet(data, uid)
	for _, pet in ipairs(data.pets) do
		if pet.uid == uid then
			return pet
		end
	end
	return nil
end

local function petBoost(petId)
	local def = Config.Pets[petId]
	return def and def.boost or 0
end

-- Bonus total des compagnons equipes (0.3 = +30 %)
function Stats.PetBoost(data)
	local total = 0
	for _, uid in ipairs(data.equipped) do
		local pet = Stats.FindPet(data, uid)
		if pet then
			total += petBoost(pet.id)
		end
	end
	return total
end

-- Les meilleurs compagnons (uids), pour "Equip best"
function Stats.BestPets(data)
	local sorted = table.clone(data.pets)
	table.sort(sorted, function(a, b)
		local boostA, boostB = petBoost(a.id), petBoost(b.id)
		if boostA ~= boostB then
			return boostA > boostB
		end
		return (tonumber(a.uid) or 0) < (tonumber(b.uid) or 0)
	end)
	local out = {}
	for i = 1, math.min(Config.MaxEquippedPets, #sorted) do
		out[i] = sorted[i].uid
	end
	return out
end

function Stats.EquippedIds(data)
	local ids = {}
	for _, uid in ipairs(data.equipped) do
		local pet = Stats.FindPet(data, uid)
		if pet then
			table.insert(ids, pet.id)
		end
	end
	return table.concat(ids, ",")
end

-- Revenu ------------------------------------------------------------------------

-- Multiplicateur commun : 1 + compagnons + Codex + gamepass
function Stats.Bonus(data)
	return 1 + Stats.PetBoost(data) + Stats.CodexBonus(data) + (data._passBonus or 0)
end

-- Revenu des bassins seuls, par seconde
function Stats.BaseIncome(data, now)
	local total = 0
	for _, creature in ipairs(data.pools) do
		if creature then
			total += Stats.CreatureIncome(creature, now, Stats.GrowthSpeed(data))
		end
	end
	return total
end

-- Revenu total par seconde, bonus compris
function Stats.Income(data, now)
	return Stats.BaseIncome(data, now) * Stats.Bonus(data)
end

-- Pieces gagnees entre t0 et t1 (bonus compris), en suivant les changements de stade
function Stats.IncomeBetween(data, t0, t1)
	if not (t1 > t0) then
		return 0
	end
	local total = 0
	local speed = Stats.GrowthSpeed(data)
	for _, creature in ipairs(data.pools) do
		if creature then
			local t = t0
			while t < t1 do
				local stage, nextAt = Stats.Stage(creature, t, speed)
				local stop = if nextAt > 0 then math.min(nextAt, t1) else t1
				if stop <= t then
					stop = t1 -- securite : jamais de boucle infinie
				end
				total += Stats.BabyIncome(creature.id, creature.mut) * Config.Stages[stage].mult * (stop - t)
				t = stop
			end
		end
	end
	return total * Stats.Bonus(data)
end

function Stats.LagoonTier(income)
	local tier = 1
	for i, threshold in ipairs(Config.LagoonTiers) do
		if income >= threshold then
			tier = i
		end
	end
	return tier
end

-- Bassins -------------------------------------------------------------------------

-- Tableau dense de longueur Slots, false = bassin vide
function Stats.NormalizePools(data)
	local slots = Stats.Slots(data)
	local out = table.create(slots, false)
	for slot = 1, slots do
		local creature = data.pools[slot]
		if type(creature) == "table" then
			out[slot] = creature
		end
	end
	return out
end

-- Depot : bassin libre d'abord ; lagon plein -> la nouvelle remplace la plus faible si elle vaut plus,
-- sinon elle est relachee. Les meilleures nouvelles passent en premier.
-- newcomers = creatures deja creees ({uid, id, mut, born}).
-- locked = { [uid] = true } : jamais remplacees (montee, portee par un voleur). speed = vitesse de croissance.
-- Renvoie newPools, placed = {{slot, creature}}, released = {{creature, slot?}}
function Stats.Deposit(pools, slots, newcomers, now, speed, locked)
	locked = locked or {}
	local out = table.create(slots, false)
	for slot = 1, slots do
		out[slot] = pools[slot] or false
	end
	local order = table.clone(newcomers)
	table.sort(order, function(a, b)
		return Stats.BabyIncome(a.id, a.mut) > Stats.BabyIncome(b.id, b.mut)
	end)

	local placed, released = {}, {}
	for _, creature in ipairs(order) do
		local target = table.find(out, false)
		if not target then
			local weakest, weakestIncome = nil, math.huge
			for slot = 1, slots do
				if not locked[out[slot].uid] then
					local income = Stats.CreatureIncome(out[slot], now, speed)
					if income < weakestIncome then
						weakest, weakestIncome = slot, income
					end
				end
			end
			if weakest and Stats.CreatureIncome(creature, now, speed) > weakestIncome then
				table.insert(released, { creature = out[weakest], slot = weakest })
				target = weakest
			end
		end
		if target then
			out[target] = creature
			table.insert(placed, { slot = target, creature = creature })
		else
			table.insert(released, { creature = creature })
		end
	end
	return out, placed, released
end

-- Tirages -------------------------------------------------------------------------

-- Tirage pondere sur une liste {{id, poids}, ...}
function Stats.PickWeighted(list, rng)
	local total = 0
	for _, entry in ipairs(list) do
		total += entry[2]
	end
	local roll = rng:NextNumber() * total
	for _, entry in ipairs(list) do
		roll -= entry[2]
		if roll < 0 then
			return entry[1]
		end
	end
	return list[#list][1]
end

-- Mutation d'une creature qui apparait pendant la maree `tide` : "" ou une cle de Config.Mutations
function Stats.RollMutation(tide, rng)
	local def = Config.Tides[tide] or Config.Tides.Normal
	local roll = rng:NextNumber() * 100
	for _, entry in ipairs(def.odds) do
		roll -= entry[2]
		if roll < 0 then
			return entry[1]
		end
	end
	return ""
end

return Stats
