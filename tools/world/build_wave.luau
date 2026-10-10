-- tools/world/build_wave.luau
-- C : la vague, star du jeu (docs/DA_MONDE.md §4). Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--  * ReplicatedStorage.Assets.Wave (v2) : vague de gameplay, rendue cote client. Memes noms qu'avant :
--    PrimaryPart Body (corps 300 x 22 x 40, bas a Y 0, front vers +Z), Foam (pied), Crest (rouleau d'ecume) avec le ParticleEmitter Spray.
--    En plus : Inner (profondeur), ShadowBand (ombre sur le sable devant le front), Mist (brume d'embruns).
--    La hauteur du corps reste celle du gameplay (Config.Wave : 22) ; le spectacle vient de la crete, des embruns et de l'ombre.
--  * ReplicatedStorage.Assets.WaveSwell : la houle geante a l'horizon pendant l'alerte (55 studs), que B fait monter
--    de sous la mer (Y -Height -> 0) pendant RiseTime, a Z = SpawnZ, puis cache au depart de la vague.
-- L'ancienne vague est gardee dans ServerStorage.C_Backup.Wave_v1.

local DRY_RUN = true

-- Decision D 09/10 : hauteur de vague ~30, plateformes de tours ~34 (Config.Wave.height = 30).
-- A fixe les valeurs finales ; le jeu n'est pas testable avant le 12/10, donc 30 reste une valeur de travail.
local WAVE = { width = 300, height = 30, thickness = 40, crest = 9, sprayMaxY = 29 }
local SWELL = { width = 1000, height = 55, thickness = 70, crest = 16, riseTime = 7, spawnZ = -1000 }

-- D 09/10 : la crete visible ne doit JAMAIS depasser une plateforme ou l'on est a l'abri (Y 34).
-- On se cale sous le corps : les embruns balaient les plateformes, ils ne les recouvrent pas.
local TOWER_SAFE_Y = 34
local MAX_VISIBLE_Y = TOWER_SAFE_Y - 5
assert(WAVE.sprayMaxY <= MAX_VISIBLE_Y, "sprayMaxY depasse la zone sure des tours")

local C = {
	deep = Color3.fromHex("13707A"),
	shallow = Color3.fromHex("2FB8B3"),
	ocean = Color3.fromHex("0D3B4C"),
	foam = Color3.fromHex("EEF5F2"),
	shadow = Color3.fromHex("0D2A33"),
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local assets = RS:FindFirstChild("Assets")
assert(assets, "[C] ReplicatedStorage.Assets introuvable")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function part(name, props, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function seq(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

local function emitter(name, props, parent)
	local e = Instance.new("ParticleEmitter")
	e.Name = name -- texture par defaut de Roblox ; a remplacer par une texture d'ecume sous licence si on en trouve une
	e.Color = ColorSequence.new(C.foam)
	e.LightInfluence = 1
	for k, v in props do
		e[k] = v
	end
	e.Parent = parent
	return e
end

-- Un mur d'eau : corps, profondeur, rouleau d'ecume a la crete (front vers +Z, bas a Y 0, centre en X 0)
local function wall(model, dims, colors)
	local body = part("Body", {
		Size = Vector3.new(dims.width, dims.height, dims.thickness),
		CFrame = CFrame.new(0, dims.height / 2, 0),
		Material = Enum.Material.Glass,
		Color = colors.outer,
		Transparency = 0.15,
		CastShadow = true,
	}, model)
	part("Inner", {
		Size = Vector3.new(dims.width - 2, dims.height * 0.8, dims.thickness * 0.7),
		CFrame = CFrame.new(0, dims.height * 0.4, -dims.thickness * 0.1),
		Material = Enum.Material.Glass,
		Color = colors.inner,
		Transparency = 0.1,
		CastShadow = false,
	}, model)
	-- rouleau : cylindre couche le long de X, en surplomb du front
	local crest = part("Crest", {
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(dims.width, dims.crest, dims.crest),
		CFrame = CFrame.new(0, dims.height - dims.crest * 0.25, dims.thickness / 2 + dims.crest * 0.15),
		Material = Enum.Material.Snow,
		Color = C.foam,
		Transparency = 0.1,
		CastShadow = true,
	}, model)
	model.PrimaryPart = body
	return body, crest
end

local function buildWave()
	local model = Instance.new("Model")
	model.Name = "Wave"
	model:SetAttribute("Width", WAVE.width)
	model:SetAttribute("Height", WAVE.height)
	model:SetAttribute("Thickness", WAVE.thickness)
	model:SetAttribute("SprayMaxY", WAVE.sprayMaxY)
	local body, crest = wall(model, WAVE, { outer = C.deep, inner = C.ocean })
	-- pied d'ecume devant le front (B fait defiler une texture dessus)
	local foam = part("Foam", {
		Size = Vector3.new(WAVE.width, 1.2, 8),
		CFrame = CFrame.new(0, 0.6, WAVE.thickness / 2 + 4),
		Material = Enum.Material.Snow,
		Color = C.foam,
		Transparency = 0.2,
		CastShadow = false,
	}, model)
	-- ombre portee sur le sable, 10 a 30 studs devant le front.
	-- F 10/10 : SmoothPlastic ici donnait le rendu "jouet". Une ombre plate ne se voit pas
	-- comme un plastique lisse : Material.Ground, mat et sans reflet.
	part("ShadowBand", {
		Size = Vector3.new(WAVE.width, 0.2, 20),
		CFrame = CFrame.new(0, 0.15, WAVE.thickness / 2 + 20),
		Material = Enum.Material.Ground,
		Color = C.shadow,
		Transparency = 0.62,
		Reflectance = 0,
		CastShadow = false,
	}, model)
	-- 3 emetteurs (budget §5) : embruns de crete, brume, eclaboussures au pied.
	-- Spray : vitesse calculee pour retomber SOUS le sommet de la crete. Avec une vitesse fixe
	-- de 20 a 60 deg, les particules montaient bien au-dessus de WAVE.sprayMaxY (F 10/10) et
	-- pouvaient recouvrir une plateforme de tour, ce que D a interdit. On borne la vitesse
	-- a la chute qu'il faut pour retomber a la hauteur visee, avec une marge.
	local sprayTop = WAVE.height + WAVE.crest
	local sprayFall = math.max(0, sprayTop - WAVE.sprayMaxY)
	local spraySpeed = math.min(20, math.sqrt(2 * 20 * sprayFall))
	emitter("Spray", {
		Rate = 35,
		Lifetime = NumberRange.new(1, 1.6),
		Speed = NumberRange.new(spraySpeed * 0.6, spraySpeed),
		SpreadAngle = Vector2.new(20, 60),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -20, 4),
		Size = seq(2, 6),
		Transparency = seq(0.3, 1),
		Drag = 1,
	}, crest)
	emitter("Mist", {
		Rate = 8,
		Lifetime = NumberRange.new(2, 3),
		Speed = NumberRange.new(2, 5),
		SpreadAngle = Vector2.new(60, 60),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(10, 16),
		Transparency = seq(0.6, 1),
	}, body)
	emitter("FootSplash", {
		Rate = 20,
		Lifetime = NumberRange.new(0.5, 0.9),
		Speed = NumberRange.new(6, 10),
		SpreadAngle = Vector2.new(30, 30),
		EmissionDirection = Enum.NormalId.Top,
		Acceleration = Vector3.new(0, -25, 0),
		Size = seq(1, 3),
		Transparency = seq(0.2, 1),
	}, foam)
	return model
end

local function buildSwell()
	local model = Instance.new("Model")
	model.Name = "WaveSwell"
	model:SetAttribute("Height", SWELL.height)
	model:SetAttribute("RiseTime", SWELL.riseTime)
	model:SetAttribute("SpawnZ", SWELL.spawnZ)
	-- A 10/10 : la vague arrive des 4 directions (N/E/S/O). UNE SEULE houle est construite,
	-- modelisee face a +Z comme la v1 ; c'est B qui la oriente selon la direction annoncee.
	-- Ne pas construire 4 houles : meme modele, 4 orientations.
	-- Convention A : "from N" vient de -Z et avance vers +Z ; "from E" vient de +X et avance
	-- vers -X ; S et W a l'inverse. La houle traverse de -330 a +330 sur son axe.
	model:SetAttribute("AxisConvention", "front=+Z ; N=-Z E=+X S=+Z W=-X")
	model:SetAttribute("Reach", 330)
	local body = wall(model, SWELL, { outer = C.ocean, inner = C.deep })
	emitter("Mist", {
		Rate = 6,
		Lifetime = NumberRange.new(3, 4),
		Speed = NumberRange.new(3, 6),
		SpreadAngle = Vector2.new(40, 40),
		EmissionDirection = Enum.NormalId.Top,
		Size = seq(20, 30),
		Transparency = seq(0.5, 1),
	}, body)
	return model
end

local function build()
	log(string.format("Assets.Wave v2 : corps %d x %d x %d, crete %d, embruns jusqu'a Y %d, ombre au sol", WAVE.width, WAVE.height, WAVE.thickness, WAVE.crest, WAVE.sprayMaxY))
	log(string.format("Assets.WaveSwell : houle %d x %d, montee en %d s, portee +-330 sur son axe, orientee par B (4 directions N/E/S/O)", SWELL.width, SWELL.height, SWELL.riseTime))
	if DRY_RUN then
		return
	end
	local old = assets:FindFirstChild("Wave")
	if old then
		local backup = ServerStorage:FindFirstChild("C_Backup") or Instance.new("Folder")
		backup.Name = "C_Backup"
		backup.Parent = ServerStorage
		local prev = backup:FindFirstChild("Wave_v1")
		if prev then
			old:Destroy() -- une sauvegarde de la v1 existe deja
		else
			old.Name = "Wave_v1"
			old.Parent = backup
		end
	end
	buildWave().Parent = assets
	local oldSwell = assets:FindFirstChild("WaveSwell")
	if oldSwell then
		oldSwell:Destroy()
	end
	buildSwell().Parent = assets
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : vague v2")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("vague v2 creee. Verifier en Play que l'ancien rendu cote client la trouve (memes noms). Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
