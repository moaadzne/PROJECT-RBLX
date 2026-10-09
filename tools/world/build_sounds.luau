-- tools/world/build_sounds.luau
-- C : sons du jeu (docs/SOURCING_C.md §4). Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--  * SoundService : SoundGroups Master > SFX, Ambient, UI (lus par TideClient/Sfx.lua)
--  * ReplicatedStorage.Assets.Sounds.<nom> : modeles de Sound que Sfx.Play(nom) / Sfx.Loop(nom) clonent
-- Sons ProSoundEffects / APMOfficial uniquement (bibliotheques sous licence publiees pour Roblox).
-- Les volumes sont un point de depart : a regler a l'oreille lundi, sur telephone.

local DRY_RUN = true

-- nom = { id, volume, group, looped?, pitch? }
local SOUNDS = {
	-- Boucle et intro (GDD §1 ter)
	pickup = { 9112751536, 0.6, "SFX" }, -- prise : Bubble Bloop High Pitched Cute 1 (pitch selon la rarete cote client)
	crabPip = { 9120222115, 0.45, "SFX", false, 1.3 }, -- le crabe saute de joie : Toy Squeak 2
	splash = { 9125703162, 0.7, "SFX" }, -- plongeon dans le bassin : Mud Puddle Splash Shallow Water Impacts
	rumble = { 9112775181, 0.8, "SFX" }, -- alerte vague -7 s : Earthquake Rumble 2
	horn = { 9113467353, 0.6, "SFX" }, -- corne de brume -3 s : Boat Horn Short Long Blasts 2
	waveImpact = { 9120610956, 0.9, "SFX" }, -- la vague s'ecrase : Wave Crash 1
	-- Vol, barriere, monture (GDD §4.6, §4.7)
	steal = { 9116400132, 0.6, "SFX" }, -- la creature saute dans les bras du voleur : Magic Movement Airy Whips Swooshes 24
	theftAlert = { 9113085114, 0.5, "SFX" }, -- alerte du proprietaire : Alarm Bell On Hard Surface 1 (couper a 1,5 s cote client)
	barrierOpen = { 9118770617, 0.6, "SFX" }, -- le corail rentre dans le sable : Sand Silt 2
	barrierClose = { 9118689425, 0.6, "SFX" }, -- le corail remonte : Rocks Knock Against Each Other 3
	surf = { 9120606857, 0.8, "SFX" }, -- glisse sur la crete : Water Surge 1
	surfLoop = { 9120591281, 0.5, "SFX", true }, -- embruns pendant le surf : Water Spray 1
	-- Marée Royale (GDD §4.8)
	royalWin = { 1846266827, 0.6, "SFX" }, -- top 3 : Short Fanfare (APM)
	-- Ambiance (DA §7)
	ambientBeach = { 9119679792, 0.35, "Ambient", true }, -- Surf Waves Crash On Shore Constant
	seagulls = { 9112870701, 0.2, "Ambient", true }, -- Seagulls 2
	bubbles = { 9112752570, 0.25, "Ambient", true }, -- bassins, au plus pres : Bubbles Dribble Small Bloops 1
}

local GROUPS = { SFX = 0.8, Ambient = 0.6, UI = 0.7 }

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local assets = RS:FindFirstChild("Assets")
assert(assets, "[C] ReplicatedStorage.Assets introuvable")

local function log(msg)
	print((DRY_RUN and "[C][DRY] " or "[C] ") .. msg)
end

local function build()
	-- 1. SoundGroups (on garde ceux qui existent deja)
	local master = SoundService:FindFirstChild("Master")
	log("SoundGroups : Master > SFX, Ambient, UI")
	if not DRY_RUN and not master then
		master = Instance.new("SoundGroup")
		master.Name = "Master"
		master.Volume = 1
		master.Parent = SoundService
	end
	local groups = {}
	for name, volume in GROUPS do
		local g = SoundService:FindFirstChild(name, true)
		if not g and not DRY_RUN then
			g = Instance.new("SoundGroup")
			g.Name = name
			g.Volume = volume
			g.Parent = master
		end
		groups[name] = g
	end

	-- 2. Modeles de Sound
	local folder = assets:FindFirstChild("Sounds")
	if not folder and not DRY_RUN then
		folder = Instance.new("Folder")
		folder.Name = "Sounds"
		folder.Parent = assets
	end
	for name, def in SOUNDS do
		local id, volume, group, looped, pitch = def[1], def[2], def[3], def[4], def[5]
		log(string.format("  %s = rbxassetid://%d (vol %.2f, %s%s)", name, id, volume, group, looped and ", boucle" or ""))
		if not DRY_RUN then
			local old = folder:FindFirstChild(name)
			if old then
				old:Destroy()
			end
			local s = Instance.new("Sound")
			s.Name = name
			s.SoundId = "rbxassetid://" .. id
			s.Volume = volume
			s.Looped = looped == true
			s.PlaybackSpeed = pitch or 1
			s.SoundGroup = groups[group]
			s.Parent = folder
		end
	end
end

if DRY_RUN then
	build()
	log("DRY_RUN : rien n'a ete modifie. Relancer avec DRY_RUN = false.")
else
	local rec = CHS:TryBeginRecording("C : sons")
	assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
	local ok, err = pcall(build)
	CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
	if ok then
		log("sons crees. Les ecouter un par un (Play dans les proprietes) et regler les volumes.")
	else
		warn("[C] erreur, tout est annule : " .. tostring(err))
	end
end
