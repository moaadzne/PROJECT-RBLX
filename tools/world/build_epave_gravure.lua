-- tools/world/build_epave_gravure.lua
-- C : épave SO + gravure "Quand la mer recule, l'ancien roi revient..." + cliffhanger visuel.
-- DECISIONS_MARCHE.md §3 : texte lisible en 3s, cliffhanger lumineux pulse rythme marées.
-- Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
-- Place l'épave (modele _DecorLib ou creer un placeholder) au SO ~180 studs.
-- Ajoute : SurfaceGui gravure au sol, ParticleEmitter pulse rythme marées (toutes les 58 cycles ~1h).
-- Cross-platform : particules max 50 mobile / 200 PC (Config.CrossPlatform).

local DRY_RUN = true

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")

local lib = RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("_DecorLib")
assert(lib, "[C] ReplicatedStorage.Assets._DecorLib introuvable")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

-- Position épave : SO (sud-ouest) = X neg, Z pos. Distance ~180 studs du centre (0,0).
-- DECISIONS_MARCHE.md : "epave au SO a environ 180 studs"
local WRECK_POS = Vector3.new(-127, 0, 127) -- ~180 studs du centre, angle -135 deg (SO)

-- Gravure DECISIONS_MARCHE.md §3
local GRAVURE_TEXT = [[
Quand la mer recule,
l'ancien roi revient.
La marée extrême
révèle ce qu'elle a pris.
]]

-- Cliffhanger : particule pulse rythme marée extrême (toutes les 58 cycles ~1h)
-- En jeu : WaveService.signale la marée extreme → cette particule pulse.

local function findWreck()
	-- Cherche dans _DecorLib : "Wreck", "Shipwreck", "BoatWreck", "FishingBoat"
	local candidates = { "Wreck", "Shipwreck", "BoatWreck", "FishingBoat", "Raft" }
	for _, name in candidates do
		local found = lib:FindFirstChild(name, true)
		if found and (found:IsA("Model") or found:IsA("BasePart")) then
			log("épave trouvee dans _DecorLib : " .. found:GetFullName())
			return found
		end
	end
	-- Fallback : creer un placeholder simple (coque + mat)
	log("aucune épave dans _DecorLib -> creation placeholder")
	local model = Instance.new("Model")
	model.Name = "Wreck_Placeholder"
	local hull = Instance.new("Part")
	hull.Name = "Hull"
	hull.Size = Vector3.new(24, 6, 8)
	hull.Material = Enum.Material.Wood
	hull.Color = Color3.fromHex("7D6E60") -- driftwood
	hull.Anchored = true
	hull.CanCollide = true
	hull.Parent = model
	local mast = Instance.new("Part")
	mast.Name = "Mast"
	mast.Size = Vector3.new(1, 18, 1)
	mast.Material = Enum.Material.Wood
	mast.Color = Color3.fromHex("5A524C")
	mast.Anchored = true
	mast.CanCollide = false
	mast.CFrame = CFrame.new(0, 12, 0)
	mast.Parent = model
	return model
end

local function createGravurePart(parent)
	-- Plaque au sol devant l'épave, lisible de dessus
	local plate = Instance.new("Part")
	plate.Name = "GravurePlate"
	plate.Size = Vector3.new(20, 0.4, 12)
	plate.Material = Enum.Material.Rock
	plate.Color = Color3.fromHex("3B3633")
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanQuery = false
	plate.Parent = parent

	local sg = Instance.new("SurfaceGui")
	sg.Name = "GravureGui"
	sg.Face = Enum.NormalId.Top
	sg.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	sg.CanvasSize = Vector2.new(800, 400)
	sg.LightInfluence = 0
	sg.Parent = plate

	local lbl = Instance.new("TextLabel")
	lbl.Name = "GravureText"
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.RobotoCondensed -- H uploadera Font Awesome + RobotoCondensed
	lbl.Text = GRAVURE_TEXT
	lbl.TextColor3 = Color3.fromHex("F2A35E") -- or doré
	lbl.TextSize = 28
	lbl.TextWrapped = true
	lbl.TextXAlignment = Enum.TextXAlignment.Center
	lbl.TextYAlignment = Enum.TextYAlignment.Center
	lbl.Parent = sg

	-- Effet : texte lumineux pulse doux (cliffhanger visuel)
	local tween = game:GetService("TweenService"):Create(lbl, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {TextTransparency = 0.3})
	tween:Play()

	return plate
end

local function createCliffhangerParticles(parent)
	-- Particule au sol qui pulse au rythme des marées extrêmes (toutes les ~1h = 58 cycles)
	-- En jeu : WaveService declenche "ExtremeTideStart" → cette particule pulse fort pendant revealTime (25s)
	local attachment = Instance.new("Attachment")
	attachment.Name = "CliffhangerAttach"
	attachment.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "CliffhangerPulse"
	emitter.Color = ColorSequence.new(Color3.fromHex("FFD166")) -- or
	emitter.LightEmission = 1
	emitter.LightInfluence = 0
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 4), NumberSequenceKeypoint.new(1, 0) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 0.2) })
	emitter.Lifetime = NumberRange.new(2, 3)
	emitter.Rate = 0 -- declenche par script (WaveService)
	emitter.Speed = NumberRange.new(0.5, 1.5)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = attachment

	-- Cross-platform : max particules (lu par CreatureRenderer/VFX cote client)
	emitter:SetAttribute("MaxParticlesMobile", 50)
	emitter:SetAttribute("MaxParticlesPC", 200)

	return attachment
end

local function run()
	local map = Workspace:FindFirstChild("Map")
	assert(map, "[C] Workspace.Map introuvable")

	if DRY_RUN then
		log("DRY_RUN : épave SO ~180 studs, gravure texte 3s, cliffhanger pulse rythme marees")
		log("  Position : " .. tostring(WRECK_POS))
		log("  Texte gravure : 4 lignes, lisible en 3s, police RobotoCondensed")
		log("  Cliffhanger : particule or pulse, declenchee par WaveService (maree extreme)")
		log("  Cross-platform : particules 50 mobile / 200 PC")
		return
	end

	local rec = CHS:TryBeginRecording("C : epave + gravure + cliffhanger")
	assert(rec, "[C] enregistrement impossible")
	local ok, err = pcall(function()
		local wreck = findWreck()
		wreck.Name = "Wreck"
		wreck.Parent = map

		-- Positionne l'épave au sol (raycast pour Y)
		local origin = WRECK_POS + Vector3.new(0, 100, 0)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {map}
		params.FilterType = Enum.RaycastFilterType.Include
		local hit = Workspace:Raycast(origin, Vector3.new(0, -200, 0), params)
		local y = hit and hit.Position.Y or 0
		wreck:PivotTo(CFrame.new(WRECK_POS.X, y + 3, WRECK_POS.Z))

		-- Gravure devant l'épave (côté mer = +Z)
		local gravure = createGravurePart(wreck)
		gravure.CFrame = wreck:GetPivot() * CFrame.new(0, 0.2, 8)
		gravure.Parent = wreck

		-- Cliffhanger particules
		createCliffhangerParticles(wreck.PrimaryPart or wreck:FindFirstChild("Hull") or wreck:FindFirstChildWhichIsA("BasePart"))

		log("épave placee a " .. tostring(wreck:GetPivot().Position) .. " avec gravure + cliffhanger")
	end)

	if ok then
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Commit)
		log("Épave + gravure + cliffhanger places.")
	else
		CHS:FinishRecording(rec, Enum.FinishRecordingOperation.Cancel)
		warn("[C] erreur : " .. tostring(err))
	end
end

run()