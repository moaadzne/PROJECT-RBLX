-- tools/world/build_zone_palettes.luau
-- N : les 5 zones de l'archipel — palettes distinctes et ambiance propre a chacune
-- (CYCLE 1 point 2, brief D "taches infinies N"). Source unique des couleurs par zone :
-- le dossier cree ici, Map.ZonePalettes, est lu par B (ambiance de zone), K (FX) et le client.
-- Ordre : apres build_lighting.luau, avant build_mutation_fx.luau (les marees se calent
-- sur la lumiere de base, pas sur les ambiances de zone).
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--
-- Ce que le script fait :
--  1. Couleurs globales des materiaux (MaterialService) : sable, roche volcanique, mousse, vase.
--     Une seule valeur par materiau, donc les zones sont distinguees surtout par les accents,
--     l'eau et la lumiere (on ne peut pas colorer le terrain par zone).
--  2. Map.ZonePalettes : un Configuration par zone, avec les attributs de palette
--     (Water, Sand, Accent, Coral, Foam) et les ecarts d'ambiance pour B
--     (Atmosphere_Color, Atmosphere_Density, Atmosphere_Haze, ColorCorrection_Saturation,
--      ColorCorrection_Contrast, SunRays_Intensity, Lighting_Brightness).
--     B tweene vers ces valeurs (2 s) quand le joueur entre dans la zone.
--  3. Voiles d'eau teintes par zone (ZONE_WATER) : la ou l'eau doit etre d'une autre couleur
--     que l'ocean #1a7aa6. Positions a relever avec inspect_world.luau ; nil = pas de voile.

local DRY_RUN = true

