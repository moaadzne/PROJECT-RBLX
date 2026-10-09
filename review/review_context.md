# Tide Rush — review context (server, Roblox Luau)

Code under review: /Users/admin/Documents/claude code/tide-rush/src/ServerScriptService/
- Main.server.lua (Script, ServerScriptService.Main)
- Services/*.lua (ModuleScripts under ServerScriptService.Services): Net, Stats, ItemFactory, DataService, PlotService, TreasureService, WaveService, UpgradeService, PetService, DebugService, SelfTest

Shared config (ReplicatedStorage.Shared.Config, read-only for review): /Users/admin/Documents/claude code/tide-rush/review/Config.lua

The code will run in Roblox Studio and then on live servers (8 players max per server, mobile-first).
Teammates write the CLIENT against the remote contract below (out of scope), but the server must honour the contract exactly.

## Game design (spec)
- Beach X -132..132, Z -784..124, ground Y ~= 0..2 (terrain). Ocean around. Bases (plots) at Z > 0; beach zones at Z < 0.
- 5 zones (Config.Zones) going away from base (Z decreasing). Treasures spawn per zone up to maxItems every spawnEvery seconds, on Terrain only (never in decor or water), >= 6 studs apart.
- Player collects treasures (bag limited, Config Bag upgrade), pickup radius Config.PickupRadius checked by the server 10x/s.
- Every ~minute a giant wave: 35 s calm, 7 s warning, travels from Z=-800 at 46 studs/s and stops at Z=0, height 22, thickness 40, recede 2.5 s. Tower platforms at Y=26 (above the wave). Player caught if Z<0 and frontZ-40 <= Z <= frontZ and feet Y<22. NEVER caught on a tower platform nor in own base. Caught = loses only what they carry, teleported home 0.8 s later, no death screen, at most 1 catch per cycle. Disconnect during the wave must not error. No server CFrame update per frame.
- Base: 5 pedestals at start, up to 10. Deposit automatic when entering own plot rectangle (plot attributes MinX/MaxX/MinZ/MaxZ). When pedestals are full, a stronger treasure replaces the weakest; whatever doesn't fit is sold for income x Config.SellMultiplier.
- Income = sum of displayed items' income/s x (1 + sum of equipped pet boosts), paid once per second.
- Upgrades bought with coins: Speed 16..40 (+2/level, cost 50*2^n), Bag 2..10 (cost 75*2.2^n), Slots 5..10 (cost 200*3^n). WalkSpeed applied, pedestal unlocked.
- Pets: eggs bought with in-game coins ONLY (never Robux — halal rule + Roblox rules: no paid random draws). 3 equipped max, 40 inventory max. "Equip best". Full pet system is Phase 2; remotes must answer cleanly now.
- Home button (GoHome RF): refused outside "calm" phase (WaveActive), cooldown Config.HomeCooldown (Cooldown).
- Death (reset) loses the carried bag (otherwise reset = free teleport home with the bag) -> Notify bagLost.
- Server authority: validate every remote (type, existence, cost, rate limit -> RateLimited). No RemoteFunction without handler. StreamingEnabled = true: player:RequestStreamAroundAsync before teleporting.
- Data: DataStore load with 3 tries; if load fails the session NEVER saves (saveEnabled=false, Notify saveOff). Autosave every 90 s, on leave, and in BindToClose. Versioned schema v1 + reconciliation. Session locking so two servers never overwrite each other. Without Studio API access: no red error.
- Debug: ServerStorage.TR_Debug BindableFunction, Studio only: help, addCoins, forceWave, give, state, selftest (+ level, home, treasures, save).
- Team rule: the server depends only on NAMES and ATTRIBUTES (Plots/PlotN: Index, MinX, MaxX, MinZ, MaxZ, SpawnPos; Pedestals/PedestalN: Slot, LockGui, height Size.X; Towers: Center), never on decor geometry (decor is being rebuilt). The server does NOT write the sign text; it only sets plot attributes Owner (UserId) / OwnerName (DisplayName), removed when free.

## Map facts (verified in Studio)
- workspace.Map.Plots.Plot1..Plot8: attributes Index, MinX, MaxX, MinZ (=4), MaxZ (=67), SpawnPos (Vector3, Y=1 = deck top). Children: Pedestals folder with Pedestal1..10 (Parts, cylinders lying on their side, height = Size.X = 2, Position.Y = 2, attribute Slot, child BillboardGui "LockGui" with a TextLabel) and Rim1..10; Display folder (empty, runtime); SignAnchor.OwnerGui.Title (TextLabel).
- workspace.Map.Towers.Tower1..10: attribute Center (Vector3 at ground), platform top at Y 26, ramp toward +Z until Center.Z + 48.
- ReplicatedStorage.Assets.Items.<ItemId>: Models, PrimaryPart "Root" (invisible), attributes ItemId, Rarity; all parts Anchored.
- ReplicatedStorage.Assets.FX.RarityBeam: Part with Attachments BeamA/BeamB and Beams "Core" and "Halo" (style for Epic/Legendary beacons).
- SpawnLocation at hub (0, 0.6, 96), neutral. Players.CharacterAutoLoads = true.

## Remote contract v1 (published to teammates — server must match)
Times: workspace:GetServerTimeNow().
GetState (RemoteFunction): GetState() -> (state, wave). state.loaded=false while loading; StateChanged follows when ready. state may be nil (player not tracked yet, or rate limited); wave is always a table.
StateChanged (RemoteEvent S->C): (state) full snapshot on each change (coins: 1/s)
  state = { loaded, saveEnabled, coins, income (per s, boosts incl.), baseIncome, petBoost (0.3=+30%),
    bag={itemId...}, bagMax, levels={Speed,Bag,Slots}, slots (5..10),
    display={itemId or "", ...} dense array of length slots, plot (1..8, 0=none), walkSpeed, homeReadyAt (server time),
    pets={{uid="1", id="CrabBuddy"}...}, equipped={uid...},
    stats={pickups, deposited, sold, caught, wavesSurvived, eggsHatched, upgradesBought, coinsEarned},
    collection={[itemId]=count} }
WaveState (RemoteEvent S->C): (wave) on each phase change + to the arriving player
  wave = {phase="calm"|"warning"|"wave"|"recede", phaseStart, phaseEnd, startTime, cycle}
  startTime = departure of the (current or next) wave from Config.Wave.startZ.
  frontZ = math.min(endZ, startZ + speed*(now - startTime)); body = [frontZ - thickness, frontZ].
  Also mirrored as attributes on Remotes.WaveState: Phase, PhaseStart, PhaseEnd, StartTime, Cycle.
Notify (RemoteEvent S->C): (kind, data), data.text always present (English)
  welcome {text}; saveOff {text}; pickup {itemId, rarity, position (Vector3), bagCount, bagMax, isNew};
  bagFull {bagMax} (max once per 3 s); deposit {items={itemId...}, slots={slot...}}; sold {itemId, coins} (one per sold item);
  caught {lost=n, items={...}} (teleport home 0.8 s later); bagLost {lost=n}; upgrade {kind, level, value};
  hatch {eggId, petId, uid, rarity}; error {code, text}; info {text}; survived {text}
BuyUpgrade (RF): BuyUpgrade(kind "Speed"|"Bag"|"Slots") -> (true, newLevel) | (false, code)
GoHome (RF): GoHome() -> (true) | (false, code)   refused outside "calm" and during cooldown
HatchEgg (RF): HatchEgg(eggId) -> (true, petId, uid) | (false, code)
EquipPet (RF): EquipPet(uid, equip bool) -> (true) | (false, code); EquipPet("best", true) = Equip best; EquipPet("best", false) -> (false, "BadRequest")
Codes: BadRequest, RateLimited, NotLoaded, NotEnoughCoins, MaxLevel, Cooldown, WaveActive, NoPlot, InventoryFull, UnknownPet, EquipFull, ServerError
Runtime objects: workspace.Treasures models (ModelStreamingMode Atomic, tag TR_Spin, attributes ItemId, Rarity, Zone, BasePos, BaseYaw, SpinSpeed, Bob; Epic/Legendary get clones of FX.RarityBeam Core+Halo between Root.BeamA and Root.BeamB at Y+42); Map.Plots.PlotN.Display (same + Slot, Zone=0); plot attributes Owner/OwnerName; Player attributes Plot, Loaded, Pets ("CrabBuddy,Turtle"); leaderstats Coins/Income StringValues.

## Design notes on DataService (v2, after a first review round)
- Per-profile lock token (lock = {s=server session, p=profile token, j, t}); claim waits while another profile holds a fresh lock (< AUTOSAVE_EVERY+30 s), asks the holder to release via MessagingService topic "TR_Release" (holder saves, releases and kicks the player), and forces after 10 x 3 s.
- Final save on leave is retried up to 4 times. Shutdown also waits for in-flight loads.
- Unknown ids/levels read from the DataStore are kept in data.legacy instead of being erased.
- Permanent errors (Studio without API access, unpublished place) fail fast without retries.
