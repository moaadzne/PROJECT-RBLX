-- tools/world/build_lagoon.luau
-- C : lagon d'une base, palier 1, et sa barriere de corail et de roche (docs/DA_MONDE.md §2, direction v2).
-- Plot1 par defaut ; mettre { 1, 2, ..., 8 } pour la hero shot.
-- Lancement manuel uniquement (execute_luau, mode edition), jamais automatique.
-- 1er passage avec DRY_RUN = true (affiche le plan, ne modifie rien), puis DRY_RUN = false.
-- Un seul enregistrement ChangeHistoryService : Ctrl+Z annule tout ; en cas d'erreur, rien n'est garde.
-- Ne touche pas : noms, attributs, Slot, LockGui, Display, SignAnchor, collision du Deck (SpawnPos inchange).
-- Les anciens visuels de la base sont deplaces dans ServerStorage.C_Backup (pas supprimes).

local DRY_RUN = true
local PLOTS = { 1 }

-- false : cuvettes surelevees dans une dalle de roche (aucun objet porteur deplace).
-- true : vrai lagon creuse ; descend les PedestalN de POOL.sink (noms et attributs gardes). A VALIDER PAR D ET A avant usage.
-- Remettre false et relancer restaure la hauteur d'origine (attribut C_OrigY).
local SUNK_POOLS = false

-- Noms cherches dans _DecorLib (insensible a la casse, premier trouve). A corriger apres inspect_world.luau.
local FIND = {
	cabin = { "hut", "cabane", "cabin", "shack" },
	palm = { "palm" },
	dock = { "dock", "pier", "ponton", "jetty" },
	rock = { "rock", "stone", "boulder" },
	shell = { "shell", "coquillage" },
	coral = { "coral", "corail" },
}

-- Enfants de PlotN qu'on garde en place (le serveur en depend, ou c'est notre dossier)
local KEEP = { Pedestals = true, Display = true, SignAnchor = true, Deck = true, Lagoon = true, Barrier = true }

local POOL = {
	waterDepth = 0.8, -- eau au-dessus du fond ; le fond = haut du socle (le serveur y pose la creature)
	rimExtra = 0.4, -- rebord au-dessus de l'eau
	minDiameter = 5,
	maxDiameter = 7,
	rocks = 4, -- gros blocs de roche volcanique qui se chevauchent (budget : 150 parts par base)
	sink = 3.5, -- SUNK_POOLS : descente des socles
	waterColor = Color3.fromHex("2FB8B3"),
	waterTransparency = 0.5, -- eau claire : on voit la creature au fond
	floorColor = Color3.fromHex("E6D2A8"),
}

-- Decor du palier 1, relatif a la base : x depuis le centre, z depuis MaxZ (arriere) ou MinZ (entree)
local DECOR = {
	{ key = "cabin", x = -7, fromBack = 7, height = 9, yaw = 180 },
	{ key = "palm", x = 12, fromBack = 12, height = 22, yaw = 30 },
	{ key = "dock", x = 0, fromFront = -5, scale = 1, yaw = 0, decorOnly = false }, -- sur la plage, devant la barriere
}

-- Barriere de corail (PlotN.Barrier) : A pilote l'attribut Open et la collision des Blockers ; B anime le corail.
-- Fermee : mur de corail. Ouverte : le corail descend de RetractDepth dans le sable.
local BARRIER = {
	spacing = 4.5, -- un corail tous les 4,5 studs sur le contour
	minHeight = 6.5, -- masses de corail et de roche volcanique, 6,5 a 8 studs
	maxHeight = 8,
	rockEvery = 3, -- un bloc de roche tous les 3 elements, le reste en corail
	retractDepth = 5.5,
	blockerHeight = 12, -- plus haut qu'un saut
	blockerThickness = 1,
	inset = 1, -- retrait depuis le bord de la base
}

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local lib = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("_DecorLib")
assert(lib, "[C] ReplicatedStorage.Assets._DecorLib introuvable")
local plotsFolder = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Plots")
assert(plotsFolder, "[C] workspace.Map.Plots introuvable")

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

-- Nettoie un clone : 0 script, tout ancre, options de collision et d'ombre
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

