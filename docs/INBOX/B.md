# File de B — Interface & feel
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 14:55
FAIT     : P1-14 poussé (`3ac6e73`). Titres et chiffres sur `Enum.Font.RobotoCondensed` (Oswald retiré). Nouveau module `Glyph.lua` = point de substitution unique : résout une clé vers l'image de C (`Assets.UI.Icons`) ou le pictogramme dessiné ; `Theme.Icon` délègue, les 8 appelants n'ont pas bougé. Plaques sombres, coins 6–10 px et hiérarchies étaient déjà en place : rien à refaire dessus.
VÉRIFIÉ  : rien testé en jeu (ni Studio ni luau-analyze). Relu : **0 emoji** dans tout le client, et `Theme.lua` est le seul fichier fabriquant une `ImageLabel`.
BESOIN   : [D] — un point important : **tu ne construis rien de neuf, tu repars d'une base déjà faite.** Le système console et les pictogrammes dessinés dataient d'avant ton message ; je n'ai fait que la police et l'extraction du point de substitution, comme demandé. Et j'ai durci le require de `Glyph` : ce bootstrap saute en silence un module qui échoue, un require dur aurait fait tomber toute l'interface.

## 2026-10-10 14:35
FAIT     : rien de nouveau côté code, j'ai vérifié avant d'agir. **Correction d'un signalement que j'avais fait : les codes d'erreur v2.1 sont complets**, `StealHud.CODE_TEXT` couvre les 11 du vol et `MountButton.CODE_TEXT` ceux de la monture. Il n'y a pas de bug à corriger là, ne le cherche pas.
VÉRIFIÉ  : lectures seules (`StealHud.lua:21-32`, `MountButton.lua:8-14`, `World.lua:40-52`). Rien testé en jeu.
BESOIN   : [D] — trois décisions qui me bloquent, aucune ne m'appartient : **(1)** fusionner `claude/friendly-volta-qj504y`, mes 2 correctifs sont orphelins et tu m'interdis de merger ; **(2)** le jeu d'icônes pour P1-14 — les emoji sont interdits et le dépôt n'a aucun asset d'icône, donc je ne peux pas sortir l'UI console sans ta décision (Creator Store sous licence, ou atlas que je dessine) ; **(3)** la police condensée (Barlow Condensed ou équivalent, licence).

## 2026-10-10 14:20
FAIT     : P1-15 (suite) : noms de stades v2.1 dans le repli du store — `STAGE_IDS` portait encore `Baby`/`Giant` au lieu de `Juvenile`/`Elder`/`Titan` (`Store.lua:18`). Commit `c10b989` poussé. Mon plan d'interface Reef Keepers **n'est pas écrit** : limite hebdomadaire atteinte, je me suis arrêté net plutôt que de le commencer à moitié.
VÉRIFIÉ  : rien testé en jeu. Lectures seules : `World.lua` prend le matériau de mutation via `preset:GetAttribute("Material")` + cast dynamique, donc **Night = "Keep" fonctionne sans changer une ligne** (réponse à [C]/[A]).
BESOIN   : [D] — j'ai besoin que quelqu'un fusionne `claude/friendly-volta-qj504y` (mes 2 commits) : tu m'interdis de merger, et rien ne les reprend. [D] — ton brief de 14 h est en retard sur le repo : le contrat est **v2.1** (pas v1), le **GDD est écrit en v3 depuis le 09/10** (pas « en ce moment »), et `docs/UI_REEF.md` est **périmé** — ton propre AGENTS.md interdit de le lire et de le remplir. Je n'ai donc rien écrit dedans.

## 2026-10-10 13:59
FAIT     : P1-15 wave : `Store` porte `dir`/`direction`/`startD`/`endD` et délègue à `Config.WaveFrontD` ; `WaveFrontZ` (faux axe Z) remplacé par `WaveFrontD` + `WaveDistanceTo` + `WaveFrontPoint` ; `Feel` rumble/impact mesure sur l'axe ; démo : durée de trajet sur REACH au lieu des `startZ/endZ` supprimés, + direction N/E/S/O. Branche `claude/friendly-volta-qj504y`.
VÉRIFIÉ  : rien testé en jeu (ni Studio ni luau-analyze en local). Relu à la main ; plus aucun appelant de `WaveFrontZ` dans `src/`.
BESOIN   : de D — la fusion vers l'intégration (je n'ai rien fusionné) ; **`AGENTS.md` et `docs/INBOX/` sont sur `e-gdd-reef`, pas dans la PR #1 (`06f2f54`)** — à intégrer, sinon les règles ne suivent pas le code. Le rendu de vague P1-42 reste à tester contre mon Store.

