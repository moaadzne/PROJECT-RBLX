# Import dans Studio — lundi 12/10 soir (préparé par F)

But : faire passer le code du repo dans la place Studio, sans rien perdre, puis garder Studio synchronisé avec le repo pour toute la suite.
Qui fait quoi : la **session locale du Mac** (Claude Code avec le MCP Studio) lance les commandes ; **Moaad** fait seulement les clics dans Studio et Cmd + S.

## 1. Verdict : Rojo (méthode b)

| | (a) Import par le MCP Studio | (b) Rojo |
|---|---|---|
| Mise en place | Aucune | Une seule fois, environ 15 min |
| Coût d'un import | La session locale relit et recopie chaque script (environ 25 fichiers aujourd'hui, de plus en plus ensuite), soit beaucoup de tokens, alors que le quota hebdo des sessions locales est déjà le facteur limitant | `git pull`, et Studio se met à jour en quelques secondes, **sans Claude** |
| Fichiers supprimés ou renommés | À gérer à la main (des scripts orphelins restent) | Gérés automatiquement dans les dossiers mappés |
| Risque d'erreur | Copie partielle, échappement des longues chaînes, oubli d'un fichier | Faible : Rojo affiche les changements et attend « Accept » |
| Vitesse d'itération pour la suite | Lente : chaque push du cloud demande une session locale | Rapide : le cloud code toute la semaine, le Mac ne fait que `git pull` |

**Recommandation : Rojo.** Le repo devient la seule source des scripts, et les sessions du cloud continuent de travailler sans Studio.

Règle qui en découle, pour toute l'équipe : **on ne modifie plus dans Studio un script mappé** (Rojo l'écraserait au prochain changement). Un script se modifie dans le repo, puis on fait `git pull`.

## 2. Ce que Rojo touche, et ce qu'il ne touche jamais

`default.project.json` (racine du repo) mappe **seulement les scripts** :

| Dans Studio | Depuis le repo | Remarque |
|---|---|---|
| `ReplicatedStorage.Shared` | `src/ReplicatedStorage/Shared` | Config |
| `ReplicatedStorage.Remotes` | `src/ReplicatedStorage/Remotes` | **optionnel** : seulement si A y met des `*.model.json` (sinon les remotes de Studio restent intactes) |
| `ServerScriptService` | `src/ServerScriptService` | Main + Services |
| `StarterPlayer.StarterPlayerScripts` | `src/StarterPlayer/StarterPlayerScripts` | TideClient |
| `StarterPlayer.StarterCharacterScripts` | `src/StarterPlayer/StarterCharacterScripts` | **optionnel** : Animate, sons du personnage |
| `StarterGui` | `src/StarterGui` | optionnel |
| `ReplicatedFirst` | `src/ReplicatedFirst` | optionnel |

**Jamais touchés** : Workspace (Map, Terrain), Lighting, `ReplicatedStorage.Assets`, MaterialService, SoundService, ServerStorage (DevNotes, Backup_Template).

**Protection de l'existant** (vérifiée le 09/10 avec l'API de `rojo serve` 7.5.1) :
- Les 7 nœuds mappés ont `"$ignoreUnknownInstances": true`. Rojo n'y supprime donc **rien** de ce qui existe seulement dans Studio : remotes v1, interface construite dans Studio, etc.
- Sans ce réglage, Rojo **vidait** StarterGui et ReplicatedFirst, même quand leur dossier est absent du repo. C'est corrigé.
- Ce réglage ne vaut que pour le nœud lui-même. **À l'intérieur** de `Services` et du LocalScript `TideClient`, le repo fait foi : un module supprimé du repo est supprimé dans Studio. C'est voulu, et ces deux endroits sont aujourd'hui identiques au repo (vérifié sur le .rbxl).
- Conséquence : un script supprimé ou renommé **au premier niveau** (par exemple `ServerScriptService.Main`) reste dans Studio comme orphelin. L'étape 8 les liste, et rien n'est supprimé sans l'accord de D.

Prérequis côté repo, déjà signalés aux auteurs le 09/10 :
- **B** : réglé dans 53a9f71 (`TideClient/init.client.lua`). Sans ce renommage, Rojo crée un Folder TideClient, les modules ne sont plus enfants du LocalScript et le client ne charge rien, sans aucune erreur.
- **A** : réglé dans c9b95d2. `Net.lua` crée au démarrage les remotes manquantes à partir d'une liste, et remplace celles qui ont une mauvaise classe. Il n'y a pas de fichier Rojo pour les remotes : le dossier `src/ReplicatedStorage/Remotes` reste absent et Rojo ne touche pas aux remotes de Studio.

## 3. Procédure de lundi

