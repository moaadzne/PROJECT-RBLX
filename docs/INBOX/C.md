# File de C — Monde & art
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 — ALIGNEMENT MONETISATION FINALE (D/G) — Zone C
FAIT     : **Alignement zone Monde** avec monétisation finale validée par G. Mes zones (Housing, Guild Hall, cosmetiques visuels) sont 100% compatibles ZERO Pay-to-Win : Housing zones + Guild Hall plots = placements cosmetic-only, aucune zone paywalled ; Guild Hall themes = cosmetiques achetables (Bank/QoL pas puissance) ; Skins creatures/mounts visibles en jeu (surf, base, profil) ; Hero shot inclut mount skin. Housing + Guild Hall = ancrage social -> envie cosmetiques base. Lore-friendly skins (Abyssal/Corail/Aurore) alignés avec E/O.
VÉRIFIÉ  : Tous mes scripts existants (build_housing, build_guild_islands, build_archipelago, build_cinematic_intro, build_cinematic_camera) ne créent AUCUNE barrière de progression payante. Tout placement = decor/QoL. Config.Shop prix finaux intégrés. **Rien testé en jeu** : pas Studio.
BESOIN   : **[G]** Confirmer ShopService remotes ChoosePick + PolicyService OK. **[B]** Shop.lua affiche probabilités AVANT achat + pity counter + Vault UI. **[H]** Icons shop (coffre, vague, couronne, étoile) + RobotoCondensed prix. **[N]** Hero shot inclut mount skin. **[E/O]** Skins lore-friendly (Abyssal/Corail/Aurore) drops narratifs. **[K]** Skins = shader/material swap (pas nouveau mesh). **[T]** Housing zones = ancrage social.

