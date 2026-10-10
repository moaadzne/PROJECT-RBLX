-- tools/world/build_weather_events.lua
-- C : Météo dynamique + Evenements mondiaux — DECISIONS_MARCHE.md §9 (agents T, S).
-- Types : Clear, Fog, Storm, BlackTide, LeviathanWake.
-- Cycle 30min, transition 5min. Synchro serveur -> clients.
-- Effets : Lighting, Atmosphere, Particules, Sons, Vague modifiee.
-- Lancement manuel (execute_luau, edition). DRY_RUN = true.

local DRY_RUN = true
local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Types de météo (cycle 30min, transition 5min)
local WEATHER_TYPES = {
	{
		id = "Clear",
		name = "Ciel Degage",
		weight = 40,
		duration = { 10, 20 }, -- minutes
		lighting = {
			ClockTime = 14,
			Brightness = 2,
			Atmosphere = { Density = 0.15, Haze = 1.5, Glare = 0.5, Color = Color3.fromHex("F2A35E"), Decay = Color3.fromHex("13707A") },
			Bloom = { Intensity = 0.3, Threshold = 1.5 },
			CC = { Saturation = 1.1, Contrast = 0.1, Tint = Color3.fromHex("F2A35E") },
		},
		sounds = { "ambientBeach", "seagulls" },
		particles = {},
		waveModifier = 1.0,
	},
	{
		id = "Fog",
		name = "Brouillard Matinal",
		weight = 20,
		duration = { 5, 15 },
		lighting = {
			ClockTime = 6.5,
			Brightness = 1,
			Atmosphere = { Density = 0.5, Haze = 3, Glare = 0.2, Color = Color3.fromHex("A0A8B8"), Decay = Color3.fromHex("8899AA") },
			Bloom = { Intensity = 0.1, Threshold = 2 },
			CC = { Saturation = 0.6, Contrast = -0.1, Tint = Color3.fromHex("B0B8C8") },
		},
		sounds = { "ambientFog" },
		particles = { "FogDrift" },
		waveModifier = 0.8,
	},
	{
		id = "Storm",
		name = "Tempete Tropicale",
		weight = 15,
		duration = { 8, 20 },
		lighting = {
			ClockTime = 18,
			Brightness = 0.5,
			Atmosphere = { Density = 0.4, Haze = 2.5, Glare = 0.1, Color = Color3.fromHex("4A4A5A"), Decay = Color3.fromHex("2A2A3A") },
			Bloom = { Intensity = 0.2, Threshold = 1.8 },
			CC = { Saturation = 0.5, Contrast = 0.2, Tint = Color3.fromHex("5A5A6A") },
		},
		sounds = { "stormWind", "stormRain", "thunder" },
		particles = { "RainHeavy", "StormMist", "Lightning" },
		waveModifier = 1.5,
	},
	{
		id = "BlackTide",
		name = "Maree Noire (Evenement Mondial)",
		weight = 2, -- tres rare, declenche par evenement
		duration = { 25, 25 }, -- fixe 25 min (revealTime)
		triggered = true, -- pas aleatoire, declenche par ExtremeTide
		lighting = {
			ClockTime = 20,
			Brightness = 0.2,
			Atmosphere = { Density = 0.6, Haze = 4, Glare = 0, Color = Color3.fromHex("0A0A1A"), Decay = Color3.fromHex("050510") },
			Bloom = { Intensity = 0.5, Threshold = 1.2 },
			CC = { Saturation = 0.2, Contrast = 0.3, Tint = Color3.fromHex("1A0A0A") },
		},
		sounds = { "blackTideRumble", "leviathanRoar", "abyssalWhisper" },
		particles = { "BlackTideMist", "AbyssalParticles", "LeviathanWake" },
		waveModifier = 2.0, -- vague double hauteur
	},
	{
		id = "LeviathanWake",
		name = "Sillage du Leviathan (Post-BlackTide)",
		weight = 3,
		duration = { 30, 60 },
		lighting = {
			ClockTime = 19,
			Brightness = 0.8,
			Atmosphere = { Density = 0.35, Haze = 2, Glare = 0.3, Color = Color3.fromHex("1A1A2A"), Decay = Color3.fromHex("0D1A1A") },
			Bloom = { Intensity = 0.4, Threshold = 1.4 },
			CC = { Saturation = 0.8, Contrast = 0.15, Tint = Color3.fromHex("8A4A4A") },
		},
		sounds = { "leviathanEcho", "deepRumble", "calmAfterStorm" },
		particles = { "LeviathanTrail", "BlessedWater" },
		waveModifier = 1.2,
	},
}

