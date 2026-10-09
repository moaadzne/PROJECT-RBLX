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
- **Moaad, 09/10 (fin d'après-midi)** : **pas enfantin, le public le plus large possible, effet « wow, c'est sur Roblox ça ? » sans renier Roblox.** Traduit et rendu applicable dans **docs/DIRECTION_V2.md**, qui prime sur la bible pour le ton, le public, le style et la police. Les créatures deviennent de vrais animaux marins crédibles, l'interface passe en style console (sans Fredoka ni emojis), la vague devient spectaculaire.
- **Moaad, 09/10** : titre du jeu = **« Ride the Tsunami »** (nom affiché proposé : « Ride the Tsunami 🌊 Steal & Ride »). À vérifier dans la recherche Roblox avant publication.
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

## Phase 1 v2 — en cours (référence : docs/GDD.md v2)
Priorité : intro de 30 s → vol pendant la vague → monture → œufs Robux + PolicyService. Les échanges arrivent en semaine 2.

| # | Qui | Tâche | État |
|---|---|---|---|
| P1-01 | A | Contrat des remotes v2 (GDD §11), publié avant le code | en cours |
| P1-02 | A | Config v2 (§13), schéma v2, migration vers legacy.v1 | en cours |
| P1-03 | A | Intro : spawn au lagon, vague d'intro par joueur, 2e marée Golden | à faire |
| P1-04 | A | Ouverture des lagons par phase de vague (`PlotN.Barrier`, attribut `Open`, autorité serveur) | à faire |
| P1-05 | A | StealService et toutes les protections du §4.7 | à faire |
| P1-06 | A | MountService (les Giant surfent la vague) | à faire |
| P1-07 | A | RoyalService (score, top 3, créature unique) | à faire |
| P1-08 | A | Marketplace : 3 passes, Tide Egg 79 / Pick a Creature 149 selon PolicyService | à faire |
| P1-09 | A | RF RedeemCode (codes promo) + événements AnalyticsService du funnel (docs/LANCEMENT.md) | à faire, après P1-08 |
| P1-10 | B | Intro de 30 s sans HUD (caméra, flèche, fondu) | en cours |
| P1-11 | B | HUD de vol (alerte, flèche, maintien, verrou, revanche, bouclier) | à faire |
| P1-12 | B | HUD de la Marée Royale, bouton Monter, billboard de bassin, animation de la barrière | à faire |
| P1-13 | B | Boutique (probabilités avant achat, bascule PolicyService) | à faire |
| P1-20 | C | 3 créatures (Pebble Crab, Sand Star, Reef Hatchling montable) : IDs + prompts | en cours |
| P1-21 | C | Barrière de corail `PlotN.Barrier` + lagon de Plot1 + hero shot (tools/world) | en cours |
| P1-22 | C | FX Golden + ambiance Golden Tide, 3 couronnes + FX royal, sons | à faire |
| P1-30 | F | Contrôle qualité des pushes de A et B (luau-analyze, contrat v2) | en cours |
| P1-31 | F | docs/IMPORT_LUNDI.md : **Rojo** retenu ; à corriger : `$ignoreUnknownInstances` sur chaque nœud + sauvegarde avant la 1re synchronisation | en cours |
| P1-32 | B | Renommer TideClient.client.lua en init.client.lua (sinon aucun module client ne se charge avec Rojo) | à faire |
| P1-33 | A | Remotes v2 créées par code ou en *.model.json (Net.lua:43 attend sans fin une remote absente) | à faire |
| P1-41 | E | Appliquer DIRECTION_V2 au GDD : roster de vraies espèces, noms, ton des textes, onboarding, miniatures cinématiques | à faire, prioritaire |
| P1-23 | C | Appliquer DIRECTION_V2 : DA du monde, fiches et prompts des créatures réalistes, vague à grande échelle, sons | à faire, prioritaire |
| P1-14 | B | Appliquer DIRECTION_V2 : système visuel console (police condensée, panneaux sombres, sans emojis), textes d'action | à faire, prioritaire |
| P1-34 | F | Passe de cohérence de tous les docs face à DIRECTION_V2 : liste des contradictions par propriétaire | à faire |
| P1-40 | E | Plan de lancement : miniatures, icône, page du jeu, budget pub, TikTok / YouTube | fait (docs/LANCEMENT.md) |

## Fait
- [A 09/10] Net.lua : plus de seau de limite recréé pour un joueur parti. **À réimporter lundi.**
- [B 09/10] Notifications.lua : nom de la rareté dans le toast, pas de doublon en file. **À réimporter lundi.**
- [E 09/10] docs/GDD.md v1.
- [A 09/10] docs/ARCHI_SERVEUR_REEF.md.
- [B 09/10] docs/UI_REEF.md.
- [C 09/10] docs/DA_MONDE.md et docs/CREATURES_ART.md.

## Questions pour Moaad
2. Prix des gamepasses : les valeurs de départ du GDD §9 restent jusqu'aux premiers tests.