### Étape 0 : avant de commencer (Moaad)
1. Ferme le Roblox Player. Ouvre seulement Roblox Studio avec la place Tide Rush habituelle.
2. Dans la conversation locale du Mac, dis : « on fait l'import de lundi, suis docs/IMPORT_LUNDI.md ».

### Étape 1 : sauvegarde, puis copie de travail (Moaad, obligatoire, dans cet ordre)
1. Si la place est publiée : **File** → **Save to Roblox**. C'est le premier filet, en ligne.
2. **File** → **Save to File As…** → dossier `Documents/claude code/`, nom `TideRush_SAUVEGARDE_2026-10-12.rbxl` → **Save**. Cette copie n'est plus jamais modifiée.
3. Tout de suite après : **File** → **Save to File As…** → même dossier, nom `TideRush_import_2026-10-12.rbxl` → **Save**.
4. Regarde le titre de l'onglet en haut de Studio : il doit afficher `TideRush_import_2026-10-12`. On travaille dans cette copie, et la sauvegarde reste intacte.

Retour arrière à tout moment : fermer Studio **sans sauvegarder**, puis rouvrir `TideRush_SAUVEGARDE_2026-10-12.rbxl`.

### Étape 1 bis : photo de l'existant (session locale, avant toute synchronisation)
Avec le MCP Studio, en mode Edit :
- `search_game_tree` sur `ReplicatedStorage.Remotes`, `Workspace.Map`, `ReplicatedStorage.Assets`, `StarterGui` et `ReplicatedFirst`. Garder la liste.
- `execute_luau` (Edit), pour noter les comptes :
```lua
local RS = game:GetService("ReplicatedStorage")
for _, inst in { RS:FindFirstChild("Remotes"), workspace:FindFirstChild("Map"), RS:FindFirstChild("Assets"), game:GetService("StarterGui"), game:GetService("ReplicatedFirst"), game:GetService("Lighting") } do
	if inst then
		print(inst:GetFullName(), #inst:GetDescendants())
	end
end
```

### Étape 2 : récupérer le repo sur le Mac (session locale)
```bash
cd "$HOME/Documents/claude code"
git --version   # si macOS propose d'installer les « outils de ligne de commande » : Moaad clique Installer, puis on relance
git clone https://github.com/moaadzne/PROJECT-RBLX.git project-rblx   # première fois seulement
cd project-rblx
git fetch origin
git checkout <branche donnée par D lundi>   # intégration : claude/epic-pasteur-q323d7, ou main si D a fusionné
git pull
```
Le dossier `tide-rush/` (anciennes sources locales) n'est plus utilisé : on le garde comme archive, sans le supprimer.
Si `git clone` demande un identifiant, la session locale l'explique à Moaad (connexion GitHub). On ne colle jamais de mot de passe dans le chat.

### Étape 3 : installer Rojo 7.5.1 (session locale, une seule fois)
Mac Intel (MacBook Pro 2016) → binaire `macos-x86_64`. Le téléchargement par `curl` évite le blocage Gatekeeper.
```bash
mkdir -p "$HOME/bin" && cd "$HOME/bin"
curl -sSfL -o rojo.zip https://github.com/rojo-rbx/rojo/releases/download/v7.5.1/rojo-7.5.1-macos-x86_64.zip
unzip -o rojo.zip && rm rojo.zip && chmod +x rojo
./rojo --version          # attendu : Rojo 7.5.1
./rojo plugin install     # installe le plugin Studio de la même version
```

### Étape 4 : redémarrer Studio (Moaad)
1. **Cmd + Q** pour quitter Studio.
2. Rouvre Studio et la place Tide Rush.
3. En haut, onglet **Plugins** : un bouton **Rojo** doit apparaître.

### Étape 5 : lancer le serveur Rojo (session locale)
```bash
cd "$HOME/Documents/claude code/project-rblx"
"$HOME/bin/rojo" serve default.project.json   # laisser tourner ; écoute sur le port 34872
```
À lancer en arrière-plan : il doit tourner tant qu'on travaille dans Studio. Il est léger pour le Mac.

