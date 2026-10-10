-- CreatureRenderer : animations Rthro (bundle 356) + effets Hero Titan pour les creatures.
-- Requis : World.lua gere deja l'echelle du stade (ScaleTo) et les mutations (Assets.FX.Mutations).
-- Ce module ajoute : idle/walk/swim/carry/mount/surf via Animator, et effets permanents Titan.
-- Une seule boucle RenderStepped, seulement pour les creatures proches de la camera (<= 120 studs).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CreatureRenderer = {}

local CREATURE_TAG = "TR_Creature" -- ajoute par CreatureFactory cote serveur
local ANIMATE_RADIUS = 120 -- studs : au-dela, pas d'animation (performance mobile)
local TITAN_SCALE = 1.5 -- Config.Stages[4].scale

-- Animations Rthro (bundle 356) - AssetIds a remplir apres import
-- Importer le pack Rthro (356) dans Studio, puis copier les Animation objects dans ReplicatedStorage.Assets.Animations.RthroBundle356
local ANIMATION_IDS = {
	idle = 0,       -- Rthro Idle
	walk = 0,       -- Rthro Walk
	swim = 0,       -- Rthro Swim (ou custom)
	carry = 0,      -- Rthro Carry (porter objet)
	mount = 0,      -- Rthro Mount (assis)
	surf = 0,       -- Rthro Surf (debout, equilibre)
}

local LOADED_ANIMATIONS = {} -- [AnimationId] = AnimationTrack (cache)
local TRACKED_CREATURES = {} -- [Model] = { animator, tracks, isTitan, isHero, heroEffects }
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local isLowGraphics = false

-- Helper : charger une animation depuis Assets.Animations.RthroBundle356
local function loadAnimation(animName: string): AnimationTrack?
	local animId = ANIMATION_IDS[animName]
	if animId == 0 then
		-- Fallback : chercher dans Assets.Animations.RthroBundle356 par nom
		local animFolder = ReplicatedStorage:FindFirstChild("Assets")
		animFolder = animFolder and animFolder:FindFirstChild("Animations")
		animFolder = animFolder and animFolder:FindFirstChild("RthroBundle356")
		if animFolder then
			local anim = animFolder:FindFirstChild(animName)
			if anim and anim:IsA("Animation") then
				animId = anim.AnimationId
				ANIMATION_IDS[animName] = animId
			end
		end
	end
	if animId == 0 or animId == "" then
		return nil
	end
	if LOADED_ANIMATIONS[animId] then
		return LOADED_ANIMATIONS[animId]
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = animId
	-- On cree un Animator temporaire pour charger le track, puis on le detruit
	local tempAnimator = Instance.new("Animator")
	local track = tempAnimator:LoadAnimation(animation)
	tempAnimator:Destroy()
	LOADED_ANIMATIONS[animId] = track
	return track
end

-- Helper : jouer une animation sur un Animator (avec fade)
local function playAnimation(animator: Animator, animName: string, fadeTime: number?): AnimationTrack?
	local track = loadAnimation(animName)
	if not track then
		return nil
	end
	local clone = track:Clone()
	clone.Priority = Enum.AnimationPriority.Movement
	clone:Play(fadeTime or 0.1)
	return clone
end

-- Helper : arreter une animation
local function stopAnimation(track: AnimationTrack?, fadeTime: number?)
	if track and track.IsPlaying then
		track:Stop(fadeTime or 0.1)
	end
end

-- Detecter si une creature est un Titan (stade 4)
local function isTitan(model: Model): boolean
	local stage = model:GetAttribute("Stage")
	return stage == 4
end

-- Detecter si c'est la creature "Hero" (Titan montable avec effets permanents)
-- Hero = Titan montable (HawksbillTurtle, LeopardRay, MantaRay, WhaleShark) avec mutation Golden
local function isHeroTitan(model: Model): boolean
	if not isTitan(model) then
		return false
	end
	local species = model:GetAttribute("CreatureId")
	local mutation = model:GetAttribute("Mutation")
	local mountable = Config.Mount and Config.Mount.species and Config.Mount.species[species]
	return mountable == true and mutation == "Golden"
end

