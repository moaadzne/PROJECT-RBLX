-- verify_launch.luau
-- Script de vérification mécanique de la checklist de lancement (exécutable en Edit ou avant Play)
-- Responsable : M (QA Infrastructure)
-- Usage : exécuter en contexte Server (Edit ou Play) depuis la Command Bar ou un Script temporaire.

local Remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
local Shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
local Config = Shared and Shared:FindFirstChild("Config")
local SSS = game:GetService("ServerScriptService")
local SPS = game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts")
local WaveModule = SPS and SPS:FindFirstChild("TideClient") and SPS:FindFirstChild("TideClient"):FindFirstChild("Wave")
local Debug = game:GetService("ServerStorage"):FindFirstChild("TR_Debug")

local results = {}
local function check(name, ok, detail)
	table.insert(results, { name = name, ok = ok, detail = detail or "" })
	local tag = ok and "PASS" or "FAIL"
	print(string.format("[%s] %s %s", tag, name, detail and ("— " .. detail) or ""))
end

print("=== VERIFY LAUNCH — Checklist mécanique ===")

-- 5. Remotes v2.1
local expectedRemotes = {
	"GetState", "StateChanged", "WaveState", "Notify", "BuyUpgrade", "GoHome",
	"HatchEgg", "EquipPet", "LockLagoon", "StartSteal", "ChoosePick", "Mount", "RoyalBoard",
}
if Remotes then
	for _, name in ipairs(expectedRemotes) do
		check("Remote:" .. name, Remotes:FindFirstChild(name) ~= nil,
			Remotes:FindFirstChild(name) and Remotes[name].ClassName or "absent")
	end
	local ws = Remotes:FindFirstChild("WaveState")
	if ws then
		for _, attr in ipairs({ "Phase", "PhaseStart", "PhaseEnd", "StartTime", "Cycle", "Tide", "Direction" }) do
			check("Attribut WaveState:" .. attr, ws:GetAttribute(attr) ~= nil)
		end
	end
else
	check("Remotes", false, "ReplicatedStorage.Remotes absent")
end

-- 6. Wave.lua présent
check("Wave.lua", WaveModule ~= nil, WaveModule and WaveModule.ClassName or "absent")

-- 8. Config.Shop requise
if Config and Config:IsA("ModuleScript") then
	local okC, cfg = pcall(require, Config)
	if okC and type(cfg) == "table" then
		check("Config.Shop", type(cfg.Shop) == "table")
		-- prix finaux attendus (79/149/99/249/199/399)
		local pass = cfg.Shop and cfg.Shop.Passes or {}
		check("Shop.VIPRider price", pass.VIPRider and pass.VIPRider.price == 79, pass.VIPRider and tostring(pass.VIPRider.price) or "absent")
		check("Shop.SpeedBoost price", pass.SpeedBoost and pass.SpeedBoost.price == 149, pass.SpeedBoost and tostring(pass.SpeedBoost.price) or "absent")
		check("Shop.BagExpand price", pass.BagExpand and pass.BagExpand.price == 99, pass.BagExpand and tostring(pass.BagExpand.price) or "absent")
		check("Shop.StarterPack price", pass.StarterPack and pass.StarterPack.price == 249, pass.StarterPack and tostring(pass.StarterPack.price) or "absent")
		check("Shop.TideEgg price", cfg.Shop.TideEgg and cfg.Shop.TideEgg.price == 199, cfg.Shop.TideEgg and tostring(cfg.Shop.TideEgg.price) or "absent")
		check("Shop.PickCreature price", cfg.Shop.PickCreature and cfg.Shop.PickCreature.price == 399, cfg.Shop.PickCreature and tostring(cfg.Shop.PickCreature.price) or "absent")
		-- vague
		check("Vague hauteur 30", cfg.Wave and cfg.Wave.height == 30, cfg.Wave and tostring(cfg.Wave.height) or "absent")
	else
		check("Config require", false, tostring(cfg))
	end
else
	check("Config", false, "ReplicatedStorage.Shared.Config absent")
end

-- 11. Services attendus
local services = { "Net", "Stats", "DataService", "PlotService", "WaveService", "CreatureService",
	"CreatureFactory", "IntroService", "LagoonService", "StealService", "MountService",
	"RoyalService", "ShopService", "UpgradeService", "PetService", "DebugService", "SelfTest" }
local sFolder = SSS:FindFirstChild("Services")
for _, name in ipairs(services) do
	check("Service:" .. name, sFolder and sFolder:FindFirstChild(name) ~= nil)
end

-- 14. Debug présent (pour SelfTest)
check("ServerStorage.TR_Debug", Debug ~= nil)

-- composants orphelins premier niveau
local sourcemap = nil -- remplir par `rojo sourcemap` avant si besoin
print("=== Vérification des orphelins à faire via rojo sourcemap (étape IMPORT_LUNDI 7) ===")

-- Résumé
local fails = 0
for _, r in ipairs(results) do
	if not r.ok then fails += 1 end
end
print(string.format("=== RÉSULTAT : %d checks, %d FAIL, %d PASS ===", #results, fails, #results - fails))
if fails > 0 then
	warn("CHECKLIST MÉCANIQUE EN ÉCHEC — rollback si exécuté avant sync (voir docs/QA/ROLLBACK.md)")
else
	print("CHECKLIST MÉCANIQUE OK")
end

return results
