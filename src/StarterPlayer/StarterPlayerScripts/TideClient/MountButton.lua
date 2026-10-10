-- MountButton : bouton RIDE / GET OFF (GDD v2 §4.6, contrat v2.1).
--   RF Mount(uid) monte, Mount(nil) descend ; state.mount = uid de la monture ou nil ; state.carrying bloque.
--   Montures possibles : Store.Mountables() (Config.Mount : especes, stade minimum), la plus grande d'abord.
-- Visible seulement si le serveur propose Mount et qu'une monture est disponible (ou active).
local MountButton = {}

-- 6 mots au plus (VISION_TON §5)
local CODE_TEXT = {
	NotMountable = "Can't ride this one",
	TooYoung = "Too young to ride",
	Carrying = "Drop the creature first",
	WaveActive = "Not during the wave",
	Busy = "Busy",
}

local Theme, Store, Hud, Notifications, Sfx
local pending = false

local function refresh(state)
	local riding = state.mount ~= nil
	local available = state.loaded and Store.HasRemote("Mount") and (riding or #Store.Mountables() > 0)
	Hud.SetAction("mount", {
		visible = available,
		icon = if riding then "down" else "ride",
		label = if riding then "Get off" else "Ride",
		enabled = not pending and not state.carrying,
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
		ok, code = Store.Mount(nil)
	else
		local best = Store.Mountables()[1]
		if best then
			ok, code = Store.Mount(best.uid)
		else
			ok, code = false, "TooYoung"
		end
	end
	pending = false
	refresh(Store.Get())
	if ok then
		Sfx.Play("whoosh")
	elseif code ~= "NoRemote" then
		Sfx.Play("deny")
		Notifications.Push({ text = string.upper(CODE_TEXT[code] or "Can't ride now"), color = Theme.Colors.Danger, icon = "close", key = "mount-err" })
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
