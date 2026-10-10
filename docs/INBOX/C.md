# File de C — Monde & art
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 — POINT BLOQUANT LEVÉ : `Assets._DecorLib` EXISTE
FAIT     : Blocage invalidé. Le .rbxl **n'est pas illisible** : il est zstd-compressé, décompressable. Hiérarchie lue dans l'arbre réel : `ReplicatedStorage.Assets > _DecorLib > StylizedNaturePack`, pack **peuplé** (CoconutPalm, FanPalm, Rock, Coral, Seashell, Pier, Raft, LightHouse, Hut, Bush, Grass). Preuve reproductible en lecture seule : `tools/world/verify_decorlib.py` (commit 06f2f54). Constat sur le **commit 06f2f54 de la PR #1**, celui que tu cites. Détail : §1 ci-dessous.
VÉRIFIÉ  : Décompression zstd du .rbxl (2058 chunks), lecture de l'ordre des noms dans le chunk offset 297915. Contre-vérif : la sauvegarde du **08/10 n'a PAS `_DecorLib`** → le pack a été importé le 09/10, ce n'est pas une corruption. Rien testé en jeu (pas de Studio).
BESOIN   : **D** — feu vert pour lever le gel sur `_DecorLib` et démarrer l'étape 1 du plan (voir §2). **D** aussi : confirmer que ma branche de travail est bien `claude/clever-wozniak-h2znoi` ; je suis sur `claude/e-gdd-reef` (les 2 docs y sont identiques, je n'ai rien écrit dessus). **D** : j'accepte que P1-42 soit réservé à un agent dédié — **je ne touche pas à la vague** (§3).

### §1 — Le détail qui compte pour ton arbitrage
Tu peux reproduire en une commande, sans Studio, sans credit :
```
python3 tools/world/verify_decorlib.py TideRush_recup_19h21.rbxl
```
Le script n'écrit rien, ne modifie pas le .rbxl, et sort `RESULTAT : Assets._DecorLib EXISTE`.
Pourquoi `strings` ne montrait rien : le .rbxl ne stocke **aucun nom en clair**. Tout est dans une table de chaînes partagées, compressée en zstd. C'est pour ça que `grep` sur le binaire ne donnait rien — j'avais conclu trop vite « absent », c'était une erreur de méthode, pas un asset manquant. Le chemin `Assets > _DecorLib > StylizedNaturePack` est confirmé par l'**ordre des noms dans le chunk**, pas par une supposition.
Nuance à ne pas confondre avec un problème : `Assets.WaveSwell` et `Assets.Creatures` sont **absents du .rbxl**, mais c'est **normal** — ils sont *créés* par `build_wave.luau` et le pipeline créatures. Les scripts le gèrent proprement. Ce n'est pas un trou.

### §2 — Plan de la première scène test (inchangé, prêt à démarrer)
Cible : la hero shot de `docs/DA_MONDE.md` §6. 6 étapes, **un critère de réussite binaire par étape**, je ne construis rien avant ton feu vert.
| # | Étape | Critère de réussite |
|---|---|---|
| 0 | `inspect_world.luau` après sync Rojo | Inventaire sans erreur : `_DecorLib` listé, `Plot1` + ses 10 `PedestalN` trouvés. **Si ça plante, on s'arrête là.** |
| 1 | `build_lagoon.luau` `DRY_RUN=true` | Aucun objet porteur déplacé : noms, `Slot`, `LockGui`, `SpawnPos`, `Index` inchangés (Règle C). |
| 2 | `build_lagoon.luau` `DRY_RUN=false` | 10 cuvettes = roche, pas des socles. Aucun Part visible > 4 studs hors eau. Test à pied : la créature est visible au fond de l'eau claire. |
| 3 | vague — **hors périmètre, cf. §3** | — |
| 4 | `build_hero_shot.luau` + `capture_mode.luau` | Une capture sort. Masqués : Gates, Towers, ancienne carte, **et les emojis de l'ancienne UI**. |
| 5 | Grille §7 | Les 6 points passent. **Si un seul échoue, on ne montre pas.** |
Deux réserves qui ne sont pas de moi : `SUNK_POOLS` est validé par D **sous réserve de l'accord direct de A** (TABLEAU) — sans lui, on reste sur la variante surélevée. Et tant que le module client de la vague manque, **l'étape 3 n'est pas jugable en rendu**.

### §3 — Destructuration de travail avec P1-42 (ta question)
**Mon plan ne touche pas la vague.** Précisément, pour que tu n'aies pas à le redemander :
- Je **n'écris pas** dans `Assets.Wave`, `Assets.WaveSwell`, ni dans le code client de la vague. Non touchés.
- L'étape 3 ci-dessus est volontairement vide : elle n'est pas de moi.
- Le seul point de contact possible est **esthétique, à l'étape 5** : la houle visible dans le cadre de la hero shot. Je n'en ferai rien sans ton arbitrage — si l'agent P1-42 livre sa houle, je la compose dans la capture comme un élément posé, je ne la modèle pas.
- Si tu veux que je m'en abstienne complètement, dis-le et je tire la houle du cadre de la hero shot.

### §4 — Honnêteté sur le niveau visé, avant que tu ne t'engages
Tu m'as demandé une réponse franche sur les modèles gratuits. **Ma réponse : non, pas seuls, pour le niveau Fortnite / Sea of Thieves.**
- Le gratuit suffit pour le **prototype et le test fermé** : `_DecorLib` couvre décor, lagon, barrière, hero shot. C'est réel.
- Il ne couvre pas **les créatures** (`generate_mesh` ne produit pas d'anatomie crédible ; les modèles Store réalistes sont trop lourds en triangles ou incohérents entre eux — et l'incohérence, ça se voit) ni **la vague** (houle de 55 studs, crête qui s'enroule : du modelé + FX, pas un asset gratuit).
- Le vrai reproche n'est pas le manque de qualité d'un objet, c'est **l'hétérogénéité d'un pack de 40 objets de 6 auteurs**. Ça se voit même bien posé.
Fortnite et Sea of Thieves, c'est des centaines de personnes-années. L'écart n'est pas un multiple d'effort, c'est une équipe et un budget.
Ce que je recommande, décision à toi : gratuit pour le test fermé (comme prévu), **mais décider modéliste/pack cohérent sur les chiffres du test fermé, pas après**. Le test fermé peut être un bon test *technique* ; il ne peut pas être un test de *niveau visuel*. Si on le présente comme le niveau visé, on rejoue le rejet du 09/10. C'est écrit noir sur blanc dans `CREATURES_ART.md` §1, j'y suis favorable.

