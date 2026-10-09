-- PoolBillboards : etiquette au-dessus de chaque bassin occupe du lagon du joueur
-- (nom + rarete, stade, mutation, barre et temps jusqu'au prochain stade).
-- Bassin = Map.Plots.PlotN.Pedestals.PedestalN (noms inchanges, decision D du 09/10).
-- Une seule boucle a 1 Hz pour toutes les etiquettes ; rien a chaque frame.
local Players = game:GetService("Players")

local PoolBillboards = {}

local UPDATE_EVERY = 1
local MAX_DISTANCE = 80
local BOARD_SIZE = UDim2.fromOffset(176, 80)
local BOARD_OFFSET = Vector3.new(0, 3.4, 0) -- au-dessus du bassin (a ajuster sur le visuel de C)
local MAX_STAGE = 4 -- Giant
local TEXT = 16 -- px reels : les billboards ne passent pas par l'UIScale du HUD

local Util, Theme, Components, Store, Sfx
local playerGui: Instance
local boards: { [number]: any } = {}
local currentPlot = 0

local function formatLeft(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s < 60 then
		return ("%ds"):format(s)
	elseif s < 3600 then
		return ("%dm %02ds"):format(s // 60, s % 60)
	end
	return ("%dh %02dm"):format(s // 3600, (s % 3600) // 60)
end

local function findPedestal(plot: number, slot: number): BasePart?
	local p = Util.Find(workspace, "Map", "Plots", "Plot" .. plot, "Pedestals", "Pedestal" .. slot)
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

local function entryKey(entry): string
	return ("%s|%s|%s|%s"):format(entry.species, entry.mutation or "", tostring(entry.bornAt), tostring(entry.stage))
end

---------------------------------------------------------------- Construction
local function buildBoard(slot: number, entry)
	local info = Store.CreatureInfo(entry.species)
	local rarity = info and info.rarity
	local rarityColor = Theme.RarityColor(rarity)
	local gui = Theme.Create("BillboardGui", {
		Name = "TR_Pool" .. slot,
		Size = BOARD_SIZE,
		StudsOffsetWorldSpace = BOARD_OFFSET,
		MaxDistance = MAX_DISTANCE,
		LightInfluence = 0,
		AlwaysOnTop = false,
		ResetOnSpawn = false,
		ClipsDescendants = false,
	})
	local card = Theme.Plate({
		Name = "Card",
		Position = UDim2.fromOffset(4, 12),
		Size = UDim2.new(1, -8, 1, -14),
		Accent = rarityColor,
		Parent = gui,
	})
	local badge = Theme.RarityBadge(rarity, 20)
	badge.Position = UDim2.fromOffset(8, 10)
	badge.ZIndex = 3
	badge.Parent = card
	Theme.Text({
		Name = "Name",
		Position = UDim2.fromOffset(32, 8),
		Size = UDim2.new(1, -38, 0, 24),
		Text = Store.CreatureName(entry.species),
		TextSize = TEXT + 2,
		FontFace = Theme.Fonts.Title,
		TextColor3 = rarityColor,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = card,
	})
	local stageLabel = Theme.Text({
		Name = "Stage",
		Position = UDim2.fromOffset(8, 32),
		Size = UDim2.new(0.55, -8, 0, 18),
		Text = "",
		TextSize = TEXT,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
		Parent = card,
	})
	local timeLabel = Theme.Text({
		Name = "Time",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -8, 0, 32),
		Size = UDim2.new(0.45, 0, 0, 18),
		Text = "",
		TextSize = TEXT,
		TextColor3 = Theme.Colors.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
		Parent = card,
	})
	local bar = Components.ProgressBar({
		Name = "Growth",
		Position = UDim2.fromOffset(8, 52),
		Size = UDim2.new(1, -16, 0, 10),
		Color = rarityColor,
		ZIndex = 3,
		Parent = card,
	})
	bar.Label.Visible = false
	-- mutation : pastille couleur + icone + nom, a cheval sur le haut de la carte
	local mutation = entry.mutation and Theme.Mutations[entry.mutation]
	if entry.mutation then
		local style = mutation or { label = entry.mutation, icon = "✦", color = Theme.Colors.White }
		local chip = Theme.Plate({
			Name = "Mutation",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 0),
			Size = UDim2.fromOffset(96, 22),
			Radius = 8,
			ZIndex = 5,
			Parent = gui,
		})
		Theme.Text({
			Name = "Text",
			Size = UDim2.fromScale(1, 1),
			Text = style.icon .. " " .. style.label,
			TextSize = TEXT - 1,
			FontFace = Theme.Fonts.Title,
			TextColor3 = style.color,
			ZIndex = 6,
			Parent = chip,
		})
		-- contour de la carte dans la couleur de la mutation
		local outline = card:FindFirstChildOfClass("UIStroke")
		if outline then
			outline.Color = style.color
		end
	end
	gui.Parent = playerGui
	return {
		gui = gui,
		card = card,
		key = entryKey(entry),
		entry = entry,
		stage = 0,
		stageLabel = stageLabel,
		timeLabel = timeLabel,
		bar = bar,
		rarityColor = rarityColor,
	}
end

local function destroyBoard(slot: number)
	local board = boards[slot]
	if board then
		board.gui:Destroy()
		boards[slot] = nil
	end
end

---------------------------------------------------------------- Mise a jour
local function attach(slot: number, board)
	local adornee = board.gui.Adornee
	if adornee and adornee.Parent then
		return
	end
	-- streaming : le bassin peut arriver plus tard, on reessaie a chaque tick
	board.gui.Adornee = findPedestal(currentPlot, slot)
end

local function refreshBoard(slot: number, board, now: number)
	attach(slot, board)
	local stage, progress, left = Store.CreatureStage(board.entry, now)
	if stage ~= board.stage then
		local grew = board.stage > 0 and stage > board.stage
		board.stage = stage
		board.stageLabel.Text = Store.StageId(stage)
		if grew then
			Theme.Pop(board.card, 0.25)
			Sfx.Play("grow")
		end
	end
	if left then
		board.timeLabel.Text = formatLeft(left)
		board.bar:Set(progress, false)
	elseif stage >= MAX_STAGE then
		board.timeLabel.Text = "MAX"
		board.bar:Set(1, false)
		board.bar:SetColor(Theme.Colors.Gold)
	else
		-- duree inconnue (serveur v1, ou stade sans date) : pas de faux chiffre
		board.timeLabel.Text = ""
		board.bar:Set(progress, false)
	end
end

local function onState(state)
	if not state.loaded then
		return
	end
	if state.plot ~= currentPlot then
		for slot in boards do
			destroyBoard(slot)
		end
		currentPlot = state.plot
	end
	local pools = if currentPlot > 0 then state.pools else {}
	local now = Store.ServerClock()
	for slot in boards do
		if not pools[slot] then
			destroyBoard(slot)
		end
	end
	for slot, entry in pools do
		if entry then
			local board = boards[slot]
			if board and board.key ~= entryKey(entry) then
				destroyBoard(slot)
				board = nil
			end
			if not board then
				board = buildBoard(slot, entry)
				boards[slot] = board
				Theme.Pop(board.card, 0.2)
			end
			board.entry = entry
			refreshBoard(slot, board, now)
		end
	end
end

---------------------------------------------------------------- Demarrage
function PoolBillboards.Init(ctx)
	Util, Theme, Components, Sfx = ctx.Util, ctx.Theme, ctx.Components, ctx.Sfx
	playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

function PoolBillboards.Start(ctx)
	Store = ctx.Store
	Store.Changed:Connect(onState)
	onState(Store.Get())
	while true do
		task.wait(UPDATE_EVERY)
		local now = Store.ServerClock()
		for slot, board in boards do
			refreshBoard(slot, board, now)
		end
	end
end

return PoolBillboards