-- Appliquer les effets permanents Hero Titan
local function applyHeroEffects(model: Model, rec)
	if rec.heroEffectsApplied then
		return
	end
	rec.heroEffectsApplied = true

	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root then
		return
	end

	-- 1. Aura dorée permanente (PointLight + Beam comme Royal mais plus subtil)
	local glow = Instance.new("PointLight")
	glow.Name = "HeroGlow"
	glow.Color = Color3.fromHex("FFC93C")
	glow.Range = 12
	glow.Brightness = 1
	glow.Shadows = false
	glow.Parent = root

	-- 2. Particules d'or tourbillonnantes (plus lent que Golden normal)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "HeroTrail"
	emitter.Color = ColorSequence.new(Color3.fromHex("FFD966"), Color3.fromHex("FFC93C"))
	emitter.LightEmission = 1
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 8
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.Parent = root
	CollectionService:AddTag(emitter, "TR_HeroEffect")

	-- 3. Beam vertical subtil (comme RarityBeam mais or)
	local fxFolder = ReplicatedStorage:FindFirstChild("Assets")
	fxFolder = fxFolder and fxFolder:FindFirstChild("FX")
	local rarityBeam = fxFolder and fxFolder:FindFirstChild("RarityBeam")
	if rarityBeam then
		for _, name in ipairs({ "Core", "Halo" }) do
			local beam = rarityBeam:FindFirstChild(name, true)
			if beam and beam:IsA("Beam") then
				local clone = beam:Clone()
				clone.Name = "Hero" .. name
				clone.Color = ColorSequence.new(Color3.fromHex("FFC93C"))
				clone.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
				clone.Parent = root
				CollectionService:AddTag(clone, "TR_HeroEffect")
				-- Attachments BeamA/BeamB sont deja sur Root (crees par CreatureFactory via addBeacon pour Epic/Legendary)
			end
		end
	end

	rec.heroEffects = { glow, emitter }
end

-- Retirer les effets Hero
local function removeHeroEffects(rec)
	if not rec.heroEffectsApplied then
		return
	end
	rec.heroEffectsApplied = false
	if rec.heroEffects then
		for _, effect in rec.heroEffects do
			if effect and effect.Parent then
				effect:Destroy()
			end
		end
		rec.heroEffects = nil
	end
	-- Nettoyer les beams tags
	for _, beam in model:GetDescendants() do
		if beam:IsA("Beam") and CollectionService:HasTag(beam, "TR_HeroEffect") then
			beam:Destroy()
		end
	end
end

-- Appliquer l'animation selon l'etat de la creature
local function updateAnimation(model: Model, rec, now: number, isMoving: boolean, isInWater: boolean, isCarrying: boolean, isMounted: boolean, isSurfing: boolean)
	local animator = rec.animator
	if not animator then
		return
	end

	-- Priorité des animations : surf > mount > carry > swim > walk > idle
	local targetAnim
	local fadeTime = 0.15

	if isSurfing then
		targetAnim = "surf"
	elseif isMounted then
		targetAnim = "mount"
	elseif isCarrying then
		targetAnim = "carry"
	elseif isInWater then
		targetAnim = "swim"
	elseif isMoving then
		targetAnim = "walk"
	else
		targetAnim = "idle"
	end

	if rec.currentAnim ~= targetAnim then
		-- Arreter l'ancienne
		if rec.currentTrack then
			stopAnimation(rec.currentTrack, fadeTime)
		end
		-- Jouer la nouvelle
		rec.currentTrack = playAnimation(animator, targetAnim, fadeTime)
		rec.currentAnim = targetAnim
	end
end

-- Suivre une creature
local function trackCreature(model: Model)
	if not model:IsA("Model") or TRACKED_CREATURES[model] then
		return
	end
	if not model:GetAttribute("CreatureId") then
		return -- pas une creature valide
	end

	local animator = Instance.new("Animator")
	animator.Parent = model

	local rec = {
		model = model,
		animator = animator,
		currentAnim = nil,
		currentTrack = nil,
		isTitan = isTitan(model),
		isHero = isHeroTitan(model),
		heroEffectsApplied = false,
		lastPos = model:GetPivot().Position,
	}

	TRACKED_CREATURES[model] = rec

	-- Appliquer effets Hero si c'en est un
	if rec.isHero then
		applyHeroEffects(model, rec)
	end

	-- Nettoyage quand la creature est detruite
	model.Destroying:Connect(function()
		untrackCreature(model)
	end)
end

