# GDD_REEF — Reef Keepers : spécification de référence

**Auteur : E (concept & game design). Écrit le 2026-10-10.**
Base : branche `claude/e-gdd-reef`, tirée du commit `06f2f54` (dernier état de A).

> **Règle de lecture.** Ce document ne réécrit pas `docs/GDD.md` (v3, la prose du concept) : il le **fige** là où A, B et C bloquent. Tout ce qui est déjà dans `ReplicatedStorage.Shared.Config` est **repris tel quel**, pas redécidé.
> **Avertissement honnête** : tous les chiffres ci-dessous sont des **valeurs de départ proposées par E** (choix de design), jamais des mesures ni des faits. Ils se règlent au playtest. Ce qui n'est pas décidé est écrit `[À DÉFINIR]` et listé au §14.

## 0. Ce que ce document tranche

| # | Décision | Statut |
|---|---|---|
| 1 | Les 30 premières secondes, minute par minute (§1) | **figé** — A l'a déjà codé dans `Config.Intro`, ce document aligne B et C dessus |
| 2 | 10 espèces, leurs zones, leur croissance, leur montabilité (§2) | **figé** — c'est le roster que C modélise |
| 3 | 5 marées + la marée extrême (§3) | **figé** — Phase 1 = Normal + Golden ; Phase 2 = Night, Storm, Rainbow |
| 4 | 5 zones de jeu et leur correspondance avec les 3 anneaux d'A (§4) | **figé** |
| 5 | 5 paliers de richesse et les 5 monuments du lagon (§5) | **figé** — seuils repris de `Config.LagoonTiers`, monuments repris de `DA_MONDE.md` §2 |
| 6 | Bassins, **réserve**, dépôt, mutations (§6, §8) | **figé** — la réserve n'existe pas encore dans le code d'A, je la décide ici |
| 7 | 5 paliers du Codex (§7) | **figé** — `ClaimCodex(tier)` n'a aucune table, je la donne |
| 8 | Réponses aux 5 questions ouvertes d'A (`ARCHI_SERVEUR_REEF.md` §7) (§9) | **figé** |
| 9 | Tide Rank / rebirth (§10) | **figé** — il manquait le contenu exact |
| 10 | Ce que B doit savoir (§11), ce que C doit savoir (§12) | **figé** |

---

## 1. LES 30 PREMIÈRES SECONDES, IMAGE PAR IMAGE

**Le moment le plus important du jeu.** Objectif, dans l'ordre : (1) « attends, c'est Roblox ça ? » ; (2) attraper un animal vivant ; (3) avoir **peur** de la vague ; (4) vouloir y retourner immédiatement.

La séquence est **entièrement pilotée par le serveur** (`IntroService` + `Config.Intro`) : elle est identique pour les 8 joueurs d'un serveur, et elle ne peut pas se passer « à moitié ». Si le joueur est déjà arrivé à 2 captures, le tutoriel saute, mais la vague d'intro reste.

### 1.1 Minutage

Les durées ci-dessous sont **déjà dans `Config.Intro`** (A). B et C doivent caler leurs animations dessus, pas l'inverse.

| Temps | Ce qu'il voit | Ce qu'il entend | Ce qu'il fait | Émotion visée |
|---|---|---|---|---|
| **0,0 – 1,5 s** | Écran de chargement maison (`ReplicatedFirst`, B). **Jamais d'écran noir** : plan aérien lent en mouvement au-dessus de l'île, couchant rasant, brume, lagon turquoise taillé dans la roche volcanique. | Vent, ressac, une note grave lointaine. | Rien. | « C'est beau, qu'est-ce que c'est » |
| **1,5 – 3,0 s** | Fondu au noir en 0,4 s puis la caméra se pose **derrière son avatar**, au bord de **son** lagon, au sable humide. Premier plan : son abri en bois flotté et ses cuvettes. **Interface : le joystick uniquement.** Aucun HUD. | La note grave s'éteint. L'océan reste. | Il regarde. | Curiosité |
| **3,0 – 7,0 s** | À **8 studs** devant lui, un **Ghost Crab** détale entre deux rochers, puis se fige, ses pédoncules oculaires dressés. Il **fuit** quand on approche (il faut le couper). | Crabales sur le sable, mouettes lointaines. | Il court après. | « C'est vivant » |
| **7,0 – 7,6 s** | **CATCH** : le crabe est soulevé en 0,15 s, gouttes d'eau et sable. Micro-ralenti 0,15 s. Le mot **CATCH** en capitales condensées, 0,25 s, puis disparaît. | Impact sec et lourd. Petit « splash ». | Contact = prise. | Satisfaction |
| **7,6 – 16,0 s** | La caméra s'ouvre : 4 autres créatures entre les rochers, de plus en plus loin (`Config.Intro.creatures` : Cushion Star à 20 studs, Ghost Crab à 26, Ghost Crab à 34). Il en attrape 2 ou 3, le sac se remplit. | Les mouettes s'envolent d'un coup. Le ressac **s'arrête**. | Il court, il coupe, il chope. | « Celle-là je la veux » |
| **16,0 – 18,0 s** | Il aperçoit, **48 studs** vers le large, une **Cushion Star dorée** : reflets métalliques, la seule chose dorée de l'écran. Impossible de l'attraper avant la vague. | Le silence devient étourdissant. | Il hésite, il part vers elle. | **Appât.** C'est volontaire. |
| **18,0 – 20,0 s** | **ALERTE.** La mer se retire **à vue d'œil** : sable découvert, poissons qui sautent, coques d'épaves. Le ciel fonce côté mer. À l'horizon, un **mur d'eau plus haut que les tours** se dresse, crête d'écume, son ombre qui balaie le sable. **Un seul mot au sol, en capitales : RUN.** | Grondement grave **dans les basses** qui monte, une corne. **Silence juste avant l'impact.** | Il comprend, sans lire. | **Peur.** |
| **20,0 – 29,0 s** | Course vers le lagon. Caméra plus basse, tremblement léger, embruns. La Cushion Star dorée est **avalée derrière lui** dans le reflux. | Le grondement couvre tout. | Il sprinte. | Adrénaline, regret |
| **29,0 – 29,6 s** | Il franchit sa barrière de corail : elle **s'enfonce** dans le sable avec un bruit de gravier. Ses 3 créatures plongent dans les cuvettes, chacune avec un splash lourd et une onde. | Gravier, puis 3 splashes. | Automatique. | Soulagement |
| **29,6 – 31,5 s** | La vague **s'écrase sur la barrière**, juste derrière lui. Pluie d'embruns à l'écran, le sable mouillé brille. Puis l'eau se retire. **Une seule ligne en bas : « NEXT TIDE: GOLDEN ».** | Impact lourd, puis ressac. | Il regarde le large. | « J'y retourne » |
| **31,5 s** | **Le HUD apparaît d'un coup** : pièces, revenu/s, sac, boussole, bouton Lagoon. | Le cycle normal démarre (calme 35 s). | Il joue. | Envie |

