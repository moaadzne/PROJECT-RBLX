# Sourcing de C : créatures, couronnes et sons (09/10/2026, GDD v2)

**Méthode** : le 09/10, j'ai interrogé l'API publique du Creator Store (`apis.roblox.com/toolbox-service/v1/marketplace` et `/items/details`) et regardé les vignettes. Les données ci-dessous (scripts, triangles, gratuit) viennent de cette API. **Rien n'est encore validé.** Lundi, dans Studio, chaque ID doit passer la vérification §3 avant d'entrer dans le jeu.

## 1. Créatures et couronnes (Creator Store)
Filtre appliqué : `hasScripts = false`, gratuit. J'ai écarté les modèles qui reprennent une propriété intellectuelle (Pokémon, Pet Sim, TDX, Dev Awards…).

| Rôle | ID | Nom (créateur) | Triangles | Avis sur la vignette |
|---|---|---|---|---|
| **PebbleCrab** | **128260644806616** | Bone Rigged Crab (Qztuezzzz, 07/2025) | 2 898 | **le seul vraiment stylisé** : orange, gros yeux, pinces rondes, avec un rig. **Dépasse le budget de 1 500** : prototype seulement |
| PebbleCrab (à écarter) | 79383488594800 | Crab (sigma_pro975, 08/2025) | 2 898 | même vignette et mêmes triangles, publié un mois après : **réupload probable** |
| **SandStar** | 5174450906 | Starfish (Monschl) | 1 276 | étoile réaliste vert-jaune, 1 MeshPart ; recolorable |
| SandStar | 5088223335 | starfish (TreeckoEleganteM) | 1 680 | étoile réaliste orange, texturée ; légèrement au-dessus du budget |
| **ReefHatchling** | **9942412730** | Turtle (MattVSNNL, 2022) | 1 118 | **tortue stylisée** verte (gros yeux, sourire), 1 MeshPart, 10 votes sur 10. **Mais c'est une tortue de terre** (pattes, pas de nageoires) : à recolorer en turquoise ; dos assez plat pour la selle ? À vérifier |
| ReefHatchling | 4597594292 | Green sea turtle (Capyvarinha, 2020) | 1 636 | vraie tortue de mer avec nageoires, mais réaliste : ne colle pas au style |
| **Couronne** (base des 3 rangs) | **12506519368** | Crown (vanyakrashov) | 128 | couronne simple low-poly, 1 MeshPart, 8 votes sur 10 : **la plus facile à recolorer** en or, argent et bronze |
| Couronne | 13105387046 | REAL GOLD CROWN (Hachi_OfficialBACK) | 544 | style cartoon, pointes rondes ; très lisible |
| Couronne | 5416453719 | crown (gertyba) | 1 850 | dorée avec pierres rouges, 3 MeshParts ; la plus belle, mais plus lourde |

Verdict : le Store dépanne pour le crabe, l'étoile recolorée et les couronnes. Pour la Reef Hatchling, la tortue stylisée 9942412730 sert de **prototype jouable** (pour tester la monture), mais la version finale doit être une tortue **de mer** : `generate_mesh` (prompt 3) ou un modéliste après le test fermé.

## 2. Prompts `generate_mesh` (prêts à l'emploi)
Vérifier lundi la signature exacte de l'outil (paramètres, taille). Lancer chaque prompt 3 fois et garder le meilleur résultat selon la grille §3.

**Suffixe de style commun** (à ajouter à chaque prompt) :
> stylized console game art style, chunky rounded shapes, soft hand-painted colors, clean readable silhouette, single creature, centered, no base, no background, no text

1. **PebbleCrab**
   > cute baby crab with a round smooth pebble-like shell in warm grey-blue stone colors, two small orange claws raised happily, big glossy black eyes on short stalks, six short rounded legs, standing pose, facing forward
2. **SandStar**
   > cute starfish with five thick rounded arms, warm sandy orange color with tiny lighter dots, two big friendly eyes in the center, slightly puffy shape, lying flat, top view friendly
3. **ReefHatchling** (montable)
   > large friendly young sea turtle with a wide, low and flat domed shell made of smooth teal and sand-colored plates with a darker outline, four broad flippers spread out, small rounded head held low with big kind eyes, flat back suitable for a rider, swimming pose, facing forward
