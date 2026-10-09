# Pipeline art des créatures : Reef Keepers (C, 09/10/2026)

Le plus gros risque du concept. Références : docs/GDD.md v2, §4.2 à 4.8, §11 C et §12. La Phase 1 compte **3 espèces : Pebble Crab, Sand Star et Reef Hatchling (montable)**. Les IDs et les sons sont dans docs/SOURCING_C.md.

## 1. Options de production
Aucun prix n'est donné : je n'ai pas de source vérifiée.

| Option | Pour | Limites |
|---|---|---|
| **Génération IA dans Studio** (`generate_mesh` du MCP Studio) | rapide, itérable, aucune licence tierce | qualité et topologie variables ; style à harmoniser ; pas de rig, donc animation par CFrame seulement ; disponible seulement sur le Mac de Moaad (lundi) |
| **Creator Store** (gratuit) | immédiat | styles disparates, beaucoup de modèles anciens ou en blocs ; **vérifier 0 script et la provenance** (risque de réupload) |
| **Pack premium** (licence commerciale) | une série cohérente, souvent riggée | coût, licence à vérifier, import FBX |
| **Modéliste sur mesure** | style unique, famille cohérente, rig adapté | délai, coût, brief nécessaire (ce document sert de brief) |

### Avis franc : le gratuit peut-il atteindre le niveau visé ?
- **Décor : oui, probablement**, avec _DecorLib bien assemblé. À confirmer lundi sur la hero shot. Les monuments des zones 2 à 5 manquent (Phase 2).
- **Créatures : non, je ne compte pas dessus.** Les créatures se voient de près, en permanence, et en série. Il leur faut une famille cohérente. **Recherche faite le 09/10** (API publique du Creator Store, détail dans SOURCING_C.md) : un seul crabe est correct ; les étoiles de mer sont réalistes, pas stylisées ; il n'y a qu'une tortue stylisée correcte, mais c'est une tortue de terre, donc à adapter. La génération IA reste à prouver.

**Décision de D (09/10)** : pas de modéliste avant le test fermé (~20–23/10). La Phase 1 se fait avec un prototype : génération + Creator Store. Le modéliste sera décidé selon les chiffres du test. Mon avis reste le même : les créatures finales passeront par un modéliste ou par un pack cohérent.
- Règle : un seul style par lagon. Si le crabe vient du Store et l'étoile de la génération, on harmonise les couleurs et le matériau avec le preset §4. Sinon, on génère les deux.

