# Tableau des tâches — Tide Rush : Reef Keepers (tenu par D)

Mis à jour le 2026-10-09. Branche d'intégration : `claude/epic-pasteur-q323d7` (D y fusionne les branches de l'équipe).

## Sessions (cloud, sans Studio jusqu'au lundi 12/10 21 h)
| Lettre | Session | Branche |
|---|---|---|
| A | Tide Rush · A Serveur | `claude/inspiring-albattani-8hikpu` |
| B | Tide Rush · B Interface | `claude/friendly-volta-qj504y` |
| C | Tide Rush · C Monde | `claude/clever-wozniak-h2znoi` |
| D | Tide Rush · D Chef de projet | `claude/epic-pasteur-q323d7` (intégration) |
| F | Tide Rush · F Assistant chef de projet | `claude/awesome-allen-i2ni7b` |
| E | Tide Rush · E Concept | `claude/laughing-lovelace-8xixq7` |

## Décisions
- **D, 09/10** : **Deep Dive** (GDD §9 bis : tirage payant en Pearls, avec garantie de rareté visible, créatures liées non volables, alternative PolicyService) = **première mise à jour (semaine 2)**, pas au lancement. Au lancement : la boutique minimale déjà codée par A (3 passes + Tide Egg ou Pick a Creature). Le lancement se concentre sur le nombre de joueurs et la rétention ; Dive arrive avec les données de la semaine 1. À prévoir au lancement : déclarer les tirages payants dans le questionnaire de l'expérience sur Creator Hub (à vérifier).
- **D, 09/10** : vague de gameplay plus imposante. **Hauteur d'environ 30, plateformes des tours d'environ 34**, au lieu de 22 et 26. A fixe les valeurs finales selon le temps de montée des rampes ; C construit les tours en conséquence. La crête visuelle ne dépasse jamais une plateforme où l'on est à l'abri, par cohérence. La houle de 55 à l'horizon (C) et la vague d'intro restent les moments « plus haut que tout ». Bassins creusés (SUNK_POOLS, PedestalN abaissés de 3,5) validés, sous réserve de l'accord direct de A.
- **D, 09/10** : secret de la Phase 1 (GDD §6 bis) = **la marée extrême fusionne avec le point d'intérêt « récif à marée basse »**. Environ 1 fois par heure, la mer se retire plus loin et révèle le récif, avec des créatures rares pendant un temps limité. Les signes arrivent sans texte : mouettes, mer qui recule, son. L'épave reste un repère visible ; son secret complet (ce qui émerge) passe à la semaine 2.
- **D, 09/10** : île ouverte (GDD §3 bis), **version intermédiaire au lancement**. Île d'environ 600×600 avec la crique centrale et les 8 lagons ; **vague venant des 4 directions** (N/E/S/O, annoncée, jamais deux fois de suite la même) ; 3 points d'intérêt (belvédère, épave, récif à marée basse) ; 8 tours ; boussole et direction de la vague dans le HUD, sans carte. L'île de 800×800, la jungle, la grotte et la carte arrivent dans la première grosse mise à jour. Objectif : garder le test public vers le 29/10.
- **D, 09/10** : nom affiché sur Roblox = **« Ride the Tsunami: Steal & Ride »**, sans emoji, par cohérence avec DIRECTION_V2. Roster v3 de E validé (vraies espèces ; Phase 1 : GhostCrab, CushionStar, HawksbillTurtle). Stades : Juvenile / Adult / Elder / Titan (monture dès Elder, surf en Titan).
- **D, 09/10** : **docs/DIRECTION_V2.md est la référence de la direction.** docs/VISION_TON.md (F) en est l'annexe détaillée : prompt de session, juste milieu, règles vérifiables, 10 premières secondes, checklist de contrôle, remplacement des éléments Roblox par défaut (§8 bis). En cas de conflit, DIRECTION_V2 l'emporte.
- **D, 09/10** : on **garde les avatars des joueurs** (pas de personnage unique imposé), avec des proportions R15 réalistes et identiques pour tous, nos animations et une tenue « Reef Keeper » en cosmétique. Moaad peut revenir sur ce choix.
- **D, 09/10** : **coordination technique directe autorisée entre A, B et C** (noms, attributs, contrat des remotes, assets). A reste propriétaire du contrat. Le périmètre, les priorités et le design passent toujours par D.
- **Moaad, 09/10 (fin d'après-midi)** : **pas enfantin, le public le plus large possible, effet « wow, c'est sur Roblox ça ? » sans renier Roblox.** Traduit et rendu applicable dans **docs/DIRECTION_V2.md**, qui prime sur la bible pour le ton, le public, le style et la police. Les créatures deviennent de vrais animaux marins crédibles, l'interface passe en style console (sans Fredoka ni emojis), la vague devient spectaculaire.
- **Moaad, 09/10** : titre du jeu = **« Ride the Tsunami »** (nom affiché : voir la décision « sans emoji » plus haut). À vérifier dans la recherche Roblox avant publication.
- **Moaad, 09/10** : concept **Reef Keepers** (docs/DIRECTIONS.md §A, détaillé dans docs/GDD.md).
- **Moaad, 09/10** : objectif **top 10 Roblox**. Tout est permis pour y arriver, y compris un changement total de concept. E audite Reef Keepers face au top 10 (docs/AUDIT_TOP10.md) avant toute implémentation.
- **Moaad, 09/10** : « pour le jeu, oublie le halal / haram » (rappel fait une fois). Les règles halal sont levées pour Tide Rush : vol entre joueurs et tirages payants en Robux autorisés. Restent obligatoires : probabilités affichées, PolicyService (ArePaidRandomItemsRestricted), règles communautaires et de monétisation de Roblox, aucune propriété intellectuelle copiée.
- **Moaad, 09/10** : le test du jour est rejeté (« rien ne va, tout est à revoir »). Tout ce qui se voit est refait à partir de zéro. On ne garde que la plomberie invisible qui marche : sauvegarde, verrou de session, Net, attribution des bases, vague.
- **D, 09/10** :
  - Périmètre de la Phase 1 = GDD §12, ni plus ni moins.
  - **Noms de la carte inchangés** : `Plots/PlotN/Pedestals/PedestalN` (Slot, LockGui). Pas de `Pools/PoolN`. Un bassin = un PedestalN, dont le cylindre est masqué par C.
  - **Clés de données et du contrat inchangées** : l'amélioration reste `"Slots"` (affichée « Pools » dans l'interface).
  - **Attribut `LagoonTier` (1..5) validé** : A l'écrit sur PlotN à partir du revenu, avec les seuils dans Config ; C l'utilise pour le visuel.
  - **Phase 1 sans réserve** : pas de `MoveCreature` ni de `ClaimCodex`. Placement automatique, la plus faible est remplacée si la nouvelle vaut plus, sinon la créature est relâchée contre des pièces (GDD §5.1). Les récompenses du Codex sont automatiques.
  - **Contrat des remotes v2** : A le publie dans review/review_context.md AVANT de coder. B code contre ce contrat.
  - **Exception validée** : en jeu seulement, le client (B) peut animer localement Lighting et Atmosphere pour les marées, avec les valeurs fournies par C. Jamais en mode édition.
  - Tant que les modèles de C manquent, les créatures utilisent les modèles des anciens trésors (via Config.LegacyItemToCreature).

