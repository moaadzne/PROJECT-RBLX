-- tools/world/build_boss_arenas.lua
-- C : Arènes World Boss hebdo (Leviathan, Kraken, Hydre) — DECISIONS_MARCHE.md §9 Piliers 3.
-- 20 joueurs, mécaniques phases, enrage timers, positioning, coordination.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Configuration des World Boss (hebdo, 20 joueurs)
local BOSSES = {
	{
		id = "Leviathan",
		name = "Leviathan, l'Ancien Roi",
		arena = { center = Vector3.new(0, 0, 850), radius = 200 }, -- Ile_Abysses
		phases = 4,
		mechanics = {
			{ name = "TidalCrush", desc = "Zone circulaire qui se reduit, deplacement obligatoire" },
			{ name = "AbyssalTentacles", desc = "Tentacules spawn au hasard, il faut les tuer" },
			{ name = "TidalWave", desc = "Vague geante traverse l'arene, il faut se mettre a l'abri" },
			{ name = "Enrage", desc = "A 10% PV : vitesse x2, degats x2, enrage timer 3min" },
		},
		rewards = { "Cosmetique_Leviathan_Skin", "Materiel_Craft_Legendaire", "Titre_ChasseurLeviathan", "Monture_Leviathan_Juvenile" },
		weekly = true,
		respawnHours = 168, -- 1 semaine
	},
	{
		id = "Kraken",
		name = "Kraken des Profondeurs",
		arena = { center = Vector3.new(-600, 0, 600), radius = 180 }, -- Nord-Ouest
		phases = 3,
		mechanics = {
			{ name = "InkCloud", desc = "Nuage d'encre aveugle, il faut sortir de la zone" },
			{ name = "TentacleSlam", desc = "Tentacules frappent au sol, marqueurs au sol" },
			{ name = "Whirlpool", desc = "Tourbillon aspire les joueurs au centre" },
		},
		rewards = { "Cosmetique_Kraken_Ink", "Materiel_Craft_Epique", "Titre_TueurKraken" },
		weekly = true,
		respawnHours = 168,
	},
	{
		id = "HydraTide",
		name = "Hydre des Marees",
		arena = { center = Vector3.new(500, 0, -400), radius = 160 }, -- Nord-Est
		phases = 5,
		mechanics = {
			{ name = "HeadMultiply", desc = "Tetes se multiplient si pas tuees en meme temps" },
			{ name = "TidalBreath", desc = "Souffle de marée traverse l'arene en ligne" },
			{ name = "PoisonTide", desc = "Zone empoisonnee qui s'etend" },
			{ name = "Enrage", desc = "Derniere tete : vitesse x3, degats x3" },
		},
		rewards = { "Cosmetique_Hydra_Head", "Materiel_Craft_Legendaire", "Titre_TueurHydre", "Monture_Hydra_Juvenile" },
		weekly = true,
		respawnHours = 168,
	},
}

local function createBossArena(boss)
	log("  Arene " .. boss.id .. " @ " .. tostring(boss.arena.center) .. " r=" .. boss.arena.radius)
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "BossArena_" .. boss.id
	folder.Parent = Workspace

	-- Sol de l'arene (plateforme plate au niveau de la mer + 10)
	local platform = Instance.new("Part")
	platform.Name = "ArenaFloor"
	platform.Size = Vector3.new(boss.arena.radius * 2, 4, boss.arena.radius * 2)
	platform.CFrame = CFrame.new(boss.arena.center.X, 10, boss.arena.center.Z)
	platform.Anchored = true
	platform.Material = Enum.Material.Rock
	platform.Color = Color3.fromHex("2A2A2A")
	platform.Parent = folder

	-- Bordure lumineuse (zone de combat)
	for i = 1, 32 do
		local angle = (i - 1) * (2 * math.pi / 32)
		local marker = Instance.new("Part")
		marker.Name = "ArenaMarker_" .. i
		marker.Size = Vector3.new(4, 8, 4)
		marker.CFrame = CFrame.new(
			boss.arena.center.X + math.cos(angle) * boss.arena.radius,
			14,
			boss.arena.center.Z + math.sin(angle) * boss.arena.radius
		) * CFrame.Angles(0, angle, 0)
		marker.Material = Enum.Material.Neon
		marker.Color = Color3.fromHex("FF6B35")
		marker.Anchored = true
		marker.CanCollide = false
		marker.Parent = folder
	end

	-- Attributs pour le serveur (BossService)
	folder:SetAttribute("BossId", boss.id)
	folder:SetAttribute("BossName", boss.name)
	folder:SetAttribute("Phases", boss.phases)
	folder:SetAttribute("MaxPlayers", 20)
	folder:SetAttribute("Weekly", boss.weekly)
	folder:SetAttribute("RespawnHours", boss.respawnHours)
	folder:SetAttribute("ArenaRadius", boss.arena.radius)

	-- Spawn point boss (au centre, legerement en hauteur)
	local spawn = Instance.new("Part")
	spawn.Name = "BossSpawn"
	spawn.Size = Vector3.new(1, 1, 1)
	spawn.Transparency = 1
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.CFrame = CFrame.new(boss.arena.center.X, 20, boss.arena.center.Z)
	spawn.Parent = folder

	-- Zone de sécurité (entree/sortie)
	local safeZone = Instance.new("Part")
	safeZone.Name = "SafeZone"
	safeZone.Size = Vector3.new(30, 20, 30)
	safeZone.CFrame = CFrame.new(boss.arena.center.X, 15, boss.arena.center.Z + boss.arena.radius + 20)
	safeZone.Transparency = 0.5
	safeZone.Material = Enum.Material.ForceField
	safeZone.Color = Color3.fromHex("00FF88")
	safeZone.Anchored = true
	safeZone.CanCollide = false
	safeZone.Parent = folder

	-- Mécaniques stockées pour le serveur
	local mechanicsFolder = Instance.new("Folder")
	mechanicsFolder.Name = "Mechanics"
	mechanicsFolder.Parent = folder
	for i, mech in ipairs(boss.mechanics) do
		local m = Instance.new("StringValue")
		m.Name = "Mechanic_" .. i
		m.Value = mech.name .. "|" .. mech.desc
		m.Parent = mechanicsFolder
	end

	-- Récompenses
	local rewardsFolder = Instance.new("Folder")
	rewardsFolder.Name = "Rewards"
	rewardsFolder.Parent = folder
	for _, rew in ipairs(boss.rewards) do
		local r = Instance.new("StringValue")
		r.Name = rew
		r.Value = rew
		r.Parent = rewardsFolder
	end
end

local function run()
	log("=== WORLD BOSS ARENAS (3 boss hebdo, 20 joueurs) ===")
	for _, b in BOSSES do
		log("  " .. b.id .. " : " .. b.name .. " @ " .. tostring(b.arena.center) .. " r=" .. b.arena.radius .. " phases=" .. b.phases)
	end

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : World Boss Arenas (Leviathan, Kraken, Hydra)")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		for _, b in BOSSES do
			createBossArena(b)
		end
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("3 World Boss Arenas creees. Pret pour BossService (Phases, Enrage, Rewards).")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()