# DA du monde : Ride the Tsunami (C, v2 du 09/10/2026)

**docs/DIRECTION_V2.md prime** sur ce document et sur la bible pour le style. Concept et chiffres : docs/GDD.md (v2). Créatures : docs/CREATURES_ART.md. IDs et sons : docs/SOURCING_C.md. Scripts : tools/world/.

**Style : réaliste stylisé.** Le monde est crédible : la lumière, l'eau, les matériaux et les animaux se comportent comme en vrai. Les formes sont simplifiées. Jamais de cartoon, rien de mignon. Une silhouette doit se lire à 60 studs sur un écran de téléphone.

## 0. Contraintes héritées (ne pas casser)
Le serveur dépend de ces noms et attributs (review/review_context.md) :
- `Map.Plots.PlotN` (1..8) : `Index`, `MinX`, `MaxX`, `MinZ`=4, `MaxZ`=67, `SpawnPos` (Y=1), `Owner`, `OwnerName`, `LagoonTier`. Enfants : `Pedestals/PedestalN` (`Slot`, `LockGui`), `Display`, `SignAnchor.OwnerGui.Title`, `Barrier` (`Open`).
- `Map.Towers.TowerN` : `Center`, plateforme au-dessus de Y 34.
- Vague de gameplay : hauteur 30 et épaisseur 40 (Config.Wave). Un joueur est pris si ses pieds sont sous Config.Wave.height.
- Base : **`Center` + `Radius`** (contrat ile ouverte, A 10/10). `Center` = centre du lagon au sol, `Radius` = rayon horizontal, deck compris. « Dans le lagon » = distance horizontale à `Center` ≤ `Radius`. Les anciens `MinX/MaxX/MinZ/MaxZ` restent un repli côté serveur. Sortie du lagon : `Center + o·(Radius + 5)`, `o` = direction horizontale de la crique vers `Center`, donc **côté extérieur, face à la plage**.

Règle C : je remplace le visuel et je garde les objets porteurs. Tout déplacement d'un objet porteur passe par D, puis A.

## 1. Ce qui faisait moche, et la parade v2
| Cause | Parade |
|---|---|
| Formes en blocs (decks, arches, tours, cabanes) | uniquement des MeshParts organiques ; aucun Part visible de plus de 4 studs, sauf l'eau |
| Plastique lisse, couleurs saturées partout | matériaux PBR (sable, roche volcanique, bois flotté, corail) ; palette naturelle §3, avec des accents seulement |
| Style « jouet » ou enfantin | réaliste stylisé : proportions vraies, pas de gros yeux, pas de couleurs bonbon, pas de déco mignonne |
| Échelle incohérente | gabarit : avatar ≈ 5 studs, porte ≈ 7, palmier 20–30, rocher de lisière 4–8, phare ≈ 60, vague 22 de corps et 50+ en houle (§4) |
| Grands aplats vides | sable avec variations (traces, sable mouillé, laisse de mer, bois flotté), roches, végétation dense en lisière |
| Lumière plate | Future, soleil bas rasant, ombres douces, brume atmosphérique (§5) |
| Textes 3D génériques (« BASE i », « ▲ SAFE ») | aucun texte 3D en police par défaut ; panneaux en bois gravé, ou interface de B |
| Avatar par défaut dans la capture | avatar habillé, bien éclairé, à la bonne échelle |
| Horizon vide | îles volcaniques en silhouette, nuages, brume ; la houle de la vague y naît (§4) |

## 2. Le lagon du joueur : un vrai lagon
Un lagon, ce sont des **cuvettes de roche volcanique remplies d'eau claire, avec du corail vivant** : rien qui ressemble à un socle ou à un bac.

### Plan d'une base (vue de dessus, -Z = la mer)
```
Z 4   ═══════ barrière de corail et de roche (Front) ═══════   ponton de bois flotté devant
      │  cuvettes 1 à 5 (rangée avant)                      │
      │  cuvettes 6 à 10 (rangée arrière, verrouillées)      │
      │  abri en bois flotté + palmiers (palier)             │
Z 67  ═══════ barrière (Back) ═══════════════════════════════
```
- **Cuvette = un PedestalN** (`tools/world/build_lagoon.luau`). Le cylindre est invisible ; nom, Slot, LockGui et collision sont gardés.
  - Fond de sable clair, eau `Glass` #2FB8B3 à 0,5 de transparence, pour qu'on voie la créature au fond.
  - Rebord : 4 gros blocs de roche volcanique qui se chevauchent, plus un corail vivant dans l'eau.
- **Deux variantes**, choisies par l'option `SUNK_POOLS` :
  - **surélevée** (par défaut, aucun objet porteur déplacé) : une dalle de roche volcanique d'environ 3 studs de haut, avec l'eau dedans, comme les cuvettes d'un platier rocheux ;
  - **creusée** (recommandée, **à valider par D et A**) : les PedestalN descendent de 3,5 studs et le terrain est creusé. L'eau affleure au niveau du sol : c'est un vrai lagon. Le serveur pose déjà la créature en haut du socle, donc il n'y a aucun code à changer, mais les positions des socles bougent.
