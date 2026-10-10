-- tools/world/build_lighting.luau
-- N : lumiere et eau FINALES du jeu (brief D du 12/10, valide).
-- Distinct de build_hero_shot.luau : celui-ci donne le preset "capture" de la hero shot
-- (docs/DA_MONDE.md §5), celui-la donne la lumiere de JEU, celle dans laquelle on joue.
-- Ordre : apres build_lagoon.luau et build_wave.luau, avant build_mutation_fx.luau
-- (les presets de maree de build_mutation_fx.luau partent de CES valeurs).
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- ⚠ Lighting.Technology n'est PAS modifiable par script : Moaad doit la passer en
-- Future a la main (une seule fois, dans les proprietes du place). Le script verifie
-- et previent si ce n'est pas fait : sans Future, Atmosphere et les ombres douces
-- ne rendent pas comme prevu.

local DRY_RUN = true

-- Lumiere de jeu : coucher de soleil, chaude, contraste leger (brief D 12/10).
-- Valeurs differentes de la hero shot : ici on joue, pas on capture.
local LIGHT = {
	Lighting = { ClockTime = 17, GeographicLatitude = 15 },
	Atmosphere = { Density = 0.3, Haze = 2, Glare = 1, Color = Color3.fromHex("F2A35E"), Decay = Color3.fromHex("13707A") },
	BloomEffect = { Intensity = 0.5, Size = 24, Threshold = 1.2 },
	SunRaysEffect = { Intensity = 0.3, Spread = 1 },
	ColorCorrectionEffect = { Saturation = 1.1, Contrast = 0.1, Brightness = 0.02, TintColor = Color3.fromRGB(255, 240, 224) },
}

-- Eau (Terrain). L'ocean du jeu ; les lagons ont leur propre eau dans build_lagoon.luau.
local WATER = {
	WaterColor = Color3.fromHex("1a7aa6"),
	WaterTransparency = 0.4,
	WaterWaveSize = 0.8,
	WaterWaveSpeed = 8,
	WaterReflectance = 0.3,
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChild("Terrain")

assert(not RunService:IsRunning(), "[N] a lancer en mode edition, pas en Play")
assert(Terrain, "[N] workspace.Terrain introuvable")

local function log(msg)
	print((DRY_RUN and "[N][DRY] " or "[N] ") .. msg)
end

-- Cree l'effet s'il manque, ou renvoie celui qui existe (on ne duplique jamais).
local function effect(className)
	for _, c in Lighting:GetChildren() do
		if c.ClassName == className then
			return c
		end
	end
	if DRY_RUN then
		return nil
	end
	local e = Instance.new(className)
	e.Parent = Lighting
	log("  cree " .. className)
	return e
end

local function build()
	for className, props in LIGHT do
		local target = className == "Lighting" and Lighting or effect(className)
		for prop, value in props do
			log(string.format("  %s.%s = %s", className, prop, tostring(value)))
			if target and not DRY_RUN then
				target[prop] = value
			end
		end
	end
	for prop, value in WATER do
		log(string.format("  Terrain.%s = %s", prop, tostring(value)))
		if not DRY_RUN then
			Terrain[prop] = value
		end
	end
	if Lighting.Technology ~= Enum.Technology.Future then
		warn("[N] Lighting.Technology = " .. Lighting.Technology.Name .. " : Moaad doit la passer en Future a la main")
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("N : lumiere et eau finales")
	assert(rec, "[N] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("lumiere et eau appliquees. Ctrl+Z annule tout. Puis build_mutation_fx.luau (presets de maree calques sur ces valeurs).")
	else
		warn("[N] erreur, tout est annule : " .. tostring(err))
	end
end
