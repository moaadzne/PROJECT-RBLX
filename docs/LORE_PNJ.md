# LORE_PNJ — Personnages Non-Joueurs de l'Archipel des Marées

**Auteur : O (Story & Lore Lead). Écrit le 2026-10-10.**
Aligné sur : DIRECTION_V2, GDD_REEF, LORE_ARCHIPEL.md, contrat v2.1.

---

## 1. VISION PNJ

Trois personnages portent la mémoire du monde. Ils ne sont pas des quêtes à prendre : ils sont des **relations** qui se construisent, se fissurent, ou se brisent selon les choix du joueur. Chacun représente une voie possible devant le Léviathan — l'ordre, la puissance, la liberté.

**Ton** : cool, intense, premium. Pas enfantin. Zéro emoji. Capitales condensées. Verbes d'action (ÉCOUTER, CHOISIR, TRAHIR).

---

## 2. LES 3 PNJ MÉMORABLES

### 2.1 LE GARDIEN DES MARÉES

| Attribut | Valeur |
|---|---|
| **Forme** | HawksbillTurtle Elder/Titan, grande taille, carapace couverte de corail et de berniques |
| **Âge apparent** | Plusieurs siècles. Il croit être le dernier de son espèce. |
| **Voix** | Grave, lente, sans urgence. Chaque phrase est une sentence. |
| **Lieu** | Le phare de la Crique Centrale (Île de la Crique) |
| **Apparition** | Dès le chapitre 1, à la rencontre du joueur |
| **Rôle narratif** | Mémoire vivante de l'archipel. Il a vu le Roi s'endormir. Il a vu la malédiction s'installer. Il attend. |

**Le Gardien ne donne pas de quêtes : il donne des vérités.** Le joueur vient le voir, et il parle — de l'ancien temps, de la première vague, du Roi. Il ne demande rien. Il constate.

**Dialogues branchés** (choix persistants `state.choices["gardien"]`) :

| Choix | Réputation | Conséquence |
|---|---|---|
| **PROTÉGER** | Gardien +25 | Accès au phare (abri + bibliothèque secrète). Le Gardien apprend au joueur à lire les glyphes. |
| **OBSERVER** | Gardien +0 | Le Gardien reste neutre. Le joueur voit le phare de loin, jamais à l'intérieur. |
| **EXPLOITER** | Gardien -40 | Le Gardien se ferme. Le joueur peut piller le phare, mais perd son soutien final. |

**Fin Gardien** (chapitre 10) : si réputation > 50, le Gardien se sacrifie pour contenir la vague. Sa carapace devient le sceau de la marée.

---

### 2.2 LE MARCHAND D'ÉCAILLES

| Attribut | Valeur |
|---|---|
| **Forme** | Humanoïde encapuchonné, visage masqué par une coquille d'ormeau. Toujours souriant. |
| **Âge apparent** | Impossible à dire. Il a toujours été là. |
| **Voix** | Rapide, cynique, financière. Il chiffre tout, même les émotions. |
| **Lieu** | Itinérant. Apparaît sur la plage pendant les marées Golden (chapitre 4, 6) |
| **Apparition** | Chapitre 4, première marée Golden du joueur |
| **Rôle narratif** | Courtier du secret. Il vend ce qu'il sait — et achète ce que le joueur trouve. Rien n'est gratuit. |

**Le Marchand ne vend pas des objets : il vend des réponses.** Chaque échange est un marché. Chaque information a un prix (pièces, items lore, ou un choix).

**Dialogues branchés** (choix persistants `state.choices["marchand"]`) :

| Choix | Réputation | Conséquence |
|---|---|---|
| **ÉCHANGER** | Marchand +25 | Prix réduits au shop (10%). Accès aux contrats et items exclusifs. |
| **VOLER** | Marchand -50 | Le Marchand s'en souvient. Prix doublés. Il peut voler en retour. |
| **PROTÉGER** | Marchand +10 | Le Marchand respecte. Il révèle des secrets que les autres ne vendent pas. |

**Fin Marchand** (chapitre 10) : si réputation > 50, le Marchand offre son trésor — la carte complète de l'archipel, révélant chaque îlot, chaque cache. Le pouvoir par la connaissance.

---

### 2.3 L'ORPHELINE DU RÉCIF

| Attribut | Valeur |
|---|---|
| **Forme** | Enfant, 8-10 ans, peau couverte d'écailles nacrées, yeux entièrement dorés |
| **Origine** | Seule survivante du naufrage de l'Épave (chapitre 4). Trouvée par les Cushion Stars. |
| **Voix** | Douce, fragile, mais chargée d'une autorité étrange. Elle parle aux créatures. |
| **Lieu** | Le Récif Noyé (Île du Récif), apparaît quand la marée se retire |
| **Apparition** | Chapitre 5, première marée extrême du joueur |
| **Rôle narratif** | Le lien vivant entre les créatures et le Roi. Elle sait ce que le Léviathan veut. Elle est la clé. |

**L'Orpheline parle à la place des créatures.** Elle ne demande pas au joueur de parler — elle traduit. Le joueur écoute le récif à travers elle.

**Dialogues branchés** (choix persistants `state.choices["orpheline"]`) :

| Choix | Réputation | Conséquence |
|---|---|---|
| **ÉCOUTER** | Orpheline +30 | Elle guide le joueur vers la Perle (chapitre 7). Mutation Abyssal débloquée. |
| **IGNORER** | Orpheline 0 | Elle s'éloigne. Le récif reste secret. |
| **TRAHIR** | Orpheline -60 | Elle fuit. Le récif se ferme au joueur. Le Gardien la protège à sa place. |

