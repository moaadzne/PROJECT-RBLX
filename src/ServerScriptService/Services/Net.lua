-- Net : remotes du jeu, limite de frequence, notifications, etat de la vague (global ou propre a un joueur).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remotes du contrat v2 : crees au demarrage s'ils manquent dans Studio
local REMOTES = {
	GetState = "RemoteFunction",
	BuyUpgrade = "RemoteFunction",
	GoHome = "RemoteFunction",
	HatchEgg = "RemoteFunction",
	EquipPet = "RemoteFunction",
	LockLagoon = "RemoteFunction",
	StartSteal = "RemoteFunction",
	Mount = "RemoteFunction",
	ChoosePick = "RemoteFunction",
	StateChanged = "RemoteEvent",
	RoyalBoard = "RemoteEvent",
	WaveState = "RemoteEvent",
	Notify = "RemoteEvent",
}

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end
for name, className in pairs(REMOTES) do
	local existing = Remotes:FindFirstChild(name)
	if existing and not existing:IsA(className) then
		warn(("[TideRush] Remotes.%s n'est pas un %s : remplace"):format(name, className))
		existing:Destroy()
		existing = nil
	end
	if not existing then
		local remote = Instance.new(className)
		remote.Name = name
		remote.Parent = Remotes
	end
end

local Net = {}

local RATE_CAPACITY = 8 -- appels d'affilee possibles, par remote et par joueur
local RATE_REFILL = 4 -- appels rendus par seconde

local buckets = {} -- [player][remoteName] = { tokens, t }
local handlers = {} -- [remoteName] = fonction branchee (pour le selftest)
local currentWave = nil
local personal = {} -- [player] = { wave = table? (vague propre), tide = string? (maree propre sur la vague globale) }

local function allow(player, name)
	if not player.Parent then
		return false -- deja parti : ne pas recreer de seau apres Net.Forget (fuite du Player)
	end
	local now = os.clock()
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local bucket = perPlayer[name]
	if not bucket then
		bucket = { tokens = RATE_CAPACITY, t = now }
		perPlayer[name] = bucket
	end
	bucket.tokens = math.min(RATE_CAPACITY, bucket.tokens + (now - bucket.t) * RATE_REFILL)
	bucket.t = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

-- Branche une RemoteFunction. Le handler renvoie (true, ...) ou (false, code).
-- onReject(player) remplace (false, code) quand le contrat impose une autre forme (GetState).
function Net.Handle(name, handler, onReject)
	local remote = Remotes[name]
	local function invoke(player, ...)
		if not allow(player, name) then
			if onReject then
				return onReject(player)
			end
			return false, "RateLimited"
		end
		local results = table.pack(pcall(handler, player, ...))
		if not results[1] then
			warn(("[TideRush] %s a plante pour %s : %s"):format(name, player.Name, tostring(results[2])))
			if onReject then
				return onReject(player)
			end
			return false, "ServerError"
		end
		return table.unpack(results, 2, results.n)
	end
	handlers[name] = invoke
	remote.OnServerInvoke = invoke
end

function Net.IsHandled(name)
	return handlers[name] ~= nil
end

-- Selftest : appelle un remote exactement comme un client (limite de frequence comprise)
function Net.Invoke(name, player, ...)
	local invoke = handlers[name]
	if not invoke then
		return false, "NoHandler"
	end
	return invoke(player, ...)
end

function Net.Notify(player, kind, data)
	Remotes.Notify:FireClient(player, kind, data)
end

function Net.NotifyAll(kind, data, except)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= except then
			Remotes.Notify:FireClient(player, kind, data)
		end
	end
end

function Net.FireAll(name, ...)
	Remotes[name]:FireAllClients(...)
end

function Net.SendState(player, state)
	Remotes.StateChanged:FireClient(player, state)
end

-- La vague telle que ce joueur la vit : intro propre, maree propre, ou vague globale
function Net.GetWaveFor(player)
	local own = personal[player]
	if own and own.wave then
		return own.wave
	end
	if own and own.tide and currentWave then
		local wave = table.clone(currentWave)
		wave.tide = own.tide
		return wave
	end
	return currentWave
end

function Net.SendWave(player)
	local wave = Net.GetWaveFor(player)
	if wave then
		Remotes.WaveState:FireClient(player, wave)
	end
end

-- Vague globale : copie en attributs (pour un client qui arrive tard) puis envoi a chacun sa version
function Net.SetWave(wave)
	currentWave = wave
	local remote = Remotes.WaveState
	remote:SetAttribute("Phase", wave.phase)
	remote:SetAttribute("PhaseStart", wave.phaseStart)
	remote:SetAttribute("PhaseEnd", wave.phaseEnd)
	remote:SetAttribute("StartTime", wave.startTime)
	remote:SetAttribute("Cycle", wave.cycle)
	remote:SetAttribute("Tide", wave.tide)
	for _, player in ipairs(Players:GetPlayers()) do
		local own = personal[player]
		if not (own and own.wave) then
			Net.SendWave(player)
		end
	end
end

function Net.GetWave()
	return currentWave
end

-- Vague propre a un joueur (intro) ; nil = il revient sur la vague globale
function Net.SetPersonalWave(player, wave)
	if not player.Parent then
		return
	end
	local own = personal[player] or {}
	own.wave = wave
	personal[player] = own
	Net.SendWave(player)
end

-- Maree propre a un joueur sur la vague globale (Golden de l'intro) ; nil = maree globale
function Net.SetPersonalTide(player, tide)
	if not player.Parent then
		return
	end
	local own = personal[player] or {}
	own.tide = tide
	personal[player] = own
	Net.SendWave(player)
end

function Net.Forget(player)
	buckets[player] = nil
	personal[player] = nil
end

return Net