### 1.2 Les règles qui rendent cette séquence possible

1. **Aucun texte avant 18 s, sauf « CATCH ». Aucun HUD avant 31,5 s** — pas de pièces affichées, pas de barre de sac, pas de tutoriel. Le HUD n'existe pas encore.
2. **La vague d'intro est scénarisée** (`Config.Intro.waveDelay = 18`) : elle part de la mer **en face de son lagon** et s'arrête au bord de la crique. **Impossible d'être pris.** Le joueur ne perd rien, il apprend.
3. **La 2ᵉ marée du joueur est Golden** (`Config.Intro.goldenTide`), avec **5 créatures personnelles** dont au moins une mutée (`goldenCount = 5`). C'est le premier « wow » de collection, à 1 minute de jeu.
4. **Le son est la moitié de la peur.** Priorité Phase 1 pour C/B : grondement dans les basses, silence de 0,3 s avant l'impact.
5. **Si le chargement dépasse 2 s, la caméra reste en plan aérien.** Jamais de coupe, jamais de noir. (`IntroService` / `LoadingScreen` de B.)
6. **Ton des textes** (`DIRECTION_V2.md`) : capitales condensées, verbes d'action, 2 à 5 mots, **aucun emoji**, jamais de « Yay » ni de « !!! ».

---

## 2. LA LISTE COMPLÈTE DES CRÉATURES

**Roster figé : 10 espèces.** C modelledise les 3 premières (Phase 1), les 7 autres en Phase 2. Les ids sont **ceux de `Config.Creatures`** — A les a déjà écrits, ils ne changent pas.

Règles de lecture (issues de `CREATURES_ART.md`, contraignantes) : vrais animaux marins, anatomie et couleurs crédibles, **jamais de gros yeux ni d'air mignon**. La rareté se lit par la **taille, le matériau, la lumière et les particules** — la couleur de rareté (gris/vert/bleu/violet/or) vit dans l'interface, **jamais peinte sur l'animal**.

| # | Id Config | Animal | Rareté | Revenu/s Juvenile | Zone (§4) | Montable | Croissance A/E/T (min) | Statut art |
|---|---|---|---|---|---|---|---|---|
| 1 | `GhostCrab` | Crabe fantôme (*Ocypode*) | Common | **1** | 2 et 3 | non | 3 / 15 / 60 | **Phase 1 — à modéliser** |
| 2 | `CushionStar` | Étoile cushion (*Protoreaster*) | Common | **2** | 3 et 4 | non | 3 / 15 / 60 | **Phase 1 — à modéliser** |
| 3 | `Lionfish` | Poisson-lion | Uncommon | **6** | 5 (récif) | non | 5 / 30 / 120 | Phase 1, seulement au récif de marée extrême |
| 4 | `HawksbillTurtle` | Tortue imbriquée | Uncommon | **10** | 4 et 5 | **oui** (dès Elder) | 5 / 30 / 120 | **Phase 1 — à modéliser** |
| 5 | `BlueRingedOctopus` | Poulpe à anneaux bleus | Rare | **30** | 5, de nuit | non | 10 / 60 / 240 | Phase 2 |
| 6 | `LeopardRay` | Raie léopard | Rare | **50** | 5 (épave) | **oui** | 10 / 60 / 240 | Phase 2 |
| 7 | `GiantPacificOctopus` | Poulpe géant du Pacifique | Epic | **150** | 5 (épave) | non | 20 / 120 / 480 | Phase 2 |
| 8 | `LionsManeJelly` | Méduse à crins de lion | Epic | **250** | 5, au large | non | 20 / 120 / 480 | Phase 2 |
| 9 | `MantaRay` | Raie manta | Legendary | **800** | 5, marée Golden | **oui** | 30 / 240 / 1200 | Phase 2 |
| 10 | `WhaleShark` | Requin-baleine | Legendary | **1 500** | 5, événement | **oui** | 30 / 240 / 1200 | Phase 2 |

