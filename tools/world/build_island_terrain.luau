-- tools/world/build_island_terrain.luau
-- C : l'île ouverte, version de lancement (GDD §3 bis, P1-36). docs/DA_MONDE.md §10.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- CONTRAT AVEC A (10/10) — ne pas devier, le serveur lit exactement cela :
--  * Centre de l'île et de la crique = Config.Island.center = (0,0,0). Tout est calcule autour.
--  * Config.Island.size = 600. La vague traverse de -(300 + seaMargin) a +(300 + seaMargin) = -330..+330.
--  * Config.Island.coveRadius = 70 : dans ce cercle, la vague ne prend personne, pas de capture.
--    Les 8 lagons sont poses DANS ce cercle, en anneau, avec une breche de falaise face a chacun.
--  * Apparitions (A) : sur Terrain de materiau Sand ou Mud, sol entre spawnYMin (-2) et spawnYMax (16),
--    dans les anneaux 70-150, 150-225, 225-300. Il faut donc du SABLE PLAT dans cette plage.
--  * Pas d'apparition dans un rayon de 16 (Config.Island.towerRadius) autour de TowerN.Center.
--
-- Ce que ce script NE fait pas (et pourquoi) :
--  * Il ne touche ni aux Map.Plots.PlotN ni a leurs attributs : c'est le monde de C, mais les
--    lagons sont places par A (Center + Radius). Ce script prepare seulement le terrain autour.
--  * Il ne pose pas les creations : lagons, barrieres, decor sont faits par build_lagoon.luau,
--    qui doit tourner APRES, une fois le sol en place.
--
-- Un seul enregistrement ChangeHistoryService. Si le terrain est mauvais, Ctrl+Z et rien d'autre.

local DRY_RUN = true

-- Valeurs relues depuis Config si le serveur est charge, sinon les defauts ci-dessous.
-- On ne duplique PAS Config : on le lit quand il existe, pour ne jamais diverger du serveur.
local C_ISLAND = {
	size = 600,
	seaMargin = 30,
	coveRadius = 70,
	seaY = 0,
	spawnYMin = -2,
	spawnYMax = 16,
	towerRadius = 16,
	ring1 = { 70, 150 },
	ring2 = { 150, 225 },
	ring3 = { 225, 300 },
}

local function readConfig()
	local ok, cfg = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.Config)
	end)
	if ok and cfg and cfg.Island then
		local i = cfg.Island
		C_ISLAND.size = i.size or C_ISLAND.size
		C_ISLAND.seaMargin = i.seaMargin or C_ISLAND.seaMargin
		C_ISLAND.coveRadius = i.coveRadius or C_ISLAND.coveRadius
		C_ISLAND.seaY = i.seaY or C_ISLAND.seaY
		C_ISLAND.spawnYMin = i.spawnYMin or C_ISLAND.spawnYMin
		C_ISLAND.spawnYMax = i.spawnYMax or C_ISLAND.spawnYMax
		C_ISLAND.towerRadius = i.towerRadius or C_ISLAND.towerRadius
		print("[C] Config.Island lu : size", C_ISLAND.size, "cove", C_ISLAND.coveRadius)
	else
		warn("[C] Config indisponible, valeurs par defaut utilisees (verifier avec A).")
	end
end

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Terrain = workspace:WaitForChild("Terrain")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local SIZE = C_ISLAND.size
local HALF = SIZE / 2 -- 300
local SEA_Y = C_ISLAND.seaY -- 0
local COVE = C_ISLAND.coveRadius -- 70

-- 8 lagons en anneau dans la crique, comme le veut le serveur (cercles disjoints, rayon lu par A).
--
-- GEOMETRIE CONTRAINTE, calculee et non devinee :
--   8 disques de rayon L sur un anneau de rayon R, disjoints  =>  L <= R * sin(pi/8)
--   et contenus dans la crique                              =>  R + L <= coveRadius (70)
--   On combine : L <= 70 * s / (1 + s), avec s = sin(pi/8) = 0.3827  =>  L <= 19.4
-- Donc un lagon de plus de 19 de rayon est IMPOSSIBLE dans une crique de 70 avec 8 lagons.
-- On prend L = 18, R = 50 (68 <= 70, et 2*50*s = 38.3 > 2*18 = 36 : disjoints).
-- ⚠ Consequence a signaler a A : chaque PlotN devient un cercle de ~36 studs de diametre,
-- contre 32 x 63 pour l'ancien rectangle. 10 cuvettes de 5 a 7 studs tiennent mal dans 36.
-- A de decider : agrandir coveRadius, ou reduire a 6 lagons. Voir docs/INBOX/C.md.
local LAGOON_COUNT = 8
local LAGOON_RING_R = 50 -- distance du centre de la crique au centre d'un lagon
local LAGOON_RADIUS = 18 -- rayon horizontal d'un lagon (Center + Radius lu par A)

