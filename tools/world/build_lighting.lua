-- tools/world/build_lighting.lua
-- C : Lighting niveau visé (Fortnite / Sea of Thieves stylisé) — DA_MONDE.md §5, DIRECTION_V2, DECISIONS_MARCHE.md agent N.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
-- Configure : Lighting, Atmosphere, Bloom, ColorCorrection, SunRays, MaterialService, Sky.
-- Cross-platform : ShadowMap PC, désactivé mobile (Config.CrossPlatform.ShadowsMobile).

local DRY_RUN = true

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Palette DA (docs/DA_MONDE.md §3 + agent N 5 zones)
local PALETTE = {
	-- Eau
	waterColor = Color3.fromHex("1A7AA6"),
	waterTransparency = 0.4,
	waveSize = 0.8,
	waveSpeed = 8,
	-- Sable
	sandDry = Color3.fromHex("E8D5B7"),
	sandWet = Color3.fromHex("BFA892"),
	-- Roche volcanique
	rockDark = Color3.fromHex("3B3633"),
	rockLight = Color3.fromHex("5A524C"),
	-- Corail
	coral = Color3.fromHex("FF6B35"),
	-- Bois flotté
	driftwood = Color3.fromHex("7D6E60"),
	-- Végétation
	vegDark = Color3.fromHex("3F6B3A"),
	vegLight = Color3.fromHex("6C8F4A"),
	-- Ciel / couchant
	skyTop = Color3.fromHex("0B1418"),
	skyHorizon = Color3.fromHex("F2A35E"),
	sunColor = Color3.fromHex("FFD166"),
}

local function applyLighting()
	log("Lighting Technology = Future")
	Lighting.Technology = Enum.Technology.Future

	log("Atmosphere : Density=0.3, Haze=2, Glare=1, Color=#3B3633, Decay=#13707A")
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.3
	atm.Haze = 2
	atm.Glare = 1
	atm.Color = PALETTE.rockDark
	atm.Decay = Color3.fromHex("13707A")
	atm.Parent = Lighting

	log("Bloom : Intensity=0.5, Threshold=1.5, Size=24")
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.5
	bloom.Threshold = 1.5
	bloom.Size = 24
	bloom.Parent = Lighting

	log("ColorCorrection : Saturation=1.1, Contrast=0.1, Tint=#F2A35E (couchant)")
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Saturation = 1.1
	cc.Contrast = 0.1
	cc.TintColor = PALETTE.skyHorizon
	cc.Parent = Lighting

	log("SunRays : Intensity=0.15, Spread=0.5")
	local sr = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	sr.Intensity = 0.15
	sr.Spread = 0.5
	sr.Parent = Lighting

	log("Sky : CelestialBodiesShown=false, MoonTextureId="", SunTextureId="", SkyboxBk/Ft/Lf/Rt/Up=skyTop")
	local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	sky.CelestialBodiesShown = false
	sky.MoonTextureId = ""
	sky.SunTextureId = ""
	sky.SkyboxBk = "rbxassetid://0"
	sky.SkyboxFt = "rbxassetid://0"
	sky.SkyboxLf = "rbxassetid://0"
	sky.SkyboxRt = "rbxassetid://0"
	sky.SkyboxUp = "rbxassetid://0"
	sky.Parent = Lighting

	-- Heure : couchant (17h05) pour hero shot, mais cycle dynamique en jeu
	Lighting.ClockTime = 17.05
	Lighting.GeographicLatitude = 15
end

