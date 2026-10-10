-- RateLimiter : anti-spam remote adaptatif par joueur, reconnexion seamless.
-- Cycle 1 — Core Stability.
-- Principe : seau a jetons + score de comportement. Plus un joueur spamme,
-- plus son seau se vide vite et plus la recharge ralentit.
-- Un joueur calme regagne vite sa capacite ; un bot est bloque en < 10 s.

local Players = game:GetService("Players")

local RateLimiter = {}

-- Constantes adaptatives
local BASE_CAPACITY = 12 -- appels d'affilee max (joueur calme)
local BASE_REFILL = 6 -- appels rendus par seconde (joueur calme)
local PENALTY_REFILL_MULT = 0.5 -- multiplicateur de recharge en cas de spam
local PENALTY_CAPACITY_MULT = 0.5 -- multiplicateur de capacite en cas de spam
local MAX_PENALTY = 4 -- multiplicateur de penalite max (x4 plus lent)
local DECAY_RATE = 0.95 -- decroissance du score de penalite par seconde
local BLOCK_THRESHOLD = 8 -- score de penalite depuis lequel on bloque
local BLOCK_DURATION = 10 -- secondes de blocage
local RECONNECT_GRACE = 30 -- secondes de grace apres reconnexion

local state = {} -- [player] = { tokens, refill, penalty, blocked, lastSeen, reconnectAt }

local function getNow()
	return os.clock()
end

local function getState(player)
	local s = state[player]
	if not s then
		s = {
			tokens = BASE_CAPACITY,
			refill = BASE_REFILL,
			penalty = 1.0,
			blocked = false,
			lastSeen = getNow(),
			reconnectAt = 0,
		}
		state[player] = s
	end
	return s
end

-- Penalite adaptatif : plus le joueur spam, plus la recharge est lente
local function effectiveRefill(s)
	return BASE_REFILL / math.max(1, s.penalty)
end

local function effectiveCapacity(s)
	return math.max(1, math.floor(BASE_CAPACITY / math.max(1, s.penalty)))
end

-- Appel autorisé ? Renvoie true/false + raison
function RateLimiter.Allow(player, remoteName)
	local now = getNow()
	local s = getState(player)

	-- Si le joueur n'est plus la, nettoyer
	if not player.Parent then
		state[player] = nil
		return false, "Left"
	end

	-- Reconnexion seamless : grace de 30 s
	if s.reconnectAt > 0 and now < s.reconnectAt then
		return true, "Grace"
	end

	-- Periode de blocage active
	if s.blocked then
		if now >= s.blockedUntil then
			s.blocked = false
			s.penalty = 1.0
		else
			return false, "Blocked"
		end
	end

	-- Recharge adaptative
	local dt = now - s.lastSeen
	s.tokens = math.min(effectiveCapacity(s), s.tokens + dt * effectiveRefill(s))
	s.lastSeen = now

	-- Decroissance naturelle de la penalite
	s.penalty = math.max(1.0, s.penalty - DECAY_RATE * dt)

	if s.tokens >= 1 then
		s.tokens -= 1
		return true, "OK"
	else
		-- Spam detecte : augmenter la penalite
		s.penalty = math.min(MAX_PENALTY, s.penalty + 0.5)
		if s.penalty >= BLOCK_THRESHOLD then
			s.blocked = true
			s.blockedUntil = now + BLOCK_DURATION
			return false, "Blocked"
		end
		return false, "RateLimited"
	end
end

-- Appel force (admin, selftest) : ne compte pas dans le rate limiting
function RateLimiter.AllowForced(player)
	return true, "Forced"
end

-- Reconnexion : donne un bonus de grace au joueur
function RateLimiter.OnReconnect(player)
	local s = getState(player)
	s.reconnectAt = getNow() + RECONNECT_GRACE
	s.penalty = 1.0 -- reset penalite
end

-- Le joueur vient de partir : nettoyer
function RateLimiter.Forget(player)
	state[player] = nil
end

-- Stats pour debug/monitoring
function RateLimiter.Debug(player)
	local s = getState(player)
	return {
		tokens = s.tokens,
		refill = effectiveRefill(s),
		capacity = effectiveCapacity(s),
		penalty = s.penalty,
		blocked = s.blocked,
	}
end

-- Nettoyer les joueurs partis
local function cleanup()
	for player in pairs(state) do
		if not player.Parent then
			state[player] = nil
		end
	end
end

-- Nettoyage periodique
task.spawn(function()
	while true do
		task.wait(60)
		cleanup()
	end
end)

return RateLimiter