# Test Plan — Phase 5 : Endgame & Polish (Semaines 11-12) — LANCEMENT

**Responsable QA : M**
**Objectif : lancement Semaine 12 avec zéro friction.**

---

## 1. Charge & Stabilité

| Test | Joueurs | Durée | Critère PASS |
|---|---|---|---|
| Stress initial | 100 | 30 min | 0 crash |
| Stress moyen | 250 | 1 h | < 0.5 % disconnect |
| **Stress final** | **500** | **2 h** | **< 1 % disconnect, 0 crash** |
| World Boss | 20 simultanés | 1 combat | Phases + enrage stables |
| Raid | 20 simultanés | 1 raid | 0 desync, loot correct |
| Économie | 50 traders | 2 h | 0 exploit, inflation < 5 % |

---

## 2. Régression complète

| # | Vérification | PASS |
|---|---|---|
| 2.1 | Phases 1, 2, 3, 4 toutes PASS | ☐ |
| 2.2 | Aucune régression fonctionnelle | ☐ |
| 2.3 | Performance régression globale < 3 % | ☐ |
| 2.4 | 0 erreur / 0 warning / 0 exception | ☐ |

---

## 3. Lancement

| # | Vérification | PASS |
|---|---|---|
| 3.1 | Page du jeu : titre « Ride the Tsunami: Steal & Ride », miniatures, icône | ☐ |
| 3.2 | Description + tags + genre corrects | ☐ |
| 3.3 | Tous les pass/produits ont les vrais ids Creator Hub | ☐ |
| 3.4 | Game Settings : Avatar R15, Min = Max | ☐ |
| 3.5 | Lighting Future validé sur capture | ☐ |
| 3.6 | Sauvegarde `Save to Roblox` effectuée | ☐ |
| 3.7 | Aucune feature derrière flag « off » qui devrait être on | ☐ |
| 3.8 | Monitoring dashboards live | ☐ |

---

## 4. Rollback / Déploiement

| # | Vérification | PASS |
|---|---|---|
| 4.1 | Git tag de lancement créé | ☐ |
| 4.2 | Procédure rollback < 5 min testée | ☐ |
| 4.3 | Feature flags prêts (taux 1 % → 100 %) | ☐ |
| 4.4 | Hotfix SLA : P0 30 min / P1 2 h | ☐ |
| 4.5 | Runbook incidents lu par l'équipe | ☐ |

---

## 5. Post-lancement

| # | Vérification | PASS |
|---|---|---|
| 5.1 | On-call rotation 21 agents en place | ☐ |
| 5.2 | Création du canal incident partagé | ☐ |
| 5.3 | A/B test framework actif (prix, drop rates, XP) | ☐ |
| 5.4 | Pipeline « weekly update » prêt (hebdomadaire) | ☐ |

---

## Métriques cibles au lancement

| Métrique | Cible |
|---|---|
| Uptime | 99,9 % |
| Crash rate | < 0,1 % |
| Disconnect rate | < 1 % |
| P95 latency | < 100 ms |
| FPS | Mobile 30+ / PC 60+ @ 500 joueurs |
| P0/P1 ouverts | **0** |
| P2/P3 documentés | < 10 |
| Inflation économie | < 5 %/semaine |
| RMT | < 0,01 % des transactions |
| PolicyService | appelé avant **chaque** achat |
| Probabilités affichées | **avant** chaque achat aléatoire |

---

## Go / No-Go

- [ ] **Tous** les points ci-dessus PASS
- [ ] Go décidé par **D** (feu vert formel)
- [ ] Moaad clique « Publish »

---

*Checklist vivante — cocher en temps réel. Une case non cochée = NO-GO.*
