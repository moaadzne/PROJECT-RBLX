-- tools/world/build_cinematic_camera.lua
-- C : Moteur cinématographique — DECISIONS_MARCHE.md §9 Pilier 5 (agent S).
-- Camera scriptee, dialogue, choix, camera joueur verrouillee, replay system.
-- Intro 3min, Chapitre cuts 2-3min, Boss intros 30s, Evenements mondiaux synchro, Replay (camera libre, export).
-- Lancement manuel (execute_luau, edition). DRY_RUN = true.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Cinematiques definies (agent S les scriptera completement)
local CINEMATICS = {
	{
		id = "Intro_Archipelago",
		name = "Intro : Arrivee sur l'Archipel",
		duration = 180, -- 3 min
		trigger = "OnJoin",
		skippable = true,
		chapters = {
			{ time = 0,   camera = "Aerial_Approach",   desc = "Vue aerienne lente, brume, couchant, lagon turquoise" },
			{ time = 30,  camera = "Wave_Crash",        desc = "Vague arrive, joueur court, attrape creature" },
			{ time = 60,  camera = "Lagoon_Place",      desc = "Pose creature, barre s'ouvre, NEXT TIDE: GOLDEN" },
			{ time = 120, camera = "Leviathan_Awaken",  desc = "L'ancien roi s'eveille au loin, rugissement" },
			{ time = 180, camera = "Player_Control",    desc = "Controle rendu, flèche unique 'Va la'" },
		},
	},
	{
		id = "Chapter_1_Coral",
		name = "Chapitre 1 : Le Coeur de Corail",
		duration = 150,
		trigger = "Quest_Complete_CoralHeart",
		chapters = {
			{ time = 0,   camera = "CoralReef_Reveal", desc = "Recif s'illumine, creature legendaire apparait" },
			{ time = 60,  camera = "Choice_Present",   desc = "Choix : Proteger / Etudier / Exploiter" },
			{ time = 120, camera = "Consequence_Show", desc = "Resultat du choix visible dans le monde" },
		},
	},
	{
		id = "Boss_Leviathan_Intro",
		name = "Boss Intro : Leviathan",
		duration = 30,
		trigger = "Boss_Spawn_Leviathan",
		chapters = {
			{ time = 0,  camera = "Leviathan_Rise",  desc = "Eau bouillonne, Leviathan sort des profondeurs" },
			{ time = 15, camera = "Eye_Contact",    desc = "Oeil geant fixe le joueur, rugissement" },
			{ time = 30, camera = "Combat_Start",   desc = "Combat commence, musique epic" },
		},
	},
	{
		id = "WorldEvent_BlackTide",
		name = "Evenement Mondial : Maree Noire",
		duration = 60,
		trigger = "WorldEvent_BlackTide_Start",
		synced = true, -- tous les joueurs la voient en meme temps
		chapters = {
			{ time = 0,  camera = "Sky_Darkens",     desc = "Ciel s'assombrit, mer recule anormalement" },
			{ time = 20, camera = "Leviathan_Roar",  desc = "Rugissement planétaire, vague geante" },
			{ time = 40, camera = "Call_To_Arms",    desc = "Message serveur : 'L'Eveil commence. Rejoignez l'arene.'" },
			{ time = 60, camera = "Player_Control",  desc = "Controle rendu, marqueur arene Leviathan" },
		},
	},
	{
		id = "Chapter_2_Abysses",
		name = "Chapitre 2 : Les Abysses",
		duration = 180,
		trigger = "Quest_Complete_AbyssalGate",
		chapters = {
			{ time = 0,   camera = "Abyssal_Gate_Open", desc = "Porte abyssale s'ouvre, lumiere bizarre" },
			{ time = 90,  camera = "Deep_Choice",       desc = "Choix moral : Sacrifier / Sauver / Sceller" },
			{ time = 180, camera = "World_Change",      desc = "Monde change visiblement selon choix" },
		},
	},
}