## Direction v2 (D, 09/10, d'après docs/AUDIT_TOP10.md et « fais ce qui attire le plus de joueurs »)
- On garde le thème : créatures marines et vague. On change le hook : **titre verbe + objet**, **monture** (les Giant surfent la vague), **vol entre lagons** en version complète (verrou gratuit, récupération en touchant le voleur, protection des nouveaux joueurs, pas de protection payante au lancement), **Marée Royale** (classement à chaque marée spéciale), **échanges** en semaine 2.
- Phase 1 v2 : 1 zone, 3 espèces (au moins une montable), monture, vol, Golden Tide, Marée Royale, sauvegarde. Boutique minimale.
- Calendrier visé : Studio du 12 au 19/10 → test fermé du 20 au 23/10 → premier test public vers le 26/10 (A/B des miniatures, petit budget pub décidé par Moaad) → une mise à jour par semaine.
- Modéliste de créatures : pas de dépense avant le test fermé ; prototype avec generate_mesh et le Creator Store.
- E écrit le GDD v2. A, B et C démarrent le noyau commun (contrat v2, données, créatures, HUD, lagon).

## Semaine 2 (première mise à jour), prévu
- Deep Dive (GDD §9 bis) : A = DiveService + produits Pearls ; B = écran Dive + bouton HUD ; C = FX de plongée + variante Abyssal.
- Échanges entre joueurs ; secret complet de l'épave.

## Phase 1 v2 — en cours (référence : docs/GDD.md v2)
Priorité : intro de 30 s → vol pendant la vague → monture → œufs Robux + PolicyService. Les échanges arrivent en semaine 2.