### 2.1 Règles de capture et de croissance

- **La rareté domine le stade.** Le revenu d'une espèce juvénile va de 1/s (Common) à 1 500/s (Legendary), soit un rapport de 1 à 1 500, alors que l'écart entre deux stades ne vaut que ×8. **Un Titan d'une espèce courante n'atteint donc jamais une juvénile d'une espèce deux raretés au-dessus** : une Légendaire juvénile vaut 94× un Common Titan. C'est voulu — les espèces communes servent aux dix premières minutes et à meubler la plage pendant une marée Golden ; la vraie valeur, c'est le haut du roster.

- **`bornAt` est fixé à la CAPTURE, pas au dépôt** (décision E, répond à `ARCHI_SERVEUR_REEF.md` §2.3). Le temps que tu portes une créature compte. C'est le risque du sac.
- Croissance **hors ligne comprise et sans plafond** : elle est calculée, donc gratuite. **Seul le revenu est plafonné** (§9).
- **Sac** : de 2 à 9 places (`Config.Upgrades.Bag`). Une capture au sac plein est refusée proprement (`Notify`), pas écrasée.
- **Espacement au sol** : `Config.CreatureSpacing = 7` studs, rayon de prise 6 studs. Les créatures ne se superposent jamais.

### 2.2 Modèles montables (spécification pour A, B et C)

Déjà écrite dans `CREATURES_ART.md` §3 bis, je la confirme :
- `Attachment Saddle` au centre de la carapace (axe avant `-Z`) + `SurfStand` 0,3 stud au-dessus.
- Montable à partir du stade **Elder** (`Config.Mount.minStage = "Elder"`), vitesse Elder ×1,3, **Titan ×1,6**.
- Une **Titan montée surfe la vague et n'est jamais prise** (`Config.Mount.giantSurfs`). C'est le sommet du jeu : you've earned it.
- Posture du joueur : **assis** (animation Sit) sur `Saddle`, **debout** sur `SurfStand` pendant le surf.
- Gabarit : dos ≥ 3 × 4 studs, à 2,5–3 studs du sol, longueur 7–8. Une Titan (×1,5) fait ~11 de long et un dos vers 4 studs.

---

## 3. LA LISTE COMPLÈTE DES MARÉES

Une marée est tirée **au début de chaque cycle de calme**, côté serveur (`WaveService`), publiée dans `WaveState` avec l'attribut `TideType`. Les probabilités sont dans `Config` et donc **affichables** — c'est une règle non négociable.

**Il y a deux choses à ne pas confondre** : la **marée** (un état du monde, avec sa lumière et sa probabilité de mutation) et la **marée extrême** (un événement qui Discovery le récif, environ 1 fois par heure).

### 3.1 Les marées

| Id | Nom affiché | Phase | Lumière (presets de C) | Mutation tirée à l'apparition | Poids |
|---|---|---|---|---|---|
| `Normal` | **NORMAL TIDE** | 1 | Couchant, ClockTime 17,05, ombres douces, brume chaude légère | `Golden` **0,5 %** | 7/8 du temps |
| `Golden` | **GOLDEN TIDE** | 1 | Soleil plus bas (17,45), Bloom +0,2, teinte dorée, Glare +0,3, brume dorée | `Golden` **30 %** | 1 marée toutes les **8** cycles (`Config.TideSchedule`) |
| `Night` | **NIGHT TIDE** | 2 | ClockTime 20,5, lune froide, bioluminescence, brume bleutée | `Night` 12 %, `Golden` 2 % | 1/16, après Golden |
| `Storm` | **STORM TIDE** | 2 | Désaturée −0,25, plus sombre, Atmosphère grise dense +0,15 | `Storm` 6 %, `Night` 5 %, `Golden` 1 % | 1/16, après Night |
| `Rainbow` | **RAINBOW TIDE** | 2 | Normale, + irisation nacrée dans l'eau | `Rainbow` 2 %, `Golden` 8 % | 1/16, après Storm |

- **Phase 1 = `Normal` + `Golden` uniquement.** C'est déjà le cas dans `Config.Tides` : **A n'a rien à coded**. J'ajoute en Phase 2 trois entrées et une rotation qui s'allonge (`Config.TideSchedule.rotation = { "Golden", "Night", "Storm", "Rainbow" }`, `every = 8`).
- **Annonce** : au début du calme, une ligne en bas d'écran (« GOLDEN TIDE — 25 MIN »), et la **boussole de B** prend la couleur de la marée pendant tout le cycle.
- **Rien n'est jamais garanti** : une `Golden Tide` donne 30 % de mutations, pas 100 %. Le joueur doit **oser** la plage pendant une Golden Tide.

