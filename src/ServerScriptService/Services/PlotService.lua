-- PlotService : bases des joueurs (attribution, tresors poses, verrous des socles),
-- proprietaire en attributs Owner / OwnerName (l'affichage du panneau appartient a C),
-- teleport a la base, bouton Home, revenus des socles (1 fois/s).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Services = script.Parent
local Net = require(Services.Net)
local Stats = require(Services.Stats)
local DataService = require(Services.DataService)
local ItemFactory = require(Services.ItemFactory)

local PlotService = {}

local LOCK_ICON = "🔒"
local DISPLAY_BOB = 0.25
local DISPLAY_GAP = 0.3
local SPAWN_HEIGHT = 3 -- pivot du personnage au-dessus de SpawnPos : pieds sur le deck
local SPAWN_LOOK = Vector3.new(0, 0, -10) -- regarde vers la plage
local STREAM_TIMEOUT = 3
local CHARACTER_TIMEOUT = 10
local INCOME_TICK = 1
local MAX_INCOME_DT = 5

local plots = {} -- [index] = { model, bounds = {minX, maxX, minZ, maxZ}, owner }
local plotOf = {} -- [player] = index

local function pedestalOf(model, slot)
	local folder = model:FindFirstChild("Pedestals")
	return folder and folder:FindFirstChild("Pedestal" .. slot)
end

local function setLock(model, slot, locked, text)
	local pedestal = pedestalOf(model, slot)
	local gui = pedestal and pedestal:FindFirstChild("LockGui")
	if not gui then
		return
	end
	gui.Enabled = locked
	local label = gui:FindFirstChildWhichIsA("TextLabel")
	if label then
		label.Text = text
	end
end

local function resetPlot(index)
	local plot = plots[index]
	plot.owner = nil
	plot.model:SetAttribute("Owner", nil)
	plot.model:SetAttribute("OwnerName", nil)
	local display = plot.model:FindFirstChild("Display")
	if display then
		display:ClearAllChildren()
	end
	for slot = 1, Config.MaxSlots do
		setLock(plot.model, slot, slot > Config.Upgrades.Slots.base, LOCK_ICON)
	end
end

function PlotService.GetIndex(player)
	return plotOf[player]
end

function PlotService.GetModel(index)
	return plots[index] and plots[index].model
end

function PlotService.IsInOwnPlot(player, position)
	local index = plotOf[player]
	local bounds = index and plots[index].bounds
	if not bounds then
		return false
	end
	return position.X >= bounds.minX and position.X <= bounds.maxX
		and position.Z >= bounds.minZ and position.Z <= bounds.maxZ
end

-- Pose les tresors du joueur sur ses socles et met a jour les cadenas
function PlotService.RenderDisplay(player)
	local index = plotOf[player]
	local profile = DataService.Get(player)
	if not index or not profile or not profile.loaded then
		return
	end
	local model = plots[index].model
	local display = model:FindFirstChild("Display")
	if not display then
		return
	end
	local d = profile.data
	local slots = Stats.Slots(d)

	local current = {}
	for _, child in ipairs(display:GetChildren()) do
		local slot = child:GetAttribute("Slot")
		if slot and not current[slot] then
			current[slot] = child
		else
			child:Destroy()
		end
	end

	for slot = 1, Config.MaxSlots do
		local want = (slot <= slots and d.display[slot]) or ""
		local have = current[slot]
		if have and have:GetAttribute("ItemId") ~= want then
			have:Destroy()
			have = nil
		end
		local pedestal = pedestalOf(model, slot)
		if want ~= "" and not have and pedestal then
			local top = pedestal.Position.Y + pedestal.Size.X / 2 -- cylindre couche : hauteur = Size.X
			local y = top + ItemFactory.RestOffset(want) + DISPLAY_BOB + DISPLAY_GAP
			local item = ItemFactory.Create(want, Vector3.new(pedestal.Position.X, y, pedestal.Position.Z), {
				zone = 0,
				bob = DISPLAY_BOB,
				slot = slot,
				beacon = false,
			})
			if item then
				item.Name = "Slot" .. slot
				item.Parent = display
			end
		end
		local lockText = LOCK_ICON
		if slot == slots + 1 and d.levels.Slots < Config.Upgrades.Slots.maxLevel then
			lockText = LOCK_ICON .. " " .. Config.Format(Config.GetUpgradeCost("Slots", d.levels.Slots))
		end
		setLock(model, slot, slot > slots, lockText)
	end
end

function PlotService.ApplySpeed(player)
	local profile = DataService.Get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and profile and profile.loaded then
		humanoid.WalkSpeed = Stats.WalkSpeed(profile.data)
	end
end

local function homeCFrame(player)
	local index = plotOf[player]
	local spawnPos = index and plots[index].model:GetAttribute("SpawnPos")
	if typeof(spawnPos) ~= "Vector3" then
		spawnPos = Config.HubSpawn
	end
	local position = spawnPos + Vector3.new(0, SPAWN_HEIGHT, 0)
	return CFrame.lookAt(position, position + SPAWN_LOOK)
end

-- Teleporte le joueur a sa base (ou au hub s'il n'en a pas). Peut attendre le streaming.
function PlotService.SendHome(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local target = homeCFrame(player)
	local ok, err = pcall(function()
		player:RequestStreamAroundAsync(target.Position, STREAM_TIMEOUT)
	end)
	if not ok then
		warn("[TideRush] streaming avant teleport : " .. tostring(err))
	end
	if player.Character ~= character or not root.Parent then
		return false
	end
	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	return true
end

local function onCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", CHARACTER_TIMEOUT)
	local root = character:WaitForChild("HumanoidRootPart", CHARACTER_TIMEOUT)
	if not humanoid or not root or player.Character ~= character then
		return
	end
	PlotService.ApplySpeed(player)
	humanoid.Died:Connect(function()
		-- mort (reset compris) = sac perdu, sinon le reset deviendrait un retour gratuit avec le sac
		local profile = DataService.Get(player)
		if profile and #profile.bag > 0 then
			local lost = #profile.bag
			profile.bag = {}
			Net.Notify(player, "bagLost", {
				lost = lost,
				text = ("You dropped %d treasure%s."):format(lost, lost > 1 and "s" or ""),
			})
			DataService.MarkDirty(player)
		end
	end)
	if not character:IsDescendantOf(workspace) then
		character.AncestryChanged:Wait()
	end
	task.wait()
	if player.Character == character then
		PlotService.SendHome(player)
	end
end

function PlotService.Assign(player)
	if plotOf[player] then
		return plotOf[player]
	end
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end

	local index = nil
	for i = 1, Config.MaxPlayersPerServer do
		if plots[i] and not plots[i].owner then
			index = i
			break
		end
	end
	if not index then
		warn("[TideRush] plus de base libre pour " .. player.Name)
		Net.Notify(player, "error", { code = "NoPlot", text = "Every beach is taken on this server." })
		return 0
	end

	local plot = plots[index]
	plot.owner = player
	plotOf[player] = index
	plot.model:SetAttribute("Owner", player.UserId)
	plot.model:SetAttribute("OwnerName", player.DisplayName)
	player:SetAttribute("Plot", index)
	local profile = DataService.Get(player)
	if profile then
		profile.plot = index
		if profile.loaded then
			PlotService.RenderDisplay(player)
		end
		DataService.MarkDirty(player)
	end
	return index
end

function PlotService.Release(player)
	local index = plotOf[player]
	plotOf[player] = nil
	if index and plots[index] and plots[index].owner == player then
		resetPlot(index)
	end
end

local function goHome(player)
	local profile = DataService.Get(player)
	if not profile or not profile.loaded then
		return false, "NotLoaded"
	end
	if not plotOf[player] then
		return false, "NoPlot"
	end
	local wave = Net.GetWave()
	if wave and wave.phase ~= "calm" then
		return false, "WaveActive"
	end
	local now = workspace:GetServerTimeNow()
	if now < profile.homeReadyAt then
		return false, "Cooldown"
	end
	-- cooldown pose avant l'attente du streaming : un double clic ne passe pas
	profile.homeReadyAt = now + Config.HomeCooldown
	DataService.MarkDirty(player)
	if not PlotService.SendHome(player) then
		profile.homeReadyAt = 0
		DataService.MarkDirty(player)
		return false, "BadRequest"
	end
	return true
end

local function incomeLoop()
	local last = os.clock()
	while true do
		task.wait(INCOME_TICK)
		local now = os.clock()
		local dt = math.min(now - last, MAX_INCOME_DT)
		last = now
		for player, profile in DataService.All() do
			if profile.loaded and not profile.leaving then
				local income = Stats.Income(profile.data)
				if income > 0 then
					DataService.AddCoins(player, income * dt)
				end
			end
		end
	end
end

function PlotService.Start()
	local folder = workspace:WaitForChild("Map"):WaitForChild("Plots")
	for _, model in ipairs(folder:GetChildren()) do
		local index = model:GetAttribute("Index")
		local minX, maxX = model:GetAttribute("MinX"), model:GetAttribute("MaxX")
		local minZ, maxZ = model:GetAttribute("MinZ"), model:GetAttribute("MaxZ")
		if type(index) == "number" and minX and maxX and minZ and maxZ then
			plots[index] = {
				model = model,
				bounds = { minX = minX, maxX = maxX, minZ = minZ, maxZ = maxZ },
				owner = nil,
			}
		else
			warn("[TideRush] base mal configuree : " .. model:GetFullName())
		end
	end
	for index in pairs(plots) do
		resetPlot(index)
	end
	DataService.OnLoaded(function(player)
		PlotService.RenderDisplay(player)
		PlotService.ApplySpeed(player)
	end)
	Net.Handle("GoHome", goHome)
	task.spawn(function()
		while true do
			local ok, err = pcall(incomeLoop)
			warn("[TideRush] boucle de revenus relancee : " .. tostring(ok and "fin" or err))
			task.wait(1)
		end
	end)
end

return PlotService