### Étape 6 : connecter Studio (Moaad)
1. Onglet **Plugins** → bouton **Rojo**. Un panneau s'ouvre.
2. Adresse `localhost`, port `34872` (valeurs par défaut) → **Connect**.
3. Rojo affiche la liste des changements. Vérifie qu'elle ne parle **que** de ReplicatedStorage.Shared, ServerScriptService, StarterPlayerScripts (et Remotes, StarterGui, ReplicatedFirst s'ils existent dans le repo). S'il y a **Workspace, Lighting ou Assets** dans la liste → **Abort** et on prévient D.
   **Changements attendus** — liste **revérifiée le 10/10 à 14:40 contre l'intégration**
   (`origin/claude/epic-pasteur-q323d7`), pas contre le .rbxl. La session locale compare quand même avec `rojo sourcemap default.project.json` du jour, qui fait foi.
   - `ServerScriptService.Services` : **ajouts** CreatureFactory, CreatureService, IntroService, LagoonService, StealService, MountService, RoyalService, ShopService ; **suppressions** TreasureService et ItemFactory. Elles sont normales : dans ce dossier, le repo fait foi. Les 9 autres services (DataService, DebugService, Net, PetService, PlotService, SelfTest, Stats, UpgradeService, WaveService) sont mis à jour.
   - `ServerScriptService.Main` et `ReplicatedStorage.Shared.Config` : mis à jour.
   - `ReplicatedFirst` : ajout de `LoadingScreen`.
   - `StarterPlayerScripts.TideClient` — **c'est ici qu'il y a le plus de changements**, 14 modules ajoutés, 5 réécrits :
     - **ajoutés** : `Wave` (le rendu de la vague, P1-42), `Hud`, `Onboarding`, `StealHud`, `RoyalHud`, `Shop`, `Prompts`, `Feel`, `Ambience`, `ChatStyle`, `NameTags`, `World`, `PoolBillboards`, `MountButton` ;
     - **réécrits** : `Store`, `Theme`, `Components`, `Fx`, `Notifications` ;
     - **renommé** : `TideClient.client.lua` → `init.client.lua`. **C'est la seule suppression hors de `Services`**, et elle est voulue. Si elle n'apparaît pas, le LocalScript n'est pas rechargé et le client ne démarre pas.
   - **Ne doivent surtout pas apparaître** : `Workspace`, `Terrain`, `Lighting`, `ReplicatedStorage.Assets`, `MaterialService`, `SoundService`, `ServerStorage`. Ces nœuds ne sont pas mappés ; s'ils apparaissent, c'est que la place a changé → **Abort**.

   **Deux choses que Rojo ne touche pas, mais qui restent visibles en jeu :**
   - **`StarterGui` n'existe pas dans le repo.** Rojo n'y touche donc rien, et **l'ancienne interface construite dans Studio reste**. Le nouveau HUD est créé dans `PlayerGui` avec `DisplayOrder` 5 et 20, donc l'ancienne UI passe *derrière* et reste visible là où le nouveau HUD est transparent. Elle utilisait des emojis comme glyphes (DIRECTION_V2 les interdit, §8 bis). **À vérifier à l'étape 7 et à masquer avant toute capture** — sinon on rejoue le rejet du 09/10.
   - **`ReplicatedStorage.Remotes` : absent du repo** (`Net.lua` crée les remotes au démarrage). Si la liste Rojo parle de `Remotes`, c'est anormal.
4. Si la liste correspond → **Accept**.
5. **Cmd + S**.

### Étape 7 : vérifier la synchronisation (session locale, juste après l'étape 6, AVANT de toucher au monde)
- [ ] **Existant intact** : on relance le même `search_game_tree` et le même `execute_luau` qu'à l'étape 1 bis. Remotes, Map, Assets, StarterGui, ReplicatedFirst et Lighting ont **les mêmes comptes qu'avant**. Remotes et StarterGui peuvent seulement avoir **plus** d'éléments, si le repo en ajoute. S'il manque quoi que ce soit : on ferme sans sauvegarder, on rouvre la sauvegarde et on prévient D.
- [ ] Les scripts de Studio correspondent à `rojo sourcemap default.project.json` : mêmes noms, mêmes classes. TideClient est bien un **LocalScript** qui contient ses modules.
- [ ] **Orphelins** : on liste les Script, LocalScript et ModuleScript du premier niveau (ServerScriptService, StarterPlayerScripts, Shared, Remotes) qui ne figurent pas dans le sourcemap, et on envoie la liste à D. Aucune suppression sans son accord.
- [ ] Mode Edit : aucune erreur rouge dans l'Output.
- [ ] **Cmd + S** (Moaad).

### Étape 8 : construire le monde de C, AVANT tout test (session locale avec le MCP)
Pourquoi c'est dans cet ordre : le serveur de A (île ouverte, 1ba0aa3) a besoin de l'île de C. Il lui faut les lagons au format `Center` + `Radius` et les anneaux de sable. Sans eux, les créatures n'ont aucun sol valide : le serveur tourne, mais la plage reste vide.

Règles :
- Les scripts sont dans `tools/world/` (hors Rojo). On les lance avec `execute_luau` en mode Edit.
- **La liste et l'ordre exacts sont ceux de `tools/world/README.md` le jour J**, car C y ajoute l'île (P1-36).
- Pour chaque script, dans l'ordre :
  1. `DRY_RUN = true` : on lit la sortie, et rien n'est modifié ;
  2. `DRY_RUN = false` : construction réelle. Chaque script forme un seul enregistrement, annulable par Cmd + Z ;
  3. contrôle rapide (`search_game_tree` ou capture) ;
  4. **Cmd + S** (Moaad) avant le script suivant.
