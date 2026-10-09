# Pipeline art des créatures : Reef Keepers (C, 09/10/2026)

Le plus gros risque du concept (DIRECTIONS §A). Liste des espèces : **[GDD de E]**, emplacements prévus en §3.

## 1. Options de production
Aucun prix n'est donné : je n'ai pas de source vérifiée. À chiffrer avec Moaad au cas par cas.

| Option | Pour | Limites |
|---|---|---|
| **Génération IA dans Studio** (outil de génération de mesh via le MCP Studio, `generate_mesh`) | rapide, itérable, pas de licence tierce | qualité et topologie variables ; style à harmoniser ; pas de rig → animation par CFrame seulement ; disponible seulement sur le Mac de Moaad (lundi) |
| **Creator Store** (modèles gratuits) | immédiat, licence Roblox | styles disparates, souvent trop détaillés ou trop « Roblox » ; **vérifier 0 script** ; peu de créatures cohérentes en série |
| **Pack premium** (marketplace externe, licence commerciale) | une série cohérente, souvent riggée | coût ; vérifier la licence (usage commercial Roblox) ; import FBX + conversion |
| **Modéliste sur mesure** | style unique, une famille cohérente, rig adapté | délai, coût, brief précis nécessaire (ce document sert de brief) |

**Recommandation** : lundi, tester `generate_mesh` sur 2 espèces (une commune, une légendaire) avec le brief §2. Si le rendu ne tient pas sur la hero shot, passer au modéliste/pack pour les créatures **seulement** (le décor reste en _DecorLib). On garde un style unique : jamais deux sources mélangées dans un même lagon.

## 2. Règles de modélisation (brief commun)
- Style : rond, pattes/nageoires épaisses, gros yeux brillants, 2–3 couleurs à plat + dégradé doux. Aucun personnage connu, aucun mème.
- Pivot au centre du corps, face vers -Z, échelle « bébé » = ~2 studs de long.
- ≤ 2 000 triangles, 1 SurfaceAppearance (ou couleurs de vertex), texture ≤ 512 px.
- Parties séparées si possible : **Body** + **Fin/Tail** (pour l'animation par CFrame).
- Modèle dans `ReplicatedStorage.Assets.Creatures.<Id>`, PrimaryPart `Root` invisible, attributs `CreatureId`, `Rarity`, tout Anchored, 0 script (même convention que `Assets.Items`).

## 3. Fiches créatures (à compléter avec le GDD)
Tailles par stade de croissance (scale du modèle, pas de nouveau mesh) : **bébé ×1, adulte ×1,6, géant ×2,6**.

Repères de rareté (identiques pour toutes) :
| Rareté | Repère visuel |
|---|---|
| Common | aucun effet |
| Uncommon | contour clair (Highlight désactivé sur mobile → liseré de matériau) |
| Rare | légère lueur émissive sur les yeux/nageoires |
| Epic | + traînée de bulles (1 emitter, Rate 4) |
| Legendary | + faisceau de rareté (FX.RarityBeam) au sol + halo doré |

Fiches pré-remplies avec les espèces citées dans DIRECTIONS §A ; les autres sont des emplacements.

| # | Espèce | Silhouette (lisible de loin) | Taille bébé | Mouvement | Rareté proposée |
|---|---|---|---|---|---|
| 1 | Bébé tortue | carapace en dôme, 4 nageoires plates | 2 | nage lente, battement alterné | Common [GDD] |
| 2 | Poisson-lune | disque vertical, nageoires haute/basse | 2,5 | flottement, rotation lente | Rare [GDD] |
| 3 | Hippocampe | « S » vertical, queue enroulée | 1,8 | bob vertical, pas de déplacement | Epic [GDD] |
| 4 | Œuf (toutes espèces) | ovale à taches, couleur de rareté | 1,2 | balancement | — |
| 5 | Léviathan (boss) | serpent marin à crête, très long | ×10 | ondulation en sinus le long du corps | boss [GDD] |
| 6–N | [GDD] | | | | |

## 4. Mutations sans nouveau modèle
Une mutation = un **jeu de paramètres** appliqué au même modèle par le client (et/ou à la création du clone). Coût : 0 mesh supplémentaire.

| Mutation | Couleur | Matériau | Effet |
|---|---|---|---|
| Golden | Color #FFC93C sur Body | `Foil` ou SurfaceAppearance teintée, Reflectance 0,2 | paillettes dorées (Rate 3) |
| Night | base #1E2A44, motifs #3DF5FF | Neon sur les détails (yeux, taches) | lueur cyan pulsée (client, sinus 2 s) |
| Storm | #B48CFF | `Glass` léger sur nageoires | petit éclair (ParticleEmitter Rate 1, burst) |

Implémentation : un module client `CreatureLook.apply(model, mutation, rarity, stage)` ; données (couleurs, matériaux) dans Shared.Config pour qu'A et B lisent la même source **[à valider par D/A]**. Une créature peut afficher rareté + mutation : la mutation change la couleur, la rareté ajoute l'effet.

## 5. Animation côté client (sans rig)
Tout en CFrame local, calculé avec dt, jamais côté serveur (bible §6 Technique). Paramètres en attributs du modèle (comme TR_Spin : `BasePos`, `Bob`…).

- **Nage en bassin** : orbite elliptique autour du centre du bassin (rayon 1,5–2 studs), vitesse 0,4 rad/s ±20 % aléatoire par créature, le modèle regarde sa tangente.
- **Flottement** : Y = base + sin(t·1,6 + phase) × 0,25.
- **Battement** : Tail/Fin oscillent en rotation (±15°, 3 Hz) si la pièce existe ; sinon léger roulis du corps (±5°).
- **Au sol (sur la plage)** : sautillement sur place + rotation lente (réutilise SpinAnimator, tag TR_Spin).
- **Capture** : gonfle à 1,3 puis disparaît (bible §6), particules couleur rareté.
- **Perf** : une seule boucle RenderStepped pour toutes les créatures ; on n'anime que celles à < 120 studs de la caméra ; au-delà, figées.

## 6. Ordre lundi
1. Dossier `Assets.Creatures` + 1 placeholder conforme §2 pour débloquer A et B.
2. `generate_mesh` : bébé tortue + hippocampe, jugés dans la hero shot.
3. Verdict à D : on garde la génération, ou on passe à modéliste/pack.
