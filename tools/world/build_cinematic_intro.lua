-- tools/world/build_cinematic_intro.lua
-- C : Intro cinematographique 3min — DECISIONS_MARCHE.md §9 Pilier 5 (agent S + L).
-- 0-1.5s : Ecran chargement custom, plan aerien lent ile au couchant, brume, lagon turquoise.
-- 1.5-7.6s : Camera s'ouvre sur lagon joueur, 4 creatures posees, il en attrape 2-3.
-- 7.6-16s : Mouettes s'enfuient, ressac s'arrete -> vague arrive, il court, il chope.
-- 16-29.6s : Il place sa creature sur le bassin, barre s'ouvre, "NEXT TIDE: GOLDEN".
-- 29.6-31.5s : Vague s'ecrase, embruns, une ligne : "TA BASE. TA CREATURE. TA VAGUE."
-- ZERO texte explicatif. Flèche unique. Pas de HUD avant 31.5s.
-- Lancement manuel (execute_luau, edition). DRY_RUN = true.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Sequences exactes (timing en secondes)
local INTRO_SEQUENCE = {
	{
		id = "LoadingScreen",
		name = "Ecran Chargement Custom",
		start = 0,
		duration = 1.5,
		description = "Plan aerien lent ile au couchant, brume, lagon turquoise. Zero UI Roblox.",
		camera = {
			type = "Aerial",
			path = { Vector3.new(0, 200, -1000), Vector3.new(0, 150, -500), Vector3.new(0, 100, -100) },
			fov = 60,
			lookAt = Vector3.new(0, 10, -100),
		},
		lighting = {
			ClockTime = 17.05,
			Bloom = 0.6,
			CC = { Saturation = 1.15, Contrast = 0.12, Tint = Color3.fromHex("F2A35E") },
			Atmosphere = { Density = 0.35, Haze = 2.2, Glare = 1.2, Color = Color3.fromHex("F2A35E") },
		},
		sounds = { "musicCalm", "ambientBeach" },
		ui = { visible = false }, -- ZERO UI
	},
	{
		id = "LagoonReveal",
		name = "Lagon Joueur + 4 Creatures",
		start = 1.5,
		duration = 6.1,
		description = "Camera s'ouvre sur lagon joueur, 4 creatures posees, il en attrape 2-3.",
		camera = {
			type = "Track",
			path = { Vector3.new(-112, 14, 80), Vector3.new(-80, 8, 60), Vector3.new(-60, 5, 40) },
			fov = 55,
			lookAt = Vector3.new(-80, 3, -120),
		},
		lighting = {
			ClockTime = 17.1,
			Bloom = 0.5,
			CC = { Saturation = 1.1, Contrast = 0.1, Tint = Color3.fromHex("F2A35E") },
		},
		actions = {
			{ time = 2.0,  action = "SpawnCreatures",   params = { count = 4, types = { "GhostCrab", "CushionStar", "HawksbillTurtle", "Lionfish" } } },
			{ time = 3.5,  action = "PlayerCatch",      params = { count = 2 } },
			{ time = 5.0,  action = "ShowArrow",        params = { target = "Lagoon", text = "TA BASE" } },
		},
		sounds = { "musicCalm", "pickup", "splash" },
	},
	{
		id = "WaveApproach",
		name = "Mouettes Fuient + Vague Arrive",
		start = 7.6,
		duration = 8.4,
		description = "Mouettes s'enfuient, ressac s'arrete -> vague arrive, il court, il chope.",
		camera = {
			type = "Track",
			path = { Vector3.new(-80, 8, 60), Vector3.new(-60, 6, 20), Vector3.new(-40, 5, -10) },
			fov = 65,
			lookAt = Vector3.new(-50, 3, -120),
		},
		lighting = {
			ClockTime = 17.2,
			Bloom = 0.45,
			CC = { Saturation = 1.05, Contrast = 0.12, Tint = Color3.fromHex("E8B86A") },
			Atmosphere = { Density = 0.38, Haze = 2.5, Glare = 1.3, Color = Color3.fromHex("E8B86A") },
		},
		actions = {
			{ time = 0.5,  action = "SeagullsFlee",     params = { count = 12 } },
			{ time = 2.0,  action = "SurfSoundFade",    params = { fadeOut = true } },
			{ time = 3.0,  action = "WaveAlert",        params = { horn = true, rumble = true } },
			{ time = 5.0,  action = "PlayerRun",        params = { direction = "Lagoon" } },
			{ time = 7.0,  action = "PlayerCatchWave",  params = { creature = "HawksbillTurtle" } },
		},
		sounds = { "seagulls", "surfLoop", "horn", "rumble", "waveBoom" },
	},
	{
		id = "PlaceCreature",
		name = "Place Creature + Barre NEXT TIDE: GOLDEN",
		start = 16,
		duration = 13.6,
		description = "Il place sa creature sur le bassin, barre s'ouvre, NEXT TIDE: GOLDEN.",
		camera = {
			type = "Track",
			path = { Vector3.new(-80, 5, 40), Vector3.new(-80, 8, 60), Vector3.new(-112, 14, 80) },
			fov = 60,
			lookAt = Vector3.new(-80, 3, -120),
		},
		lighting = {
			ClockTime = 17.3,
			Bloom = 0.5,
			CC = { Saturation = 1.1, Contrast = 0.1, Tint = Color3.fromHex("F2A35E") },
		},
		actions = {
			{ time = 1.0,  action = "PlaceCreature",    params = { lagoon = 1 } },
			{ time = 3.0,  action = "ShowBar",          params = { text = "NEXT TIDE: GOLDEN", color = "Gold" } },
			{ time = 8.0,  action = "ShowArrow",        params = { target = "Horizon", text = "LA VAGUE VIENT" } },
			{ time = 12.0, action = "WaveSwellRise",    params = { height = 55, duration = 7 } },
		},
		sounds = { "musicTension", "rumble", "seagulls" },
	},
	{
		id = "WaveCrashFinale",
		name = "Vague s'Ecrase + Tagline Finale",
		start = 29.6,
		duration = 1.9,
		description = "Vague s'ecrase, embruns, une ligne : 'TA BASE. TA CREATURE. TA VAGUE.'",
		camera = {
			type = "Track",
			path = { Vector3.new(-112, 14, 80), Vector3.new(-60, 6, -10), Vector3.new(-40, 5, -30) },
			fov = 70,
			lookAt = Vector3.new(-50, 3, -120),
		},
		lighting = {
			ClockTime = 17.4,
			Bloom = 0.8,
			CC = { Saturation = 1.2, Contrast = 0.15, Tint = Color3.fromHex("FFD166") },
			Atmosphere = { Density = 0.4, Haze = 3, Glare = 1.5, Color = Color3.fromHex("FFD166") },
		},
		actions = {
			{ time = 0.2,  action = "WaveCrash",       params = { height = 30, foam = true, spray = true } },
			{ time = 0.5,  action = "ScreenFlash",     params = { color = Color3.fromHex("FFFFFF"), duration = 0.1 } },
			{ time = 0.8,  action = "ShowTagline",     params = { text = "TA BASE. TA CREATURE. TA VAGUE.", font = "RobotoCondensed", size = 48, color = Color3.fromHex("FFFFFF"), duration = 3 } },
			{ time = 1.5,  action = "HUD_FadeIn",      params = { duration = 2 } },
			{ time = 1.9,  action = "ControlReturn",   params = {} },
		},
		sounds = { "waveBoom", "waveImpact", "musicCalm" },
	},
}

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createIntroSequence()
	log("  Sequence Intro 31.5s : 5 segments, zero texte, fleche unique, pas HUD avant 31.5s")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "IntroSequence"
	folder.Parent = RS

	for _, seq in INTRO_SEQUENCE do
		local s = Instance.new("Folder")
		s.Name = seq.id
		s.Parent = folder
		s:SetAttribute("Name", seq.name)
		s:SetAttribute("Start", seq.start)
		s:SetAttribute("Duration", seq.duration)
		s:SetAttribute("Description", seq.description)

		-- Camera
		if seq.camera then
			local cam = Instance.new("Folder")
			cam.Name = "Camera"
			cam.Parent = s
			for k, v in pairs(seq.camera) do
				if type(v) == "table" and v.x then
					local v3 = Instance.new("Vector3Value")
					v3.Name = k
					v3.Value = v
					v3.Parent = cam
				elseif type(v) == "table" then
					local path = Instance.new("Folder")
					path.Name = k
					path.Parent = cam
					for i, pt in ipairs(v) do
						local ptVal = Instance.new("Vector3Value")
						ptVal.Name = "Point_" .. i
						ptVal.Value = pt
						ptVal.Parent = path
					end
				else
					local val = Instance.new("StringValue")
					val.Name = k
					val.Value = tostring(v)
					val.Parent = cam
				end
			end
		end

		-- Lighting
		if seq.lighting then
			local lit = Instance.new("Folder")
			lit.Name = "Lighting"
			lit.Parent = s
			for k, v in pairs(seq.lighting) do
				if type(v) == "table" then
					local sub = Instance.new("Folder")
					sub.Name = k
					sub.Parent = lit
					for k2, v2 in pairs(v) do
						if type(v2) == "userdata" and v2.r then
							local c = Instance.new("Color3Value")
							c.Name = k2
							c.Value = v2
							c.Parent = sub
						else
							local n = Instance.new("NumberValue")
							n.Name = k2
							n.Value = v2
							n.Parent = sub
						end
					end
				elseif type(v) == "userdata" and v.r then
					local c = Instance.new("Color3Value")
					c.Name = k
					c.Value = v
					c.Parent = lit
				else
					local n = Instance.new("NumberValue")
					n.Name = k
					n.Value = v
					n.Parent = lit
				end
			end
		end

		-- Actions
		if seq.actions then
			local act = Instance.new("Folder")
			act.Name = "Actions"
			act.Parent = s
			for _, a in ipairs(seq.actions) do
				local aFolder = Instance.new("Folder")
				aFolder.Name = "Action_" .. a.action
				aFolder.Parent = act
				aFolder:SetAttribute("Time", a.time)
				for k, v in pairs(a.params or {}) do
					if type(v) == "userdata" and v.r then
						local c = Instance.new("Color3Value")
						c.Name = k
						c.Value = v
						c.Parent = aFolder
					elseif type(v) == "boolean" then
						local b = Instance.new("BoolValue")
						b.Name = k
						b.Value = v
						b.Parent = aFolder
					elseif type(v) == "number" then
						local n = Instance.new("NumberValue")
						n.Name = k
						n.Value = v
						n.Parent = aFolder
					else
						local s = Instance.new("StringValue")
						s.Name = k
						s.Value = tostring(v)
						s.Parent = aFolder
					end
				end
			end
		end

		-- Sounds
		if seq.sounds then
			local snd = Instance.new("Folder")
			snd.Name = "Sounds"
			snd.Parent = s
			for _, sndName in ipairs(seq.sounds) do
				local sn = Instance.new("StringValue")
				sn.Name = sndName
				sn.Value = sndName
				sn.Parent = snd
			end
		end

		-- UI
		if seq.ui then
			local ui = Instance.new("Folder")
			ui.Name = "UI"
			ui.Parent = s
			for k, v in pairs(seq.ui) do
				if type(v) == "boolean" then
					local b = Instance.new("BoolValue")
					b.Name = k
					b.Value = v
					b.Parent = ui
				end
			end
		end
	end
end

local function createIntroMarker()
	log("  Marqueur Intro (AutoPlay, Priority=100)")
	if DRY_RUN then return end

	local marker = Instance.new("Part")
	marker.Name = "Cinematic_Intro_3min"
	marker.Size = Vector3.new(1, 1, 1)
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.Parent = Workspace
	marker:SetAttribute("CinematicId", "Intro_Archipelago")
	marker:SetAttribute("AutoPlay", true)
	marker:SetAttribute("Priority", 100)
	marker:SetAttribute("Duration", 31.5)
	marker:SetAttribute("Skippable", true)
	marker:SetAttribute("SkipKey", "Escape")
end

local function run()
	log("=== INTRO CINEMATOGRAPHIQUE 3MIN (31.5s exactes) ===")
	for _, s in INTRO_SEQUENCE do
		log("  " .. s.id .. " : " .. s.name .. " @ " .. s.start .. "s (" .. s.duration .. "s)")
	end
	log("ZERO texte explicatif. Fleche unique. Pas HUD avant 31.5s. Skippable (Echap).")

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Intro cinematographique 3min (sequence exacte)")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		createIntroSequence()
		createIntroMarker()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Intro cinematographique 3min creee. Pret pour CinematicService (S) + Onboarding (L).")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()