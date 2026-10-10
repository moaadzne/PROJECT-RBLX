-- tools/world/build_mutation_fx.luau
-- C : mutations credibles (direction v2) et ambiances de maree.
--  * ReplicatedStorage.Assets.FX.Mutations.<Golden|Night|Storm|Rainbow> : apparence (docs/CREATURES_ART.md §4).
--    Phase 1 : seul Golden est utilise ; les autres sont prets pour la Phase 2.
--  * ReplicatedStorage.Assets.FX.TidePresets.<Normal|Golden|Night|Storm> : valeurs de Lighting que B anime en jeu.
--    Normal = copie de la lumiere actuelle (lancer APRES le reglage de la hero shot) ; les autres = Normal + ecarts.
-- Lancement manuel uniquement (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- Contrat pour B (World.lua applique deja les 4 premiers points) :
--  Mutation : Color (Color3), Material (string, nom d'Enum.Material), Reflectance (number),
--             ApplyTo ("*" = toutes les parties sauf Root), enfants ParticleEmitter a cloner dans Root.
--             ⚠ Material = "Keep" = ne PAS toucher au materiau de la creature, seule la couleur
--             change. Le consomteur doit tester Material ~= "Keep" avant un Enum.Material[...].
--             Sans ce test, Enum.Material["Keep"] vaut nil et casse l'affectation.
--             (Night l'utilise : F 10/10, le SmoothPlastic d'origine donnait un rendu jouet.)
--             En plus (Phase 2) : enfant PointLight "Glow" a cloner dans Root, avec l'attribut Pulse (s) pour la faire respirer ;
--             enfant Beam "Arc" : arcs electriques, deux Attachments au hasard sur la creature, deplaces toutes les ArcInterval s ;
--             attribut HueCycle (s) : irisation, la teinte tourne lentement (saturation basse, IridescentSaturation).
--  TidePreset : un attribut par propriete, nomme "<Classe>_<Propriete>" (ex. Lighting_ClockTime). B tweene vers ces valeurs (2 s).

local DRY_RUN = true

local function seq(a, b)
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b) })
end

-- Mutations : metal et nacre, bioluminescence, arcs electriques, irisation. Jamais de couleur bonbon.
local MUTATIONS = {
	Golden = {
		attrs = { Color = Color3.fromHex("D9A93F"), Material = "Foil", Reflectance = 0.3, ApplyTo = "*" },
		emitters = {
			-- reflets nacres lents, pas de paillettes de dessin anime
			Sheen = { Color = ColorSequence.new(Color3.fromRGB(255, 244, 214), Color3.fromHex("D9A93F")), Rate = 3, Lifetime = NumberRange.new(1.2, 1.8), Size = seq(0.12, 0), Speed = NumberRange.new(0.2, 0.5), LightEmission = 0.5 },
		},
	},
	Night = {
		-- F 10/10 : SmoothPlastic ici donnait exactement le rendu "jouet en plastique" que
		-- DIRECTION_V2 interdit, alors que Night doit etre de la bioluminescence.
		-- Material = "Keep" : on garde le materiau d'origine de la creature, seule la couleur
		-- change. Une carapace qui garde sa matiere et perd sa lumiere, c'est credible.
		attrs = { Color = Color3.fromHex("14222E"), Material = "Keep", Reflectance = 0.05, ApplyTo = "*" },
		emitters = {
			-- plancton bioluminescent qui derive autour de la creature
			Plankton = { Color = ColorSequence.new(Color3.fromHex("3DF5FF")), Rate = 6, Lifetime = NumberRange.new(2, 3), Size = seq(0.1, 0.05), Speed = NumberRange.new(0.1, 0.3), LightEmission = 1, LightInfluence = 0 },
		},
		light = { Color = Color3.fromHex("3DF5FF"), Range = 8, Brightness = 1, Pulse = 2.5 },
	},
	Storm = {
		attrs = { Color = Color3.fromHex("2A2E38"), Material = "Slate", Reflectance = 0, ApplyTo = "*", ArcInterval = 0.25 },
		emitters = {
			Sparks = { Color = ColorSequence.new(Color3.fromHex("C9B8FF")), Rate = 5, Lifetime = NumberRange.new(0.1, 0.2), Size = seq(0.25, 0), Speed = NumberRange.new(2, 4), LightEmission = 1, LightInfluence = 0 },
		},
		arc = { Color = Color3.fromHex("C9B8FF") },
	},
	Rainbow = {
		attrs = { Color = Color3.fromHex("E8E2F0"), Material = "Foil", Reflectance = 0.35, ApplyTo = "*", HueCycle = 6, IridescentSaturation = 0.3 },
		emitters = {
			Sheen = { Color = ColorSequence.new(Color3.fromHex("F4F0FF")), Rate = 3, Lifetime = NumberRange.new(1.2, 1.8), Size = seq(0.12, 0), Speed = NumberRange.new(0.2, 0.5), LightEmission = 0.6 },
		},
	},
}

