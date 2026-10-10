# B — Interface & feel : PRÉPARATION (méthode + structure)

Statut : **préparation seulement**. Aucun code Luau, aucune maquette, aucun commit.
Document rédigé par B le 2026-10-10. Remplace le brouillon du même jour, bâti sur une
prémisse fausse (GDD « non écrit ») — voir §0.

Hiérarchie des références pour toute l'UI :
**`docs/DIRECTION_V2.md`** (prime) → `docs/DA_MONDE.md` (monde) → `docs/BIBLE_QUALITE.md` §5–6 ·
`docs/UI_REEF.md` est **périmé** (voir §0.3) · contrat technique : `review/review_context.md` v2.1.

---

## 0. Faits vérifiés avant de concevoir

### 0.1 Le GDD existe — c'est le point qui change tout
`docs/GDD.md` **v3, 656 lignes**, écrit par E, intégré en git (`bd7691a`, `241827c`, `657645f`).
Il contient : univers (§1), 30 premières secondes image par image (§1 ter), boucle (§2),
île ouverte (§3 bis), 10 espèces + 4 stades + mutations (§4.2–4.5), monture (§4.6),
vol (§4.7), Marée Royale (§4.8), économie (§5), Codex (§5.4), Tide Rank (§5.6),
social (§7), onboarding (§8), monétisation (§9), **Deep Dive (§9 bis)**, KPI (§10),
**livrables de B (§11)**, **périmètre Phase 1 (§12)**, Config (§13).

`docs/EQUIPE.md` §Documents dit encore « (à venir) » : **c'est la ligne périmée**, pas le GDD.
Je conçois donc **sur le GDD réel**, pas en attente.

### 0.2 L'ancienne UI est bien celle du dépôt — page blanche confirmée
`src/StarterPlayer/StarterPlayerScripts/TideClient/` = 6 329 lignes, 19 modules.
Vérifié par grep : **37 glyphes emoji** (👑 🐢 🔒 🌊 ✨ 🐚 ⭐ 🦀 🛒 🚨 ⚔ 🛡 ⬇) sur 7 fichiers,
et **`Theme.lua:47` titre en `LuckiestGuy`** — police ronde, interdite par DIRECTION_V2 §Interface.
C'est exactement le lot signalé par la QA de F le 09/10 (`TABLEAU.md` : « 74 emojis + LuckiestGuy chez B »).

**Décision** : je repars de zéro visuellement. Je ne réécris pas ligne par ligne — je repars
d'un système neuf (jetons + composants), et je réutilise seulement la plomberie qui marche
(`Util`, `Settings`, `Sfx`, `Fx`, `Store` — ce dernier seulement après mise à niveau §0.4).

### 0.3 Trois documents UI se contredisent — arbitrage
| Doc | Statut | Conflit |
|---|---|---|
| `UI_REEF.md` (commitée, v2) | **périmée** | prescrit Luckiest Guy (§1) alors que DIRECTION_V2 exige une condensée ; et contient elle-même des emoji (§1, §3) **en violant sa propre règle**. |
| `UI_B_preparation.md` (brouillon du jour) | **remplacée** | partait de « GDD non écrit » ; annonçait une arborescence socles/trésors. |
| `DIRECTION_V2.md` §Interface | **prime** | plaques sombres translucides, coins 6–10 px, condensée, MAJUSCULES espacées, **aucun emoji**, animations 0,1–0,25 s. |

