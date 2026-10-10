# LORE_ARCHIPEL — Archipel des Marées

**Auteur : O (Story & Lore Lead). Écrit le 2026-10-10.**
Aligné sur : DIRECTION_V2, GDD_REEF, DECISIONS_MARCHE.md §9, contrat v2.1.

---

## 1. VISION GÉNÉRALE

L'**Archipel des Marées** est un monde persistant de 5 îles principales + îlots secrets, façonné par la **Malédiction des Marées** — un cycle éternel de 1 heure (55 min de normale → 25 s d'extrême où le récif est révélé → reflux). Au cœur de l'île principale dort l'**Ancien Roi Léviathan**, un être colossal dont les rêves font monter et descendre les marées. La Malédiction est à la fois une mécanique de jeu (vague, marée extrême, Marée Royale) et le fondement narratif : le monde est prisonnier du cycle du Roi, et le joueur doit comprendre pourquoi.

**Ton** : cool, intense, premium. Pas enfantin. Zéro emoji. Capitales condensées. Verbes d'action.

---

## 2. GÉOGRAPHIE NARRATIVE

### 2.1 Les 5 îles principales

| Île | Nom | Fonction narrative | Zone GDD_REEF |
|---|---|---|---|
| 1 | **Île de la Crique** | Zone sûre, départ, lagons joueurs | Crique Centrale (rayon 70) |
| 2 | **Île des Ruines** | Lore ancien, chapitre 3, journaux/fresques | Anneau 1 (70-150) |
| 3 | **Île de l'Épave** | Chapitre 4, épave qui chuchote, Marchand | Anneau 2 (150-225) |
| 4 | **Île du Récif** | Chapitre 5, cœur du récif, Orpheline | Anneau 3 (225-300) |
| 5 | **Île du Léviathan** | Endgame, chapitre 9-10, cœur du Roi | Récif Noyé (sud, 335) |

### 2.2 Les îlots secrets

- **Îlot Nord** : Zone PvP Marée Noire (Phase 4)
- **Îlot Est** : Zone PvP Marée Noire (Phase 4)
- **Îlot Ouest** : Zone PvP Marée Noire (Phase 4)
- **Îlot du Phare** : Belvédère, spot vidéo, abri de toutes les vagues
- **Îlot de la Perle** : Secret, débloqué par l'Orpheline (chapitre 7)

### 2.3 Correspondance avec GDD_REEF

- **Crique Centrale** = zone sûre, pas de créatures, lagons joueurs
- **Anneaux 1-3** = progression risque/récompense (Common → Uncommon → Rare)
- **Récif Noyé** = endgame, marée extrême, Deep Dive, Éveil Léviathan
- **Épave** (ouest) = créatures meilleures, loin de la crique
- **Belvédère** (falaise) = spot vidéo, abri de toutes les vagues

---

## 3. L'ANCIEN ROI — LÉVIATHAN

### 3.1 Nature

Léviathan est un **WhaleShark Titan** (espèce 10 du roster, Legendary, montable). Il dort sous l'île principale depuis des millénaires. Ses rêves font monter et descendre les marées. Quand il s'éveille (Phase 3, chapitre 9-10), le monde entier le sent : la mer tremble, le ciel change, les créatures fuient.

### 3.2 Rôle narratif

- **Cycle 1-2** : Léviathan est une rumeur, une gravure, une empreinte lumineuse. Le joueur entend des échos sonores, voit des fresques, lit des journaux.
- **Cycle 3** (Phase 3) : Léviathan s'éveille — Événement Mondial, Raid 20 joueurs, cinématique serveur-synchro.
- **Cycle 4-5** : Léviathan est un personnage — on peut le combattre, le raisonner, ou le libérer (3 fins).

### 3.3 Connexion avec le roster

- **WhaleShark** (Legendary, montable) = forme mortelle de Léviathan
- **MantaRay** (Legendary, montable) = messager du Roi
- **LionsManeJelly** (Epic) = gardien des abysses du Roi
- **GiantPacificOctopus** (Epic) = serviteur du Roi

---

## 4. LA MALÉDICTION DES MARÉES

### 4.1 Nature

La Malédiction est un **cycle éternel** infligé à l'archipel par l'Ancien Roi. Elle se manifeste par :
- **Marée normale** (55 min) : la mer monte et descend, les créatures apparaissent sur la plage
- **Marée extrême** (25 s) : la mer se retire plus loin, le récif est révélé, des créatures rares apparaissent
- **Marée Royale** (1 cycle sur 8) : une créature royale unique apparaît, le classement s'active
- **Marée Noire** (Phase 4) : zone PvP, la mer devient noire, les ressources rares apparaissent

### 4.2 Rôle narratif

- **Cycle 1-2** : La Malédiction est le mystère central. Pourquoi la mer monte et descend ? Qui a infligé cette malédiction ?
- **Cycle 3** : La Malédiction est liée à Léviathan — c'est son sommeil qui crée le cycle.
- **Cycle 4-5** : La Malédiction peut être brisée (3 fins : Gardien / Marchand / Orpheline).

