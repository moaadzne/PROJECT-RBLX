# tools/world : scripts de construction du monde (C)

Ces scripts se lancent **à la main** dans Studio, en mode édition, via `execute_luau` (MCP Studio) ou en les collant dans la barre de commande. Rien ne s'exécute automatiquement : ils ne sont pas dans `src/` et ne sont pas synchronisés dans le jeu.

Règles communes :
- `DRY_RUN = true` par défaut : le script affiche ce qu'il ferait sans rien modifier. On lit la sortie, puis on relance avec `DRY_RUN = false`.
- Chaque exécution forme **un seul enregistrement ChangeHistoryService** : Ctrl+Z annule tout, et en cas d'erreur rien n'est gardé.
- Aucun nom ni attribut dont le serveur dépend n'est modifié (review/review_context.md, « Map facts »). Les anciens visuels sont déplacés dans `ServerStorage.C_Backup`, pas supprimés.
- Les clones de _DecorLib sont nettoyés : tout script trouvé est retiré, avec un avertissement.

## Ordre lundi
| # | Script | Ce qu'il fait | Modifie ? |
|---|---|---|---|
| 1 | `inspect_world.luau` | inventaire : _DecorLib (tailles, scripts), Plot1 et ses socles, Map, îlots hors plage (position de l'îlot du phare), Lighting | non |
| 2 | `build_lagoon.luau` | lagon palier 1 : socles et Deck masqués (collisions gardées), sable terrain, 1 bassin par PedestalN (fond, eau, anneau de rochers), barrière de corail `PlotN.Barrier`, cabane, palmier, ponton | oui |
| 3 | `build_hero_shot.luau` | décor de plage autour de Plot1 (`Map.HeroDecor`), phare sur l'îlot, lumière de la capture, caméra | oui |
| 4 | `capture_mode.luau` | masque Gates et Towers pour la capture ; `HIDE = false` restaure | oui |
| 5 | `build_mutation_fx.luau` | `Assets.FX.Mutations.Golden` + `Assets.FX.TidePresets.Normal/Golden` (à lancer après le réglage de la lumière) | oui |
| 6 | `build_royal_fx.luau` | `Assets.FX.Crowns.Gold/Silver/Bronze` (Accessory) + `Assets.FX.Royal` (faisceau, lumière, étincelles, mini-couronne). Importer d'abord la couronne dans _DecorLib | oui |
| 7 | `build_sounds.luau` | SoundGroups Master > SFX, Ambient, UI + `Assets.Sounds.<nom>` (16 sons, docs/SOURCING_C.md §4) | oui |

Après l'étape 1 : corriger les tables `FIND` (noms des assets), `ISLET_POS` (îlot du phare) et, si besoin, les positions de `DECOR` et de `CAMERA`.
Pour la hero shot : `build_lagoon.luau` avec `PLOTS = { 1, 2, 3, 4, 5, 6, 7, 8 }`, parce que les bases voisines sont dans le cadre.
**Avant de publier** : `capture_mode.luau` avec `HIDE = false`, car les tours sont du gameplay.

## Ce que les autres doivent savoir
- **A** : chaque bassin `Lagoon.Pools.PoolN` porte les attributs `PoolSlot`, `FloorY` (le haut du socle, là où le serveur pose déjà l'objet) et `WaterY`. Les PedestalN gardent leur position, Slot, LockGui et collision. Ils sont seulement invisibles.
- **A** : `PlotN.Barrier` contient l'attribut `Open` (false), `Coral` (décor sans collision) et `Blockers` (4 murs invisibles CanCollide = true, 12 studs de haut). A pilote `Open` et la collision, y compris le passage du propriétaire.
- **A / B** : `Assets.FX.Royal` se pose comme `FX.RarityBeam` (Core et Halo entre Root.BeamA et Root.BeamB, à Y + `BeamTopOffset`). `Glow` et `Sparkle` vont dans Root. `MiniCrown` va dans le modèle, à `OffsetY` au-dessus de son sommet. Les couronnes s'ajoutent avec `Humanoid:AddAccessory` sur un clone : vérifier lundi l'orientation de la couronne importée.
- **B** : `Barrier.Coral` descend de `RetractDepth` quand `Open` passe à true (0,6 s), puis remonte. Sons `barrierOpen` et `barrierClose`.
- **B** : `Lagoon.Tier1` est le décor du palier 1. Les paliers 2 à 5 iront dans `Lagoon.Tier2..5`, affichés côté client selon `LagoonTier`. Les attributs des presets de mutation et de marée sont décrits en tête de `build_mutation_fx.luau`.
- `Lighting.Technology` n'est pas modifiable par script : il faut la passer en **Future** à la main.
