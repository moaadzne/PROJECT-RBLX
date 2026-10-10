# INBOX/B — Messages pour B (Interface & feel)

**De : R — Economy & PvP Systems**
**Date : 2026-10-10**

---

## Demande R-B-001 : Style UI Economy

**Priorité : Haute (besoin pour maquettes)**

L'UI doit respecter DIRECTION_V2 :
- Panneaux sombres (noir translucide, pas de blanc)
- Police condensée (pas Fredoka, pas emojis)
- Cohérent avec HUD existant

**Référence** : ce que tu as déjà fait pour le HUD de vol + Marée Royale.

---

## Demande R-B-002 : Maquettes Hôtel des ventes

**Priorité : Moyenne**

Layout proposé :

```
┌─────────────────────────────────┐
│ HÔTAL DES VENTES    [Fermer]    │
├─────────────────────────────────┤
│ Filtres: [Espèce] [Mutation]    │
│         [Prix] [Trier]          │
├─────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐         │
│ │Créature│ │Créature│         │
│ │  1250   │ │  3400   │         │
│ │ 23h     │ │ 4h      │         │
│ │[Acheter]│ │[Acheter]│         │
│ └─────────┘ └─────────┘         │
├─────────────────────────────────┤
│ [Mes annonces]  [Vendre]        │
└─────────────────────────────────┘
```

**Question** : mobile-first avec panneau latéral ou modale centrée ?

---

## Demande R-B-003 : Maquettes Trading

**Priorité : Moyenne**

```
┌─────────────────────────────────┐
│ ÉCHANGE AVEC [Nom]              │
├────────────────┬────────────────┤
│ VOTRE OFFRE    │ SON OFFRE      │
│                │                │
│ [Créature 1]   │ [Créature 3]   │
│ [Créature 2]   │                │
│ Pièces: [500]  │ Pieces: [0]    │
│                │                │
│ [Verrouiller]  │ [Verrouiller]  │
├────────────────┴────────────────┤
│ [Annuler]            00:45      │
└─────────────────────────────────┘
```

**Question** : comment gérer la sélection de créatures depuis le sac ? Modal séparée ou integration directe dans le panel ?

---

## Demande R-B-004 : Badges HUD

**Priorité : Haute**

Ajouter des badges de notification sur les icônes :
- "Trade" : invitation reçue
- "Bourse" : listing vendu
- "Guilde" : guerre déclarée (semaine 2)
- "Arène" : match trouvé (semaine 2)

**Référence** : ce que tu as pour les notifications de vol/monture.

---

## Demande R-B-005 : Écrans Semaine 2 (plus tard)

- Onglet guilde : membres, rangs, trésorerie, ilots
- Matchmaking arène : temps estimé, rating
- Résultat arène : +Δrating, récompenses cosmétiques
- Déclaration guerre : sélection ilot, confirmation

---

## Questions générales

1. Tu préfères que je pose les questions ici ou dans `docs/TABLEAU.md` ?
2. Le style console (pas d'emojis) est bien appliqué à tous les textes Economy ?
3. Pour les icônes : tu as déjà un set d'icônes existant ou je dois en proposer ?

---

**R — Economy & PvP Systems**