# DA du monde : Reef Keepers (C, 09/10/2026)

Référence visuelle : docs/BIBLE_QUALITE.md §4. Concept : docs/DIRECTIONS.md §A. Le GDD de E (docs/GDD.md) prime dès qu'il est poussé : les points marqués **[GDD]** l'attendent.

Style : **stylisé console** (formes rondes et biseautées, couleurs saturées mais chaudes, matières lisibles, pas de photoréalisme). Un objet = une silhouette lisible à 60 studs sur un écran de téléphone.

## 0. Contraintes héritées (ne pas casser)
Le serveur dépend de ces noms et attributs (review/review_context.md, « Map facts ») :
- `Map.Plots.PlotN` (1..8) : `Index`, `MinX`, `MaxX`, `MinZ`=4, `MaxZ`=67, `SpawnPos` (Y=1, dessus du deck). Enfants `Pedestals/PedestalN` (`Slot`, `LockGui`), `Display`, `SignAnchor.OwnerGui.Title`.
- `Map.Towers.TowerN` : `Center`, plateforme à Y=26, rampe vers +Z jusqu'à Center.Z+48.
- Base : centre X = -112 + (i-1)×32, donc **32 studs de large × 63 de profond** par base.

Règle C : je **remplace le visuel**, je **garde les objets porteurs**. Les PedestalN restent (mêmes noms, Slot, LockGui) ; ils deviennent les « points d'ancrage » des bassins. Si le passage socles → bassins demande de déplacer/renommer quoi que ce soit, c'est une demande à D puis à A, pas une modif C.

## 0 bis. Ce qui faisait moche (et comment c'est évité)
Verdict de Moaad au dernier test : « rien ne va, tout est à revoir ». Il a vu l'ancienne carte en blocs, avec l'avatar par défaut. Causes concrètes :

