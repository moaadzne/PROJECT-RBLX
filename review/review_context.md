# Tide Rush : Reef Keepers — contexte serveur et contrat des remotes v2

Mis à jour par A le 2026-10-09. Le contrat v1 (trésors) est remplacé : le client v1 n'est pas compatible, B code contre la v2.
Référence design : docs/GDD.md (§1 ter, §4, §5, §8, §12, §13) et docs/TABLEAU.md (décisions de D).

## Code serveur
- `src/ServerScriptService/Main.server.lua` (Script) ; `Services/*.lua` (ModuleScripts) : Net, Stats, DataService, PlotService, WaveService, CreatureService, CreatureFactory, IntroService, UpgradeService, PetService, DebugService, SelfTest.
- Config partagée (lue aussi par le client, source unique des chiffres et des probabilités affichées) : `ReplicatedStorage.Shared.Config`.
- 8 joueurs max par serveur, mobile d'abord. Serveur qui fait autorité : temps, stades, mutations et valeurs sont calculés côté serveur.

## Règles de jeu (Phase 1, GDD §12)
- Zone ouverte : Shallows (zone 1). Les zones 2 à 5 sont dans Config mais `open = false`.
- **Marée** : chaque cycle de vague a un type (`Normal` ou `Golden` en Phase 1). Calendrier déterministe à partir du numéro de cycle (Config.TideSchedule).
- **Créatures sur la plage** : au début du calme, la plage se remplit ; pendant le calme, elle se recharge. La **mutation est tirée à l'apparition**, avec les chances de la marée en cours (Config.Tides). La vague emporte les créatures de la plage au passage de son front.
- **Capture** : au contact (rayon Config.PickupRadius, vérifié 10 fois/s par le serveur), sac limité (Bag).
- **Dépôt** automatique en entrant dans sa base : bassin libre d'abord ; lagon plein → la nouvelle remplace la plus faible si elle vaut plus (revenu/s courant, stade et mutation compris) ; sinon elle est relâchée contre des pièces. Une créature remplacée est relâchée aussi. Prix de relâche = revenu bébé (mutation comprise) × Config.SellMultiplier.
- **Croissance** : 4 stades (Config.Stages) calculés depuis `born` (heure Unix du serveur, au dépôt). Aucune minuterie : la croissance hors ligne est automatique.
- **Revenu** /s = Σ (base × mult. de stade × mult. de mutation) × (1 + bonus compagnons + bonus Codex), versé chaque seconde.
- **Hors ligne** : 50 % du revenu (croissance comprise), plafonné à 8 h, versé au chargement (Notify `offline`).
- **Reef Codex** : une case par espèce × variante (Config.CodexVariants : `Normal`, `Golden` en Phase 1). Nouvelle case à la capture : revenu de base × 50 pièces. Ligne d'espèce complète : +5 % de revenu permanent. Jamais remis à zéro.
- **LagoonTier** (1..5) : calculé à partir du revenu/s (Config.LagoonTiers), écrit en attribut sur PlotN.
- **Vague** (inchangée) : 35 s de calme, 7 s d'alerte, part de Z = -800 à 46 studs/s, s'arrête à Z = 0, hauteur 22, épaisseur 40. Prise si Z < 0, dans le corps de la vague et pieds sous 22. Jamais sur une tour ni dans sa base. Prise = sac perdu, retour à la base 0,8 s plus tard, au plus 1 prise par cycle.
- **Intro par joueur** (GDD §1 ter), pour un nouveau joueur seulement :
  - spawn dans son lagon ;
  - 5 créatures personnelles près du lagon : un Pebble Crab à environ 10 studs, puis 3 autres, puis une Sand Star Golden plus loin ;
  - **vague d'intro personnelle** 18 s après le chargement : elle ne peut pas attraper le joueur, mais elle emporte ses créatures personnelles restées sur le sable ;
  - au premier calme global qui suit, **marée Golden personnelle** : sa WaveState indique `tide = "Golden"` et 5 créatures personnelles sont tirées avec les chances Golden, dont au moins une Golden ;
  - ensuite, le calendrier normal.
