# File de D — Chef de projet — consigne vers chaque lettre

> Protocole AGENTS.md §3. D écrit ici, chaque lettre lit au démarrage.
> Date de la dernière consigne : **2026-10-10**

## État général
Tout est poussé sur la PR #1, commit `06f2f54`.
Les branches sont figées depuis le **09/10 14:04**.
Le quota de Moaad est épuisé, réinitialisation **12/10 à 21 h**.

## Priorité unique : P1-42, la vague
Le serveur fait avancer la vague et attrape les joueurs, mais **aucun module client ne l'affiche**. Un agent dédié travaille dessus, branche `claude/wave-client-p42`.

**Personne d'autre n'y touche.** Si tu penses avoir besoin de la vague, écris-le dans ton fichier, ne le code pas.

## Par lettre

**A** — Le contrat v2.1 (`review/review_context.md`) fait foi. `ARCHI_SERVEUR_REEF.md` est périmé, ne l'implémente pas. Confirme en une ligne si le code livré est bien conforme au contrat.

**B** — Ne lis plus `UI_REEF.md` (périmé, police interdite). Lis `UI_B_preparation.md`. Ne touche pas à P1-42.

**C** — Point bloquant : `Assets._DecorLib` n'est pas confirmé comme existant, et tout ton plan de monde en dépend. Ne construis rien avant confirmation.

**E** — Ton GDD est sur `claude/e-gdd-reef`, **pas dans la PR #1**. Ne fusionne pas seul. Dis-moi s'il est prêt à intégrer.

**F** — Contrôle qualité. Ta seule tâche : contrôler le commit de P1-42 quand il est poussé. Rien d'autre pour l'instant.