### 3.2 La marée extrême (déjà codée par A)

`Config.ExtremeTide` — environ **1 fois par heure** (1 cycle sur 58), pendant le calme :
- `revealDelay = 5` s après le début du calme → la mer se retire plus loin que d'habitude ;
- `revealTime = 25` s → **le récif est découvert**, 6 créatures apparaissent dessus ;
- 70 % `HawksbillTurtle`, 30 % `Lionfish`, avec les chances de mutation de la marée Golden ;
- la mer revient et **les reprend toutes** ;
- annoncée **seulement par un signe planté côté client** (B), d'après `wave.extreme` dans WaveState — sinon le joueur ne comprend pas ce qui se passe.

**Décision E** : `everyCycles = 58` / `revealTime = 25` / `count = 6` sont **validés**. 25 s c'est court exprès : c'est une **fenêtre**, pas un FIF. Le spot de la marée extrême (récif sud, centre `(0, 0, 335)`, rayon 30) doit être un lieurepère visible depuis la plage — sinon personne ne le trouve.

---

## 4. LES 5 ZONES

⚠️ **Point important pour tout le monde** : le monde n'est **pas** un couloir en Z. C'est une **île de 600 × 600 studs** avec une crique centrale (rayon 70) et **3 anneaux de rareté** autour (`Config.Island`, `Config.Rings`). La carte en 5 zonesalignées sur Z de l'ancien jeu est **abandonnée**.

Voici les **5 zones de jeu**, telles que le joueur doit les comprendre et les nommer :