-- Transitions (5 min par defaut)
local TRANSITION_MINUTES = 5

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function createWeatherSystem()
	log("  Systeme meteo : 5 types, cycle 30min, transition 5min, synchro serveur->clients")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "WeatherSystem"
	folder.Parent = RS

	-- Config cycle
	local config = Instance.new("Folder")
	config.Name = "Config"
	config.Parent = folder
	config:SetAttribute("CycleMinutes", 30)
	config:SetAttribute("TransitionMinutes", TRANSITION_MINUTES)
	config:SetAttribute("CurrentWeather", "Clear")
	config:SetAttribute("NextWeather", "")
	config:SetAttribute("TimeRemaining", 30 * 60)
	config:SetAttribute("IsTransitioning", false)

	-- Types de météo
	local typesFolder = Instance.new("Folder")
	typesFolder.Name = "WeatherTypes"
	typesFolder.Parent = folder

	for _, wt in WEATHER_TYPES do
		local wtFolder = Instance.new("Folder")
		wtFolder.Name = wt.id
		wtFolder.Parent = typesFolder
		wtFolder:SetAttribute("Name", wt.name)
		wtFolder:SetAttribute("Weight", wt.weight)
		wtFolder:SetAttribute("MinDuration", wt.duration[1] * 60)
		wtFolder:SetAttribute("MaxDuration", wt.duration[2] * 60)
		wtFolder:SetAttribute("Triggered", wt.triggered or false)
		wtFolder:SetAttribute("WaveModifier", wt.waveModifier)

		-- Lighting
		local lit = Instance.new("Folder")
		lit.Name = "Lighting"
		lit.Parent = wtFolder
		for k, v in pairs(wt.lighting) do
			if type(v) == "table" then
				local sub = Instance.new("Folder")
				sub.Name = k
				sub.Parent = lit
				for k2, v2 in pairs(v) do
					local v2Obj = Instance.new("Color3Value")
					if type(v2) == "userdata" and v2.r then
						v2Obj.Name = k2
						v2Obj.Value = v2
					else
						local nObj = Instance.new("NumberValue")
						nObj.Name = k2
						nObj.Value = v2
						nObj.Parent = sub
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

		-- Sons
		local snd = Instance.new("Folder")
		snd.Name = "Sounds"
		snd.Parent = wtFolder
		for _, s in ipairs(wt.sounds) do
			local sObj = Instance.new("StringValue")
			sObj.Name = s
			sObj.Value = s
			sObj.Parent = snd
		end

		-- Particules
		local part = Instance.new("Folder")
		part.Name = "Particles"
		part.Parent = wtFolder
		for _, p in ipairs(wt.particles) do
			local pObj = Instance.new("StringValue")
			pObj.Name = p
			pObj.Value = p
			pObj.Parent = part
		end
	end

	-- Script de transition (cote serveur)
	local script = Instance.new("Script")
	script.Name = "WeatherCycle"
	script.Parent = folder
	script.Source = [[
		-- WeatherCycle.server.lua
		-- Gere le cycle meteo cote serveur, synchro clients via RemoteEvent
		-- (Implemente par A dans WeatherService)
		print("[Weather] Cycle system ready")
	]]

	log("Systeme meteo cree : " .. #WEATHER_TYPES .. " types, cycle 30min, transition " .. TRANSITION_MINUTES .. "min")
end

local function createWorldEvents()
	log("  Evenements mondiaux : BlackTide (Leviathan), LeviathanWake, Eveil Leviathan")
	if DRY_RUN then return end

	local folder = Instance.new("Folder")
	folder.Name = "WorldEvents"
	folder.Parent = RS

	-- BlackTide (Maree Noire - Eveil Leviathan)
	local bt = Instance.new("Folder")
	bt.Name = "BlackTide"
	bt.Parent = folder
	bt:SetAttribute("WeatherType", "BlackTide")
	bt:SetAttribute("Trigger", "ExtremeTide_Leviathan")
	bt:SetAttribute("Duration", 25 * 60)
	bt:SetAttribute("WaveModifier", 2.0)
	bt:SetAttribute("Announcement", "L'Eveil du Leviathan commence. La mer recule...")
	bt:SetAttribute("Cinematic", "WorldEvent_BlackTide")
	bt:SetAttribute("BossSpawn", "Leviathan_TrueForm")
	bt:SetAttribute("RaidUnlock", "Raid_BlackTide")
	bt:SetAttribute("GlobalAnnouncement", true)
	bt:SetAttribute("CooldownHours", 672) -- 4 semaines

	-- LeviathanWake (Sillage)
	local lw = Instance.new("Folder")
	lw.Name = "LeviathanWake"
	lw.Parent = folder
	lw:SetAttribute("WeatherType", "LeviathanWake")
	lw:SetAttribute("Trigger", "BlackTide_End")
	lw:SetAttribute("Duration", { 30, 60 })
	lw:SetAttribute("WaveModifier", 1.2)
	lw:SetAttribute("BlessedWaterDropRate", 2.0)

	-- Storm (tempete aleatoire)
	local st = Instance.new("Folder")
	st.Name = "TropicalStorm"
	st.Parent = folder
	st:SetAttribute("WeatherType", "Storm")
	st:SetAttribute("Weight", 15)
	st:SetAttribute("Duration", { 8, 20 })
	st:SetAttribute("WaveModifier", 1.5)
	st:SetAttribute("LightningStrikeInterval", 30)

	log("Evenements mondiaux crees : BlackTide (Leviathan), LeviathanWake, Storm")
end

local function run()
	log("=== METEO DYNAMIQUE + EVENEMENTS MONDIAUX ===")
	for _, wt in WEATHER_TYPES do
		log("  " .. wt.id .. " : " .. wt.name .. " (poids=" .. wt.weight .. ", duree=" .. wt.duration[1] .. "-" .. wt.duration[2] .. "min, vague x" .. wt.waveModifier .. ")")
	end

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Meteo dynamique + Evenements mondiaux")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		createWeatherSystem()
		createWorldEvents()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Meteo dynamique + Evenements mondiaux crees. Pret pour WeatherService/WorldEventService.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()