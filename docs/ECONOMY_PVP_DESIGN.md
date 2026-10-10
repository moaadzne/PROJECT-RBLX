# ECONOMY_PVP_DESIGN — Spécification détaillée R (Economy & PvP Systems)

**Auteur : R — Economy & PvP Systems. Écrit le 2026-10-10.**
**Base : contrat v2.1 (review_context.md), GDD v2, GDD_REEF.md (E), DIRECTION_V2, DECISIONS_MARCHE.md.**
**Statut : Proposition pour validation D. Rien n'est codé tant que D n'a pas validé le périmètre Phase 1.**

---

## 0. Cadre et non-cadre

### Dans la Phase 1 (sous réserve décision D)
- Hôtel des ventes (taxe 5 %)
- Trading direct joueur-à-joueur (créatures + pièces)
- Anti-RMT Phase 1 : logs, compteurs, patterns simples, restriction

### Hors Phase 1 (Semaine 2+)
- Zones PvP ilots contestés
- Arènes classées 1v1/2v2/3v3 (saisons, cosmétiques only)
- Guerres de guilde (sièges, ressources, contrôle ilots)
- Taxes guilde/royaume
- Anti-RMT avancé (ML, appeal)

### Jamais (sans décision explicite de Moaad)
- P2P payant (argent réel contre Robux)
- Lootbox payante sans probabilités affichées
- Objets de puissance en récompense d'arène

---

## 1. Hôtel des ventes (Marketplace)

### 1.1 Règles économiques
- Taxe **5 %** prélevée à la vente (pas à la mise en vente)
- Prix libre, mais fourchette affichée (médiane × 0,3 à × 3) comme guide
- Durée d'annonce : 24 h, renouvelable
- Max 20 annonces actives par joueur
- Pas de "snipe" : achat direct à l'annonce, pas d'enchère

### 1.2 Modèle de données
```lua
listings = {
  [listingId] = {
    sellerId, sellerName,
    creature = {uid, species, mutation, born, stage, income, mounted = false},
    price, -- pièces
    listedAt, expiresAt,
  }
}
```

### 1.3 Processus
1. `ListCreature(uid, price)` : retire créature du bassin (pool), pose listing
2. `BuyListing(id)` : acheteur paie price + taxe 5 %, reçoit créature, vendeur reçoit price
3. `CancelListing(id)` : créature retourne au bassin du vendeur
4. Expiration auto à 24 h : créature retourne au bassin, pas de taxe

### 1.4 Anti-abus
- Pas de listing si créature montée ou portée
- Prix minimum = revenu créature × 10
- Cooldown 60 s entre listings du même joueur
- Logs DataStore `EconomyLogs` : chaque transaction horodatée

---

## 2. Trading direct

### 2.1 Règles
- Échange atomique : les deux joueurs valident, tout ou rien
- Contrepartie : créatures + pièces des deux côtés
- Cooldown 30 s entre trades du même joueur
- Pas de trade si l'un des deux est en protection débutant
- Pas de trade pendant une alerte/vague (sauf entre joueurs de même guilde, semaine 2)

### 2.2 Processus
1. `TradeRequest(target)` : crée session, envoie invitation
2. `TradeOffer(tradeId, offer)` : chaque joueur compose son offre (créatures du sac, pièces)
3. Les deux offres visibles en temps réel ; bouton "Verrouiller" pour valider son côté
4. Quand les deux ont verrouillé : `TradeAccept` → transfert atomique
5. Timeout 120 s → cancel automatique

### 2.3 Sécurité
- Rollback en cas d'erreur : état restauré des deux côtés
- Pas de duplication : créatures verrouillées pendant le trade
- Logs : partenariat, items échangés, pièces, horodatage

---

## 3. Anti-RMT Phase 1

### 3.1 Compteurs journaliers (par joueur, reset minuit UTC)
- `dailyTradeCount` : nombre de trades
- `dailyTradeVolume` : total pièces échangées (achats + ventes)
- `dailyListingCount` : nombre de mises en vente

### 3.2 Seuils d'alerte
| Seuil | Action |
|---|---|
| > 50 trades/jour | Flag "high_frequency" |
| > 100 000 pièces/jour | Flag "high_volume" |
| Trade unique > 50 000 pièces | Flag "high_value" |
| Même partenaire > 5 fois/jour | Flag "circular_trading" |

### 3.3 Action
- 3+ flags simultanés → `restricted = true` : trades et listings bloqués
- Alerte admin (webhook Discord ou Notification Roblox)
- Log complet : joueur, flags, action, horodatage
- Restriction levée manuellement par admin (ou après 24 h si pas de réponse)

### 3.4 Ce qui n'est PAS en Phase 1
- ML / détection de patterns complexes
- Système d'appeal automatique
- Ban automatique (toujours manuel)

---

## 4. Zones PvP ilots contestés (Semaine 2)

### 4.1 Concept
- 3 ilots autour de l'île principale : NE, SE, SW
- Chaque ilot a 3 points de contrôle (A, B, C)
- Une guilde qui tient 2/3 points pendant 5 minutes capture l'ilot
- Contrôle = bonus ressources (+15 % revenus passifs) + accès nœuds rares
- 1 seul ilot contrôlé par guilde (évite monopole)

### 4.2 Ressources rares
| Ressource | Spawn | Usage |
|---|---|---|
| Perles abyssales | 1/h/ilot | Amélioration guilde |
| Corail ancien | 2/j/ilot | Craft cosmétique |
| Écailles Titan | 1/j/ilot | Upgrade monture cosmétique |

