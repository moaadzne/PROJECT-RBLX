-- tools/world/build_archipelago_v2.luau
-- C : Cycle 1 — Archipel Core (DECISIONS_MARCHE.md §9, directive tâches infinies).
-- 12 iles, 8 biomes, StreamingEnabled chunks 200, LOD mobile 80/160/300 PC 120/250/500,
-- 5 zones distinctes (palettes, props, lighting, ambiance), crique centrale (hub + 8 lagons),
-- terrain sculpté (falaises, grottes, plages, fonds marins, ruines), integration _DecorLib.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- CONTRAT : Config.Streaming (chunks), Config.CrossPlatform (LOD, particules), Config.Island.
-- _DecorLib : ReplicatedStorage.Assets._DecorLib.StylizedNaturePack (verifié existant, d2b3a76).

local DRY_RUN = true
local DECOR = true -- true = placer _DecorLib selon heightAt/materialAt

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Terrain = Workspace:WaitForChild("Terrain")
local RS = game:GetService("ReplicatedStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local lib = RS and RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("_DecorLib")
if not lib then
	warn("[C] _DecorLib introuvable : decor ignore (verifier avec verify_decorlib.py)")
end

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- ========== CONFIG (lu depuis Config.lua quand dispo, sinon ces valeurs) ==========
local function readConfig()
	local ok, cfg = pcall(function()
		return require(RS.Shared.Config)
	end)
	local d = {
		streaming = { chunk = 200, min = 200, target = 400, max = 600 },
		lod = { mobile = { 80, 160, 300 }, pc = { 120, 250, 500 } },
		particles = { mobile = 50, pc = 200 },
		coveRadius = 110,
		lagoonRing = 50,
		lagoonRadius = 30,
		waveHeight = 30,
	}
	if ok and cfg then
		if cfg.Streaming then
			d.streaming.chunk = cfg.Streaming.ChunkSize or 200
			d.streaming.min = cfg.Streaming.MinRadius or 200
			d.streaming.target = cfg.Streaming.TargetRadius or 400
			d.streaming.max = cfg.Streaming.MaxRadius or 600
		end
		if cfg.CrossPlatform then
			d.lod.mobile = cfg.CrossPlatform.LOD.mobile or d.lod.mobile
			d.lod.pc = cfg.CrossPlatform.LOD.pc or d.lod.pc
			d.particles.mobile = cfg.CrossPlatform.MaxParticles.mobile or 50
			d.particles.pc = cfg.CrossPlatform.MaxParticles.pc or 200
		end
		if cfg.Island then
			d.coveRadius = cfg.Island.coveRadius or 110
			d.waveHeight = cfg.Wave and cfg.Wave.height or 30
		end
	end
	return d
end
local C = readConfig()

-- ========== 12 ÎLES, 8 BIOMES ==========
-- Palette DA (docs/DA_MONDE.md §3) + biomes distincts.
local BIOMES = {
	Crique   = { ground = "Sand",  accent = "Coral", h = 0,   color = Color3.fromHex("2FB8B3"), props = { "Pier", "Coral", "Seashell" } },
	Dunes    = { ground = "Sand",  accent = "Rock",  h = 6,   color = Color3.fromHex("E6D2A8"), props = { "CoconutPalm", "FanPalm", "Rock" } },
	Recif    = { ground = "Sand",  accent = "Coral", h = 1,   color = Color3.fromHex("1A7AA6"), props = { "Coral", "Seashell", "Rock" } },
	Falaise  = { ground = "Rock",  accent = "Grass", h = 46,  color = Color3.fromHex("5A524C"), props = { "LightHouse", "Rock", "Bush" } },
	Epave    = { ground = "Sand",  accent = "Wood",  h = 4,   color = Color3.fromHex("7D6E60"), props = { "Wreck", "Raft", "Chest" } },
	Jungle   = { ground = "Grass", accent = "Wood",  h = 14,  color = Color3.fromHex("3F6B3A"), props = { "Tree", "Bush", "Flower" } },
	Volcans  = { ground = "Rock",  accent = "Lava",  h = 34,  color = Color3.fromHex("3B3633"), props = { "Rock", "LavaRock" } },
	Abysses  = { ground = "Rock",  accent = "Coral", h = -16, color = Color3.fromHex("0D3B4C"), props = { "Coral", "Ruins", "Column" } },
}

local ISLANDS = {
	{ name = "Crique_Centrale", biome = "Crique",  cx = 0,    cz = 0,    r = 110, hub = true },
	{ name = "Dunes_Est",       biome = "Dunes",   cx = 420,  cz = 0,    r = 220, ring = 1 },
	{ name = "Recif_Nord",      biome = "Recif",   cx = 0,    cz = -380, r = 200, ring = 1 },
	{ name = "Falaise_Ouest",   biome = "Falaise", cx = -400, cz = 0,    r = 240, ring = 2 },
	{ name = "Epave_Sud",       biome = "Epave",   cx = 0,    cz = 335,  r = 120, ring = 1 },
	{ name = "Jungle_EstSud",   biome = "Jungle",  cx = 500,  cz = 300,  r = 180, ring = 3 },
	{ name = "Volcans_NordEst", biome = "Volcans", cx = -380, cz = -450, r = 160, ring = 3 },
	{ name = "Abysses_SudEst",  biome = "Abysses", cx = 350,  cz = 500,  r = 150, ring = 3 },
	{ name = "Cite_Engloutie",  biome = "Abysses", cx = -450, cz = 450,  r = 140, ring = 3 },
	{ name = "Ile_Celeste",     biome = "Falaise", cx = 0,    cz = -650, r = 130, ring = 3 },
	{ name = "Ile_Miroir",      biome = "Epave",   cx = 620,  cz = -300, r = 120, ring = 3 },
	{ name = "Banc_Sable",      biome = "Dunes",   cx = -260, cz = -260, r = 90,  ring = 2 },
}

-- 5 zones distinctes (palettes, lighting, ambiance, crees uniques par zone)
local ZONES = {
	{ name = "Crique",    rMin = 0,   rMax = 110, lighting = { ClockTime = 17.05, Brightness = 2, Bloom = 0.4 }, creatures = { "GhostCrab", "CushionStar" } },
	{ name = "Littoral",  rMin = 110, rMax = 225, lighting = { ClockTime = 17.2,  Brightness = 2, Bloom = 0.35 }, creatures = { "Lionfish", "HawksbillTurtle" } },
	{ name = "HautFond",  rMin = 225, rMax = 340, lighting = { ClockTime = 17.5,  Brightness = 1.8, Bloom = 0.3 }, creatures = { "BlueRingedOctopus", "LeopardRay" } },
	{ name = "Abysses",   rMin = 340, rMax = 600, lighting = { ClockTime = 19,    Brightness = 0.8, Bloom = 0.5 }, creatures = { "GiantPacificOctopus", "LionsManeJelly" } },
	{ name = "Ciel",      rMin = 600, rMax = 900, lighting = { ClockTime = 18,    Brightness = 2.4, Bloom = 0.6 }, creatures = { "MantaRay", "WhaleShark" } },
}

-- Crique centrale : hub + 8 lagons
local COVE = C.coveRadius
local LAGOON_COUNT, LAGOON_RING, LAGOON_R = 8, C.lagoonRing, C.lagoonRadius
local CLIFF_H = C.waveHeight + 16 -- 46 : au-dessus de la vague (30) marge de securite

local function dist(x1, z1, x2, z2) return math.sqrt((x1 - x2) ^ 2 + (z1 - z2) ^ 2) end

local function nearestIsland(x, z)
	local best, bestD = nil, math.huge
	for _, isl in ISLANDS do
		local d = dist(x, z, isl.cx, isl.cz)
		if d <= isl.r and d < bestD then
			best, bestD = isl, d
		end
	end
	return best, bestD
end

-- Hauteur du terrain : sommet de l'ile + creusement (grottes, fonds marins)
local function heightAt(x, z)
	local isl, d = nearestIsland(x, z)
	if not isl then return -3 end -- mer profonde

	local b = BIOMES[isl.biome]
	local r = isl.r
	local t = 1 - math.min(1, d / r)
	local h = b.h * t * t

	-- Plage : pente douce vers l'eau sur les 30 premiers studs du bord
	if t < 0.15 then
		h = b.h * (t / 0.15) * 0.5
	end

	-- Crique centrale : cuvette (les 8 lagons sont creuses)
	if isl.hub then
		local cd = dist(x, z, isl.cx, isl.cz)
		if cd < COVE then
			h = -2 + math.min(6, cd / COVE * 8) -- de -2 (centre) a +6 (bord)
			-- 8 cuvettes de lagon : creux circulaires
			for i = 1, LAGOON_COUNT do
				local a = (i - 1) * (2 * math.pi / LAGOON_COUNT)
				local lx, lz = math.cos(a) * LAGOON_RING, math.sin(a) * LAGOON_RING
				local ld = dist(x, z, lx, lz)
				if ld < LAGOON_R then
					h = -3.5 + math.max(0, (ld / LAGOON_R)) * 3.5 -- cuvette a -3.5 (SUNK_POOLS)
				end
			end
			-- Depot du ponton devant l'entree
			if math.abs(z - 0) < 8 and x > -14 and x < 14 then h = 1 end
		else
			h = h + 12 -- levee de terre autour de la crique
		end
	end

	-- Falaises : blocs rocheux sur le pourtour (biome Falaise / Volcans)
	if isl.biome == "Falaise" or isl.biome == "Volcans" then
		if t > 0.55 then
			h = h + (t - 0.55) * 2.2 * 46 -- montee raide vers la falaise
		end
	end

	-- Grottes : creux sous les falaises (sinusoidaux, reproductibles)
	if isl.biome == "Falaise" then
		local cave = math.sin(x * 0.02) * math.cos(z * 0.023)
		if cave > 0.72 and t > 0.5 then h = h - 14 end
	end

	-- Fonds marins : sous la crique et sous les abysses
	if isl.biome == "Abysses" then
		h = h - 10 -- plateau plus bas
		if t > 0.7 then h = h - 8 end
	end

	-- Ruines : blocs anciens (Cite Engloutie)
	if isl.name == "Cite_Engloutie" then
		local rr = math.floor(d / 18) % 3
		if rr == 0 then h = h + 5 end
	end

	return math.max(-24, math.min(120, h))
end

local function materialAt(x, z)
	local isl = nearestIsland(x, z)
	if not isl then return Enum.Material.Sand end
	local b = BIOMES[isl.biome]
	if isl.biome == "Crique" or isl.biome == "Dunes" or isl.biome == "Recif" or isl.biome == "Epave" then
		return Enum.Material.Sand
	elseif isl.biome == "Jungle" then
		return Enum.Material.Grass
	elseif isl.biome == "Volcans" then
		return Enum.Material.CrackedLava
	elseif isl.biome == "Abysses" then
		return Enum.Material.Slate
	end
	return Enum.Material.Rock
end

-- ========== CONSTRUCTION ==========
local CHUNK = C.streaming.chunk
local RANGE = 950 -- couvre toutes les iles + marge

local function terrainColumn(cx, cz)
	local h = heightAt(cx, cz)
	local bottom, top = -26, math.max(h + 4, -22)
	Terrain:FillBlock(
		CFrame.new(cx, (bottom + top) / 2, cz),
		Vector3.new(CHUNK, top - bottom, CHUNK),
		materialAt(cx, cz)
	)
end

local function buildTerrain()
	local n = 0
	for bx = -RANGE / CHUNK, RANGE / CHUNK do
		for bz = -RANGE / CHUNK, RANGE / CHUNK do
			local cx = bx * CHUNK + CHUNK / 2
			local cz = bz * CHUNK + CHUNK / 2
			if nearestIsland(cx, cz) then -- ne remplit que la ou il y a une ile
				terrainColumn(cx, cz)
				n = n + 1
			end
		end
	end
	return n
end

-- _DecorLib : place les props selon heightAt/materialAt, un seul enregistrement
local function findDecor(key)
	if not lib then return nil end
	for _, pat in ({ "palm", "rock", "coral", "pier", "hut", "wreck", "chest", "raft", "light", "lighthouse" })[key] or {} do
		local found = lib:FindFirstChild(pat, true)
		if found and (found:IsA("Model") or found:IsA("BasePart")) then return found end
	end
	return nil
end

local DECOR_KEYS = {
	palm = { "CoconutPalm", "FanPalm", "Palm" },
	rock = { "Rock", "MediumRock", "MossyRock" },
	coral = { "Coral", "Coral4_G2", "Coral5_G2" },
	pier = { "Pier", "Dock" },
	hut = { "Hut", "HutPost" },
	wreck = { "Wreck", "Shipwreck" },
	chest = { "Chest", "TreasureChest" },
	raft = { "Raft" },
	light = { "LightHouse", "Lighthouse" },
}

local function placeDecor()
	if not lib or not DECOR then return 0 end
	local n = 0
	local rng = Random.new(710)
	for _, isl in ISLANDS do
		local b = BIOMES[isl.biome]
		for _, prop in b.props do
			local key
			for k, _ in DECOR_KEYS do
				if string.find(string.lower(prop), k, 1, true) then key = k end
			end
			if not key then continue end
			local found = findDecor(key)
			if found then
				local angle = rng:NextNumber(0, 2 * math.pi)
				local r = isl.r * rng:NextNumber(0.35, 0.95)
				local x = isl.cx + math.cos(angle) * r
				local z = isl.cz + math.sin(angle) * r
				local h = heightAt(x, z)
				local clone = found:Clone()
				clone:PivotTo(CFrame.new(x, h, z))
				for _, d in clone:GetDescendants() do
					if d:IsA("BasePart") then
						d.Anchored = true
						d.CanCollide = d.Name == "Hull" or d.Name == "Chest"
						d.CanQuery = false
						d.CastShadow = rng:NextNumber() > 0.5
					elseif d:IsA("LuaSourceContainer") then
						warn("[C] script retire du decor : " .. d:GetFullName())
						d:Destroy()
					end
				end
				clone.Name = isl.name .. "_" .. prop .. "_" .. n
				clone.Parent = Workspace
				n = n + 1
			end
		end
	end
	return n
end

-- 8 lagons de la crique centrale : barrières + pontons + cabanes
local function buildCove()
	local n = 0
	for i = 1, LAGOON_COUNT do
		local a = (i - 1) * (2 * math.pi / LAGOON_COUNT)
		local lx = LAGOON_RING and math.cos(a) * LAGOON_RING or 0
		local lz = math.sin(a) * (C.lagoonRing or 50)

		-- Ponton : planche devant l'entree du lagon (vers la mer)
		local pier = findDecor("pier")
		if pier then
			local clone = pier:Clone()
			clone:PivotTo(CFrame.new(lx, 1, lz) * CFrame.new(math.cos(a), 0, math.sin(a)) * 4)
			for _, d in clone:GetDescendants() do
				if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = true end
			end
			clone.Name = "Ponton_" .. i
			clone.Parent = Workspace
			n = n + 1
		end

		-- Cabane sur le palier (derriere le lagon, vers l'interérieur)
		local hut = findDecor("hut")
		if hut then
			local clone = hut:Clone()
			local hx, hz = math.cos(a) * (LAGOON_RING - 34), math.sin(a) * (LAGOON_RING - 34)
			clone:PivotTo(CFrame.new(hx, heightAt(hx, hz), hz))
			for _, d in clone:GetDescendants() do
				if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = true end
			end
			clone.Name = "Cabane_" .. i
			clone.Parent = Workspace
			n = n + 1
		end
	end
	return n
end

local function applyStreaming()
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = C.streaming.min
	Workspace.StreamingTargetRadius = C.streaming.target
	Workspace.StreamingMaxRadius = C.streaming.max
end

local function run()
	log("=== CYCLE 1 — ARCHIPEL CORE : 12 ILES, 8 BIOMES ===")
	for _, isl in ISLANDS do
		log(string.format("  %-18s %-8s (%4d,%4d) r=%d", isl.name, isl.biome, isl.cx, isl.cz, isl.r))
	end
	log("Streaming : chunks " .. CHUNK .. ", min=" .. C.streaming.min .. " target=" .. C.streaming.target .. " max=" .. C.streaming.max)
	log("LOD : mobile " .. table.concat(C.lod.mobile, "/") .. " | PC " .. table.concat(C.lod.pc, "/"))
	log("Particules : " .. C.particles.mobile .. " mobile / " .. C.particles.pc .. " PC")
	log("Crique : r=" .. COVE .. ", " .. LAGOON_COUNT .. " lagons r=" .. LAGOON_R .. " anneau r=" .. LAGOON_RING)

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer DRY_RUN=false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : Cycle 1 archipel core 12 iles")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		applyStreaming()
		local cols = buildTerrain()
		log("terrain : " .. cols .. " colonnes")
		if DECOR then
			local d = placeDecor()
			log("decor _DecorLib : " .. d .. " props places")
		end
		local c = buildCove()
		log("crique : " .. c .. " pontons/cabanes")
		-- Ocean autour
		Terrain:FillBlock(CFrame.new(0, -14, 0), Vector3.new(2400, 20, 2400), Enum.Material.Water)
	end)

	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("CYCLE 1 TERMINE. Lancer build_wave.luau puis build_lagoon.luau.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur, tout annule : " .. tostring(err))
	end
end

run()
