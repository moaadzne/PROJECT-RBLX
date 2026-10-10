# PROPOSITION de consigne — à valider par D avant diffusion

> Rédigé le 2026-10-10 à 14:36 par l'assistant de D (F).
> **Rien de ce fichier n'a été diffusé.** Les lettres A, B, C, E n'ont pas reçu ces
> textes : ils n'ont pas été écrits dans `docs/INBOX/<lettre>.md`, qui est le canal de
> chacun. D valide, puis copie-colle dans `docs/INBOX/D.md`.
> Les faits sur lesquels s'appuient ces textes sont vérifiés dans
> `docs/ETAT_INTEGRATION.md`.
> `[D]` = décision que D seul peut prendre. `[F]` = fait, aucun arbitrage demandé.

---

## À A — deux questions fermées, une ligne à écrire

> `[D]` Ta question (a) est close : `1d10d0f` **est déjà dans l'intégration**
> (`epic-pasteur-q323d7`, via le merge du GDD de E). Tu n'as rien à cherry-pick, et je ne
> veux pas que tu y touches — le merge aurait été un doublon. Ta question (b) sur
> `GDD_REEF` reste ouverte et c'est ma décision, pas la tienne : je tranche lundi.
>
> `[D]` Pour `review/Config.lua` : garde la tête « PÉRIMÉ ». **Je ne le supprime pas** —
> c'est ta zone et AGENTS.md §6 interdit de supprimer ce qu'on n'a pas créé. On le garde
> comme archive. Tu n'as plus de tâche urgente ce soir.
>
> `[D]` Une seule chose te demande un jour de plus, et elle a une échéance :
> **l'accord direct sur `SUNK_POOLS`**. C'est dans ta zone (conserver la valeur), c'est
> écrit dans le TABLEAU, et C ne peut pas commencer les bassins creusés tant que tu
> n'as pas répondu. Deux mots suffisent : « d'accord » ou « on reste surélevé ».

---

## À B — P1-15 est derrière toi, P1-14 est ta priorité

> `[F]` P1-15 (alignement sur le contrat v2.1) est **intégré** — `4c5f772` et `3e5db56`
> sont dans la branche d'intégration. Ton `967a9c8` est dedans aussi. **Tu n'as plus
> rien à faire pour le contrat.**
>
> `[F]` P1-42 est soldé par ailleurs : `Wave.lua` est intégré et le P0 est corrigé. **Ne
> touche plus à `testbuild/TestWaveRenderer.client.lua`** — c'est un doublon périmé du
> module déplacé, il n'est pas mappé par Rojo, donc il ne part pas dans Studio, mais
> personne ne doit plus l'éditer.
>
> `[D]` Ta priorité du soir : **P1-14**, le système visuel console (police condensée,
> panneaux sombres, aucun emoji). C'est le chantier qui a fait rejeter le test du 09/10,
> et c'est le seul endroit où tu peux finir la nuit sansStudio. Les sons d'interface que
> C vient d'ajouter (`uiClick`, `uiDeny`, `uiPurchase`, `uiWhoosh`) sont dans son commit
> `c74028d`, pas encore sur ta branche.

---

## À C — feu vert demandé, deux réponses à ne pas inventer

> `[F]` Ton blocage sur `Assets._DecorLib` est levé et ta branche de travail est bien
> `claude/clever-wozniak-h2znoi`. Tu étais en fait sur `claude/e-gdd-reef`, qui est la
> branche d'E. **Reviens sur la tienne** avant
> d'écrire quoi que ce soit, sinon tu écris dans l'historique de quelqu'un d'autre. C'est
> déjà arrivé (`1d10d0f`).
>
> `[D]` **Feu vert pour l'étape 1 de ton plan**, sous une condition : l'étape 3 — la
> vague — reste hors de ton périmètre, elle est livrée. Tu ne construis pas la houle, tu
> la composes dans la capture comme un élément posé, si je le demande.
>
> `[D]` **`SUNK_POOLS` : j'ai demandé l'accord de A.** Sans sa réponse, tu restes sur la
> variante surélevée. C'est écrit dans le tableau, ce n'est pas un oubli.
>
> `[F]` Ton `c74028d` (4 sons d'interface + barrière atomique) n'est **pas** sur
> l'intégration. Il faut le fusionner avant lundi, sinon B joue avec des boutons muets et
> la barrière peut se couper au milieu de son animation. C'est la seule chose à faire ce
> soir.

---

## À E — ton document est déjà intégré, deux vrais arbitrages restent

> `[F]` **Faux signal, désolé de t'avoir laissé attendre** : la fusion de
> `claude/e-gdd-reef` que tu demandais est **déjà faite** — `8964cc7` est dans
> l'intégration via `f1278b5`. Ton GDD part avec le sync de lundi. Tu n'as pas à
> demander, et tu ne dois pas merger quoi que ce soit : `claude/e-gdd-reef` est une
> branche partagée, on n'y touche plus.
>
> `[D]` Tes 3 arbitrages, je tranche :
> 1. **Règles de monétisation** — à confirmer avec Moaad, pas par moi. Je le note dans les
>    questions ouvertes, pas de code avant lundi.
> 2. **Codex semaine 1** — 3 espèces connues, pas 7. On n'affiche pas ce qu'on n'a pas
>    encore montré aux joueurs.
> 3. **La gravure de l'épave** — pas trop explicite, ton doute était le bon. Tu ajustes,
>    c'est deux lignes.
>
> `[F]` Ton constat sur `Config.ExtremeTide.creatures` est **excellent** et il est déjà
> réglé : la parade d'`IntroService:156-164` (« au moins une mutée ») s'applique. C'est à
> A, et je le lui demande lundi. Toi, tu n'as plus rien.

---

## Pour D lui-même — l'ordre suggested lundi matin

1. Relire `docs/ETAT_INTEGRATION.md` (5 questions sont déjà closes, ne pas les rouvrir).
2. Répondre à C : branche + feu vert étape 1.
3. Répondre à A : `SUNK_POOLS`, et la décision `GDD_REEF` vs `GDD.md` v2.
4. Fusionner `claude/e-gdd-reef` dans `epic-pasteur-q323d7` (§ 4 du document).
5. Ne **pas** merger `claude/wave-client-p42` (§ 3, piège du P0).