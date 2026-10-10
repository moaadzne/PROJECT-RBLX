# Runbook — Incidents & Escalade

**Responsable : M (QA Infrastructure)**
**Usage : en cas d'incident post-lancement, suivre la procédure selon la sévérité.**

---

## Sévérités

| Sév | Définition | SLA | Qui | Canal |
|---|---|---|---|---|
| **P0** | Crash serveur / économie cassée / perte de données | 30 min | On-call + A | Incident channel |
| **P1** | Gameplay bloquant (vol, boutique, boss cassés) | 2 h | A + B | Incident channel |
| **P2** | Bug majeur non bloquant | next deploy | Concerné | Ticket |
| **P3** | Bug mineur / cosmétique | backlog | Concerné | Ticket |

---

## P0 — Crash / Économie / Données

1. **Évaluer** : combien de joueurs touchés ? Depuis quand ?
2. **Feature flag OFF** si nouveau système suspect (< 30 s).
3. Si persiste : **rollback** — `git revert` vers le dernier tag stable + relancer le serveur.
4. **DataStore** : si perte, restaurer le backup le plus récent (voir §DataStore).
5. **Communication** : post statut joueur (si Roblox status disponible).
6. **Postmortem** obligatoire dans les 48 h.

**Escalade** : si non résolu en 30 min → réveiller A (blocage critique autorisé, AGENTS.md §3).

---

## P1 — Gameplay bloquant

1. Reproduire (sinon ticket avec étapes + capture).
2. Feature flag OFF si possible.
3. Hotfix dans le **repo** (jamais en Studio), PR, review rapide.
4. Déploiement : 1 % → 5 % → 25 % → 100 %.
5. Si bloquant pour > 10 % joueurs → traitement P0.

---

## DataStore — Restauration

```lua
-- Vérifier l'état du backup (Admin uniquement)
local DSS = game:GetService("DataStoreService")
local store = DSS:GetDataStore("ProfileServiceV2")
-- lister les versions (selon outil de backup choisi par A)
```

- Backup horaire actif → restaurer le dernier état sain.
- **JAMAIS** écrire en DataStore depuis la barre de commande sans validation D.
- Toute restauration = postmortem obligatoire.

---

## Économie — Anomalie (P0)

1. Suspect (duplication, RMT, exploit) : **geler** les échanges/marché.
2. Logs : identifier les comptes concernés, montants.
3. Rollback sélectif des transactions frauduleuses (script validé A).
4. Anti-RMT : patterns détectés → ban.
5. Postmortem + ajustements.

---

## Communication joueur

- **Jamais** de détail technique aux joueurs.
- Messages courts : « maintenance en cours », « retour sous peu ».
- Statut lieu créé par Moaad (page Roblox / Discord).

---

## Postmortem (48 h)

Template `POSTMORTEMS/<date>_<sujet>.md` :
1. **Chronologie** (timeline)
2. **Impact** (joueurs, durée, systèmes)
3. **Cause racine**
4. **Ce qui a marché / ce qui a échoué**
5. **Actions correctives** (owner + deadline)
6. **Détection** : comment l'éviter / le détecter plus tôt

---

## Règles d'or

- **Pas de Cmd + S en Studio** pendant un incident (voir ROLLBACK.md).
- **Pas de hotfix en Studio** — toujours via le repo.
- **Un seul modifie, un autre vérifie** avant tout déploiement P0/P1.
- **Décider vite** : si incertain, rollback d'abord, debug ensuite.
