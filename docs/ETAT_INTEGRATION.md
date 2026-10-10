# État de l'intégration — vérifié le 2026-10-10 à 14:36

> Rédigé par l'assistant de D (F), à partir de commandes git **en lecture seule**.
> Aucun branche déplacée, aucun checkout, aucun stash, aucun reset.
> Tout ce qui suit est reproductible avec les commandes citées.

But : que lundi 12/10 au soir parte du **bon** état. Ce document existe parce que
plusieurs questions posées à D dans les fichiers `docs/INBOX/` sont **déjà résolues
par les faits** — personne ne le savait, et chacune attendait un arbitrage humain.

---

## 1. La branche de vérité

**`origin/claude/epic-pasteur-q323d7` @ `ada8300`.** C'est le seul endroit qui contient
tout ce qui est attendu lundi.

```bash
git branch -a --contains <commit>          # le commit est-il dedans ?
git merge-base --is-ancestor <commit> <branche> && echo OUI || echo NON
```

| Attendu lundi | Commit sur l'intégration | État |
|---|---|---|
| `Wave.lua` (rendu client de la vague, 493 l.) | `9f10adb` | présent |
| **Correctif P0 de `Wave.lua:404`** (`base * CFrame.new`) | `9f10adb` | présent |
| `init.client.lua` charge `Wave` (ligne 18) | `9f10adb` | présent |
| Correctif VIPRider / contrat v2.1 de A (`Stats.CoinBonus`) | `1d10d0f` | présent |
| Alignement du client sur le contrat v2.1 (P1-15 de B) | `4c5f772`, `3e5db56` | présent |
| GDD_REEF recalé sur le contrat v2.1 | `f1278b5` (apporte `8964cc7`) | présent |
| Code serveur de A | `06f2f54` | présent |

---

## 2. Cinq questions déjà tranchées par les faits

D n'a **rien à arbitrer** là-dessus. Ce sont des demandes de décision qui sont
devenues fausses depuis qu'elles ont été écrites.

| Question | Qui | Ce que la demande disait | Réalité vérifiée |
|---|---|---|---|
| « `1d10d0f` est sur la branche de E, pas dans la PR #1 » | A | il faut le cherry-pick | **déjà intégré** (`git branch -a --contains 1d10d0f` → intégration comprise) |
| « fusionner `claude/e-gdd-reef` avant lundi, sinon le sync part sans le GDD » | E | urgente | **déjà fusionné** (`f1278b5`) |
| « `967a9c8` (Store de B) n'y est pas intégré » | F | risque lundi | **déjà intégré** (`3e5db56`) |
| « le P0 de `Wave.lua` ne peut pas être corrigé, qui l'applique ? » | F | décision à prendre | **déjà corrigé** dans `9f10adb`, ligne 404 relue et confirmée |
| « `waveBoom` et `ambientBeach` n'existent dans aucun `Assets.Sounds` » | F | vague muette, bug | **faux avertissement** : les deux sont définis dans `tools/world/build_sounds.luau` (ids `9125484367`, `9119679792`). `Assets.Sounds` est un dossier *créé par* ce script, jamais exécuté (pas de Studio). Ce n'est pas un asset manquant, c'est une étape de lundi. |

---

## 3. Le piège de lundi : ne pas importer depuis le mauvais worktree

Il y a **trois worktrees**, pas un arbre partagé :

| Worktree | Branche | Contains la vague ? |
|---|---|---|
| `tide-rush/` | `claude/e-gdd-reef` | **non** |
| `tide-rush-b/` | `claude/friendly-volta-qj504y` | non |
| `tide-rush-p42/` | `claude/wave-client-p42` | oui, **mais avec le P0 non corrigé** |

