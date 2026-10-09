-- tools/world/capture_mode.luau
-- C : masque l'ancienne carte en blocs pour la capture (Gates, Towers...), puis la restaure.
-- HIDE = true : masque. HIDE = false : restaure exactement (transparence et guis d'origine).
-- Ne supprime rien, ne change ni nom ni attribut serveur. Un enregistrement ChangeHistoryService.
-- A RESTAURER avant toute publication : les tours sont du gameplay.

local HIDE = true
local TARGETS = { "Gates", "Towers" } -- enfants de workspace.Map ; ajouter d'autres dossiers apres inspect_world.luau

local CHS = game:GetService("ChangeHistoryService")
local RunService = game:GetService("RunService")

assert(not RunService:IsRunning(), "[C] a lancer en mode edition, pas en Play")
local map = workspace:FindFirstChild("Map")
assert(map, "[C] workspace.Map introuvable")

local function apply()
	local n = 0
	for _, name in TARGETS do
		local root = map:FindFirstChild(name)
		if not root then
			warn("[C] Map." .. name .. " introuvable")
			continue
		end
		for _, d in root:GetDescendants() do
			if d:IsA("BasePart") then
				if HIDE then
					if d:GetAttribute("C_CapT") == nil then
						d:SetAttribute("C_CapT", d.Transparency)
					end
					d.Transparency = 1
				elseif d:GetAttribute("C_CapT") ~= nil then
					d.Transparency = d:GetAttribute("C_CapT")
					d:SetAttribute("C_CapT", nil)
				end
				n += 1
			elseif d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
				if HIDE then
					if d:GetAttribute("C_CapE") == nil then
						d:SetAttribute("C_CapE", d.Enabled)
					end
					d.Enabled = false
				elseif d:GetAttribute("C_CapE") ~= nil then
					d.Enabled = d:GetAttribute("C_CapE")
					d:SetAttribute("C_CapE", nil)
				end
			end
		end
	end
	print(string.format("[C] %s : %d parts", HIDE and "masque" or "restaure", n))
end

local rec = CHS:TryBeginRecording(HIDE and "C : mode capture" or "C : fin du mode capture")
assert(rec, "[C] enregistrement impossible (Play en cours ou autre enregistrement ouvert)")
local ok, err = pcall(apply)
CHS:FinishRecording(rec, ok and Enum.FinishRecordingOperation.Commit or Enum.FinishRecordingOperation.Cancel)
if not ok then
	warn("[C] erreur, tout est annule : " .. tostring(err))
end