- Mort ou reset = sac perdu (Notify `bagLost`). Bouton Home refusé hors du calme (`WaveActive`) et pendant le cooldown (`Cooldown`).
- Données : DataStore, 3 essais, verrou de session, autosave 90 s, sauvegarde au départ et dans BindToClose. Si le chargement échoue, la session ne sauvegarde jamais (Notify `saveOff`). Schéma v2 ; une donnée v1 est rangée dans `legacy.v1`, rien n'est effacé.
- Le serveur dépend seulement des NOMS et des ATTRIBUTS de la carte : `Plots/PlotN` (Index, MinX, MaxX, MinZ, MaxZ, SpawnPos), `Pedestals/PedestalN` (Slot, LockGui, hauteur Size.X ; un bassin = un PedestalN), `Towers/TowerN` (Center).
- Modèles : `ReplicatedStorage.Assets.Creatures.<Species>`. **Repli** tant qu'ils manquent : `Assets.Items.<ancien trésor>` via Config.LegacyItemToCreature.

## Contrat des remotes v2 (publié pour B — le serveur s'y tient exactement)

**Temps.** Toutes les heures du contrat sont en secondes Unix, comparables à `workspace:GetServerTimeNow()`. `state.serverNow` donne l'heure du serveur au moment du snapshot.

**Création.** Le serveur crée au démarrage les remotes qui manquent dans `ReplicatedStorage.Remotes`. Le client fait `WaitForChild`.

### GetState (RemoteFunction)
`GetState() -> (state, wave)`.
- `state` peut être nil : joueur pas encore suivi, ou limite de fréquence.
- `state.loaded = false` pendant le chargement ; un StateChanged suit quand c'est prêt.
- `wave` est toujours une table : celle de **ce joueur**, donc l'intro ou la Golden personnelle le cas échéant.

### StateChanged (RemoteEvent S→C) : `(state)`, snapshot complet à chaque changement (au plus 10 fois/s)
```
state = {
  loaded, saveEnabled, serverNow,
  coins, income,            -- income = revenu/s total, bonus compris
  baseIncome,               -- Σ revenus des créatures, sans bonus
  petBoost, codexBonus,     -- 0.3 = +30 %
  bag = { {species, mutation}, ... }, bagMax,
  levels = {Speed, Bag, Slots}, slots,   -- slots = nombre de bassins ouverts (5..10)
  pools = { [1..slots] = creature | false },   -- tableau dense, false = bassin vide
  plot,                     -- 1..8, 0 = aucune base
  lagoonTier,               -- 1..5
  walkSpeed, homeReadyAt,
  intro,                    -- "intro" | "golden" | "done"
  codex = { [species] = { [variant] = true } }, codexCount, codexTotal,
  pets = {{uid, id}}, equipped = {uid...},
  stats = {pickups, deposited, released, caught, wavesSurvived, eggsHatched, upgradesBought, coinsEarned, mutationsFound, offlineCoins},
}
creature = {
  uid,                      -- chaîne, unique par joueur
  species,                  -- clé de Config.Creatures
  mutation,                 -- "" (aucune) ou clé de Config.Mutations
  born,                     -- heure du dépôt
  stage,                    -- 1..4 (index dans Config.Stages)
  nextStageAt,              -- heure du prochain stade, 0 si Giant
  income,                   -- revenu/s de cette créature (stade et mutation), sans bonus
}
```
Le client peut afficher la progression entre deux snapshots grâce à `born`, `nextStageAt` et `serverNow`. Le serveur reste la référence : au changement de stade, il envoie un `grown` et un nouveau snapshot.

### WaveState (RemoteEvent S→C) : `(wave)`, à chaque changement de phase, et à l'arrivée du joueur
```
wave = {
  phase = "calm" | "warning" | "wave" | "recede",
  phaseStart, phaseEnd, startTime, cycle,
  tide,                     -- "Normal" | "Golden" (Phase 2 : "Night", "Storm", "Rainbow")
  nextSpecial = { tide, cycle },   -- prochaine marée spéciale du calendrier global
  intro,                    -- true seulement pour la vague d'intro personnelle
  startZ, speed,            -- présents seulement si différents de Config.Wave (vague d'intro)
}
```
- `startTime` = départ de la vague, en cours ou à venir.
- `frontZ = math.min(Config.Wave.endZ, (wave.startZ or Config.Wave.startZ) + (wave.speed or Config.Wave.speed) * (now - startTime))`. Corps de la vague = `[frontZ - thickness, frontZ]`.
- Copie de la vague **globale** en attributs sur `Remotes.WaveState` : Phase, PhaseStart, PhaseEnd, StartTime, Cycle, Tide. Pendant une intro ou une Golden personnelle, ce qui fait foi pour le joueur, c'est l'événement WaveState, pas ces attributs.

