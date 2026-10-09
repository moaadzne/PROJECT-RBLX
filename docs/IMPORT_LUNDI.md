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

Attention : dans un dossier mappé, Rojo **supprime** ce qui n'existe pas dans le repo. C'est voulu pour les scripts. Mais si A met un dossier `src/ReplicatedStorage/Remotes`, il faut **un fichier pour chaque remote**, v1 comprises.

Prérequis côté repo, déjà signalés aux auteurs le 09/10 :
- **B** : renommer `TideClient/TideClient.client.lua` en `TideClient/init.client.lua`. Sinon Rojo crée un Folder TideClient, les modules ne sont plus enfants du LocalScript et le client ne charge rien, sans aucune erreur.
- **A** : décider comment naissent les remotes v2 (`Net.lua` fait `WaitForChild` sans délai) : soit créées par Net au démarrage, soit en fichiers `*.model.json`.

## 3. Procédure de lundi

### Étape 0 : avant de commencer (Moaad)
1. Ferme le Roblox Player. Ouvre seulement Roblox Studio avec la place Tide Rush habituelle.
2. Dans la conversation locale du Mac, dis : « on fait l'import de lundi, suis docs/IMPORT_LUNDI.md ».

### Étape 1 : sauvegarde du .rbxl (Moaad, obligatoire)
1. Dans Studio : menu **File** → **Save to File As…**
2. Dossier : `Documents/claude code/`. Nom : `TideRush_avant_import_2026-10-12.rbxl` → **Save**.
3. Si la place est publiée : **File** → **Save to Roblox** aussi. La version en ligne sert de second filet.

Retour arrière à tout moment : fermer Studio **sans sauvegarder**, puis rouvrir ce fichier.

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
- [ ] Les scripts de Studio correspondent à `rojo sourcemap default.project.json` : mêmes noms, mêmes classes. TideClient est bien un **LocalScript** qui contient ses modules.
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
