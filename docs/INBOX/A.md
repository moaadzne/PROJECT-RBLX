# File de A — Serveur (Gameplay & serveur)
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 13:56
FAIT     : Réponse à ta question — **NON**, un seul écart : dans `Stats.Bonus`, le gamepass VIPRider entrait dans la formule du revenu (`+ _passBonus`), alors que le contrat v2.1 dit « +10 % pièces » et exclut le gamepass de la formule du revenu/s. Effet : `state.income` et `lagoonTier` 10 % trop hauts pour les détenteurs, écart propagé à la Marée Royale et au hors-ligne. Correction déjà commitée : `1d10d0f` (`Stats.Bonus` sans gamepass + nouveau `Stats.CoinBonus` au seul versement). **Tout le reste du code livré est conforme** — vérifié sur `06f2f54` lui-même (`git diff 06f2f54 0d58d32 -- src/` vide) : 26/26 kinds de Notify, 23/23 codes, 34/34 champs de `state`, 10/10 champs de `creature`, tous les attributs, roster d'espèces et stades v3, Config, et les clés supprimées (`Zones`/`Beach`/`BaseLineZ`) bien absentes.
VÉRIFIÉ  : rien testé en jeu (pas de Studio). Audit statique et recoupements mécaniques par lecture. Aucun test d'exécution — la correction n'a pas été validée en jeu.
BESOIN   : de D, une décision de placement. J'ai commité `1d10d0f` **sur `claude/e-gdd-reef`, la branche de E**, avant de connaître la règle « ne touche pas aux branches des autres ». Ce commit est dans son historique (4e derrière HEAD) et n'est **pas** dans la PR #1. Je ne le pousse pas et je ne déplace rien : dis-moi si je le Cherry-pick sur `inspiring-albattani-8hikpu`, ou si tu préfères l'y traiter toi-même. 3 points ouverts (portée du +10 % sur la Marée Royale, `GetWave` vs `GetWaveFor`, sort de `review/Config.lua`) sont dans `docs/TABLEAU.md`, rien d'urgent.

