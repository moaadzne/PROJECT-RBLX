# Créatures : pipeline art (C, v2 du 09/10/2026)

**docs/DIRECTION_V2.md prime** : de **vrais animaux marins**, reconnaissables, aux proportions et aux couleurs réalistes, avec des formes simplifiées. **Interdits** : gros yeux cartoon, visage « kawaii », expression humaine, couleurs bonbon. La rareté se lit par la **taille**, le **matériau**, la **lumière** et les **particules**, jamais par un air mignon.
Le roster est fixé par E. Phase 1 probable : **crabe fantôme, étoile de mer, tortue imbriquée (montable)**. Les IDs de Config sont à confirmer par E et A **[E]**. Candidats et prompts : docs/SOURCING_C.md.

## 1. Options de production
Aucun prix n'est donné : je n'ai pas de source vérifiée.
| Option | Pour | Limites |
|---|---|---|
| Génération IA dans Studio (`generate_mesh`) | rapide, itérable, sans licence tierce | qualité et réalisme non prouvés ; pas de rig ; seulement sur le Mac de Moaad |
| Creator Store (gratuit) | immédiat ; **en réaliste, on trouve mieux qu'en stylisé** (recherche du 09/10) | budget de triangles souvent dépassé ; provenance à vérifier |
| Pack premium (licence commerciale) | série cohérente | coût, licence, import FBX |
| Modéliste sur mesure | une famille cohérente au niveau visé | délai, coût |

**Avis franc** : pour un **prototype jouable**, le Store suffit (crabe fantôme, tortue et étoile réalistes trouvés, voir SOURCING_C.md). **Pour le niveau « wow » de la version finale**, il faudra un modéliste ou un pack cohérent. **Décision de D** : on le décide après le test fermé (~20–23/10), selon les chiffres.

## 2. Règles de modélisation
- **Réaliste stylisé** : anatomie et couleurs vraies, détails simplifiés, matière PBR crédible (carapace, peau, chitine). Les yeux sont à leur taille réelle.
- **≤ 1 500 triangles**. Au-delà, le modèle est marqué « prototype ». Texture ≤ 512 px (1 024 pour une espèce montable).
- **Dimensionné à la taille Elder = 1,0** (Config.Stages fait foi). Stades : **Juvenile 0,6 · Adult 0,8 · Elder 1,0 · Titan 1,5**. Avec `Model:ScaleTo`, les Attachments suivent. ⚠ Ne plus utiliser Baby/Giant : le serveur (Config.Stages) ne connaît que Juvenile/Adult/Elder/Titan.
- Pivot au centre, **face vers -Z**. Si possible, pièces séparées `Body` + `Fin/Tail/Claw` pour l'animation.
- Rangement : `ReplicatedStorage.Assets.Creatures.<Id>`, PrimaryPart `Root` invisible, attributs `CreatureId` et `Rarity`, tout Anchored, 0 script.
- **Mutations et SurfaceAppearance** : `World.lua` change `Color` et `Material`. Une SurfaceAppearance masque ces changements. Pour une créature qui a une SurfaceAppearance, il faut donc soit teinter `SurfaceAppearance.Color` (à tester lundi), soit retirer la SurfaceAppearance pendant la mutation.

## 3. Fiches
### Repères de rareté (sans rien de mignon)
| Rareté | Taille (× Adult) | Matériau et lumière | Particules |
|---|---|---|---|
| Common | ×1 | naturel | aucune |
| Uncommon | ×1,05 | reflet humide plus marqué | aucune |
| Rare | ×1,1 | légère irisation sur la carapace | quelques bulles fines |
| Epic | ×1,15 | iridescence nette | bulles et sillage |
| Legendary | ×1,2 | reflets profonds | faisceau de rareté au sol, sillage lumineux |
La couleur de rareté (gris, vert, bleu, violet, or) vit dans l'interface : billboard, icône et nom. Elle n'est **jamais peinte sur l'animal**.

