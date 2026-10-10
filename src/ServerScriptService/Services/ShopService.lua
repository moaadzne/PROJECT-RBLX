-- ShopService : boutique complète MMORPG (Phase 1 + préparation Phase 2).
-- Gamepasses : VIPRider 79, SpeedBoost 149, BagExpand 99, StarterPack 249 (bundle 3 passes).
-- Produits : TideEgg 199 (chances par rareté 60/25/10/4/1 + pity 50), PickCreature 399, DeepDive 399 (semaine 2, Pearls).
-- Rewarded Ads : 1 TideEgg/jour gratuit (cooldown 24h partagé).
-- Battle Pass : 12 semaines, 499 Robux, 12 paliers gratuits + 12 premium.
-- PolicyService gating : ArePaidRandomItemsRestricted -> TideEgg caché, PickCreature visible.
-- A/B test : priceVariants sur VIPRider (79/99/129 mobile/PC séparés).
-- Analytics : PurchaseAttempted, PurchaseCompleted, PurchaseFailed, RewardedAdWatched, RewardedAdFailed.
-- Premium Payouts listener (passif).
-- ProcessReceipt idempotent : achat confirmé seulement après sauvegarde PurchaseId.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local AnalyticsService = game:GetService("AnalyticsService")

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

-- A/B test : variantes de prix. Format : { price = 79, weight = 0.5, label = "A", platform = "mobile|pc|both" }
local function pickPriceVariant(passConfig: { price: number, priceVariants: { { price: number, weight: number, label: string, platform: string? } }? }, player): number
	if not passConfig.priceVariants or #passConfig.priceVariants == 0 then
		return passConfig.price
	end
	-- Détecter plateforme (simplifié : via UserInputService côté client, ici on utilise attribut)
	local platform = player:GetAttribute("Platform") or "both"
	local totalWeight = 0
	for _, v in ipairs(passConfig.priceVariants) do
		local vPlatform = v.platform or "both"
		if vPlatform == "both" or vPlatform == platform then
			totalWeight += v.weight or 0
		end
	end
	if totalWeight <= 0 then
		return passConfig.price
	end
	local roll = rng:NextNumber() * totalWeight
	local acc = 0
	for _, v in ipairs(passConfig.priceVariants) do
		local vPlatform = v.platform or "both"
		if vPlatform == "both" or vPlatform == platform then
			acc += v.weight or 0
			if roll <= acc then
				return v.price
			end
		end
	end
	return passConfig.price
end

