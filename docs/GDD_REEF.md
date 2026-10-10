# GDD_REEF — Reef Keepers : spécification de référence

**Auteur : E (concept & game design). Écrit le 2026-10-10, revu contre le code le même jour.**
Base : branche `claude/e-gdd-reef`, tirée du commit `06f2f54` (dernier état de A).

> ## ⚠️ LIRE CE CADRE AVANT TOUT
>
> **`docs/ARCHI_SERVEUR_REEF.md` est PÉRIMÉ** (il le dit lui-même ligne 3, et `AGENTS.md` §7 le confirme). Ce document répond **quand même** à ses emplacements `[GDD]` parce que c'était la demande — mais **ce qui fait foi, c'est `review/review_context.md` (contrat v2.1) et `Config.lua`**.
>
> **Conséquence concrète :** la Phase 1 a été arbitrée par D le 09/10 et **retire trois choses** que ce document propose ailleurs. Ne les construisez pas :
>
> | Sujet | Statut réel | Où le lire |
> |---|---|---|
> | **Réserve / `storage`** | ❌ **écarté de la Phase 1** par D. Pas de `Config.Storage`. Le dépôt reste « bassin libre → plus faible remplacée → relâchée ». | §6.2, `TABLEAU.md` D 09/10 |
> | **Paliers du Codex / `ClaimCodex`** | ❌ **écarté**. Pas de `ClaimCodex` en Phase 1 : les récompenses du Codex sont **automatiques** à la capture. | §7.1, `review_context.md` |
> | **Tide Rank / rebirth** | ❌ **absent du contrat v2.1**. Ni `rank`, ni `Rebirth()`. | §10 |
>
> Ces trois sujets sont gardés ici comme **propositions Phase 2**, clairement étiquetées. Personne ne doit les coder en Phase 1.
>
> **Règle de lecture.** Ce document ne réécrit pas `docs/GDD.md` (v3, la prose du concept) : il le **fige** là où A, B et C bloquent. Tout ce qui est déjà dans `ReplicatedStorage.Shared.Config` est **repris tel quel**, pas redécidé.
> **Avertissement honnête** : tous les chiffres ci-dessous sont des **valeurs de départ proposées par E** (choix de design), jamais des mesures ni des faits. Ils se règlent au playtest. Ce qui n'est pas décidé est écrit `[À DÉFINIR]` et listé au §14.

## 0. Ce que ce document tranche

| # | Décision | Statut |
|---|---|---|
| 1 | Les 30 premières secondes, seconde par seconde (§1) | **figé** — déjà codé par A (`Config.Intro`) et B (`Onboarding`) ; ce document aligne C dessus |
| 2 | 10 espèces, leurs zones, leur croissance, leur montabilité (§2) | **figé** — c'est exactement `Config.Creatures` ; roster v3 déjà validé par D |
| 3 | 5 marées + la marée extrême (§3) | **figé** — Phase 1 = `Normal` + `Golden`, déjà dans `Config.Tides`. Les 3 autres sont **Phase 2** |
| 4 | 5 zones de jeu et leur correspondance avec les 3 anneaux d'A (§4) | **figé** |
| 5 | 5 paliers de richesse et les 5 monuments du lagon (§5) | **figé** — seuils repris de `Config.LagoonTiers`, monuments repris de `DA_MONDE.md` §2 |
| 6 | Bassins, **réserve**, dépôt, mutations (§6, §8) | **partiel** — bassins et dépôt : figés (= code actuel). **Réserve : proposition Phase 2**, retirée de la Phase 1 par D |
| 7 | 5 paliers du Codex (§7) | **Phase 2** — le Codex de Phase 1 est automatique, sans palier |
| 8 | Réponses aux questions ouvertes d'A (§9) | **figé**, mais ancré sur le contrat v2.1, pas sur l'archi périmée |
| 9 | Tide Rank / rebirth (§10) | **Phase 2** — absent du contrat v2.1 |
| 10 | Ce que B doit savoir (§11), ce que C doit savoir (§12) | **figé** |

