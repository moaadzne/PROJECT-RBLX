# Architecture serveur : Reef Keepers (A, 2026-10-09)

Plan seulement. Rien n'est implémenté avant le « go » de D, une fois le GDD validé.
Les valeurs à reprendre du GDD de E sont notées **`[GDD: …]`**.

## 1. Ce qui reste tel quel

| Service | Statut | Note |
|---|---|---|
| Net | gardé | limite de fréquence, Handle/Notify/SetWave inchangés |
| DataService | gardé, schéma v2 | verrou de session, sauvegardes, BindToClose inchangés ; `_Sanitize` réécrit pour la v2 + migration |
| WaveService | gardé + type de marée | le cycle et la capture ne changent pas ; ajoute `tideType` au cycle |
| PlotService | gardé, socles → bassins | attribution, Home, téléport, revenu 1/s inchangés |
| UpgradeService | gardé | Speed, Bag (→ « Net »/filet), Slots (→ Pools) ; nouvelles clés dans Config |
| PetService | gardé | compagnons = bonus ; œufs en pièces uniquement, probabilités dans Config (affichables) |
| ItemFactory | gardé, renommé à terme CreatureFactory | ajoute taille (stade) et apparence de mutation |
| TreasureService | **remplacé** par CreatureService | même boucle de spawn / ramassage / dépôt |
| Stats | étendu | fonctions pures : croissance, valeur, mutations, Codex |
| DebugService, SelfTest | étendus | voir §6 |

## 2. Ce qui change

### 2.1 Trésors → créatures
- Une créature attrapée devient une **instance** (pas un simple id) : `{ uid, species, mutation, bornAt, stage }`.
- Sur la plage on garde des modèles légers (`species` + `mutation`), l'instance n'est créée qu'au ramassage.
- Espèces dans `Config.Creatures[speciesId] = { name, rarity, baseIncome, growTime = [GDD], stages = [GDD] }`.

### 2.2 Socles → bassins du lagon
- `display` (liste d'ids) devient `pools` : tableau dense de longueur `Stats.Pools(d)`, chaque case = uid ou `""`.
- Le dépôt reste automatique en entrant dans la base. Bassins pleins : on **n'écrase plus** une créature (elle a grandi, elle a de la valeur). Le surplus va dans un **aquarium de réserve** `storage` (max `[GDD: taille réserve]`), puis seulement au-delà : vente au prix `Stats.SellValue`.
- Attributs carte attendus (à confirmer avec C via D) : `Plots/PlotN/Pools/PoolN` avec attribut `Slot`, comme les Pedestals aujourd'hui.

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
  pets, equipped, petSeq,      -- inchangés
  codex = { [speciesId] = { seen, mutations = {...} } },
  rank = 0, codexClaimed = { [tier] = true },
  stats = { ...v1, creaturesCaught, mutationsFound, rebirths },
  firstJoin, lastSeen, legacy,
}
```

### Migration v1 → v2 (dans `_Sanitize`, idempotente)
1. `levels.Slots` → `levels.Pools`.
2. Chaque id de `display` : si l'id correspond à une espèce (table de correspondance `Config.LegacyItemToSpecies`, `[GDD]`) → créature `bornAt = now`, mutation `"None"`, placée au même bassin ; sinon → `legacy.display`.
3. `collection` → `codex[species].seen = true` pour les ids correspondants ; le reste en `legacy.collection`.
4. `v = 2`. Les données `v > 2` restent refusées (session sans sauvegarde), comme aujourd'hui.
5. Pas de vrais joueurs (jeu non publié) : la migration sert surtout à garder la discipline. Changer `STORE_NAME` reste possible si E/D préfèrent repartir de zéro.

## 4. Contrat des remotes v2

Inchangés : `GetState`, `StateChanged`, `WaveState`, `Notify`, `BuyUpgrade`, `GoHome`, `HatchEgg`, `EquipPet`, codes d'erreur.

Changements :
- `state` : `display` → `pools` (uids), + `creatures = { [uid] = { species, mutation, bornAt } }`, `storage`, `codex`, `rank`, `serverNow` (pour que le client calcule le stade sans sa propre horloge). `bag` devient une liste de `{ species, mutation }`.
- `wave` : + `tideType`.
- `BuyUpgrade(kind)` : kinds `"Speed" | "Bag" | "Pools"`.
- Nouveaux RF (tous validés + limités par Net) :
  - `MoveCreature(uid, target)` : `target = poolIndex | "storage"` → `(true) | (false, code)`.
  - `SellCreature(uid)` → `(true, coins) | (false, code)`.
  - `ClaimCodex(tier)` → `(true, reward) | (false, code)`.
  - `Rebirth()` → `(true, rank) | (false, code)` ; conditions vérifiées serveur.
- Nouveaux Notify : `catch {species, mutation, isNewSpecies, isNewMutation}` (remplace `pickup`), `grown {uid, stage}` (envoyé au prochain tick de revenu quand un stade change), `offline {seconds, coins}`, `tide {tideType}`, `codex {species, mutation}`.
- Nouveaux codes : `UnknownCreature`, `PoolFull`, `StorageFull`, `NotReady`.
- Attributs : modèles de plage + `Species`, `Mutation` ; bassins `Display` + `Uid`, `Stage`.

## 5. Règles non négociables (rappel, vérifiées dans le code)
- Aucun remote ne déclenche un tirage payant en Robux. Œufs en pièces uniquement. Toute probabilité vit dans Config.
- Achats Robux (plus tard, MarketplaceService) : prix fixe, `ProcessReceipt` idempotent (reçus enregistrés dans les données), jamais de pièces vendues.
- Serveur qui fait autorité : temps, stades, mutations, valeurs calculés côté serveur.

## 6. SelfTest à ajouter
- Config : chaque espèce a rarity/baseIncome/stages valides ; poids des marées > 0 ; chaque mutation a un mult.
- Croissance : `Stats.Stage` monotone, bornes (`now < bornAt`, très grand `elapsed`), plafond hors ligne.
- Migration : jeu de données v1 fixe → v2 attendu ; deuxième passage = identique (idempotence) ; ids inconnus dans `legacy`.
- Dépôt : bassins pleins → réserve → vente ; jamais d'écrasement d'une créature posée.
- Remotes : chaque nouveau RF répond `BadRequest` aux types faux, `RateLimited` en rafale, `UnknownCreature` sur un uid d'un autre joueur.
- Marée : `tideType` toujours dans Config.Tides ; publié dès `calm`.
- Codex : pas de double réclamation d'un palier.

## 7. Questions ouvertes (pour E via D)
- Revenu hors ligne : oui/non, taux, plafond.
- Stades (nombre, durées) et multiplicateurs par stade.
- Taille de la réserve ; la réserve grandit-elle ?
- Poids des marées et chances de mutation.
- Correspondance des trésors v1 → espèces (ou départ à zéro).
- Contenu exact du rebirth.
