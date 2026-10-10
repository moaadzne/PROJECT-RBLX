# Test Plan — Phase 2 : Monde & Histoire (Semaines 3-5)

**Responsable QA : M**

---

## Objectif

Valider l'archipel (streaming), la campagne (chapitres 1-3), les PNJ, les quêtes et le moteur cinématographique.

---

## 1. Monde & Streaming

| # | Vérification | PASS |
|---|---|---|
| 1.1 | Îles complètes (archipel), 3 points d'intérêt visibles | ☐ |
| 1.2 | StreamingEnabled : chunks fluides, aucun pop-in agressif | ☐ |
| 1.3 | Collision correcte (terrain, rochers, bâtiments) | ☐ |
| 1.4 | Navigation PNJ / créatures fonctionnelle | ☐ |
| 1.5 | Lore environnemental découvert (ruines, journaux, échos) | ☐ |
| 1.6 | Météo dynamique et événements monde (marée extrême) | ☐ |
| 1.7 | Performance maintenue en zone dense | ☐ |

---

## 2. Histoire & Quêtes

| # | Vérification | PASS |
|---|---|---|
| 2.1 | Chapitre 1-3 jouables de bout en bout | ☐ |
| 2.2 | Cinématique intro (3 min) joue sans bug caméra | ☐ |
| 2.3 | Chapitres dialogués 2-3 min avec impact des choix | ☐ |
| 2.4 | 100+ quêtes secondaires branchées | ☐ |
| 2.5 | Conséquences visibles des choix majeurs | ☐ |
| 2.6 | PNJ mémorables, dialogues cohérents | ☐ |
| 2.7 | Sauvegarde/rechargement conserve l'état de quête | ☐ |
| 2.8 | Aucun joueur bloqué (quête non faisable = fail) | ☐ |

---

## 3. Moteur cinématographique (S)

| # | Vérification | PASS |
|---|---|---|
| 3.1 | Caméra scriptée, dialogue, choix fonctionnent | ☐ |
| 3.2 | Caméra joueur verrouillée pendant la cinématique | ☐ |
| 3.3 | Replay system : enregistrement + caméra libre + export | ☐ |
| 3.4 | Toutes les cinématiques visibles mobile **et** PC | ☐ |
| 3.5 | Skip possible (confort joueur) | ☐ |

---

## 4. Cross-platform

- [ ] 10 points `CROSS_PLATFORM.md` PASS mobile **et** PC
- [ ] Streaming correct sur mobile low-end
- [ ] Cinématiques fluides sur mobile

---

## 5. Régression

| # | Vérification | PASS |
|---|---|---|
| 5.1 | Phase 1 toujours PASS (fondation) | ☐ |
| 5.2 | Performance régression < 5% | ☐ |
| 5.3 | 0 erreur / 0 warning | ☐ |

---

## Sortie Phase 2

- [ ] Chapitres 1-3 sans blocage
- [ ] 0 P0 / P1 ouvert
- [ ] Go pour Phase 3 (Progression & Boss)