---

## 1. LES 30 PREMIÈRES SECONDES, IMAGE PAR IMAGE

**Le moment le plus important du jeu.** Objectif, dans l'ordre : (1) « attends, c'est Roblox ça ? » ; (2) attraper un animal vivant ; (3) avoir **peur** de la vague ; (4) vouloir y retourner immédiatement.

La séquence est **entièrement pilotée par le serveur** (`IntroService` + `Config.Intro`) : elle est **individuelle par joueur**, pas scriptée pour les 8 d'un coup. Elle rejoue tant qu'elle n'est pas terminée — vérifié dans `DataService` : l'intro se déclenche sur `isNew or introStep == 0`, et si le joueur part avant la fin, `IntroService` la **rejoue à la prochaine connexion** au lieu de la sauter. Il n'existe **aucun** saut de tutoriel sur un nombre de captures.

> **Conséquence pour B et C** : ne construisez rien qui suppose une intro « jouée une fois pour toutes » au premier clic. Si le joueur se déconnecte à 12 s, il la revoit depuis le début.

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
- **Sac** : de **2 à 10** places (`Config.Upgrades.Bag` : `base = 2`, `step = 1`, `maxLevel = 8` → 2 + niveau). Une capture au sac plein est refusée proprement (`Notify`), pas écrasée.
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

- **Phase 1 = `Normal` + `Golden` uniquement.** C'est déjà le cas dans `Config.Tides` : **A n'a rien à coder**. J'ajoute en Phase 2 trois entrées et une rotation qui s'allonge (`Config.TideSchedule.rotation = { "Golden", "Night", "Storm", "Rainbow" }`, `every = 8`).
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
- **Réorganiser / vendre une créature posée** (`MoveCreature`, `SellCreature`) : **Phase 2**, ces deux remotes ont été retirés de la Phase 1 avec la réserve. En Phase 1, le joueur dépose, le serveur range — point.

### 6.2 Le dépôt — et pourquoi une réserve est proposée plus tard

**Phase 1 : c'est le code de A, tel quel. Rien à demander.** `Stats.Deposit` fait : bassin libre d'abord ; **lagon plein → la nouvelle remplace la plus faible si elle vaut plus ; sinon elle est relâchée contre des pièces** au prix `Stats.ReleaseValue`. C'est exactement ce que D a validé le 09/10.

**Ma réserve est une objection de design, pas une tâche.** Le problème est réel : une Titan Golden que tu ne veux ni poser ni vendre à 20× n'a nulle part où aller, et le joueur est forcé entre « je la perds » et « je la vends ». Mais **D a tranché le 09/10 : pas de réserve en Phase 1**. Je respecte l'arbitrage et je garde la proposition pour plus tard, avec les valeurs que je recommande.

> **Phase 2 — proposition E (pas de code attendu cette semaine)**
>
> | Paramètre | Valeur proposée | Raison |
> |---|---|---|
> | Taille | **10 emplacements fixes** | Assez pour un palier 2–3 complet, trop pour être un deuxième lagon. |
> | Revenu | **25 %** du revenu normal | Palette de rangement, pas une extension du lagon. 10 × 25 % < 5 bassins × 100 %, donc elle ne cannibalise jamais les bassins. |
> | Croissance | **oui**, comme un bassin | Sinon les créatures de réserve obsolètes ne servent plus à rien. |
> | Montable / volable | **non, jamais** | Simplifie le vol et l'anti-triche. |
> | Grandit avec le jeu | **non** | Si elle grossit, elle remplace le lagon et le jeu perd sa tension. |
>
> Quand D la rouvrira, il faudra **aussi** `MoveCreature` et `SellCreature` — les deux ont été retirés de la Phase 1 avec la réserve. Une réserve sans réorganisation est un piège : on stocke, on ne peut plus rien en faire.

---

## 7. LE REEF CODEX