## 2. Règles de modélisation (brief commun, aligné sur le GDD)
- Style : rond, pattes et nageoires épaisses, gros yeux brillants, 2 ou 3 couleurs à plat plus un dégradé doux. Aucun personnage connu, aucun mème.
- **≤ 1 500 triangles** (GDD §11), 1 SurfaceAppearance ou des couleurs de vertex, texture ≤ 512 px.
- Pivot au centre du corps, **face vers -Z** (LookVector), à l'échelle Adult = 1,0.
- Parties séparées si possible : **Body** + **Fin/Tail/Claw** (pour l'animation par CFrame).
- Rangement : `ReplicatedStorage.Assets.Creatures.<CreatureId>`, PrimaryPart `Root` invisible, attributs `CreatureId` et `Rarity`, tout Anchored, 0 script (même convention que `Assets.Items`).
- Stades (arbitrage de D, 09/10) : **un seul modèle, dimensionné à la taille Adult = 1,0**. C'est le client qui applique l'échelle de `Config.Stages` (Baby 0,6 · Juvenile 0,8 · Adult 1 · Giant 1,5, relatives à l'Adult). Avec `Model:ScaleTo`, les Attachments, dont `Saddle`, suivent.

## 3. Fiches créatures
Taille de référence = Adult (1,0). Repères de rareté communs :

| Rareté | Repère visuel |
|---|---|
| Common | aucun effet |
| Uncommon | liseré clair sur le matériau |
| Rare | légère lueur émissive sur les yeux et les nageoires |
| Epic | + traînée de bulles (1 emitter, Rate 4) |
| Legendary | + faisceau de rareté (FX.RarityBeam) au sol + halo doré |

### Phase 1
| Id | Silhouette (lisible de loin) | Adult (L × H) | Mouvement | Rareté |
|---|---|---|---|---|
| **PebbleCrab** | carapace ronde en galet, 2 pinces levées, yeux sur tiges | 2,5 × 1,5 studs | marche de côté en bassin, pinces qui claquent | Common |
| **SandStar** | étoile à 5 bras épais, plate, yeux au centre | 2,5 × 0,6 | rotation lente, bras qui ondulent (roulis léger) | Common |
| **ReefHatchling** (montable) | tortue de mer ronde : carapace large, basse et plate, 4 grandes nageoires, petite tête basse | 7,5 × 2,8 (dos à 2,6) ; voir §3 bis | nage lente, battement ample des nageoires avant | Uncommon (10 % dans Shallows en Phase 1) |

### Phase 2+ (GDD §4.2, emplacements)
| Id | Silhouette | Adult (L) | Rareté |
|---|---|---|---|
| BubblePuffer | boule, épines douces, petites nageoires | 2 | Uncommon |
| LanternSeahorse | « S » vertical, lanterne émissive sur la tête | 2,5 (H) | Rare |
| CoralRay (montable) | disque plat, ailes, queue fine, motifs corail | 8 d'envergure | Rare |
| InkOctopus | tête ronde, 8 bras courts enroulés | 3 | Epic |
| MoonJelly | cloche translucide (Glass) + filaments | 3 (H) | Epic |
| StarWhaleCalf (montable) | baleineau rond, taches d'étoiles émissives | 9 | Legendary |
| AbyssSerpent (montable) | serpent à crête, segments | 10 | Legendary |
| Léviathan (décor) | serpent géant au large, modèle unique | ×10 | — |

### 3 bis. Monture (Reef Hatchling, puis Coral Ray, Star Whale Calf, Abyss Serpent) : spécification pour A et B
- **Attachment `Saddle`** dans `Root`, au centre du dos, à la surface. Orientation : son axe avant = l'avant du modèle (-Z). A y soude le Seat ou le personnage.
- **Taille** : seuls les stades Adult et Giant sont montables. Un avatar R15 mesure environ 5 studs et assis, ses jambes s'écartent d'environ 2 studs.
  - Adult (1,0) : dos plat d'au moins **3 studs de large × 4 de long**, surface du dos à **2,5–3 studs** du sol. Longueur totale 7–8 studs.
  - Giant (×1,5, appliqué par le client) : dos à environ 4 studs, longueur 11 environ ; `Saddle` suit l'échelle.
  - Les stades Baby et Juvenile ne se montent pas : rien à prévoir.
- Pas de pièce plus haute que le dos devant la selle (une tête basse, pas de crête), pour que la caméra ne soit pas bouchée.
- Collision : `CanCollide = false` sur toutes les parties visibles ; A gère une hitbox simple sur `Root`.
- **Posture du joueur** : assis, avec l'animation Sit par défaut de Roblox, sur `Saddle`.
- **Pose de surf (Giant, GDD §4.6)** :
  - Créature : tangage de 15° vers l'avant, roulis ±8° qui oscille (1,5 s), nageoires avant écartées à 35° et figées.
  - Joueur : debout sur `SurfStand`, un 2ᵉ Attachment du `Root` placé 0,3 stud au-dessus de `Saddle`. Pose « surfeur » : pieds écartés, genoux fléchis à 30°, bras ouverts.
  - La pose du joueur demande une animation : à faire lundi dans l'éditeur d'animation de Studio, ou à défaut en réglant les articulations côté client (B).
  - Lisibilité sous la vague : la Giant reste **au-dessus de la crête** (Y ≥ 22 + moitié de sa hauteur). Sa couleur turquoise clair doit se détacher de l'eau de la vague, d'où un liseré sombre sur la carapace.
- **Effet de surf** (B) : embruns (le ParticleEmitter Spray de la vague, Rate 30) à l'avant de la créature, et le son `surfLoop`.

## 4. Mutations sans nouveau modèle (GDD §4.4)
Les presets sont dans `ReplicatedStorage.Assets.FX.Mutations.<Nom>` (construits par tools/world/build_mutation_fx.luau). Le client les applique au clone.

| Mutation | Couleur | Matériau | Effet | Phase |
|---|---|---|---|---|
| **Golden** | #FFC93C sur Body | `Foil`, Reflectance 0,15 | paillettes dorées (Rate 4, Lifetime 0,8–1,2) | **1** |
| Glow | base #1E2A44, détails #3DF5FF | Neon sur yeux et taches | lueur cyan pulsée ; le GDD prévoit une PointLight : **1 seule par créature, Range ≤ 8, Shadows off, et uniquement à moins de 60 studs de la caméra** (budget DA §4) | 2 |
| Storm | #B48CFF | Glass léger sur les nageoires | petit éclair (ParticleEmitter, burst toutes les 2–4 s) | 2 |
| Rainbow | teinte qui tourne (HSV, client) | inchangé | traînée arc-en-ciel courte | 2 |

Contenu d'un preset (exemple Golden) : un Folder avec les attributs `Color` (Color3), `Material` (string), `Reflectance` (number), `ApplyTo` = "Body" (nom de la partie, ou "*" pour toutes), et un `ParticleEmitter` « Sparkle » à cloner dans `Root`. B l'applique : couleur et matériau sur les parties ciblées, puis clone des emitters.

## 5. Animation côté client (sans rig)
Tout en CFrame local, calculé avec dt, jamais côté serveur (bible §6).
- **Nage en bassin** : orbite elliptique autour du centre du bassin (rayon 1,5–2 studs), 0,4 rad/s ±20 % par créature, le modèle regarde sa tangente. Le crabe marche de côté (on décale le regard de 90°).
- **Flottement** : Y = base + sin(t·1,6 + phase) × 0,25 (0 pour l'étoile, qui reste au fond).
- **Battement** : Fin/Tail/Claw ±15° à 3 Hz si la pièce existe ; sinon roulis du corps ±5°.
- **Au sol, sur la plage** : sautillement + rotation lente (TR_Spin et Bob existants).
- **Capture** : gonfle à 1,3 puis disparaît, avec des particules de la couleur de rareté.
- **Perf** : une seule boucle RenderStepped ; on anime seulement à < 120 studs de la caméra.

## 6. Ordre lundi
1. `tools/world/inspect_world.luau`, puis les scripts du lagon et de la hero shot (tools/world/README.md).
2. Créatures : importer les candidats du Store (SOURCING_C.md §1) et lancer les prompts `generate_mesh` (SOURCING_C.md §2). Juger chacun à côté de la hero shot avec la grille de SOURCING_C.md §3.
3. Ranger les 3 retenus dans `Assets.Creatures` (règles §2 ; `Saddle` et `SurfStand` sur la Reef Hatchling), puis `build_mutation_fx.luau` et `build_royal_fx.luau`.
4. Verdict à D, avec captures.