-- Clone un modele : hauteur cible ou facteur d'echelle, centre XZ sur pos, bas pose sur pos.Y
local function place(key, pos, opts)
	local template = templates[key]
	if not template then
		return nil
	end
	log(string.format("  %s en (%.0f, %.1f, %.0f)", key, pos.X, pos.Y, pos.Z))
	if DRY_RUN then
		return nil
	end
	local c = template:Clone()
	prepare(c, opts)
	local _, size = boxOf(c)
	if opts.height and size.Y > 0 then
		scaleBy(c, opts.height / size.Y)
	elseif opts.width then
		scaleBy(c, opts.width / math.max(size.X, size.Z))
	elseif opts.scale then
		scaleBy(c, opts.scale)
	end
	c:PivotTo(CFrame.new(pos) * CFrame.Angles(0, math.rad(opts.yaw or 0), 0))
	local cf
	cf, size = boxOf(c)
	-- bas pose sur pos.Y (+ sink), ou sommet aligne sur topY
	local bottom = if opts.topY then opts.topY - size.Y else pos.Y + (opts.sink or 0)
	local offset = Vector3.new(pos.X - cf.Position.X, bottom - (cf.Position.Y - size.Y / 2), pos.Z - cf.Position.Z)
	c:PivotTo(c:GetPivot() + offset)
	c.Name = opts.name or c.Name
	c.Parent = opts.parent
	return c
end

