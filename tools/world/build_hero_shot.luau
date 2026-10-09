-- tools/world/build_hero_shot.luau
-- C : decor de la hero shot (Plot1 -> zone 1), lumiere et camera (docs/DA_MONDE.md §5).
-- Ordre : inspect_world.luau, build_lagoon.luau (PLOTS = 1..8), puis ce script, puis capture_mode.luau.
-- Lancement manuel uniquement (execute_luau, mode edition). DRY_RUN = true d'abord.
-- Decor et lumiere : un seul enregistrement ChangeHistoryService (Ctrl+Z annule). La camera n'est pas dans l'historique.
-- Lighting.Technology n'est pas modifiable par script : la passer en Future a la main.

local DRY_RUN = true
local DO_DECOR = true
local DO_LIGHTING = true
local DO_CAMERA = true

-- Houle de la vague posee a l'arret pour la capture (Assets.WaveSwell, construite par build_wave.luau). nil = pas de houle.
local SWELL_POS = Vector3.new(-60, 20, -450) -- centre du corps : Y 20 = houle presque entierement levee (sommet vers Y 47)

-- Centre de l'ilot du phare : relever la position donnee par inspect_world.luau (section Ilots). nil = phare non place.
local ISLET_POS = nil -- ex. Vector3.new(-175, 0, -120)

local CAMERA = {
	position = Vector3.new(-112, 14, 80),
	target = Vector3.new(-80, 3, -120),
	fov = 60,
}

local FIND = {
	lighthouse = { "lighthouse", "phare" },
	palm = { "palm" },
	raft = { "raft", "radeau" },
	rock = { "rock", "stone", "boulder" },
	shell = { "shell", "coquillage" },
	coral = { "coral", "corail" },
	bush = { "bush", "fern", "grass", "plant" },
}

-- Positions monde. Plot1 : X -128..-96, Z 4..67. Plage : X -132..132. Zone 1 : Z -25..-150.
-- water = true : pose a la surface de l'eau (radeau), sinon sur le terrain.
local DECOR = {
	{ key = "palm", pos = Vector3.new(-129, 0, -12), height = 26, yaw = 10 },
	{ key = "palm", pos = Vector3.new(-104, 0, -48), height = 20, yaw = 140 },
	{ key = "palm", pos = Vector3.new(-62, 0, -95), height = 24, yaw = 260 },
	{ key = "rock", pos = Vector3.new(-133, 0, -30), height = 5, yaw = 40, noShadow = false },
	{ key = "rock", pos = Vector3.new(-131, 0, -78), height = 3.5, yaw = 200 },
	{ key = "bush", pos = Vector3.new(-126, 0, -24), height = 2.5, yaw = 0, decorOnly = true, noShadow = true },
	{ key = "bush", pos = Vector3.new(-100, 0, -40), height = 2, yaw = 90, decorOnly = true, noShadow = true },
	{ key = "coral", pos = Vector3.new(-128, 0, -45), height = 2.5, yaw = 0, decorOnly = true, noShadow = true },
	{ key = "coral", pos = Vector3.new(-125, 0, -102), height = 3, yaw = 70, decorOnly = true, noShadow = true },
	{ key = "shell", pos = Vector3.new(-118, 0, -20), height = 0.8, yaw = 30, decorOnly = true, noShadow = true },
	{ key = "shell", pos = Vector3.new(-96, 0, -33), height = 0.7, yaw = 120, decorOnly = true, noShadow = true },
	{ key = "shell", pos = Vector3.new(-120, 0, -66), height = 0.9, yaw = 250, decorOnly = true, noShadow = true },
	{ key = "raft", pos = Vector3.new(-152, 0, -85), scale = 1, yaw = 25, water = true, decorOnly = true },
}

