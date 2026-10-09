# Sourcing de C : créatures et sons (09/10/2026)

**Méthode** : le 09/10, j'ai interrogé l'API publique du Creator Store (`apis.roblox.com/toolbox-service/v1/marketplace` et `/items/details`) et regardé les vignettes. Les données ci-dessous (scripts, triangles, gratuit) viennent de cette API. **Rien n'est encore validé.** Lundi, dans Studio, chaque ID doit passer la vérification §3 avant d'entrer dans le jeu.

## 1. Créatures (Creator Store)
Filtre appliqué : `hasScripts = false`, gratuit. J'ai écarté les modèles qui reprennent une propriété intellectuelle (Pokémon, Pet Sim, TDX…).

| Rôle | ID | Nom (créateur) | Triangles | Avis sur la vignette |
|---|---|---|---|---|
| PebbleCrab | **128260644806616** | Bone Rigged Crab (Qztuezzzz, 07/2025) | 2 898 | **le seul vraiment stylisé** : orange, gros yeux, pinces rondes, avec des os (rig). **Dépasse le budget de 1 500** : prototype seulement |
| PebbleCrab (doublon ?) | 79383488594800 | Crab (sigma_pro975, 08/2025) | 2 898 | même vignette et même nombre de triangles que le précédent, publié un mois après : **réupload probable**, ne pas l'utiliser |
| SandStar | 5174450906 | Starfish (Monschl) | 1 276 | étoile réaliste vert-jaune, 1 MeshPart ; restylable avec la couleur du preset |
| SandStar | 5088223335 | starfish (TreeckoEleganteM) | 1 680 | étoile réaliste orange, texturée ; légèrement au-dessus du budget |
| Monture | — | aucune | — | raies (32703272…) et tortues (314895157…) en blocs ou trop anciennes : **inutilisables**. Monture = `generate_mesh` |

Verdict : le Store dépanne pour le crabe en prototype. Pour l'étoile, ce sera la génération ou le Store recoloré. Pour la monture, la génération.

## 2. Prompts `generate_mesh` (prêts à l'emploi)
Vérifier lundi la signature exacte de l'outil (paramètres, taille). Lancer chaque prompt 3 fois et garder le meilleur résultat selon la grille §3.

**Suffixe de style commun** (à ajouter à chaque prompt) :
> stylized console game art style, chunky rounded shapes, soft hand-painted colors, clean readable silhouette, single creature, centered, no base, no background, no text

1. **PebbleCrab**
   > cute baby crab with a round smooth pebble-like shell in warm grey-blue stone colors, two small orange claws raised happily, big glossy black eyes on short stalks, six short rounded legs, standing pose, facing forward
2. **SandStar**
   > cute starfish with five thick rounded arms, warm sandy orange color with tiny lighter dots, two big friendly eyes in the center, slightly puffy shape, lying flat, top view friendly
3. **Monture, option tortue** [GDD v2]
   > large friendly sea turtle with a wide, low and flat domed shell made of smooth teal and sand-colored plates, four broad flippers spread out, small rounded head held low with big kind eyes, flat back suitable for a rider, swimming pose, facing forward
4. **Monture, option raie manta** [GDD v2]
   > large friendly manta ray with wide rounded wings, smooth dark teal top with soft lighter spots and pale belly, short curled head fins, big kind eyes, thick flat body suitable for a rider, gliding pose, facing forward

Si le résultat est trop détaillé ou réaliste, on ajoute « low poly, simple flat colors ». S'il est trop « jouet », on ajoute « subtle surface detail ».

## 3. Vérification lundi (chaque modèle, Store ou généré)
- [ ] 0 Script, LocalScript ou ModuleScript (recherche dans l'arbre après insertion)
- [ ] Store : créateur d'origine (pas un réupload), licence du Creator Store
- [ ] ≤ 1 500 triangles, sinon marqué « prototype »
- [ ] silhouette lisible à 60 studs sur téléphone ; style cohérent avec la hero shot
- [ ] rangé selon CREATURES_ART.md §2 (Root, attributs, face -Z, Anchored)
- [ ] monture : `Saddle` et dimensions de CREATURES_ART.md §3 bis

## 4. Sons (liste de E et ambiance DA)
Je retiens seulement **ProSoundEffects** et **APMOfficial**, les bibliothèques sous licence publiées pour Roblox (créateurs vérifiés). J'ai écarté les réuploads de jeux ou de séries (HL2, BFDI…). La durée est en secondes, d'après l'API.

| Usage | ID principal | Nom | Durée | Alternatives |
|---|---|---|---|---|
| **Prise** (ramassage) | 9112751536 | Bubble Bloop High Pitched Cute 1 | 1 | 9112872009 (Small Bubbles… Pop, 5 s, à couper) ; pitch selon la rareté (bible §6) |
| **Splash** (dépôt, plongeon dans le bassin) | 9125703162 | Mud Puddle Splash Shallow Water Impacts | 1 | 9125702439, 9125702803 (variantes à tirer au hasard) |
| **Grondement** (alerte, -7 s) | 9112775181 | Earthquake Rumble 2 | 49 | 9120018695 (Thunder Distant Rumble 2, 136 s) |
| **Corne** (alerte, -3 s, et Marée Royale) | 9113467353 | Boat Horn Short Long Blasts 2 | 4 | 9113467357 (Blasts 1) ; 9125544480 (Energy Blast Big Deep Horn Swell, 7 s) |
| **Impact de la vague** | 9120610956 | Wave Crash 1 | 16 | 9120611182 (Wave Crash 2, 21 s) ; 9120611452 (Large Impacts 6) |
| Ambiance plage (boucle) | 9119679792 | Surf Waves Crash On Shore Constant | 8 | 9119677305 (Zuma Beach 4, 40 s) |
| Mouettes (ambiance) | 9112870701 | Seagulls 2 | 42 | 9118858002 (Seagulls 1, 36 s) |
| Bulles (bassins, au plus près) | 9112752570 | Bubbles Dribble Small Bloops 1 | 14 | 9112752575 |

Lundi : écouter chaque son dans Studio, régler le volume et les SoundGroups (Ambient, SFX, UI), et vérifier que le son est toujours public.
