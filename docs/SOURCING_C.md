# Sourcing de C : créatures, couronnes et sons (v2 du 09/10/2026, réaliste stylisé)

**Méthode** : le 09/10, j'ai interrogé l'API publique du Creator Store (`apis.roblox.com/toolbox-service/v1/marketplace` et `/items/details`) et regardé les vignettes. Les données ci-dessous (scripts, triangles, gratuit) viennent de cette API. **Rien n'est encore validé.** Lundi, dans Studio, chaque ID doit passer la vérification §3.
Direction v2 : de vrais animaux, rien de cartoon. Les candidats « mignons » de la v1 sont écartés (crabe aux gros yeux 128260644806616, tortue souriante 9942412730).

## 1. Créatures et couronnes (Creator Store)
Filtre : `hasScripts = false`, gratuit. J'ai écarté tout ce qui reprend une propriété intellectuelle (Pokémon, Pet Sim, Dev Awards…).

| Rôle | ID | Nom (créateur) | Triangles | Avis sur la vignette |
|---|---|---|---|---|
| **GhostCrab** | **14303108140** | ghost crab (lukash338, 2023) | 996, 8 MeshParts | **vrai crabe fantôme** : yeux sur pédoncules dressés, carapace gris-bleu pâle, sous le budget. Pièces séparées, donc animable. Couleur à rapprocher du sable |
| GhostCrab | 12027630161 | Sand crab (L3git_LT, vérifié, 2023) | 2 994 | crabe de sable pâle et réaliste ; **2 fois le budget** : prototype seulement |
| GhostCrab | 13402394758 | crab rig (2023) | 1 920, 2 MeshParts | crabe brun réaliste avec pédoncules oculaires ; légèrement au-dessus du budget |
| **SeaStar** | **5174450906** | Starfish (Monschl) | 1 276 | étoile réaliste texturée, 1 MeshPart ; teinte à passer en orange-brun |
| SeaStar | 5088223335 | starfish (TreeckoEleganteM) | 1 680 | étoile réaliste orange et texturée ; un peu au-dessus du budget |
| **HawksbillTurtle** | **6193860066** | turtle (ExtraRareZooKeeper, 2021) | 2 726 | **ressemble à une tortue imbriquée** : carapace brun-rouge à écailles marquées, nageoires. Au-dessus du budget : prototype de monture |
| HawksbillTurtle | 4597594292 | Green sea turtle (Capyvarinha, 2020) | 1 636 | vraie tortue de mer à nageoires, carapace texturée ; plus proche du budget |
| **Couronne** (base des 3 rangs) | **12506519368** | Crown (vanyakrashov) | 128 | couronne simple, sobre, 1 MeshPart : facile à recolorer en or, argent et bronze, et pas enfantine |
| Couronne | 5416453719 | crown (gertyba) | 1 850 | dorée avec pierres ; plus riche, plus lourde |

Verdict : le prototype jouable est possible avec le Store (14303108140, 5174450906, 6193860066 ou 4597594292). Le niveau « wow » final demandera un modéliste ou un pack (CREATURES_ART.md §1).

## 2. Prompts `generate_mesh` (réaliste stylisé, prêts à l'emploi)
Vérifier lundi la signature exacte de l'outil. Lancer chaque prompt 3 fois et garder le meilleur résultat selon la grille §3.

**Suffixe commun** :
> realistic stylized game art, anatomically accurate proportions, natural colors, simplified clean forms, believable PBR materials, no cartoon eyes, no cute face, single animal, centered, neutral pose, no base, no background, no text

1. **GhostCrab** (crabe fantôme)
   > ghost crab, square pale sand-colored carapace with subtle grey mottling, two long upright eye stalks, one claw slightly larger than the other, thin long walking legs, low crouched stance, facing forward
2. **SeaStar** (étoile de mer à boutons)
   > knobbed sea star, five thick tapered arms, warm orange-brown body with rows of dark brown conical knobs on top, slightly rough texture, lying flat
3. **HawksbillTurtle** (tortue imbriquée, montable)
   > adult hawksbill sea turtle, elongated shell with overlapping amber, brown and gold scutes, hooked narrow beak, large front flippers spread wide, grey-beige scaled skin, wide and fairly flat shell top, swimming pose, facing forward
