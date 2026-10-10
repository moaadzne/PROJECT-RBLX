# Quêtes — framework + gabarits

**Auteure : E (concept lead). 2026-10-10.**
**Statut : architecture, gabarits et noyau écrit. Le volume (100+ quêtes détaillées) est le livrable de l'agent O en Phase 2.**
Socle : `LORE_BIBLE_v2.md`, `CAMPAGNE_10_CHAPITRES.md`.

> **Pourquoi je ne livre pas les 100 quêtes ici** : les duplier coûterait du budget pour un travail que l'agent O doit refaire de toute façon. Ce document donne l'architecture, les gabarits et un lot réel écrit — O remplit le volume avec. Ce qui est écrit ici est **utilisable tel quel**.

---

## 1. Les 4 types de quêtes

| Type | Rôle | Longueur | Récompense | Exemple |
|---|---|---|---|---|
| **Histoire** | Fait avancer la campagne | 1 chapitre | Cosmétique, badge, titre | Chapitre 3 — l'épave ouverte |
| **Répétable** | Fait tourner la boucle | 2-10 min | Pièces, XP | « Attrape 5 créatures » |
| **Exploration** | Révèle le monde | 10-30 min | Gravure, secret, espèce | « Trouve la 2ᵉ gravure » |
| **Sociale** | Relie les joueurs | Variable | Réputation, cosmétique | « Protège le lagon d'un autre joueur » |

**Règle** : une quête donne du **temps** ou du **sens**, jamais de la puissance. Aucune quête ne donne de revenu/s, de vitesse ou de stade.

---

## 2. Le moteur : 5 familles de gameplay

Toutes les quêtes du jeu sont construites sur ces 5 familles. **Toute nouvelle quête est une combinaison de 2 ou 3.**

| Famille | Verbe | Mécanique GDD |
|---|---|---|
| **Capture** | Attraper / Rapporter | Boucle de base, `Config.PickupRadius` |
| **Survie** | Fuir / Surfer | La vague, monture Titan, abris |
| **Exploration** | Trouver / Descendre | Marée extrême, récif, épave, abysse |
| **Sociale** | Voler / Protéger / Échanger | `Config.Steal`, protection, économie |
| **Patience** | Attendre / Revenir | Croissance, hors ligne, calendrier |

**Conséquence de production** : 100 quêtes ne demandent pas 100 mécaniques. Elles demandent 5 mécaniques × 20 habillages narratifs.

---

## 3. Gabarit de quête (à utiliser par O)

```
TITRE        : 2-5 mots, verbe d'action. "RAPPORTE LE FILET"
DONNEUR      : PNJ (doit avoir un rôle OU un secret, jamais décoratif)
FAMILLE      : Capture / Survie / Exploration / Sociale / Patience
MÉCANIQUE    : la rèle de jeu réelle, sans lore
HABILLAGE    : ce que le joueur croit faire (le lore)
OBJECTIF     : mesurable côté serveur
RÉCOMPENSE   : pièces / XP / cosmétique / secret
SECRET       : ce que le joueur curieux découvre en plus (souvent rien)
```

**Exemple rempli** :
```
TITRE       : RAPPORTE LE FILET
DONNEUR     : Bram (Tisseur)
FAMILLE     : Sociale + Capture
MÉCANIQUE   : Rapporte 3 Cushion Stars et rends-les à un autre joueur
HABILLAGE   : Un filet cassé, trois étoiles, un quota
OBJECTIF    : 3 CushionStar livrées
RÉCOMPENSE  : +2 % réputation Tisseur, 500 pièces
SECRET      : Le filet est celui que Kael cherche au chapitre 2
```

---

## 4. Lot réel écrit — les 24 premières

### Exploration (6) — révèlent le monde

