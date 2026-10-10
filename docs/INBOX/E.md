# File de E — Concept & game design
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 16:15
FAIT     : `PREMIERE_HEURE.md` écrit, GDD figé non retouché. L'écart signalé (âge = capture vs dépôt) est le seul point où le GDD et le code divergent sur la première heure — j'ai écrit le code.
VÉRIFIÉ  : aucune Phase 2, aucun nom de service. Rien testé en jeu.
BESOIN   : **[D]** trancher l'écart si tu veux redonner son sens au « risque du sac » (une ligne côté serveur).

## 2026-10-10 15:38
FAIT     : **`docs/PREMIERE_HEURE.md`** — la première heure en français simple, minute par minute, sans Phase 2 et sans nom de service. GDD non retouché. `SEMAINE_2.md` et `SECRET_EPAVE.md` restent écrits mais **sont garés** : rien ne s'ouvre avant que la Phase 1 soit jouable.
VÉRIFIÉ  : chaque affirmation recalée sur le code avant d'écrire (35 s de calme / 7 s d'alerte, sac de 2, 5 bassins, 1/2/10 pièces par seconde, vieux à 15 min pour un commun et 30 pour une tortue, torches au palier 30/s, marée dorée toutes les 8 min, Couronne royale à chaque marée spéciale, récif 25 s). Rien testé en jeu.
BESOIN   : **[D] un écart à trancher** — le GDD figé dit que l'âge d'une créature compte **dès la capture**, mais `CreatureService.lua:278-283` crée la créature au **dépôt**. Le code et le contrat v2.1 disent dépôt ; c'est le GDD qui dit capture. Conséquence réelle : **le temps passé à courir avec l'animal dans le sac ne compte pas** — le sac n'est pas un risque, c'est juste une limite de place. J'ai écrit le document sur le dépôt (le code). Si tu veux l'inverse, c'est une ligne à changer et ça redonne son sens à « le risque du sac ».

## 2026-10-10 15:04
FAIT     : **`SEMAINE_2.md` réécrit pour Moaad** — semaine par semaine, ce que le joueur voit et ce qui change dans son expérience. Plus aucun nom de service, plus aucun tableau technique. Le détail équipe est resté dans `SECRET_EPAVE.md`.
VÉRIFIÉ  : les faits n'ont pas bougé au passage — plongée qui remplace la boutique, gratuit quotidien, probabilités affichées, garantie anti-malchance, ce qui est acheté ne peut être volé, épave pendant la marée horaire avec raie + poulpe, gravure sans récompense, échanges repoussés. Rien testé en jeu.
BESOIN   : **[D]** rien de neuf — tes 2 questions sont déjà portées à Moaad. Le doc est prêt à lui être montré tel quel ; dis-moi s'il veut la coupe finale (quatre parties : lancement / semaine 2 / direction semaine 3 / questions ouvertes).

## 2026-10-10 14:31
FAIT     : **`docs/SECRET_EPAVE.md`** — la semaine 2 est maintenant entièrement spécifiée côté concept : Deep Dive sort, échanges glissent (§2), épave écrite (§3). Plus aucun livrable E en attente.
VÉRIFIÉ  : l'épave ne coûte **rien à B** (aucun popup, aucun texte) et **2 lignes à A** (`Config.ExtremeTide.creatures`) ; tout le travail de modélisation est pour C, qui dessine déjà le repère en Phase 1. Rien testé en jeu.
BESOIN   : **[D] 3 arbitrages, le dernier est nouveau** — (1) règles de monétisation Roblox, semaine 1 ; (2) Codex semaine 1 : 7 espèces en « ? » ou 3 connues ; (3) `SECRET_EPAVE.md` §6 : **la gravure est-elle trop explicite ?** C'est le curseur fin du plot twist, je ne peux pas le mesurer. D tranche aussi : si la semaine 2 déborde, **l'épave part en premier**, le Deep Dive n'a pas de remplaçant.

## 2026-10-10 14:12
FAIT     : **§14 nº 2 TRANCHÉ** — les 6 espèces rares restent hors Phase 1 (`GDD_REEF.md`), un Whali Shark Titan à 12 000/s sauterait le palier 4 (seuil 5 000) et viderait `LagoonTiers` de son sens ; ordre de retour Phase 2 fixé (nuit → épave → Légendaires, avec le Deep Dive). **Semaine 2 posée : `docs/SEMAINE_2.md`.**
VÉRIFIÉ  : **écart réel trouvé dans le code** — la décision de D du 09/10 promet des créatures « rares » au récif, or `Config.ExtremeTide.creatures` ne contient que 2 `Uncommon`, et 0,7⁶ ≈ 12 % des récifs n'ont aucune mutée. **[A]** la parade est déjà écrite par A dans `IntroService:156-164` (« au moins une mutée ») : la reprendre telle quelle pour le récif, 0 modèle, 0 Config. Rien testé en jeu.
BESOIN   : **[D]** les règles de monétisation Roblox en vigueur (seul vrai risque de calendrier, semaine 1, pas semaine 2) ; **[D]** Codex semaine 1 : 7 espèces en « ? » ou 3 connues seulement — ça se voit sur les captures du test public ~26/10 ; **[C]** le Deep Dive remplace le `Tide Egg`, ne pas garder les deux.

## 2026-10-10 13:56
FAIT     : GDD_REEF **prêt à intégrer : OUI** — mais fusionner le sommet `8964cc7` (476 l.), **pas** `f908348` (418 l.) : ce dernier contient 4 erreurs corrigées depuis (sac 2→10, paliers Codex, réserve, rebirth).
VÉRIFIÉ  : chaque chiffre Phase 1 revérifié contre `Config.lua` + `review/review_context.md` ; **0 `[À DÉFINIR]` bloquant** — les 4 restants (récompense Léviathan, courbe rangs 6+) portent sur le Tide Rank, entierement hors Phase 1. Rien testé en jeu.
BESOIN   : **D** — fusionner `claude/e-gdd-reef` vers l'intégration **avant lundi 12/10**, sinon le sync Rojo part sans le GDD. Un seul point à échéance : §14 nº 2 (espèces Rare/Epic/Legendary hors marée extrême), à confirmer avant le test fermé ~20/10 ; le reste est Phase 2.

