# Test Plan — Monétisation (Cycle 3)

**Référence : DECISIONS_MARCHE.md §1, §5 (prix finaux) + brief G**
**Responsable QA : M**
**Règle : ZÉRO PAY-TO-WIN. Tout cosmétique ou QoL.**

---

## 1. Prix finaux (Config.Shop)

| Produit | Prix | Type | Contenu |
|---|---|---|---|
| VIPRider | 79 | QoL | +10 % pièces, file prioritaire, émote |
| SpeedBoost | 149 | QoL | +15 % vitesse vague, GoHome -30 % CD |
| BagExpand | 99 | QoL | +10 slots inventaire |
| StarterPack | 249 | Bundle | VIP + Speed + Bag (valeur perçue 327) |
| TideEgg | 199 | Aléatoire | Probabilités affichées : 60/25/10/4/1 |
| PickCreature | 399 | Choix direct | Pas d'aléatoire, premium |

**Vérification** : chaque prix affiché en jeu = ce tableau. Aucun écart toléré.

---

## 2. Probabilités Tide Egg (affichées AVANT achat)

| Rareté | % | Vérification |
|---|---|---|
| Common | 60 % | Affichée dans l'UI avant clic |
| Uncommon | 25 % | Affichée |
| Rare | 10 % | Affichée |
| Epic | 4 % | Affichée |
| Legendary | 1 % | Affichée |

- [ ] Affichage **avant** ouverture du prompt d'achat (pas après)
- [ ] **Pity** : au 51ᵉ essai sans Legendary → Legendary garanti
- [ ] **Pity counter** visible par le joueur
- [ ] Duplicata → converti en Essence (craft skins)

---

## 3. PolicyService (P0 — obligatoire Roblox)

- [ ] `MarketplaceService` + `PolicyService:ArePaidRandomItemsRestricted()` appelé **AVANT chaque** achat Produit Développeur
- [ ] Si restreint → bascule automatique vers **Pick a Creature** (pas Tide Egg aléatoire)
- [ ] `ProcessReceipt` **idempotent** (double achat = un seul grant)
- [ ] Aucune exception non catchée pendant un achat

---

## 4. Rewarded Ads (opt-in total)

- [ ] 1 Tide Egg gratuit / jour (non cumulable)
- [ ] Cooldown **24 h** respecté (pas de contournement)
- [ ] Bouton « Regarder pour récompense » — **jamais forcé**
- [ ] Récompense créditée une seule fois

---

## 5. Cosmetics & Battle Pass

- [ ] Skins créatures 149-399, Mount skins 299-599, Wings/Trails 199-499, Housing 299-799, Emotes 49-149
- [ ] Rotation mensuelle 4 nouveaux, Vault annuel, retour annuel garanti (FOMO sain)
- [ ] Battle Pass 12 semaines : gratuit 12 paliers + premium 499 (+12 paliers)
- [ ] Gratuit suffit à tout débloquer en jouant (ZÉRO FOMO)
- [ ] Aucun cosmétique n'accorde de puissance (vérifier stats avant/après achat)

---

## 6. Zéro Pay-to-Win (validation)

| Test | Méthode | PASS |
|---|---|---|
| Achat VIPRider ne change pas le DPS | Combat identique avant/après | ☐ |
| Achat SpeedBoost = confort (vitesse vague), pas dégâts | Comparer stats | ☐ |
| Aucune puissance dans le shop | Auditer Config.Shop + grants | ☐ |
| Puissance = temps + skill uniquement | Revue items | ☐ |

---

## 7. Cross-platform achat (Cycle 2 + 3 combinés)

- [ ] Achat fonctionnel mobile **et** PC
- [ ] Mêmes prix des deux côtés
- [ ] Même économie (cross-save compte Roblox)
- [ ] 0 erreur / 0 warning console les deux plateformes
- [ ] Prompt d'achat natif Roblox s'affiche correctement

---

## 8. A/B Test framework (V)

- [ ] Test prix VIP 79 / 99 / 129 sans restart
- [ ] Feature flags déploiement progressif (1 % → 5 % → 25 % → 100 %)
- [ ] Rollback flag < 30 s

---

## Sortie Cycle 3

- [ ] Tous points PASS
- [ ] 0 exception économique
- [ ] Rapport P2W audit dans `POSTMORTEMS/`
