-- tools/world/build_archipelago.lua
-- C : Archipel streaming 5 îles — VRAI MMORPG (DECISIONS_MARCHE.md §9).
-- Phase 1 (2 sem) : Fondations monde persistant 200-500 joueurs.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
-- StreamingEnabled chunks 300 studs, LOD 3 niveaux, biomes, météo, secrets.
-- Cross-platform : LOD 80/160/300 mobile, 120/250/500 PC.

local DRY_RUN = true

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- ========== CONFIG ARCHIPEL (lu depuis Config si dispo) ==========
local CFG = {
	-- Îles : 5 îles principales + hub central
	islands = {
		{ name = "Hub_Central",     center = Vector3.new(0, 0, 0),     radius = 300, biome = "Hub",       height = 50,  secrets = { "HotelVentes", "GuildeHall", "PortailDonjon" } },
		{ name = "Ile_Crique",      center = Vector3.new(0, 0, -400),  radius = 250, biome = "Crique",    height = 30,  secrets = { "LagonJoueurs", "RecifMaree", "EpaveSO" } },
		{ name = "Ile_Dunes",       center = Vector3.new(500, 0, 200), radius = 220, biome = "Dunes",     height = 40,  secrets = { "RuinesAnciennes", "GrotteSable" } },
		{ name = "Ile_Recif",       center = Vector3.new(-450, 0, 300),radius = 200, biome = "Recif",     height = 35,  secrets = { "GrotteCorail", "NidTortues", "TempleMaree" } },
		{ name = "Ile_Falaise",     center = Vector3.new(-300, 0, -500),radius = 240, biome = "Falaise",   height = 80,  secrets = { "Phare", "Belvedere", "GrotteVents" } },
		{ name = "Ile_Abysses",     center = Vector3.new(0, 0, 800),   radius = 180, biome = "Abysses",   height = -20, secrets = { "EntreeDonjon", "BossLeviathan", "CathédraleEcume" } },
	},
	-- Streaming
	streaming = {
		chunkSize = 300,
		streamingMinRadius = 200,
		streamingMaxRadius = 600,
		targetRadius = 400,
	},
	-- LOD cross-platform
	lod = {
		mobile = { 80, 160, 300 },
		pc = { 120, 250, 500 },
	},
	-- Météo dynamique
	weather = {
		types = { "Clear", "Fog", "Storm", "BlackTide", "LeviathanWake" },
		cycleMinutes = 30,
		transitionMinutes = 5,
	},
	-- Lagons joueurs (8 lagons, r=30, coveRadius=110)
	playerLagoons = {
		count = 8,
		ringRadius = 50,
		lagoonRadius = 30,
		coveRadius = 110,
		sunkPools = true,
		sinkDepth = 3.5,
	},
	-- Biomes palette
	biomes = {
		Hub       = { ground = "Grass",      accent = "Flower",     heightMul = 1.0,  color = Color3.fromHex("E8D5B7") },
		Crique    = { ground = "Sand",       accent = "Coral",      heightMul = 0.8,  color = Color3.fromHex("2FB8B3") },
		Dunes     = { ground = "Sand",       accent = "Rock",       heightMul = 1.2,  color = Color3.fromHex("D3BC8C") },
		Recif     = { ground = "Sand",       accent = "Coral",      heightMul = 0.7,  color = Color3.fromHex("1A7AA6") },
		Falaise   = { ground = "Rock",       accent = "Grass",      heightMul = 2.5,  color = Color3.fromHex("5A524C") },
		Abysses   = { ground = "Rock",       accent = "Coral",      heightMul = -0.5, color = Color3.fromHex("0D3B4C") },
	},
}

-- ========== FONCTIONS UTILITAIRES ==========
local function lerp(a, b, t) return a + (b - a) * t end
local function dist(x1, z1, x2, z2) return math.sqrt((x1-x2)^2 + (z1-z2)^2) end

local function heightAt(x, z)
	-- Calcule la hauteur du terrain en combinant les contributions de toutes les îles
	local h = 0
	local maxContrib = 0
	for _, isl in CFG.islands do
		local d = dist(x, z, isl.center.X, isl.center.Z)
		if d <= isl.radius + 50 then
			local t = 1 - math.min(1, d / (isl.radius + 50))
			local contrib = isl.height * t * t -- quadratique pour bord doux
			h = h + contrib
			maxContrib = math.max(maxContrib, contrib)
		end
	end
	-- Niveau de la mer
	if h < 0 then h = -2 + math.random() * 0.5 end
	return h
end

local function materialAt(x, z)
	-- Détermine le biome dominant
	local bestBiome, bestWeight = "Hub", 0
	for _, isl in CFG.islands do
		local d = dist(x, z, isl.center.X, isl.center.Z)
		if d <= isl.radius + 80 then
			local w = math.max(0, 1 - d / (isl.radius + 80))
			if w > bestWeight then
				bestWeight, bestBiome = w, isl.biome
			end
		end
	end
	local b = CFG.biomes[bestBiome] or CFG.biomes.Hub
	if bestBiome == "Abysses" then return Enum.Material.Rock end
	if bestBiome == "Crique" then return Enum.Material.Sand end
	if bestBiome == "Falaise" then return Enum.Material.Rock end
	if bestBiome == "Recif" then return Enum.Material.Sand end
	if bestBiome == "Dunes" then return Enum.Material.Sand end
	return Enum.Material.Grass