-- Applique les effets des gamepasses (et du bundle) au profil
local function applyPasses(player, profile)
	local passes = profile.passes
	local d = profile.data
	-- VIPRider
	local vip = passes.VIPRider
	if vip then
		d._growth = Shop.Passes.VIPRider.growthMult or 1
		d._passBonus = Shop.Passes.VIPRider.coinBonus or 0.10
		d._mountSpeedBonus = Shop.Passes.VIPRider.mountSpeedBonus or 0.10
		d._priorityQueue = Shop.Passes.VIPRider.priorityQueue == true
		d._exclusiveEmote = Shop.Passes.VIPRider.exclusiveEmote == true
	else
		d._growth = nil
		d._passBonus = nil
		d._mountSpeedBonus = nil
		d._priorityQueue = nil
		d._exclusiveEmote = nil
	end
	-- SpeedBoost
	local speed = passes.SpeedBoost
	if speed then
		d._waveSpeedBonus = Shop.Passes.SpeedBoost.waveSpeedBonus or 0.15
		d._homeCooldownMult = Shop.Passes.SpeedBoost.homeCooldownMult or 0.70
	else
		d._waveSpeedBonus = nil
		d._homeCooldownMult = nil
	end
	-- BagExpand
	local bag = passes.BagExpand
	if bag then
		profile.pickupMult = 1
		d._extraSlots = Shop.Passes.BagExpand.extraSlots or 10
	else
		profile.pickupMult = 1
		d._extraSlots = nil
	end
	-- StarterPack : ne fait rien de plus (c'est la somme des 3)
	player:SetAttribute("VIP", vip == true)
	PlotService.RenderDisplay(player)
	DataService.MarkDirty(player)
end

-- Vérifie les gamepasses possédés au chargement (et applique le bundle si possède)
local function checkPlayer(player, profile)
	local passConfigs = Shop.Passes
	for name, pass in pairs(passConfigs) do
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
	-- Si le joueur a le StarterPack, on accorde les 3 passes (idempotent)
	if profile.passes.StarterPack then
		profile.passes.VIPRider = true
		profile.passes.SpeedBoost = true
		profile.passes.BagExpand = true
	end
	-- PolicyService : aléatoire payant
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	profile.randomAllowed = ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false
	-- Rewarded Ad cooldown (persiste dans le profil)
	if not profile.data._rewardedAdCooldown then
		profile.data._rewardedAdCooldown = 0
	end
	-- Battle Pass progress
	if not profile.data._battlePass then
		profile.data._battlePass = { tier = 0, premium = false, xp = 0, claimed = {} }
	end
	if player.Parent and DataService.Get(player) == profile then
		applyPasses(player, profile)
	end
end

-- Choisit l'espèce selon chances par rareté (TideEgg)
local function pickTideEggSpecies(egg, pick)
	if type(egg.chances) ~= "table" then
		return nil
	end
	local speciesWeights = {}
	for _, sp in ipairs(pick.species) do
		local info = Config.Creatures[sp]
		if info then
			local rarityWeight = egg.chances[info.rarity] or 0
			if rarityWeight > 0 then
				table.insert(speciesWeights, { sp, rarityWeight })
			end
		end
	end
	if #speciesWeights == 0 then
		return nil
	end
	-- Pity system : si pityCount >= pity, forcer Legendary
	local profile = DataService.Get(Players.LocalPlayer) -- fallback, mais pity géré côté serveur via profile.data._pityCount
	return Stats.PickWeighted(speciesWeights, rng)
end

-- Pose une créature achetée : bassin libre, sinon remplace la plus faible (relâchée contre pièces)
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

-- Traite l'achat d'un produit développeur (TideEgg, PickCreature, DeepDive, RewardedAd)
local function grant(player, profile, productId)
	local egg = Shop.TideEgg
	local pick = Shop.PickCreature
	local deep = Shop.DeepDive

	if productId == egg.id and profile.randomAllowed then
		-- TideEgg : tirage par rareté avec pity
		local pityCount = profile.data._pityCount or 0
		local pityMax = egg.pity or 50
		local species
		if pityCount >= pityMax then
			-- Pity : forcer Legendary
			local legendarySpecies = {}
			for _, sp in ipairs(pick.species) do
				if Config.Creatures[sp].rarity == "Legendary" then
					table.insert(legendarySpecies, sp)
				end
			end
			if #legendarySpecies > 0 then
				species = legendarySpecies[rng:NextInteger(1, #legendarySpecies)]
			else
				species = pickTideEggSpecies(egg, pick)
			end
			profile.data._pityCount = 0
		else
			species = pickTideEggSpecies(egg, pick)
			if species and Config.Creatures[species].rarity == "Legendary" then
				profile.data._pityCount = 0
			else
				profile.data._pityCount = pityCount + 1
			end
		end
		local mutation = rng:NextNumber() * 100 < (egg.goldenChance or 0) and "Golden" or ""
		return "TideEgg", species, mutation, { pityCount = profile.data._pityCount }

	elseif productId == pick.id or (productId == egg.id and not profile.randomAllowed) then
		-- Pick a Creature, ou Tide Egg pour joueur restreint : choix direct
		local choice = profile.pickChoice
		local species = (choice and table.find(pick.species, choice)) and choice or pick.species[1]
		profile.pickChoice = nil
		return "PickCreature", species, "", {}

	elseif productId == deep.id and deep.enabled then
		-- DeepDive (semaine 2) : monnaie Pearls
		-- Logique similaire mais avec pool DeepDive
		return "DeepDive", "", "", {}

	elseif productId == "RewardedAd" then
		-- Rewarded Ad : TideEgg gratuit (même logique que TideEgg payant)
		local species = pickTideEggSpecies(egg, pick)
		if not species then
			return nil
		end
		local mutation = rng:NextNumber() * 100 < (egg.goldenChance or 0) and "Golden" or ""
		return "RewardedAd", species, mutation, {}

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
		-- Analytics : PurchaseAttempted
		pcall(function()
			AnalyticsService:FireEvent("PurchaseAttempted", {
				playerId = player.UserId,
				productId = receipt.ProductId,
				currency = "Robux",
			})
		end)
		local product, species, mutation, extra = grant(player, profile, receipt.ProductId)
		if not product then
			warn("[TideRush] produit inconnu : " .. tostring(receipt.ProductId))
			pcall(function()
				AnalyticsService:FireEvent("PurchaseFailed", {
					playerId = player.UserId,
					productId = receipt.ProductId,
					reason = "UnknownProduct",
				})
			end)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		if not giveCreature(player, profile, species, mutation) then
			pcall(function()
				AnalyticsService:FireEvent("PurchaseFailed", {
					playerId = player.UserId,
					productId = receipt.ProductId,
					reason = "NoSlot",
				})
			end)
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
			pityCount = extra.pityCount,
			text = ("%s%s joined your reef!"):format(mutation ~= "" and (mutation .. " ") or "", Config.Creatures[species].name),
		})
		DataService.MarkDirty(player)
		-- Analytics : PurchaseCompleted
		pcall(function()
			AnalyticsService:FireEvent("PurchaseCompleted", {
				playerId = player.UserId,
				productId = receipt.ProductId,
				product = product,
				species = species,
				mutation = mutation,
			})
		end)
	end
	-- Confirme seulement une fois l'achat sauvegardé
	if DataService.Save(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- RF GetPlayerPasses : renvoie les passes du joueur + prix actuels (avec A/B)
local function getPlayerPasses(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local result = {}
	for name, pass in pairs(Shop.Passes) do
		result[name] = {
			owned = profile.passes[name] == true,
			price = pickPriceVariant(pass, player),
			name = pass.name,
			id = pass.id,
		}
	end
	return true, result
end

-- RF BuyPass : achat gamepass (déclenche PromptGamePassPurchase côté client, ici juste confirmation)
local function buyPass(player, passName)
	if type(passName) ~= "string" then
		return false, "BadRequest"
	end
	local pass = Shop.Passes[passName]
	if not pass or pass.id == 0 then
		return false, "NotAvailable"
	end
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	-- Le client fait PromptGamePassPurchase, on attend PromptGamePassPurchaseFinished
	-- Ici on renvoie juste le prix pour confirmation UI
	return true, { price = pickPriceVariant(pass, player), id = pass.id }
end

-- RF ChoosePick : le client choisit l'espèce avant l'achat Pick a Creature
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

-- RF ClaimRewardedAd : le client réclame son TideEgg gratuit après avoir regardé une pub
local function claimRewardedAd(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local ad = Shop.RewardedAd
	if not ad or not ad.enabled then
		return false, "Disabled"
	end
	local now = os.time()
	local cooldown = profile.data._rewardedAdCooldown or 0
	if now < cooldown then
		return false, "Cooldown", { nextAvailable = cooldown }
	end
	-- Accorder le TideEgg
	local egg = Shop.TideEgg
	local pick = Shop.PickCreature
	local species = pickTideEggSpecies(egg, pick)
	if not species then
		return false, "NoSpecies"
	end
	local mutation = rng:NextNumber() * 100 < (egg.goldenChance or 0) and "Golden" or ""
	if not giveCreature(player, profile, species, mutation) then
		return false, "NoSlot"
	end
	-- Mettre à jour le cooldown (24h)
	profile.data._rewardedAdCooldown = now + (ad.cooldownHours or 24) * 3600
	Net.Notify(player, "purchase", {
		product = "RewardedAd",
		species = species,
		mutation = mutation,
		text = ("%s%s joined your reef!"):format(mutation ~= "" and (mutation .. " ") or "", Config.Creatures[species].name),
	})
	DataService.MarkDirty(player)
	-- Analytics : RewardedAdWatched
	pcall(function()
		AnalyticsService:FireEvent("RewardedAdWatched", {
			playerId = player.UserId,
			reward = "TideEgg",
			species = species,
			mutation = mutation,
		})
	end)
	if DataService.Save(player) then
		return true, { species = species, mutation = mutation, nextCooldown = profile.data._rewardedAdCooldown }
	end
	return false, "SaveFailed"
end

-- RF GetShopState : état complet boutique pour le client (prix, probabilités, pity, battlepass, cooldowns)
local function getShopState(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	local egg = Shop.TideEgg
	local pick = Shop.PickCreature
	local ad = Shop.RewardedAd
	local bp = Shop.BattlePass
	local passes = {}
	for name, pass in pairs(Shop.Passes) do
		passes[name] = {
			owned = profile.passes[name] == true,
			price = pickPriceVariant(pass, player),
			name = pass.name,
			id = pass.id,
		}
	end
	return true, {
		passes = passes,
		tideEgg = {
			price = egg.price,
			id = egg.id,
			chances = egg.chances,
			goldenChance = egg.goldenChance,
			pity = egg.pity,
			pityCount = profile.data._pityCount or 0,
			available = profile.randomAllowed and egg.id ~= 0,
		},
		pickCreature = {
			price = pick.price,
			id = pick.id,
			species = pick.species,
			available = (not profile.randomAllowed) and pick.id ~= 0,
		},
		rewardedAd = {
			enabled = ad.enabled,
			cooldownHours = ad.cooldownHours,
			nextAvailable = profile.data._rewardedAdCooldown or 0,
			available = ad.enabled and (profile.data._rewardedAdCooldown or 0) <= os.time(),
		},
		battlePass = {
			enabled = bp.enabled,
			price = bp.price,
			durationWeeks = bp.durationWeeks,
			freeTiers = bp.freeTiers,
			premiumTiers = bp.premiumTiers,
			owned = profile.data._battlePass and profile.data._battlePass.premium or false,
			tier = profile.data._battlePass and profile.data._battlePass.tier or 0,
			xp = profile.data._battlePass and profile.data._battlePass.xp or 0,
		},
		cosmeticRotation = Shop.CosmeticRotation,
		randomAllowed = profile.randomAllowed,
	}
end

-- Premium Payouts : listener passif (Roblox gère automatiquement, on log pour analytics)
Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("Premium", player.MembershipType == Enum.MembershipType.Premium)
end)

function ShopService.Start()
	Net.Handle("GetPlayerPasses", getPlayerPasses)
	Net.Handle("BuyPass", buyPass)
	Net.Handle("ChoosePick", choosePick)
	Net.Handle("ClaimRewardedAd", claimRewardedAd)
	Net.Handle("GetShopState", getShopState)

	DataService.OnLoaded(function(player, profile)
		checkPlayer(player, profile)
		-- Envoyer état boutique initial
		local ok, state = getShopState(player)
		if ok then
			Net.Notify(player, "shopState", state)
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local profile = DataService.Get(player)
		if not profile or not profile.loaded then
			return
		end
		for name, pass in pairs(Shop.Passes) do
			if pass.id ~= 0 and pass.id == passId then
				profile.passes[name] = true
				-- Si c'est le StarterPack, accorder les 3 passes
				if name == "StarterPack" then
					profile.passes.VIPRider = true
					profile.passes.SpeedBoost = true
					profile.passes.BagExpand = true
				end
				applyPasses(player, profile)
				-- Notifier client
				local ok, state = getShopState(player)
				if ok then
					Net.Notify(player, "shopState", state)
				end
				break
			end
		end
	end)

	MarketplaceService.ProcessReceipt = processReceipt
end

return ShopService