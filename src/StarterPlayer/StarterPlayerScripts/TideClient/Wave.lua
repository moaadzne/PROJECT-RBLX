-- Wave : rendu client de la vague (P1-16 / P1-42). Le serveur ne bouge aucune piece : WaveService publie
-- l'etat du cycle dans WaveState, et le client dessine le mur d'eau avec la MEME formule que le serveur.
-- Ce que le serveur fait foi (review/review_context.md, contrat v2.1) :
--   - `dir` : sens de marche de la vague de CE cycle, horizontal (Config.WaveTravel pour N / E / S / O) ;
--   - front : Config.WaveFrontD(wave, t) = min(endD, startD + speed * (t - startTime)), par defaut de
--     -REACH a +REACH, REACH = Config.Island.size / 2 + Config.Island.seaMargin ;
--   - le corps occupe l'axe [front - thickness, front] ; le serveur y prend un joueur dont l'axe est dans
--     cette tranche, pieds sous Config.Wave.height, hors de la crique (Config.InCove) ;
--   - phases : warning (7 s d'alerte) -> wave (trajet a 46 studs/s) -> recede (retrait) ; `startD` / `endD`
--     different de -REACH / +REACH pour la seule vague d'intro, qui s'arrete au bord de la crique.
-- Rendu : corps de verre, face avant claire, houle (segments qui roulent, cretes decalees en phase), ombre
-- portee sur le sable, embruns. Pendant l'alerte, la houle se construit deja au point de depart, du bon cote.
-- Cout : toutes les pieces sont creees une fois, une seule boucle RenderStepped qui ne pose que des CFrame
-- et qui dort hors des phases warning / wave / recede. Aucune Instance, aucune table par frame.
-- Sons : WaveService ne joue rien, la vague est donc sonore ici (grondement du depart, mer au passage).
--
-- L'etat de vague est lu dans le contrat (RemoteEvent WaveState) et non dans le Store : le Store normalise
-- encore l'ancienne vague sur Z et perd dir / direction / startD / endD. Tant qu'il ne les expose pas, c'est
-- le seul endroit ou la vraie direction du serveur existe cote client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Wave = {}

local W, ISLAND = Config.Wave, Config.Island
local REACH = ISLAND.size / 2 + ISLAND.seaMargin -- depart et arrivee de la vague (serveur)
local WIDTH = ISLAND.size + 300 -- le mur depasse l'ile : aucun bout visible depuis la plage
local THICK = W.thickness -- 40 : epaisseur du corps, sur l'axe de la vague
local BODY_H = W.height -- 30 : la meme hauteur que le test de prise du serveur
local BODY_TOP = W.height - 2 -- la crete reste sous les plateformes des tours (height + 4)
local BODY_Y = BODY_TOP - BODY_H / 2
local BODY_Z = THICK / 2 -- le corps est derriere le front
local FACE_D = 8 -- epaisseur de la face avant, plus claire
local CREST_H = 5
local CREST_TOP = BODY_TOP + 3 -- l'ecume deborde un peu du corps
local CREST_Y = CREST_TOP - CREST_H / 2
local CREST_Z = BODY_Z -- calee sur le front : l'ecume ne deborde que d'un stud de la tranche reelle
local CREST_T = 0.18
local SHADOW_W = ISLAND.size
local SHADOW_D = THICK + 26
local SHADOW_Y = ISLAND.seaY + 0.12
local SHADOW_Z = BODY_Z + 8
local SHADOW_T = 0.52
local SHADOW_RANGE = ISLAND.size / 2 + 70 -- l'ombre n'existe que sur l'ile

local SEG_HIGH, SEG_LOW = 12, 6 -- segments de houle (graphismes bas : la moitie)
local SWELL_ROLL = 2.1 -- rad/s : la houle roule vers le fond
local SWELL_BREATH = 0.62 -- rad/s : le souffle de toute la ligne de crete
local SWELL_AMP = 4.5 -- +/- studs
local SWELL_ASYM = 0.65 -- la crete s'enfonce plus qu'elle ne depasse : decision du 09/10, la crete
-- visuelle ne doit jamais depasser une plateforme ou l'on est a l'abri (tours a height + 4 = 34)
local WARN_AMP = 0.25 -- amplitude de depart, pendant les 7 s d'alerte
local RECEDE_SINK = 14 -- studs : le mur s'enfonce en se retirant
local NEAR_RANGE = 420 -- au-dela, la houle respire au lieu de rouler (gain de perf)
local ROAR_RANGE = 320 -- le grondement de mer commence a cette distance du front
local ROAR_STEP = 0.05 -- en dessous, on ne retouche pas au volume
local ROAR_RETRY = 5 -- secondes avant de retenter un son absent

local BODY_T, FACE_T = 0.34, 0.42
local COLOR_BODY = Color3.fromRGB(28, 96, 128)
local COLOR_FACE = Color3.fromRGB(126, 196, 214)
local COLOR_FOAM = Color3.fromRGB(228, 242, 248)
local COLOR_GOLD_FACE = Color3.fromRGB(214, 190, 120)
local COLOR_GOLD_FOAM = Color3.fromRGB(255, 238, 190)
local COLOR_SHADOW = Color3.fromRGB(8, 26, 36)
local SPRAY_RATE_HIGH, SPRAY_RATE_LOW = 46, 14

local Util, Settings, Sfx
local player = Players.LocalPlayer

local model: Model? = nil
local body: Part? = nil
local face: Part? = nil
local shadow: Part? = nil
local sprayPart: Part? = nil
local spray: ParticleEmitter? = nil
local segments: { { x: number, phase: number, crest: Part } } = {}
local waterParts: { part: BasePart, transparency: number } = {}
local waterShown, foamShown, shadowShown, lowGraphics = false, false, false, false

local base = CFrame.new(ISLAND.center) -- repere de la vague, remplace quand la direction change
local wave = nil -- etat normalise du dernier WaveState
local roar: any = nil -- grondement de mer (Sfx.Loop)
local roarLevel = 0
local roarRetryAt = 0
local warnedDir = false

---------------------------------------------------------------- Utilitaires
local function warnOnce(message: string)
	if warnedDir then
		return
	end
	warnedDir = true
	warn("[TideClient] " .. message)
end

-- etat brut du serveur -> table propre ; nil si la phase est inconnue ou la direction absente
local function normalizeWave(raw: any)
	if type(raw) ~= "table" then
		return nil
	end
	local phase = raw.phase
	if phase ~= "calm" and phase ~= "warning" and phase ~= "wave" and phase ~= "recede" then
		return nil
	end
	-- dir : horizontal, sens de marche. Repli sur le nom du cycle si le Vector3 n'est pas arrive.
	local dir: Vector3? = nil
	if typeof(raw.dir) == "Vector3" then
		dir = Vector3.new(raw.dir.X, 0, raw.dir.Z)
		if dir.Magnitude < 0.001 then
			dir = nil
		end
	end
	if not dir then
		dir = Config.WaveTravel[raw.direction]
	end
	if not dir then
		warnOnce("vague sans direction : rien n'est affiche")
		return nil
	end
	local function num(value: any, default: number): number
		local n = tonumber(value)
		return if n then n else default
	end
	return {
		phase = phase,
		phaseStart = num(raw.phaseStart, 0),
		phaseEnd = num(raw.phaseEnd, 0),
		startTime = num(raw.startTime, 0),
		cycle = raw.cycle or 0,
		tide = type(raw.tide) == "string" and raw.tide or "Normal",
		intro = raw.intro == true,
		dir = dir.Unit,
		-- absents = valeurs par defaut du serveur, appliquees par Config.WaveFrontD
		startD = tonumber(raw.startD),
		endD = tonumber(raw.endD),
		speed = tonumber(raw.speed),
	}
end

-- repere : X = perpendiculaire a la marche, Y = haut, Z = le dos du front (donc -Z = sens de la vague)
local function setDirection(dir: Vector3)
	base = CFrame.fromMatrix(ISLAND.center, Vector3.new(-dir.Z, 0, dir.X), Vector3.yAxis, -dir)
end

local function setShown(records: { part: BasePart, transparency: number }, shown: boolean)
	for i = 1, #records do
		local rec = records[i]
		rec.part.Transparency = if shown then rec.transparency else 1
	end
end

local function setWater(shown: boolean)
	waterShown = shown
	setShown(waterParts, shown)
	if spray then
		spray.Enabled = false
	end
end

local function setShadow(shown: boolean)
	shadowShown = shown
	shadow.Transparency = if shown then SHADOW_T else 1
end

local function setFoam(shown: boolean)
	foamShown = shown
	local count = if lowGraphics then SEG_LOW else SEG_HIGH
	for i = 1, SEG_HIGH do
		segments[i].crest.Transparency = if shown and i <= count then CREST_T else 1
	end
end

---------------------------------------------------------------- Construction
local function newPart(name: string, size: Vector3, color: Color3, transparency: number, material: Enum.Material): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false -- l'ombre est posee a la main : une vraie ombre ferait doubler le noir
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = material
	p.Size = size
	p.Color = color
	p.Transparency = 1 -- cachees tant qu'aucune vague ne roule
	p.Parent = model
	return p
end

-- Embruns : preset de C s'il existe (Assets.FX.WaveSpray), sinon une gerbe integree, comme Fx.Emit
local function buildSpray(part: Part)
	local template = Util.Find(ReplicatedStorage, "Assets", "FX", "WaveSpray")
	local emitted = 0
	if template and template:IsA("BasePart") then
		for _, child in template:GetChildren() do
			if child:IsA("ParticleEmitter") then
				local clone = child:Clone()
				clone.Enabled = false
				clone.Parent = part
				emitted += 1
			end
		end
	end
	if emitted == 0 then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Spray"
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Rate = SPRAY_RATE_HIGH
		pe.Lifetime = NumberRange.new(0.5, 1.1)
		pe.Speed = NumberRange.new(10, 26)
		pe.SpreadAngle = Vector2.new(32, 32)
		pe.Acceleration = Vector3.new(0, -18, 0)
		pe.Rotation = NumberRange.new(0, 360)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
		pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.LightEmission = 0.6
		pe.Color = ColorSequence.new(COLOR_FOAM)
		pe.Enabled = false
		pe.Parent = part
		spray = pe
		return
	end
	spray = part:FindFirstChildWhichIsA("ParticleEmitter")
end

-- Une seule fois : le mur, sa face, son ombre, ses segments de houle et ses embruns.
local function buildModel()
	local folder = Instance.new("Folder")
	folder.Name = "TR_Wave"
	folder.Parent = workspace

	model = Instance.new("Model")
	model.Name = "Wave"
	model.Parent = folder

	body = newPart("Body", Vector3.new(WIDTH, BODY_H, THICK), COLOR_BODY, BODY_T, Enum.Material.Glass)
	table.insert(waterParts, { part = body, transparency = BODY_T })
	face = newPart("Face", Vector3.new(WIDTH, BODY_H, FACE_D), COLOR_FACE, FACE_T, Enum.Material.Glass)
	table.insert(waterParts, { part = face, transparency = FACE_T })
	-- un seul bloc plat au niveau du sable : suivre le relief demanderait un raycast par frame
	shadow = newPart("Shadow", Vector3.new(SHADOW_W, 0.4, SHADOW_D), COLOR_SHADOW, SHADOW_T, Enum.Material.SmoothPlastic)

	local segW = WIDTH / SEG_HIGH
	for i = 1, SEG_HIGH do
		segments[i] = {
			x = -WIDTH / 2 + segW * (i - 0.5),
			phase = math.random() * math.pi * 2, -- cretes decalees : la ligne n'est jamais reguliere
			crest = newPart("Crest", Vector3.new(segW + 1, CREST_H, THICK + 2), COLOR_FOAM, CREST_T, Enum.Material.SmoothPlastic),
		}
	end

	sprayPart = newPart("SprayAnchor", Vector3.one, COLOR_FOAM, 1, Enum.Material.SmoothPlastic)
	buildSpray(sprayPart)
end

---------------------------------------------------------------- Sons
local function stopRoar()
	if roar then
		roar:Stop(0.8)
		roar = nil
		roarLevel = 0
	end
end

-- Grondement de mer non spatial, volume pilote par la distance du front au joueur (comme la secousse de
-- camera) : on l'entend venir de loin, et il s'eteint une fois le mur passe.
local function updateRoar(w, front: number, now: number)
	local root = Util.LocalRoot(player)
	if not root or w.phase ~= "wave" then
		stopRoar()
		return
	end
	local distance = math.abs(Config.WaveAxis(w, root.Position) - front)
	if distance >= ROAR_RANGE then
		stopRoar()
		return
	end
	local want = 0.25 + 0.75 * (1 - distance / ROAR_RANGE)
	if not roar then
		if now < roarRetryAt then
			return
		end
		roarRetryAt = now + ROAR_RETRY
		local handle = Sfx.Loop("ambientBeach", want)
		if not handle then
			return -- son absent : on retentera plus tard, pas a chaque frame
		end
		roar = handle
		roarLevel = want
		return
	end
	if math.abs(want - roarLevel) > ROAR_STEP then
		roarLevel = want
		roar:SetVolume(want)
	end
end

-- Point du mur de depart le plus proche du joueur : le grondement part du bon cote.
local function incomingPoint(w): Vector3
	local c = ISLAND.center
	local lateral = Vector3.new(-w.dir.Z, 0, w.dir.X)
	local side = 0
	local root = Util.LocalRoot(player)
	if root then
		side = (root.Position.X - c.X) * lateral.X + (root.Position.Z - c.Z) * lateral.Z
	end
	return c + lateral * side + w.dir * ((w.startD or -REACH) + THICK) + Vector3.new(0, 4, 0)
end

local function playDeparture(w)
	local sound = Sfx.Play("waveBoom", { position = incomingPoint(w) })
	if sound then
		-- la houle part de 300 studs : la attenuation par defaut la rendrait muette
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.RollOffMinDistance = 60
		sound.RollOffMaxDistance = 520
	end
end

---------------------------------------------------------------- Phases
local function applyTide(tide: string)
	if not foamShown then
		return
	end
	local golden = tide == "Golden"
	face.Color = if golden then COLOR_GOLD_FACE else COLOR_FACE
	for i = 1, SEG_HIGH do
		segments[i].crest.Color = if golden then COLOR_GOLD_FOAM else COLOR_FOAM
	end
	if spray then
		spray.Color = ColorSequence.new(if golden then COLOR_GOLD_FOAM else COLOR_FOAM)
	end
end

-- Une phase = une seule ecriture d'etat ; le reste est pose par la boucle.
local function onPhase(w, _prev)
	local phase = w.phase
	if phase == "warning" then
		setWater(false) -- rien d'autre que la houle qui se construit, la-bas, du bon cote
		setFoam(true)
		setShadow(false)
	elseif phase == "wave" then
		setWater(true)
		setFoam(true)
		playDeparture(w)
	elseif phase == "recede" then
		setShadow(false) -- le mur s'enfonce : plus d'ombre posee
	elseif phase == "calm" then
		setWater(false)
		setFoam(false)
		setShadow(false)
		stopRoar()
	end
end

local function onWave(raw)
	local nextWave = normalizeWave(raw)
	if not nextWave then
		return
	end
	local prev = wave
	wave = nextWave
	if not prev or prev.dir ~= nextWave.dir then
		setDirection(nextWave.dir)
	end
	if not prev or prev.phase ~= nextWave.phase or prev.cycle ~= nextWave.cycle then
		onPhase(nextWave, prev)
	end
	applyTide(nextWave.tide)
end

---------------------------------------------------------------- Boucle
-- Une seule iteration par frame, et seulement quand la vague existe. Tout est calcule a partir de
-- Config.WaveFrontD, donc le mur est exactement la ou le serveur attrape les joueurs.
local function onRender()
	local w = wave
	if not w or w.phase == "calm" then
		return
	end
	local now = workspace:GetServerTimeNow()
	local front = Config.WaveFrontD(w, now)
	local amp, sink = 1, 0
	if w.phase == "warning" then
		local span = math.max(0.01, w.phaseEnd - w.phaseStart)
		local k = math.clamp((now - w.phaseStart) / span, 0, 1)
		front = w.startD or -REACH -- la houle attend au point de depart
		amp = WARN_AMP + (1 - WARN_AMP) * k
	elseif w.phase == "recede" then
		local span = math.max(0.01, w.phaseEnd - w.phaseStart)
		local k = math.clamp((now - w.phaseStart) / span, 0, 1)
		front -= (front - (w.startD or -REACH)) * k -- retrait vers le point de depart
		sink = -RECEDE_SINK * k
		amp = 1 - k
	end

	-- une seule pose par frame : le repere du front, enTranslations locale (-front = vers l'avant)
	local frame = base + Vector3.new(0, sink, -front)
	body.CFrame = frame * CFrame.new(0, BODY_Y, BODY_Z)
	face.CFrame = frame * CFrame.new(0, BODY_Y, FACE_D / 2)
	shadow.CFrame = frame * CFrame.new(0, SHADOW_Y, SHADOW_Z)
	sprayPart.CFrame = frame * CFrame.new(0, CREST_TOP - 1, CREST_Z)

	-- houle : chaque segment a sa phase, la ligne respire ensemble
	local shared = math.sin(now * SWELL_BREATH)
	local ampNow = SWELL_AMP * amp
	local cam = workspace.CurrentCamera
	local near = cam == nil or math.abs(Config.WaveAxis(w, cam.CFrame.Position) - front) < NEAR_RANGE
	local count = if lowGraphics then SEG_LOW else SEG_HIGH
	for i = 1, count do
		local seg = segments[i]
		local mix
		if near then
			mix = 0.55 * math.sin(now * SWELL_ROLL + seg.phase) + 0.45 * shared
		else
			mix = shared * 0.6
		end
		-- la crete plonge dans le corps et ne ressort que de 35 % : le mur ne depasse jamais les tours
		local dy = ampNow * (mix - SWELL_ASYM * (if mix > 0 then mix else 0))
		seg.crest.CFrame = frame * CFrame.new(seg.x, CREST_Y + dy, CREST_Z)
	end

	-- ombre : seulement sur l'ile, et seulement pendant le passage
	local wantShadow = w.phase == "wave" and math.abs(front) <= SHADOW_RANGE
	if wantShadow ~= shadowShown then
		setShadow(wantShadow)
	end

	if spray then
		spray.Enabled = waterShown and w.phase == "wave" and near and not lowGraphics
	end

	updateRoar(w, front, now)
end

-- Graphismes bas : moitie des segments, embruns coupes. Un seul passage quand le reglage change.
local function applyQuality()
	local low = Settings.IsLowGraphics()
	if low == lowGraphics then
		return
	end
	lowGraphics = low
	setFoam(foamShown)
	if spray then
		spray.Rate = if low then SPRAY_RATE_LOW else SPRAY_RATE_HIGH
	end
end

---------------------------------------------------------------- Demarrage
-- Si l'evenement d'arrive a ete manque (client lent), GetState rend la meme vague ; on ne l'accepte que
-- si rien n'est encore arrive, pour ne jamais revenir en arriere derriere un evenement plus recent.
local function fetchInitialWave(folder: Instance)
	local rf = folder:FindFirstChild("GetState")
	if not rf or not rf:IsA("RemoteFunction") then
		return
	end
	task.spawn(function()
		local ok, _, raw = pcall(rf.InvokeServer, rf)
		if ok and wave == nil then
			onWave(raw)
		end
	end)
end

function Wave.Init(ctx)
	Util, Settings, Sfx = ctx.Util, ctx.Settings, ctx.Sfx
end

function Wave.Start(_ctx)
	buildModel()
	setDirection(Vector3.new(0, 0, 1))
	applyQuality()
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes", 15)
		if not folder then
			return
		end
		local event = folder:WaitForChild("WaveState", 15)
		if event and event:IsA("RemoteEvent") then
			event.OnClientEvent:Connect(onWave)
			fetchInitialWave(folder)
		end
	end)
	RunService.RenderStepped:Connect(onRender)
end

return Wave