-- PetService : oeufs (pieces du jeu uniquement, jamais de Robux) et compagnons equipes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)

local PetService = {}

local BEST = "best"

local rng = Random.new()

local function hatch(player, eggId)
	if type(eggId) ~= "string" then
		return false, "BadRequest"
	end
	local egg = Config.GetEgg(eggId)
	if not egg then
		return false, "BadRequest"
	end
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local d = profile.data
	if #d.pets >= Config.MaxPetInventory then
		return false, "InventoryFull"
	end
	if not DataService.TrySpend(player, egg.cost) then
		return false, "NotEnoughCoins"
	end

	local petId = Stats.PickWeighted(egg.odds, rng)
	d.petSeq += 1
	local uid = tostring(d.petSeq)
	table.insert(d.pets, { uid = uid, id = petId })
	d.stats.eggsHatched += 1
	-- confort : equipe tout seul s'il reste une place
	if #d.equipped < Config.MaxEquippedPets then
		table.insert(d.equipped, uid)
	end

	local def = Config.Pets[petId]
	Net.Notify(player, "hatch", {
		eggId = eggId,
		petId = petId,
		uid = uid,
		rarity = def.rarity,
		text = ("You hatched a %s!"):format(def.name),
	})
	DataService.MarkDirty(player)
	return true, petId, uid
end

local function equip(player, uid, wantEquipped)
	if type(uid) ~= "string" or type(wantEquipped) ~= "boolean" then
		return false, "BadRequest"
	end
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local d = profile.data
	if uid == BEST then
		if not wantEquipped then
			return false, "BadRequest"
		end
		d.equipped = Stats.BestPets(d)
		DataService.MarkDirty(player)
		return true
	end
	if not Stats.FindPet(d, uid) then
		return false, "UnknownPet"
	end
	local index = table.find(d.equipped, uid)
	if wantEquipped and not index then
		if #d.equipped >= Config.MaxEquippedPets then
			return false, "EquipFull"
		end
		table.insert(d.equipped, uid)
	elseif not wantEquipped and index then
		table.remove(d.equipped, index)
	end
	DataService.MarkDirty(player)
	return true
end

function PetService.Start()
	Net.Handle("HatchEgg", hatch)
	Net.Handle("EquipPet", equip)
end

return PetService
