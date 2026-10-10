# REPRISE — à lire en premier

> **Si tu es une session qui reprend le projet (locale ou cloud), lis ce fichier avant tout
> autre.** Il dit où est chaque chose. Écrit par l'assistant de D le 10/10 au soir.
>
> **En 3 lignes** : 21 agents travaillent sur des zones séparées. Le concept a pivoté vers un
> vrai MMORPG (`DECISIONS_MARCHE.md` §9), pas seulement « vague + collection ». La branche qui
> part dans Studio lundi 12/10 à 21 h est **`claude/e-gdd-reef`**, et il reste **une synchro à
> faire dimanche matin** (§6 ci-dessous).

---

## 1. Les 21 agents, et où lire leur plan

Chaque agent écrit dans `docs/INBOX/<lettre>.md`, 3 lignes (FAIT / VÉRIFIÉ / BESOIN).
**C'est la source de vérité de l'état d'avancement.** Lis les fichiers, pas les gens.

| Lettre | Rôle | Zone (seul à modifier) | INBOX |
|---|---|---|---|
| **A** | Gameplay & serveur | `ServerScriptService`, `Shared` (Config), `Remotes` | `docs/INBOX/A.md` |
| **B** | Interface & feel | `StarterGui`, `StarterPlayer`, `ReplicatedFirst` | `docs/INBOX/B.md` |
| **C** | Monde & art | `Workspace.Map`, `Terrain`, `Lighting`, `Assets`, `SoundService` | `docs/INBOX/C.md` |
| **E** | Concept & design | `docs/` seulement | `docs/INBOX/E.md` |
| **F** | Contrôle qualité | lecture seule, écrit `docs/` | `docs/INBOX/F.md` |
| **G** | Monétisation & boutique | `Config.Shop`, `ShopService`, `Shop.lua` | `docs/INBOX/G.md` |
| **H** | Icônes, polices, langage visuel | `Theme.lua`, `Glyph.lua`, `IconResolver.lua` | `docs/INBOX/H.md` |
| **I** | Codex & collection UI | `Codex.lua`, HUD | `docs/INBOX/I.md` |
| **J** | Rétention, quêtes, social | `Retention/` (services), `Config.Shop` (DailyReward/Quest/BattlePass) | `docs/INBOX/J.md` |
| **K** | VFX, modèles, animations | `Assets.Creatures`, `CreatureRenderer.lua` | `docs/INBOX/K.md` |
| **L** | Onboarding, 30 premières secondes | `CameraIntro.lua`, `Onboarding.lua` | `docs/INBOX/L.md` |
| **M** | Lancement, Rojo sync, QA | `docs/VERIFS_LUNDI.md`, checklist | `docs/INBOX/M.md` |
| **N** | Polish visuel, lumière, DA | `Lighting`, `Atmosphere`, eau, palettes | `docs/INBOX/N.md` |
| **O** | Histoire & lore | `docs/` (aucune zone Studio) | `docs/INBOX/O.md` |
| **P** | Progression & systèmes | `Config` (XP, classes, talents, gear), données | `docs/INBOX/P.md` |
| **Q** | Boss & raids | design semaine 2+ | `docs/INBOX/Q.md` |
| **R** | Économie & PvP | `Config.Economy`, services économie | `docs/INBOX/R.md` |
| **S** | Cinématiques & présentation | design semaine 2+ | `docs/INBOX/S.md` |
| **T** | Exploration monde | POI, marée extrême, streaming | `docs/INBOX/T.md` |
| **U** | Guildes & social | phase 4 | `docs/INBOX/U.md` |
| **V** | Technique & performance | netcode, streaming, `Config.CrossPlatform` | `docs/INBOX/V.md` |

**D** est le chef de projet, il ne développe pas : il arbitre et valide. **Moaad** est le
créateur, il ne parle qu'à D.

---

## 2. Le concept a changé : pivot MMORPG

`docs/DECISIONS_MARCHE.md` **§9** contient le pivot validé. Le jeu n'est plus seulement
« une vague + une collection de créatures » : c'est un **vrai MMORPG Roblox** bâti sur 5 piliers.

