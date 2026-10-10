# MÉTÉO JOUR/NUIT — BASE PHASE 1 (T, 10/10/2026)

> **Phase 1** : cycle visuel uniquement (Lighting presets). Gameplay (spawn nuit, visibilité réduite) = Phase 2+.
> **Style** : réaliste stylisé, couchant permanent (DIRECTION_V2). Pas de nuit complète en P1 — juste un cycle d'ambiance.
> **Référence** : DA_MONDE.md §4, DIRECTION_V2.md.

---

## 1. CYCLE

| Paramètre | Valeur |
|-----------|--------|
| **Durée cycle** | 20 minutes réelles = 24h jeu |
| **Phases** | Jour (7h-18h), Crépuscule (18h-20h), Nuit (20h-5h), Aube (5h-7h) |
| **Impact P1** | Visuel seulement (Lighting presets). Gameplay = P2+. |
| **Référence** | `Lighting.ClockTime` piloté serveur → RemoteEvent `weatherUpdate` |

```
07:00 ─────── Jour ─────── 18:00
                           │
18:00 ── Crépuscule ── 20:00
                           │
20:00 ─────── Nuit ─────── 05:00
                           │
05:00 ───── Aube ─────── 07:00
```

---

## 2. PHASES ET LIGHTING PRESETS

### 2.1. Jour (7h-18h)
| Paramètre | Valeur |
|-----------|--------|
| `ClockTime` | 7.0 → 18.0 |
| `Technology` | `Future` |
| `GlobalShadows` | true |
| `ShadowSoftness` | 0.5 |
| `Brightness` | 2.5 |
| `ColorCorrection_Saturation` | +0.05 |
| `ColorCorrection_Contrast` | +0.08 |
| `Atmosphere_Density` | 0.25 |
| `Atmosphere_Haze` | 1.0 |
| `Atmosphere_Color` | #F2A35E (couchant chaud) |
| `Atmosphere_Decay` | #13707A (turquoise) |

### 2.2. Crépuscule (18h-20h)
| Paramètre | Valeur |
|-----------|--------|
| `ClockTime` | 18.0 → 20.0 |
| `GlobalShadows` | true |
| `ShadowSoftness` | 0.3 |
| `Brightness` | 1.8 |
| `ColorCorrection_Saturation` | +0.10 |
| `ColorCorrection_Contrast` | +0.12 |
| `ColorCorrection_TintColor` | #F2A35E (chaud) |
| `Atmosphere_Density` | 0.30 |
| `Atmosphere_Haze` | 1.3 |
| `Atmosphere_Color` | #F2A35E |
| `Atmosphere_Decay` | #0D3B4C (océan profond) |

### 2.3. Nuit (20h-5h)
| Paramètre | Valeur |
|-----------|--------|
| `ClockTime` | 20.5 |
| `GlobalShadows` | true |
| `ShadowSoftness` | 0.2 |
| `Brightness` | 0.8 |
| `ColorCorrection_Saturation` | -0.05 |
| `ColorCorrection_Contrast` | +0.15 |
| `ColorCorrection_TintColor` | #1A2436 (bleu nuit) |
| `Atmosphere_Density` | 0.35 |
| `Atmosphere_Haze` | 1.5 |
| `Atmosphere_Color` | #0D1B2A |
| `Atmosphere_Decay` | #0A0F1A |
| **Bioluminescence** | Créatures Night : émission #00FF88 (Phase 2+) |

### 2.4. Aube (5h-7h)
| Paramètre | Valeur |
|-----------|--------|
| `ClockTime` | 5.0 → 7.0 |
| `GlobalShadows` | true |
| `ShadowSoftness` | 0.6 |
| `Brightness` | 2.0 |
| `ColorCorrection_Saturation` | +0.02 |
| `ColorCorrection_Contrast` | +0.05 |
| `ColorCorrection_TintColor` | #FFE4C4 (doré) |
| `Atmosphere_Density` | 0.28 |
| `Atmosphere_Haze` | 1.1 |
| `Atmosphere_Color` | #FFE4C4 |
| `Atmosphere_Decay` | #F2A35E |

---

## 3. SERVEUR (A) — SPECS