local function hide(inst)
	local parts = inst:IsA("BasePart") and { inst } or {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	for _, p in parts do
		if p:GetAttribute("C_OrigTransparency") == nil then
			p:SetAttribute("C_OrigTransparency", p.Transparency)
		end
		p.Transparency = 1
	end
end

local function disc(name, center, diameter, height, props, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(center) * CFrame.Angles(0, 0, math.rad(90))
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function buildBarrier(plot, index, minX, maxX, minZ, maxZ, groundY)
	local x0, x1 = minX + BARRIER.inset, maxX - BARRIER.inset
	local z0, z1 = minZ + BARRIER.inset, maxZ - BARRIER.inset
	local sides = {
		{ name = "Front", a = Vector3.new(x0, 0, z0), b = Vector3.new(x1, 0, z0) },
		{ name = "Back", a = Vector3.new(x0, 0, z1), b = Vector3.new(x1, 0, z1) },
		{ name = "Left", a = Vector3.new(x0, 0, z0), b = Vector3.new(x0, 0, z1) },
		{ name = "Right", a = Vector3.new(x1, 0, z0), b = Vector3.new(x1, 0, z1) },
	}
	local count = 0
	for _, side in sides do
		count += math.max(1, math.floor((side.b - side.a).Magnitude / BARRIER.spacing))
	end
	log(string.format("  barriere : %d masses de corail et de roche sur le contour, 4 Blockers, Open = false", count))
	if DRY_RUN then
		return
	end
	local old = plot:FindFirstChild("Barrier")
	if old then
		old:Destroy()
	end
	local barrier = Instance.new("Model")
	barrier.Name = "Barrier"
	barrier:SetAttribute("Open", false)
	barrier:SetAttribute("RetractDepth", BARRIER.retractDepth)
	local coralFolder = Instance.new("Folder")
	coralFolder.Name = "Coral"
	coralFolder.Parent = barrier
	local blockers = Instance.new("Folder")
	blockers.Name = "Blockers"
	blockers.Parent = barrier
	local rng = Random.new(index * 1000)
	for _, side in sides do
		local delta = side.b - side.a
		local n = math.max(1, math.floor(delta.Magnitude / BARRIER.spacing))
		for k = 0, n - 1 do
			local p = side.a + delta * ((k + 0.5) / n)
			local isRock = k % BARRIER.rockEvery == 0
			place(isRock and "rock" or "coral", Vector3.new(p.X, groundY, p.Z), {
				height = rng:NextNumber(BARRIER.minHeight, BARRIER.maxHeight),
				yaw = rng:NextNumber(0, 360),
				sink = -0.3,
				decorOnly = true,
				noShadow = k % 2 == 1, -- une ombre sur deux suffit
				parent = coralFolder,
			})
		end
		local b = Instance.new("Part")
		b.Name = side.name
		b.Anchored = true
		b.Transparency = 1
		b.CanCollide = true
		b.CanTouch = false
		b.CastShadow = false
		local mid = (side.a + side.b) / 2
		local long = delta.Magnitude + BARRIER.blockerThickness
		b.Size = math.abs(delta.X) > math.abs(delta.Z) and Vector3.new(long, BARRIER.blockerHeight, BARRIER.blockerThickness)
			or Vector3.new(BARRIER.blockerThickness, BARRIER.blockerHeight, long)
		b.CFrame = CFrame.new(mid.X, groundY + BARRIER.blockerHeight / 2, mid.Z)
		b.Parent = blockers
	end
	barrier.Parent = plot
end

local function buildPlot(index)
	local plot = plotsFolder:FindFirstChild("Plot" .. index)
	if not plot then
		warn("[C] Plot" .. index .. " introuvable")
		return
	end
	local minX, maxX = plot:GetAttribute("MinX"), plot:GetAttribute("MaxX")
	local minZ, maxZ = plot:GetAttribute("MinZ"), plot:GetAttribute("MaxZ")
	local spawnPos = plot:GetAttribute("SpawnPos")
	assert(minX and maxX and minZ and maxZ and spawnPos, "[C] attributs MinX/MaxX/MinZ/MaxZ/SpawnPos manquants sur Plot" .. index)
	local cx = (minX + maxX) / 2
	local deckTop = spawnPos.Y
	log(string.format("== Plot%d : X %.0f..%.0f, Z %.0f..%.0f, sol %.1f", index, minX, maxX, minZ, maxZ, deckTop))

	-- 1. Anciens visuels -> ServerStorage.C_Backup.PlotN
	local toMove = {}
	for _, c in plot:GetChildren() do
		if not KEEP[c.Name] then
			table.insert(toMove, c)
			log("  sauvegarde puis retrait : " .. c.Name .. " [" .. c.ClassName .. "]")
		end
	end
	if not DRY_RUN then
		local backup = ServerStorage:FindFirstChild("C_Backup") or Instance.new("Folder")
		backup.Name = "C_Backup"
		backup.Parent = ServerStorage
		local dest = backup:FindFirstChild(plot.Name) or Instance.new("Folder")
		dest.Name = plot.Name
		dest.Parent = backup
		for _, c in toMove do
			c.Parent = dest
		end
	end

	-- 2. Socles et rebords masques (objets, Slot, LockGui et collisions gardes) ; Deck masque, collision gardee
	local peds = plot:FindFirstChild("Pedestals")
	assert(peds, "[C] Pedestals manquant sur Plot" .. index)
	log("  masque Pedestals (socles + Rim) et Deck")
	if not DRY_RUN then
		for _, c in peds:GetChildren() do
			hide(c)
		end
		local deck = plot:FindFirstChild("Deck")
		if deck then
			hide(deck)
		end
	end

	-- 3. Sable sous la base, jusqu'au niveau du deck
	local w, d = maxX - minX, maxZ - minZ
	log(string.format("  sable terrain %.0f x %.0f jusqu'a Y %.1f", w, d, deckTop))
	if not DRY_RUN then
		workspace.Terrain:FillBlock(CFrame.new(cx, deckTop - 1, (minZ + maxZ) / 2), Vector3.new(w, 2, d), Enum.Material.Sand)
	end

	-- 4. Bassins, un par PedestalN
	local lagoon = plot:FindFirstChild("Lagoon")
	if not DRY_RUN then
		if lagoon then
			lagoon:Destroy() -- reconstruction propre (annulable par Ctrl+Z)
		end
		lagoon = Instance.new("Folder")
		lagoon.Name = "Lagoon"
		lagoon.Parent = plot
	end
	local pools = not DRY_RUN and Instance.new("Folder") or nil
	if pools then
		pools.Name = "Pools"
		pools.Parent = lagoon
	end

	local list = {}
	for i = 1, 10 do
		local p = peds:FindFirstChild("Pedestal" .. i)
		if p then
			table.insert(list, { slot = i, part = p })
		end
	end
	for _, e in list do
		local nearest = math.huge
		for _, o in list do
			if o ~= e then
				local a, b = e.part.Position, o.part.Position
				nearest = math.min(nearest, Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude)
			end
		end
		local diameter = math.clamp(nearest - 1.5, POOL.minDiameter, POOL.maxDiameter)
		local part = e.part
		-- hauteur du socle : d'origine, ou descendue pour un lagon creuse
		local origY = part:GetAttribute("C_OrigY") or part.Position.Y
		local pedY = origY - (SUNK_POOLS and POOL.sink or 0)
		if not DRY_RUN and math.abs(part.Position.Y - pedY) > 1e-3 then
			if part:GetAttribute("C_OrigY") == nil then
				part:SetAttribute("C_OrigY", origY)
			end
			part.Position = Vector3.new(part.Position.X, pedY, part.Position.Z)
		end
		local pos = Vector3.new(part.Position.X, pedY, part.Position.Z)
		local floorTop = pedY + part.Size.X / 2 -- cylindre couche : hauteur = Size.X (comme PlotService)
		local waterTop = if SUNK_POOLS then deckTop - 0.2 else floorTop + POOL.waterDepth
		local rimTop = if SUNK_POOLS then deckTop + 0.6 else waterTop + POOL.rimExtra
		local bottom = math.min(deckTop, floorTop - 1)
		log(string.format("  cuvette %d : centre (%.1f, %.1f), diametre %.1f, fond Y %.1f, eau Y %.1f%s", e.slot, pos.X, pos.Z, diameter, floorTop, waterTop, SUNK_POOLS and ", creusee" or ""))
		if not DRY_RUN then
			if SUNK_POOLS then
				workspace.Terrain:FillCylinder(CFrame.new(pos.X, (bottom + deckTop + 1) / 2, pos.Z), deckTop + 1 - bottom, diameter / 2 + 0.5, Enum.Material.Air)
			end
			local pool = Instance.new("Model")
			pool.Name = "Pool" .. e.slot
			pool:SetAttribute("PoolSlot", e.slot)
			pool:SetAttribute("FloorY", floorTop)
			pool:SetAttribute("WaterY", waterTop)
			pool.Parent = pools
			local inner = diameter - 0.6
			disc("Floor", Vector3.new(pos.X, (bottom + floorTop) / 2, pos.Z), inner, floorTop - bottom, {
				Material = Enum.Material.Sand,
				Color = POOL.floorColor,
				CastShadow = false,
			}, pool)
			disc("Water", Vector3.new(pos.X, (floorTop + waterTop) / 2, pos.Z), inner, waterTop - floorTop, {
				Material = Enum.Material.Glass,
				Color = POOL.waterColor,
				Transparency = POOL.waterTransparency,
				CanCollide = false,
				CanTouch = false,
				CanQuery = false,
				CastShadow = false,
			}, pool)
			-- rebord : gros blocs de roche volcanique qui se chevauchent, sommet vers rimTop
			local rng = Random.new(index * 100 + e.slot)
			for k = 1, POOL.rocks do
				local a = (k / POOL.rocks) * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
				local r = diameter / 2 + 0.3
				place("rock", Vector3.new(pos.X + math.cos(a) * r, bottom, pos.Z + math.sin(a) * r), {
					width = diameter * 0.7,
					topY = rimTop + rng:NextNumber(-0.2, 0.4),
					yaw = rng:NextNumber(0, 360),
					name = "Rock" .. k,
					parent = pool,
				})
			end
			-- corail vivant dans l'eau, decale du centre (la creature est au centre)
			local ca = rng:NextNumber(0, math.pi * 2)
			place("coral", Vector3.new(pos.X + math.cos(ca) * diameter * 0.28, floorTop, pos.Z + math.sin(ca) * diameter * 0.28), {
				height = (waterTop - floorTop) + 0.3,
				yaw = rng:NextNumber(0, 360),
				decorOnly = true,
				noShadow = true,
				name = "Coral",
				parent = pool,
			})
		end
	end

	-- 5. Barriere de corail
	buildBarrier(plot, index, minX, maxX, minZ, maxZ, deckTop)

	-- 6. Decor du palier 1 (les paliers 2 a 5 iront dans Lagoon.Tier2..5, affiches selon LagoonTier cote client)
	local tier = not DRY_RUN and Instance.new("Folder") or nil
	if tier then
		tier.Name = "Tier1"
		tier.Parent = lagoon
	end
	for _, item in DECOR do
		local z = item.fromBack and (maxZ - item.fromBack) or (minZ + item.fromFront)
		place(item.key, Vector3.new(cx + item.x, deckTop, z), {
			height = item.height,
			scale = item.scale,
			yaw = item.yaw,
			decorOnly = item.decorOnly,
			parent = tier,
		})
	end
end

local function build()
	for _, index in PLOTS do
		buildPlot(index)
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : lagon palier 1")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("termine. Ctrl+Z annule tout.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
