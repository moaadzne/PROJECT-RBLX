# POI SPECS PHASE 1 — WORLD & EXPLORATION (T, 10/10/2026)

> **Contexte** : Phase 1 = île 600×600 intermédiaire. Pas de 800×800, pas de jungle, pas de grotte. 3 POI seulement.
> **Référence** : contrat v2.1 (A), DA_MONDE.md (C), DIRECTION_V2.md, TABLEAU.md P1-36.
> **Décision D 09/10** : île ouverte version intermédiaire au lancement. 800×800 / jungle / grotte / carte = Phase 2+.

---

## 1. BELVÉDÈRE (falaise Est)

| Attribut | Valeur |
|----------|--------|
| **Position** | Centre (220, 0, -40), rayon 25 |
| **Altitude** | Plateau Y=40, falaise jusqu'à Y=60 |
| **Rôle gameplay** | Safe spot pendant toutes les vagues, meilleur point de vue vague, spot vidéo naturel |
| **Streaming mode** | `Atomic` (chunk Est) |
| **Collision** | MeshPart ancrée `BelvedereCliff` (invisible), `BelvedereFloor` (visible) |
| **Assets requis** | Mesh falaise volcanique (LOD0/1/2), arche de corail, 2 palmiers, banc bois flotté |
| **LOD** | Near <80: LOD0 (détail complet), Mid 80-160: LOD1 (simplifié), Far >160: LOD2 (imposter) |

### Specs techniques
- **Falaise** : `Part` size (30, 40, 60), position (220, 20, -40), ancrée, `CanCollide=true`, `CanQuery=true`
- **Plateau** : `Part` size (30, 2, 30), position (220, 41, -40), surface marchable
- **Arche corail** : MeshPart organique, Y=42, hauteur 8, non marchable ( décor)
- **Trigger zone** : `BelvedereZone` (Part invisible, 30×4×30) — détecte joueur sur plateau → safe spot (serveur lit position)

### Intégration contrat
- **A** : `BelvedereZone` lu par serveur → exclut joueurs dessus de la détection vague (safe spot)
- **B** : HUD indique "Belvédère — safe spot" quand joueur entre dans la zone
- **C** : Construction visuelle + assets

---

## 2. ÉPAVE (Ouest, anneau extérieur)

| Attribut | Valeur |
|----------|--------|
| **Position** | Centre (-240, 0, 30), rayon 30, orientée N-S |
| **Rôle gameplay** | Meilleurs spawns créatures (tier 2-3), gravure lumineuse au sol (indice marée extrême) |
| **Streaming mode** | `Atomic` (chunk Ouest) |
| **Collision** | `WreckHull` (visible, non traversable), `WreckMast` (décor) |
| **Assets requis** | Mesh épave modulaire (coque, mâts, voiles déchirées), particule empreinte pulse |
| **LOD** | Near <80: coque détaillée + mâts + voiles, Mid 80-160: coque simplifiée, Far >160: silhouette |