4. **Couronne** (si aucune couronne du Store ne convient)
   > simple heavy royal crown, five sharp points, plain smooth band, solid metal, no gems, game item

Si le résultat est trop « jouet », on ajoute « more realistic surface detail ». S'il est trop lourd ou trop détaillé, on ajoute « low poly, simplified ».

## 3. Vérification lundi (chaque modèle, Store ou généré)
- [ ] 0 Script, LocalScript ou ModuleScript
- [ ] Store : créateur d'origine (pas un réupload), licence du Creator Store
- [ ] ≤ 1 500 triangles, sinon marqué « prototype »
- [ ] **vrai animal reconnaissable**, sans gros yeux ni visage mignon (DIRECTION_V2)
- [ ] silhouette lisible à 60 studs sur téléphone ; cohérent avec la hero shot ; passe le test « wow mais Roblox »
- [ ] rangé selon CREATURES_ART.md §2 (Root, attributs, face -Z, Anchored, taille Adult)
- [ ] tortue : `Saddle`, `SurfStand` et dimensions §3 bis ; test assis avec un avatar R15

## 4. Sons et musique (réalistes et graves)
Seulement **ProSoundEffects** et **APMOfficial**, les bibliothèques sous licence publiées pour Roblox. J'ai écarté les réuploads et les sons « cartoon » (squeak, bloop). Installés par `tools/world/build_sounds.luau` dans `ReplicatedStorage.Assets.Sounds.<nom>` (convention de `Sfx.lua`).

| Nom (Sfx) | Usage | ID | Son | Durée (s) |
|---|---|---|---|---|
| `pickup` | prise | 9125702803 | Mud Puddle Splash (variante courte) | 1 |
| `splash` | plongeon dans la cuvette | 9125703162 | Mud Puddle Splash Shallow Water Impacts | 1 |
| `alertHit` | début de l'alerte | 1837830879 | WHOOSHBANG-Surge Hit 01 (APM) | 9 |
| `rumble` | grondement grave qui monte | 9112775181 | Earthquake Rumble 2 | 49 |
| `siren` | alerte (déjà appelé par Hud.lua) | 9119165140 | Siren Wail 2 (à couper à 4 s) | 30 |
| `horn` | corne de brume, -3 s | 9113467353 | Boat Horn Short Long Blasts 2 | 4 |
| `waveBoom` | la houle déferle | 9125484367 | Deep Hits Big Reverberant Booms Rumbling | 4 |
| `waveImpact` | la vague s'écrase | 9120610956 | Wave Crash 1 | 16 |
| `steal` | la créature est arrachée | 9120718689 | Whoosh Fast Swish By 2 | 2 |
| `theftAlert` | alerte du propriétaire | 1842433183 | Lethal Dose (SFX 5) (APM) | 6 |
| `barrierOpen` | le récif s'enfonce | 9118770617 | Sand Silt 2 | 2 |
| `barrierClose` | le récif remonte | 9113807062 | Cinder Block Slide On Stone Surface | 5 |
| `surf` / `surfLoop` | glisse sur la crête / embruns | 9120606857 / 9120591281 | Water Surge 1 / Water Spray 1 | 2 / 15 |
| `grow` | une créature grandit (déjà appelé par PoolBillboards.lua) | 9112872437 | Small Bubbles Water Surface Float Up | 3 |
| `royalWin` + `royalCheer` | top 3 de la Marée Royale | 1837830084 + 9112766203 | BOOM-Sub Boom 05 (APM) + Crowd Cheer 2 (à couper) | 4 + 80 |
| `ambientBeach` / `seagulls` | ambiance (boucles) | 9119679792 / 9112870701 | Surf Waves Crash On Shore Constant / Seagulls 2 | 8 / 42 |
| `musicCalm` | musique calme en jeu | 1837463526 | Ethereal Drone (APM) ; alternative 1837389538 Peaceful Island | 123 |
| `musicRiser` | montée sur les 7 s d'alerte | 1846880576 | Suspense Build 2 (APM) | 11 |
| `musicTension` | alerte et vague | 91017465590486 | Tension To Action A (APM) | 124 |

Lundi : écouter chaque son et chaque musique (je n'ai pas pu les écouter d'ici), régler les volumes sur téléphone, vérifier qu'ils sont toujours publics. La musique a son propre SoundGroup `Music` pour pouvoir la couper séparément.