Conséquence : si lundi on part de `claude/e-gdd-reef` (le worktree principal, celui qui
s'ouvre par défaut), **le serveur attrape des joueurs avec une vague invisible** — le
piège nº 1 de `AGENTS.md` §8.

### Second piège : ne pas merger la branche `wave-client-p42`

`4955d92` **n'est pas** un ancêtre de l'intégration. Les deux branches *ajoutent*
`Wave.lua`, et elles ne diffèrent que d'une ligne : celle du P0.

```
diff 4955d92  vs  ada8300
404c404
< 	local frame = base + Vector3.new(0, sink, -front)   # p42 : le bug
---
> 	local frame = base * CFrame.new(0, sink, -front)    # intégration : corrigé
```

Merger `claude/wave-client-p42` dans l'intégration, c'est **réécrire la ligne 404 avec le
bug**. La branche p42 n'apporte rien de plus. Elle est à consider comme **soldée**.

> `testbuild/TestWaveRenderer.client.lua` existe encore sur l'intégration. C'est un doublon
> périmé du module qui a été déplacé. **Inerte** : `default.project.json` ne mappe pas
> `testbuild/`, donc Rojo ne le touche pas. On le laisse en place (règle : ne pas supprimer
> ce qu'on n'a pas créé), mais **personne ne doit plus l'éditer** — l'ancien est en
> production.

---

## 4. La seule fusion qui reste à faire, et elle est sûre

`claude/e-gdd-reef` a **2 commits non poussés** que l'intégration n'a pas :

| Commit | quoi |
|---|---|
| `53f36c1` | `docs/SECRET_EPAVE.md` (E) + fermeture de ses livrables |
| `c74028d` | `tools/world` (C) : 4 sons d'interface pour B + barrière en streaming atomique |

`c74028d` compte pour lundi : sans lui, les boutons de B font du bruit de vide et
l'animation de la barrière peut se couper au milieu.

Simulation de fusion faite **sans rien modifier** :

```bash
git merge-tree --write-tree origin/claude/epic-pasteur-q323d7 claude/e-gdd-reef
```

Résultat : **aucun conflit de code**. Seuls `docs/INBOX/E.md` et `docs/INBOX/F.md`
entrent en conflit — parce que ce sont des fichiers où chacun ajoute son entrée **en
haut**. Les deux camps sont à garder.

```bash
# lundi, sur le worktree d'intégration (à faire par D, pas par une lettre)
git checkout -b integration-lundi claude/epic-pasteur-q323d7
git push origin claude/epic-pasteur-q323d7            # récupère ada8300
git merge claude/e-gdd-reef
# docs/INBOX/E.md et docs/INBOX/F.md : garder les DEUX camps (git add puis git commit)
```

---

## 5. Restes : ce que je n'ai pas tranché et ne peux pas trancher

Deux points sont de la **décision de D**, pas de la vérification technique. Ils sont
préparés dans `docs/INBOX/D_PROPOSITION.md`.

1. **`claude/wave-client-p42` et `claude/friendly-volta-qj504y`** : on les déclare
   soldées et on les laisse en plan, ou on les archive ?
2. **`docs/INBOX/logs/`** : non suivi et non versionné. Ce sont des transcriptions de
   sessions. Elles ne devraient **pas** aller dans le repo (elles sont volumineuses et
   écrites par toutes les lettres en même temps). Décision : `.gitignore` ou commit
   volontaire.

---

## 6. Limites de ce document

- Rien ici n'a été testé en jeu : pas de Studio avant lundi 21 h.
- La conformité de `Wave.lua` au reste du contrat v2.1 **n'a pas été revue ligne à
  ligne** — seulement le correctif P0 et son intégration. C'est le contrôle de qualité
  de lundi matin, une fois la place ouverte.
- `waveBoom` / `ambientBeach` : les **ids** sont bien définis par C, mais personne n'a
  **écouté** les sons. Un id douteux ne casse rien (le client ignore un son absent), mais
  la qualité sonore est à vérifier à l'oreille lundi.
---

## 7. SYNCHRO FINALE — dimanche matin (décidé par D le 10/10 au soir)

Constat du 10/10 : les agents travaillent **en direct sur `claude/r-economy-pvp`**, pas sur
`e-gdd-reef`. La fusion faite le 10/10 au soir (`153b86c..4d23d37`) a déjà été dépassée :
commit `1ec1d21` (P, cycle 1 passe 2) et des fichiers non committés sont arrivés après.

**Dimanche matin, refaire la même séquence.** Rien à improviser :

```bash
WT=/private/var/folders/x8/bz8tzhd92d17d891z2lgl9hm0000gn/T/opencode/synchro-dimanche
git worktree add -q --detach "$WT" origin/claude/e-gdd-reef
cd "$WT" && git checkout -q -b synchro-dimanche origin/claude/e-gdd-reef
git merge --no-edit claude/r-economy-pvp        # conflits = uniquement des INBOX : garder les 2 camps
git push origin HEAD:claude/e-gdd-reef
cd - && git worktree remove --force "$WT"
```

**Avant de merger**, sécuriser ce qui traîne dans l'arbre partagé (les agents committent
sans arrêt, il y aura du non commité) : `git add -A && git commit` sur `r-economy-pvp`.
C'est la seule opération autorisée dans l'arbre partagé — jamais de checkout/switch/reset.

**À vérifier après la fusion** (les 4 points qui cassent le jeu) :
1. `Wave.lua:404` = `base * CFrame.new(0, sink, -front)` — le P0.
2. `Store.lua` : `WaveFrontD` / `StartSteal` / `ChoosePick` — contrat v2.1.
3. Aucun `testbuild/` mappé par Rojo.
4. `src/StarterGui` absent du repo → l'ancienne UI à emojis reste en jeu, à masquer.

**Rappel de calendrier** : quota Moaad réinitialisé 12/10 à 21 h. Le sync Rojo se fait
ce soir-là, sur `claude/e-gdd-reef`. Si la synchro de dimanche n'a pas eu lieu, on perd
tout ce que les agents ont produit depuis la fusion du 10/10.