### 4.3 Connexion avec GDD_REEF

- **Config.Tides** : Normal, Golden (Phase 1) → Night, Storm, Rainbow (Phase 2)
- **Config.ExtremeTide** : cycle 58, revealTime 25 s, récif sud
- **Config.TideSchedule** : rotation Golden toutes les 8 cycles
- **WaveState** : phase, tide, direction, extreme, royal

---

## 5. LES 10 CHAPITRES — CAMPAGNE PRINCIPALE

### 5.1 Structure

| Chapitre | Titre | Durée | Île | PNJ | Choix impactant |
|---|---|---|---|---|---|
| 1 | Arrivée & Premier Reflet | 2-3 h | Crique | Gardien | Protéger / Observer / Exploiter |
| 2 | Le Gardien des Marées | 2-3 h | Crique | Gardien | Croire / Douter / Interroger |
| 3 | Échos du Passé | 2-3 h | Ruines | — | Explorer / Détruire / Préserver |
| 4 | L'Épave qui Chuchote | 2-3 h | Épave | Marchand | Échanger / Voler / Protéger |
| 5 | Cœur du Récif | 2-3 h | Récif | Orpheline | Écouter / Ignorer / Trahir |
| 6 | Le Marchand d'Écailles | 2-3 h | Épave | Marchand | Acheter / Négocier / Refuser |
| 7 | L'Orpheline et la Perle | 2-3 h | Récif | Orpheline | Garder / Rendre / Détruire |
| 8 | Marée Noire | 2-3 h | Îlots | — | Combattre / Fuir / Négocier |
| 9 | Chant du Léviathan | 2-3 h | Léviathan | — | Combattre / Raisonner / Libérer |
| 10 | L'Éveil | 2-3 h | Léviathan | — | 3 fins (Gardien / Marchand / Orpheline) |

### 5.2 Règles

- Chaque chapitre = 2-3 h de jeu, cinématique 2-3 min
- Choix impactants : réputation PNJ, accès zones, items lore, dénouement final
- 3 fins possibles : fin Gardien (ordre), fin Marchand (pouvoir), fin Orpheline (liberté)
- Codex lore intégré : 50 entrées (ruines, journaux, fresques, échos sonores)

---

## 6. CODEX LORE — 50 ENTRÉES

### 6.1 Structure

| Type | Nombre | Où | Contenu |
|---|---|---|---|
| Ruines | 10 | Île des Ruines | Fresques, statues, tablettes |
| Journaux | 10 | Épave, Récif, Léviathan | Pages de bord, lettres, notes |
| Échos sonores | 10 | Partout | Voix, chants, murmures |
| Fresques | 10 | Ruines, Léviathan | Peintures murales, glyphes |
| Secrets | 10 | Îlots, belvédère, perle | Caches, énigmes, récompenses |

### 6.2 Intégration avec GDD_REEF

- **Config.Codex** : 10 espèces × 2 variantes = 20 lignes (Phase 1)
- **Codex lore** : 50 entrées supplémentaires (Phase 2+)
- **Config.CodexTiers** : 5 paliers (Phase 2, proposition E)
- **Notify `codex`** : déclenche l'affichage d'une nouvelle entrée

---

## 7. ALIGNEMENT TECHNIQUE

### 7.1 Contrat v2.1

- **WaveState** : phase, tide, direction, extreme, royal
- **State** : intro, golden, done, codex, lagoonTier, mount, carrying
- **Notify** : codex, capture, deposit, grown, royal, extreme, caught, survived

### 7.2 DataStore v3 (proposition)

```lua
state.questLog = { {questId, stage, choices}, ... }
state.choices = { [questId] = choiceId }
state.reputation = { [PNJ] = -100..100 }
state.loreDiscovered = { [loreId] = true }
state.cinematicSeen = { [cinematicId] = true }
```

### 7.3 Planning 12 semaines

- **Phase 1** (sem 1-2) : Fondation — serveur, netcode, DataStore, streaming
- **Phase 2** (sem 3-5) : Monde & Histoire — Archipel, Chapitres 1-3, PNJ, quêtes, cinématiques
- **Phase 3** (sem 6-8) : Progression & Boss — Classes, talents, gear, World Boss 1, Donjon 1
- **Phase 4** (sem 9-10) : PvP & Économie — Arènes, hôtel ventes, guildes, bases, trading
- **Phase 5** (sem 11-12) : Endgame & Polish — Raid 10/20, World Boss 2-3, cinématiques finales

---

## 8. RÉFÉRENCES

- `docs/GDD_REEF.md` — roster, marées, zones, Codex
- `docs/DIRECTION_V2.md` — ton, style, public
- `docs/DECISIONS_MARCHE.md` §9 — PIVOT MAJEUR, 5 piliers
- `review/review_context.md` — contrat v2.1
- `docs/LORE_PNJ.md` — 3 PNJ mémorables, dialogues, choix
- `docs/LORE_EVENTS.md` — Éveil Léviathan, Marée Noire

---

*Écrit par O le 2026-10-10. Si une valeur de ce document et `Config.lua` divergent, **Config gagne**.*
