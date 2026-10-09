# Ride the Tsunami (Reef Keepers) — contexte serveur et contrat des remotes v2.1

Mis à jour par A le 2026-10-09. Le contrat v1 (trésors) est remplacé : le client v1 n'est pas compatible, B code contre la v2.
- **v2.1** (GDD v2 « Steal & Ride ») : ouverture des lagons, vol, monture, Marée Royale et boutique sont en Phase 1. Elles remplacent les « emplacements réservés » de la v2.
- **v3 des noms** (GDD v3, DIRECTION_V2) :
  - espèces : GhostCrab, CushionStar, Lionfish, HawksbillTurtle, BlueRingedOctopus, LeopardRay, GiantPacificOctopus, LionsManeJelly, MantaRay, WhaleShark ;
  - stades : Juvenile / Adult / Elder / Titan (indices 1..4 inchangés) ;
  - monture dès Elder ; Titan surfe ;
  - les anciens ids sont traduits à la lecture des données (Config.LegacyItemToCreature).
- Le serveur met `Humanoid.DisplayDistanceType = None` à chaque personnage : plus de nom ni de barre de vie Roblox.
- Tout le reste de la v2 est inchangé.
Référence design : docs/GDD.md v2 (§1 ter, §2, §4.6–4.8, §9, §11, §12, §13) et docs/TABLEAU.md (décisions de D).

## Code serveur
- `src/ServerScriptService/Main.server.lua` (Script) ; `Services/*.lua` (ModuleScripts) : Net, Stats, DataService, PlotService, WaveService, CreatureService, CreatureFactory, IntroService, LagoonService, StealService, MountService, RoyalService, ShopService, UpgradeService, PetService, DebugService, SelfTest.
- Config partagée (lue aussi par le client, source unique des chiffres et des probabilités affichées) : `ReplicatedStorage.Shared.Config`.
- 8 joueurs max par serveur, mobile d'abord. Serveur qui fait autorité : temps, stades, mutations et valeurs sont calculés côté serveur.

## Règles de jeu (Phase 1, GDD §12)
- **Île ouverte** (GDD §3 bis, P1-36) :
  - île d'environ 600 × 600 centrée sur Config.Island.center ;
  - crique de rayon 70 au centre, avec les 8 lagons : la vague n'y prend personne et on n'y capture rien ;
  - créatures en **anneaux** (Config.Rings : 70–150 Ghost Crab ; 150–225 Ghost Crab / Cushion Star ; 225–300 Cushion Star / Hawksbill Turtle, montable) ;
  - plus de zones alignées sur Z (Config.Zones, Config.Beach et BaseLineZ sont supprimés).
- **Phases et lagons** (GDD §2) :
  - calme : les lagons sont **fermés** ;
  - alerte et vague : ils sont **ouverts**, c'est la fenêtre de vol, sauf lagon verrouillé ou protégé ;
  - reflux : ils se referment.
  Le propriétaire entre toujours chez lui.
