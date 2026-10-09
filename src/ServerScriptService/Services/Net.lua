-- Net : remotes du jeu, limite de frequence, notifications, etat de la vague.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local Net = {}

local RATE_CAPACITY = 8 -- appels d'affilee possibles, par remote et par joueur
local RATE_REFILL = 4 -- appels rendus par seconde

local buckets = {} -- [player][remoteName] = { tokens, t }
local handlers = {} -- [remoteName] = fonction branchee (pour le selftest)
local currentWave = nil

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
	local remote = Remotes:WaitForChild(name)
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

function Net.SendState(player, state)
	Remotes.StateChanged:FireClient(player, state)
end

-- Vague : copie en attributs (pour un client qui arrive tard) puis envoi a tous
function Net.SetWave(wave)
	currentWave = wave
	local remote = Remotes.WaveState
	remote:SetAttribute("Phase", wave.phase)
	remote:SetAttribute("PhaseStart", wave.phaseStart)
	remote:SetAttribute("PhaseEnd", wave.phaseEnd)
	remote:SetAttribute("StartTime", wave.startTime)
	remote:SetAttribute("Cycle", wave.cycle)
	remote:FireAllClients(wave)
end

function Net.GetWave()
	return currentWave
end

function Net.SendWave(player)
	if currentWave then
		Remotes.WaveState:FireClient(player, currentWave)
	end
end

function Net.Forget(player)
	buckets[player] = nil
end

return Net