local function applyMaterialService()
	log("MaterialService : variants eau, sable, roche, corail, bois")
	-- Eau : variant custom pour lagon + ocean
	local waterVariant = MaterialService:FindFirstChild("Water_TideRush") or Instance.new("MaterialVariant")
	waterVariant.Name = "Water_TideRush"
	waterVariant.BaseMaterial = Enum.Material.Water
	waterVariant.DisplayName = "TideRush Water"
	waterVariant.Color = PALETTE.waterColor
	waterVariant.Roughness = 0.1
	waterVariant.Metalness = 0.0
	waterVariant.Parent = MaterialService

	-- Sable sec
	local sandDry = MaterialService:FindFirstChild("Sand_TideRush_Dry") or Instance.new("MaterialVariant")
	sandDry.Name = "Sand_TideRush_Dry"
	sandDry.BaseMaterial = Enum.Material.Sand
	sandDry.DisplayName = "TideRush Sand Dry"
	sandDry.Color = PALETTE.sandDry
	sandDry.Roughness = 0.9
	sandDry.Metalness = 0.0
	sandDry.Parent = MaterialService

	-- Sable mouillé
	local sandWet = MaterialService:FindFirstChild("Sand_TideRush_Wet") or Instance.new("MaterialVariant")
	sandWet.Name = "Sand_TideRush_Wet"
	sandWet.BaseMaterial = Enum.Material.Sand
	sandWet.DisplayName = "TideRush Sand Wet"
	sandWet.Color = PALETTE.sandWet
	sandWet.Roughness = 0.3
	sandWet.Metalness = 0.0
	sandWet.Parent = MaterialService

	-- Roche volcanique
	local rockVar = MaterialService:FindFirstChild("Rock_TideRush_Volcanic") or Instance.new("MaterialVariant")
	rockVar.Name = "Rock_TideRush_Volcanic"
	rockVar.BaseMaterial = Enum.Material.Rock
	rockVar.DisplayName = "TideRush Volcanic Rock"
	rockVar.Color = PALETTE.rockDark
	rockVar.Roughness = 0.85
	rockVar.Metalness = 0.05
	rockVar.Parent = MaterialService

	-- Corail
	local coralVar = MaterialService:FindFirstChild("Coral_TideRush") or Instance.new("MaterialVariant")
	coralVar.Name = "Coral_TideRush"
	coralVar.BaseMaterial = Enum.Material.Coral
	coralVar.DisplayName = "TideRush Coral"
	coralVar.Color = PALETTE.coral
	coralVar.Roughness = 0.7
	coralVar.Metalness = 0.0
	coralVar.Parent = MaterialService

	-- Bois flotté
	local woodVar = MaterialService:FindFirstChild("Wood_TideRush_Driftwood") or Instance.new("MaterialVariant")
	woodVar.Name = "Wood_TideRush_Driftwood"
	woodVar.BaseMaterial = Enum.Material.Wood
	woodVar.DisplayName = "TideRush Driftwood"
	woodVar.Color = PALETTE.driftwood
	woodVar.Roughness = 0.8
	woodVar.Metalness = 0.0
	woodVar.Parent = MaterialService
end

local function applyCrossPlatformShadows()
	-- Config.CrossPlatform.ShadowsMobile (defaut false) lu par le client au runtime.
	-- Ici on active ShadowMap globalement (PC). Le client mobile le desactivera via LocalScript.
	log("Lighting.GlobalShadows = true (ShadowMap) — mobile le desactivera cote client")
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.3
end

local function run()
	if DRY_RUN then
		log("DRY_RUN : Lighting, Atmosphere, Bloom, CC, SunRays, MaterialService, Sky, Shadows")
		log("  Technology=Future, Atmosphere(d=0.3,h=2,g=1), Bloom(0.5), CC(sat=1.1,con=0.1), SunRays(0.15)")
		log("  MaterialVariants: Water, Sand Dry/Wet, Rock Volcanic, Coral, Driftwood")
		log("  CrossPlatform: ShadowMap PC, mobile desactive cote client (Config.CrossPlatform.ShadowsMobile=false)")
		return
	end

	local rec = CHS:TryBeginRecording("C : Lighting niveau vise")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		applyLighting()
		applyMaterialService()
		applyCrossPlatformShadows()
	end)
	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Lighting niveau vise applique. Hero shot pret (ClockTime=17.05).")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()