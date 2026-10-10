# Test Plan — Phase 3 : Progression & Boss (Semaines 6-8)

**Responsable QA : M**

---

## 1. Progression & Builds

| # | Vérification | PASS |
|---|---|---|
| 1.1 | Niveaux 1-100+ atteignables, XP cohérente | ☐ |
| 1.2 | 4 classes : Gardien / Chasseur / Maître / Tisseur | ☐ |
| 1.3 | Stats de base + scaling par classe corrects | ☐ |
| 1.4 | 3 arbres de talents / classe | ☐ |
| 1.5 | 30 points max, respec au coût croissant | ☐ |
| 1.6 | Builds variés possibles (pas de mono-build obligatoire) | ☐ |

---

## 2. Gear & Craft

| # | Vérification | PASS |
|---|---|---|
| 2.1 | Craft : recettes, matériaux, réussite | ☐ |
| 2.2 | Enchantement et runes | ☐ |
| 2.3 | Sets légendaires (bonus de set) | ☐ |
| 2.4 | Durabilité et repair (pas de destruction définitive) | ☐ |
| 2.5 | Aucun gear achetable = puissance (ZÉRO P2W) | ☐ |

---

## 3. Créatures 50+

| # | Vérification | PASS |
|---|---|---|
| 3.1 | 50+ espèces présentes avec stats | ☐ |
| 3.2 | Évolution ramifiée (pas linéaire) | ☐ |
| 3.3 | Mutations héréditaires transmises au breeding | ☐ |
| 3.4 | Breeding (2 parents → descendant) | ☐ |
| 3.5 | Montures vol / nage / terre | ☐ |
| 3.6 | Arbre de progression propre par monture | ☐ |
| 3.7 | Skins monture = shader/trail swap (pas nouveau mesh) | ☐ |

---

## 4. Boss / Donjon / Raid

| # | Vérification | PASS |
|---|---|---|
| 4.1 | World Boss (Leviathan / Kraken / Hydre) 20 joueurs | ☐ |
| 4.2 | Phases, enrage timer, positioning — pas tank & spank | ☐ |
| 4.3 | Loot table cohérente (cosmétiques + matériaux) | ☐ |
| 4.4 | Donjons 5 joueurs × 3 difficultés (N/H/M) | ☐ |
| 4.5 | Weekly reset des donjons | ☐ |
| 4.6 | Raids 10/20 joueurs (Temple / Abyss / Cathédrale) | ☐ |
| 4.7 | Coordination requise (mécaniques multi-joueurs) | ☐ |
| 4.8 | Récompenses : cosmétiques + titres, **jamais** puissance | ☐ |
| 4.9 | Intro cinématique 30 s par boss majeur | ☐ |

---

## 5. Tests de charge contenu

| Test | Joueurs | Critère |
|---|---|---|
| World Boss | 20 simultanés | 0 desync, loot correct, phases stables |
| Donjon | 5 simultanés | 3 difficultés sans blocage |
| Raid | 10 + 20 | coordination, enrage, récompenses |

---

## 6. Cross-platform

- [ ] 10 points PASS mobile **et** PC
- [ ] Boss lisibles sur mobile (phases annoncées, lisibilité)
- [ ] HUD boss / raid lisible sur les deux plateformes

---

## 7. Régression

| # | Vérification | PASS |
|---|---|---|
| 7.1 | Phases 1-2 toujours PASS | ☐ |
| 7.2 | Performance régression < 5% | ☐ |
| 7.3 | 0 erreur / 0 warning | ☐ |

---

## Sortie Phase 3

- [ ] World Boss 1 et Donjon 1 validés
- [ ] Progression 1-100 validée
- [ ] Go pour Phase 4 (PvP & Économie)