4. **Couronne** (si aucune couronne du Store ne convient)
   > simple chunky royal crown with five rounded points and a smooth band, single solid material, no gems, game item

Si le résultat est trop détaillé ou réaliste, on ajoute « low poly, simple flat colors ». S'il est trop « jouet », on ajoute « subtle surface detail ».

## 3. Vérification lundi (chaque modèle, Store ou généré)
- [ ] 0 Script, LocalScript ou ModuleScript (recherche dans l'arbre après insertion)
- [ ] Store : créateur d'origine (pas un réupload), licence du Creator Store
- [ ] ≤ 1 500 triangles, sinon marqué « prototype »
- [ ] silhouette lisible à 60 studs sur téléphone ; style cohérent avec la hero shot
- [ ] rangé selon CREATURES_ART.md §2 (Root, attributs, face -Z, Anchored, dimensionné à la taille Adult)
- [ ] Reef Hatchling : `Saddle`, `SurfStand` et dimensions de CREATURES_ART.md §3 bis ; test assis avec un avatar R15

## 4. Sons
Je retiens seulement **ProSoundEffects** et **APMOfficial**, les bibliothèques sous licence publiées pour Roblox (créateurs vérifiés). J'ai écarté les réuploads de jeux ou de séries (HL2, BFDI…). La durée est en secondes, d'après l'API. Ils sont installés par `tools/world/build_sounds.luau` dans `ReplicatedStorage.Assets.Sounds.<nom>`, la convention de `TideClient/Sfx.lua` : B joue `Sfx.Play("<nom>")`.

| Nom (Sfx) | Usage | ID | Son | Durée | Alternatives |
|---|---|---|---|---|---|
| `pickup` | prise | 9112751536 | Bubble Bloop High Pitched Cute 1 | 1 | 9112872009 ; pitch selon la rareté |
| `crabPip` | le crabe saute de joie (intro) | 9120222115 | Toy Squeak 2 | 2 | 9120222027 |
| `splash` | plongeon dans le bassin (intro) | 9125703162 | Mud Puddle Splash Shallow Water Impacts | 1 | 9125702439, 9125702803 |
| `rumble` | grondement de l'alerte (intro) | 9112775181 | Earthquake Rumble 2 | 49 | 9120018695 |
| `horn` | corne de brume (intro, alerte) | 9113467353 | Boat Horn Short Long Blasts 2 | 4 | 9113467357 ; 9125544480 |
| `waveImpact` | la vague s'écrase | 9120610956 | Wave Crash 1 | 16 | 9120611182 ; 9120611452 |
| `steal` | vol : la créature saute dans les bras | 9116400132 | Magic Movement Airy Whips Swooshes 24 | 1 | 9116399338 ; 9120718689 (Whoosh Fast Swish By 2) |
| `theftAlert` | alerte du propriétaire | 9113085114 | Alarm Bell On Hard Surface 1 | 27 (à couper à 1,5 s) | 9125544285 |
| `barrierOpen` | le corail rentre dans le sable | 9118770617 | Sand Silt 2 | 2 | 9118769530 (Sand Pour) |
| `barrierClose` | le corail remonte | 9118689425 | Rocks Knock Against Each Other 3 | 3 | 9113807062 (Cinder Block Slide) |
| `surf` | début de la glisse sur la crête | 9120606857 | Water Surge 1 | 2 | 9120607089 |
| `surfLoop` | embruns pendant le surf (boucle) | 9120591281 | Water Spray 1 | 15 | 9120618803 |
| `royalWin` | top 3 de la Marée Royale | 1846266827 | Short Fanfare (APM) | 6 | 9112766203 (Crowd Cheer 2) |
| `ambientBeach` | ambiance plage (boucle) | 9119679792 | Surf Waves Crash On Shore Constant | 8 | 9119677305 |
| `seagulls` | mouettes (boucle) | 9112870701 | Seagulls 2 | 42 | 9118858002 |
| `bubbles` | bulles des bassins (boucle) | 9112752570 | Bubbles Dribble Small Bloops 1 | 14 | 9112752575 |

Lundi : écouter chaque son dans Studio, régler les volumes sur téléphone, et vérifier que chaque son est toujours public.
