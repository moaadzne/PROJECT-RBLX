# EXTRÊME TIDE — SYSTÈME COMPLET PHASE 1 (T, 10/10/2026)

> **Concept** : ~1×/h, la mer se retire plus loin et révèle le récif (Sud), avec des créatures rares (1 Golden garantie) pendant 25 secondes. Signes sans texte : mouettes, mer qui recule, grondement grave, empreinte de l'épave qui pulse.
> **Phase 1 seulement** : pas de gameplay nuit, pas d'échange, pas de Deep Dive. Tout ça = semaine 2+.
> **Référence** : décision D 09/10, GDD §6 bis, TABLEAU.md P1-37.

---

## 1. CYCLE ET TIMING

| Paramètre | Valeur |
|-----------|--------|
| **Cycle** | 3600 secondes (1h réel) |
| **Déclenchement** | `tick % 58 == 29` → toutes les 58 minutes à 29 minutes après l'heure |
| **Condition** | Pendant le calme seulement (pas de vague active) |
| **Durée** | 25 secondes (émergence récif) |
| **Fréquence max** | 1×/h (jamais 2× de suite) |

```
00:29 — Déclenchement
00:29 → 00:32 — Signes : mouettes, mer recule, grondement
00:32 → 00:34 — Récif émergé, spawns créatures
00:34 → 00:54 — Fenêtre joueur (25s)
00:54 → 00:57 — Nettoyage, eau remonte
00:57 — Fin, retour la normale
```

---

## 2. SERVEUR (A) — SPECS

### 2.1. Déclenchement
```lua
-- Dans Net.lua ou service dédié
local CYCLE = 3600
local OFFSET = 29 * 60  -- 29 minutes
local DURATION = 25

function ExtremeTideService:Trigger()
    local now = os.clock()
    if self.lastTrigger and (now - self.lastTrigger) < CYCLE then return end
    
    -- Vérifier pas de vague active
    if Net:GetWave() ~= WaveState.Calm then return end
    
    self.lastTrigger = now
    self.endsAt = now + DURATION
    
    -- Notifier client
    NotifyAll("extremeTide", { startsAt = now, endsAt = self.endsAt })
end
```

### 2.2. Spawn créatures
```lua
function ExtremeTideService:SpawnReefCreatures()
    local REEF_CENTER = Vector3.new(0, 2, 335)
    local RADIUS = 25
    local SPAWN_COUNT = 6
    local GOLDEN_GUARANTEED = 1
    
    for i = 1, SPAWN_COUNT do
        local offset = Vector3.new(
            math.random(-RADIUS, RADIUS),
            0,
            math.random(-RADIUS, RADIUS)
        )
        local pos = REEF_CENTER + offset
        
        local creatureType
        if i <= GOLDEN_GUARANTEED then
            creatureType = "GoldenHawksbill"  -- Garantie
        else
            local roll = math.random(100)
            creatureType = roll <= 70 and "Hawksbill" or "Lionfish"
        end
        
        CreatureService:Spawn(creatureType, pos, { source = "extremeTide" })
    end
end
```

### 2.3. Nettoyage
```lua
function ExtremeTideService:Cleanup()
    local reefCreatures = CreatureService:GetBySource("extremeTide")
    for _, creature in ipairs(reefCreatures) do
        creature:Destroy()
    end
    NotifyAll("extremeTideEnd", {})
end
```

---

## 3. CLIENT (B) — SPECS

### 3.1. Signes sans texte (25-30s avant)
| Signe | Visuel | Son |
|-------|--------|-----|
| Mouettes | 5-8 oiseaux s'envolent vers le nord | `seagullDistance` (lointain) |
| Mer recule | Eau baisse progressivement (tween Y: 0 → -3) | `wavesRecede` (ressac inversé) |
| Grondement | — | `deepRumble` (grave, montant) |
| Empreinte pulse | Épave : glyphe lumineux pulse 3× | `glyphPulse` (subtil) |

### 3.2. Alerte joueur
| Moment | Notification HUD |
|--------|-------------------|
| Déclenchement | "La mer se retire..." (3s, sans texte, icône vague) |
| Récif émergé | "Le récif est visible — créatures rares !" + flèche Sud |
| Fin | "La mer revient..." (3s) |

### 3.3. Transition eau
```lua
-- Dans Ambience.lua ou module dédié
function ExtremeTideClient:OnStart()
    local tween = TweenService:Create(
        workspace.Map.Ocean,
        TweenInfo.new(3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Position = Vector3.new(0, -3, 0) }
    )
    t:Play()
end

function ExtremeTideClient:OnEnd()
    local tween = TweenService:Create(
        workspace.Map.Ocean,
        TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        { Position = Vector3.new(0, 0, 0) }
    )
    t:Play()
end
```

---

## 4. VISUEL (C) — SPECS

### 4.1. Mouettes
- **Assets** : Mesh oiseau (50 tris), 5-8 instances
- **Animation** : Vol circulaire puis ligne vers le nord (tween CFrame, 5s)
- **Son** : `seagullDistance` (Distance 200, Volume 0.2)

### 4.2. Empreinte épave
- **Position** : (-235, 0.5, 30) devant la coque
- **Apparence** : Part plane 8×8, SurfaceGui invisible, émission cyclique
- **Pulse** : Visible 0.5s toutes les 5s (cycle 3×)
- **Particules** : `GlyphPulseEmitter` (Rate 5, Lifetime 2, Color or #D9A93F)

### 4.3. Récif émergé
- **Avant** : Sous l'eau, coraux invisibles ou silhouettes floues
- **Pendant** : Eau baisse, coraux visibles, sable mouillé brillant
- **Après** : Eau remonte, coraux de nouveau immergés

---

## 5. CONFIG (A) — VALEURS

```lua
-- Dans Config.lua
ExtremeTide = {
    Cycle = 3600,           -- secondes
    Offset = 29 * 60,       -- 29 minutes après l'heure
    Duration = 25,          -- secondes d'émergence
    ReefCenter = Vector3.new(0, 2, 335),
    ReefRadius = 25,
    SpawnCount = 6,
    GoldenGuaranteed = 1,
    SpawnTable = {
        [1] = { type = "Hawksbill", weight = 70 },
        [2] = { type = "Lionfish", weight = 30 },
    }
}
```

---

## 6. INTÉGRATION CONTRAT v2.1

| Remote | Usage |
|--------|-------|
| `Notify("extremeTide", { startsAt, endsAt })` | Déclenchement |
| `Notify("extremeTideEnd", {})` | Fin + nettoyage |

**Pas de nouveau remote** — réutilise `Notify` avec code `extremeTide` / `extremeTideEnd`.

---

## 7. TESTS (lundi 12/10, Studio)

| # | Test | Critère |
|---|------|---------|
| 1 | Déclenchement auto | 1×/h, pas pendant vague |
| 2 | Signes visuels | Mouettes, mer recule, pulse visible |
| 3 | Spawn récif | 6 créatures, 1 Golden garantie |
| 4 | Nettoyage | Créatures supprimées à `endsAt` |
| 5 | Retour eau | Tween inverse, pas de glitch |

---

## 8. HORS PHASE 1 (P2+)

- Impact gameplay (spawn nuit, visibilité réduite)
- Météo dynamique (pluie, brouillard)
- Événements spéciaux (rogue wave, phénomène fantôme)

---

**Validé par D** : 10/10/2026
**Prochaine étape** : A intègre lundi 12/10.