| # | Qui | Tâche | État |
|---|---|---|---|
| P1-01 | A | Contrat des remotes v2 et v2.1 (GDD §11) | fait (73c5704) |
| P1-02 | A | Config v2 (§13), schéma v2, migration vers legacy.v1 | fait (c9b95d2) ; reste le roster v3 et les stades renommés |
| P1-03 | A | Intro : spawn au lagon, vague d'intro par joueur, 2e marée Golden | fait (c9b95d2) |
| P1-04 | A | Ouverture des lagons par phase de vague (`PlotN.Barrier`, attribut `Open`, autorité serveur) | fait (LagoonService) |
| P1-05 | A | StealService et toutes les protections du §4.7 | fait |
| P1-06 | A | MountService (les Titan surfent la vague) | fait |
| P1-07 | A | RoyalService (score, top 3, créature unique) | fait |
| P1-08 | A | Marketplace : 3 passes, Tide Egg 79 / Pick a Creature 149 selon PolicyService | fait (ShopService, ids à 0 en attendant Moaad) |
| P1-35 | A | Roster v3 + stades Juvenile/Adult/Elder/Titan dans Config, migration et services | fait (4ee2b25) |
| P1-37 | A, B, C | Marée extrême ≈ 1/h qui révèle le récif (A : événement serveur + apparitions rares ; B : signes sans texte ; C : récif + mouettes + son) | après P1-36, priorité basse |
| P1-36 | A, B, C | Île ouverte, version intermédiaire : A = vague à 4 directions + biomes par anneaux ; B = boussole + direction de la vague ; C = île de 600×600 + 3 points d'intérêt + 8 tours | GO (A après P1-35) |
| P1-09 | A | RF RedeemCode (codes promo) + événements AnalyticsService du funnel (docs/LANCEMENT.md) | à faire, après P1-08 |
| P1-10 | B | Intro de 30 s sans HUD (caméra, flèche, fondu) | fait (Onboarding) |
| P1-11 | B | HUD de vol (alerte, flèche, maintien, verrou, revanche, bouclier) | fait (a24dbc7) |
| P1-12 | B | HUD de la Marée Royale, bouton Monter, billboard de bassin, animation de la barrière | fait (a24dbc7) |
| P1-13 | B | Boutique (probabilités avant achat, bascule PolicyService) | fait côté client ; attend Config.Shop et les RF de A |
| P1-20 | C | 3 créatures (Pebble Crab, Sand Star, Reef Hatchling montable) : IDs + prompts | en cours |
| P1-21 | C | Barrière de corail `PlotN.Barrier` + lagon de Plot1 + hero shot (tools/world) | en cours |
| P1-22 | C | FX Golden + ambiance Golden Tide, 3 couronnes + FX royal, sons | à faire |
| P1-30 | F | Contrôle qualité des pushes de A et B (luau-analyze, contrat v2) | en cours |
| P1-31 | F | docs/IMPORT_LUNDI.md : **Rojo** retenu, protections ignoreUnknownInstances, sauvegardes, réglages Avatar | fait |
| P1-32 | B | Renommer TideClient.client.lua en init.client.lua (sinon aucun module client ne se charge avec Rojo) | fait (53a9f71) |
| P1-33 | A | Remotes v2 créées par code ou en *.model.json (Net.lua:43 attend sans fin une remote absente) | fait (c9b95d2, créées au démarrage) |
| P1-41 | E | Appliquer DIRECTION_V2 au GDD : roster de vraies espèces, noms, ton des textes, onboarding, miniatures cinématiques | fait (GDD v3, LagoonTiers) |
| P1-23 | C | Appliquer DIRECTION_V2 : DA du monde, fiches et prompts des créatures réalistes, vague à grande échelle, sons | fait (1a0bd8f) |
| P1-15 | B | **CRITIQUE avant lundi** : aligner le client sur le contrat v2.1 de A (StartSteal + Notify, Mount(nil), ChoosePick, shop.randomAllowed, newbie/shield, stades Juvenile…Titan, ids v3 dans la démo) ; sinon le vol, la monture et la boutique ne marchent pas | à faire |
| P1-14 | B | Appliquer DIRECTION_V2 : système visuel console (police condensée, panneaux sombres, sans emojis), textes d'action | à faire, prioritaire |
| P1-34 | F | Passe de cohérence face à DIRECTION_V2 | fait : VISION_TON §7 envoyé à A, B, C et E ; défauts Roblox (§6) distribués |
| P1-40 | E | Plan de lancement : miniatures, icône, page du jeu, budget pub, TikTok / YouTube | fait (docs/LANCEMENT.md) |

## Fait
- [F 09/10] QA : serveur de A propre ; 7 écarts de contrat + 74 emojis + LuckiestGuy chez B ; 4 emojis chez A (Config:200–202) ; SmoothPlastic sur la mutation Night chez C. Envoyé aux auteurs.
- [A 09/10] Net.lua : plus de seau de limite recréé pour un joueur parti. **À réimporter lundi.**
- [B 09/10] Notifications.lua : nom de la rareté dans le toast, pas de doublon en file. **À réimporter lundi.**
- [E 09/10] docs/GDD.md v1.
- [A 09/10] docs/ARCHI_SERVEUR_REEF.md.
- [B 09/10] docs/UI_REEF.md.
- [C 09/10] docs/DA_MONDE.md et docs/CREATURES_ART.md.

## Questions pour Moaad
1. Créer les gamepasses et produits développeur dans Creator Hub (après la publication privée), puis donner leurs ids à A. En attendant, les ids sont à 0 et la boutique est désactivée.
2. Prix des gamepasses : les valeurs de départ du GDD §9 restent jusqu'aux premiers tests.