Le Codex est la **seule collection durable** du jeu : il n'est **jamais** remis à zéro, ni par le Tide Rank, ni par rien. Il se remplit **à la capture** (et `maxStage` se calcule à la volée).

- **Une ligne = une espèce**, avec ses variantes : `Normal` (jamais mutée) et `Golden`. `Config.CodexVariants = { "Normal", "Golden" }`. Total théorique : **10 espèces × 2 variantes = 20 lignes**.
- **Bonus permanent** : `+5 %` de revenu par **espèce** consignée (`Config.Codex.speciesBonus`), pas par variante. Ça pousse à élargir la collection, pas à farmer la même ligne.
- **Première capture d'une espèce** : multiplicateur de revenu ×50 sur cette créature (`Config.Codex.newEntryIncomeMult`), une seule fois, affiché en gros. C'est le « NEW SPECIES LOGGED » de `DIRECTION_V2.md`.

### 7.1 Les paliers du Codex — **Phase 2, pas de `ClaimCodex` en Phase 1**

⚠️ **`ClaimCodex(tier)` n'existe pas dans le contrat v2.1** et D l'a retiré de la Phase 1 le 09/10 : *« Phase 1 sans réserve : pas de `MoveCreature` ni de `ClaimCodex` … Les récompenses du Codex sont automatiques. »*

**Ce qu'A code en Phase 1, et qui est déjà écrit** (`review_context.md`) : à chaque nouvelle case, le joueur reçoit automatiquement **le revenu de base × 50 pièces** (`Config.Codex.newEntryIncomeMult`), et une **ligne d'espèce complète donne +5 % de revenu permanent**. `codexCount` / `codexTotal` sont déjà dans le snapshot. **B n'a donc rien à demander à A pour afficher le Codex : il lit `state.codex`, `codexCount`, `codexTotal` et le Notify `codex`.**

**Semaine 1 — affichage validé par étude de marché (`DECISIONS_MARCHE.md` §2) :**
- **3 visibles** : Ghost Crab (Common, 1/s), Cushion Star (Common, 2/s), Hawksbill Turtle (Uncommon, montable Elder+, 10/s)
- **4 mystère** : slots "? ? ? ?" avec silhouettes floues + rareté colorée (Rare/Epic/Legendary)
- Barre de progression "X/10 découvertes", animation d'apparition scale 0→1 bounce + son "pop", clic sur mystère → tooltip "Découvre-le en jouant !" + particule

Le tableau ci-dessous est ma **proposition Phase 2**, à réarbitrer par D le moment où le rebirth rouvre (§10). Je le garde ici pour que la décision soit déjà réfléchie — pas pour que quelqu'un le code maintenant.

| Palier | Nom | Condition (lignes de Codex) | Récompense | Effet |
|---|---|---|---|---|
| 1 | **LOGGED** | **2 lignes** | 500 pièces | Badge « LOGGED » |
| 2 | **COLLECTOR** | **5 lignes** | 2 000 pièces | Badge « COLLECTOR » |
| 3 | **ARCHIVIST** | **10 lignes** — les 10 espèces | 10 000 pièces | Badge « ARCHIVIST » |
| 4 | **KEEPER** | **15 lignes** — les 10 espèces + 5 Golden | 75 000 pièces | Badge « KEEPER » + aileron de corail sur le lagon (cosmétique) |
| 5 | **REEF KEEPER** | **20 lignes** — les 10 espèces + les 10 Golden | 500 000 pièces | Titre « REEF KEEPER » + **jardin de lagon** (cosmétique) |

**Une ligne de Codex = une espèce × une variante**, pas une espèce : le plafond est **20** (10 × 2, §7). Compter en « espèces » rendait les paliers 4 et 5 inatteignables (14 > 10) et identiques. Le décompte se fait sur `codex[speciesId]` (variantes) et `rowComplete` dans le Notify.