end

local function createIslandFolder(name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = Workspace
	return folder
end

local function buildIslandTerrain(island)
	log("  Construction île : " .. island.name .. " (r=" .. island.radius .. ", biome=" .. island.biome .. ")")
	if DRY_RUN then return end

	local folder = createIslandFolder("Island_" .. island.name)
	local biome = CFG.biomes[island.biome]
	local chunk = CFG.streaming.chunkSize

	-- Grille de chunks couvrant l'île + marge
	local r = island.radius + 80
	local minX, maxX = math.floor((island.center.X - r) / CFG.streaming.chunkSize), math.ceil((island.center.X + r) / CFG.streaming.chunkSize)
	local minZ, maxZ = math.floor((island.center.Z - r) / CFG.streaming.chunkSize), math.ceil((island.center.Z + r) / CFG.streaming.chunkSize)

	for cx = minX, maxX do
		for cz = minZ, maxZ do
			local wx = cx * CFG.streaming.chunkSize
			local wz = cz * CFG.streaming.chunkSize
			local chunkCenterX = wx + CFG.streaming.chunkSize / 2
			local chunkCenterZ = wz + CFG.streaming.chunkSize / 2
			local d = dist(chunkCenterX, chunkCenterZ, island.center.X, island.center.Z)
			if d <= island.radius + 80 then
				-- Ce chunk touche l'île
				local h = heightAt(chunkCenterX, chunkCenterZ)
				local mat = materialAt(chunkCenterX, chunkCenterZ)
				Terrain:FillBlock(
					CFrame.new(chunkCenterX, h / 2, chunkCenterZ),
					Vector3.new(CFG.streaming.chunkSize, math.max(4, h + 4), CFG.streaming.chunkSize),
					mat
				)
			end
		end
	end

	-- Marquer les secrets (pour les scripts suivants)
	for _, secret in island.secrets do
		local marker = Instance.new("Part")
		marker.Name = "Secret_" .. secret
		marker.Size = Vector3.new(10, 10, 10)
		marker.Transparency = 1
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.Parent = folder
		marker:SetAttribute("SecretType", secret)
	end

	-- Attributs streaming
	folder:SetAttribute("StreamingChunkSize", CFG.streaming.chunkSize)
	folder:SetAttribute("Biome", island.biome)
end

local function buildPlayerLagoons()
	log("  8 lagons joueurs (coveRadius=110, r=30, sunk=true)")
	if DRY_RUN then return end
	-- Réutilise build_lagoon.lua qui gère déjà Center+Radius + SUNK_POOLS
	-- Ce script ne fait que positionner les 8 PlotN aux bons endroits
	local map = Workspace:FindFirstChild("Map")
	assert(map, "Workspace.Map requis")
	local plots = map:FindFirstChild("Plots")
	assert(plots, "Map.Plots requis")

	for i = 1, CFG.playerLagoons.count do
		local angle = (i - 1) * (2 * math.pi / CFG.playerLagoons.count)
		local cx = math.cos(angle) * CFG.playerLagoons.ringRadius
		local cz = math.sin(angle) * CFG.playerLagoons.ringRadius
		local plot = plots:FindFirstChild("Plot" .. i)
		if plot then
			plot:SetAttribute("Center", Vector3.new(cx, 0, cz))
			plot:SetAttribute("Radius", CFG.playerLagoons.lagoonRadius)
			plot:SetAttribute("SunkPools", true)
			plot:SetAttribute("SinkDepth", CFG.playerLagoons.sinkDepth)
			-- Rotation : sortie vers l'exterieur (vers la mer)
			local outward = Vector3.new(cx, 0, cz).Unit
			plot:SetAttribute("OutwardDir", outward)
		end
	end
end

local function buildStreamingSettings()
	if DRY_RUN then return end
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = CFG.streaming.streamingMinRadius
	Workspace.StreamingMaxRadius = CFG.streaming.streamingMaxRadius
	Workspace.StreamingTargetRadius = CFG.streaming.streamingTargetRadius
	log("StreamingEnabled = true, chunks=" .. CFG.streaming.chunkSize .. " studs")
end

local function run()
	log("=== ARCHIPEL STREAMING 5 ÎLES (MMORPG Phase 1) ===")
	for _, isl in CFG.islands do
		log("  Île : " .. isl.name .. " @ (" .. isl.center.X .. "," .. isl.center.Z .. ") r=" .. isl.radius .. " biome=" .. isl.biome)
	end
	log("Lagons joueurs : " .. CFG.playerLagoons.count .. " x r=" .. CFG.playerLagoons.lagoonRadius .. " @ ring=" .. CFG.playerLagoons.ringRadius)

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer avec DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Archipel streaming 5 îles")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		buildStreamingSettings()
		for _, isl in CFG.islands do
			buildIslandTerrain(isl)
		end
		buildPlayerLagoons()
		-- Océan autour
		Terrain:FillBlock(
			CFrame.new(0, -10, 0),
			Vector3.new(3000, 20, 3000),
			Enum.Material.Water
		)
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Archipel cree. Streaming actif. Lancer build_boss_arenas.lua puis build_dungeon_raid.lua")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()