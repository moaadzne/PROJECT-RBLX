-- Sfx : sons cote client. Cherche ReplicatedStorage.Assets.Sounds.<nom> (fournis par C, T-012).
-- Un son absent est ignore en silence. Volume x reglage du joueur. SoundGroups UI / SFX si presents.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Sfx = {}

local MAX_ONESHOT_LIFE = 12 -- secondes : filet de securite si Ended ne vient jamais
local UI_SOUNDS = { click = true, purchase = true, deny = true, whoosh = true }

local Settings, Util
local worldFolder: Folder? = nil

local function group(name: string): SoundGroup?
	local g = SoundService:FindFirstChild(name, true)
	if g and g:IsA("SoundGroup") then
		return g
	end
	return nil
end

local function template(name: string): Sound?
	local s = Util.Find(ReplicatedStorage, "Assets", "Sounds", name)
	if s and s:IsA("Sound") then
		return s
	end
	return nil
end

local function getWorldFolder(): Folder
	if worldFolder and worldFolder.Parent then
		return worldFolder
	end
	local f = Instance.new("Folder")
	f.Name = "TR_ClientSounds"
	f.Parent = workspace
	worldFolder = f
	return f
end

-- Petite part invisible qui porte un son 3D
local function soundAnchor(position: Vector3): Part
	local part = Instance.new("Part")
	part.Name = "SfxAnchor"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one
	part.CFrame = CFrame.new(position)
	part.Parent = getWorldFolder()
	return part
end

function Sfx.Init(ctx)
	Settings = ctx.Settings
	Util = ctx.Util
end

-- Joue un son ponctuel. opts : volume (x), pitch (x), position (Vector3 = son 3D)
function Sfx.Play(name: string, opts: { volume: number?, pitch: number?, position: Vector3? }?): Sound?
	local src = template(name)
	if not src then
		return nil
	end
	local o = opts or {}
	local s = src:Clone()
	s.Looped = false
	s.Volume = src.Volume * (o.volume or 1) * Settings.Get("volume")
	if o.pitch then
		s.PlaybackSpeed = src.PlaybackSpeed * o.pitch
	end
	if not s.SoundGroup then
		s.SoundGroup = group(if UI_SOUNDS[name] then "UI" else "SFX")
	end
	-- l'objet a detruire : la part 3D ou le son lui-meme
	local owner: Instance = s
	if o.position then
		owner = soundAnchor(o.position)
		s.Parent = owner
	else
		s.Parent = SoundService
	end
	s.Ended:Once(function()
		owner:Destroy()
	end)
	task.delay(MAX_ONESHOT_LIFE, function()
		if owner.Parent then
			owner:Destroy()
		end
	end)
	s:Play()
	return s
end

-- Son en boucle pilotable (grondement de la vague). Renvoie une poignee ou nil.
--   handle:SetVolume(x)  (x = 0..1, relatif au volume du modele) ; handle:Stop(fadeTime)
function Sfx.Loop(name: string, startLevel: number?)
	local src = template(name)
	if not src then
		return nil
	end
	local s = src:Clone()
	s.Looped = true
	local baseVolume = src.Volume
	s.Volume = baseVolume * (startLevel or 1) * Settings.Get("volume")
	if not s.SoundGroup then
		s.SoundGroup = group("SFX")
	end
	s.Parent = SoundService
	s:Play()
	local handle = {}
	function handle.SetVolume(_self, level: number)
		if s.Parent then
			s.Volume = baseVolume * level * Settings.Get("volume")
		end
	end
	function handle.Stop(_self, fadeTime: number?)
		if not s.Parent then
			return
		end
		local t = fadeTime or 0.6
		Util.Tween(s, t, { Volume = 0 }, Enum.EasingStyle.Quad)
		task.delay(t + 0.05, function()
			s:Destroy()
		end)
	end
	return handle
end

return Sfx
