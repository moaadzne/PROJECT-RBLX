# File de E — Concept & game design
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 14:12
FAIT     : **§14 nº 2 TRANCHÉ** — les 6 espèces rares restent hors Phase 1 (`GDD_REEF.md`), un Whali Shark Titan à 12 000/s sauterait le palier 4 (seuil 5 000) et viderait `LagoonTiers` de son sens ; ordre de retour Phase 2 fixé (nuit → épave → Légendaires, avec le Deep Dive). **Semaine 2 posée : `docs/SEMAINE_2.md`.**
VÉRIFIÉ  : **écart réel trouvé dans le code** — la décision de D du 09/10 promet des créatures « rares » au récif, or `Config.ExtremeTide.creatures` ne contient que 2 `Uncommon`, et 0,7⁶ ≈ 12 % des récifs n'ont aucune mutée. **[A]** la parade est déjà écrite par A dans `IntroService:156-164` (« au moins une mutée ») : la reprendre telle quelle pour le récif, 0 modèle, 0 Config. Rien testé en jeu.
BESOIN   : **[D]** les règles de monétisation Roblox en vigueur (seul vrai risque de calendrier, semaine 1, pas semaine 2) ; **[D]** Codex semaine 1 : 7 espèces en « ? » ou 3 connues seulement — ça se voit sur les captures du test public ~26/10 ; **[C]** le Deep Dive remplace le `Tide Egg`, ne pas garder les deux.

## 2026-10-10 13:56
FAIT     : GDD_REEF **prêt à intégrer : OUI** — mais fusionner le sommet `8964cc7` (476 l.), **pas** `f908348` (418 l.) : ce dernier contient 4 erreurs corrigées depuis (sac 2→10, paliers Codex, réserve, rebirth).
VÉRIFIÉ  : chaque chiffre Phase 1 revérifié contre `Config.lua` + `review/review_context.md` ; **0 `[À DÉFINIR]` bloquant** — les 4 restants (récompense Léviathan, courbe rangs 6+) portent sur le Tide Rank, entierement hors Phase 1. Rien testé en jeu.
BESOIN   : **D** — fusionner `claude/e-gdd-reef` vers l'intégration **avant lundi 12/10**, sinon le sync Rojo part sans le GDD. Un seul point à échéance : §14 nº 2 (espèces Rare/Epic/Legendary hors marée extrême), à confirmer avant le test fermé ~20/10 ; le reste est Phase 2.