-- Replay System
local REPLAY_CONFIG = {
	maxDuration = 300, -- 5 min max
	recordInterval = 0.1, -- 10Hz
	exportFormat = "JSON", -- camera path + timestamps + events
	cameraFree = true,
	exportVideo = false, -- Roblox n'exporte pas video nativement, mais on exporte le path
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createCinematicSystem()
	log("  Moteur cinematographique + Replay system")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "CinematicSystem"
	folder.Parent = RS

	-- Cinematiques
	local cinFolder = Instance.new("Folder")
	cinFolder.Name = "Cinematics"
	cinFolder.Parent = folder

	for _, cin in CINEMATICS do
		local c = Instance.new("Folder")
		c.Name = cin.id
		c.Parent = cinFolder
		c:SetAttribute("Name", cin.name)
		c:SetAttribute("Duration", cin.duration)
		c:SetAttribute("Trigger", cin.trigger)
		c:SetAttribute("Skippable", cin.skippable or false)
		c:SetAttribute("Synced", cin.synced or false)

		for i, ch in ipairs(cin.chapters) do
			local chFolder = Instance.new("Folder")
			chFolder.Name = "Chapter_" .. i
			chFolder.Parent = c
			chFolder:SetAttribute("Time", ch.time)
			chFolder:SetAttribute("Camera", ch.camera)
			chFolder:SetAttribute("Description", ch.desc)
		end
	end

	-- Replay System
	local replay = Instance.new("Folder")
	replay.Name = "ReplaySystem"
	replay.Parent = folder
	replay:SetAttribute("MaxDuration", REPLAY_CONFIG.maxDuration)
	replay:SetAttribute("RecordInterval", REPLAY_CONFIG.recordInterval)
	replay:SetAttribute("ExportFormat", REPLAY_CONFIG.exportFormat)
	replay:SetAttribute("CameraFree", REPLAY_CONFIG.cameraFree)

	-- Camera Paths (pour replay)
	local paths = Instance.new("Folder")
	paths.Name = "CameraPaths"
	paths.Parent = replay
	paths:SetAttribute("ExportFormat", "JSON")

	-- Dialogue System (pour choix)
	local dialogue = Instance.new("Folder")
	dialogue.Name = "DialogueSystem"
	dialogue.Parent = folder
	dialogue:SetAttribute("ChoiceLockTime", 10) -- secondes pour choisir
	dialogue:SetAttribute("ConsequenceDelay", 5) -- delai avant consequence visible
end

local function createIntroCinematic()
	log("  Intro 3min : Aerial -> Wave -> Lagoon -> Leviathan -> Control")
	if DRY_RUN then return end

	-- L'intro est definie dans CINEMATICS[1] (Intro_Archipelago)
	-- Ce script cree juste le marqueur pour le client
	local marker = Instance.new("Part")
	marker.Name = "Cinematic_Intro_Marker"
	marker.Size = Vector3.new(1, 1, 1)
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = Workspace
	marker:SetAttribute("CinematicId", "Intro_Archipelago")
	marker:SetAttribute("AutoPlay", true)
	marker:SetAttribute("Priority", 100)
end

local function run()
	log("=== MOTEUR CINEMATOGRAPHIQUE + REPLAY + INTRO 3MIN ===")
	for _, c in CINEMATICS do
		log("  " .. c.id .. " : " .. c.name .. " (" .. c.duration .. "s, " .. #c.chapters .. " chapitres)")
	end
	log("Replay : " .. REPLAY_CONFIG.maxDuration .. "s max, " .. (1/REPLAY_CONFIG.recordInterval) .. "Hz, export " .. REPLAY_CONFIG.exportFormat)

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Moteur cinematographique + Replay + Intro")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		createCinematicSystem()
		createIntroCinematic()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Moteur cinematographique + Replay + Intro crees. Pret pour CinematicService (S).")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()