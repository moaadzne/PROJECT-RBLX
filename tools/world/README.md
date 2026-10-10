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
| 2 | `build_lagoon.luau` | lagon palier 1 : socles et Deck masqués (collisions gardées), sable terrain, 1 cuvette de roche volcanique par PedestalN (fond, eau claire, corail vivant), barrière corail + roche `PlotN.Barrier`, abri, palmier, ponton. Option `SUNK_POOLS` (lagon creusé) **à valider par D et A** | oui |
| 3 | `build_wave.luau` | `Assets.Wave` v2 (mêmes noms : Body, Foam, Crest/Spray ; en plus Inner, ShadowBand, Mist, FootSplash) + `Assets.WaveSwell` (houle de 55 studs pour l'alerte). L'ancienne vague va dans `C_Backup.Wave_v1` | oui |
| 3 bis | `build_lighting.luau` | **N** : lumière et eau FINALES du jeu (Technology Future à la main par Moaad ; Atmosphere Density 0.3 / Haze 2 / Glare 1, Bloom 0.5, SunRays 0.3, ColorCorrection Sat 1.1 / Contrast 0.1 ; Terrain eau #1a7aa6, Transp 0.4, WaveSize 0.8, WaveSpeed 8). À lancer AVANT `build_mutation_fx.luau`, dont les presets de marée partent de ces valeurs | oui |
| 3 ter | `build_zone_palettes.luau` | **N** : les 5 zones (Crique, Dunes, Récif, Falaise, Épave) : couleurs des matériaux (MaterialService), ambiances par zone et voiles d'eau teints. Écrit `Map.ZonePalettes` (source unique lue par B et K). Positions des voiles à confirmer avec `inspect_world.luau` | oui |
| 4 | `build_hero_shot.luau` | décor de plage autour de Plot1 (`Map.HeroDecor`), houle de la vague posée à l'arrêt, phare sur l'îlot, lumière de capture, caméra | oui |
| 5 | `capture_mode.luau` | masque Gates et Towers pour la capture ; `HIDE = false` restaure | oui |
| 6 | `build_mutation_fx.luau` | `Assets.FX.Mutations.Golden/Night/Storm/Rainbow` + `Assets.FX.TidePresets.Normal/Golden/Night/Storm` (à lancer après le réglage de la lumière) | oui |
| 7 | `build_royal_fx.luau` | `Assets.FX.Crowns.Gold/Silver/Bronze` (Accessory) + `Assets.FX.Royal` (faisceau, lumière, étincelles, mini-couronne). Importer d'abord la couronne dans _DecorLib | oui |
| 8 | `build_sounds.luau` | SoundGroups Master > SFX, Ambient, UI, Music + `Assets.Sounds.<nom>` (sons réalistes et musique APM, docs/SOURCING_C.md §4) | oui |

Après l'étape 1 : corriger les tables `FIND` (noms des assets), `ISLET_POS` (îlot du phare) et, si besoin, les positions de `DECOR` et de `CAMERA`.
Pour la hero shot : `build_lagoon.luau` avec `PLOTS = { 1, 2, 3, 4, 5, 6, 7, 8 }`, parce que les bases voisines sont dans le cadre.
**Avant de publier** : `capture_mode.luau` avec `HIDE = false`, car les tours sont du gameplay.

## Ce que les autres doivent savoir
- **A** : chaque bassin `Lagoon.Pools.PoolN` porte les attributs `PoolSlot`, `FloorY` (le haut du socle, là où le serveur pose déjà l'objet) et `WaterY`. Les PedestalN gardent leur position, Slot, LockGui et collision. Ils sont seulement invisibles.
- **A** : `PlotN.Barrier` contient l'attribut `Open` (false), `Coral` (décor sans collision) et `Blockers` (4 murs invisibles CanCollide = true, 12 studs de haut). A pilote `Open` et la collision, y compris le passage du propriétaire.
- **A / B** : `Assets.FX.Royal` se pose comme `FX.RarityBeam` (Core et Halo entre Root.BeamA et Root.BeamB, à Y + `BeamTopOffset`). `Glow` et `Sparkle` vont dans Root. `MiniCrown` va dans le modèle, à `OffsetY` au-dessus de son sommet. Les couronnes s'ajoutent avec `Humanoid:AddAccessory` sur un clone : vérifier lundi l'orientation de la couronne importée.
- **B** : la barrière est déjà animée par `Ambience.lua` (tout le modèle s'enfonce) ; l'attribut `RetractDepth` est optionnel.
- **B** : vague v2. Le corps reste à 22 de haut (gameplay). `ShadowBand` suit le front. `WaveSwell` monte de sous la mer à `SpawnZ` pendant l'alerte (`RiseTime`), puis se cache au départ. Sons `alertHit`, `rumble`, `siren`, `horn`, `waveBoom`, `waveImpact`, musique `musicRiser` puis `musicTension`.
- **B** : `Lagoon.Tier1` est le décor du palier 1. Les paliers 2 à 5 iront dans `Lagoon.Tier2..5`, affichés côté client selon `LagoonTier`. Les attributs des presets de mutation et de marée sont décrits en tête de `build_mutation_fx.luau`.
- `Lighting.Technology` n'est pas modifiable par script : il faut la passer en **Future** à la main.