**Fin Orpheline** (chapitre 10) : si réputation > 40, l'Orpheline emmène le joueur au cœur du Léviathan et libère le Roi — pas pour le tuer, mais pour le laisser partir. La liberté.

---

## 3. DIALOGUES BRANCHÉS — FORMAT CONSOLE

### 3.1 Règles de style (DIRECTION_V2)

- **Verbes courts** : ÉCOUTER, CHOISIR, TRAHIR, RÉPONDRE, TAIRE
- **2 à 5 mots** par option visible
- **Capitales condensées** pour les actions
- **Zéro emoji**, zéro point d'exclamation, pas de "Yay!"
- **Police** : RobotoCondensed (B)

### 3.2 Exemple — Rencontre du Gardien (Chapitre 1)

```
+--------------------------------------------------+
|  GARDIEN DES MARÉES                              |
|                                                  |
|  "Tu arrives avec la vague.                       |
|   Tu partiras avec quoi ?"                        |
|                                                  |
|  [ RÉPONDRE ]                                     |
|  [ TAIRE ]                                        |
|  [ OBSERVER ]                                     |
+--------------------------------------------------+
```

### 3.3 Exemple — Marchand (Chapitre 4)

```
+--------------------------------------------------+
|  MARCHAND D'ÉCAILLES                             |
|                                                  |
|  "Une époque pour un secret.                      |
|   Lequel te manque ?"                             |
|                                                  |
|  [ ÉCHANGER ]   750 coins — Glyphe de la Vague    |
|  [ ACHETER ]     250 coins — Carte Nord           |
|  [ VOLER ]       (risque: réputation -50)         |
|  [ PARTIR ]                                     |
+--------------------------------------------------+
```

### 3.4 Exemple — Orpheline (Chapitre 5)

```
+--------------------------------------------------+
|  ORPHELINE DU RÉCIF                              |
|                                                  |
|  "Ils chantent. Tu entends ?                      |
|   Le Roi rêve encore."                            |
|                                                  |
|  [ ÉCOUTER ]                                     |
|  [ IGNORER ]                                     |
|  [ TRAHIR ]                                      |
+--------------------------------------------------+
```

---

## 4. 100+ QUÊTES ANNEXES

### 4.1 Répartition

| Île | Quêtes | Types |
|---|---|---|
| Crique | 15 | Tutoriel, protection, exploration, artisanat |
| Ruines | 20 | Investigation, collecte, énigmes, glyphes |
| Épave | 20 | Récupération, commerce, plongée, secrets |
| Récif | 20 | Nettoyage, observation, protection, contamination |
| Léviathan | 15 | Endgame, survie, cosmétiques, prestige |
| Îlots | 10 | PvP Marée Noire, ressources rares, contrôle |

### 4.2 Types de quêtes

| Type | Description | Récompenses typiques |
|---|---|---|
| **Exploration** | Trouver un lieu, découvrir un Codex lore | XP, pièces, entrée lore |
| **Collecte** | Ramener X créatures / ressources | Pièces, items craft |
| **Protection** | Défendre une zone / créature pendant une vague | Réputation PNJ, XP |
| **Investigation** | Lire journaux, écouter échos, résoudre énigmes | Entrées lore, items |
| **Commerce** | Échanger avec le Marchand | Items exclusifs, skins |
| **Investigation** | Observer, analyser, comprendre | XP, Codex lore |

### 4.3 Conséquences persistantes

- **Réputation PNJ** : -100 à +100 par PNJ (DataStore `state.reputation`)
- **Accès zones** : débloqué / fermé selon réputation
- **Items lore** : obtenus et conservés
- **Dénouement chapitre 10** : 3 fins selon réputation globale

---

## 5. ALIGNEMENT TECHNIQUE

### 5.1 Contrat v2.1

- **Notify** : `codex`, `capture`, `deposit`, `grown` déclenchent des dialogues PNJ
- **State** : `intro`, `golden`, `done`, `codexCount`, `codexTotal`
- **WaveState** : `tide` (Golden → Marchand), `extreme` (Orpheline)

### 5.2 DataStore v3 (proposition)

```lua
state.choices = {
  gardien = "proteger",      -- "proteger" | "observer" | "exploiter"
  marchand = "echanger",     -- "echanger" | "voler" | "proteger"
  orpheline = "ecouter",     -- "ecouter" | "ignorer" | "trahir"
}
state.reputation = {
  gardien = 25,              -- -100..100
  marchand = 0,
  orpheline = 0,
}
state.questLog = {
  { questId = "chap1_gardien", stage = 2, choices = { "repondre" } },
}
```

### 5.3 Interface (B)

- `DialogueUI.lua` : panneaux sombres translucides, coins peu arrondis
- Options cliquables ≥ 44px (mobile) / 48dp (Android)
- RobotoCondensed, capitales condensées pour les actions
- Zéro emoji, icônes pleines ou au trait (Font Awesome fallback)

---

## 6. RÉFÉRENCES

- `docs/LORE_ARCHIPEL.md` — monde, chapitres, géographie
- `docs/LORE_EVENTS.md` — Éveil Léviathan, Marée Noire
- `docs/DIRECTION_V2.md` — ton, style, public
- `docs/GDD_REEF.md` — roster, marées, zones, Codex
- `review/review_context.md` — contrat v2.1

---

*Écrit par O le 2026-10-10. Si une valeur de ce document et `Config.lua` divergent, **Config gagne**.*
