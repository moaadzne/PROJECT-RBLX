# File de A — Serveur
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

---

## TÂCHES INFINIES — A (SERVEUR) — TU NE T'ARRÊTES JAMAIS

### RÈGLE : Quand un cycle fini → recommencer au cycle 1 avec améliorations. JAMAIS d'arrêt.

---

## CYCLE 1 — CORE STABILITY (maintenant)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 1 | **Net.lua** : rate limiting adaptatif par joueur, anti-spam remote, reconnexion seamless | P0 | ⬜ |
| 2 | **DataStore** : ProfileService v2, migration auto, backup horaire, recovery < 1s | P0 | ⬜ |
| 3 | **Combat** : hit validation serveur, anti-teleport, anti-speedhack, lag compensation | P0 | ⬜ |
| 4 | **Vague** : 4 directions, hauteur 30, tours 34 safe, P0 corrigé (base*CFrame) | P0 | ⬜ |
| 5 | **Marée Royale** : score global, top 3, créature unique, reset horaire | P0 | ⬜ |

---

## CYCLE 2 — SYSTÈMES PROFONDS (semaine 1)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 6 | **Classes 4** (Gardien/Chasseur/Maître/Tisseur) : stats de base, scaling 1-100 | P1 | ⬜ |
| 7 | **Talents** : 3 arbres/classe, 30 points max, respec coût croissant | P1 | ⬜ |
| 8 | **Gear** : craft, enchant, runes, sets légendaires, durabilité, repair | P1 | ⬜ |
| 9 | **Créatures 50+** : évolution ramifiée, mutations héréditaires, breeding | P1 | ⬜ |
| 10 | **Montures** : vol/nage/terre, arbres progression propres, skins shader | P1 | ⬜ |
| 11 | **Housing/Bases** : construction modulaire, défense, production, Guild Hall | P1 | ⬜ |

---

## CYCLE 3 — ENDGAME & PVP (semaine 2-3)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 12 | **World Boss** : Leviathan/Kraken/Hydre 20j, phases, enrage, loot table | P1 | ⬜ |
| 13 | **Donjons 5j** : 3 diff (N/H/M), mechanics, loot, weekly reset | P1 | ⬜ |
| 14 | **Raids 10/20** : Temple/Abysse/Cathédrale, coordination, enrage timers | P1 | ⬜ |
| 15 | **PvP zones** : îlots contestés, ressources, contrôle territorial guildes | P1 | ⬜ |
| 16 | **Arènes classées** : 1v1/2v2/3v3, saisons, MMR, rewards cosmetics only | P1 | ⬜ |
| 17 | **Guerres guilde** : sièges, objectifs, ressources, cooldown | P1 | ⬜ |

---

## CYCLE 4 — ÉCONOMIE & POLISH (continu)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 18 | **Hôtel ventes** : 5% taxe, filtres, enchères, contrats, history | P2 | ⬜ |
| 19 | **Trading direct** : secure trade window, confirmation, anti-scam | P2 | ⬜ |
| 20 | **ProfileService hot-reload**, zero-downtime deploy, A/B test framework | P2 | ⬜ |
| 21 | **Monitoring** : metrics temps réel, alertes, rollback auto < 30s | P2 | ⬜ |

---

## 2026-10-10 21:00
FAIT      : Tâches infinies A (Serveur) créées dans docs/INBOX/A.md — 4 cycles, 21 tâches, priorisées P0/P1/P2
VÉRIFIÉ   : Cycle 1 = Core Stability (Net.lua, DataStore, Combat, Vague, Marée Royale) ; Cycle 2 = Systèmes Profonds (Classes, Talents, Gear, Créatures 50+, Montures, Housing) ; Cycle 3 = Endgame & PvP (World Boss, Donjons, Raids, PvP zones, Arènes, Guerres guilde) ; Cycle 4 = Économie & Polish (Hôtel ventes, Trading, Hot-reload, Monitoring)
BESOIN    : D — Validation que A démarre Cycle 1 immédiatement ; M — QA alignée sur chaque cycle (checklist 20 points + cross-platform + plan 12 sem)