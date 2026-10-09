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
| `StarterGui` | `src/StarterGui` | optionnel |
| `ReplicatedFirst` | `src/ReplicatedFirst` | optionnel |

**Jamais touchés** : Workspace (Map, Terrain), Lighting, `ReplicatedStorage.Assets`, MaterialService, SoundService, ServerStorage (DevNotes, Backup_Template), StarterCharacterScripts.

**Protection de l'existant** (vérifiée le 09/10 avec l'API de `rojo serve` 7.5.1) :
- Les 6 nœuds mappés ont `"$ignoreUnknownInstances": true`. Rojo n'y supprime donc **rien** de ce qui existe seulement dans Studio : remotes v1, interface construite dans Studio, etc.
- Sans ce réglage, Rojo **vidait** StarterGui et ReplicatedFirst, même quand leur dossier est absent du repo. C'est corrigé.
- Ce réglage ne vaut que pour le nœud lui-même. **À l'intérieur** de `Services` et du LocalScript `TideClient`, le repo fait foi : un module supprimé du repo est supprimé dans Studio. C'est voulu, et ces deux endroits sont aujourd'hui identiques au repo (vérifié sur le .rbxl).
- Conséquence : un script supprimé ou renommé **au premier niveau** (par exemple `ServerScriptService.Main`) reste dans Studio comme orphelin. L'étape 8 les liste, et rien n'est supprimé sans l'accord de D.

Prérequis côté repo, déjà signalés aux auteurs le 09/10 :
- **B** : renommer `TideClient/TideClient.client.lua` en `TideClient/init.client.lua`. Sinon Rojo crée un Folder TideClient, les modules ne sont plus enfants du LocalScript et le client ne charge rien, sans aucune erreur.
- **A** : décider comment naissent les remotes v2 (`Net.lua` fait `WaitForChild` sans délai) : soit créées par Net au démarrage, soit en fichiers `src/ReplicatedStorage/Remotes/<Nom>.model.json`. Les remotes v1 de Studio sont conservées dans les deux cas.

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
4. Sinon → **Accept**.
5. **Cmd + S**.

### Étape 7 : le monde de C (hors Rojo, session locale avec le MCP)
Ce qui n'est pas un script (lagon, décor, FX, sons) passe toujours par le MCP Studio : on exécute les scripts de C (`tools/world/…`) avec `execute_luau`, en suivant leur README, une opération lourde à la fois.
Ensuite **Cmd + S**.

### Étape 8 : vérification (session locale, puis Moaad)
- [ ] **Existant intact** : on relance le même `search_game_tree` et le même `execute_luau` qu'à l'étape 1 bis. Remotes, Map, Assets, StarterGui, ReplicatedFirst et Lighting ont **les mêmes comptes qu'avant**. Remotes et StarterGui peuvent seulement avoir **plus** d'éléments, si le repo en ajoute. S'il manque quoi que ce soit : on ferme sans sauvegarder, on rouvre la sauvegarde et on prévient D.
- [ ] Les scripts de Studio correspondent à `rojo sourcemap default.project.json` : mêmes noms, mêmes classes. TideClient est bien un **LocalScript** qui contient ses modules.
- [ ] **Orphelins** : on liste les Script, LocalScript et ModuleScript du premier niveau (ServerScriptService, StarterPlayerScripts, Shared, Remotes) qui ne figurent pas dans le sourcemap, et on envoie la liste à D. Aucune suppression sans son accord.
- [ ] Mode Edit : aucune erreur rouge dans l'Output.
- [ ] Playtest court (Moaad a fait Cmd + S avant) : console **sans erreur ni warning** du jeu.
- [ ] `selftest` du TR_Debug, côté serveur, pendant le Play (`execute_luau` en contexte Server) : tout est PASS (la liste des tests dépend de la version de A).
- [ ] L'interface s'affiche, le joueur reçoit sa base, la vague passe.
- [ ] Arrêt du Play, puis **Cmd + S**, puis **File → Save to Roblox** si la place est publiée.
- [ ] Compte-rendu à D en 3 lignes : fait, vérifié, besoin.

## 4. Les fois suivantes (2 minutes)
1. Session locale : `git pull` dans `project-rblx`, puis `rojo serve default.project.json` s'il n'est pas déjà lancé.
2. Moaad : **Plugins → Rojo → Connect** (après chaque ouverture de Studio), puis **Accept**.
3. Playtest court, puis **Cmd + S**.

Jamais de synchro pendant un Play : on arrête le Play avant `git pull`.