- **Marée** : chaque cycle de vague a un type (`Normal` ou `Golden` en Phase 1). Calendrier déterministe à partir du numéro de cycle (Config.TideSchedule).
- **Créatures sur la plage** : au début du calme, la plage se remplit ; pendant le calme, elle se recharge. La **mutation est tirée à l'apparition**, avec les chances de la marée en cours (Config.Tides). La vague emporte les créatures de la plage au passage de son front.
- **Capture** : au contact (rayon Config.PickupRadius, vérifié 10 fois/s par le serveur), sac limité (Bag).
- **Dépôt** automatique en entrant dans sa base : bassin libre d'abord ; lagon plein → la nouvelle remplace la plus faible si elle vaut plus (revenu/s courant, stade et mutation compris) ; sinon elle est relâchée contre des pièces. Une créature remplacée est relâchée aussi. Prix de relâche = revenu au stade Juvenile (mutation comprise) × Config.SellMultiplier.
- **Croissance** : 4 stades (Config.Stages) calculés depuis `born` (heure Unix du serveur, au dépôt). Aucune minuterie : la croissance hors ligne est automatique.
- **Revenu** /s = Σ (base × mult. de stade × mult. de mutation) × (1 + bonus compagnons + bonus Codex), versé chaque seconde.
- **Hors ligne** : 50 % du revenu (croissance comprise), plafonné à 8 h, versé au chargement (Notify `offline`).
- **Reef Codex** : une case par espèce × variante (Config.CodexVariants : `Normal`, `Golden` en Phase 1). Nouvelle case à la capture : revenu de base × 50 pièces. Ligne d'espèce complète : +5 % de revenu permanent. Jamais remis à zéro.
- **LagoonTier** (1..5) : calculé à partir du revenu/s (Config.LagoonTiers), écrit en attribut sur PlotN.
- **Vague** :
  - 35 s de calme, 7 s d'alerte, 46 studs/s, **hauteur 30** (plateformes des tours à 34 = height + 4), épaisseur 40 ;
  - **une direction par cycle** (N/E/S/W, jamais deux fois de suite la même). Elle est tirée au début du cycle et annoncée dès le calme ; la suivante est aussi connue ;
  - elle traverse toute l'île sur son axe, de -reach à +reach (reach = size/2 + seaMargin = 330) ;
  - prise si l'axe du joueur est dans `[front - thickness, front]`, pieds sous 30 et hors de la crique. Tours, remparts, belvédère et terrain haut sont des abris (pieds au-dessus de 30), et une monture Titan surfe ;
  - prise = sac perdu, retour à la base 0,8 s plus tard, au plus 1 prise par cycle.
- **Intro par joueur** (GDD §1 ter), pour un nouveau joueur seulement :
  - spawn dans son lagon ;
  - 5 créatures personnelles près du lagon : un Ghost Crab à environ 10 studs, puis 3 autres, puis une Cushion Star Golden plus loin ;
  - **vague d'intro personnelle** 18 s après le chargement : elle ne peut pas attraper le joueur, mais elle emporte ses créatures personnelles restées sur le sable ;
  - au premier calme global qui suit, **marée Golden personnelle** : sa WaveState indique `tide = "Golden"` et 5 créatures personnelles sont tirées avec les chances Golden, dont au moins une Golden ;
  - ensuite, le calendrier normal.
- **Vol** (GDD §4.7) :
  - pendant la fenêtre, on entre dans un lagon ouvert et on maintient 1 s près d'un bassin (`StartSteal`) ;
  - on porte 1 créature à la fois, vitesse ×0,8, impossible de monter ;
  - il faut rentrer chez soi avant la fin du reflux, sinon la créature retourne chez son propriétaire ;
  - elle retourne aussi chez lui s'il touche le voleur, si le voleur est pris par la vague ou meurt, ou si l'un des deux part.
  - Protections, toutes vérifiées par le serveur :
    - jamais la dernière créature, jamais une créature montée ;
    - débutant : moins de 15 min de jeu cumulé ou moins de 4 créatures. Il ne peut ni voler ni être volé ;
    - après un vol subi : 2 vagues de protection, plus un marqueur Revanche contre le voleur (son lagon s'ouvre pour toi à l'alerte suivante, même verrouillé) ;
    - plus de 3 vols subis en 10 min : verrou automatique ;
    - verrou gratuit (`LockLagoon`) : 1 vague, puis 4 cycles de recharge.
  - Un joueur hors ligne n'a pas de lagon : il ne peut pas être volé.
- **Monture** (GDD §4.6) :
  - espèces de Config.Mount, à partir du stade Elder, une seule à la fois ;
  - vitesse : Elder ×1,3, Titan ×1,6 ;
  - une Titan n'est jamais prise par la vague, elle la surfe, et le joueur garde son sac ;
  - une créature montée rapporte toujours son revenu et ne peut pas être volée ;
  - la vitesse passe uniquement par WalkSpeed, fixé par le serveur, qui vérifie aussi la vitesse réelle.
