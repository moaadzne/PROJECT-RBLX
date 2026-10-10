# Test Plan — Phase 4 : PvP & Économie (Semaines 9-10)

**Responsable QA : M**

---

## 1. Zones PvP

| # | Vérification | PASS |
|---|---|---|
| 1.1 | Îlots contestés, ressources rares | ☐ |
| 1.2 | Contrôle territorial par les guildes | ☐ |
| 1.3 | Protections nouveaux joueurs | ☐ |
| 1.4 | Récompenses de zone cohérentes | ☐ |
| 1.5 | Aucun avantage acheté (ZÉRO P2W) | ☐ |

---

## 2. Arènes classées

| # | Vérification | PASS |
|---|---|---|
| 2.1 | 1v1, 2v2, 3v3 fonctionnels | ☐ |
| 2.2 | MMR calculé et affiché | ☐ |
| 2.3 | Saisons + reset MMR | ☐ |
| 2.4 | Récompenses **cosmétiques uniquement** (P0 audit) | ☐ |
| 2.5 | Matchmaking équilibré (pas de mismatch extrême) | ☐ |
| 2.6 | Latence tolérée (lag compensation) | ☐ |

---

## 3. Guerres de guilde

| # | Vérification | PASS |
|---|---|---|
| 3.1 | Sièges de bases, objectifs | ☐ |
| 3.2 | Ressources et cooldown respectés | ☐ |
| 3.3 | Guild Hall avec permissions | ☐ |
| 3.4 | Chat / calendrier guilde | ☐ |
| 3.5 | Bank guilde (QoL, pas puissance) | ☐ |

---

## 4. Économie joueur

| # | Vérification | PASS |
|---|---|---|
| 4.1 | Hôtel des ventes : taxe **5 %** | ☐ |
| 4.2 | Filtres, enchères, contrats | ☐ |
| 4.3 | Historique consultable | ☐ |
| 4.4 | Trading direct : fenêtre sécurisée | ☐ |
| 4.5 | Confirmation avant échange final | ☐ |
| 4.6 | Anti-scam (double confirmation items/prix) | ☐ |
| 4.7 | Assurance vol optionnelle | ☐ |
| 4.8 | Shop = source primaire, joueur = secondaire | ☐ |

---

## 5. Anti-RMT / Anti-exploit (P0)

| # | Vérification | PASS |
|---|---|---|
| 5.1 | Logs transactions comparés (trades, ventes) | ☐ |
| 5.2 | Limites (montant/fréquence) actives | ☐ |
| 5.3 | Détection patterns suspects → flag | ☐ |
| 5.4 | Test : tentative de duplication d'items = échec | ☐ |
| 5.5 | Test : inflation < 5 %/semaine sur 50 traders | ☐ |

---

## 6. Cross-platform

- [ ] 10 points PASS mobile **et** PC
- [ ] Trading utilisable des deux plateformes
- [ ] Arènes jouables au clavier/souris **et** tactile

---

## 7. Régression

| # | Vérification | PASS |
|---|---|---|
| 7.1 | Phases 1-3 toujours PASS | ☐ |
| 7.2 | Économie stable (pas de boucle de dup) | ☐ |
| 7.3 | Performance régression < 5% | ☐ |
| 7.4 | 0 erreur / 0 warning | ☐ |

---

## Sortie Phase 4

- [ ] PvP + économie sans exploit
- [ ] 0 fail anti-RMT
- [ ] Go pour Phase 5 (Endgame & Polish)
