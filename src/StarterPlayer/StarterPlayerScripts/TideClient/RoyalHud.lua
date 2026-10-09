-- RoyalHud : Maree Royale (GDD v2 §4.8). Forme du contrat PROVISOIRE (noms reserves par A) :
--   wave.royal = {active, endsAt} ; RemoteEvent RoyalBoard(board = {{userId, name, score}}) ; Notify royalResult {rank, reward}.
-- Classement en direct (top 3 + ma place) pendant la manche ; a la fin, couronnes or / argent / bronze au-dessus
-- de la tete du top 3 jusqu'a la manche suivante.
local Players = game:GetService("Players")

local RoyalHud = {}

local RESULT_HOLD = 8 -- s : le classement final reste affiche apres la manche
local MEDALS = {
	{ color = Color3.fromRGB(255, 204, 64), name = "Gold" },
	{ color = Color3.fromRGB(205, 215, 230), name = "Silver" },
	{ color = Color3.fromRGB(215, 140, 80), name = "Bronze" },
}

local Theme, Store, Hud, Notifications, Config, Sfx
local player = Players.LocalPlayer
local playerGui: Instance
local lastBoard: { any } = {}
local active = false
local hideToken = 0
local crowns: { BillboardGui } = {}

local function toRows(board: { any })
	local rows = {}
	for _, entry in board do
		if type(entry) == "table" and type(entry.name) == "string" then
			table.insert(rows, {
				name = entry.name,
				score = tonumber(entry.score) or 0,
				isMe = tonumber(entry.userId) == player.UserId,
				userId = tonumber(entry.userId),
			})
		end
	end
	table.sort(rows, function(a, b)
		return a.score > b.score
	end)
	return rows
end

---------------------------------------------------------------- Couronnes
local function clearCrowns()
	for _, gui in crowns do
		gui:Destroy()
	end
	crowns = {}
end

local function crownFor(target: Player, rank: number)
	local character = target.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local medal = MEDALS[rank]
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_Crown",
		Size = UDim2.fromOffset(96, 40),
		StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0),
		LightInfluence = 0,
		MaxDistance = 150,
		ResetOnSpawn = false,
		Adornee = head,
	})
	local plate = Theme.Plate({ Name = "Plate", Size = UDim2.fromScale(1, 1), Accent = medal.color, Parent = gui })
	-- couleur + icone + texte (lisible sans la couleur)
	Theme.Text({
		Name = "Text",
		Size = UDim2.fromScale(1, 1),
		Text = "👑 #" .. rank,
		TextSize = 20,
		FontFace = Theme.Fonts.Title,
		TextColor3 = medal.color,
		ZIndex = 3,
		Parent = plate,
	})
	gui.Parent = playerGui
	table.insert(crowns, gui)
end

local function placeCrowns(rows)
	clearCrowns()
	for rank = 1, math.min(3, #rows) do
		local target = rows[rank].userId and Players:GetPlayerByUserId(rows[rank].userId)
		if target then
			crownFor(target, rank)
		end
	end
end

---------------------------------------------------------------- Manche
local function showBoard()
	local rows = toRows(lastBoard)
	if #rows == 0 then
		rows = { { name = "Catch creatures to score!", score = 0, isMe = false } }
	end
	Hud.SetLeaderboard(rows, "👑 Royal Tide")
end

local function onWave(wave)
	local isActive = wave.royal ~= nil and wave.royal.active
	if isActive == active then
		return
	end
	active = isActive
	hideToken += 1
	if isActive then
		lastBoard = {}
		clearCrowns() -- les couronnes de la manche precedente tombent
		showBoard()
		Sfx.Play("royalStart")
		Notifications.Push({ text = "Royal Tide! Catch the best creatures to win a crown.", color = Theme.Colors.Gold, icon = "👑", priority = "wave", duration = 4 })
	else
		local rows = toRows(lastBoard)
		placeCrowns(rows)
		local token = hideToken
		task.delay(RESULT_HOLD, function()
			if hideToken == token then
				Hud.SetLeaderboard(nil)
			end
		end)
	end
end

local function onBoard(board)
	lastBoard = board
	if active then
		showBoard()
	end
end

---------------------------------------------------------------- Demarrage
function RoyalHud.Init(ctx)
	Theme, Hud, Notifications, Config, Sfx = ctx.Theme, ctx.Hud, ctx.Notifications, ctx.Config, ctx.Sfx
	playerGui = player:WaitForChild("PlayerGui")
end

function RoyalHud.Start(ctx)
	Store = ctx.Store
	Store.WaveChanged:Connect(onWave)
	Store.RoyalBoard:Connect(onBoard)
	Store.Notified:Connect(function(kind, data)
		if kind ~= "royalResult" then
			return
		end
		local rank = tonumber(data.rank)
		local reward = tonumber(data.reward)
		if rank and rank <= 3 then
			local medal = MEDALS[rank]
			Notifications.Reward({
				text = "#" .. rank,
				sub = medal.name .. " crown" .. (if reward then " · +" .. Config.Format(reward) else ""),
				color = medal.color,
			})
		elseif type(data.text) == "string" then
			Notifications.Push({ text = data.text, color = Theme.Colors.Gold, icon = "👑", priority = "reward" })
		end
	end)
	onWave(Store.GetWave())
end

return RoyalHud