> **Point d'attention — ce n'est pas une décision** : le palier 5 exige les 10 variantes Golden, alors qu'une `Normal Tide` n'en tire que **0,5 %**. C'est un but de plusieurs semaines, voulu. Si D le trouve trop loin, le levier le moins cher est d'ajouter une 6ᵉ marée, **pas** de gonfler la chance en Normal — gonfler en Normal rendrait la Golden Tide inutile.

- **Aucune récompense payante**, à aucun palier. Tout en pièces gagnées en jouant, jamais de badge en Robux.
- Si ces paliers ouvrent un jour, ils seront **réclamables une seule fois** (`codexClaimed[tier]`, jamais d'attribution silencieuse : les doublons sont ingérables).
- La récompense du palier 5 est **purement cosmétique**. Le multiplicateur de progression, c'est le Tide Rank (§10) — pas le Codex.

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

`docs/ARCHI_SERVEUR_REEF.md` §7 pose cinq questions « pour E via D ». Voici les réponses — **avec une ligne de séparation entre ce qui est déjà en jeu et ce qui est mort avec l'archi périmée**.

**La demande initiale était de remplir les `[GDD]` du §7.** Ils sont remplis, tous les cinq, et les 14 marqueurs `[GDD]` semés dans les §2.1 à §2.6 aussi.

| Marqueur dans `ARCHI_SERVEUR_REEF.md` | Réponse | Où l'appliquer |
|---|---|---|
| §7 q1 — revenu hors ligne | 50 %, plafond 8 h, résumé > 60 s | §9.1 · `Config.Offline` **existe déjà** |
| §7 q2 — stades et multiplicateurs | 4 stades ×1/×2/×4/×8, durées par rareté | §9.2 · `Config.Stages` + `GrowthMinutes` **existent déjà** |
| §7 q3 — taille de la réserve, grandit-elle | **question annulée** : D a retiré la réserve de la Phase 1 | §6.2 · ⛔ **pas de `Config.Storage`** |
| §7 q4 — poids des marées, mutations | table §3.1 | §3.1 · `Config.Tides` **existe déjà** |
| §7 q5 — contenu exact du rebirth | §10 | §10 · ⛔ **absent du contrat v2.1** |
| §2.1 — `growTime`, `stages` | §9.2 | `Config.GrowthMinutes` |
| §2.2 — `pools` nombre de départ / max | 5 → 10 | §6.1 · `Config.Upgrades.Slots` + `MaxSlots` |
| §2.2 — dépôt auto ou manuel | **automatique** en entrant dans la base | §6.1 · `Stats.Deposit` |
| §2.2 — réserve `storage`, max | **annulée en Phase 1** | §6.2 · proposition Phase 2 |
| §2.3 — `OFFLINE_CAP` | 8 h de revenu versé | §9.1 · `Config.Offline` |
| §2.3 — croissance max hors ligne | **aucun plafond** (elle est calculée, donc gratuite) | §9.1 |
| §2.3 — la réserve grandit ? | **sans objet**, elle n'existe pas | §6.2 |
| §2.4 — poids et effets des marées | §3.1 | `Config.Tides` |
| §2.4 — `mutationChance` | §3.1, par marée | `Config.Tides[t].odds` |
| §2.5 — paliers du Codex | **annulés** — récompenses automatiques en Phase 1 | §7.1 · proposition Phase 2 |
| §2.6 — condition du Léviathan | **jamais définie**, et absente du contrat | §14 nº 1 · `[À DÉFINIR]` |
| §2.6 — ce que le Tide Rank remet à zéro | §10 | §10 · Phase 2 |

> ### Ce qu'A doit faire, en une ligne
> **Rien pour la Phase 1.** Tout ce que ce document fige existe déjà dans `Config.lua` et tourne. Les blocs du §13 sont **tous des propositions Phase 2** — aucun n'est une tâche de cette semaine. Si A cherche quoi implémenter ici, la réponse est : **rien**, et c'est un résultat, pas un oubli.

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
**Sans objet en Phase 1.** D a retiré la réserve du périmètre le 09/10 (« Phase 1 sans réserve »). `Stats.Deposit` fait donc exactement ce qu'il fait aujourd'hui : bassin libre → plus faible remplacée si la nouvelle vaut mieux → relâchée contre des pièces.
Ma réponse pour le jour où D la rouvrira : **10 emplacements fixes, revenu à 25 %, elle ne grandit jamais** (§6.2). ⛔ **A n'ajoute rien cette semaine.**

### 9.4 « Poids des marées et chances de mutation. »
Voir **§3.1** : `Normal` 7/8 avec `Golden` 0,5 % ; `Golden` 1 cycle sur 8 avec `Golden` 30 % ; `Night`, `Storm`, `Rainbow` en Phase 2 avec les poids et chances du tableau.
**Phase 1 : rien à ajouter, c'est déjà dans Config.** Phase 2 : ajouter 3 entrées à `Config.Tides` et allonger `Config.TideSchedule.rotation`.

### 9.5 « Contenu exact du rebirth. »
Voir **§10**.

---

## 10. TIDE RANK (rebirth) — **Phase 2, hors contrat v2.1**

⚠️ **Rien de tout ce qui suit n'existe.** Le contrat v2.1 n'a ni `rank`, ni `Rebirth()`, ni remise à zéro : D l'a sorti de la Phase 1 avec la réserve. C'est une **proposition de design pour la suite**, à réarbitrer — pas une tâche pour A.

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

1. **Roster figé, 10 espèces** (§2). Les 3 premières sont **urgentes** : `GhostCrab`, `CushionStar`, `HawksbillTurtle`. C'est le contenu qui manque aujourd'hui. **L'étoile de mer s'appelle `CushionStar`, pas `SeaStar`** (§14, incohérence 4) : le dossier est `Assets.Creatures.CushionStar`.
2. **La règle de modelisation** : vrai animal, proportions et couleurs crédibles, jamais de gros yeux ni de'air mignon. La rareté se lit par la **taille, le matériau, la lumière et les particules** — **jamais** en peignant l'animal. Gabarit : Juvenile 0,6 / Adult 0,8 / Elder 1,0 / **Titan 1,5** appliqué par le client. **Les noms de stades sont ceux de `Config.Stages`** : Juvenile / Adult / Elder / **Titan** — pas Baby / Giant.
3. **Les 5 monuments du lagon** (§5) correspondent exactement aux 5 paliers que A écrit dans `LagoonTier`. Le décor doit poder le chiffre, pas l'inverse.
4. **Les cuvettes restent des `PedestalN`** avec leur attribut `Slot`. C'est une contrainte serveur non négociable.
5. **Les 5 zones** (§4) sont des **anneaux autour d'une crique**, pas des bandes en Z. Si tu construis encore des bandes en Z, tu construis le mauvais monde.
6. **Le récif de marée extrême** doit être **visible depuis la plage** (centre `(0, 0, 335)`, rayon 30). C'est le seul moyen que le joueur sache qu'il peut courir.
7. **Presets de marée** : `Normal`, `Golden` en Phase 1 ; `Night`, `Storm`, `Rainbow` en Phase 2. Les valeurs sont dans `DA_MONDE.md` §4 (`Normal`, `Golden`, `Night`, `Storm`) et doivent partir de `Assets.FX.TidePresets.<Marée>`. **`Rainbow` n'a pas de valeurs** : à proposer par C, Phase 2 (§14).
8. **Presets de mutation** : `Golden`, `Night`, `Storm`, `Rainbow`, aucun nouveau modèle (table §8).

---

## 13. BLOCS CONFIG PROPOSÉS — **aucun n'est une tâche de Phase 1**

> **A : ne code rien de cette section cette semaine.** Tout y est une proposition Phase 2, retirée du périmètre par D le 09/10. Je la garde écrite pour que la décision soit déjà prise quand elle reviendra — pas pour créer du travail.

```lua
-- Réserve (E, §6.2) — HORS PHASE 1, D l'a retirée le 09/10
Config.Storage = { slots = 10, incomeMult = 0.25 }

-- Marées Phase 2 (E, §3.1) — le plus proche du réutilisable, 3 lignes
Config.Tides.Night   = { label = "Night Tide",   odds = { { "Night", 12 }, { "Golden", 2 } } }
Config.Tides.Storm   = { label = "Storm Tide",   odds = { { "Storm", 6 }, { "Night", 5 }, { "Golden", 1 } } }
Config.Tides.Rainbow = { label = "Rainbow Tide", odds = { { "Rainbow", 2 }, { "Golden", 8 } } }
Config.TideSchedule.rotation = { "Golden", "Night", "Storm", "Rainbow" }

-- Renommage d'id (E, §8) : "Glow" devient "Night". SEUL item de cette liste
-- qui soit une simple correction de nom, et donc sans risque ni charge.
Config.Mutations.Glow = nil
Config.Mutations.Night = { mult = 2, label = "Night" }

-- Paliers du Codex (E, GDD_REEF 7.1), pour ClaimCodex(tier).
-- Une "ligne" = espece x variante ; plafond 20 (10 especes x {Normal, Golden}).
Config.CodexTiers = {
	{ tier = 1, id = "Logged",     lines = 2,  coins = 500 },
	{ tier = 2, id = "Collector",  lines = 5,  coins = 2000 },
	{ tier = 3, id = "Archivist",  lines = 10, coins = 10000 },
	{ tier = 4, id = "Keeper",     lines = 15, coins = 75000 },
	{ tier = 5, id = "ReefKeeper", lines = 20, coins = 500000 },
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

-- Monétisation top 10 validée (DECISIONS_MARCHE.md §5) — IDs 0 = en attente Moaad
Config.Shop = {
	Passes = {
		VIPRider    = { id = 0, price = 79,   name = "VIP Rider" },
		SpeedBoost  = { id = 0, price = 149,  name = "Speed Boost" },
		BagExpand   = { id = 0, price = 99,   name = "Bag Expansion" },
		StarterPack = { id = 0, price = 249,  name = "Starter Pack", includes = { "VIPRider", "SpeedBoost", "BagExpand" } },
	},
	TideEgg      = { id = 0, price = 199, chances = { Common = 60, Uncommon = 25, Rare = 10, Epic = 4, Legendary = 1 } },
	PickCreature = { id = 0, price = 399 },
	RewardedAd   = { enabled = true, reward = "TideEgg", cooldownHours = 24 },
}
```

**Rappel de cohérence** : `Stats.LagoonTier` doit être appelé avec le **revenu total** du joueur (`Stats.Income`, bonus compris), pas avec le revenu brut des bassins. Sinon le palier 5 devient inatteignable.

---

## 14. À DÉFINIR — signaled, pas caché

| # | Sujet | Qui tranche | Quand |
|---|---|---|---|
| 1 | Récompense exacte du **Léviathan** (rang 3+) | D + Moaad | Phase 2 |
| 2 | ~~Les 6 espèces **Rare / Epic / Legendary** : absentes ou ajoutées au récif ?~~ | **TRANCHÉ par E le 10/10** — voir ci-dessous | clos |
| 3 | Contenu du Deep Dive (`GDD.md` §9 bis) au-delà de ce que A a déjà écrit dans `Config.Shop` | D | Phase 2 |
| 4 | Rangs 6+ : courbe | D | Phase 2 |
| 5 | Prix Robux finaux | Moaad | Lancement |

### Les 4 incohérences que j'ai trouvées en croisant les documents

Elles sont **réelles** et doivent être tranchées avant que ça coûte du temps :

1. **Hauteur de la vague : 22 ou 30 ? — DÉJÀ TRANCHÉ par D le 09/10, reste à appliquer par C.**
   `DA_MONDE.md` §0 et §4 disent encore « hauteur 22, tours à Y = 26 » (et `PASSATION.md` aussi). Mais `Config.Wave.height = 30`, et **D a arbitré explicitement** : *« Hauteur d'environ 30, plateformes des tours d'environ 34 »*. → **La valeur de Config fait foi.** C n'a plus qu'à remonter ses tours à **34** et son corps de vague à **30** dans `DA_MONDE.md` ; le 22/26 est un reste du monde rejeté le 09/10. Tant que C n'a pas fait ça, **les tours ne sont pas sûrs** — un joueur s'y croit à l'abri et se fait prendre.

2. **Noms des stades : deux listes différentes.**
   `CREATURES_ART.md` §2 dit « Baby 0,6 / Juvenile 0,8 / Adult 1,0 / Giant 1,5 ». `Config.Stages` dit « **Juvenile** 0,6 / **Adult** 0,8 / **Elder** 1,0 / **Titan** 1,5 ». → **Les noms de Config gagnent** (Juvenile, Adult, Elder, Titan). C et B doivent adopter cette liste ; `CREATURES_ART.md` §2 est à corriger.

3. **Mutation `Glow` vs `Night`.** Cf. §8. C doit renommer son preset, ou A doit renommer sa clé.

4. **`SeaStar` vs `CushionStar` — l'id de l'étoile de mer.**
   `Config.Creatures` s'appelle **`CushionStar`**, et c'est déjà l'id **validé par D le 09/10** (`TABLEAU.md`). Mais `CREATURES_ART.md` §3 et `SOURCING_C.md` §1 proposent encore **`SeaStar`** (y compris l'asset candidat `5088223335`). → **`CushionStar` gagne.** C range ses modèles dans `Assets.Creatures.CushionStar` et corrige ses deux documents ; s'il garde `SeaStar` en nom de fichier local, il lui faut un alias, sinon `Assets.Creatures` ne résoudra pas à l'exécution.

