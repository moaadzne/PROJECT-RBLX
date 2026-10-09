-- tools/world/build_mutation_fx.luau
-- C : presets Golden (P1-11).
--  * ReplicatedStorage.Assets.FX.Mutations.Golden : apparence de la mutation (docs/CREATURES_ART.md §4)
--  * ReplicatedStorage.Assets.FX.TidePresets.Normal / Golden : valeurs de Lighting que B anime en jeu
--    Normal = copie de la lumiere actuelle (lancer APRES le reglage de la hero shot) ; Golden = Normal + ecarts.
-- Lancement manuel uniquement (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- Contrat pour B (attributs) :
--  Mutation : Color (Color3), Material (string, nom d'Enum.Material), Reflectance (number),
--             ApplyTo (string : nom de la partie, ou "*" pour toutes) ; enfants ParticleEmitter a cloner dans Root.
--  TidePreset : un attribut par propriete, nomme "<Classe>_<Propriete>" (ex. Lighting_ClockTime,
--             Atmosphere_Color, BloomEffect_Intensity, ColorCorrectionEffect_TintColor). B tweene vers ces valeurs (2 s).

local DRY_RUN = true

local GOLD = Color3.fromHex("FFC93C")

-- Ecarts de la Golden Tide par rapport a Normal (number : ajoute ; Color3 : remplace)
local GOLDEN_DELTA = {
	Lighting_ClockTime = 0.45,
	Lighting_Brightness = 0.3,
	BloomEffect_Intensity = 0.2,
	ColorCorrectionEffect_Saturation = 0.12,
	ColorCorrectionEffect_TintColor = Color3.fromRGB(255, 236, 205),
	SunRaysEffect_Intensity = 0.04,
	Atmosphere_Color = Color3.fromHex("FFC97A"),
	Atmosphere_Glare = 0.3,
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

local function build()
	-- 1. Mutation Golden
	log("Assets.FX.Mutations.Golden : Foil #FFC93C, Reflectance 0.15, Sparkle Rate 4")
	if not DRY_RUN then
		local mutations = folder(folder(assets, "FX"), "Mutations")
		local old = mutations:FindFirstChild("Golden")
		if old then
			old:Destroy()
		end
		local golden = Instance.new("Folder")
		golden.Name = "Golden"
		golden:SetAttribute("Color", GOLD)
		golden:SetAttribute("Material", "Foil")
		golden:SetAttribute("Reflectance", 0.15)
		golden:SetAttribute("ApplyTo", "Body")
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Name = "Sparkle" -- texture par defaut de Roblox (etincelles)
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 240, 170), GOLD)
		sparkle.LightEmission = 0.6
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.18), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
		sparkle.Lifetime = NumberRange.new(0.8, 1.2)
		sparkle.Rate = 4
		sparkle.Speed = NumberRange.new(0.5, 1)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Parent = golden
		golden.Parent = mutations
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
	local golden = table.clone(normal)
	for key, delta in GOLDEN_DELTA do
		if golden[key] == nil then
			continue
		end
		if typeof(delta) == "number" then
			golden[key] += delta
		else
			golden[key] = delta
		end
	end
	for key, value in golden do
		log(string.format("  Golden %s = %s (Normal %s)", key, tostring(value), tostring(normal[key])))
	end
	if not DRY_RUN then
		local presets = folder(folder(assets, "FX"), "TidePresets")
		for name, values in { Normal = normal, Golden = golden } do
			local old = presets:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			local f = Instance.new("Folder")
			f.Name = name
			for key, value in values do
				f:SetAttribute(key, value)
			end
			f.Parent = presets
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : presets Golden")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("presets crees. Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