- **Marée Royale** (GDD §4.8), à chaque marée spéciale :
  - le score est la valeur (revenu/s) des créatures attrapées et volées pendant le cycle ;
  - à la fin du reflux, le top 3 reçoit une couronne et des pièces (5 / 3 / 2 min de son revenu) ;
  - une **créature royale** unique apparaît au bout de la zone, toujours Golden.
- **Boutique** (GDD §9) :
  - 3 gamepasses : FastGrowth (croissance ×2), BigNet (rayon de capture ×1,5), VIPRider (+10 % pièces, +10 % vitesse de monture) ;
  - Tide Egg (aléatoire, probabilités affichées) **ou** Pick a Creature (choix direct), selon `ArePaidRandomItemsRestricted` ;
  - ProcessReceipt idempotent ; les ids Roblox sont dans Config.Shop (0 = produit désactivé).
- Mort ou reset = sac perdu (Notify `bagLost`). Bouton Home refusé hors du calme (`WaveActive`) et pendant le cooldown (`Cooldown`).
- Données : DataStore, 3 essais, verrou de session, autosave 90 s, sauvegarde au départ et dans BindToClose. Si le chargement échoue, la session ne sauvegarde jamais (Notify `saveOff`). Schéma v2 ; une donnée v1 est rangée dans `legacy.v1`, rien n'est effacé.
- Le serveur dépend seulement des NOMS et des ATTRIBUTS de la carte : `Plots/PlotN` (Index, SpawnPos, emprise du lagon = attributs **`Center`** (Vector3) + **`Radius`** (cercle horizontal ; île de C : rayon 17, centres à r = 48, angles k × 45°) ; replis : Part `PlotN.Bounds` tournée, puis MinX/MaxX/MinZ/MaxZ ; sortie du lagon côté mer), `Pedestals/PedestalN` (Slot, LockGui, hauteur Size.X ; un bassin = un PedestalN), `Towers/TowerN` (Center).
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
  newbie,                   -- true pendant la protection débutant (ni voler ni être volé)
  playTime,                 -- secondes de jeu cumulées
  mount,                    -- uid de la créature montée, "" sinon
  carrying,                 -- false, ou {species, mutation, victim (UserId), victimName} : créature volée portée
  lockActive,               -- true si le verrou couvre la fenêtre en cours ou la prochaine
  lockReadyAt,              -- heure où LockLagoon redevient possible (0 = prêt)
  shield,                   -- "" | "newbie" | "stolen" | "cap" | "lock" : pourquoi ton lagon reste fermé
  protectedUntil,           -- heure de fin de la protection après un vol subi (0 sinon)
  revenge,                  -- false, ou {userId, name} : la barrière de ce voleur s'ouvre pour toi à la prochaine fenêtre
  crown,                    -- 0 | 1 | 2 | 3 (Marée Royale)
  passes = {FastGrowth, BigNet, VIPRider},   -- booléens
  shop = {randomAllowed},   -- false : montrer Pick a Creature à la place du Tide Egg
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
  nextStageAt,              -- heure du prochain stade, 0 si Titan (dernier stade)
  income,                   -- revenu/s de cette créature (stade et mutation), sans bonus
  royal,                    -- true pour la créature royale
  mounted,                  -- true si c'est la monture active (le bassin s'affiche vide)
  carried,                  -- true si un voleur la porte en ce moment (le bassin s'affiche vide)
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
  direction,                -- "N" | "E" | "S" | "W" : d'où vient la vague de ce cycle ("" pour la vague d'intro)
  dir,                      -- Vector3 unitaire horizontal : sens dans lequel elle AVANCE (N = venue de -Z, avance vers +Z)
  nextDirection,            -- direction du cycle suivant (pour la boussole)
  intro,                    -- true seulement pour la vague d'intro personnelle
  startD, endD, speed,      -- présents seulement si différents des valeurs par défaut (vague d'intro)
  royal,                    -- {active = true, endsAt} pendant un cycle de Marée Royale, sinon absent
  extreme,                  -- marée extrême, pendant le calme de son cycle seulement : {active, revealAt, endsAt, center, radius}
}
```
- `startTime` = départ de la vague, en cours ou à venir.
- Front : `frontD = Config.WaveFrontD(wave, now)` = `min(endD, startD + speed * (now - startTime))`. Par défaut, startD = -reach et endD = +reach.
- Axe d'une position : `Config.WaveAxis(wave, p)` = `(p - Config.Island.center) · wave.dir`. Corps de la vague = axe dans `[frontD - thickness, frontD]`.
- La vague d'intro vient de la mer en face du lagon du joueur et s'arrête au bord de la crique (endD = -coveRadius).
- Copie de la vague **globale** en attributs sur `Remotes.WaveState` : Phase, PhaseStart, PhaseEnd, StartTime, Cycle, Tide, Direction. Pendant une intro ou une Golden personnelle, ce qui fait foi pour le joueur, c'est l'événement WaveState, pas ces attributs.

### Notify (RemoteEvent S→C) : `(kind, data)`, `data.text` toujours présent (anglais)
| kind | data |
|---|---|
| welcome | `{text, isNew = false}` : seulement pour un joueur qui revient. Un nouveau joueur ne reçoit aucun texte pendant son intro, et `state.intro` sert de drapeau de tutoriel. |
| stealStart | `{role = "victim"|"thief", thief, thiefName, victim, victimName, species, mutation, slot}` : la créature vient d'être prise (alerte du propriétaire) |
| stealWin | `{victim, victimName, species, mutation, slot}` : le voleur est rentré, la créature est à lui |
| stolen | `{thief, thiefName, species, mutation, protectedUntil}` : au volé, quand le vol réussit |
| stealFail | `{reason, push?}`, reason = "moved" \| "touched" \| "time" \| "wave" \| "died" \| "ownerLeft" \| "invalid" ; push = Vector3 (recul à jouer côté client si touché) |
| recovered | `{species, mutation, slot, reason}` : au propriétaire, sa créature est revenue |
| revenge | `{thief, thiefName}` : marqueur Revanche gagné |
| lock | `{active, readyAt}` |
| royal | `{phase = "start"|"end", top = {{userId, name, score}}, rank?, coins?}` |
| purchase | `{product, species?, mutation?}` : achat accordé |
| extreme | `{endsAt, count}` : à tous, au moment où le récif se découvre (marée extrême) |
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
- `LockLagoon() -> (true, readyAt) | (false, code)` : verrou gratuit ; couvre la fenêtre en cours (alerte/vague) ou la prochaine (calme/reflux).
- `StartSteal(plot, slot) -> (true, holdEndsAt) | (false, code)` :
  - démarre le maintien de 1 s ; le serveur prend la créature à `holdEndsAt` si le voleur n'a pas bougé (Notify `stealStart`), sinon `stealFail {reason = "moved"}` ;
  - à appeler debout dans le lagon visé, à moins de Config.Steal.grabRange studs du bassin.
- `Mount(uid | nil) -> (true) | (false, code)` : nil = descendre.
- `ChoosePick(species) -> (true) | (false, code)` : choix pour Pick a Creature, à appeler juste avant d'ouvrir l'achat. Sans choix, le serveur donne l'espèce de plus grande valeur.
- Codes : BadRequest, RateLimited, NotLoaded, NotEnoughCoins, MaxLevel, Cooldown, WaveActive, NoPlot, InventoryFull, UnknownPet, EquipFull, ServerError.
- Codes v2.1 : Closed (hors fenêtre), Locked (lagon verrouillé ou protégé), Newbie, LastCreature, Mounted, Carrying, TooFar, NotStealable, NotMountable, TooYoung, Busy.

### RemoteEvent RoyalBoard (S→C)
`(board)` avec `board = {cycle, endsAt, top = {{userId, name, score}}}`, trié, tous les joueurs du serveur. Il est envoyé au début de la manche, puis au plus une fois par seconde quand les scores changent.

### Objets et attributs à l'exécution
- `workspace.Creatures` : créatures de la plage.
  - Modèles en ModelStreamingMode Atomic, tag `TR_Spin`.
  - Attributs : CreatureId, Rarity, Mutation ("" si aucune), Stage (= 1), Zone (= index d'anneau, 0 hors anneaux), BasePos, BaseYaw, SpinSpeed, Bob.
  - `Owner` (UserId) seulement sur une créature personnelle de l'intro : le client la cache aux autres joueurs, et seul ce joueur peut l'attraper.
- `Map.Plots.PlotN.Display` : une créature par bassin, avec les mêmes attributs + Slot, Uid, Born, Stage (1..4), Zone = 0. Le client applique l'échelle du stade (Config.Stages[stage].scale) et le look de mutation (CreatureLook, côté C/B).
- PlotN : attributs `Owner` (UserId), `OwnerName` (DisplayName), `LagoonTier` (1..5). Owner et OwnerName sont retirés quand la base est libre.
- PlotN : `Open` (bool, barrière baissée pour tous), `Locked` (bool), `Shield` ("" | "newbie" | "stolen" | "cap" | "lock").
- `PlotN.Barrier` (Model de C) : attribut `Open`, écrit par le serveur. Le serveur règle `CanCollide` de ses parts. Les groupes de collision `TR_BarrierN` / `TR_CharN` laissent passer le propriétaire, et le joueur qui a la Revanche. B anime le visuel à partir de `Open`.
- Un joueur trouvé sans droit dans un lagon fermé est ramené devant la sortie, côté mer : Center + o·(Radius + 5), où o = direction de la crique vers le lagon (dans la brèche de la falaise). Vérification serveur 10 fois/s.
- Apparitions : uniquement sur le Terrain de plage (Config.Island.spawnMaterials = Sand, Mud), avec un sol entre spawnYMin et spawnYMax, et à plus de max(16, PlatformRadius + 4) studs du Center d'une tour.
- `Config.Upgrades[*].icon = ""` (plus d'emoji) ; le LockGui des bassins affiche « LOCKED ». Les icônes viennent de B, d'après `key`.
- Joueur : attributs `Plot`, `Loaded`, `Pets` ("CrabBuddy,Turtle"), `Bag` ("GhostCrab:Golden,CushionStar:" pour afficher la pile sur la tête).
- Joueur : `Carrying` ("HawksbillTurtle:Golden" ou ""), `Mount` (espèce ou ""), `MountStage` (3 ou 4), `Surfing` (bool, monture Titan pendant la vague), `Crown` (0..3), `Newbie` (bool), `VIP` (bool).
- Monture : le serveur soude au HumanoidRootPart un clone de la créature, à l'échelle de son stade. C fournit l'Attachment `Saddle` dans `Root`. Le serveur relève `Humanoid.HipHeight`. L'animation assise et le surf sont côté client.
- Créature royale : attribut `Royal = true` sur son modèle, sur la plage comme dans un bassin.
- **Marée extrême** (P1-37) :
  - environ 1 fois par heure (Config.IsExtremeCycle : cycle % 58 == 29), jamais en même temps qu'une marée spéciale ;
  - pendant le calme, de `revealAt` à `endsAt` (environ 25 s), le récif est découvert. Le récif = `Map.Reef` (attributs Center + Radius, construit par C), sinon le repli de Config.ExtremeTide.reef, au sud ;
  - des créatures rares y apparaissent (attribut `Reef = true`), puis le serveur les retire à `endsAt` ;
  - le retrait de la mer et son retour sont joués par le client d'après `wave.extreme`. Côté serveur, le récif reste sous l'eau ;
  - debug : `extreme`.
- leaderstats : `Coins` et `Income` (StringValue).

## Debug (Studio seulement) : ServerStorage.TR_Debug (BindableFunction)
Commandes : help, state, addCoins, give, level, forceWave, tide, grow, intro, home, creatures, save, selftest, playtime (sortir de la protection débutant), steal (vol forcé pour tester).