local function untrackCreature(model: Model)
	local rec = TRACKED_CREATURES[model]
	if not rec then
		return
	end
	if rec.currentTrack then
		stopAnimation(rec.currentTrack)
	end
	if rec.heroEffectsApplied then
		removeHeroEffects(rec)
	end
	if rec.animator then
		rec.animator:Destroy()
	end
	TRACKED_CREATURES[model] = nil
end

-- Mettre a jour toutes les creatures suivies
local function onRenderStepped(dt: number)
	if not camera then
		return
	end
	local camPos = camera.CFrame.Position
	local now = os.clock()
	local reducedMotion = false -- TODO: lire depuis Settings.Get("reducedMotion")

	for model, rec in TRACKED_CREATURES do
		-- Distance check pour performance
		local pivot = model:GetPivot()
		local dist = (pivot.Position - camPos).Magnitude
		if dist > ANIMATE_RADIUS then
			-- Trop loin : arreter l'animation en cours
			if rec.currentTrack then
				stopAnimation(rec.currentTrack)
				rec.currentTrack = nil
				rec.currentAnim = nil
			end
			continue
		end

		-- Detecter mouvement
		local isMoving = (pivot.Position - rec.lastPos).Magnitude > 0.1
		rec.lastPos = pivot.Position

		-- Detecter etats (a affiner selon le contexte : piscine, monture, etc.)
		local isInWater = pivot.Position.Y < 5 -- approximation : Y < 5 = dans l'eau
		local isCarrying = model:GetAttribute("Carried") == true
		local isMounted = model:GetAttribute("Mounted") == true
		local isSurfing = model:GetAttribute("Surfing") == true

		-- Mettre a jour Hero Titan (peut devenir Hero si mutation Golden ajoutee)
		local heroNow = isHeroTitan(model)
		if heroNow and not rec.isHero then
			rec.isHero = true
			applyHeroEffects(model, rec)
		elseif not heroNow and rec.isHero then
			rec.isHero = false
			removeHeroEffects(rec)
		end

		if not reducedMotion then
			updateAnimation(model, rec, now, isMoving, isInWater, isCarrying, isMounted, isSurfing)
		end
	end
end

-- Initialiser : tagger les creatures existantes et ecouter les nouvelles
function CreatureRenderer.Init()
	-- Taguer les creatures existantes (workspace.Creatures + Map.Plots.*.Display)
	for _, model in CollectionService:GetTagged(CREATURE_TAG) do
		trackCreature(model)
	end
	CollectionService:GetInstanceAddedSignal(CREATURE_TAG):Connect(trackCreature)
	CollectionService:GetInstanceRemovedSignal(CREATURE_TAG):Connect(untrackCreature)

	-- Aussi suivre les creatures des bassins (Display) qui n'ont pas le tag
	task.spawn(function()
		local plots = workspace:WaitForChild("Map", 10)
		plots = plots and plots:WaitForChild("Plots", 5)
		if not plots then
			return
		end
		for _, plot in plots:GetChildren() do
			local display = plot:FindFirstChild("Display")
			if display then
				for _, model in display:GetChildren() do
					trackCreature(model)
				end
				display.ChildAdded:Connect(trackCreature)
				display.ChildRemoved:Connect(untrackCreature)
			end
		end
	end)

	RunService.RenderStepped:Connect(onRenderStepped)
end

-- API pour forcer une animation (ex: lors d'une capture)
function CreatureRenderer.PlayCaptureAnimation(model: Model)
	local rec = TRACKED_CREATURES[model]
	if not rec or not rec.animator then
		return
	end
	local track = playAnimation(rec.animator, "carry", 0.05) -- carry comme "prise"
	if track then
		task.delay(0.5, function()
			stopAnimation(track, 0.1)
		end)
	end
end

-- API pour le son unique Hero Titan (appele par MountButton/Surf quand le joueur monte)
function CreatureRenderer.PlayHeroSound(model: Model)
	if not isHeroTitan(model) then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("Root")
	if not root then
		return
	end
	-- Son unique Hero : grave, resonnant (a importer dans Assets.Sounds.heroMount)
	local sound = Instance.new("Sound")
	sound.Name = "HeroMountSound"
	sound.SoundId = "rbxassetid://0" -- TODO: remplacer par vrai ID
	sound.Volume = 0.8
	sound.PlaybackSpeed = 0.9
	sound.Parent = root
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return CreatureRenderer