| Cause | Pourquoi ça fait « Roblox 2010 » | Parade |
|---|---|---|
| **Formes en blocs** (Parts rectangulaires : decks, arches, tours, cabanes) | angles droits partout, aucune silhouette organique | uniquement des MeshParts biseautés (_DecorLib, pack nature) ; plus aucun Part visible de plus de 4 studs, sauf s'il est caché sous le terrain |
| **SmoothPlastic / couleurs plates** | surfaces sans matière, rendu « jouet en plastique » | SurfaceAppearance sur tout objet principal ; MaterialVariant sable mouillé, bois patiné, pierre de corail ; SmoothPlastic interdit sur toute surface de plus de 2×2 studs |
| **Échelle incohérente** (objets trop gros ou trop petits par rapport à l'avatar, grandes surfaces vides) | le monde paraît faux et vide | gabarit d'échelle : avatar ≈ 5 studs, porte de cabane ≈ 7, palmier 18–28, phare ≈ 60 ; un détail de premier plan tous les 8–10 studs le long des chemins |
| **Grands aplats vides** (plage uniforme de 264 studs de large) | rien pour l'œil, profondeur nulle | variation du terrain (dunes, sable mouillé, flaques, rochers), touffes d'herbe, coquillages, laisse de mer au rivage |
| **Lumière plate** (Technology pas en Future, pas d'ombres douces) | aucun volume, couleurs ternes | Future, soleil bas rasant, Atmosphere, Bloom discret, ColorCorrection (§3) ; ombres du soleil sur tous les gros objets |
| **Palette sans direction** (couleurs de blocs au hasard, arches criardes) | patchwork, aucune identité | palette verrouillée §3 ; aucune couleur hors palette sans validation |
| **UI et textes 3D génériques** (étiquettes « BASE i », « ▲ SAFE » en police par défaut) | look de prototype | panneaux en bois sculpté ou en MeshPart, police unique de l'UI (avec B) |
| **Avatar par défaut** dans le test Studio | le personnage gris tue l'ambiance de la capture | pour les captures : avatar de Moaad ou un avatar habillé (test Studio ou téléphone) ; en jeu, les joueurs ont leur propre avatar |
| **Horizon vide** (océan qui s'arrête, ciel sans relief) | le monde a l'air d'une maquette | îles lointaines en silhouette, bateaux à l'horizon, nuages, Atmosphere qui fond le lointain |

Règle de passage : **rien n'est montré à Moaad tant que la checklist §5 n'est pas entièrement verte.**

## 1. Le lagon du joueur (remplace les socles)

### Plan d'une base (vue de dessus, Z croissant = vers l'arrière)
```
Z 4   ┌──────────── plage (vers la mer, -Z) ────────────┐
      │  ponton d'entrée + arche « nom du joueur »       │  Z 4–12
Z 12  │  ╭──────────╮        ╭──────────╮               │
      │  │ Bassin 1 │  ...   │ Bassin 5 │  rangée avant │  Z 14–34
      │  ╰──────────╯        ╰──────────╯               │
      │  ╭──────────╮        ╭──────────╮               │
      │  │ Bassin 6 │  ...   │ Bassin 10│  rangée arrière (verrouillés au départ)
      │  ╰──────────╯        ╰──────────╯               │  Z 36–56
Z 58  │  cabane + phare de lagon (niveau de richesse)   │  Z 58–67
Z 67  └──────────────────────────────────────────────────┘
```
- **Bassin = un PedestalN** : chaque bassin est centré sur son PedestalN (Slot 1..10). Le cylindre couché devient invisible (Transparency 1, CanCollide garde son réglage actuel) et le LockGui reste attaché : rien ne change pour le serveur.
- Bassin : anneau de roche corail (MeshPart du pack nature, ou palourde géante de _DecorLib pour l'avant), Ø ~6 studs, eau peu profonde = Part `Glass`/`ForceField` turquoise #16A0A8 à 0,4 de transparence, fond de sable clair #F8DA9E. **Pas de Terrain water dans les bassins** (8 bases × 10 bassins = trop coûteux et on ne contrôle pas la couleur par bassin).
- Bassin verrouillé : eau vide et grise, couvercle de planches (ponton de _DecorLib), LockGui visible. Déverrouillage = planches qui s'envolent (client) + éclaboussure.
- La créature nage **dans** son bassin (voir CREATURES_ART.md §5) : le `Display` reste le dossier runtime où le serveur pose le modèle.

### Lisibilité de la richesse (5 paliers, visibles de loin)
Le palier se lit en un coup d'œil depuis la plage, sans UI. Piloté par un attribut lu côté client (ex. `LagoonTier` 1..5 calculé depuis l'income) **[à valider par A/D, aucun attribut ajouté sans eux]**.

| Palier | Repère principal (lisible de loin) | Détails |
|---|---|---|
| 1 Débutant | cabane simple, 1 palmier | bassins en roche nue |
| 2 | + guirlande de lanternes chaudes | coquillages au bord des bassins |
| 3 | + petite cascade derrière la cabane | coraux roses #FF7A8A dans les bassins |
| 4 | + phare de lagon allumé (faisceau lent) | bassins à rebord doré, poissons d'ambiance |
| 5 Légende | + arche de corail géante + halo doré sur l'eau | particules dorées légères, eau bioluminescente la nuit |

Règle : chaque palier **ajoute** un élément haut (silhouette) + un détail bas. Les achats déco du concept (coraux, lumières, cascades) se posent dans des **emplacements fixes** prévus par palier, jamais en placement libre (perf et anti-laideur).

## 2. La plage et ses 5 zones
Plage X -132..132, Z -784..124, sol Y 0, océan Y -2. Zones et Z : PASSATION §4. Chaque zone a une **couleur dominante**, un **sol**, un **monument** (silhouette repère, visible depuis la base) et une **ambiance son**.

| Zone (Z) | Nom | Dominante | Sol | Monument (placement) | Ambiance |
|---|---|---|---|---|---|
| 1 (-25/-150) | Shallows | sable doré, turquoise | Sand + MaterialVariant sable mouillé au rivage | **Phare** sur l'îlot rocheux, X +105, Z -110 (hors zone de jeu, visible de la base) | vagues douces, mouettes |
| 2 (-150/-280) | Coral Coast | corail #FF7A8A | Sand rosé | **Arche de corail** enjambant la plage, Z -215 (≥ 30 studs au-dessus du sol, la vague passe dessous) | bulles, vent |
| 3 (-280/-420) | Sunken Reef | turquoise profond, vert d'eau | Limestone | **Temple englouti** à moitié dans l'eau, X -110, Z -350 | bulles du récif, gouttes |
| 4 (-420/-570) | Pirate Cove | bois brun, orange couchant | Ground | **Bateau pirate** échoué, X +100, Z -495 | craquements de bois |
| 5 (-570/-740) | Abyss Shore | bleu nuit #1E2A44, violet | Basalt | **Cristaux des abysses** géants, Z -700, émissifs doux | bourdonnement grave |

- Les monuments sont **hors de la bande de course** (|X| > 90) sauf l'arche (zone 2), pour ne pas gêner le gameplay et les tours (X ±75).
- Transition entre zones : 15 studs de fondu de matériau terrain + changement de props, jamais de mur.
- Les Gates actuelles (arches en blocs) sont remplacées visuellement ; leurs **noms** ne sont pas dans les Map facts, mais je ne les supprime pas sans accord de D.
- Créatures au sol : elles apparaissent là où les trésors apparaissent aujourd'hui (serveur inchangé).

## 3. La vague et la palette

### Palette (bible §4 + extensions Reef Keepers)
| Usage | Couleur |
|---|---|
| Sable sec / mouillé | #F8DA9E / #C9A86E |
| Lagon / eau peu profonde | #16A0A8 / #5FD3C9 |
| Corail | #FF7A8A |
| Couchant (lumière, accents) | #FFB25A |
| Nuit / UI | #1E2A44 |
| Écume | #F4FFFC |
| Mutation Golden | #FFC93C + émissif |
| Mutation Night | #3DF5FF bioluminescent sur base #1E2A44 |
| Mutation Storm | #B48CFF + éclairs blancs |
| Rareté | gris #A7B0BA, vert #5BD16A, bleu #4AA8FF, violet #B06BFF, or #FFC93C |

### La vague
Modèle existant `Assets.Wave` (Body 300×22×40, Foam, Crest, Spray), rendu client. Refonte visuelle :
- **Body** : MeshPart courbe (profil en « rouleau »), dégradé turquoise #16A0A8 en bas → #5FD3C9 en haut, transparence 0,15. Si pas de mesh : garder le Part `Glass` mais ajouter une 2ᵉ couche intérieure plus sombre pour la profondeur.
- **Crest** : bande d'écume blanche #F4FFFC avec Texture qui défile (OffsetStudsU, client).
- **Spray** : 1 ParticleEmitter sur la crête, Rate ≤ 40, Lifetime 0,6–1 s.
- **Couleur selon la marée [GDD]** : Golden Tide = crête dorée + paillettes ; Night Tide = vague bleu nuit à crête bioluminescente cyan ; Storm Tide = vague gris-violet + éclairs sur l'horizon. Une seule variable `TideType` (lue côté client) pilote couleurs de la vague, de Lighting et de l'Atmosphere.
- Arrivée : bible §6 (horizon assombri à -7 s, embruns, sable mouillé qui sèche en 3 s).

### Lumière par marée (Lighting, client-side tween 2 s)
Les valeurs livrées à B sont dans `ReplicatedStorage.Assets.FX.TidePresets.<Marée>`, construits par `tools/world/build_mutation_fx.luau` : Normal = copie de la lumière réglée pour la hero shot, Golden = Normal + écarts. Night et Storm arrivent en Phase 2.
| Marée | ClockTime | Ambiance | Atmosphere |
|---|---|---|---|
| Normale | 17 | chaude, ombres douces | Density 0,3, teinte orangée |
| Golden | 17,5 | + Bloom un cran, ColorCorrection Tint chaud | dorée |
| Night | 20,5 (ou 0) | lune froide, bioluminescence | bleutée, Density 0,35 |
| Storm | 16 | désaturée, contraste + | grise, Density 0,45 |

## 4. Budgets perf mobile (60 FPS, téléphone moyen)
Cible : contrôle final sur téléphone de Moaad (le Mac est trop faible pour juger).

| Poste | Budget |
|---|---|
| Parts/MeshParts visibles à l'écran | ≤ 3 000 (carte entière ≤ 8 000, StreamingEnabled ON) |
| Par base (décor lagon palier 5 inclus) | ≤ 150 parts, ≤ 12 SurfaceAppearance distinctes |
| Triangles par créature | ≤ 2 000 (géant inclus : on scale, pas plus de polys) |
| Lumières dynamiques (Point/Spot/Surface) | ≤ 8 actives près du joueur ; **0 lumière par bassin**, l'éclat = matériau Neon/émissif |
| Lumières avec Shadows | 0 (seul le soleil projette des ombres) |
| ParticleEmitters actifs | ≤ 15 à l'écran, Rate total ≤ 300 particules/s |
| Beams | ≤ 10 (faisceaux de rareté compris) |
| Textures | ≤ 1024 px ; atlas partagés du pack nature |
| Sons simultanés | ≤ 12 (ambiances en boucle : 2 max) |
| Terrain water | seulement l'océan ; aucune dans les bassins |

Règles : tout mouvement d'ambiance (palmes, nage, défilement d'écume) côté client avec dt ; `RenderFidelity Automatic` sur les MeshParts de décor ; `CastShadow = false` sur les petits props (coquillages, herbes, coraux) ; `CanCollide/CanQuery/CanTouch = false` sur le décor non marchable.

## 5. Plan de la hero shot (lundi 12/10)
Objectif : **une capture qui pourrait servir de miniature** (pilier 1). Vue depuis Plot1 vers la zone 1, au coucher du soleil. C'est le **niveau final dès la première capture**, pas un brouillon : si la checklist de validation n'est pas entièrement verte, on ne la montre pas à Moaad, on corrige d'abord.

### Cadre
- **Caméra** : position (-112, 14, 80), regarde vers (-80, 3, -120). FOV 60. Légère plongée (~6°). Format 16:9, puis recadrage 1:1 pour vérifier que la miniature tient.
- **Composition (règle des tiers)** : tiers gauche = lagon de Plot1 (premier plan) ; centre = plage et rivage mouillé ; tiers droit, en fond = phare sur son îlot avec le soleil bas derrière.

### Placements (assets de `ReplicatedStorage.Assets._DecorLib`)
| # | Asset | Position approx. | Rôle |
|---|---|---|---|
| 1 | Cabane stylisée | (-120, 0, 62), tournée vers -Z | fond de base, palier 1 |
| 2 | Palmiers ×3 | (-126, 0, 20), (-98, 0, 50), (-60, 0, -40) | cadre vertical gauche + profondeur |
| 3 | Ponton | entrée de Plot1, Z 4–12 | ligne directrice vers la plage |
| 4 | Rochers du pack nature (anneaux) ; palourde en option | autour de chaque PedestalN | rebords des bassins (palourde testée après l'inventaire) |
| 5 | Coraux + coquillages | rivage gauche, X -118..-128, Z -20..-102 | détails bas, couleur corail |
| 6 | Pack nature (rochers, buissons) | lisière X -132, bord de l'îlot | casser les lignes droites |
| 7 | Radeau | dans l'eau près du rivage gauche, (-152, eau, -85) | point d'intérêt au milieu du cadre |
| 8 | Phare | sur l'îlot rocheux existant (position relevée par `inspect_world.luau`), placé du côté du soleil | monument de la zone 1, au fond |

Les positions exactes et la caméra sont dans `tools/world/build_hero_shot.luau` (et `build_lagoon.luau` pour la base). Elles sont à affiner lundi, capture après capture.
- Créatures : **pas de placeholder dans le cadre**. Des sphères colorées feraient « prototype ». Si on n'a pas encore de vraies créatures lundi, le cadre montre les bassins avec de l'eau, des coraux et des coquillages, sans créature.
- Personnage : un avatar habillé se tient sur le ponton, de dos, et regarde la plage (il donne l'échelle). Jamais l'avatar gris par défaut.
- À masquer pour la capture : Gates, Towers, decks et arches en blocs, panneaux « BASE i » (Transparency locale, pas de suppression).

### Lumière de la capture
Technology **Future** (à passer à la main). ClockTime 17,05, GeographicLatitude 15 (existant). Bloom Intensity ~0,4, Threshold 1,5. ColorCorrection « TideColor » : Saturation +0,1, Contrast +0,05, Tint très légèrement chaud. SunRays Intensity ~0,05. Atmosphere Density 0,3, Haze 1, Color #FFB25A, Decay #16A0A8.

### Validation
1. Capture plein écran sur le Mac (résolution), puis **test sur téléphone** (Studio Device Emulator ne suffit pas pour le rendu).
2. Checklist (tout doit être vrai) :
   - la silhouette du phare se lit, et le lagon de Plot1 se lit comme « à moi » ;
   - aucun Part rectangulaire visible, aucune surface SmoothPlastic, aucun bloc de l'ancienne carte dans le cadre ;
   - l'échelle est cohérente avec l'avatar (gabarit §0 bis) ;
   - le premier plan, le milieu et le fond ont chacun un point d'intérêt, et l'horizon n'est pas vide ;
   - toutes les couleurs sont dans la palette §3 ;
   - recadrée en 1:1, la capture tient comme miniature.
3. FPS sur téléphone ≥ 55 en regardant ce cadre.
4. Si un point est rouge, on ne montre pas la capture : on corrige, ou on signale à D ce qui manque (souvent un asset).

## 6. Ce qu'il me faut
- Liste des créatures et des marées **[GDD de E]**.
- Accord A/D : (a) attribut de palier `LagoonTier` (ou équivalent) ; (b) masquer le cylindre des PedestalN en gardant objet, Slot et LockGui.
- Moaad : passer Lighting.Technology en Future ; dire si les 9 assets suffisent après la hero shot.
