# QA Infrastructure — Tide Rush MMORPG

**Responsable : M (QA Infrastructure Lead)**
**Mis à jour : 2026-10-10**

Mission : zéro régression, qualité continue, lancement Semaine 12 sans friction.
Règle d'or : **échec sur L'UN (mobile OU PC) = rollback complet.**

---

## 1. Test Framework

### Stack
- **Unit / Integration** : TestEZ (Roblox) + mocks Net.lua / DataStore / Remotes
- **E2E** : Studio Play Solo + Play with Clients (2+ sessions simultanées)
- **Cross-platform** : Mobile (iPhone 12 / Android mid-2021) + PC (GTX 1060) simultanés

### Structure
```
tests/
├── unit/           # ModuleScripts purs (Config, Stats, math combat, loot tables)
├── integration/    # Services + mocks (Net, DataStore, Shop, Wave)
├── e2e/            # Playtest scripts (cycles vagues, vol, boss, raids)
└── load/           # 500 bots headless (stress serveur unique)
```

### Quality Gates (PR blocked si)
- luau-analyze : **0 warning**
- Couverture tests nouveau code : **≥ 80%**
- Régression performance : **> 5% slowdown = block**
- Cross-platform checklist : **10/10 points PASS**

---

## 2. CI/CD Pipeline

### GitHub Actions (`.github/workflows/qa.yml`)
| Job | Déclencheur | Action |
|---|---|---|
| `lint` | chaque PR | `rojo build` + `luau-analyze` + `selene` |
| `test-unit` | chaque PR | TestEZ run + rapport couverture |
| `test-integration` | merge sur intégration | Mock DataStore + services |
| `perf-baseline` | merge sur intégration | Comparaison FPS/mémoire vs baseline |
| `sourcemap-check` | merge sur intégration | `rojo sourcemap` vs Studio attendu |

### Feature Flags (déploiement progressif)
- Tous nouveaux systèmes derrière flag
- Lancement par % joueurs : 1% → 5% → 25% → 100%
- Rollback flag en < 30 s

---

## 3. Performance Baselines

| Plateforme | Cible | Minimum acceptable |
|---|---|---|
| **PC (GTX 1060)** | 60 FPS | 55 FPS |
| **Mobile (iPhone 12)** | 30 FPS | 25 FPS |
| **Mobile (Android mid-2021)** | 30 FPS | 25 FPS |
| **Mémoire mobile** | < 500 Mo | < 600 Mo |
| **Mémoire PC** | < 800 Mo | < 1 Go |
| **Latency P95** | < 80 ms | < 100 ms |
| **Streaming pop-in** | < 16 studs/s | < 32 studs/s |

---

## 4. Cross-Platform Checklist (10 points — à CHAQUE sync)

| # | Point | Critère PASS |
|---|---|---|
| 1 | Mouvement fluide | Joystick responsive / WASD+Shift, pas de rubber-band |
| 2 | Caméra | Touch drag+pinch / clic droit+molette, pas d'inversion |
| 3 | Vol mobile↔PC | StartSteal, ChoosePick, Mount, LockLagoon identiques |
| 4 | Boutique | Prix, PolicyService, ProcessReceipt, 0 erreur |
| 5 | HUD lisible | Mobile bas (safe area ≥44px) / PC latéral (hover) |
| 6 | Trading/Vol protections | Newbie, revanche, cap, lock actifs des 2 côtés |
| 7 | Marée Royale | RoyalBoard global reçu des 2 côtés |
| 8 | Daily Rewards | Synchro instantanée cross-device |
| 9 | Console | 0 erreur / 0 warning (mobile DevConsole + PC Output) |
| 10 | Performance | Mobile ≥30 FPS / PC ≥60 FPS |

---

## 5. Load / Stress Tests (Phase 5)

| Test | Joueurs | Durée | Critère PASS |
|---|---|---|---|
| Stress initial | 100 | 30 min | 0 crash |
| Stress moyen | 250 | 1 h | < 0.5% disconnect |
| Stress final | 500 | 2 h | < 1% disconnect, 0 crash |
| World Boss | 20 simultané | 1 combat | Phases + enrage stables |
| Raid | 20 simultanés | 1 raid | 0 desync, loot correct |
| Économie | 50 traders | 2 h | 0 exploit, inflation < 5% |

---

## 6. Incident Response (post-lancement)

| Sévérité | Définition | SLA | Action |
|---|---|---|---|
| **P0** | Crash / économie cassée | 30 min | Rollback auto + incident channel |
| **P1** | Gameplay bloquant | 2 h | Hotfix + déployer progressif |
| **P2** | Bug majeur non bloquant | next deploy | Ticket + fix planifié |
| **P3** | Bug mineur / cosmétique | backlog | Ticket |

---

## 7. Métriques Cibles Semaine 12

- **Stabilité** : 99.9% uptime, < 0.1% crash rate, < 1% disconnect rate
- **Performance** : P95 latency < 100 ms, Mobile 30+ FPS / PC 60+ FPS @ 500 joueurs
- **Qualité** : 0 P0/P1 ouverts, < 10 P2/P3 documentés
- **Économie** : 0 exploit, inflation < 5%/semaine, RMT < 0.01% transactions
- **Monétisation** : PolicyService appelé AVANT chaque achat, probabilités affichées, Pity 50

---

## 8. Documentation vivante

```
docs/QA/
├── README.md              # ce fichier
├── CHECKLIST_LAUNCH.md    # 20 points (voir INBOX/M.md)
├── CROSS_PLATFORM.md      # 10 points + devices
├── ROLLBACK.md            # 6 scénarios + procédures
├── PERFORMANCE.md         # baselines + outils mesure
├── TEST_PLANS/            # un plan par phase
├── RUNBOOKS/              # procédures incident
└── POSTMORTEMS/           # apprentissage continu
```

---

*Basé sur DECISIONS_MARCHE.md §7-9 (cross-platform, MMORPG, monétisation) + AGENTS.md (protocole async docs/).*
