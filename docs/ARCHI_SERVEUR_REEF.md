# Architecture serveur : Reef Keepers (A, 2026-10-09)

Plan initial du 09/10 matin. **Ce qui fait foi depuis le « go » de D : `review/review_context.md` (contrat v2) et `docs/TABLEAU.md`** (Phase 1 sans réserve, sans `MoveCreature` ni `ClaimCodex`, clé `Slots` gardée).
Les valeurs à reprendre du GDD de E sont notées **`[GDD: …]`**.

## 1. Ce qui se garde : la plomberie seulement

Le gameplay est refait de zéro d'après le GDD. On ne garde que la plomberie invisible qui marche (revue faite le 09/10) :

| Service | Ce qu'on garde | Ce qui change |
|---|---|---|
| DataService | profils, verrou de session, chargement en 3 essais, autosave, sauvegarde au départ, BindToClose, `legacy` | le contenu des données (§3) : nouveau `defaultData` et `_Sanitize` |
| Net | `Handle` (validation + limite de fréquence), `Notify`, `SetWave`, `Forget` | rien |
| PlotService | attribution des bases (Owner/OwnerName), `SendHome` (streaming + PivotTo), GoHome, boucle de revenu 1/s | l'affichage : les socles deviennent des bassins (`RenderDisplay` réécrit) |
| WaveService | cycle calm/warning/wave/recede, capture mathématique, 1 capture par cycle, déconnexion sans erreur | + `tideType` par cycle (§2.4) ; ce que la vague fait perdre suit le GDD |

Tout le reste est **réécrit** pour le nouveau design, sans chercher à réutiliser l'ancien code :
- `CreatureService` (nouveau) : apparition sur la plage, capture, dépôt, croissance ;
- `CodexService` (nouveau) : Reef Codex, paliers ;
- `Stats` : réécrit, fonctions pures (stade, valeur, revenu, mutations) ;
- améliorations, compagnons, Léviathan, rang : selon le GDD (TreasureService, ItemFactory, UpgradeService et PetService partent) ;
- DebugService et SelfTest : refaits autour des nouveaux services (§6).

## 2. Ce qui change

### 2.1 Créatures
- Une créature attrapée est une **instance** (pas un simple id) : `{ uid, species, mutation, bornAt }`. Le stade se calcule (§2.3).
- Sur la plage : modèles légers (`species` + `mutation`), l'instance n'est créée qu'à la capture.
- Espèces dans `Config.Creatures[speciesId] = { name, rarity, baseIncome, growTime = [GDD], stages = [GDD] }`.

### 2.2 Bassins du lagon
- `pools` : tableau dense de longueur `Stats.Pools(d)` `[GDD: nombre de départ / max]`, chaque case = uid ou `""`.
- Dépôt `[GDD: automatique en entrant dans la base, ou manuel]`. Bassins pleins : on **n'écrase jamais** une créature (elle a grandi, elle a de la valeur). Le surplus va dans une **réserve** `storage` (max `[GDD]`), puis seulement au-delà : vente au prix `Stats.SellValue`.
- Le serveur ne dépend que des noms et des attributs, jamais de la géométrie du décor. Attendu (à confirmer avec C via D) : `Plots/PlotN/Pools/PoolN` avec attribut `Slot`.

### 2.3 Croissance, y compris hors ligne
- **Seule source de temps : `os.time()` côté serveur.** Jamais l'heure du client.
- On stocke `bornAt` (os.time au moment de la capture) ; le stade se **calcule** : `Stats.Stage(creature, now)` = fonction pure de `now - bornAt - pausedFor`.
- Pas de boucle qui fait grandir : le revenu 1/s lit le stade courant (`Stats.Income(d, now)`).
- Hors ligne : à la connexion, `elapsed = clamp(now - lastSeen, 0, OFFLINE_CAP [GDD])`.
  - Croissance : automatique (calculée sur `bornAt`). Plafond optionnel `[GDD: croissance max hors ligne]` via `offlineCredit`.
  - Revenu hors ligne : `[GDD: oui/non, taux]` ; si oui, versé une fois au chargement, plafonné, notification `offline`.
- Garde-fous : horloge serveur qui recule → `max(0, …)` ; `bornAt > now` à la lecture → ramené à `now`.
- La réserve ne grandit pas (ou plus lentement, `[GDD]`) : sinon elle remplace le lagon.

### 2.4 Mutations selon la marée
- `WaveService` tire `tideType` au début de chaque cycle (`calm`) dans `Config.Tides = { {id="Normal", weight}, {id="Golden", …}, {id="Night", …}, {id="Storm", …} }` `[GDD: poids, effets]`. Tirage gratuit, côté serveur, probabilités dans Config (donc affichables).
- `wave.tideType` publié dans WaveState (+ attribut `TideType`) dès le calme : les clients préparent le rendu et la plage.
- Mutation fixée **au spawn** sur la plage (pas au ramassage) : `chance = Config.Tides[t].mutationChance [GDD]`. Le modèle porte l'attribut `Mutation`.
- Effet : multiplicateur de revenu `Config.Mutations[m].mult [GDD]`.