- Cuvette verrouillée : eau trouble et sombre, LockGui visible. Au déverrouillage, l'eau s'éclaircit en 0,5 s.

### Richesse lisible de loin (`LagoonTier` 1..5, écrit par A)
| Palier | Élément haut (silhouette) | Détail bas |
|---|---|---|
| 1 | abri en bois flotté, 1 palmier | cuvettes nues |
| 2 | + torches en bambou (flamme réelle, sans lumière dynamique) | coquillages et algues au bord |
| 3 | + petite cascade sur la roche derrière l'abri | coraux vivants plus nombreux |
| 4 | + phare de lagon en pierre (faisceau lent) | rebords incrustés de nacre |
| 5 | + arche de roche volcanique couverte de corail | eau scintillante, reflets dorés |
Chaque palier ajoute un élément haut et un détail bas. Les achats de déco se posent dans des emplacements fixes.

### Barrière : massive et crédible
`PlotN.Barrier` (Model, toutes les parts ancrées) : environ 40 masses de corail et de roche volcanique sur le contour, de 6,5 à 8 studs de haut, plus 4 `Blockers` invisibles de 12 studs. A pilote `Open` et la collision. B enfonce tout le modèle dans le sable à l'ouverture (`Ambience.lua`), avec les sons `barrierOpen` et `barrierClose`.
- **Fermée** : un récif continu, plus haut qu'un avatar, roche sombre et corail aux teintes naturelles.
- **Ouverte** : le récif s'enfonce, le passage est visiblement libre.

## 3. Palette naturelle, avec des accents
| Usage | Couleur | Rôle |
|---|---|---|
| Sable sec / sable mouillé / traces | #E6D2A8 / #A58C66 / #D3BC8C | base |
| Roche volcanique (clair / sombre) | #5A524C / #3B3633 | structure, contraste |
| Bois flotté (clair / sombre) | #A8998A / #7D6E60 | constructions |
| Végétation | #3F6B3A, #6C8F4A | lisières |
| Lagon peu profond / profond | **#2FB8B3** / #13707A | **accent turquoise** |
| Océan au large | #0D3B4C | profondeur |
| Écume | #EEF5F2 | vague, rivage |
| Corail vivant (désaturé) | #D9776A, #B8607A | détails |
| Couchant | #F2A35E | lumière, ciel |
| Or (rareté, Golden, couronne) | **#D9A93F** | **accent rare** |
| Rareté (Roblox, lisibilité) | gris #A7B0BA, vert #5BD16A, bleu #4AA8FF, violet #B06BFF, or #FFC93C | toujours avec icône et nom |
Règle : 80 % de tons naturels. Le turquoise et l'or sont des accents qu'on remarque. Aucune couleur saturée sur une grande surface.

## 4. La vague, star du jeu
On doit avoir peur la première fois. Décision D 09/10 : la vague **monte** à **30**, les plateformes de tours à **34** (A fixe les valeurs finales ; `Config.Wave.height` fait foi). ⚠ La crête et les embruns ne doivent jamais dépasser une plateforme où l'on est à l'abri. La vague arrive désormais **des 4 directions (N/E/S/O)**, jamais deux fois de suite la même. Modèle : `tools/world/build_wave.luau`.

| Phase (WaveState) | Ce qu'on voit | Ce qu'on entend |
|---|---|---|
| **Alerte** (7 s) | À l'horizon, **du côté d'où elle vient** (N = -Z, E = +X, S et W inversés ; A 10/10), une **houle** monte de 0 à **55 studs**, plus haute que les tours, sur toute la largeur. Elle traverse de -330 à +330 sur son axe. La mer se retire et découvre le sable mouillé. Le ciel fonce (ColorCorrection -0,1). | grondement grave qui monte (`rumble`), corne (`horn`), musique tendue (`musicTension`) |
| **Départ** | La houle **déferle** en 1,5 s : la crête s'enroule vers l'avant et s'effondre. Les embruns jaillissent, **sans dépasser Y 29** (sous les plateformes des tours, Y 34). | `waveBoom` (impact lourd) |
| **Course** | Corps de 30 × 300 × 40, turquoise profond en bas, plus clair en haut. Crête d'écume en rouleau. Embruns **jusqu'à environ 29** : ils balaient les plateformes des tours (Y 34) sans danger, et les joueurs dessus sont éclaboussés à l'écran. **Ombre** : une bande sombre glisse sur le sable 20 studs devant le front. | rugissement continu, `waveImpact` au contact du rivage |
| **Reflux** | L'eau se retire en laissant du sable mouillé brillant, qui sèche en 3 s. | ressac |

Notes pour B : la houle d'alerte est `Assets.WaveSwell`, rendue côté client. Si Moaad veut une vague plus haute **pendant la course**, il faut monter les tours et `Config.Wave.height`, ce qui est une décision de D et de A.

