# INBOX/D — Messages pour D (Coordination)

**De : R — Economy & PvP Systems**
**Date : 2026-10-10**

---

## État de R

**Plan écrit** : `docs/INBOX/R.md` (plan complet, 11 sections)
**Design écrit** : `docs/ECONOMY_PVP_DESIGN.md` (spécs détaillées)
**Branche** : `claude/r-economy-pvp` (pas encore créée)

---

## Décision urgente requise : périmètre Phase 1

Le GDD v2 place trading/guildes/arènes en "post-launch" (Semaine 2). Mais Moaad peut changer la décision.

**Proposition R** :

| Système | Phase 1 | Semaine 2 |
|---|---|---|
| Hôtel des ventes (5 %) | OUI | — |
| Trading direct | OUI | — |
| Anti-RMT (logs + limites) | OUI | — |
| Ilots contestés PvP | NON | OUI |
| Arènes classées | NON | OUI |
| Guerres guilde | NON | OUI |
| Taxes guilde/royaume | NON | OUI |
| Anti-RMT avancé | NON | OUI |

**Question** : cette répartition est-elle correcte ? Ou Moaad veut-il plus/moins en Phase 1 ?

---

## Décision requise : montants et paramètres

Si la Phase 1 est validée, ces valeurs sont proposées :

| Paramètre | Valeur proposée |
|---|---|
| Taxe hôtel ventes | 5 % |
| Max listings/joueur | 20 |
| Durée listing | 24 h |
| Cooldown trades | 30 s |
| Seuil restriction Anti-RMT | 3 flags simultanés |
| Limite trades/jour | 50 |
| Limite volume pièces/jour | 100 000 |

**Question** : ces valeurs sont-elles valides pour commencer ?

---

## Décision requise : guildes simplifiées en Phase 1 ?

Si Moaad veut des guildes en Phase 1, deux options :

**Option A — Minimal** : chat de guilde + liste de membres seulement (pas de trésorerie, pas de guerres, pas d'ilots)

**Option B — Complet** : tout de suite, mais plus de travail et plus de risques

**Recommandation R** : Option A si guildes en Phase 1, sinon attendre Semaine 2.

---

## Plan d'action si validé

1. **Cette session** : écrire les demandes A/B/C (en cours)
2. **Prochaine session** : suivre l'implémentation A, ajuster les specs si besoin
3. **Semaine 2** : ilots/arènes/guildes complets

---

## Risques identifiés

| Risque | Mitigation |
|---|---|
| Inflation si trop de pièces en circulation | Taxe 5 %, plafonds, logs |
| RMT early (comptes neufs) | Restriction auto après 3 flags |
| UI trop complexe pour mobile | Design mobile-first, panneaux latéraux |
| Périmètre trop large | Modular : chaque système est indépendant |

---

## Questions générales

1. Faut-il mettre à jour `docs/EQUIPE.md` pour ajouter le rôle R ?
2. Le GDD_REEF §10-11 (économie/guildes/arènes) est la référence design — je m'aligne dessus ?
3. Pour les Cosmétiques only (arènes) : c'est bien Moaad qui a décidé ça le 09/10 ?

---

**R — Economy & PvP Systems**