### Specs techniques
- **Coque** : MeshPart `WreckHull`, size (12, 8, 40), position (-240, 4, 30), rotation (0, 15, 5) — wreckage realistic
- **Mast** : 2 mâts MeshPart `WreckMast` (cylindres inclinés), hauteurs 15/20
- **Voiles** : MeshPart `WreckSail` (tissu déchiré), 3 pièces suspendues
- **Empreinte gravure** : `WreckGlyph` (Part plane 8×8, SurfaceGui invisible, position sol devant coque)
  - **Pulse** : Emission cyclique 5s (Visible pendant 0.5s) — synchronisé avec Config.ExtremeTide
  - **Particules** : `GlyphPulseEmitter` (Rate 5, Lifetime 2, Color or #D9A93F)
  - **Son** : `GlyphRumble` (Distance 50, Volume 0.3) pendant pulse

### Intégration contrat
- **A** : Spawn créatures tier 2-3 dans rayon 30 de (-240, 0, 30) — override normal spawn. Empreinte pulse via `ExtremeTideCycle`.
- **B** : HUD indiquer "Épave — spawns améliorés" + notification pulse empreinte
- **C** : Construction visuelle + assets + particules

---

## 3. RÉCIF MARÉE BASSE (Sud, centre)

| Attribut | Valeur |
|----------|--------|
| **Position** | Centre (0, 0, 335), rayon 30 |
| **Rôle gameplay** | Révélé seulement pendant marée extrême (25s), 6 créatures dont 1 Golden garantie |
| **Streaming mode** | `Atomic` (chunk Sud) |
| **Collision** | `ReefFloor` (visible, marchable à marée basse), `ReefCorals` (décor) |
| **Assets requis** | Coraux vivants (désaturés #D9776A, #B8607A), algues, étoiles de mer, sable mouillé |
| **LOD** | Near <80: coraux détaillés + algues, Mid 80-160: coraux simplifiés, Far >160: plat sable |

### Specs techniques
- **Plateau** : `ReefFloor` size (60, 1, 60), position (0, -0.5, 335) — sous eau normale (mer Y=0)
- **Émergence** : Pendant marée extrême, eau baisse à Y=-3 → récif émerge (visuel C: tween eau)
- **Coraux** : 8-12 MeshParts organiques (tailles 2-5 studs), positions aléatoires dans rayon 30
- **Spawn zone** : `ReefSpawnZone` (Part invisible 60×10×60) — serveur spawn 6 créatures à (0, 2, 335) ±25
- **Nettoyage** : À `endsAt`, serveur supprime créatures récif, eau remonte (tween inverse)

### Intégration contrat
- **A** : `ExtremeTideService` spawn 6 créatures (70% Hawksbill, 30% Lionfish), **1 Golden garantie** (reprise logique IntroService). Nettoyage à `endsAt`.
- **B** : HUD alerte "Récif émergé — créatures rares !" + flèche direction Sud
- **C** : Construction visuelle + assets + tween eau

---

## 4. POSITIONS DÉTAILLÉES (repère monde 600×600)

```
Z = -300 ┌─────────────────────────────────────┐
         │           N (mer)                   │
         │                                      │
  Z = 0  │  Épave (-240, 30)     Belvédère (220, -40) │
         │         ← 460 studs →                 │
         │                                      │
  Z = 300 │           S (Récif 0, 335)           │
         └─────────────────────────────────────┘
        X = -300                 X = +300
```

| POI | Centre | Rayon | Altitude | Chunk |
|-----|--------|-------|----------|-------|
| Belvédère | (220, -40) | 25 | Y=40-60 | Est |
| Épave | (-240, 30) | 30 | Y=0-8 | Ouest |
| Récif | (0, 335) | 30 | Y=-1 (émergé) | Sud |

---

## 5. ASSETS REQUIS (ReplicatedStorage.Assets)

| Asset | Type | Taille cible | LOD |
|-------|------|-------------|-----|
| `BelvedereCliff` | MeshPart | ~800 tris | 3 niveaux |
| `BelvedereArch` | MeshPart | ~400 tris | 1 niveau |
| `WreckHull` | MeshPart | ~1200 tris | 3 niveaux |
| `WreckMast` | MeshPart | ~300 tris | 1 niveau |
| `WreckSail` | MeshPart | ~200 tris | 1 niveau |
| `ReefCoral_01..04` | MeshPart | ~200 tris chacun | 1 niveau |
| `GlyphPulseEmitter` | ParticleEmitter | — | — |
| `GlyphRumble` | Sound | — | — |

**Source** : Creator Store + generate_mesh (C). **Budget** : ≤1500 tris par créature, ≤3000 parts visibles.

---

## 6. PLAN DE BUILD (C, lundi 12/10)

1. **Créer assets** dans ReplicatedStorage.Assets (ou pointer vers _DecorLib)
2. **Construire POI** dans Workspace.Map via script `build_poi.luau`
3. **Placer collisions** et zones (serveur lit positions, pas noms)
4. **Tester LOD** et streaming radius 300 (mobile) / 500 (PC)
5. **Intégrer avec A** : override spawn épave, safe spot belvédère, spawn récif marée extrême
6. **Intégrer avec B** : HUD zones + alertes

---

## 7. LIVRABLES T

- [x] `docs/POI_SPECS_P1.md` — ce document
- [ ] `docs/EXTREME_TIDE_P1.md` — timeline + specs serveur/client
- [ ] `docs/STREAMING_SPECS_P1.md` — config + chunks + LOD + budgets
- [ ] `docs/WEATHER_SPECS_P1.md` — cycle jour/nuit + presets

---

## 8. HORS PHASE 1 (noté pour P2+)

- Archipel 5+ îles, navigation monture
- Jungle, grotte, carte HD
- Classes/progression, boss/raids
- Secrets Phase 2 (grotte reflux, rogue wave, espèce fantôme, gravures lore)
- Donjons instanciés (grotte, épave intérieure)

---

**Validé par D** : 10/10/2026
**Prochaine étape** : C implémente lundi 12/10 en Studio.