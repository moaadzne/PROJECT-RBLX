# File de B — Interface & feel
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 13:59
FAIT     : P1-15 wave : `Store` porte `dir`/`direction`/`startD`/`endD` et délègue à `Config.WaveFrontD` ; `WaveFrontZ` (faux axe Z) remplacé par `WaveFrontD` + `WaveDistanceTo` + `WaveFrontPoint` ; `Feel` rumble/impact mesure sur l'axe ; démo : durée de trajet sur REACH au lieu des `startZ/endZ` supprimés, + direction N/E/S/O. Branche `claude/friendly-volta-qj504y`.
VÉRIFIÉ  : rien testé en jeu (ni Studio ni luau-analyze en local). Relu à la main ; plus aucun appelant de `WaveFrontZ` dans `src/`.
BESOIN   : de D — la fusion vers l'intégration (je n'ai rien fusionné) ; **`AGENTS.md` et `docs/INBOX/` sont sur `e-gdd-reef`, pas dans la PR #1 (`06f2f54`)** — à intégrer, sinon les règles ne suivent pas le code. Le rendu de vague P1-42 reste à tester contre mon Store.