### 2.5 Reef Codex
- `codex[speciesId] = { seen = bool, mutations = { Golden = true, … }, maxStage = n }`.
- Mis à jour à la capture (et à la croissance pour `maxStage`, calculé à la volée).
- Paliers de récompense `[GDD]` réclamés via un remote (pas d'attribution silencieuse, pour éviter les doublons).
- Remplace `collection` (migré, voir §3).

### 2.6 Léviathan et Tide Rank (rebirth)
- Léviathan : condition serveur `Stats.LagoonScore(d) >= [GDD]` → événement serveur (phase spéciale de vague). Détail après GDD.
- Tide Rank : `rank` + reset `[GDD: ce qui est remis à zéro]`. Le Codex n'est **jamais** remis à zéro.

## 3. Schéma de données v2

```lua
{
  v = 2,
  coins, levels = { Speed, Bag, Pools }, -- "Slots" renommé "Pools"
  creatures = { [uid] = { species, mutation, bornAt } },
  creatureSeq = 0,
  pools = { uid | "" ... },   -- dense, longueur Stats.Pools(d)
  storage = { uid ... },       -- réserve
  -- compagnons, améliorations : champs selon le GDD
  codex = { [speciesId] = { seen, mutations = {...} } },
  rank = 0, codexClaimed = { [tier] = true },
  stats = { creaturesCaught, mutationsFound, wavesSurvived, caught, coinsEarned, rebirths, ... },
  firstJoin, lastSeen, legacy,
}
```

### Migration v1 → v2 : repartir de zéro, proprement
Le jeu n'a jamais été publié : aucun vrai joueur. On ne convertit donc pas l'ancien gameplay (pas de correspondance trésor → espèce).
1. Données `v = 1` lues : on garde **uniquement** `firstJoin` et les compteurs utiles ; tout le reste part dans `legacy.v1` (rien n'est effacé, comme aujourd'hui).
2. On écrit `v = 2` avec `defaultData` v2. Idempotent : des données déjà en v2 passent seulement par `_Sanitize`.
3. Données `v > 2` : refusées, session sans sauvegarde (comportement actuel, gardé).
4. Le nom du DataStore (`STORE_NAME`) ne change pas : la chaîne de versions reste continue pour les migrations futures.

## 4. Contrat des remotes v2

Gardés tels quels (plomberie) : `GetState` / `StateChanged` (snapshot complet, `loaded`, `saveEnabled`), `WaveState` (+ attributs), `Notify(kind, data)` avec `data.text`, `GoHome`, les codes `BadRequest`, `RateLimited`, `NotLoaded`, `NotEnoughCoins`, `Cooldown`, `WaveActive`, `NoPlot`, `ServerError`.

Nouveau :
- `state` : `coins`, `income`, `pools` (uids), `creatures = { [uid] = { species, mutation, bornAt } }`, `storage`, `bag` (liste de `{ species, mutation }`), `bagMax`, `codex`, `rank`, `plot`, `walkSpeed`, `homeReadyAt`, `stats`, `serverNow` (pour que le client calcule le stade sans sa propre horloge) ; le reste selon le GDD.
- `wave` : + `tideType`.
- Améliorations, compagnons, œufs : remotes définis après le GDD (`BuyUpgrade`, `HatchEgg`, `EquipPet` sont retirés ou redéfinis, pas gardés par défaut).
- RF prévus (tous validés + limités par Net) :
  - `MoveCreature(uid, target)` : `target = poolIndex | "storage"` → `(true) | (false, code)`.
  - `SellCreature(uid)` → `(true, coins) | (false, code)`.
  - `ClaimCodex(tier)` → `(true, reward) | (false, code)`.
  - `Rebirth()` → `(true, rank) | (false, code)` ; conditions vérifiées serveur.
- Notify : `catch {species, mutation, isNewSpecies, isNewMutation}`, `grown {uid, stage}` (envoyé au prochain tick de revenu quand un stade change), `offline {seconds, coins}`, `tide {tideType}`, `codex {species, mutation}`.
- Nouveaux codes : `UnknownCreature`, `PoolFull`, `StorageFull`, `NotReady`.
- Attributs : modèles de plage + `Species`, `Mutation` ; bassins `Display` + `Uid`, `Stage`.

## 5. Règles non négociables (rappel, vérifiées dans le code)
- Aucun remote ne déclenche un tirage payant en Robux. Œufs en pièces uniquement. Toute probabilité vit dans Config.
- Achats Robux (plus tard, MarketplaceService) : prix fixe, `ProcessReceipt` idempotent (reçus enregistrés dans les données), jamais de pièces vendues.
- Serveur qui fait autorité : temps, stades, mutations, valeurs calculés côté serveur.

## 6. SelfTest à ajouter
- Config : chaque espèce a rarity/baseIncome/stages valides ; poids des marées > 0 ; chaque mutation a un mult.
- Croissance : `Stats.Stage` monotone, bornes (`now < bornAt`, très grand `elapsed`), plafond hors ligne.
- Migration : un enregistrement v1 fixe → v2 par défaut + `legacy.v1` rempli ; deuxième passage identique (idempotence) ; v > 2 refusé.
- Dépôt : bassins pleins → réserve → vente ; jamais d'écrasement d'une créature posée.
- Remotes : chaque nouveau RF répond `BadRequest` aux types faux, `RateLimited` en rafale, `UnknownCreature` sur un uid d'un autre joueur.
- Marée : `tideType` toujours dans Config.Tides ; publié dès `calm`.
- Codex : pas de double réclamation d'un palier.

## 7. Questions ouvertes (pour E via D)
- Revenu hors ligne : oui/non, taux, plafond.
- Stades (nombre, durées) et multiplicateurs par stade.
- Taille de la réserve ; la réserve grandit-elle ?
- Poids des marées et chances de mutation.
- Contenu exact du rebirth.