-- Lumiere de la capture (DA §5). Valeurs absolues ; nil = on ne touche pas.
local LIGHT = {
	Lighting = { ClockTime = 17.05, GeographicLatitude = 15 },
	BloomEffect = { Intensity = 0.4, Threshold = 1.5, Size = 24 },
	ColorCorrectionEffect = { Saturation = 0.05, Contrast = 0.08, TintColor = Color3.fromRGB(255, 248, 240) },
	SunRaysEffect = { Intensity = 0.05, Spread = 0.6 },
	Atmosphere = { Density = 0.32, Haze = 1.2, Glare = 0.2, Color = Color3.fromHex("F2A35E"), Decay = Color3.fromHex("13707A") },
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local lib = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("_DecorLib")
assert(lib, "[C] ReplicatedStorage.Assets._DecorLib introuvable")
local map = workspace:FindFirstChild("Map")
assert(map, "[C] workspace.Map introuvable")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function findTemplate(key)
	for _, pattern in FIND[key] do
		for _, d in lib:GetDescendants() do
			if (d:IsA("Model") or d:IsA("BasePart")) and string.find(string.lower(d.Name), pattern, 1, true) then
				return d
			end
		end
	end
	return nil
end

local templates = {}
for key in FIND do
	templates[key] = findTemplate(key)
	if templates[key] then
		log(string.format("modele %s = %s", key, templates[key]:GetFullName()))
	else
		warn("[C] aucun modele pour " .. key .. " : corriger FIND")
	end
end

local function boxOf(inst)
	if inst:IsA("Model") then
		return inst:GetBoundingBox()
	end
	return inst.CFrame, inst.ExtentsSize
end

local function scaleBy(inst, factor)
	if math.abs(factor - 1) < 1e-3 then
		return
	end
	if inst:IsA("Model") then
		inst:ScaleTo(inst:GetScale() * factor)
	else
		inst.Size *= factor
	end
end

local function prepare(clone, opts)
	local parts = {}
	if clone:IsA("BasePart") then
		table.insert(parts, clone)
	end
	for _, d in clone:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			warn("[C] script retire : " .. d:GetFullName())
			d:Destroy()
		elseif d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, p in parts do
		p.Anchored = true
		if opts.decorOnly then
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
		end
		if opts.noShadow then
			p.CastShadow = false
		end
	end
end

-- Hauteur du sol (terrain) ou de l'eau en (x, z)
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Include
groundParams.FilterDescendantsInstances = { workspace.Terrain }
local function surfaceY(x, z, water)
	groundParams.IgnoreWater = not water
	local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -400, 0), groundParams)
	return r and r.Position.Y or 0
end

local function place(key, pos, opts)
	local template = templates[key]
	if not template then
		return nil
	end
	local y = surfaceY(pos.X, pos.Z, opts.water)
	log(string.format("  %s en (%.0f, %.1f, %.0f)", key, pos.X, y, pos.Z))
	if DRY_RUN then
		return nil
	end
	local c = template:Clone()
	prepare(c, opts)
	local _, size = boxOf(c)
	if opts.height and size.Y > 0 then
		scaleBy(c, opts.height / size.Y)
	elseif opts.scale then
		scaleBy(c, opts.scale)
	end
	c:PivotTo(CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, math.rad(opts.yaw or 0), 0))
	local cf
	cf, size = boxOf(c)
	-- bas de la boite sur le sol (enfonce de 0,3 pour ne pas flotter) ; un objet sur l'eau s'enfonce d'un tiers
	local sink = opts.water and size.Y / 3 or 0.3
	c:PivotTo(c:GetPivot() + Vector3.new(pos.X - cf.Position.X, y - (cf.Position.Y - size.Y / 2) - sink, pos.Z - cf.Position.Z))
	c.Parent = opts.parent
	return c
end

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
	if DO_DECOR then
		log("== decor")
		local folder = map:FindFirstChild("HeroDecor")
		if not DRY_RUN then
			if folder then
				folder:Destroy() -- reconstruction propre (annulable)
			end
			folder = Instance.new("Folder")
			folder.Name = "HeroDecor"
			folder.Parent = map
		end
		for _, item in DECOR do
			place(item.key, item.pos, {
				height = item.height,
				scale = item.scale,
				yaw = item.yaw,
				water = item.water,
				decorOnly = item.decorOnly,
				noShadow = item.noShadow,
				parent = folder,
			})
		end
		local swell = RS.Assets:FindFirstChild("WaveSwell")
		if SWELL_POS and swell then
			log(string.format("  houle de la vague en Z %.0f", SWELL_POS.Z))
			if not DRY_RUN then
				local c = swell:Clone()
				c:PivotTo(CFrame.new(SWELL_POS) * (swell:GetPivot() - swell:GetPivot().Position))
				c.Parent = folder
			end
		elseif SWELL_POS then
			warn("[C] Assets.WaveSwell absent : lancer build_wave.luau d'abord")
		end
		if ISLET_POS then
			place("lighthouse", ISLET_POS, { height = 60, yaw = 200, parent = folder })
		else
			warn("[C] ISLET_POS vide : phare non place (voir inspect_world.luau)")
		end
	end

	if DO_LIGHTING then
		log("== lumiere")
		for className, props in LIGHT do
			local target = className == "Lighting" and Lighting or effect(className)
			for prop, value in props do
				log(string.format("  %s.%s = %s", className, prop, tostring(value)))
				if target and not DRY_RUN then
					target[prop] = value
				end
			end
		end
		if Lighting.Technology ~= Enum.Technology.Future then
			warn("[C] Lighting.Technology = " .. Lighting.Technology.Name .. " : passer en Future a la main")
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : hero shot")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("decor et lumiere termines. Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end

-- Camera de la capture (hors historique, sans risque)
if DO_CAMERA and not DRY_RUN then
	local cam = workspace.CurrentCamera
	cam.CFrame = CFrame.lookAt(CAMERA.position, CAMERA.target)
	cam.FieldOfView = CAMERA.fov
	log("camera placee : capture 16:9, puis verifier le recadrage 1:1")
end
