# LORE_EVENTS — Événements Mondiaux de l'Archipel des Marées

**Auteur : O (Story & Lore Lead). Écrit le 2026-10-10.**
Aligné sur : DIRECTION_V2, GDD_REEF, DECISIONS_MARCHE.md §9, LORE_ARCHIPEL.md, LORE_PNJ.md.

---

## 1. VISION ÉVÉNEMENTS

Les événements mondiaux ne sont pas des quêtes : ce sont des **moments où l'archipel entier retient son souffle**. Tous les joueurs la voient en même temps. Elle change le monde, puis le rend — différent.

**Ton** : cool, intense, premium. Pas enfantin. Zéro emoji. Capitales condensées. Visuel narratif.

---

## 2. L'ÉVEIL DU LÉVIATHAN — Raid 20 joueurs

### 2.1 Identité

| Attribut | Valeur |
|---|---|
| **Phase** | Phase 3 (semaine 6-8) |
| **Type** | World Boss hebdomadaire, Raid 20 joueurs |
| **Boss** | Léviathan, forme éveillée (basée sur la mécanique WhaleShark Titan) |
| **Déclenchement** | Marée Royale active + 5 joueurs rang 3+ présents au même cycle |
| **Fréquence** | Hebdomadaire, après Marée Royale, au créneau serveur |

### 2.2 Déclenchement narratif

La gravure de l'épave est l'indice planté depuis la Phase 1 :

> **"Quand la mer recule, l'ancien roi revient.
> La marée extrême révèle ce qu'elle a prise."**

L'empreinte lumineuse au sol pulse au rythme des marées. Quand les conditions sont réunies, elle s'illumine. La mer se retire **plus loin qu'elle n'a jamais été**. Le récif apparaît en entier. Le sol tremble. La cinématique démarre.

### 2.3 Cinématique serveur-synchro (3 min)

| Temps | Image | Son |
|---|---|---|
| 0:00-0:20 | La mer se retire anormalement. Le récif entier apparaît. Les joueurs se figent. | Silence total. Juste le vent. |
| 0:20-0:45 | Le sol tremble. Des fissures de lumière dorée apparaissent dans le ciel. | Grondement sourd, dans les basses. |
| 0:45-1:30 | L'eau au large **se soulève**. Une ombre colossale monte. | Une note grave unique. Notre "horn". |
| 1:30-2:10 | Le Léviathan émerge partiellement. Tête, avant-corps, œil doré. | Océnan qui gronde. Des échos sonores du chapitre 9. |
| 2:10-2:30 | Il ouvre la gueule. La vague titanesque se prepare. | Montée de tension. Musique épique. |
| 2:30-3:00 | La vague frappe. Retour caméra sur les joueurs, prêts à combattre. | Impact. Silence. Puis la phase combat. |

**Replay system** : enregistrement automatique, camera libre, export vidéo (S).

### 2.4 Combat — 3 phases

**Phase 1 — ÉVEIL (100% → 70% PV)**
- Léviathan est lent, confus. Il teste les joueurs.
- Mécanique : la queue balaie la zone — éviter par positioning
- Mécanique : appels de Manta Rays messagères (DPS check)

**Phase 2 — COLÈRE (70% → 30% PV)**
- Le Roi est pleinement éveillé. Il est rapide, violent.
- Mécanique : coordination — 3 groupes (distraction / soin / DPS)
- Mécanique : vagues de serviteurs (GiantPacificOctopus, LionsManeJelly)
- Mécanique : enrage timer 15 min

**Phase 3 — REPOS (30% → 0% PV)**
- Le Roi ralentit. Il est vulnérable. Il semble attendre quelque chose.
- Mécanique : DPS maximal, fenêtre courte
- Mécanique : choix final — **COMBATTRE / RAISONNER / LIBÉRER** (impacte la fin)

### 2.5 Récompenses

**AUCUNE PUISSANCE.** Tout cosmétique + matériaux craft.

| Récompense | Type | Source |
|---|---|---|
| **Skin "Éveil Léviathan"** | Mount skin | 1 par combat, aléatoire |
| **Trail "Cœur Abyssal"** | Trail cosmétique | 10% drop |
| **Titre "RÉVEILLEUR"** | Titre affiché | Tous les participants |
| **Wings "Ailes du Roi"** | Ailes cosmétiques | 5% drop, rare |
| **Matériaux légendaires** | Craft | Répartis selon rôle |

### 2.6 Alignement technique

- **DECISIONS_MARCHE.md §9** : World Boss 20 joueurs, mécaniques complexes, pas "tank & spank"
- **GDD_REEF** : Marée Royale, Marée Extrême, Récif Noyé comme terreau
- **Contrat v2.1** : `WaveState.royal`, `WaveState.extreme`, `RoyalBoard` comme base
- **Zéro P2W** : cosmétiques uniquement

---

## 3. LA MARÉE NOIRE — PvP zones contestées

### 3.1 Identité

