# Performance Baselines & Outils

**Cible : 60 FPS PC / 30 FPS mobile @ 500 joueurs connectés sur serveur unique.**

---

## Baselines par plateforme

| Métrique | PC (GTX 1060) | Mobile (iPhone 12) | Mobile (Android mid-2021) |
|---|---|---|---|
| **FPS moyen** | ≥ 60 | ≥ 30 | ≥ 30 |
| **FPS minimum** | ≥ 55 | ≥ 25 | ≥ 25 |
| **Frametime P95** | < 16.7 ms | < 33.3 ms | < 33.3 ms |
| **Mémoire** | < 800 Mo | < 500 Mo | < 500 Mo |
| **Limite acceptable** | < 1 Go | < 600 Mo | < 600 Mo |
| **Latency P95** | < 80 ms | < 100 ms | < 100 ms |
| **Streaming pop-in** | < 16 studs/s | < 32 studs/s | < 32 studs/s |

---

## Config.CrossPlatform (source unique)

```lua
Config.CrossPlatform = {
	TouchTargetMin = 44,        -- px (iOS pts / Android dp)
	MobileFPS = 30,
	PCFPS = 60,
	LODDistances = { Near = 80, Mid = 160, Far = 300 },
	MaxParticlesMobile = 50,
	MaxParticlesPC = 200,
	ShadowsMobile = false,
	ShadowsPC = true,
	WaterQualityMobile = 0.5,
	WaterQualityPC = 1.0,
}
```

---

## Réglages qualité (par plateforme)

| Système | Mobile | PC |
|---|---|---|
| **GraphicsQuality** | Auto (3 niveaux : Auto/High/Low) | Auto → High |
| **LOD créatures** | 3 niveaux (near/mid/far), mesh supprimé > 200 studs | 3 niveaux, mesh supprimé > 400 studs |
| **Particules** | max 50 simultanées | max 200 simultanées |
| **Ombres** | ShadowMap désactivé (ou Distance = 100) | ShadowMap activé |
| **Eau** | WaveSize/Transparency réduits (0.5) | WaveSize/Transparency complets (1.0) |
| **Rendu vague** | 15 segments | 30 segments |
| **Streaming** | chunks agressifs | chunks larges |

---

## Détection plateforme

```lua
local UIS = game:GetService("UserInputService")
local Platform = UIS.TouchEnabled and "Mobile"
	or UIS.KeyboardEnabled and "PC"
	or UIS.GamepadEnabled and "Console"
	or "Unknown"
```

---

## Outils de mesure (Studio)

| Outil | Usage | Fréquence |
|---|---|---|
| **Ctrl+Shift+F7 / F8** | MicroProfiler (CPU/GPU) | chaque test perf |
| **Developer Console → Stats** | FPS, mémoire, réseau | chaque test |
| **Network Pane** | bande passante remotes | si lag suspecté |
| **Memory → Take Snapshot** | fuites mémoire | test long (2 h) |

---

## Test 500 joueurs (bots headless)

```
tests/load/
├── spawn_bots.luau       # lance N clients headless
├── scenario_walk.luau    # bots marchent / captnt / volent
├── scenario_wave.luau    # bots survivent à la vague
├── metrics.luau          # collecte FPS/mémoire/erreurs
└── report.luau           # génère rapport comparatif
```

| Test | Joueurs | Durée | Critère PASS |
|---|---|---|---|
| Initial | 100 | 30 min | 0 crash |
| Moyen | 250 | 1 h | < 0.5% disconnect |
| **Final** | **500** | **2 h** | **< 1% disconnect, 0 crash** |
| World Boss | 20 | 1 combat | phases + enrage stables |
| Raid | 20 | 1 raid | 0 desync, loot correct |
| Économie | 50 traders | 2 h | 0 exploit, inflation < 5% |

---

## Règle de régression

> Une baisse de performance **> 5%** entre deux builds sur la même plateforme = **PR bloquée** jusqu'à explication ou fix.