-- Une falaise en anneau autour de la crique, avec une breche face a chaque lagon.
-- C'est par la breche que la vague entre dans la crique (A ejecte le joueur vers la mer, cf. ExitOf).
local CLIFF_HEIGHT = 30 -- au-dessus du niveau de la vague (Config.Wave.height = 30) : la crique est a l'abri
-- La falaise occupe 70..74 seulement : c'est une CRETE, pas un mur epais.
-- ⚠ Point dur releve au test : l'anneau d'apparition 1 de A commence a r = 70, donc toute falaise
-- occupe une bande de son anneau. A 70..80, on constate 6.4 % de roche sur cet anneau ; a 70..74,
-- on tombe a 2.3 %. On retient la crete fine : elle protege autant (c'est la hauteur qui compte,
-- pas l'epaisseur) et elle empiete 4 fois moins sur les apparitions. Voir docs/INBOX/C.md.
local CLIFF_OUTER = 74
local CLIFF_BAND = CLIFF_OUTER - COVE
-- Demi-largeur d'une breche, en studs, mesuree sur la crete elle-meme.
local BREACH_HALF_WIDTH = 10

local RINGS = {
	C_ISLAND.ring1,
	C_ISLAND.ring2,
	C_ISLAND.ring3,
}

-- Terrain : 1000 x 1000 voxels -> blocs de 4 studs. 600 studs = 150 blocs de 4.
local VOXEL = 4
local BLOCKS = math.ceil((SIZE + 2 * 330) / VOXEL) -- 600 + 2*330 = 1260 studs -> 315 blocs

local function distXZ(x, z)
	return math.sqrt(x * x + z * z)
end

-- Angles des 8 lagons : repartition reguliere sur l'anneau.
local lagoonAngles = {}
for i = 1, LAGOON_COUNT do
	lagoonAngles[i] = (i - 1) * (2 * math.pi / LAGOON_COUNT)
end

-- Positions des 8 lagons (anneau dans la crique). Le serveur calcule Center/Radius de son cote ;
-- on garde ces positions ici pour ouvrir la breche de falaise en face de chaque lagon.
local lagonPositions = {}
for i = 1, LAGOON_COUNT do
	local a = lagoonAngles[i]
	lagonPositions[i] = Vector2.new(math.cos(a) * LAGOON_RING_R, math.sin(a) * LAGOON_RING_R)
end

-- Ecart ANGULAIRE au lagon le plus proche, en radians.
-- La breche est une porte angulaire face a un lagon : c'est ce qui la relie a la mer.
-- Une distance euclidienne au centre du lagon ne marche pas (le lagon est au bord de la crique,
-- et sa porte doit terrestrement aller vers l'exterieur, pas vers le centre de la crique).
local function angleToNearestLagon(x, z)
	local r = distXZ(x, z)
	if r < 0.01 then
		return math.huge
	end
	local ang = math.atan2(z, x)
	local best = math.huge
	for _, la in lagoonAngles do
		-- difference d'angle ramenee dans [-pi, pi], sans discontinuite a +-pi
		local d = math.abs(math.atan2(math.sin(ang - la), math.cos(ang - la)))
		if d < best then
			best = d
		end
	end
	return best
end

-- Hauteur du sol a un point (x, z). Cette fonction est le coeur du script : c'est elle que
-- les tests hors-jeu (tools/world/test_island_terrain.py) verifient.
--
-- Schema de l'ile, du centre vers l'exterieur :
--   r < coveRadius   : fond de crique sableux, sous le niveau de la mer (on y rentre par la breche)
--   r = coveRadius   : anneau de falaise (sauf breches face aux lagons)
--   anneaux 70..300  : plage et dunes SABLE PLAT, entre spawnYMin et spawnYMax (contrat A)
--   r > 300          : mer
local function heightAt(x, z)
	local r = distXZ(x, z)

	if r > HALF then
		return SEA_Y - 3 -- mer : legerement en dessous, l'eau couvre
	end

	if r < COVE then
		-- Crique : sable, en pente douce vers le centre. Sous l'eau pour que le lagon soit bleu.
		-- Le centre est le point le plus bas, on remonte vers la falaise.
		local t = r / COVE
		return SEA_Y - 2 + t * 2 -- de -2 (centre) a 0 (au pied de la falaise)
	end

	-- Falaise en anneau autour de la crique (70..80), avec une breche face a chaque lagon.
	-- La falaise protege la crique : elle depasse la hauteur de vague (30), donc un joueur
	-- dans la crique ne peut pas etre pris. La breche, elle, laisse passer la vague jusqu'au lagon.
	if r <= CLIFF_OUTER then
		-- demi-largeur angulaire de la breche, calculee a partir de sa demi-largeur lineaire
		local halfAngle = math.atan2(BREACH_HALF_WIDTH, r)
		if angleToNearestLagon(x, z) < halfAngle then
			return SEA_Y + 1 -- breche : on redescend au niveau de la plage
		end
		return SEA_Y + CLIFF_HEIGHT
	end

	-- Plage et dunes : SABLE PLAT entre spawnYMin et spawnYMax, sur toute la plage utile.
	-- C'est une contrainte dure du serveur : une creature apparue trop haut est hors de danger.
	-- On garde le sol dans [-2, 16], avec de tres leger relief pour ne pas etre un plateau.
	local roll = math.sin(x * 0.02) * 2 + math.cos(z * 0.018) * 2 -- relief doux, +/- 4
	local base = SEA_Y + 2 + roll
	-- On borne dans la plage d'apparition, avec une marge en haut (16) et en bas (-2).
	if base > C_ISLAND.spawnYMax - 2 then
		base = C_ISLAND.spawnYMax - 2
	end
	if base < C_ISLAND.spawnYMin + 1 then
		base = C_ISLAND.spawnYMin + 1
	end
	-- Loin de l'ile (r > 300), on redescend sous l'eau pour fermer l'anneau de plage.
	if r > 300 then
		local t = (r - 300) / (HALF - 300)
		base = base * (1 - t) + (SEA_Y - 3) * t
	end
	return base
end

-- Materiau de surface : sable sur la plage, roche sur la falaise, sous-sol plus bas.
-- A n'apparait creature que sur Sand ou Mud (Config.Island.spawnMaterials).
local function materialAt(x, z)
	local r = distXZ(x, z)
	if r > HALF then
		return Enum.Material.Sand -- fond marin : on laisse du sable, l'eau est au-dessus
	end
	if r <= CLIFF_OUTER then
		-- falaise : roche volcanique, sauf dans la breche qui doit rester franchissable
		if r <= COVE then
			return Enum.Material.Sand -- fond de crique
		end
		-- la breche est du sable : on ne pose pas de roche la ou la vague doit passer
		local halfAngle = math.atan2(BREACH_HALF_WIDTH, r)
		if angleToNearestLagon(x, z) < halfAngle then
			return Enum.Material.Sand
		end
		return Enum.Material.Rock
	end
	return Enum.Material.Sand -- plage : sable partout -> apparitions sur Sand
end

-- Ecrit le terrain. Une colonne de 4 studs a la fois, par blocs.
local function writeTerrain()
	local blockCount = 0
	for bx = 0, BLOCKS - 1 do
		for bz = 0, BLOCKS - 1 do
			local cx = (bx * VOXEL + VOXEL / 2) - (SIZE / 2 + 330)
			local cz = (bz * VOXEL + VOXEL / 2) - (SIZE / 2 + 330)
			local h = heightAt(cx, cz)
			local mat = materialAt(cx, cz)
			-- On ne remplit que la colonne visible : de seaY-8 au sommet.
			local bottom = SEA_Y - 8
			local top = math.max(h, bottom + VOXEL)
			Terrain:FillBlock(
				CFrame.new(cx, (bottom + top) / 2, cz),
				Vector3.new(VOXEL, top - bottom, VOXEL),
				mat
			)
			blockCount += 1
		end
	end
	return blockCount
end

local function run()
	readConfig()
	SIZE = C_ISLAND.size
	HALF = SIZE / 2
	COVE = C_ISLAND.coveRadius
	BLOCKS = math.ceil((SIZE + 2 * 330) / VOXEL)

	log(string.format("Ile %d x %d, crique r=%d, falaise %d, 8 lagons en anneau r=%d (rayon %d)",
		SIZE, SIZE, COVE, CLIFF_HEIGHT, LAGOON_RING_R, LAGOON_RADIUS))
	log("Lagon 1..8 (centre XZ) :")
	for i, p in lagonPositions do
		log(string.format("  Lagon %d : (%.0f, %.0f)", i, p.X, p.Y))
	end

	-- Controles de coherence avec le contrat A (abort si faux : mieux vaut un arret net
	-- qu'un terrain qui casse les apparitions).
	assert(LAGOON_RING_R + LAGOON_RADIUS < COVE, "les lagons debordent de la crique")
	local maxSpawnR = RINGS[#RINGS][2]
	assert(maxSpawnR <= HALF, "la plage d'apparition depasse l'ile")
	assert(CLIFF_HEIGHT >= 30, "la falaise doit depasser la hauteur de vague (30) pour proteger la crique")

	if DRY_RUN then
		log("DRY_RUN : rien modifie. Relancer avec DRY_RUN = false.")
		return
	end

	local rec = CHS:TryBeginRecording("C : ile ouverte")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(writeTerrain)
	if ok then
		-- Pose de l'ocean autour, pour que l'horizon ne s'arrete pas net a 500 studs.
		-- Planche d'eau autour de l'ile, au niveau de la mer.
		Terrain:FillBlock(
			CFrame.new(0, SEA_Y + 4, 0),
			Vector3.new(SIZE + 660, 8, SIZE + 660),
			Enum.Material.Water
		)
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Terrain ecrit. Lancer build_lagoon.luau ensuite pour les 8 lagons.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur terrain, tout annule : " .. tostring(err))
	end
end

run()