### §14 nº 2 — TRANCHÉ : les 6 espèces rares restent hors de la Phase 1, et le récif gagne une garantie

**Décision E, 10/10.** Les 6 espèces `BlueRingedOctopus`, `LeopardRay`, `GiantPacificOctopus`, `LionsManeJelly`, `MantaRay`, `WhaleShark` **n'apparaissent pas dans la nature en Phase 1**. Elles reviennent en Phase 2, dans cet ordre.

**Pourquoi, en trois arguments — le premier est arithmétique, pas goût :**

1. **Un Whali Shark en semaine 1 casse l'économie.** Il vaut 1 500 /s juvénile. Le seuil du palier 5 de lagon est **100 000 /s** et le palier 4 est **5 000 /s** (`Config.LagoonTiers`). Un seul Whali Shark Titan dans un bassin — 12 000 /s — **saute le palier 4**. Le joueur gagne les deux tiers de sa courbe de richesse en une capture, et `Config.LagoonTiers` cesse de mesurer quoi que ce soit. La rareté ne se régle pas en Phase 1 : **la Phase 1 est le lieu où l'économie se cale.**
2. **C n'a pas les modèles, et ce n'est pas le moment.** P1-20 fait 3 créatures. P1-42 (la vague rendue côté client) est P0 pour lundi. Six modèles de plus avant lundi coûtent exactement ce qui bloque le jeu.
3. **Un Rare doit arriver préparé.** Quand une Manta Ray apparaît en Phase 2, le joueur doit déjà connaître le cycle des stades et avoir vu le récif. Sinon c'est un objet rare dans un jeu où la rareté ne veut rien dire encore.