### 3.1. Pilotage ClockTime
```lua
-- Dans WeatherService.lua
local CYCLE_DURATION = 20 * 60  -- 20 minutes
local HOURS_PER_SECOND = 24 / CYCLE_DURATION

local function Tick()
    local now = os.clock()
    local elapsed = (now - startTime) % CYCLE_DURATION
    local gameHour = (elapsed / CYCLE_DURATION) * 24
    
    -- Mettre à jour Lighting
    game.Lighting.ClockTime = gameHour
    
    -- Notifier clients (pour animations locales)
    RemoteEvent:FireAllClients("weatherUpdate", {
        gameHour = gameHour,
        phase = GetPhase(gameHour)
    })
end

RunService.Heartbeat:Connect(function(dt)
    accumulated = accumulated + dt
    if accumulated >= 1.0 then  -- 1×/seconde
        accumulated = 0
        Tick()
    end
end)
```

### 3.2. Phase detection
```lua
local function GetPhase(gameHour)
    if gameHour >= 7 and gameHour < 18 then
        return "Day"
    elseif gameHour >= 18 and gameHour < 20 then
        return "Dusk"
    elseif gameHour >= 20 or gameHour < 5 then
        return "Night"
    else
        return "Dawn"
    end
end
```

---

## 4. CLIENT (B) — SPECS

### 4.1. Réception
```lua
-- Dans WeatherClient.lua
RemoteEvent.OnClientEvent:Connect(function(gameHour, phase)
    local preset = WeatherPresets[phase]
    if preset then
        ApplyLighting(preset)
        UpdateAmbience(phase)
    end
end)
```

### 4.2. Transition douce
- Tween Lighting sur 2 secondes entre phases
- Pas de changement brusque

---

## 5. VISUEL (C) — SPECS

### 5.1. Assets Lighting
| Asset | Jour | Crépuscule | Nuit | Aube |
|-------|------|------------|------|------|
| `WeatherDay` | ✅ | — | — | — |
| `WeatherDusk` | — | ✅ | — | — |
| `WeatherNight` | — | — | ✅ | — |
| `WeatherDawn` | — | — | — | ✅ |

### 5.2. Emplacement
```
ReplicatedStorage.Assets.FX.WeatherPresets.Day
ReplicatedStorage.Assets.FX.WeatherPresets.Dusk
ReplicatedStorage.Assets.FX.WeatherPresets.Night
ReplicatedStorage.Assets.FX.WeatherPresets.Dawn
```

---

## 6. CONFIG (A) — VALEURS

```lua
-- Dans Config.lua
Weather = {
    CycleDuration = 20 * 60,  -- secondes
    StartTime = os.clock(),
    Phases = {
        Day = { start = 7, finish = 18 },
        Dusk = { start = 18, finish = 20 },
        Night = { start = 20, finish = 5 },
        Dawn = { start = 5, finish = 7 }
    },
    TransitionDuration = 2  -- secondes
}
```

---

## 7. INTÉGRATION CONTRAT v2.1

| Remote | Usage |
|--------|-------|
| `weatherUpdate` (gameHour, phase) | Sync serveur → client |

**Pas de nouveau remote** — réutilise `RemoteEvent` existant.

---

## 8. HORS PHASE 1 (P2+)

| Feature | Description |
|---------|-------------|
| Gameplay nuit | Spawn créatures nocturnes, visibilité réduite |
| Météo dynamique | Pluie, brouillard, neige impact spawn/visibilité/vitesse |
| Événements | Orages, éclairs, aurores boréales |
| Classes | Créatures diurnes vs nocturnes |

---

## 9. TESTS (lundi 12/10, Studio)

| # | Test | Critère |
|---|------|---------|
| 1 | Cycle 20 min | ClockTime avance correctement |
| 2 | Phase detection | Day/Dusk/Night/Dawn corrects |
| 3 | Transition | Tween doux, pas de saut |
| 4 | Performance | Pas de drop FPS pendant transition |
| 5 | Mobile | Presets légers, 60 FPS maintenu |

---

## 10. RÉFÉRENCES

- `DA_MONDE.md` §4 — presets lumière par marée
- `DIRECTION_V2.md` — style console, couchant
- `STREAMING_SPECS_P1.md` — budgets mobile

---

**Validé par D** : 10/10/2026
**Prochaine étape** : A intègre lundi 12/10.