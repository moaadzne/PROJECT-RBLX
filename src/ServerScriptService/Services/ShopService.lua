-- ShopService : boutique de lancement (GDD 9). Prix fixes ; ids Roblox dans Config.Shop (0 = desactive).
-- Gamepasses : FastGrowth (croissance x2), BigNet (rayon de capture x1,5), VIPRider (+10 % pieces, +10 % monture).
-- Produits : Tide Egg (aleatoire, probabilites affichees) ou Pick a Creature (choix direct) si
-- PolicyService dit que l'aleatoire payant est restreint pour ce joueur. ProcessReceipt idempotent :
-- l'achat n'est confirme a Roblox qu'une fois sauvegarde avec son PurchaseId.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)

local ShopService = {}

local MAX_RECEIPTS = 100
local Shop = Config.Shop
local rng = Random.new()

local function applyPasses(player, profile)
	local passes = profile.passes
	local d = profile.data
	d._growth = passes.FastGrowth and Shop.Passes.FastGrowth.growth or nil
	d._passBonus = passes.VIPRider and Shop.Passes.VIPRider.coinBonus or nil
	profile.pickupMult = passes.BigNet and Shop.Passes.BigNet.pickupMult or 1
	player:SetAttribute("VIP", passes.VIPRider == true)
	PlotService.RenderDisplay(player) -- la croissance x2 peut changer les stades
	DataService.MarkDirty(player)
end

local function checkPlayer(player, profile)
	for name, pass in pairs(Shop.Passes) do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				profile.passes[name] = true
			elseif not ok then
				warn(("[TideRush] gamepass %s pour %s : %s"):format(name, player.Name, tostring(owns)))
			end
		end
	end
	-- aleatoire payant : refuse par defaut si la verification echoue
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	profile.randomAllowed = ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false
	if player.Parent and DataService.Get(player) == profile then
		applyPasses(player, profile)
	end
end

local function bestPick()
	local best, bestIncome = nil, -1
	for _, species in ipairs(Shop.PickCreature.species) do
		local income = Config.Creatures[species].income
		if income > bestIncome then
			best, bestIncome = species, income
		end
	end
	return best
end

-- Pose une creature achetee : bassin libre, sinon elle remplace la plus faible (qui est relachee contre des pieces)
local function giveCreature(player, profile, species, mutation)
	local d = profile.data
	local now = os.time()
	d.creatureSeq += 1
	local creature = { uid = tostring(d.creatureSeq), id = species, mut = mutation, born = now }
	local slots = Stats.Slots(d)
	local locked = DataService.LockedUids(profile)
	local target = table.find(d.pools, false)
	if not target then
		local weakestIncome = math.huge
		for slot = 1, slots do
			local current = d.pools[slot]
			if current and not locked[current.uid] then
				local income = Stats.CreatureIncome(current, now, Stats.GrowthSpeed(d))
				if income < weakestIncome then
					target, weakestIncome = slot, income
				end
			end
		end
		if target then
			local old = d.pools[target]
			local coins = Stats.ReleaseValue(old.id, old.mut)
			d.stats.released += 1
			DataService.AddCoins(player, coins)
			Net.Notify(player, "released", {
				species = old.id,
				mutation = old.mut,
				coins = coins,
				slot = target,
				text = ("Released %s +%s"):format(Config.Creatures[old.id].name, Config.Format(coins)),
			})
		end
	end
	if not target or target > slots then
		return false
	end
	d.pools[target] = creature
	PlotService.RenderDisplay(player)
	return true
end

local function grant(player, profile, productId)
	if productId == Shop.TideEgg.id and profile.randomAllowed then
		local species = Stats.PickWeighted(Shop.TideEgg.odds, rng)
		local mutation = rng:NextNumber() * 100 < Shop.TideEgg.goldenChance and "Golden" or ""
		return "TideEgg", species, mutation
	end
	if productId == Shop.PickCreature.id or productId == Shop.TideEgg.id then
		-- Pick a Creature, ou Tide Egg recu d'un joueur pour qui l'aleatoire est restreint : choix direct
		local choice = profile.pickChoice
		local species = (choice and table.find(Shop.PickCreature.species, choice)) and choice or bestPick()
		profile.pickChoice = nil
		return "PickCreature", species, ""
	end
	return nil
end

local function processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local profile = player and DataService.Get(player)
	if not profile or not profile.loaded or not profile.saveEnabled or profile.leaving then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local d = profile.data
	local purchaseId = tostring(receipt.PurchaseId)
	if not table.find(d.receipts, purchaseId) then
		local product, species, mutation = grant(player, profile, receipt.ProductId)
		if not product then
			warn("[TideRush] produit inconnu : " .. tostring(receipt.ProductId))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not giveCreature(player, profile, species, mutation) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		table.insert(d.receipts, purchaseId)
		while #d.receipts > MAX_RECEIPTS do
			table.remove(d.receipts, 1)
		end
		Net.Notify(player, "purchase", {
			product = product,
			species = species,
			mutation = mutation,
			text = ("%s%s joined your reef!"):format(mutation ~= "" and (mutation .. " ") or "", Config.Creatures[species].name),
		})
		DataService.MarkDirty(player)
	end
	-- confirme seulement une fois l'achat sauvegarde (sinon Roblox le representera plus tard)
	if DataService.Save(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

local function choosePick(player, species)
	if type(species) ~= "string" or not table.find(Shop.PickCreature.species, species) then
		return false, "BadRequest"
	end
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	profile.pickChoice = species
	return true
end

function ShopService.Start()
	Net.Handle("ChoosePick", choosePick)
	DataService.OnLoaded(function(player, profile)
		checkPlayer(player, profile)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local profile = DataService.Get(player)
		for name, pass in pairs(Shop.Passes) do
			if pass.id ~= 0 and pass.id == passId and profile and profile.loaded then
				profile.passes[name] = true
				applyPasses(player, profile)
			end
		end
	end)
	MarketplaceService.ProcessReceipt = processReceipt
end

return ShopService