| # | Zone | Où | Rareté | Apparitions | Ambiance |
|---|---|---|---|---|---|
| **1** | **THE COVE** | Crique centrale, rayon 70. Les 8 lagons. | — | **aucune** (les créatures n'apparaissent pas dans la crique) | À l'abri de la vague. Sûr. |
| **2** | **COVE BEACH** | Anneau 70 → 150 | Common | 18 max, 1 toutes les 2 s | Sable tassé, bois flotté. Zone de départ. |
| **3** | **DUNES** | Anneau 150 → 225 | Common | 16 max, 1 toutes les 2,5 s | Dunes hautes, végétation dense, plus de vent. |
| **4** | **OUTER SHORE** | Anneau 225 → 300 | Uncommon | 12 max, 1 toutes les 3,5 s | Dubord de l'île, plus loin de la crique = **course retour plus longue**. |
| **5** | **THE DROWNED REEF** | Récif sud (335) + épave (ouest) + large | Uncommon → Legendary | Événement : marée extrême, Deep Dive | Le seul endroit où il y a du Rare et plus. |

**Cohérence vérifiée** : `Config.Rings` donne exactement les zones 2, 3 et 4 avec les mêmes bornes. La zone 1 est `Config.Island.coveRadius`. La zone 5 est `Config.ExtremeTide.reef`.

**Ordre de rareté = ordre de risque** : plus c'est rare, plus c'est loin, plus la course retour avant la vague est longue. C'est **la seule vraie décision** de la boucle, et elle est géographique, pas numérique.

### 4.1 Les 3 points d'intérêt

| Point | Où | Pourquoi on y va |
|---|---|---|
| **Falaise-belvédère** | Falaise, 40–60 studs de haut | À l'abri de **toutes** les vagues. C'est le spot vidéo du jeu. |
| **Épave** | Ouest | Créatures meilleures, loin de la crique. |
| **Récif à marée basse** | Sud | N'existe que pendant la marée extrême. |

---

## 5. LES 5 PALIERS DE RICHESSE ET LES MONUMENTS DU LAGON

Le joueur doit être **riche de loin** : on doit le reconnaître à 100 studs sans lire son nom. `Stats.LagoonTier` calcule le palier depuis le revenu ; A écrit l'attribut `LagoonTier` (1..5) sur `PlotN` ; C construit la silhouette.

| Palier | À partir de | Élément haut (silhouette) | Détail bas | Émotion |
|---|---|---|---|---|
| **1** | 0 /s | Abri en bois flotté, 1 palmier | Cuvettes nues | « J'ai une base » |
| **2** | **30** /s | + torches en bambou, flamme réelle | Coquillages et algues au bord | « Elle devient vivante » |
| **3** | **200** /s | + petite cascade sur la roche derrière l'abri | Coraux vivants plus nombreux | « C'est un lagon » |
| **4** | **5 000** /s | + phare de lagon en pierre, faisceau lent | Rebords incrustés de nacre | « Les gens regardent » |
| **5** | **100 000** /s | + arche de roche volcanique couverte de corail | Eau scintillante, reflets dorés | « Je suis le meilleur » |

- **Seuils** : `Config.LagoonTiers = { 0, 30, 200, 5000, 100000 }`. Ce sont les miens, déjà dans le code de A. **Ils ne bougent plus sans playtest.**
- **Chaque palier ajoute un élément haut et un détail bas.** Jamais de retrait : la richesse est cumulative et visible.
- **Le test de cohérence économique que j'ai fait** : au palier 5, il faut 10 bassins de Légendaires Titan (1 500 × 8 × 10 = 120 000 /s). C'est cohérent avec 10 Legendary Titans et pas avec 5 Common Titans (40 /s, palier 2). La courbe est donc juste.

---

## 6. BASSINS, RÉSERVE ET DÉPÔT

### 6.1 Les bassins

- De **5 à 10** cuvettes (`Config.Upgrades.Slots`, `Config.MaxSlots = 10`), nomées `PedestalN` avec l'attribut `Slot`. **A ne les renomme pas**, le serveur en dépend.
- Chaque bassin affiche la **créature posée** : espèce, mutation, **stade courant** (qui change tout seul, calculé). Le joueur voit sa créature **grandir** dans l'eau. C'est le premier «wow » du jeu.
- **Dépôt automatique** dès que le joueur entre dans sa propre base. Une créature **dans le sac** passe dans le premier bassin libre.
- **Le joueur peut réorganiser** (`MoveCreature`) et vendre une créature posée (`SellCreature`). Servi par le serveur.

### 6.2 La règle de remplacement — et pourquoi j'ajoute une réserve

Le code actuel de A (`Stats.Deposit`) fait ceci : bassin libre d'abord ; **lagon plein → la nouvelle remplace la plus faible si elle vaut plus ; sinon elle est relâchée (vendue)**.

**Problème** : une Titan Golden que tu n'as pas envie de poser, et que tu ne veux pas vendre non plus, n'a nulle part où aller. Le joueur est forcé de choisir entre « je la perds » et « je la vends à 20× ». C'est un mauvais choix dans les deux cas, et ça décourage de garder une belle capture.

**Décision E — la réserve (le « stock ») :**

| Paramètre | Valeur | Raison |
|---|---|---|
| Taille | **10 emplacements fixes** | Assez pour un palier 2–3 complet, trop pour être un deuxième lagon. |
| Revenu | **25 %** du revenu normal de la créature | Ce n'est pas gratuit : la réserve est une **palette de rangement**, pas une extension du lagon. 10 × 25 % < 5 bassins × 100 %, donc elle ne cannibalise jamais les bassins. |
| Croissance | **oui**, comme un bassin | Sinon les créatures de réserve finissent obsolètes et le joueur ne les veut pas. |
| Montable / volable | **non, jamais** | Simplifie `MoveCreature`, le vol et l'anti-triche. |
| Grandit avec le jeu | **non** | Si elle grossit, elle remplace le lagon et le jeu se vide de sa tension. |
| Débordement | **vente** au prix `Stats.ReleaseValue` | Inchangé. |

→ **A** : il faut ajouter `Config.Storage = { slots = 10, incomeMult = 0.25 }` et l'insérer entre `Stats.Deposit` et la libération. C'est le seul ajout de logique dont A a besoin pour cette partie.

### 6.3 Ce qu'on ne fait pas

- **Jamais d'écrasement** : une créature posée et surveillée n'est jamais écrasée par une nouvelle.
- **Jamais de vente automatique** : hors lagon plein **et** réserve pleine, on ne vend rien d'office.

---

## 7. LE REEF CODEX

Le Codex est la **seule collection durable** du jeu : il n'est **jamais** remis à zéro, ni par le Tide Rank, ni par rien. Il se remplit **à la capture** (et `maxStage` se calcule à la volée).

- **Une ligne = une espèce**, avec ses variantes : `Normal` (jamais mutée) et `Golden`. `Config.CodexVariants = { "Normal", "Golden" }`. Total théorique : **10 espèces × 2 variantes = 20 lignes**.
- **Bonus permanent** : `+5 %` de revenu par **espèce** consignée (`Config.Codex.speciesBonus`), pas par variante. Ça pousse à élargir la collection, pas à farmer la même ligne.
- **Première capture d'une espèce** : multiplicateur de revenu ×50 sur cette créature (`Config.Codex.newEntryIncomeMult`), une seule fois, affiché en gros. C'est le « NEW SPECIES LOGGED » de `DIRECTION_V2.md`.

### 7.1 Les 5 paliers du Codex (`ClaimCodex(tier)`)

`ARCHI_SERVEUR_REEF.md` §4 prévoit le remote `ClaimCodex(tier)` mais **la table des paliers n'existe nulle part**. La voici :

| Palier | Nom | Condition | Récompense | Effet |
|---|---|---|---|---|
| 1 | **LOGGED** | 2 espèces consignées | 500 pièces | Badge « LOGGED » |
| 2 | **COLLECTOR** | 5 espèces | 2 000 pièces | Badge « COLLECTOR » |
| 3 | **ARCHIVIST** | 9 espèces | 10 000 pièces | Badge « ARCHIVIST » |
| 4 | **KEEPER** | 14 espèces | 75 000 pièces | Badge « KEEPER » + aileron de corail sur le lagon (cosmétique) |
| 5 | **REEF KEEPER** | 10 espèces **+** la variante Golden des 4 premières | 500 000 pièces | Titre « REEF KEEPER » + **jardin de lagon** (le bassin 5 devient un bassin de corail vivant, cosmétique) |

- **Paliers réclamables une seule fois** (`codexClaimed[tier]` côté serveur, jamais d'attribution silencieuse : sinon les doublons sont ingérables).
- **Aucune récompense payante.** Tout est en pièces gagnées en jouant. Pas de badge en Robux, jamais.
- La récompense du palier 5 est **purement cosmétique** : c'est le but qu'on affiche, pas un multiplicateur. Le multiplicateur, c'est le Tide Rank.

---

## 8. LES MUTATIONS

Une créature porte **au plus une mutation**, tirée **à son apparition sur la plage** (pas au ramassage), avec la table de la marée en cours (§3.1). Probabilités toujours affichées.

| Mutation | Id Config | Multiplicateur | Lecture (C) | Phase |
|---|---|---|---|---|
| **Golden** | `Golden` | **×3** | Métal et nacre : Foil #D9A93F, Reflectance 0,3, reflets nacrés lents | **1** |
| **Night** | `Night` *(renommage, voir la fin de cette section)* | **×2** | Bioluminescence : peau #14222E, plancton cyan #3DF5FF, PointLight qui respire (2,5 s, Range 8, sans ombre) | 2 |
| **Storm** | `Storm` | **×5** | Arcs électriques : peau #2A2E38, étincelles, arc repositionné toutes les 0,25 s | 2 |
| **Rainbow** | `Rainbow` | **×10** | Irisation de nacre : Foil #E8E2F0, HueCycle 6 s | 2 |

**Ordre de grandeur à retenir** : `Rainbow` ×10 est l'unique moyen d'atteindre le palier 5 de lagon (100 000 /s) avant d'avoir 10 Legendary Titans. C'est voulu, et c'est un but de plusieurs semaines.

**Règle de lecture** : la mutation est un **preset d'effets** (`Assets.FX.Mutations.<Nom>`, construit par C). Elle ne demande **aucun nouveau modèle**. La couleur de rareté reste dans l'interface uniquement.

⚠️ **Correction d'id à faire** : `Config.Mutations` s'appelle `Glow` alors que `CREATURES_ART.md` §4 et la table ci-dessus l'appellent **`Night`** (c'est bien la bioluminescence). C'est une seule ligne dans Config, mais elle doit être faite **avant** que C ne nomme ses presets. **Recommandation E : renommer `Glow` → `Night`**, le champ `label` découplant déjà le texte affiché.

---

## 9. RÉPONSES AUX 5 QUESTIONS OUVERTES D'A

`docs/ARCHI_SERVEUR_REEF.md` §7 pose cinq questions « pour E via D ». Voici les réponses, definitives.

### 9.1 « Revenu hors ligne : oui/non, taux, plafond. »
**Oui. 50 % du revenu normal, plafonné à 8 heures, écran de résumé au-dessus de 60 secondes.**
Déjà écrit dans `Config.Offline = { incomeRate = 0.5, maxHours = 8, minSeconds = 60 }`. **A n'a rien à coder.**
- **La croissance, elle, n'est pas plafonnée** : elle est calculée sur `bornAt`, donc une créature rare laissée 3 jours revient Titan. C'est gratuit, ça coûte rien au serveur, et c'est la meilleure raison de revenir.
- Le résumé hors ligne est une **notification `offline`** (déjà prévue au §4 de l'archi) : `« 8 H OFFLINE — 42 300 COINS — 3 CREATURES REACHED ELDER »`.
- **Pas de notification hors ligne pendant les 60 premières secondes** du nouveau joueur : il n'a rien.

### 9.2 « Stades (nombre, durées) et multiplicateurs par stade. »
**4 stades : Juvenile ×1 (0,6 d'échelle), Adult ×2 (0,8), Elder ×4 (1,0), Titan ×8 (1,5).**
Déjà dans `Config.Stages` et `Config.GrowthMinutes`. **A n'a rien à coder.**
Durées jusqu'à Adult / Elder / Titan, en minutes cumulées **depuis la capture** :

| Rareté | Adult | Elder | Titan |
|---|---|---|---|
| Common | 3 | 15 | 60 |
| Uncommon | 5 | 30 | 120 |
| Rare | 10 | 60 | 240 |
| Epic | 20 | 120 | 480 |
| Legendary | 30 | 240 | 1200 |

**Temps réel de la première Titan Legendary : 20 h.** C'est le but du jeu, et c'est censé prendre plusieurs jours avec les paliers de rang.

### 9.3 « Taille de la réserve ; la réserve grandit-elle ? »
**10 emplacements fixes, revenu à 25 %, elle ne grandit jamais.** Voir §6.2 pour la raison.
→ **A doit ajouter** `Config.Storage = { slots = 10, incomeMult = 0.25 }` et un palier dans `Stats.Deposit` : `bassin libre → bassin plus faible (si la nouvelle vaut plus) → réserve libre → vente`.

### 9.4 « Poids des marées et chances de mutation. »
Voir **§3.1** : `Normal` 7/8 avec `Golden` 0,5 % ; `Golden` 1 cycle sur 8 avec `Golden` 30 % ; `Night`, `Storm`, `Rainbow` en Phase 2 avec les poids et chances du tableau.
**Phase 1 : rien à ajouter, c'est déjà dans Config.** Phase 2 : ajouter 3 entrées à `Config.Tides` et allonger `Config.TideSchedule.rotation`.

### 9.5 « Contenu exact du rebirth. »
Voir **§10**.

---

## 10. TIDE RANK (rebirth)

**Ce que le Tide Rank remet à zéro** (c'est la seule question qui comptait) :

| Remis à zéro | **Conservé définitivement** |
|---|---|
| Pièces | **Codex** (jamais, comme dit l'archi) |
| Créatures (toutes : bassins, réserve, sac) → vendues au prix courant | Paliers de Codex réclamés (`codexClaimed`) |
| Niveau des bassins → retour à 5 | **Compagnons** et leur stuff |
| Vitesse et sac → retour au niveau 1 | Cosmetics et badges |
| **Tide Marks** (compteur de progression du rang) | Statistiques, `firstJoin` |

Le joueur ne perd donc **jamais sa collection** en rebirthant — il perd son empire, pas son savoir. C'est ce qui rend le rebirth acceptable chez un public de 9–24 ans.

### 10.1 Les paliers

| Rang | Tide Marks requis | Revenu/s requis | Effet permanent |
|---|---|---|---|
| **1** | 50 000 | 5 000 | +10 % de revenu |
| **2** | 400 000 | 20 000 | +20 % (cumulé +30 %) |
| **3** | 3 000 000 | 80 000 | +30 % (cumulé +60 %) |
| **4** | 25 000 000 | 300 000 | +40 % (cumulé +100 %) |
| **5** | 200 000 000 | 1 000 000 | +50 % (cumulé +150 %) |
| 6+ | `[À DÉFINIR]` — courbe ×8 par rang | | |

- **Tide Marks** = les pièces **gagnées** (pas dépensées) depuis le dernier rang. Un simple compteur `coinsEarnedSinceRank` dans les données. Ça empêche de rebirth-grinder sans avoir joué.
- **Le rang 1 est atteignable en une bonne session** d'un joueur attentif : c'est le premier gros « wow » de la première semaine.
- **Léviathan** : débloqué à partir du **rang 3**. Une fois par serveur et par 30 minutes, pendant une marée `Normal`, une silhouette colossale remonte au large. `[À DÉFINIR]` la récompense exacte — ma recommandation : **un Deep Dive gratuit**, ce qui est cohérent avec le reste et ne casse pas l'économie.

---

## 11. CE QUE B (INTERFACE) DOIT SAVOIR

1. **Le HUD n'existe pas avant 31,5 s.** Le joystick seul. C'est une règle dure, pas une préférence. Après : pièces, revenu/s, sac, boussole, bouton Lagoon, ligne de marée.
2. **Boussole obligatoire, carte interdite.** Une flèche indique la direction de la vague (« WAVE FROM THE NORTH ») **dès le début de l'alerte**. Pas de mini-carte : le joueur doit lire le ciel et le sable, pas un HUD.
3. **Cycle à afficher** : calme 35 s / alerte 7 s / vague / reflux 2,5 s. Le compte à rebours apparaît **à l'alerte**, jamais avant (pas de FOMO, pas de pression).
4. **La marée courante a une couleur** : `Golden`, `Night`, `Storm`, `Rainbow` ont chacun un preset de `Assets.FX.TidePresets` fait par C. La ligne d'annonce est en capitales condensées, 2 à 5 mots.
5. **Le Codex est une grille**, pas une liste : 10 lignes, icône + nom + variante + `maxStage`,Cases à cocher visuellement pour les paliers déjà réclamés.
6. **Animations : 0,1 à 0,25 s**, courtes et sèches. Célébrations réservées aux vrais moments : première capture d'une espèce, mutation, Titan atteinte, vol réussi, nouveau palier de rang.
7. **Aucun emoji, aucune police ronde** (`DIRECTION_V2.md`). Icônes fournies par B d'après la clé `key` de `Config.Upgrades`.
8. **Texte de la marée extrême** : quand `wave.extreme` passe, afficher un seul signe planté dans le monde — **pas de popup**, sinon on transforme un événement mondial en notification.

## 12. CE QUE C (MONDE & ART) DOIT SAVOIR

1. **Roster figé, 10 espèces** (§2). Les 3 premières sont **urgentes** : `GhostCrab`, `CushionStar`, `HawksbillTurtle`. C'est le contenu qui manque aujourd'hui.
2. **La règle de modelisation** : vrai animal, proportions et couleurs crédibles, jamais de gros yeux ni de'air mignon. La rareté se lit par la **taille, le matériau, la lumière et les particules** — **jamais** en peignant l'animal. Gabarit : Juvenile 0,6 / Adult 0,8 / Elder 1,0 / **Titan 1,5** appliqué par le client.
3. **Les 5 monuments du lagon** (§5) correspondent exactement aux 5 paliers que A écrit dans `LagoonTier`. Le décor doit poder le chiffre, pas l'inverse.
4. **Les cuvettes restent des `PedestalN`** avec leur attribut `Slot`. C'est une contrainte serveur non négociable.
5. **Les 5 zones** (§4) sont des **anneaux autour d'une crique**, pas des bandes en Z. Si tu construis encore des bandes en Z, tu construis le mauvais monde.
6. **Le récif de marée extrême** doit être **visible depuis la plage** (centre `(0, 0, 335)`, rayon 30). C'est le seul moyen que le joueur sache qu'il peut courir.
7. **Presets de marée** : `Normal`, `Golden` en Phase 1 ; `Night`, `Storm`, `Rainbow` en Phase 2. Les valeurs sont dans `DA_MONDE.md` §4 et doivent partir de `Assets.FX.TidePresets.<Marée>`.
8. **Presets de mutation** : `Golden`, `Night`, `Storm`, `Rainbow`, aucun nouveau modèle (table §8).

---

## 13. BLOCS CONFIG À AJOUTER (pour A)

```lua
-- Reserve (E, GDD_REEF 6.2) : 10 emplacements fixes, revenu reduit, ne grandit pas
Config.Storage = { slots = 10, incomeMult = 0.25 }

-- Marées Phase 2 (E, GDD_REEF 3.1). Phase 1 : rien a ajouter.
Config.Tides.Night   = { label = "Night Tide",   odds = { { "Night", 12 }, { "Golden", 2 } } }
Config.Tides.Storm   = { label = "Storm Tide",   odds = { { "Storm", 6 }, { "Night", 5 }, { "Golden", 1 } } }
Config.Tides.Rainbow = { label = "Rainbow Tide", odds = { { "Rainbow", 2 }, { "Golden", 8 } } }
Config.TideSchedule.rotation = { "Golden", "Night", "Storm", "Rainbow" }

-- Renommage d'id (E, GDD_REEF 8) : "Glow" devient "Night", pour coller a CREATURES_ART
Config.Mutations.Glow = nil
Config.Mutations.Night = { mult = 2, label = "Night" }

-- Paliers du Codex (E, GDD_REEF 7.1), pour ClaimCodex(tier)
Config.CodexTiers = {
	{ tier = 1, id = "Logged",     species = 2,  coins = 500 },
	{ tier = 2, id = "Collector",  species = 5,  coins = 2000 },
	{ tier = 3, id = "Archivist",  species = 9,  coins = 10000 },
	{ tier = 4, id = "Keeper",     species = 14, coins = 75000 },
	{ tier = 5, id = "ReefKeeper", species = 20, coins = 500000, goldenFirst = 4 },
}

-- Tide Rank (E, GDD_REEF 10)
Config.Ranks = {
	{ rank = 1, marks = 50000,     income = 5000,    bonus = 0.10 },
	{ rank = 2, marks = 400000,    income = 20000,   bonus = 0.20 },
	{ rank = 3, marks = 3000000,   income = 80000,   bonus = 0.30 },
	{ rank = 4, marks = 25000000,  income = 300000,  bonus = 0.40 },
	{ rank = 5, marks = 200000000, income = 1000000, bonus = 0.50 },
}
-- donnees : coinsEarnedSinceRank
```

**Rappel de cohérence** : `Stats.LagoonTier` doit être appelé avec le **revenu total** du joueur (`Stats.Income`, bonus compris), pas avec le revenu brut des bassins. Sinon le palier 5 devient inatteignable.

---

## 14. À DÉFINIR — signaled, pas caché

| # | Sujet | Qui tranche | Quand |
|---|---|---|---|
| 1 | Récompense exacte du **Léviathan** (rang 3+) | D + Moaad | Phase 2 |
| 2 | Les 6 espèces **Rare / Epic / Legendary** : absentes de la nature en Phase 1 (choix par défaut), ou ajoutées à `Config.ExtremeTide.creatures` | D | **avant le test fermé** |
| 3 | Contenu du Deep Dive (`GDD.md` §9 bis) au-delà de ce que A a déjà écrit dans `Config.Shop` | D | Phase 2 |
| 4 | Rangs 6+ : courbe | D | Phase 2 |
| 5 | Prix Robux finaux | Moaad | Lancement |

### Les 3 incohérences que j'ai trouvées en croisant les documents

Elles sont **réelles** et doivent être tranchées avant que ça coûte du temps :

1. **Hauteur de la vague : 22 ou 30 ?**
   `DA_MONDE.md` §0 dit « hauteur 22 », `PASSATION.md` aussi, mais **`Config.Wave.height = 30`** et le commentaire dit « plateformes des tours à height + 4 (**34**) ». Or `DA_MONDE.md` §2 et §4 construisent les tours à **Y = 26**. **Si C construit à 26 et que la vague fait 30 de haut, les tours ne sont plus sûres et le jeu est cassé.** → **A confirme `height = 30`, C construit les tours à 34.** C'est le seul choix cohérent.

2. **Noms des stades : deux listes différentes.**
   `CREATURES_ART.md` §2 dit « Baby 0,6 / Juvenile 0,8 / Adult 1,0 / Giant 1,5 ». `Config.Stages` dit « **Juvenile** 0,6 / **Adult** 0,8 / **Elder** 1,0 / **Titan** 1,5 ». → **Les noms de Config gagnent** (Juvenile, Adult, Elder, Titan). C est B doivent adopter cette liste ; `CREATURES_ART.md` §2 est à corriger.

3. **Mutation `Glow` vs `Night`.** Cf. §8. C doit renommer son preset, ou A doit renommer sa clé.

---

*Écrit par E le 2026-10-10. Si une valeur de ce document et `ReplicatedStorage.Shared.Config` divergent, **Config gagne** — c'est le code qui fait foi, ce document est la décision métier.*
