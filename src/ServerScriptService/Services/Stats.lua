-- Stats : calculs purs (revenus, sac, socles, vitesse, depot, tirages).
-- Aucun effet de bord : se teste en mode Edit.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Stats = {}

function Stats.ItemIncome(itemId)
	local def = Config.Items[itemId]
	return def and def.income or 0
end

function Stats.SellValue(itemId)
	return Stats.ItemIncome(itemId) * Config.SellMultiplier
end

function Stats.BagMax(data)
	return Config.GetUpgradeValue("Bag", data.levels.Bag)
end

function Stats.Slots(data)
	return math.min(Config.MaxSlots, Config.GetUpgradeValue("Slots", data.levels.Slots))
end

function Stats.WalkSpeed(data)
	return Config.GetUpgradeValue("Speed", data.levels.Speed)
end

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

-- Revenu des socles seuls, par seconde
function Stats.BaseIncome(data)
	local total = 0
	for _, itemId in ipairs(data.display) do
		total += Stats.ItemIncome(itemId)
	end
	return total
end

-- Revenu total par seconde, bonus compris
function Stats.Income(data)
	return Stats.BaseIncome(data) * (1 + Stats.PetBoost(data))
end

-- Tableau dense de longueur Slots, "" = socle vide
function Stats.NormalizeDisplay(data)
	local slots = Stats.Slots(data)
	local out = table.create(slots, "")
	for slot = 1, slots do
		local itemId = data.display[slot]
		if type(itemId) == "string" and Config.Items[itemId] then
			out[slot] = itemId
		end
	end
	return out
end

-- Depot : garde les meilleurs tresors sur les socles, vend le reste.
-- Les tresors deja poses et conserves ne changent pas de socle.
-- Renvoie newDisplay, placed = {{slot, id}}, sold = {itemId}
function Stats.Deposit(display, slots, bag)
	local pool = {}
	for slot = 1, slots do
		local itemId = display[slot]
		if itemId and itemId ~= "" then
			table.insert(pool, { id = itemId, slot = slot })
		end
	end
	for _, itemId in ipairs(bag) do
		table.insert(pool, { id = itemId })
	end
	-- Plus gros revenu d'abord ; a egalite, ce qui est deja pose reste
	table.sort(pool, function(a, b)
		local incomeA, incomeB = Stats.ItemIncome(a.id), Stats.ItemIncome(b.id)
		if incomeA ~= incomeB then
			return incomeA > incomeB
		end
		return a.slot ~= nil and b.slot == nil
	end)

	local newDisplay = table.create(slots, "")
	local newcomers, sold = {}, {}
	for rank, entry in ipairs(pool) do
		if rank > slots then
			table.insert(sold, entry.id)
		elseif entry.slot then
			newDisplay[entry.slot] = entry.id
		else
			table.insert(newcomers, entry.id)
		end
	end

	local placed = {}
	local free = 1
	for _, itemId in ipairs(newcomers) do
		while newDisplay[free] ~= "" do
			free += 1
		end
		newDisplay[free] = itemId
		table.insert(placed, { slot = free, id = itemId })
	end
	return newDisplay, placed, sold
end

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

return Stats
