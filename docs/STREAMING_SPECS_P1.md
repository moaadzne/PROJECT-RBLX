# STREAMING & PERFORMANCE — PHASE 1 (T, 10/10/2026)

> **Objectif** : 60 FPS sur téléphone moyen, ≤3000 parts visibles, ≤12 sons simultanés.
> **Plateforme cible** : Mobile (iOS/Android) + PC.
> **Référence** : DA_MONDE.md §5, DIRECTION_V2.md.

---

## 1. STREAMING CONFIG

### 1.1. Paramètres Roblox
```lua
-- Dans Studio > Game Settings > StreamingEnabled
StreamingEnabled = true
StreamingTargetRadius = 300  -- Mobile (peut être réduit à 250 si perf)
StreamingMinRadius = 50
```

### 1.2. Mode de streaming
| Objet | Mode | Raison |
|-------|------|--------|
| Créatures | `Atomic` | Toujours visibles, jamais seules |
| Bassins (PedestalN) | `Atomic` | Gameplay critique |
| Barrières | `Atomic` | Gameplay critique |
| Tours | `Atomic` | Safe spots, toujours nécessaires |
| POI (Belvédère, Épave, Récif) | `Atomic` | Contenu principal |
| Végétation, rochers, décor | `NonAtomic` | Peut apparaître/disparaître |
| Eau, ciel, lumière | `Persistent` | Toujours visibles |

### 1.3. Chunking (grille 100×100)
```
600×600 studs = 36 chunks (6×6)

Z = -300 ┌──┬──┬──┬──┬──┬──┐
         │  │  │  │  │  │  │
  Z = 0  ├──┼──┼──┼──┼──┼──┤
         │  │  │C │  │  │  │  C = Crique centrale (persistent)
  Z = 300 ├──┼──┼──┼──┼──┼──┤
         │  │  │  │  │  │  │
         └──┴──┴──┴──┴──┴──┘
        X = -300    X = +300
```

| Zone | Streaming | Rayon |
|------|-----------|-------|
| Crique centrale (Persistent) | Toujours chargé | 70 |
| Anneaux 70-300 (Atomic) | Streaming normal | 100-250 |
| POI (Atomic) | Streaming ciblé | 25-30 |
| Large (NonAtomic) | Peut ne pas charger | >300 |

---

## 2. LOD (Level of Detail)

### 2.1. Niveaux
| Niveau | Distance | Triangles max | Usage |
|--------|----------|---------------|-------|
| Near (LOD0) | <80 studs | 1500 | Détail complet |
| Mid (LOD1) | 80-160 studs | 800 | Simplifié |
| Far (LOD2) | >160 studs | 300 | Silhouette |
| Imposter | >300 studs | 50 | Sprite 2D |

### 2.2. Assets LOD
| Asset | LOD0 | LOD1 | LOD2 | Imposter |
|-------|------|------|------|----------|
| Créature | 1500 tris | 800 tris | 300 tris | Sprite |
| Épave | 1200 tris | 600 tris | 200 tris | — |
| Belvédère | 800 tris | 400 tris | 150 tris | — |
| Corail | 200 tris | 100 tris | 50 tris | — |
| Palmier | 500 tris | 250 tris | 100 tris | — |

---

## 3. BUDGETS MOBILE

### 3.1. Parts visibles
| Poste | Budget |
|-------|--------|
| Parts visibles à l'écran | ≤ 3000 |
| Parts totaux carte | ≤ 8000 |
| Par base (palier 5) | ≤ 150 parts |

### 3.2. Particules
| Poste | Budget |
|-------|--------|
| Émetteurs à l'écran | ≤ 15 |
| Particules/s | ≤ 300 |
| Vague (spécial) | 3 émetteurs |

### 3.3. Lumières
| Poste | Budget |
|-------|--------|
| Lumières dynamiques | ≤ 8 |
| Ombres lumières locales | 0 |
| Créatures royales/Nuit | 1 seule |

### 3.4. Sons
| Poste | Budget |
|-------|--------|
| Sons simultanés | ≤ 12 |
| Musique | 1 |
| Ambiances | 2 |

---

## 4. CROSS-PLATFORM

### 4.1. Segments vague
| Plateforme | Segments | Particules/segment |
|------------|----------|-------------------|
| Mobile | 15 | 50 |
| PC | 30 | 200 |

### 4.2. Ombres
| Plateforme | Ombres |
|------------|--------|
| Mobile | Désactivées |
| PC | Activées (soleil seulement) |

### 4.3. Résolution
| Plateforme | Rendering |
|------------|-----------|
| Mobile | Automatique (adapter à l'écran) |
| PC | 1080p natif |

---

## 5. TEST PLAN (lundi 12/10, Studio)

| # | Test | Critère |
|---|------|---------|
| 1 | StreamingEnabled | Pas de lag téléportation |
| 2 | LOD transition | Pas de pop-in visible |
| 3 | Budget parts | ≤3000 à l'écran |
| 4 | 60 FPS mobile | ≥55 FPS stable |
| 5 | 60 FPS PC | ≥58 FPS stable |
| 6 | Sons simultanés | ≤12, pas de coupure |

### Outils
- **Microprofiler** : `Ctrl+F6` (Studio)
- **Stats** : Game Settings > Stats
- **Test mobile** : Roblox App sur téléphone réel

---

## 6. OPTIMISATIONS

### 6.1.À faire (C)
- [ ] `CastShadow = false` sur petits props
- [ ] `CanCollide/CanQuery/CanTouch = false` sur décor non marchable
- [ ] `ModelStreamingMode = "Atomic"` sur objets critiques
- [ ] Utiliser `CollectionService` pour tags LOD

### 6.2. À éviter
- ❌ Parts > 4 studs non organiques
- ❌ Plastique lisse saturé
- ❌ Textes 3D en police par défaut
- ❌ Lumières dynamiques par cuvette

---

## 7. CONFIG SCRIPT (C)

```lua
-- tools/world/setup_streaming.luau
local StreamingEnabled = true
local StreamingTargetRadius = 300
local StreamingMinRadius = 50

-- Appliquer les paramètres
local studio = game:GetService("Studio")
studio:SetProperty("StreamingEnabled", StreamingEnabled)
studio:SetProperty("StreamingTargetRadius", StreamingTargetRadius)
studio:SetProperty("StreamingMinRadius", StreamingMinRadius)

-- Tags pour LOD
local CollectionService = game:GetService("CollectionService")
CollectionService:AddTag(game.Workspace.Map, "MapRoot")
CollectionService:AddTag(game.Workspace.Map.Plots, "Plots")
CollectionService:AddTag(game.Workspace.Map.Towers, "Towers")

print("Streaming config applied")
```

---

## 8. RÉFÉRENCES

- `DA_MONDE.md` §5 — budgets mobile
- `DIRECTION_V2.md` — style console, performance
- `POI_SPECS_P1.md` — streaming par POI
- `EXTREME_TIDE_P1.md` — particules vague

---

**Validé par D** : 10/10/2026
**Prochaine étape** : C applique lundi 12/10.