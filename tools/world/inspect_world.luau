-- tools/world/inspect_world.luau
-- C : inventaire en LECTURE SEULE, a lancer en premier (execute_luau, mode edition).
-- Ne modifie rien. Sert a corriger les noms et positions des autres scripts de tools/world.

local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local function fmt(v)
	return v and string.format("%.1f x %.1f x %.1f", v.X, v.Y, v.Z) or "-"
end

local function extents(inst)
	if inst:IsA("Model") then
		return inst:GetExtentsSize()
	elseif inst:IsA("BasePart") then
		return inst.ExtentsSize
	end
	return nil
end

local function countScripts(inst)
	local n = 0
	for _, d in inst:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			n += 1
		end
	end
	return n
end

-- 1. _DecorLib : nom, classe, taille, scripts (doit etre 0)
print("=== ReplicatedStorage.Assets._DecorLib ===")
local assets = RS:FindFirstChild("Assets")
local lib = assets and assets:FindFirstChild("_DecorLib")
if not lib then
	warn("_DecorLib introuvable")
else
	for _, child in lib:GetChildren() do
		print(string.format("%s [%s] taille %s, %d descendants, %d scripts", child.Name, child.ClassName, fmt(extents(child)), #child:GetDescendants(), countScripts(child)))
		local names = {}
		for _, c in child:GetChildren() do
			table.insert(names, c.Name)
		end
		if #names > 1 then
			print("   contient : " .. table.concat(names, ", ", 1, math.min(#names, 40)))
		end
	end
end

-- 2. Plot1 : attributs, enfants, socles
print("=== Map.Plots.Plot1 ===")
local map = workspace:FindFirstChild("Map")
local plots = map and map:FindFirstChild("Plots")
local plot = plots and plots:FindFirstChild("Plot1")
if plot then
	for k, v in plot:GetAttributes() do
		print("  attribut", k, v)
	end
	for _, c in plot:GetChildren() do
		print("  enfant", c.Name, c.ClassName, fmt(extents(c)))
	end
	local peds = plot:FindFirstChild("Pedestals")
	if peds then
		for i = 1, 10 do
			local p = peds:FindFirstChild("Pedestal" .. i)
			if p then
				print(string.format("  Pedestal%d pos (%.1f, %.1f, %.1f) taille %s CanCollide %s", i, p.Position.X, p.Position.Y, p.Position.Z, fmt(p.Size), tostring(p.CanCollide)))
			end
		end
	end
else
	warn("Plot1 introuvable")
end

-- 3. Haut de Map (pour savoir quoi masquer pendant la capture)
print("=== Map ===")
if map then
	for _, c in map:GetChildren() do
		print("  " .. c.Name, c.ClassName, #c:GetDescendants() .. " descendants")
	end
end

-- 4. Ilots : terrain au-dessus de l'eau hors de la plage (ou est l'ilot du phare ?)
print("=== Ilots hors plage (terrain au-dessus de Y 0.5) ===")
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { workspace.Terrain }
local buckets = {}
for x = -400, 400, 8 do
	for z = -900, 300, 8 do
		local onBeach = x >= -136 and x <= 136 and z >= -788 and z <= 128
		if not onBeach then
			local r = workspace:Raycast(Vector3.new(x, 200, z), Vector3.new(0, -260, 0), params)
			if r and r.Material ~= Enum.Material.Water and r.Position.Y > 0.5 then
				local key = math.floor(x / 48) .. "," .. math.floor(z / 48)
				local b = buckets[key] or { n = 0, sum = Vector3.zero, top = -math.huge, mat = r.Material.Name }
				b.n += 1
				b.sum += r.Position
				b.top = math.max(b.top, r.Position.Y)
				buckets[key] = b
			end
		end
	end
end
local found = false
for _, b in buckets do
	local c = b.sum / b.n
	print(string.format("  zone centree (%.0f, %.0f) : %d points, sommet Y %.1f, matiere %s", c.X, c.Z, b.n, b.top, b.mat))
	found = true
end
if not found then
	print("  aucun ilot trouve")
end

-- 5. Lighting
print("=== Lighting ===")
print(string.format("  Technology %s, ClockTime %.2f, Latitude %.1f, Brightness %.2f", Lighting.Technology.Name, Lighting.ClockTime, Lighting.GeographicLatitude, Lighting.Brightness))
for _, c in Lighting:GetChildren() do
	print("  " .. c.Name, c.ClassName)
end
print("=== fin de l'inventaire (rien n'a ete modifie) ===")