| Attribut | Valeur |
|---|---|
| **Phase** | Phase 4 (semaine 9-10) |
| **Type** | PvP zone, guerre de guildes, contrôle territorial |
| **Zones** | 3 îlots contestés (Nord, Est, Ouest) |
| **Fréquence** | Toutes les 10 min, rotation des îlots toutes les 30 min |
| **Participants** | Guildes, max 2 par îlot |

### 3.2 Déclenchement narratif

La Marée Noire est la **conséquence** de l'agitation du Roi. Après chaque Éveil du Léviathan, la mer devient noire pendant un temps. C'est une période de chaos : les règles normales tombent, les ressources rares apparaissent, et les guildes se battent pour le contrôle.

**Texte d'annonce** (style console) :
```
+--------------------------------------------------+
|  MARÉE NOIRE                                     |
|  Les règles tombent. Les ressources apparaissent. |
|  Contrôle territorial actif.                     |
|  [ ALLER AU COMBAT ]                             |
+--------------------------------------------------+
```

### 3.3 Mécaniques

| Mécanique | Description |
|---|---|
| **Drapeau capturable** | Capturer et tenir le drapeau 30 s pour prendre le contrôle |
| **Renforts vagues** | Vagues de PNJ hostiles toutes les 2 min, pillent et attaquent |
| **Marée Noire** | Toutes les 10 min, la zone PvP s'étend, l'eau inflige des dégâts |
| **Contrôle territorial** | Guilde victorieuse : droits d'exploitation 1 h + butin partagé |

### 3.4 Récompenses

**AUCUNE PUISSANCE.** Tout cosmétique + avantages économiques temporaires.

| Récompense | Type | Source |
|---|---|---|
| **Skin "Marée Noire"** | Creature skin | Butin partagé |
| **Mount "Requin Ombre"** | Mount skin | 1 parGui victorieuse |
| **Emote "Marque Noire"** | Emote | Tous les participants |
| **Taxe hotel -2%** | Avantage guilde | 1 h, guilde victorieuse |
| **Ressources rares** | Économie | Contrôle territorial |

### 3.5 Alignement technique

- **DECISIONS_MARCHE.md §4** : PvP zones, ressources rares, contrôle guilde
- **GDD_REEF** : Vol = interaction sociale, pas PvP toxique
- **R (Economy)** : hôtel ventes 5% taxe, taxe -2% = avantage économique, pas puissance
- **U (Guild)** : Guild Hall, guerres, calendrier
- **Zéro P2W** : cosmétiques + avantages temporaires uniquement

---

## 4. SYNTHÈSE TEMPORELLE

| Phase | Semaine | Événement | Type |
|---|---|---|---|
| **Phase 2** | 3-5 | Campagne Chapitres 1-3 | PvE narratif |
| **Phase 2** | 3-5 | Marée Royale | Classement, déjà codé |
| **Phase 2** | 3-5 | Marée Extrême | Découverte récif, déjà codé |
| **Phase 3** | 6-8 | **ÉVEIL DU LÉVIATHAN** | Raid 20j, cinématique |
| **Phase 3** | 6-8 | Donjons 5j (3 diff) | PvE instancié |
| **Phase 4** | 9-10 | Arènes classées 1v1/2v2/3v3 | PvP compétitif |
| **Phase 4** | 9-10 | **MARÉE NOIRE** | PvP territorial |

---

## 5. ALIGNEMENT TECHNIQUE

### 5.1 Contrat v2.1 existant

- **WaveState** : `royal = {active, endsAt}`, `extreme = {active, revealAt, endsAt}`
- **RoyalBoard** : `board = {cycle, endsAt, top}`, tous les joueurs
- **Notify** : `royal`, `extreme` pour les annonces

### 5.2 DataStore v3 (proposition)

```lua
state.leviathanAttempts = { count, lastWin, lastParticipation }
state.mareeNoireWins = { [guildId] = wins }
state.cinematicSeen = { leviathan_awakening = true }
state.eventRewardsClaimed = { "leviathan_skin", "maree_noire_mount" }
```

### 5.3 Interface (B)

- **Bannière serveur-synchro** : tous les joueurs la voient en même temps
- **Timer d'enigme** : compte à rebours visible pendant cinématique
- **Replay indicator** : enregistrement automatique actif
- **Zéro emoji**, capitales condensées, RobotoCondensed

---

## 6. RÉFÉRENCES

- `docs/LORE_ARCHIPEL.md` — monde, chapitres, Léviathan, Malédiction
- `docs/LORE_PNJ.md` — Gardien, Marchand, Orpheline, dialogues, choix
- `docs/DECISIONS_MARCHE.md` §9 — PIVOT MAJEUR, 5 piliers
- `docs/DIRECTION_V2.md` — ton, style, public
- `review/review_context.md` — contrat v2.1

---

*Écrit par O le 2026-10-10. Si une valeur de ce document et `Config.lua` divergent, **Config gagne**.*
