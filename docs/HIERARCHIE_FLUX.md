# HIÉRARCHIE & FLUX — Tide Rush

> Qui décide quoi, par quel canal, et dans quel ordre on escalade.
> Écrit par l'assistant de D le 10/10 ~17:15. **Ce fichier ne remplace rien** : il nomme ce qui
> existe déjà (`AGENTS.md`, `docs/INBOX/REGISTRE.md`, `tools/pont`, `tools/box`).

---

## 1. Les trois canaux, avec leurs noms

| Nom | Outil | Réveille quelqu'un ? | Quand l'utiliser |
|---|---|---|---|
| **LE PONT** | `tools/pont` | **non** — lecture seule | Voir l'état des autres, lire une conversation, déposer une question |
| **LA BOÎTE** | `docs/INBOX/<lettre>.md` | **non** — fichier | Canal officiel et asynchrone. Toute demande, tout compte-rendu |
| **LE RÉVEIL** | `tools/box send` | **oui** | **Blocage critique uniquement** (AGENTS.md §3) |

**Règle unique** : on descend les canaux dans cet ordre, on ne remonte au RÉVEIL que si la BOÎTE
n'a pas répondu et que le jeu est bloqué. Un message « ok » ou « où t'en es » par RÉVEIL est
interdit — il coûte de l'argent.

```
LE PONT (regarder)  →  LA BOÎTE (demander)  →  LE RÉVEIL (uniquement si bloqué)
```

---

## 2. La hiérarchie

```
NIVEAU 0 · MOAAD (le créateur)
          ↑ parle uniquement à D
NIVEAU 1 · D (chef de projet) + ASSISTANT
          D arbitre, valide, donne le feu vert. L'assistant exécute le mécanique
          (git, docs, vérifications, synthèses) et remonte — il ne décide jamais
          le design, les prix ou le périmètre.
          ↑
NIVEAU 2 · LES 5 PILIERS DU JEU (propriétaires de domaine)
          1. HISTOIRE & LORE ............. O  (avec E)
          2. PROGRESSION & BUILDS ........ P  (avec A, K)
          3. BOSS & RAIDS ................ Q
          4. PVP & ÉCONOMIE .............. R
          5. CINÉMATIQUES ................ S
          ↑
NIVEAU 3 · LES 21 AGENTS (un par zone, une lettre, une boîte)
```

### Le noyau technique (traverse les 5 piliers)

| Lettre | Nom officiel | Ce qu'il possède |
|---|---|---|
| **A** | Serveur | le **contrat v2.1** (`review/review_context.md`), `Config`, les `Remotes` |
| **B** | Interface | `StarterGui`, `StarterPlayer`, `ReplicatedFirst` |
| **C** | Monde | `Workspace.Map`, `Terrain`, `Lighting`, `Assets`, `SoundService` |
| **V** | Performance | architecture single-shard, streaming, netcode |

### Les fonctions transversales

| Lettre | Nom officiel | Rôle |
|---|---|---|
| **E** | Design | le GDD, la cohérence de conception |
| **F** | Qualité | contrôle, checklist, rollback |
| **M** | Lancement | la nuit de Rojo et la checklist 20 points |
| **G** | Monétisation | boutique, prix, PolicyService, Rewarded Ads |
| **H** | Identité visuelle | police, icônes, langage graphique |
| **I** | Codex | écran de collection |
| **J** | Rétention | quêtes, récompenses quotidiennes, Battle Pass, social |
| **K** | Créatures | modèles, animations, mutations, LOD |
| **L** | Onboarding | les 30 premières secondes |
| **N** | Direction artistique | lumière, eau, palettes, hero shot |
| **T** | Exploration | specs du monde jouable |
| **U** | Guildes | Phase 4 |

---

## 3. L'escalade — l'ordre exact

On s'arrête au plus bas niveau qui peut répondre. On ne saute pas les étages.

| # | Situation | Qui tranche | Canal |
|---|---|---|---|
| 1 | Un doute technique **dans sa propre zone** | soi-même | son code |
| 2 | Un doute technique **entre deux zones** (nom, format, dispo d'un asset) | les deux concernés, ensemble | LA BOÎTE de l'autre |
| 3 | Un nom, un attribut, un champ du **contrat**, `Config`, une Remote | **A seul** — jamais négocié entre voisins | LA BOÎTE de A |
| 4 | Le **périmètre**, une priorité, un prix, une décision de design | **D** | LA BOÎTE de D |
| 5 | Le produit, le business, ce que Moaad veut | **Moaad**, via **D** uniquement | D |

**Interdits absolus** (ce sont eux qui créent le bazar) :
- Modifier `Config` ou les `Remotes` sans A. Même « juste une petite ligne ».
- Toucher à la zone d'un autre agent, même pour l'aider.
- Négocier un changement de périmètre avec son voisin : ça remonte à D.
- Réveiller une session sans blocage réel.

> Un conflit entre deux zones **ne s'escalade pas** : les deux concernés se tranchent et
> l'écrivent dans `docs/TABLEAU.md`. C'est la règle AGENTS.md §2, elle reste vraie.

---

## 4. Quand deux sessions font le même travail

Ça arrive (Q et R ont chacune deux sessions). Ce n'est pas grave si c'est arbitré tôt.

- **Le REGISTRE est la seule source** : `docs/INBOX/REGISTRE.md`, une ligne par lettre. C'est
  `tools/pont` qui le lit — si le registre dit X, c'est X qui reçoit les messages.
- Une session **annexe** n'a pas de lettre : elle ne reçoit rien par la BOÎTE, son travail
  doit être relayé par la lettre officielle.
- **Découverte d'un doublon** → on écrit dans `docs/INBOX/D.md`, D tranche laquelle garde.
  On ne tue pas une session soi-même.

---

## 5. Avant de démarrer, toute session lit dans cet ordre

1. `AGENTS.md` — les règles
2. **`docs/REPRISE_LUNDI.md`** — l'état complet du projet en une page
3. `docs/INBOX/REGISTRE.md` — qui est qui, son id de session
4. `docs/INBOX/D.md` — les consignes de D
5. `docs/INBOX/<sa lettre>.md` — sa boîte
6. Les docs qui font foi : `DECISIONS_MARCHE.md`, `review/review_context.md`, `DIRECTION_V2.md`