### Notify (RemoteEvent S→C) : `(kind, data)`, `data.text` toujours présent (anglais)
| kind | data |
|---|---|
| welcome | `{text, isNew}` |
| saveOff | `{text}` |
| capture | `{species, mutation, rarity, position (Vector3), bagCount, bagMax, isNew}` (isNew = nouvelle case du Codex) |
| bagFull | `{bagMax}` (au plus une fois toutes les 3 s) |
| deposit | `{placed = {{slot, species, mutation}}}` |
| released | `{species, mutation, coins, slot}` (slot présent si c'était une créature remplacée dans un bassin) |
| grown | `{uid, slot, species, stage}` |
| codex | `{species, variant, coins, count, total, rowComplete}` |
| offline | `{seconds, coins}` (seconds = durée comptée, plafonnée) |
| caught | `{lost, items = {{species, mutation}}}` (retour à la base 0,8 s plus tard) |
| bagLost | `{lost}` |
| survived | `{text}` |
| upgrade | `{kind, level, value}` |
| hatch | `{eggId, petId, uid, rarity}` |
| error | `{code, text}` |
| info | `{text}` |

### RemoteFunctions
- `BuyUpgrade(kind "Speed"|"Bag"|"Slots") -> (true, newLevel) | (false, code)` ; « Slots » s'affiche « Pools ».
- `GoHome() -> (true) | (false, code)` : refusé hors du calme de la vague du joueur, et pendant le cooldown.
- `HatchEgg(eggId) -> (true, petId, uid) | (false, code)` : œufs en pièces (Phase 2 pour l'interface, le serveur répond déjà).
- `EquipPet(uid, equip bool) -> (true) | (false, code)` ; `EquipPet("best", true)` équipe les meilleurs.
- Codes : BadRequest, RateLimited, NotLoaded, NotEnoughCoins, MaxLevel, Cooldown, WaveActive, NoPlot, InventoryFull, UnknownPet, EquipFull, ServerError.

### Emplacements réservés (Phase 2, NON implémentés, forme provisoire jusqu'au GDD v2)
Ces noms sont réservés : personne ne les utilise pour autre chose. Le serveur ne les crée pas encore.
- **Vol entre lagons** :
  - RF `StealAttempt(plot, slot) -> (true, stealId) | (false, code)` ;
  - RE S→C `StealResult(result)`, avec `result = {stealId, thief, victim, species, mutation, success}` ;
  - attribut `LockedUntil` (heure) sur PlotN = verrou de lagon ;
  - Notify `stolen` ;
  - codes prévus : `Locked`, `TooFar`, `NotStealable`.
- **Monture** :
  - RF `Mount(mountId) -> (true) | (false, code)` et `Dismount() -> (true)` ;
  - attribut joueur `Mount` ;
  - `state.mounts`, `state.mount`.
- **Marée Royale** (compétition de marée) :
  - `wave.royal = {active, endsAt}` ;
  - RE S→C `RoyalBoard(board)`, avec `board = {{userId, name, score}}` ;
  - Notify `royalResult {rank, reward}`.

### Objets et attributs à l'exécution
- `workspace.Creatures` : créatures de la plage.
  - Modèles en ModelStreamingMode Atomic, tag `TR_Spin`.
  - Attributs : CreatureId, Rarity, Mutation ("" si aucune), Stage (= 1), Zone, BasePos, BaseYaw, SpinSpeed, Bob.
  - `Owner` (UserId) seulement sur une créature personnelle de l'intro : le client la cache aux autres joueurs, et seul ce joueur peut l'attraper.
- `Map.Plots.PlotN.Display` : une créature par bassin, avec les mêmes attributs + Slot, Uid, Born, Stage (1..4), Zone = 0. Le client applique l'échelle du stade (Config.Stages[stage].scale) et le look de mutation (CreatureLook, côté C/B).
- PlotN : attributs `Owner` (UserId), `OwnerName` (DisplayName), `LagoonTier` (1..5). Owner et OwnerName sont retirés quand la base est libre.
- Joueur : attributs `Plot`, `Loaded`, `Pets` ("CrabBuddy,Turtle"), `Bag` ("PebbleCrab:Golden,SandStar:" pour afficher la pile sur la tête).
- leaderstats : `Coins` et `Income` (StringValue).

## Debug (Studio seulement) : ServerStorage.TR_Debug (BindableFunction)
Commandes : help, state, addCoins, give, level, forceWave, tide, grow, intro, home, creatures, save, selftest.