### Lumière par marée (presets livrés à B)
Les valeurs sont dans `Assets.FX.TidePresets.<Marée>` (`build_mutation_fx.luau`). Normal reprend la lumière de la hero shot ; les autres sont des écarts par rapport à Normal.
| Marée | Lumière | Atmosphere |
|---|---|---|
| Normal | couchant, ClockTime 17, ombres douces | brume chaude légère |
| Golden | soleil plus bas (17,45), Bloom +0,2, teinte dorée | brume dorée, Glare +0,3 |
| Night (Phase 2) | ClockTime 20,5, lune froide, bioluminescence | bleutée |
| Storm (Phase 2) | désaturée (-0,25), plus sombre | grise et dense (+0,15) |

## 5. Budgets de perf mobile (60 FPS sur un téléphone moyen)
| Poste | Budget |
|---|---|
| Parts visibles à l'écran | ≤ 3 000 (carte ≤ 8 000, StreamingEnabled) |
| Par base (palier 5, barrière comprise) | ≤ 150 parts : 10 cuvettes × 7 + barrière 44 + décor du palier |
| Triangles par créature | ≤ 1 500 (au-delà, prototype seulement) |
| Lumières dynamiques | ≤ 8 près du joueur ; 0 par cuvette ; 1 seule par créature royale ou Night |
| Ombres de lumières locales | 0 (seul le soleil fait de l'ombre) |
| Particules | ≤ 15 émetteurs à l'écran, ≤ 300 particules/s ; la vague a droit à 3 émetteurs (crête, embruns, pied) |
| Sons simultanés | ≤ 12 ; 1 musique et 2 ambiances au maximum |
| Terrain water | seulement l'océan |
Mouvements d'ambiance côté client, avec dt. `CastShadow = false` sur les petits props, `CanCollide/CanQuery/CanTouch = false` sur le décor non marchable.

## 6. Hero shot (lundi 12/10)
Objectif : passer le **test « wow mais Roblox »** (§7) dès la première capture. Sinon, on ne la montre pas.

### Cadre
- **Caméra** : depuis l'arrière de Plot1, (-112, 14, 80), elle regarde vers (-80, 3, -120). FOV 60, légère plongée.
- **Composition** :
  - premier plan, tiers gauche : le lagon de Plot1 (cuvettes de roche, eau claire, une créature visible) et l'avatar habillé de dos, debout sur le ponton ;
  - milieu : la plage, avec ses traces, le sable mouillé et le bois flotté ;
  - fond : **la houle de la vague qui se lève à l'horizon**, plus haute que les tours, en contre-jour du couchant, et le phare sur son îlot de roche volcanique.
- **Moment** : l'alerte, ciel légèrement assombri. C'est la scène qui fait peur et qui vend le jeu.

### Placements
Les positions exactes sont dans les scripts et s'affinent capture après capture.
| Élément | Source | Où |
|---|---|---|
| Lagon de Plot1 (et des bases voisines) | `build_lagoon.luau`, `PLOTS = 1..8` | les bases |
| Palmiers, rochers, végétation, bois flotté, coraux au rivage | _DecorLib (pack nature, palmiers, corail, coquillages) | `build_hero_shot.luau` (`Map.HeroDecor`) |
| Radeau échoué | _DecorLib | rivage gauche |
| Phare | _DecorLib | îlot volcanique (position donnée par `inspect_world.luau`) |
| Houle de la vague | `Assets.WaveSwell` (`build_wave.luau`) | Z ≈ -450, posée à l'arrêt pour la capture |
| Créature | candidat validé (SOURCING_C.md) | une cuvette avant |
Masqués pour la capture : Gates, Towers et tout bloc de l'ancienne carte (`capture_mode.luau`).

### Lumière
Future (à régler à la main), ClockTime 17,05, latitude 15, Bloom 0,4 (seuil 1,5), ColorCorrection : saturation +0,05 (pas plus), contraste +0,08, teinte à peine chaude. Atmosphere : densité 0,32, Haze 1,2, couleur #F2A35E, Decay #13707A.

## 7. Le test « wow mais Roblox » (avant de montrer quoi que ce soit)
1. La capture pourrait passer pour un jeu console stylisé.
2. Un joueur de 20 ans ne la trouve pas enfantine.
3. Un joueur de 10 ans comprend quoi faire en 5 secondes, sans lire.
4. 60 FPS sur un téléphone moyen (≥ 55 sur ce cadre), rien de saccadé.
5. Les avatars Roblox s'intègrent sans faire tache.
6. Aucun bloc, aucun plastique lisse, aucun emoji, aucune police ronde.

Plus, pour la hero shot :
- la vague (ou sa houle) se voit et impressionne ;
- le lagon se lit comme « à moi » ;
- 80 % de couleurs naturelles, et des accents qui ressortent ;
- recadrée en 1:1, la capture tient comme miniature.

**Si un seul point échoue, on ne montre pas.** On corrige, ou on dit à D ce qui manque (souvent un asset).

## 8. Ce qu'il me faut
- D et A : valider `SUNK_POOLS`, c'est-à-dire descendre les PedestalN de 3,5 studs (noms et attributs inchangés).
- A : le passage du propriétaire à travers sa barrière fermée.
- E : le roster définitif (Phase 1 probable : crabe fantôme, étoile de mer, tortue imbriquée montable).
- Moaad : Lighting.Technology en Future ; importer dans _DecorLib les candidats de SOURCING_C.md.