À faire confirmer par D : je **retire `UI_REEF.md`** de la circulation (ou j'y grave un bandeau « v2, périmée »).

### 0.4 Tâches B déjà ouvertes au tableau
- **P1-15 — CRITIQUE avant lundi** : aligner le client sur le contrat v2.1 de A (`StartSteal`, `Mount(nil)`,
  `ChoosePick`, `shop.randomAllowed`, stades Juvenile…Titan, ids v3). Sinon **vol, monture et boutique ne marchent pas.**
- **P1-14** : appliquer DIRECTION_V2 au système visuel — c'est ma vague 0.
- **P1-36** (en cours) : boussole + direction de la vague (île ouverte).
- **P1-13** : boutique codée côté client, **attend `Config.Shop` et les RF de A**.

Le store porte encore ses « HYPOTHESES » en attendant A (`Store.lua:146`) : c'est le cœur de P1-15.

---

## 1. Périmètre de conception : Phase 1 d'abord

Le GDD est complet jusqu'à la semaine 2 et au mois. On ne conçoit pas l'UI de tout le GDD :
on conçoit **GDD §12, ni plus ni moins** (`TABLEAU.md` : « Périmètre de la Phase 1 = GDD §12 »).

**Dedans** : intro 30 s · Shallows · 3 espèces (Ghost Crab, Cushion Star, Hawksbill Turtle montable) ·
4 stades · monture Elder + surf Titan · vol complet avec protections · marées Normal + Golden ·
Marée Royale à chaque Golden · Speed / Bag / Slots · sauvegarde v2 · boutique minimale ·
boussole et direction de la vague · marée extrême (récif révélé, signes sans texte).

**Dehors, donc pas dessinés maintenant** : zones 2–5 · mutations autres que Golden ·
Codex complet · Léviathan · Tide Rank · échanges · visites · quêtes · compagnons · **Deep Dive (§9 bis, semaine 2)**.

Ce découpage est la première décision qui évite du travail perdu : l'arborescence ci-dessous
prévoit leurs emplacements, mais on ne dessine pas leurs écrans.

---

## 2. Méthode — 4 vagues

Chaque vague produit **un écran testable** et **une seule capture de validation** pour Moaad.
On n'ouvre une vague qu'après validation de la précédente.

| Vague | Objet | Sortie | Verrou |
|---|---|---|---|
| **0 — Socle** | Système visuel neuf : jetons (couleurs, coins 6–10 px, typo condensée, échelles), 6 briques de base (Plaque, Bouton, Texte, Icône, Barre, Fiche), zones de sécurité, mise à l'échelle mobile. Remplace `Theme` + `Components`. | Bibliothèque neuve + écran de test des briques, aux 3 formats. | P1-14. **Aucune dépendance au GDD** : DIRECTION_V2 suffit. |
| **1 — HUD** | Le permanent : marine (pièces + revenu/s), sac, bandeau de marée, **boussole + direction de la vague**, objectif suivant, barre d'actions, HUD de vol, HUD Marée Royale, bouton monter. | HUD jouable sur Shallows. | Vague 0 + contrat v2.1 figé (P1-15). |
| **2 — Panneaux** | Les écrans sur ouverture : Lagon, Fiche créature, Boutique, Réglages. Codex **en attente** (§1). | Panneaux complets. | Contenus §4.2–4.5 et §9 figés. |
| **3 — Écrans-système** | Chargement (ReplicatedFirst), intro 30 s, carte de gains hors ligne, erreur/connexion. | Écrans non-jeu. | §1 ter et §8 figés. |

### 2.1 Un décalage que je signale et propose
GDD §12 : « Les 30 premières secondes du §1 ter, son compris : **c'est le premier livrable jugé.** »
Mais l'ordre demandé place les écrans-système en vague 3. Ces deux règles se contredisent.

**Ma proposition** : l'**intro de 30 s et l'écran de chargement sortent de la vague 3 et ouvrent la vague 1**,
juste après le socle. Le reste de la vague 3 (hors-ligne, erreur) reste en vague 3.
C'est le seul écart que je prends sur l'ordre demandé ; **à arbitrer par D**.

### 2.2 Règles de coupe
- Une vague = une capture, pas plus.
- Le socle (vague 0) avance **sans attendre** qui que ce soit : c'est le seul poste sans verrou.
- Aucune maquette visualisée « pour montrer » sans décision GDD derrière.
- Toute divergence avec le contrat de A passe par une demande `[R-xx]`, pas par un choix silencieux.

---

## 3. Arborescence des écrans

```
Interface (StarterGui) — page blanche, zéro réemploi de l'existant
├─ Core — permanent, non-fermable
│  ├─ Loading          [v3→v1]  ReplicatedFirst, fondu, préchargement
│  ├─ Onboarding       [v3→v1]  §1 ter, 30 s, AUCUN HUD sauf le joystick
│  ├─ HUD              [v1]
│  │  ├─ TopLeft       marine : pièces + revenu/s (2 nombres, pas 5)
│  │  ├─ TopCenter     bandeau de MARÉE : type, compte à rebours, phase
│  │  ├─ TopRight      boussole + direction de la vague + sac
│  │  ├─ LeftColumn    colonne d'états (vol, revanche, bouclier, Royal) — empilée, max 3
│  │  └─ BottomRight   barre d'actions : monter, verrouiller, lagon, boutique
│  ├─ StealOverlay     [v1]  flèche vers le voleur, barre de maintien 1 s, bouton Verrou
│  ├─ RoyalOverlay     [v1]  top 3 en direct + couronnes
│  ├─ Toasts           [v1]  max 3, priorité vague > récompense > info
│  └─ WorldLabels      [v1]  billboard de bassin : espèce, stade, mutation, barre
│
├─ Panels — sur ouverture, 0,25 s Back, fond assombri + flou
│  ├─ Lagoon           [v2]  TON lagon : cuvettes, créature dans l'eau, LagoonTier
│  ├─ Creature         [v2]  fiche : espèce, stade, mutation, revenu, origine
│  ├─ Shop             [v2]  3 passes + Tide Egg / Pick a Creature, probabilités avant achat
│  ├─ Settings         [v1]  graphismes, volumes, réduire animations, taille UI
│  ├─ Codex            [v4]  DIFFÉRÉ — hors Phase 1 (§1). Emplacement réservé.
│  └─ Goals            [v4]  DIFFÉRÉ — hors Phase 1. Emplacement réservé.
│
└─ Flow
   ├─ OfflineSummary   [v3]  carte unique, plafond 8 h, 50 % du revenu
   └─ ConnectionError  [v3]  pas d'écran de mort, pas de perte
```

**Principes**
- **Core vs Panels** : ce qui se lit en courant vit dans le HUD, le reste est sur ouverture.
  Jamais les deux en même temps (bible §9 : « interface qui cache l'action »).
- **Une entrée = un écran** : la fiche créature et le lagon sont distincts. Pas de méga-menu.
- **Pas d'imbrication** : une liste est un sous-écran du même panneau, jamais un panneau dans un panneau.
- **Emplacements réservés pour le hors-Phase 1** : leur absence est volontaire, pas un oubli.

---

## 4. Cibles et mise en page

Toiles de référence (Device Emulator Studio) :

| Cible | Format | Rôle |
|---|---|---|
| **Téléphone** (paysage) | 844 × 390 | **cible principale** — public 13–25 ans, mobile d'abord |
| **Téléphone** (portrait) | 390 × 844 | à tester : le jeu se joue en paysage, mais rien ne doit déborder |
| **Tablette** | 1180 × 820 | confort, panneaux plus aérés |
| **PC** | 1920 × 1080 | l'UI s'ancre aux bords, ne flotte pas au centre |

**Toile de design** : 900 × 480 (téléphone à l'échelle 0,85). Tout se mesure là.

Règles :
- **Échelle unique** pilotée par la largeur (UIScale). Corps de texte ≥ 14 px réels sur mobile
  (≥ 17 px en conception). Boutons ≥ 58 px de conception, et toutes les actions au-dessus du bouton de saut.
- **Zones de sécurité** : le HUD n'entre jamais dans les 5 % d'insets système ni sous le CoreGui.
- **Densité variable, structure constante** : les coins et les positions sont fixes sur les 3 formats ;
  seul le contenu secondaire se replie. Exemple : le revenu/s reste permanent sur PC, se replie
  sous les pièces sur petit écran. **Arbitrage à valider par D.**
- **Vérification obligatoire** : les 4 formats au Device Emulator avant chaque capture.

---

## 5. Hiérarchie d'information du HUD

Principe : **le joueur ne lit pas l'interface, il la survole en courant.** Ordre de lecture décroissant :

1. **La menace, maintenant** — direction de la vague + compte à rebours. Boussole et bandeau
   en haut, seuls éléments qui pulsent. C'est la seule zone « urgence » du HUD.
2. **L'urgence en cours** — vol (flèche + maintien), Marée Royale, bouclier. N'apparaît que
   quand ça te concerne, puis disparaît. Jamais deux urgences simultanées.
3. **Ma progression** — pièces + revenu/s en haut-gauche, objectif suivant (« Next: Slots 2 — 165 »).
   C'est le moteur de retour ; l'objectif est **toujours** visible (bible §8).
4. **Mon outil** — sac (remplissage) et accès lagon en haut-droite. Mon « où j'en suis ».
5. **Mes actions** — barre en bas-droite, toujours au même endroit, au pouce.
6. **Le transient** — toasts (3 max) et labels de monde. Se fait, s'efface, ne pollue pas.

Règles :
- **5 éléments persistants maximum** à l'écran (HUD minimal, bible §5). Le reste est sur ouverture.
- **Un seul chiffre bouge en continu** : les pièces. Le revenu défile lentement, il ne clignote pas.
- **Une seule couleur d'urgence** : le rouge de la vague, réservé. Aucune autre alerte ne l'emprunte.
- **Rien de clignotant** au-delà de 3 fois/s, et rien du tout si « réduire les animations ».

---

## 6. Ce dont j'ai besoin

### 6.1 Du GDD — presque plus rien (il est écrit)
1. **Confirmation que v3 est gelé pour la Phase 1.** C'est la seule chose qui me bloque vraiment :
   je conçois §12, mais je dois savoir que §12 ne bouge plus pendant que je construis.
2. **Espèces et stades définitifs** : les 3 noms de Phase 1 et leur ordre de rareté — pour la fiche
   créature et les badges. Les ids v3 existent déjà côté A.
3. **Arbitrage Codex** : §12 le met hors Phase 1, §5.4 le décrit en détail et §11 ne le liste pas
   pour B. Je le réserve, je ne le dessine pas — mais qu'on tranche.
4. **Deep Dive** : §9 bis et `TABLEAU.md` le placent en semaine 2. Je ne mets donc **pas** de bouton
   DIVE dans le HUD de Phase 1. Confirmation attendue.

### 6.2 D'autres fichiers — plus urgent que le GDD
5. **Le jeu d'icônes** — *le vrai trou de la vague 0*. DIRECTION_V2 interdit les emoji et exige un
   style cohérent ; le dépôt n'a **aucun asset d'icône**. Il faut trancher : import Creator Store sous
   licence, ou atlas dessiné par B. Sans décision, la vague 0 ne peut pas finir.
6. **La police condensée** — DIRECTION_V2 cite Barlow Condensed « ou équivalent, sous licence ».
   Roblox n'embarque pas de condensée acceptable. À valider par D (licence + coût).
7. **Contrat v2.1 figé par A** (P1-15) : forme exacte de `StartSteal`, `Mount(nil)`, `ChoosePick`,
   `shop.randomAllowed`, et la liste des payloads `Notify`. Sans ça je code des hypothèses.
8. **`Config.Shop` + les RF de A** (P1-08, P1-13) : la boutique ne peut pas fonctionner avant.
9. **Modèles de créatures de C** (P1-20/21/22, en cours) : sans eux, pas d'icônes définitives ni
   de billboards crédibles. Je peux poser la structure, pas le contenu.
10. **ids de gamepasses** (Moaad, Creator Hub) : les prix sont dans le GDD §9, les ids sont à 0.
    La boutique s'affiche, l'achat non, tant que ce n'est pas fait.

### 6.3 Une décision que je prends et veux faire confirmer
Je **ne touche à aucun `Config` ni `Remotes`** (zone de A). Tout ce dont j'ai besoin du contrat passe
par une demande `[R-xx]`, et toutes les hypothèses provisoires restent regroupées dans `Store`
comme le veut `UI_REEF.md` §7 — mais réécrites contre la v2.1, pas contre mes suppositions.

---

## 7. Ce que je m'engage à respecter

- Zéro réemploi de l'UI actuelle : ni emoji, ni Luckiest Guy, ni brique existante.
- DIRECTION_V2 avant la bible : plaques sombres translucides, coins 6–10 px, condensée, MAJUSCULES espacées.
- Interface en **anglais**, verbes d'action courts (CATCH, STEAL, RIDE, SURVIVE, SURF).
- Rareté et mutation = **couleur + icône + nom**, jamais la couleur seule.
- Tout en 2 taps max · retour visuel < 0,1 s · aucun pavé de texte · aucun pavé de menu.
- Notifications : 3 max, priorité vague > récompense > info.
- Option « réduire les animations » respectée partout, y compris le HUD de vol.
- Les 4 formats vérifiés au Device Emulator avant chaque capture de validation.

---

## 8. Verdict

Le GDD n'est pas le blocage : il est écrit, complet, et §12 me donne un périmètre net.
Le blocage réel est **le jeu d'icônes et la police** (vague 0), puis **le contrat v2.1 de A** (vague 1).

Je peux démarrer la **vague 0** dès ton feu vert : elle ne dépend que de DIRECTION_V2 et d'une
décision sur les icônes. La vague 1 attend la v2.1 figée. La vague 2 attend les modèles de C.

Deux points à arbitrer avant que je commence : le **décalage de l'intro 30 s en vague 1** (§2.1)
et le **retrait de `UI_REEF.md`** de la circulation (§0.3).