| # | Titre | Donneur | Mécanique | Récompense | Secret |
|---|---|---|---|---|---|
| Q01 | TROUVE LA GRAVURE | aucun (trouvée dans le monde) | Descendre dans l'épave | Lore | — |
| Q02 | CE QU'IL A PRIS | Kael | Ressortir 1 objet de l'abysse | Espèce + lore | L'objet est à Maren |
| Q03 | LES QUATRE SILHOUETTES | aucune (gravure récif) | Voir la gravure du récif | Lore | — |
| Q04 | LA MAIN QUI TOUCHE | aucune (grotte du reflux) | Entrer pendant un reflux | Secret | — |
| Q05 | L'ÉCOLE VIDE | aucun (ruines) | Explorer les ruines | Lore | — |
| Q06 | LE LAGON DE QUELQU'UN D'AUTRE | aucune | Visiter 8 lagons | +500 pièces | Le 8ᵉ est vide depuis 80 ans |

### Survie (6) — enseignent la vague

| # | Titre | Donneur | Mécanique | Récompense |
|---|---|---|---|---|
| Q07 | TRAVERSE 3 MARÉES | Maren | Survivre 3 vagues d'affilée | Badge Gardien |
| Q08 | SURFE UNE VAGUE | Ysolde | Surfer avec une Titan | Cosmétique planche |
| Q09 | NE RAMÈNE RIEN | Maren | Traverser une vague sans rien perdre | Titre |
| Q10 | SAUVE TON VOISIN | Maren | Protéger un lagon d'un autre joueur | Réputation Gardien |
| Q11 | LA MARÉE EXTRÊME | aucun | Aller au récif pendant une extrême | Espèce Golden |
| Q12 | CINQ FOIS DE SUITE | Ysolde | 5 vagues sans être pris | Cosmétique |

### Capture (6)

| # | Titre | Donneur | Mécanique | Récompense |
|---|---|---|---|---|
| Q13 | LES TROIS DU RIVAGE | Kael | 1 de chaque espèce Phase 1 | +5 % Codex |
| Q14 | DIX CRABES | Kael | 10 GhostCrabs | 800 pièces |
| Q15 | CELLE QUI BRILLE | aucun | Attraper une Golden | Cosmétique |
| Q16 | LE PALIER DEUX | aucun | Atteindre 30 /s | Monument lagon |
| Q17 | LE PALIER TROIS | aucun | Atteindre 200 /s | Monument lagon |
| Q18 | MONTURE | aucun | Porter une tortue Elder | Selle cosmétique |

### Sociale (6)

| # | Titre | Donneur | Mécanique | Récompense |
|---|---|---|---|---|
| Q19 | LE RETOUR | Bram | Échanger avec 3 joueurs | Réputation Tisseur |
| Q20 | LA REVANCHE | aucun | Reprendre un vol subi | Titre |
| Q21 | LA COURONNE | aucun | Top 3 Marée Royale | Couronne |
| Q22 | LE MARCHÉ | Bram | Vendre 5 créatures | 1 200 pièces |
| Q23 | L'INVITATION | aucun | Ami qui joue 10 min | +500 pièces |
| Q24 | LE FOSSoyeur | Le Fossoyeur | Ramener 20 noms | Cosmétique rare |

---

## 5. Comment aller à 100+ sans exploser

| Famille | Écrites ici | Volume Phase 2 | Dont |
|---|---|---|---|
| Exploration | 6 | 30 | Dont 8 gravures/secrets |
| Survie | 6 | 20 | Dont 5 de surf Titan |
| Capture | 6 | 20 | Dont les 50+ créatures |
| Sociale | 6 | 20 | Dont guildes et économie |
| Patience | 0 | 15 | Daily, hebdo, retour |
| **Total** | **24** | **105** | |

**Le levier** : les quêtes Patience n'existent que grâce au calendrier (`LORE_BIBLE_v2.md` §7) — jour 1-7, semaine 1-12, saisons. **Le temps fait le contenu, pas la production.**

---

## 6. Ce que ce framework interdit

- **Aucune quête ne donne de puissance.** Temps ou sens, jamais stats.
- **Aucune quête mur de texte.** Si l'objectif ne se lit pas en 5 mots, elle est ratée.
- **Aucune quête bloquante hors campagne.** Tout est optionnel sauf les 10 chapitres.
- **Aucune quête payante.** Aucun « skip de quête » en Robux.

---

*Écrit par E le 10/10/2026. Architecture + noyau. Volume à charge de l'agent O, Phase 2.*