### Phase 1 (roster probable, à confirmer par E)
| Id proposé | Animal | Silhouette lisible de loin | Adult (L × H) | Couleurs réelles | Mouvement |
|---|---|---|---|---|---|
| **GhostCrab** | crabe fantôme (*Ocypode*) | carapace carrée, **longs pédoncules oculaires dressés**, une pince plus grosse, pattes fines | 2,5 × 1,2 | sable pâle, beige et gris, pointes plus claires | course de côté très rapide, arrêts nets, s'enterre à moitié au repos |
| **CushionStar** | étoile coussin (*Culcita novaeguineae*, **pas** l'étoile à boutons) | 5 bras épais et mous, très dissymétrique, **bord granuleux** | 2,5 × 0,6 | brun-roux, crème sur la face supérieure, sans bouton central | quasi immobile, bras qui ondulent lentement |
| **HawksbillTurtle** (montable) | tortue imbriquée | carapace aux **écailles imbriquées**, **bec crochu**, grandes nageoires avant | 7,5 × 2,8, dos à 2,6 | écaille ambre, brun et or ; peau grise et beige | nage ample et lente, nageoires avant qui battent en « vol » |

### Phase 2+ (exemples de DIRECTION_V2, E décide)
raie léopard · poulpe · méduse lune · raie manta (montable) · requin-baleine (légendaire, montable). Même gabarit : vrai animal, rareté par la taille, le matériau, la lumière et les particules.

### 3 bis. Monture (tortue imbriquée, puis raie manta, requin-baleine) : spécification pour A et B
- **Attachment `Saddle`** dans `Root`, au centre de la carapace, à sa surface. Son axe avant est -Z.
- **Attachment `SurfStand`**, 0,3 stud au-dessus de `Saddle` : le joueur s'y tient debout pendant le surf.
- **Taille Adult** : dos d'au moins 3 × 4 studs, à 2,5–3 studs du sol, longueur totale 7–8. La Giant (×1,5, appliquée par le client) a un dos vers 4 studs et mesure environ 11 de long.
- Pas de pièce plus haute que la carapace devant la selle : la tête reste basse, la caméra n'est pas bouchée.
- `CanCollide = false` sur les parties visibles ; A gère la hitbox sur `Root`.
- **Posture du joueur** : assis (animation Sit de Roblox) sur `Saddle`.
- **Surf de la Giant (GDD §4.6)** :
  - la tortue a un tangage de 15° vers l'avant, un roulis de ±8° (1,5 s) et les nageoires avant écartées à 35° ;
  - le joueur est debout sur `SurfStand`, pieds écartés, genoux fléchis à 30°, bras ouverts ;
  - la pose du joueur est à animer lundi dans l'éditeur de Studio, sinon B règle les articulations côté client ;
  - lisibilité : la carapace sombre se détache de la crête blanche, et la Giant reste au-dessus de la crête (Y ≥ 22 + moitié de sa hauteur).
- Effet de surf (B) : embruns de la vague à l'avant, son `surfLoop`.

## 4. Mutations crédibles (sans nouveau modèle)
Presets : `Assets.FX.Mutations.<Nom>`, construits par `tools/world/build_mutation_fx.luau`. Le contrat d'attributs est en tête du script.
| Mutation | Lecture | Preset | Phase |
|---|---|---|---|
| **Golden** | métal et nacre | Foil #D9A93F, Reflectance 0,3, reflets nacrés lents (`Sheen`) | **1** |
| Night | bioluminescence | peau #14222E, plancton cyan #3DF5FF qui dérive (`Plankton`), PointLight `Glow` qui respire (Pulse 2,5 s ; 1 lumière par créature, Range 8, sans ombre) | 2 |
| Storm | arcs électriques, peau sombre | Slate #2A2E38, étincelles (`Sparks`), Beam `Arc` repositionné toutes les 0,25 s | 2 |
| Rainbow | irisation de nacre | Foil #E8E2F0, Reflectance 0,35, teinte qui tourne lentement (HueCycle 6 s, saturation 0,3) | 2 |

## 5. Animation côté client (sans rig, réaliste)
Mouvements calculés avec dt, jamais côté serveur. Animations courtes et sèches, comme le veut la direction v2.
- **Crabe fantôme** : sprints de côté de 0,3 à 0,6 s avec des arrêts nets ; pédoncules oculaires qui pivotent ; au repos, à moitié enfoncé dans le sable.
- **Étoile de mer** : posée au fond de la cuvette, rotation de quelques degrés par minute, ondulation des bras (roulis ±3°).
- **Tortue imbriquée** : nage elliptique lente dans la cuvette, battement des nageoires avant à 0,6 Hz, montée pour respirer de temps en temps.
- **Capture** : la créature est soulevée en 0,15 s, avec des gouttes d'eau et du sable (particules de la couleur de rareté **en accent seulement**).
- **Perf** : une seule boucle RenderStepped ; animation seulement à moins de 120 studs de la caméra.

## 6. Ordre lundi
1. `tools/world/inspect_world.luau`, puis le lagon, la vague et la hero shot (tools/world/README.md).
2. Créatures : importer les candidats réalistes (SOURCING_C.md §1), lancer les prompts `generate_mesh` (§2), juger chacune à côté de la hero shot avec la grille §3 et le test « wow mais Roblox ».
3. Ranger les 3 retenues dans `Assets.Creatures` (règles §2 ; `Saddle` et `SurfStand` sur la tortue), puis `build_mutation_fx.luau` et `build_royal_fx.luau`.
4. Verdict à D, avec captures.
