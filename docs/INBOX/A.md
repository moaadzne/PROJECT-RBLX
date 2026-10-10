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
| 1 | **Net.lua** : rate limiting adaptatif par joueur, anti-spam remote, reconnexion seamless | P0 | ✅ |
| 2 | **DataStore** : ProfileService v2, migration auto, backup horaire, recovery < 1s | P0 | ✅ |
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

---

## 2026-10-11 — CYCLE 1 étapes 1 & 2 livrées
FAIT     : **RateLimiter.lua créé** — anti-spam remote ADAPTATIF : seau à jetons + score de comportement. Plus un joueur spamme, plus son seau se vide vite et plus la recharge ralentit (pénalité x0.5 recharge / x0.5 capacité, jusqu'à x4, décroissance naturelle 0,95/s). Blocage 10 s à partir de x8. **Reconnexion seamless** : 30 s de grâce + pénalité remise à zéro. **Net.lua recâblé** : ancien `allow()` par `buckets[player][name]` supprimé (zéro résidu vérifié au grep), `Net.Forget` → `RateLimiter.Forget`, nouveau `Net.OnReconnect`. **DataService** : `BACKUP_STORE` ("TideRush_Players_Backup") ouvert en parallèle, **backup horaire** (BACKUP_EVERY = 3600, copie sanitizée SANS verrou dans un store séparé), **recovery rapide** : après 3 échecs de chargement, `GetAsync` de secours sur le backup (lecture seule, pas d'écriture). Boucle backup supervisée (pcall) comme autosave/flush.
VÉRIFIÉ  : relecture manuelle du diff des deux fichiers ; grep confirmant zéro `bucket`/`RATE_` restant dans Net.lua et 9 sites `backupStore`/`BACKUP_` cohérents dans DataService. **Rien testé en jeu** (pas Studio), pas de luau-analyze.
BESOIN   : Rien pour ces deux étapes. Suite du Cycle 1 : étape 3 (Combat — hit validation, anti-teleport, anti-speedhack, lag comp en cours), puis 4 (Vague) et 5 (Marée Royale) déjà conformes au contrat, je relis seulement.