**En revanche, le récif ne doit pas sembler vide.** C'est le vrai sujet derrière la question, et il a une réponse qui ne coûte **aucun modèle** :

> ⚠️ **Écart trouvé en vérifiant le code.** La décision de D du 09/10 dit « des créatures **rares** pendant un temps limité ». Or `Config.ExtremeTide.creatures = { HawksbillTurtle 70, Lionfish 30 }` : **les deux sont `Uncommon`.** Le secret du jeu, une fois par heure, ne donne donc rien de plus rare que l'anneau extérieur. Et `mutationTide = "Golden"` necorrige pas le tir : avec 6 créatures à 30 %, la probabilité qu'**aucune** ne soit mutée est de 0,7⁶ ≈ **12 %**. Douze pour cent d'heures déçues, une fois par heure.
>
> **A : la correction est la même que celle que tu as déjà écrite pour la marée Golden personnelle.** `IntroService` (lignes 156-164) force « au moins une créature mutée » quand le tirage n'en donne aucune. **Reprends cette garantie telle quelle pour le récif.** Une seule règle, pas de nouvelle entrée de Config, aucun modèle pour C. Le récif devient alors un rendez-vous qui paie vraiment : une **Golden** y est garantie, une fois par heure, pendant 25 s.

**Ordre de retour en Phase 2** (pour ne pas rouvrir la question à chaque session) :