### 4.3 Règles PvP
- Pas de perte de sac en mourant dans un ilot (retour zone safe)
- Pas de vol dans les ilots (zone neutre)
- Dégâts normalisés (pas d'objets de puissance, base égale)
- Cooldown entrée/sortie ilot : 10 s

---

## 5. Arènes classées (Semaine 2)

### 5.1 Modes
- **1v1** : duel direct, premier à 3 manches ou timer 3 min
- **2v2** : équipe aléatoire ou duo de guilde
- **3v3** : équipe aléatoire ou tribu de guilde

### 5.2 Matchmaking
- Elo simplifié : rating de base 1000, K = 32
- Recherche dans une plage de ±200 rating, élargie si > 2 min
- Cross-server via TeleportService (si possible) ou même serveur seulement
- File d'attente visible avec temps estimé

### 5.3 Saisons
- 6 saisons/an, 2 semaines chacune
- Réinitialisation partielle : rating ramené à la médiane (1500)
- Récompenses fin de saison :
  - Top 100 : titre "Légende du Récif" + skin exclusif
  - Top 1000 : titre "Gardien" + emote
  - Participation : 10 cosmétiques aléatoires

### 5.4 Cosmétiques only
- Aucune récompense de pièces ou d'objets de puissance
- Récompenses : skins créatures, titres, emotes, trails
- Aligné décision Moaad 09/10

---

## 6. Guerres de guilde (Semaine 2)

### 6.1 Structure guilde
- Création : 10 000 pièces, tag unique 3-4 lettres
- Max 50 membres, 4 rangs : Leader, Officer, Member, Recruit
- Trésorerie commune : alimentée par taxes (3 % ventes membres) + butin guerres

### 6.2 Déclaration de guerre
- Leader déclare guerre à une autre guerre (ratification 24h)
- Cooldown : 1 guerre active par guilde, max 3 guerres simultanées sur le serveur
- Annonce publique : "La guerre entre [GuildA] et [GuildB] commence dans 24h"

### 6.3 Siège de base
- Fenêtre quotidienne de 4 heures (configurable)
- Attaquant : doit détruire 3 points de défense de la base adverse
- Défendeur : doit tenir au moins 1 point à la fin
- Victoire : contrôle d'un ilot ou transfert de 20 % trésorerie
- Défaite : pas de pénalité, juste pas de gain

### 6.4 Taxes
- **Taxe guilde** : 3 % sur ventes hôtel des ventes des membres → trésorerie
- **Taxe royaume** : 2 % sur tous les revenus passifs → trésorerie royaume (virtuel, sert au funding des récompenses saison)

---

## 7. Interface utilisateur (B implémente)

### 7.1 HUD Economy
- Icône "Bourse" dans HUD principal
- Badge notifications : trade reçu, listing vendu, guerre déclarée
- Accès rapide : "Mes annonces", "Trades en cours"

### 7.2 Hôtel des ventes
- Panel latéral (mobile) / modale (PC)
- Filtres : espèce, mutation, stade, prix min/max
- Tri : prix croissant/décroissant, plus récent
- Détail annonce : stats créature, temps restant, vendeur
- Achat : confirmation avec taxe affichée

### 7.3 Trading
- Invitation : toast "X vous propose un échange"
- Panel 2 colonnes : votre offre / offre partielle
- Sélection créatures depuis le sac (pas les bassins)
- Champ pièces : saisie avec validation
- Boutons : Verrouiller, Annuler, Refuser

### 7.4 Guilde / Guerres / Arènes (Semaine 2)
- Onglet dédié dans HUD
- Guilde : membres, rangs, trésorerie, ilots
- Guerres : déclaration, état sièges, historiques
- Arènes : queue, rating, saison, récompenses

---

## 8. Coordination technique

| Sujet | Avec | Question ouverte |
|---|---|---|
| Noms Remotes | A | Suivre nomenclature v2.1 existant |
| Codes erreur | A | Ajouter codes "Economy.*" ou réutiliser génériques ? |
| Config.Economy | A | Où dans Config.lua ? Section séparée ou dans Config ? |
| UI events | B | Utiliser RemoteEvent dédiés ou Notify ? |
| Positions ilots/arènes | C | Format Center + Radius comme les lagons ? |
| Maps arènes | C | Models à créer par C ou assets existants ? |
| Design récompenses | E | Lore + skins cosmétiques pour arènes ? |
| Validation périmètre | D | Phase 1 = quoi exactement ? |

---

## 9. métriques de succès (post-launch)

| Métrique | Cible | Pourquoi |
|---|---|---|
| Volume trades/jour | > 30 % joueurs actifs | Économie vivante |
| Prix moyen créature | Stable ±20 % | Pas d'inflation |
| Temps matchmaking arène | < 60 s (1v1) | Rétention PvP |
| Guerres déclarées/semaine | > 5 | Engagement guilde |
| Faux positifs Anti-RMT | < 1 % | Confiance joueurs |

---

## 10. Questions pour D (décision requise)

1. **Phase 1 exact** : hôtel ventes + trading direct + anti-RMT minimal = périmètre confirmé ?
2. **Guildes en Phase 1** : oui/non ? Si oui, simplifié (chat + liste) ou complet ?
3. **Arènes Phase 1** : oui/non ? Si oui, même serveur ou cross-server ?
4. **Taxes guilde/royaume Phase 1** : appliquées sur hôtel ventes ou seulement Semaine 2 ?
5. **Récompenses arènes** : cosmétiques only confirmé ?
6. **Montant création guilde** : 10 000 pièces valide ?
7. **Taille guilde** : 50 membres max valide ?
8. **Durée saison** : 2 semaines valide ?

---

**Fin du document.** Prochaine étape : validation D, puis écriture demandes A/B et implémentation.