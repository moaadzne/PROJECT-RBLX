-- DailyRewardService : récompenses journalières (connexion jour 1-7, jour 7 = Tide Egg gratuit)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Net)

local DailyRewardService = {}

-- Récompenses par jour (index 1 = jour 1)
local DAILY_REWARDS = {
	{ type = "Coins", amount = 500 },
	{ type = "Coins", amount = 1000 },
	{ type = "Coins", amount = 2000 },
	{ type = "Coins", amount = 3500 },
	{ type = "Coins", amount = 5000 },
	{ type = "Coins", amount = 7500 },
	{ type = "TideEgg", amount = 1 }, -- jour 7 = Tide Egg gratuit (non échangeable)
}

local STREAK_GRACE_DAYS = 1 -- 1 jour de grâce par semaine si coupure

local function getDailyData(profile)
	local d = profile.data
	d.dailyRewards = d.dailyRewards or { lastClaimDay = 0, streak = 0, graceUsedThisWeek = false }
	return d.dailyRewards
end

local function getCurrentDay()
	return math.floor(os.time() / 86400) -- jours Unix
end

function DailyRewardService.ClaimDaily(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end

	local daily = getDailyData(profile)
	local today = getCurrentDay()

	if daily.lastClaimDay == today then
		return false, "AlreadyClaimed"
	end

	-- Vérifier streak
	local dayDiff = today - daily.lastClaimDay
	local newStreak = 1
	if dayDiff == 1 then
		newStreak = daily.streak + 1
	elseif dayDiff > 1 then
		-- Coupure : vérifier grâce hebdomadaire
		local weekStart = today - (today % 7)
		if not daily.graceUsedThisWeek and dayDiff <= STREAK_GRACE_DAYS + 1 then
			newStreak = daily.streak + 1
			daily.graceUsedThisWeek = true
		else
			newStreak = 1
			daily.graceUsedThisWeek = false
		end
	end

	-- Récompense du jour (modulo 7 pour cycle infini)
	local rewardIndex = ((newStreak - 1) % 7) + 1
	local reward = DAILY_REWARDS[rewardIndex]

	-- Donner la récompense
	if reward.type == "Coins" then
		DataService.AddCoins(player, reward.amount)
	elseif reward.type == "TideEgg" then
		-- Ajouter un Tide Egg gratuit (marqué non-échangeable)
		DataService.AddTideEgg(player, reward.amount, true)
	end

	-- Mettre à jour
	daily.lastClaimDay = today
	daily.streak = newStreak
	if today % 7 == 0 then
		daily.graceUsedThisWeek = false -- reset grâce hebdomadaire
	end
	DataService.MarkDirty(player)

	-- Notifier client
	Net.Notify(player, "dailyReward", {
		day = newStreak,
		reward = reward,
		streak = newStreak,
		text = ("Jour %d : +%s"):format(newStreak, reward.type == "Coins" and (reward.amount .. " pièces") or "Tide Egg gratuit"),
	})

	return true, { day = newStreak, reward = reward, streak = newStreak }
end

function DailyRewardService.GetStatus(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return nil
	end
	local daily = getDailyData(profile)
	local today = getCurrentDay()
	return {
		canClaim = daily.lastClaimDay ~= today,
		streak = daily.streak,
		nextReward = DAILY_REWARDS[((daily.streak) % 7) + 1],
		lastClaimDay = daily.lastClaimDay,
	}
end

function DailyRewardService.Start()
	Net.Handle("ClaimDaily", DailyRewardService.ClaimDaily)
end

return DailyRewardService