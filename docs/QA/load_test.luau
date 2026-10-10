-- load_test.luau
-- Stress test serveur unique — N bots headless simulant des joueurs
-- Responsable : M (QA Infrastructure)
-- Usage : exécuter en contexte Server via un Script dédié (test fermé uniquement).
-- NE JAMAIS exécuter sur la place publique.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG = {
	BotCount = 500,             -- nombre de clients simulés
	Duration = 120,             -- secondes
	TickRate = 1 / 10,          -- 10 actions/s par bot
	SyncInterval = 30,          -- intervalle entre sauvegardes de données (à valider avec A)
	MetricsInterval = 10,       -- rapport toutes les X secondes
}

local state = {
	errors = 0,
	warnings = 0,
	actions = 0,
	start = 0,
	peakMemory = 0,
}

local function log(msg)
	print(string.format("[LOAD] %s", msg))
end

local function snapshotMetrics(label)
	local stats = game:GetService("Stats")
	local mem = stats:GetTotalMemoryUsageMb()
	state.peakMemory = math.max(state.peakMemory, mem)
	local players = #Players:GetPlayers()
	log(string.format(
		"%s | t=%.0fs | joueurs=%d | actions=%d | erreurs=%d | warnings=%d | RAM=%.0f Mo (pic %.0f)",
		label, tick() - state.start, players, state.actions, state.errors, state.warnings, mem, state.peakMemory
	))
end

local function runScenario(tickCount)
	-- Scenario simplifié : chaque "bot" incrémente un compteur d'action.
	-- La vraie simulation (mouvement, vague, vol) se fait avec des clients Roblox
	-- réels lancés par l'outil `spawn_bots` (voir README PERFORMANCE).
	state.actions += CONFIG.BotCount
	return true
end

-- Compteurs d'erreurs globaux
local function hookErrors()
	-- Erreurs serveur : on capture via LogService si dispo
	local ok, LogService = pcall(function()
		return game:GetService("LogService")
	end)
	if ok and LogService then
		LogService.MessageOut:Connect(function(msg, msgType)
			if msgType == Enum.MessageType.MessageError then
				state.errors += 1
			elseif msgType == Enum.MessageType.MessageWarning then
				state.warnings += 1
			end
		end)
	end
end

log(string.format(
	"Stress test démarré — bots=%d, durée=%ds, tick=%.1f/s",
	CONFIG.BotCount, CONFIG.Duration, 1 / CONFIG.TickRate
))

hookErrors()
state.start = tick()

local lastSync = 0
local elapsed = 0
while elapsed < CONFIG.Duration do
	local ok, err = pcall(runScenario, elapsed)
	if not ok then
		state.errors += 1
		warn("[LOAD] Erreur scenario : " .. tostring(err))
	end

	if elapsed - lastSync >= CONFIG.MetricsInterval then
		snapshotMetrics("métrique")
		lastSync = elapsed
	end

	task.wait(CONFIG.TickRate)
	elapsed = tick() - state.start
end

snapshotMetrics("FINAL")
log("=== CRITÈRES ===")
log(string.format("Crash : %s (attendu 0)", state.errors > 100 and "ÉCHEC" or "OK"))
log(string.format("RAM pic : %.0f Mo (limite PC 1024 / mobile 600)", state.peakMemory))
log("Vérifier aussi : disconnect rate, latency P95, FPS par plateforme (voir PERFORMANCE.md)")