- **Une seule opération lourde à la fois** : jamais deux scripts en parallèle, jamais pendant un Play.

Ordre attendu (à confirmer dans le README de C) :
1. `inspect_world` (inventaire, ne modifie rien), puis correction des tables `FIND` et positions indiquées par C ;
2. **l'île** (terrain 600×600, crique centrale, anneaux de sable, 3 points d'intérêt) ;
3. les **lagons** des 8 bases au format `Center` + `Radius`, avec leur **barrière** (`PlotN.Barrier`) ;
4. les **8 tours** (`Towers/TowerN` avec l'attribut `Center`) ;
5. la **vague** (`build_wave`) ;
6. les **FX** (`build_mutation_fx`, puis `build_royal_fx` une fois la couronne importée) ;
7. les **sons** (`build_sounds`).

Contrôle du contrat de la carte (après le point 4), `execute_luau` en mode Edit :
```lua
local map = workspace:FindFirstChild("Map")
local plots = map and map:FindFirstChild("Plots")
for i = 1, 8 do
	local p = plots and plots:FindFirstChild("Plot" .. i)
	print("Plot" .. i, p and p:GetAttribute("Center"), p and p:GetAttribute("Radius"), p and p:GetAttribute("SpawnPos"))
end
local towers = map and map:FindFirstChild("Towers")
print("Tours :", towers and #towers:GetChildren() or 0)
```
Les 8 bases doivent avoir `Center`, `Radius` et `SpawnPos`, et il doit y avoir 8 tours. Sinon, on s'arrête et on prévient C et D.

### Étape 9 : tests de A, dans cet ordre (session locale ; Moaad fait Cmd + S avant chaque Play)
Les commandes passent par `ServerStorage.TR_Debug` (Studio seulement), en contexte **Server** pendant le Play. `Invoke("help")` donne la syntaxe exacte.
1. **selftest** : tout est PASS.
2. **intro** : la vague d'intro personnelle et la Golden de bienvenue se déroulent.
3. **playtime** : on sort de la protection débutant.
4. **tide Golden** : la marée dorée, les mutations et la lumière.
5. **give HawksbillTurtle**, puis **grow** jusqu'à Elder : la monture est disponible (bouton Monter).
6. **Vol à 2 joueurs** : Test → Clients and Servers, 2 joueurs. Attention, le Mac est faible : on ferme tout le reste avant. Si Studio rame trop, ce test se fait sur téléphone après la publication.

Pendant tout le test :
- [ ] Console **sans erreur ni warning** du jeu.
- [ ] L'interface s'affiche ; le joueur reçoit sa base ; la vague vient de la direction annoncée.
- [ ] La plage n'est pas vide : des créatures apparaissent dans les anneaux.

### Étape 10 : fin
- [ ] Arrêt du Play, puis **Cmd + S**, puis **File → Save to Roblox** si la place est publiée.
- [ ] Compte-rendu à D en 3 lignes : fait, vérifié, besoin.

## 4. Les fois suivantes (2 minutes)
1. Session locale : `git pull` dans `project-rblx`, puis `rojo serve default.project.json` s'il n'est pas déjà lancé.
2. Moaad : **Plugins → Rojo → Connect** (après chaque ouverture de Studio), puis **Accept**.
3. Playtest court, puis **Cmd + S**.

Jamais de synchro pendant un Play : on arrête le Play avant `git pull`.

## 5. Réglages Avatar (Moaad, une seule fois, décision de D du 09/10)
On garde l'avatar de chaque joueur, avec R15, des proportions identiques pour tous et nos animations (VISION_TON §6.3).
Prérequis : la place est publiée (File → Save to Roblox). Sinon, Game Settings reste grisé.

1. Dans Studio, onglet **Home** → bouton **Game Settings**.
2. Dans la colonne de gauche → **Avatar**.
   Si cette page renvoie vers « Avatar Settings » : onglet **Avatar** du ruban → **Avatar Settings**. On y retrouve les mêmes réglages.
3. **Avatar Type** → **R15**.
4. **Animation** → **Standard** (tout le monde a les mêmes animations ; les nôtres les remplaceront via le script `Animate`).
5. **Scale** : pour Height, Width, Head, Body Type et Proportions, mets le **minimum égal au maximum** pour que tout le monde ait les mêmes proportions.
   Valeurs proposées, à valider sur capture : Height 100 %, Width 100 %, Head 100 %, Body Type 100 %, Proportions 0 %.
6. **Save** en bas à droite, puis **Cmd + S**.

Vérification (session locale) : playtest court, capture de l'avatar de Moaad à côté d'un bassin. Les proportions ne doivent pas faire tache à côté du décor. La capture va à D, qui valide les valeurs.
