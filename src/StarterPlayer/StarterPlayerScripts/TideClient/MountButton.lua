-- MountButton : bouton Monter / Descendre (GDD v2 §4.6). Forme du contrat PROVISOIRE (noms reserves par A) :
--   RF Mount(mountId) / Dismount() ; state.mounts = {uid...} (creatures montables, Adult et plus) ; state.mount = uid ou nil.
-- Visible seulement si le serveur propose Mount et qu'une monture est disponible (ou active).
local MountButton = {}

local ERROR_TEXT = {
	WaveActive = "Can't do that during the wave!",
	NotReady = "This creature is too young to ride.",
	Cooldown = "Not now!",
}

local Theme, Store, Hud, Notifications, Sfx
local pending = false

-- Monture proposee : la plus grande parmi state.mounts (stade le plus haut dans les bassins)
local function bestMount(state): string?
	local best, bestStage = nil, -1
	for _, uid in state.mounts do
		local stage = 0
		for _, entry in state.pools do
			if entry and entry.uid == uid then
				stage = entry.stage or 0
			end
		end
		if stage > bestStage then
			best, bestStage = uid, stage
		end
	end
	return best
end

local function refresh(state)
	local riding = state.mount ~= nil
	local available = state.loaded and Store.HasRemote("Mount") and (riding or #state.mounts > 0)
	Hud.SetAction("mount", {
		visible = available,
		icon = if riding then "⬇️" else "🐢",
		label = if riding then "Get off" else "Ride",
		enabled = not pending,
	})
end

local function onPressed()
	local state = Store.Get()
	if pending or not state then
		return
	end
	pending = true
	refresh(state)
	local ok, code
	if state.mount then
		ok, code = Store.Dismount()
	else
		local uid = bestMount(state)
		if uid then
			ok, code = Store.Mount(uid)
		else
			ok, code = false, "NotReady"
		end
	end
	pending = false
	refresh(Store.Get())
	if ok then
		Sfx.Play("whoosh")
	else
		Sfx.Play("deny")
		Notifications.Push({ text = ERROR_TEXT[code] or "Can't ride right now.", color = Theme.Colors.Danger, icon = "✖️", key = "mount-err" })
	end
end

function MountButton.Init(ctx)
	Theme, Hud, Notifications, Sfx = ctx.Theme, ctx.Hud, ctx.Notifications, ctx.Sfx
end

function MountButton.Start(ctx)
	Store = ctx.Store
	Hud.SetAction("mount", { onActivated = onPressed })
	Store.Changed:Connect(refresh)
	refresh(Store.Get())
end

return MountButton
