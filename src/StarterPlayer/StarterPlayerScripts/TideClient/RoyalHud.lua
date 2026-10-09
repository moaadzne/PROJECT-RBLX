-- RoyalHud : Maree Royale (GDD v2 §4.8, contrat v2.1).
--   wave.royal = {active, endsAt} ; RemoteEvent RoyalBoard {cycle, endsAt, top = {{userId, name, score}}} (trie) ;
--   Notify royal {phase = "start"|"end", top, rank?, coins?}.
-- Classement en direct (top 3 + ma place) pendant la manche ; les couronnes au-dessus des tetes viennent de
-- l'attribut joueur Crown (module NameTags).
local Players = game:GetService("Players")

local RoyalHud = {}

local RESULT_HOLD = 8 -- s : le classement final reste affiche apres la manche
local MEDAL_NAMES = { "Gold", "Silver", "Bronze" }
local MEDALS = { Color3.fromRGB(240, 190, 70), Color3.fromRGB(200, 208, 220), Color3.fromRGB(200, 130, 75) }

local Theme, Store, Hud, Notifications, Config, Sfx, Fx
local player = Players.LocalPlayer
local lastTop: { any } = {}
local active = false
local hideToken = 0

local function toRows(top: any)
	local rows = {}
	if type(top) ~= "table" then
		return rows
	end
	for _, entry in top do
		if type(entry) == "table" and type(entry.name) == "string" then
			table.insert(rows, {
				name = entry.name,
				score = tonumber(entry.score) or 0,
				isMe = tonumber(entry.userId) == player.UserId,
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.score > b.score
	end)
	return rows
end

local function showBoard()
	local rows = toRows(lastTop)
	if #rows == 0 then
		rows = { { name = "CATCH TO SCORE", score = 0, isMe = false } }
	end
	Hud.SetLeaderboard(rows, "Royal Tide")
end

local function setActive(isActive: boolean)
	if isActive == active then
		return
	end
	active = isActive
	hideToken += 1
	if isActive then
		lastTop = {}
		showBoard()
	else
		local token = hideToken
		task.delay(RESULT_HOLD, function()
			if hideToken == token then
				Hud.SetLeaderboard(nil)
			end
		end)
	end
end

local function onRoyal(data)
	if data.phase == "start" then
		setActive(true)
		Hud.ShowAlert("Royal Tide", { icon = "crown", color = Theme.Colors.Gold, duration = 3 })
	elseif data.phase == "end" then
		if type(data.top) == "table" then
			lastTop = data.top
			showBoard()
		end
		setActive(false)
		local rank = tonumber(data.rank)
		if rank and rank >= 1 and rank <= 3 then
			-- vrai moment : couronne
			local coins = tonumber(data.coins)
			Notifications.Reward({
				text = "#" .. rank,
				sub = MEDAL_NAMES[rank] .. " crown" .. (if coins then "  +" .. Config.Format(coins) else ""),
				color = MEDALS[rank],
			})
			Sfx.Play("royalWin")
			Fx.Confetti(workspace.CurrentCamera.ViewportSize / 2, 22)
		end
	end
end

function RoyalHud.Init(ctx)
	Theme, Hud, Notifications, Config, Sfx, Fx = ctx.Theme, ctx.Hud, ctx.Notifications, ctx.Config, ctx.Sfx, ctx.Fx
end

function RoyalHud.Start(ctx)
	Store = ctx.Store
	Store.WaveChanged:Connect(function(wave)
		setActive(wave.royal ~= nil and wave.royal.active)
	end)
	Store.RoyalBoard:Connect(function(board)
		lastTop = if type(board.top) == "table" then board.top else {}
		if active then
			showBoard()
		end
	end)
	Store.Notified:Connect(function(kind, data)
		if kind == "royal" then
			onRoyal(data)
		end
	end)
	local wave = Store.GetWave()
	setActive(wave.royal ~= nil and wave.royal.active)
end

return RoyalHud
