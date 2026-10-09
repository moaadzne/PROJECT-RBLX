# Tableau des tâches — Tide Rush : Reef Keepers (tenu par D)

Mis à jour le 2026-10-09. Branche d'intégration : `claude/epic-pasteur-q323d7` (D y fusionne les branches de l'équipe).

## Sessions (cloud, sans Studio jusqu'au lundi 12/10 21 h)
| Lettre | Session | Branche |
|---|---|---|
| A | Tide Rush · A Serveur | `claude/inspiring-albattani-8hikpu` |
| B | Tide Rush · B Interface | `claude/friendly-volta-qj504y` |
| C | Tide Rush · C Monde | `claude/clever-wozniak-h2znoi` |
| D | Tide Rush · D Chef de projet | `claude/epic-pasteur-q323d7` (intégration) |
| E | Tide Rush · E Concept | `claude/laughing-lovelace-8xixq7` |

## Décisions
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

## Phase 1 — en cours (le détail suit le GDD v2)
| # | Qui | Tâche | État |
|---|---|---|---|
| P1-01 | A | Contrat des remotes v2 (additif) dans review/review_context.md | à faire, prioritaire |
| P1-02 | A | Config : blocs GDD §13 + `LagoonTiers` ; marées Phase 1 = Normal + Golden | à faire |
| P1-03 | A | Schéma de données v2 + migration v1 → v2 | à faire |
| P1-04 | A | CreatureService (apparition en zone 1, mutation à l'apparition), croissance depuis `born`, revenu hors ligne, `wave.tide`, `LagoonTier` | à faire |
| P1-05 | A | SelfTest mis à jour | à faire |
| P1-06 | B | HUD Phase 1 : pièces, revenu, bandeau de marée | à faire |
| P1-07 | B | Billboard de bassin (stade, mutation, barre), écran « Pendant ton absence », Codex 2×2 | à faire |
| P1-08 | B | Onboarding des 60 s (GDD §8), preset Golden appliqué aux créatures | à faire |
| P1-09 | C | tools/world : construction du lagon de Plot1 (palier 1) + assemblage de la hero shot | à faire |
| P1-10 | C | Sourcing des modèles Pebble Crab et Sand Star (Creator Store : IDs à vérifier lundi ; prompts generate_mesh prêts) | à faire |
| P1-11 | C | Presets Golden : FX (Assets.FX.Mutations.Golden) et valeurs de Lighting pour la Golden Tide | à faire |
| P1-12 | E | Simulation de l'économie des 60 premières minutes (rythme) | à faire |

## Fait
- [A 09/10] Net.lua : plus de seau de limite recréé pour un joueur parti. **À réimporter lundi.**
- [B 09/10] Notifications.lua : nom de la rareté dans le toast, pas de doublon en file. **À réimporter lundi.**
- [E 09/10] docs/GDD.md v1.
- [A 09/10] docs/ARCHI_SERVEUR_REEF.md.
- [B 09/10] docs/UI_REEF.md.
- [C 09/10] docs/DA_MONDE.md et docs/CREATURES_ART.md.

## Questions pour Moaad
1. Nom du jeu : garder « Tide Rush », ou passer à « Reef Keepers » / « Tide Rush: Reef Keepers » ?
2. Prix des gamepasses : les valeurs de départ du GDD §9 restent jusqu'aux premiers tests.
