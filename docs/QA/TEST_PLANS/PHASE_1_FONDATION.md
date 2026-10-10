# Test Plan — Phase 1 : Fondation (Semaines 1-2)

**Référence : DECISIONS_MARCHE.md §9 planning**
**Responsable QA : M**

---

## Objectif

Valider la fondation technique du MMORPG : serveur unique, netcode, DataStore, streaming, combat de base. Aucun contenu de gameplay avancé n'est testé à ce stade.

---

## Prérequis

- [ ] Branche `claude/e-gdd-reef` à jour (git pull)
- [ ] `rojo serve` actif (port 34872)
- [ ] Plugin Rojo 7.5.1 installé
- [ ] Sauvegarde triple effectuée (voir ROLLBACK.md)
- [ ] Devices dispo : iPhone 12, Android mid-2021, PC GTX 1060

---

## 1. Sync Rojo (Setup)

| # | Vérification | PASS |
|---|---|---|
| 1.1 | Liste Rojo = uniquement Shared / ServerScriptService / StarterPlayerScripts (+ optionnels) | ☐ |
| 1.2 | **Aucun** Workspace / Terrain / Lighting / Assets / MaterialService / SoundService / ServerStorage | ☐ |
| 1.3 | `rojo sourcemap` = scripts Studio (mêmes noms, mêmes classes) | ☐ |
| 1.4 | TideClient = LocalScript contenant ses modules | ☐ |
| 1.5 | Comptes Game Tree identiques avant/après (Remotes, Map, Assets, StarterGui, ReplicatedFirst, Lighting) | ☐ |

---

## 2. Core Stability

### 2.1 Net.lua

| # | Vérification | PASS |
|---|---|---|
| 2.1.1 | Rate limiting adaptatif actif (pas de ban faux positif) | ☐ |
| 2.1.2 | Anti-spam remote : flood de remotes → pas de crash serveur | ☐ |
| 2.1.3 | Reconnexion seamless : reconnexion < 3 s sans perte d'état | ☐ |
| 2.1.4 | Interpolation / prediction / réconciliation actives (netcode 500 joueurs) | ☐ |

### 2.2 DataStore

| # | Vérification | PASS |
|---|---|---|
| 2.2.1 | ProfileService v2 : sauvegarde/chargement OK | ☐ |
| 2.2.2 | Migration auto v1 → v2 sans perte | ☐ |
| 2.2.3 | DataStore backup horaire actif | ☐ |
| 2.2.4 | Recovery < 1 s après coupure | ☐ |
| 2.2.5 | Session lock : 2 sessions même compte = refus propre | ☐ |

### 2.3 Combat

| # | Vérification | PASS |
|---|---|---|
| 2.3.1 | Hit validation **serveur** (le client ne décide pas) | ☐ |
| 2.3.2 | Anti-téléport : déplacement impossible > seuil/tick | ☐ |
| 2.3.3 | Anti-speedhack : WalkSpeed serveur fait référence | ☐ |
| 2.3.4 | Lag compensation :Hit enregistré malgré latence | ☐ |

### 2.4 Vague

| # | Vérification | PASS |
|---|---|---|
| 2.4.1 | **P0** : ligne 404 = `base * CFrame.new(0, sink, -front)` | ☐ |
| 2.4.2 | 4 directions N/E/S/O, jamais 2× la même de suite | ☐ |
| 2.4.3 | Hauteur vague = 30, plateforme tours = 34 | ☐ |
| 2.4.4 | Prise si pieds < 30 et hors crique | ☐ |
| 2.4.5 | Tours / belvédère = abri (pieds au-dessus de 30) | ☐ |
| 2.4.6 | Rendu client visible sur le bon axe | ☐ |

### 2.5 Marée Royale

| # | Vérification | PASS |
|---|---|---|
| 2.5.1 | Score global calculé pendant le cycle | ☐ |
| 2.5.2 | Top 3 = couronnes + pièces (5/3/2 min revenu) | ☐ |
| 2.5.3 | Créature royale unique Golden | ☐ |
| 2.5.4 | `RoyalBoard` poussé à tous les joueurs | ☐ |
| 2.5.5 | Reset horaire | ☐ |

---

## 3. Streaming & Performance

| # | Vérification | PASS |
|---|---|---|
| 3.1 | StreamingEnabled actif | ☐ |
| 3.2 | Pop-in fluide (< 16 studs/s PC, < 32 mobile) | ☐ |
| 3.3 | LOD créatures 3 niveaux fonctionnels | ☐ |
| 3.4 | PC ≥ 60 FPS en zone dense à 100 joueurs | ☐ |
| 3.5 | Mobile ≥ 30 FPS en zone dense | ☐ |
| 3.6 | Mémoire dans les limites (voir PERFORMANCE.md) | ☐ |

---

## 4. Cross-Platform (à CHAQUE sync)

- [ ] Les **10 points** de `CROSS_PLATFORM.md` passent sur mobile **et** PC
- [ ] Si un seul échec → rollback (voir ROLLBACK.md scénario 3)

---

## 5. Régression

| # | Vérification | PASS |
|---|---|---|
| 5.1 | Systèmes Phase 0 (sauvegarde, session, Net) toujours OK | ☐ |
| 5.2 | 0 erreur / 0 warning console (mobile DevConsole + PC Output) | ☐ |
| 5.3 | Performance régression < 5% vs baseline précédente | ☐ |

---

## Sortie de Phase 1

- [ ] Tous les points ci-dessus PASS
- [ ] 0 P0 / 0 P1 ouvert
- [ ] Rapport postmortem Phase 1 dans `POSTMORTEMS/`
- [ ] Go pour Phase 2 (Monde & Histoire)

---

*Feuille vivante : cocher les cases au fur et à mesure. Toute case non cochée à la fin = bloque le passage à la Phase 2.*