| Vague | Espèces | Pourquoi dans cet ordre |
|---|---|---|
| 1re mise à jour | `BlueRingedOctopus`, `LionsManeJelly` | Ce sont les **créatures de nuit** de `GDD.md` §6 bis : elles se voient de loin par leur lueur, donc la décision « je vais là-bas » est visuelle, sans texte. Un seul preset (`Night`) à faire pour les deux. |
| 2e | `LeopardRay`, `GiantPacificOctopus` | Le **secret complet de l'épave** (`TABLEAU.md`, semaine 2). Le contenu de l'épave est donc à écrire avec elles, pas avant. |

> **Gravure sur la quille (décision finale, `DECISIONS_MARCHE.md` §3) :**
>
> > **"Quand la mer recule, l'ancien roi revient.**
> > **La marée extrême révèle ce qu'elle a prise."**
>
> Lisible en 3 s, compréhensible 10-30 ans. 10 ans = marée basse + gros monstre ; 20 ans = lien mécanique horaire ; 30 ans = lore Léviathan/Whale Shark. **Empreinte lumineuse** au sol pulsant au rythme des marées → partage organique TikTok/Shorts = acquisition gratuite. Pas de spoil : ne dit pas "Whale Shark" ni "Deep Dive".

| 3e | `MantaRay`, `WhaleShark` | Les Légendaires montables. Elles supposent que le joueur ait déjà vu les 8 autres, et une économie qui tienne. **C'est aussi la promesse du Deep Dive** (`GDD.md` §9 bis) : elles doivent arriver *avec*, pas avant. |

