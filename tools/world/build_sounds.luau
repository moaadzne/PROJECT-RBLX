-- tools/world/build_sounds.luau
-- C : sons du jeu (docs/SOURCING_C.md §4). Lancement manuel (execute_luau, mode edition). DRY_RUN = true d'abord. Ctrl+Z annule.
--  * SoundService : SoundGroups Master > SFX, Ambient, UI, Music (lus par TideClient/Sfx.lua)
--  * ReplicatedStorage.Assets.Sounds.<nom> : modeles de Sound que Sfx.Play(nom) / Sfx.Loop(nom) clonent
-- Sons ProSoundEffects / APMOfficial uniquement (bibliotheques sous licence publiees pour Roblox).
-- SoundGroup Music : la musique se coupe a part dans les reglages (B).
-- Les volumes sont un point de depart : a regler a l'oreille lundi, sur telephone.

local DRY_RUN = true

-- nom = { id, volume, group, looped?, pitch? }
-- Direction v2 : realiste et grave ; rien de « cartoon » (pas de squeak, pas de bloop).
local SOUNDS = {
	-- Boucle et intro (GDD §1 ter)
	pickup = { 9125702803, 0.5, "SFX" }, -- prise : eclaboussure courte et mouillee (Mud Puddle Splash) ; pitch selon la rarete cote client
	splash = { 9125703162, 0.7, "SFX" }, -- la creature plonge dans la cuvette : Mud Puddle Splash Shallow Water Impacts
	rumble = { 9112775181, 0.8, "SFX" }, -- alerte -7 s, grondement grave qui monte : Earthquake Rumble 2
	alertHit = { 1837830879, 0.6, "SFX" }, -- debut de l'alerte : WHOOSHBANG-Surge Hit 01 (APM)
	horn = { 9113467353, 0.6, "SFX" }, -- corne de brume -3 s : Boat Horn Short Long Blasts 2
	siren = { 9119165140, 0.5, "SFX" }, -- appele par Hud.lua a l'alerte : Siren Wail 2 (sirene d'alerte, a couper a 4 s)
	grow = { 9112872437, 0.5, "SFX" }, -- appele par PoolBillboards.lua quand une creature grandit : Small Bubbles Water Surface Float Up
	waveBoom = { 9125484367, 0.9, "SFX" }, -- la houle deferle (depart) : Deep Hits Big Reverberant Booms Rumbling
	waveImpact = { 9120610956, 0.9, "SFX" }, -- la vague s'ecrase : Wave Crash 1
	-- Vol, barriere, monture (GDD §4.6, §4.7)
	steal = { 9120718689, 0.6, "SFX" }, -- la creature est arrachee : Whoosh Fast Swish By 2
	theftAlert = { 1842433183, 0.6, "SFX" }, -- alerte du proprietaire : Lethal Dose (SFX 5) (APM, sting tendu)
	barrierOpen = { 9118770617, 0.6, "SFX" }, -- le recif s'enfonce dans le sable : Sand Silt 2
	barrierClose = { 9113807062, 0.7, "SFX" }, -- le recif remonte, roche qui frotte : Cinder Block Slide On Stone Surface
	surf = { 9120606857, 0.8, "SFX" }, -- debut de la glisse sur la crete : Water Surge 1
	surfLoop = { 9120591281, 0.5, "SFX", true }, -- embruns pendant le surf : Water Spray 1
	-- Maree Royale (GDD §4.8)
	royalWin = { 1837830084, 0.7, "SFX" }, -- top 3 : BOOM-Sub Boom 05 (APM), suivi de royalCheer
	royalCheer = { 9112766203, 0.35, "SFX" }, -- foule lointaine : Crowd Cheer And Applause 2 (a couper a 4 s)
	-- Ambiance (DA)
	ambientBeach = { 9119679792, 0.35, "Ambient", true }, -- Surf Waves Crash On Shore Constant
	seagulls = { 9112870701, 0.15, "Ambient", true }, -- Seagulls 2
	-- Musique sous licence (APM) : calme en jeu, tendue pendant l'alerte et la vague. A ecouter lundi.
	musicCalm = { 1837463526, 0.25, "Music", true }, -- Ethereal Drone (alternative : 1837389538 Peaceful Island)
	musicTension = { 91017465590486, 0.35, "Music", true }, -- Tension To Action A (alerte + vague)
	musicRiser = { 1846880576, 0.4, "Music" }, -- Suspense Build 2 (11 s, sur les 7 s d'alerte)
}

local GROUPS = { SFX = 0.8, Ambient = 0.6, UI = 0.7, Music = 0.5 }

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