-- Ecarts des marees par rapport a Normal (number : ajoute ; Color3 : remplace)
local TIDE_DELTAS = {
	Golden = {
		Lighting_ClockTime = 0.4,
		Lighting_Brightness = 0.3,
		BloomEffect_Intensity = 0.2,
		ColorCorrectionEffect_Saturation = 0.06,
		ColorCorrectionEffect_TintColor = Color3.fromRGB(255, 238, 210),
		SunRaysEffect_Intensity = 0.04,
		Atmosphere_Color = Color3.fromHex("E8B86A"),
		Atmosphere_Glare = 0.3,
	},
	Night = {
		Lighting_ClockTime = 3.45, -- vers 20 h 30
		Lighting_Brightness = -0.8,
		ColorCorrectionEffect_TintColor = Color3.fromRGB(215, 228, 255),
		ColorCorrectionEffect_Saturation = -0.1,
		Atmosphere_Color = Color3.fromHex("33496B"),
		Atmosphere_Decay = Color3.fromHex("0D1B2A"),
		Atmosphere_Density = 0.05,
	},
	Storm = {
		Lighting_ClockTime = -1,
		Lighting_Brightness = -0.5,
		ColorCorrectionEffect_Saturation = -0.25,
		ColorCorrectionEffect_Contrast = 0.05,
		ColorCorrectionEffect_TintColor = Color3.fromRGB(225, 230, 238),
		Atmosphere_Color = Color3.fromHex("8C939C"),
		Atmosphere_Density = 0.15,
		Atmosphere_Haze = 1,
		SunRaysEffect_Intensity = -0.04,
	},
}

-- Proprietes copiees depuis la lumiere actuelle
local CAPTURE = {
	Lighting = { "ClockTime", "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation" },
	Atmosphere = { "Density", "Haze", "Glare", "Color", "Decay" },
	BloomEffect = { "Intensity", "Threshold", "Size" },
	ColorCorrectionEffect = { "Brightness", "Contrast", "Saturation", "TintColor" },
	SunRaysEffect = { "Intensity", "Spread" },
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local assets = RS:FindFirstChild("Assets")
assert(assets, "[C] ReplicatedStorage.Assets introuvable")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

local function effectOf(className)
	if className == "Lighting" then
		return Lighting
	end
	-- l'effet de couleur du jeu s'appelle TideColor ; sinon le premier de la classe
	local named = Lighting:FindFirstChild("TideColor")
	if className == "ColorCorrectionEffect" and named and named:IsA("ColorCorrectionEffect") then
		return named
	end
	for _, c in Lighting:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	return nil
end

local function buildMutation(name, def)
	local f = Instance.new("Folder")
	f.Name = name
	for k, v in def.attrs do
		f:SetAttribute(k, v)
	end
	for emitterName, props in def.emitters do
		local e = Instance.new("ParticleEmitter")
		e.Name = emitterName -- texture par defaut de Roblox
		e.Transparency = seq(0, 1)
		e.SpreadAngle = Vector2.new(180, 180)
		for k, v in props do
			e[k] = v
		end
		e.Parent = f
	end
	if def.light then
		local l = Instance.new("PointLight")
		l.Name = "Glow"
		l.Color = def.light.Color
		l.Range = def.light.Range
		l.Brightness = def.light.Brightness
		l.Shadows = false
		l:SetAttribute("Pulse", def.light.Pulse)
		l.Parent = f
	end
	if def.arc then
		local b = Instance.new("Beam")
		b.Name = "Arc"
		b.Color = ColorSequence.new(def.arc.Color)
		b.LightEmission = 1
		b.LightInfluence = 0
		b.FaceCamera = true
		b.Width0 = 0.12
		b.Width1 = 0.05
		b.Segments = 8
		b.CurveSize0 = 1.5
		b.CurveSize1 = -1.5
		b.Parent = f
	end
	return f
end

local function build()
	-- 1. Mutations
	local mutations = not DRY_RUN and folder(folder(assets, "FX"), "Mutations") or nil
	for name, def in MUTATIONS do
		log(string.format("Mutations.%s : %s, %s", name, def.attrs.Material, tostring(def.attrs.Color)))
		if mutations then
			local old = mutations:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			buildMutation(name, def).Parent = mutations
		end
	end

	-- 2. Presets de marée
	local normal = {}
	for className, props in CAPTURE do
		local inst = effectOf(className)
		if not inst then
			warn("[C] " .. className .. " absent de Lighting : non capture")
			continue
		end
		for _, prop in props do
			normal[className .. "_" .. prop] = inst[prop]
		end
	end
	local presets = { Normal = normal }
	for tide, deltas in TIDE_DELTAS do
		local values = table.clone(normal)
		for key, delta in deltas do
			if values[key] == nil then
				continue
			end
			if typeof(delta) == "number" then
				values[key] += delta
			else
				values[key] = delta
			end
		end
		presets[tide] = values
		log("TidePresets." .. tide .. " = Normal + ecarts")
	end
	if not DRY_RUN then
		local tideFolder = folder(folder(assets, "FX"), "TidePresets")
		for name, values in presets do
			local old = tideFolder:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			local f = Instance.new("Folder")
			f.Name = name
			for key, value in values do
				f:SetAttribute(key, value)
			end
			f.Parent = tideFolder
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : mutations et marees")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("presets crees. Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