**Conséquence à acter dans l'interface (B), semaine 1** : le Codex affiche 10 espèces, **3 accessibles + 4 mystère** ("? ? ? ?" silhouettes floues + rareté colorée). C'est le crochet de rétention validé par étude de marché (pattern Adopt Me / Blox Fruits). Barre "X/10 découvertes", animation bounce, tooltip "Découvre-le en jouant !" sur les mystères. Si D préfère ne rien annoncer, le Codex n'affiche que les 3 connues — c'est un choix de 10 lignes côté B, à confirmer, pas un blocage.

### Deux valeurs manquantes, signalées plutôt que comblées


| Manque | Où | Pourquoi ce n'est pas tranché ici |
|---|---|---|
| **Preset de lumière `RainbowTide`** | `DA_MONDE.md` §4 donne `Normal`, `Golden`, `Night`, `Storm` — **pas `Rainbow`** | `Rainbow` est un ajout d'E (§3.1), C n'a jamais eu de valeurs. C est libre de proposer un écart à partir de `Normal`. **À DÉFINIR par C**, Phase 2, sans urgence. |
| **Récompense du Léviathan** | §10 | Cf. §14 nº 1. |

---

*Écrit par E le 2026-10-10. Si une valeur de ce document et `ReplicatedStorage.Shared.Config` divergent, **Config gagne** — c'est le code qui fait foi, ce document est la décision métier.*