| Pilier | Agent | Phase |
|---|---|---|
| 1. Histoire & lore profonde | E, O | §9 — campé dès la phase 1 (texte, pas de système) |
| 2. Progression infinie & builds | A, K, P | **Phase 1 = données écrites, runtime désactivé.** Semaine 2+ = activation |
| 3. Boss & raids | Q | Semaine 2+ (Phase 1 = zéro boss) |
| 4. PvP & économie joueur | R | Phase 1 = hôtel des ventes minimal + trading ; semaine 2+ = reste |
| 5. Cinématiques & présentation | S | Semaine 2+ (L a déjà livré l'intro 30 s) |

**Ce qui est réellement jouable lundi (Phase 1)** : intro 30 s sans texte → vol pendant la
vague → monture Titan → boutique minimale (3 passes + Tide Egg / Pick a Creature) → Codex
3 connues + 4 mystère → Marée Royale → sauvegarde. **Tout le reste est écrit mais désactivé.**

---

## 3. Les docs qui font foi, dans cet ordre

En cas de conflit, cet ordre tranche :

| # | Fichier | Ce qu'il décide |
|---|---|---|
| 1 | `docs/DECISIONS_MARCHE.md` | pivot MMORPG, monétisation, prix, cross-plateforme |
| 2 | `review/review_context.md` | **contrat v2.1** — noms de remotes, attributs, champs de `state`. A en est propriétaire |
| 3 | `docs/DIRECTION_V2.md` | ton, style, police, public visé |
| 4 | `docs/TABLEAU.md` | état des tâches, décisions de Moaad du 09/10 |
| 5 | `docs/ETAT_INTEGRATION.md` | état git, pièges de la synchro |
| 6 | `docs/BRIEF_NOUVEAUX_AGENTS.md` | briefs de G à N |
| 7 | `docs/IMPORT_LUNDI.md` | procédure Rojo pas à pas |
| 8 | `docs/GDD_REEF.md` | design détaillé |

⚠️ **Périmés, ne pas implémenter au littéral** : `docs/UI_REEF.md` (police interdite) et
`docs/ARCHI_SERVEUR_REEF.md` (décrit une réserve, `Pools/PoolN`, `Species`, `TideType` —
rien de tout ça n'existe dans le contrat v2.1).

---

## 4. État technique — ce qu'il faut vérifier avant de croire que ça marche

| Point | Attendu | Pourquoi |
|---|---|---|
| `Wave.lua:404` | `base * CFrame.new(0, sink, -front)` | le P0 : avec `+ Vector3`, la vague partait à l'envers et restait immobile en E/W |
| `Store.lua` | `WaveFrontD`, `StartSteal`, `ChoosePick` | noms du contrat v2.1 ; le serveur ne crée pas les anciens |
| `src/StarterGui` | **absent du repo** | donc Rojo ne le touche pas et **l'ancienne UI à emojis reste en jeu**, derrière le nouveau HUD. À masquer avant toute capture |
| `testbuild/` | non mappé par Rojo | doublon périmé de `Wave.lua`, personne ne l'édite |
| Branche d'intégration | `claude/e-gdd-reef` | ⚠️ **ne pas** merger `claude/wave-client-p42` : il réintroduirait le P0 |

---

## 5. Ce qui est livré / ce qui bloque

**Livré** (committé) : contrat v2.1 audité et conforme, vague rendue et P0 corrigée, client
aligné sur le contrat, Config.Shop aux prix finaux, Codex UI complet, intro 30 s, pipeline
créatures + mutations shader + LOD, specs lumière/eau/palettes, plans O/P/Q/R/S/T/U/V,
procédure Rojo vérifiée et corrigée.

**Attend une décision de D** : périmètre Phase 1 = 3 créatures (K), emplacement bouton Codex
(I), scope BattlePass 499 (G), `SUNK_POOLS` validé et appliqué (`Config.SunkPoolOffset = -3.5`).

⚠️ **`Config.Island.coveRadius` est décidé à 110 mais toujours à 70 dans `Config.lua`** au moment où j'écris. C a vérifié géométriquement que 8 lagons de rayon 30 ne tiennent pas dans une crique de 70. **C'est le seul vrai bloquant technique**, et le changement est de la zone de A (Config). Si lundi la valeur est encore 70, `build_lagoon` ne sert à rien : le dire à A avant de lancer quoi que ce soit.

**Attend Moaad** : 6 ids Creator Hub pour activer la boutique, ids RobotoCondensed réels,
`Lighting.Technology = Future` (manuel, pas par script), device mobile + PC pour le test
croisé obligatoire de M.

---

## 6. Dimanche matin — la synchro qu'il reste à faire

Les agents travaillent **en direct sur `claude/r-economy-pvp`**, pas sur `e-gdd-reef`. La
fusion du 10/10 au soir a donc déjà été dépassée. La séquence exacte est écrite dans
`docs/ETAT_INTEGRATION.md` §7. En résumé : sécuriser le non-commité sur `r-economy-pvp`,
merger dans un worktree détaché, pousser sur `e-gdd-reef`, vérifier les 4 points du §4.

**Sans cette synchro, le sync Rojo de lundi part d'un code qui perd tout le travail des
agents depuis le 10/10 au soir.**

---

## 7. Règles de sécurité, non négociables

- **Jamais** de `git checkout`, `switch`, `reset`, `stash` ou `clean` dans
  `/Users/admin/Documents/claude code/tide-rush`. Cinq sessions y travaillent en même temps.
- Toute opération git se fait dans un **worktree détaché**, supprimé après :
  `git worktree add -q --detach <chemin> origin/claude/<branche>` … `git worktree remove --force <chemin>`
- On ne modifie que **sa zone**. Changer `Config` ou les `Remotes` : **A seul**.
- On ne **supprime, renomme ou déplace** rien qu'on n'a pas créé.
- Le canal de communication est `docs/INBOX/`. On ne réveille pas une session pour « savoir
  où elle en est » : on écrit dans sa boîte, elle lira à son prochain tour.
- Quota de Moaad épuisé jusqu'au **12/10 21 h**. Pas de test lourd, pas de capture en série,
  pas de `luau-analyze` complet.