-- ═══════════════════════════════════════════════════════════════════════════
-- LES 5 ZONES. Regle DIRECTION_V2 : 80 % de tons naturels, les accents se remarquent.
--   Crique  : le berceau, turquoise chaud, ecume blanche. Lisible, rassurant.
--   Dunes   : sable clair et or, soleil haut, soleil rasant et glorieux.
--   Recif   : corail et rose, sature, la vie. Le piege aussi (on s'y fait prendre).
--   Falaise : gris volcanique et vert mousse,Contraste froid, le vent, le danger.
--   Epave   : bleu nuit et argent, brume dense, le mystere (event Leviathan ~1/h).
-- ═══════════════════════════════════════════════════════════════════════════

local ZONES = {
	{
		name = "Crique",
		-- ambiances : ecarts par rapport a la lumiere de base (build_lighting.luau)
		ambiance = {
			Atmosphere_Color = Color3.fromHex("F2A35E"),
			Atmosphere_Density = 0.3, Atmosphere_Haze = 2, Atmosphere_Glare = 1,
			ColorCorrection_Saturation = 1.0, ColorCorrection_Contrast = 0.05,
			SunRays_Intensity = 0.3, Lighting_Brightness = 1,
		},
		palette = { Water = "1a7aa6", Sand = "e8d5b7", Accent = "EEF5F2", Coral = "D9776A", Foam = "EEF5F2" },
	},
	{
		name = "Dunes",
		ambiance = {
			Atmosphere_Color = Color3.fromHex("F7C88A"),
			Atmosphere_Density = 0.22, Atmosphere_Haze = 2.6, Atmosphere_Glare = 1.2,
			ColorCorrection_Saturation = 1.05, ColorCorrection_Contrast = 0.12,
			SunRays_Intensity = 0.5, Lighting_Brightness = 1.2,
		},
		palette = { Water = "2FB8B3", Sand = "e8d5b7", Accent = "D9A93F", Coral = "E8CF9A", Foam = "F2EFDF" },
	},
	{
		name = "Recif",
		ambiance = {
			Atmosphere_Color = Color3.fromHex("E8927C"),
			Atmosphere_Density = 0.28, Atmosphere_Haze = 1.8, Atmosphere_Glare = 0.8,
			ColorCorrection_Saturation = 1.2, ColorCorrection_Contrast = 0.05,
			SunRays_Intensity = 0.2, Lighting_Brightness = 1,
		},
		palette = { Water = "1a7aa6", Sand = "E6C79E", Accent = "ff6b35", Coral = "D9776A", Foam = "F6D9C8" },
	},
	{
		name = "Falaise",
		ambiance = {
			Atmosphere_Color = Color3.fromHex("9FB4B0"),
			Atmosphere_Density = 0.38, Atmosphere_Haze = 2.2, Atmosphere_Glare = 0.6,
			ColorCorrection_Saturation = 0.85, ColorCorrection_Contrast = 0.15,
			SunRays_Intensity = 0.15, Lighting_Brightness = 0.9,
		},
		palette = { Water = "0D3B4C", Sand = "A8998A", Accent = "3F6B3A", Coral = "5A7A6A", Foam = "DCE6E2" },
	},
	{
		name = "Epave",
		ambiance = {
			Atmosphere_Color = Color3.fromHex("2E4A66"),
			Atmosphere_Density = 0.5, Atmosphere_Haze = 2.8, Atmosphere_Glare = 0.4,
			ColorCorrection_Saturation = 0.75, ColorCorrection_Contrast = 0.18,
			SunRays_Intensity = 0.08, Lighting_Brightness = 0.75,
		},
		palette = { Water = "0D2A33", Sand = "6B7A85", Accent = "A7B0BA", Coral = "3F5A6A", Foam = "AEBFC9" },
	},
}

-- Couleurs globales des materiaux du terrain (MaterialService, mode edition).
local MATERIAL_COLORS = {
	Sand = Color3.fromHex("e8d5b7"), -- sable sec (base de tout l'archipel)
	Rock = Color3.fromHex("3B3633"), -- roche volcanique sombre (falaises)
	Ground = Color3.fromHex("3F6B3A"), -- mousse des falaises
	Mud = Color3.fromHex("A58C66"), -- sable mouille / vase
}

-- Voiles d'eau teintes par zone : { zone, centre, rayon }. nil = pas de voile ici.
-- Le recif a une eau plus chaude (corail), l'epave une eau tres sombre.
-- Positions a confirmer avec inspect_world.luau apres la pose des points d'interet.
local ZONE_WATER = {
	{ zone = "Recif", pos = Vector3.new(150, -0.4, -220), radius = 60 }, -- POI sud, a confirmer
	{ zone = "Epave", pos = Vector3.new(-220, -0.4, 40), radius = 45 }, -- POI ouest, a confirmer
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local MaterialService = game:GetService("MaterialService")
local Lighting = game:GetService("Lighting")

assert(not RunService:IsRunning(), "[N] a lancer en mode edition, pas en Play")

local function log(msg)
	print((DRY_RUN and "[N][DRY] " or "[N] ") .. msg)
end

local function build()
	-- 1. Materiaux globaux
	log("== materiaux")
	for materialName, color in MATERIAL_COLORS do
		log(string.format("  MaterialService %s = #%s", materialName, color:ToHex()))
		if not DRY_RUN then
			MaterialService:SetMaterialColor(Enum.Material[materialName], color)
		end
	end

	-- 2. Dossier des palettes (source unique pour B et K)
	log("== Map.ZonePalettes")
	local map = workspace:FindFirstChild("Map")
	assert(map, "[N] workspace.Map introuvable")
	if not DRY_RUN then
		local old = map:FindFirstChild("ZonePalettes")
		if old then
			old:Destroy() -- reconstruction propre (annulable)
		end
	end
	local folder = not DRY_RUN and Instance.new("Folder") or nil
	if folder then
		folder.Name = "ZonePalettes"
		folder.Parent = map
	end
	for _, zone in ZONES do
		for key, hex in zone.palette do
			log(string.format("  %s.%s = #%s", zone.name, key, hex))
		end
		for key, value in zone.ambiance do
			log(string.format("  %s.%s = %s", zone.name, key, tostring(value)))
		end
		if not DRY_RUN then
			local c = Instance.new("Configuration")
			c.Name = zone.name
			c.Parent = folder
			for key, hex in zone.palette do
				c:SetAttribute(key, hex)
			end
			for key, value in zone.ambiance do
				-- les Color3 deviennent des strings hex pour rester lisibles en attribut
				c:SetAttribute(key, typeof(value) == "Color3" and value:ToHex() or value)
			end
		end
	end

	-- 3. Voiles d'eau teintes
	log("== voiles d'eau")
	for _, w in ZONE_WATER do
		log(string.format("  %s : voile rayon %d en (%.0f, %.0f)", w.zone, w.radius, w.pos.X, w.pos.Z))
		if not DRY_RUN then
			local zoneColor
			for _, z in ZONES do
				if z.name == w.zone then
					zoneColor = z.palette.Water
				end
			end
			local veil = Instance.new("Part")
			veil.Name = "WaterTint_" .. w.zone
			veil.Shape = Enum.PartType.Cylinder
			veil.Size = Vector3.new(0.3, w.radius * 2, w.radius * 2)
			veil.CFrame = CFrame.new(w.pos) * CFrame.Angles(0, 0, math.rad(90))
			veil.Anchored = true
			veil.CanCollide = false
			veil.CanTouch = false
			veil.CanQuery = false
			veil.CastShadow = false
			veil.Material = Enum.Material.Glass
			veil.Color = Color3.fromHex(zoneColor or "1a7aa6")
			veil.Transparency = 0.55 -- voile leger : la teinte passe, on voit le fond
			veil.Parent = folder and folder:FindFirstChild(w.zone) or map
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("N : palettes des 5 zones")
	assert(rec, "[N] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("palettes posees. B lit Map.ZonePalettes pour les ambiances ; Ctrl+Z annule tout.")
	else
		warn("[N] erreur, tout est annule : " .. tostring(err))
	end
end