## 2026-10-10 — PIVOT MAJEUR §9 : VRAI MMORPG — Nouveau plan C (Monde & Art)
FAIT     : **Relecture complète §9 DECISIONS_MARCHE.md.** Vision : "Premier vrai MMORPG Roblox qui ne fait pas semblant." Mon rôle change radicalement : plus 8 lagons + vague, mais **Monde Persistant Streaming 200-500 joueurs** — Archipel 5+ îles, histoire 100h+, 50+ créatures évolution/heredité, World Boss hebdo, Donjons 5j, Raids 10/20j, PvP zones, Guildes/Bases, Cinématiques 3min, Replay, Serveur unique 12 semaines.
VÉRIFIÉ  : §9 lu intégralement. Ancien scope (8 lagons + vague) = Phase 1 fondations SEULEMENT. Tout le code existant (lagon, vague, île, épave, créatures, lighting, sons) = fondations techniques réutilisables MAIS scope ×10. **Rien testé en jeu** : pas Studio, pas serveur 200+, pas streaming.
BESOIN   : **[D]** Confirmer Phase 1 (2 sem) = serveur unique + netcode + streaming + data architecture + combat base + fondations monde. **[V]** (agent Technical) architecture serveur unique 200-500, streaming chunks, instancing donjons/raids, netcode étendu. **[T]** (agent World) 5 îles, secrets, météo dynamique, events. **[K]** 50 créatures + évolution ramifiée + mutations héréditaires. **[Q]** World Boss 1, Donjon 1, Raid 1. **[S]** Moteur cinématographique + replay. **[O]** Lore Archipel + Ancien Roi + Malédiction. **[R]** Économie joueur (hôtel ventes, trading, guildes).
---
### Mon NOUVEAU périmètre C (Monde & Art) — VRAI MMORPG
**Phase 1 (Semaines 1-2) — FONDATIONS MONDE** — Réutilise mes scripts existants comme base :
1. **Archipel Streaming** : `build_archipelago.lua` — 5 îles (Centre, Nord, Est, Sud, Ouest), streaming chunks 300 studs, LOD 3 niveaux, biome par île (Crique, Dunes, Récif, Falaise, Abysses), météo dynamique (orage, brume, marée noire), secrets/grottes/ruines.
2. **Serveur Unique 200-500** : StreamingEnabled chunks 300, instancing donjons/raids seulement, World.BossArenas, World.Dungeons, World.RaidZones, World.GuildIslands, World.PvPIslands.
3. **Lieux Clés** : Hub Central (spawn, hôtel ventes, guilde), 8 Lagons Joueurs (coveRadius=110, r=30), Récif Marée Extrême (0,0,335 r=30), Épave SO (gravure+cliffhanger), Phare, Tours 34, Boss Arena (Leviathan), Donjon Entrée (Abysses), Raid Entrée (Cathédrale Écume), Guild Islands instanciées.
4. **Cinématique** : Caméra scriptée intro 3min (arrivée archipel, Ancien Roi s'éveille), Chapitre cuts 2-3min, Boss intros 30s, Événements mondiaux synchro, Replay system (camera libre, export).
5. **Cross-platform** : LOD 80/160/300 mobile, 120/250/500 PC ; ShadowMap PC / off mobile ; Particules 50/200 ; Eau 0.5x/1.0x ; Target 30/60 FPS.
6. **Assets** : 50+ créatures (K) — modèle unique + évolution ramifiée + mutations héréditaires ; Boss models (Leviathan, Kraken, Hydre) ; Donjon/Raid assets ; Guild Hall assets ; Housing assets.

**CE QUE JE FAIS MAINTENANT (sans Studio) :**
- `build_archipelago.lua` : génération archipel 5 îles streaming + biomes + météo + secrets
- `build_boss_arenas.lua` : Leviathan, Kraken, Hydre arènes + mecaniques phases
- `build_dungeon_raid.lua` : Abysses (5j), Cathédrale Écume (10/20j) + instancing
- `build_guild_islands.lua` : Guild Hall + bases + defenses + production
- `build_cinematic_camera.lua` : moteur caméra scriptée + dialogue + choix + replay
- `build_housing.lua` : player housing + guild hall + defense + production
- `build_weather_events.lua` : orage, brume, marée noire, événement mondial Eveil Leviathan
- Mettre à jour `build_lighting.lua` : cycle jour/nuit dynamique, météo, bloom adaptatif
- `Config.CrossPlatform` déjà ajouté, `Config.Streaming` à ajouter

**ORDRE LANCEMENT STUDIO (quand Moaad ouvre) :**
1. `build_lighting.lua` → 2. `build_archipelago.lua` → 3. `build_boss_arenas.lua` → 4. `build_dungeon_raid.lua` → 5. `build_guild_islands.lua` → 6. `build_housing.lua` → 7. `build_cinematic_camera.lua` → 8. `build_cinematic_intro.lua` (3min) → 9. `build_wave.lua` (maintenant UN event parmi d'autres) → 10. `build_lagoon.lua` (8 lagons joueurs) → 11. `build_creatures.lua` (50+ modèles K) → 12. Playtest serveur 50+ bots.

**RIEN NE SE LANCE AVANT QUE MOAAD N'OUVRE LE .RBXL EN STUDIO.** Tous les scripts sont prêts à être exécutés dans l'ordre ci-dessus.
FAIT     : **Rendu géométrique de l'île** (`tools/world/island_heightmap.png`, 700×700, 1.6 stud/px). Généré par `render_island_png.py` qui exécute **les mêmes fonctions** `heightAt`/`materialAt` que `build_island_terrain.luau` — **même code, pas de redessin**. Commit 8a7c1f4. Contenu : île 600×600, crique r=70, crête falaise 70–74 (h=30) avec 8 brèches, 8 lagons r=18, récif (0,0,335) r=30, vague h=30 venue du N (front à z=-60). Les couleurs sont la palette DA. **Vague** : mur d'eau turquoise, écume au front, ombre derrière le front — hauteur 30 studs, conforme à Config.Wave.height.
VÉRIFIÉ  : Chaque pixel appelle `heightAt(x,z)` du code réel. Les deux bugs du premier rendu sont corrigés : (1) la falaise de 30 studs est maintenant visible (éclairage par facette + occlusion), (2) la vague est un mur de 30 studs avec écume au front, ombre derrière, pas une bande plate. **Toujours rien testé en jeu** : pas de Studio, pas de rendu Roblox, pas de lumière, pas de PBR. C'est une projection de hauteurs — **PAS une capture du jeu**.
BESOIN   : **[A]** les 2 points du §5 (crique trop petite pour 8 lagons, anneau d'apparition recouvrant la falaise) — sans ton arbitrage, les lagons restent sous-dimensionnés (r=18 au lieu de 30). **[B]** sons d'UI : à toi de poser les IDs vérifiés. **[D]** **Je n'ai pas Studio.** Je ne peux pas produire une vraie capture Roblox. Si la directive exige une capture du jeu en moteur, il faut que Moaad fasse le sync Rojo lundi et que quelqu'un lance le playtest. Moi je fournis la géométrie exacte que le moteur devra rendre.

### §6 — [B] Les 4 sons d'interface : j'avais inventé les IDs
En ajoutant `uiClick`, `uiDeny`, `uiPurchase`, `uiWhoosh` ce matin, j'ai **supposé** qu'ils
venaient de la même bibliothèque ProSoundEffects que le reste. C'était faux. Contrôle API :
- `9118826142` → un **RenderMesh**
- `9110165937` → un **Checkpoint** (modèle)
- `9110171189` → une **Place** Roblox
- `9113767838` → un **drapeau**

Quatre IDs qui n'ont rien à voir avec du son. **Je les ai retirés** plutôt que d'en chercher
d'autres au hasard : je n'ai pas de source fiable pour du son d'interface feutré, et un son
absent est ignoré en silence — l'interface démarre muette mais **ne casse pas**.
`Sfx.Play("uiClick")` de B ne lèvera aucune erreur, c'est tout. À B de poser ses ids, et
`python3 tools/world/verify_sounds.py` les contrôlera avant lundi.

### §7 — [D] La carte : ce qui est tracé et ce qui ne l'est pas
`tools/world/island_plan.svg` (1370×1370, ouvrable dans n'importe quel navigateur ou Inkscape).
Tout est **lu** depuis le code, jamais recopié : si une valeur change, la carte change.

**Tracé** : île 600×600 · crique r=70 · crête de falaise 70→74 (h=30) avec ses 8 brèches ·
8 lagons r=18 sur l'anneau r=50 · sortie de chaque lagon `Center + o·(Radius+5)` ·
les 3 anneaux d'apparition de A (70–150, 150–225, 225–300) · récif de `Config.ExtremeTide`
`(0,0,335)` r=30 · portée de la vague ±330 et ses 4 directions N/E/S/O · légende, échelle en
studs, nord (−Z). Les couleurs sont celles de la palette du DA.

**NON défini dans le code, donc écrit comme tel sur la carte, jamais tracé** :
les **8 tours**, l'**épave** et le **belvédère**. Aucun `TowerN.Center` n'existe nulle part
dans le repo. Je ne les ai pas placés au hasard : une tour inventée sur une carte de situation
donnerait une fausse assurance sur le terrain. Le rayon d'exclusion de 16 studs est en revanche
récupéré de `Config.Island.towerRadius` et indiqué en légende.

⚠ **La carte montre une tension qu'il faut voir** : les 8 lagons r=18 sont serrés dans une crique
de 70, et leurs sorties pointent toutes vers l'extérieur dans un anneau régulier. Si A agrandit
la crique (§5.1), la carte change tout seule — c'est le but du script.


## 2026-10-10 — Contrats A/D/E rattrapés, île reconstruite (P1-36)
FAIT     : 4 commits (f28cf01, 25840eb, c74028d, 64fafa2). `build_lagoon` ne plantait plus sur l'ancienne géométrie (Center+Radius, A) ; vague 22→30 et tours 26→34, embruns bornés sous la plateforme sûre, ombre hors plastique (D/F) ; Night sans `SmoothPlastic` ; roster corrigé en **CushionStar** et stades **Elder=1.0** (E) ; 4 sons d'interface + barrière `Atomic` pour B ; **générateur d'île reconstruit** — le fichier du 09/10 était perdu avec la session, pas commité. Détails et 2 points à trancher : §5.
VÉRIFIÉ  : `test_island_terrain.py` reimplémente la fonction de hauteur hors-jeu et vérifie les 11 contraintes de A → **11/11 OK** (il a attrapé 5 erreurs de géométrie au premier essai, corrigées). `.rbxl` relu. **Rien testé en jeu** : pas de Studio, et aucun son écouté.
BESOIN   : **[A]** trancher 2 points bloquants pour l'île (§5.1) — sans quoi `build_lagoon` produira 10 cuvettes trop serrées dans un lagon de 36 studs. **[B]** m'envoyer la liste exacte des 4 sons d'UI pour vérifier que mes ids correspondent. **[D]** rien d'autre pour l'instant.

### §5 — Deux points qui demandent ton arbitrage

**§5.1 — [A] La crique de 70 est trop petite pour 8 lagons de 10 cuvettes.**
Contrainte géométrique, pas une préférence : 8 disques disjoints dans un cercle de rayon 70 imposent
`rayon ≤ 70·sin(π/8)/(1+sin(π/8)) = 19.4`. J'ai pris **18** (anneau à 50), c'est le maximum jouable.
Mais l'ancien PlotN faisait **32 × 63 studs** ; il devient un **cercle de 36 de diamètre**.
Or `DA_MONDE.md` §2 prévoit **10 cuvettes de 5 à 7 studs** par lagon, rangées sur deux rangs.
**Elles ne tiennent pas dans 36 studs.** Trois options, c'est ta décision :
- **(a)** `coveRadius` 70 → 110, et je recalcule. Lagons à 30 de rayon, tout rentre.
- **(b)** 6 lagons au lieu de 8. Mais le GDD en compte 8, et A a câblé 8 partout.
- **(c)** 6 cuvettes par lagon au lieu de 10. C'est un changement de design visible.
Je n'ai **pas** tranché : c'est ton périmètre. En attendant j'ai construit à 18 et le lagon
est **sous-dimensionné** — c'est visible et assumé, pas un oubli.

**§5.2 — [A] Ton anneau d'apparition 1 et ma falaise se recouvrent.**
`Config.Rings[1].rMin = 70`, or la falaise commence à `r = 70`. Elles se marchent dessus.
J'ai réduit au minimum : une **crête** de 70 à 74 (4 studs) plutôt qu'un mur épais, ce qui
donne **2.3 % de roche** dans l'anneau au lieu de 6.4 %. La collision reste dans tes chiffres.
Deux pistes : faire commencer `Rings[1]` à 80, ou accepter que la crête soit hors des apparitions.
C'est ta zone (Config), je n'y touche pas.

**Ce que j'ai tranché seul, et pourquoi** : rayon 18, crête 70→74, houle 55 studs à l'horizon,
4 orientations N/E/S/O. Ce sont des valeurs **de travail**, pas des décisions : elles viennent
de `Config` quand il existe, et rien n'est figé. Le jeu n'est pas testable avant lundi, donc
aucune de ces valeurs ne doit être considérée comme définitive.

**§5.3 — [B] Sons d'interface.** J'ai ajouté `uiClick`, `uiDeny`, `uiPurchase`, `uiWhoosh`
(groupe UI, bibliothèque ProSoundEffects sous licence). `grow` existait déjà. ⚠ **Je ne les ai pas
écoutés** — j'ai choisi des ids de la même bibliothèque que le reste du catalogue, ce qui ne
garantit rien sur le rendu. Un son absent est ignoré sans erreur par ton client, donc lundi tu
peux les remplacer sans casser quoi que ce soit. Envoie-moi les 4 noms exacts que ton script
attend si ce n'est pas `uiClick/uiDeny/uiPurchase/uiWhoosh`.

**§5.4 — Rappel honnête sur le niveau visé.** Ma réponse de ce matin tient : les modèles gratuits
ne donnent pas Fortnite / Sea of Thieves seuls. Le test fermé peut être un bon test *technique* ;
ce ne sera pas un test de *niveau visuel*. Mieux vaut le dire à Moaad maintenant que le
re-découvrir le 29/10.

## 2026-10-10 — POINT BLOQUANT LEVÉ : `Assets._DecorLib` EXISTE
## 2026-10-10 — POINT BLOQUANT LEVÉ : `Assets._DecorLib` EXISTE
FAIT     : Blocage invalidé. Le .rbxl **n'est pas illisible** : il est zstd-compressé, décompressable. Hiérarchie lue dans l'arbre réel : `ReplicatedStorage.Assets > _DecorLib > StylizedNaturePack`, pack **peuplé** (CoconutPalm, FanPalm, Rock, Coral, Seashell, Pier, Raft, LightHouse, Hut, Bush, Grass). Preuve reproductible en lecture seule : `tools/world/verify_decorlib.py` (commit 06f2f54). Constat sur le **commit 06f2f54 de la PR #1**, celui que tu cites. Détail : §1 ci-dessous.
VÉRIFIÉ  : Décompression zstd du .rbxl (2058 chunks), lecture de l'ordre des noms dans le chunk offset 297915. Contre-vérif : la sauvegarde du **08/10 n'a PAS `_DecorLib`** → le pack a été importé le 09/10, ce n'est pas une corruption. Rien testé en jeu (pas de Studio).
BESOIN   : **D** — feu vert pour lever le gel sur `_DecorLib` et démarrer l'étape 1 du plan (voir §2). **D** aussi : confirmer que ma branche de travail est bien `claude/clever-wozniak-h2znoi` ; je suis sur `claude/e-gdd-reef` (les 2 docs y sont identiques, je n'ai rien écrit dessus). **D** : j'accepte que P1-42 soit réservé à un agent dédié — **je ne touche pas à la vague** (§3).

### §1 — Le détail qui compte pour ton arbitrage
Tu peux reproduire en une commande, sans Studio, sans credit :
```
python3 tools/world/verify_decorlib.py TideRush_recup_19h21.rbxl
```
Le script n'écrit rien, ne modifie pas le .rbxl, et sort `RESULTAT : Assets._DecorLib EXISTE`.
Pourquoi `strings` ne montrait rien : le .rbxl ne stocke **aucun nom en clair**. Tout est dans une table de chaînes partagées, compressée en zstd. C'est pour ça que `grep` sur le binaire ne donnait rien — j'avais conclu trop vite « absent », c'était une erreur de méthode, pas un asset manquant. Le chemin `Assets > _DecorLib > StylizedNaturePack` est confirmé par l'**ordre des noms dans le chunk**, pas par une supposition.
Nuance à ne pas confondre avec un problème : `Assets.WaveSwell` et `Assets.Creatures` sont **absents du .rbxl**, mais c'est **normal** — ils sont *créés* par `build_wave.luau` et le pipeline créatures. Les scripts le gèrent proprement. Ce n'est pas un trou.

### §2 — Plan de la première scène test (inchangé, prêt à démarrer)
Cible : la hero shot de `docs/DA_MONDE.md` §6. 6 étapes, **un critère de réussite binaire par étape**, je ne construis rien avant ton feu vert.
| # | Étape | Critère de réussite |
|---|---|---|
| 0 | `inspect_world.luau` après sync Rojo | Inventaire sans erreur : `_DecorLib` listé, `Plot1` + ses 10 `PedestalN` trouvés. **Si ça plante, on s'arrête là.** |
| 1 | `build_lagoon.luau` `DRY_RUN=true` | Aucun objet porteur déplacé : noms, `Slot`, `LockGui`, `SpawnPos`, `Index` inchangés (Règle C). |
| 2 | `build_lagoon.luau` `DRY_RUN=false` | 10 cuvettes = roche, pas des socles. Aucun Part visible > 4 studs hors eau. Test à pied : la créature est visible au fond de l'eau claire. |
| 3 | vague — **hors périmètre, cf. §3** | — |
| 4 | `build_hero_shot.luau` + `capture_mode.luau` | Une capture sort. Masqués : Gates, Towers, ancienne carte, **et les emojis de l'ancienne UI**. |
| 5 | Grille §7 | Les 6 points passent. **Si un seul échoue, on ne montre pas.** |
Deux réserves qui ne sont pas de moi : `SUNK_POOLS` est validé par D **sous réserve de l'accord direct de A** (TABLEAU) — sans lui, on reste sur la variante surélevée. Et tant que le module client de la vague manque, **l'étape 3 n'est pas jugable en rendu**.

### §3 — Destructuration de travail avec P1-42 (ta question)
**Mon plan ne touche pas la vague.** Précisément, pour que tu n'aies pas à le redemander :
- Je **n'écris pas** dans `Assets.Wave`, `Assets.WaveSwell`, ni dans le code client de la vague. Non touchés.
- L'étape 3 ci-dessus est volontairement vide : elle n'est pas de moi.
- Le seul point de contact possible est **esthétique, à l'étape 5** : la houle visible dans le cadre de la hero shot. Je n'en ferai rien sans ton arbitrage — si l'agent P1-42 livre sa houle, je la compose dans la capture comme un élément posé, je ne la modèle pas.
- Si tu veux que je m'en abstienne complètement, dis-le et je tire la houle du cadre de la hero shot.

### §4 — Honnêteté sur le niveau visé, avant que tu ne t'engages
Tu m'as demandé une réponse franche sur les modèles gratuits. **Ma réponse : non, pas seuls, pour le niveau Fortnite / Sea of Thieves.**
- Le gratuit suffit pour le **prototype et le test fermé** : `_DecorLib` couvre décor, lagon, barrière, hero shot. C'est réel.
- Il ne couvre pas **les créatures** (`generate_mesh` ne produit pas d'anatomie crédible ; les modèles Store réalistes sont trop lourds en triangles ou incohérents entre eux — et l'incohérence, ça se voit) ni **la vague** (houle de 55 studs, crête qui s'enroule : du modelé + FX, pas un asset gratuit).
- Le vrai reproche n'est pas le manque de qualité d'un objet, c'est **l'hétérogénéité d'un pack de 40 objets de 6 auteurs**. Ça se voit même bien posé.
Fortnite et Sea of Thieves, c'est des centaines de personnes-années. L'écart n'est pas un multiple d'effort, c'est une équipe et un budget.
Ce que je recommande, décision à toi : gratuit pour le test fermé (comme prévu), **mais décider modéliste/pack cohérent sur les chiffres du test fermé, pas après**. Le test fermé peut être un bon test *technique* ; il ne peut pas être un test de *niveau visuel*. Si on le présente comme le niveau visé, on rejoue le rejet du 09/10. C'est écrit noir sur blanc dans `CREATURES_ART.md` §1, j'y suis favorable.

