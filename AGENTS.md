# Tide Rush — règles d'équipe (lu automatiquement au démarrage)

> Ce fichier est le canal commun. Toute session qui travaille dans ce repo le lit.
> Il n'est pas décoratif : il remplace le besoin de se réveiller mutuellement.

## 1. Au démarrage, tu lis ces 3 fichiers, dans cet ordre

1. `AGENTS.md` (ce fichier) — les règles
2. `docs/TABLEAU.md` — les décisions de Moaad et l'état des tâches
3. `docs/EQUIPE.md` — ta zone et ce que tu ne touches pas

Puis, selon ta lettre :

- **A** serveur : `review/review_context.md` (contrat v2.1, fait foi)
- **B** interface : `docs/UI_REEF.md`
- **C** monde : `docs/DA_MONDE.md`
- **E** concept : `docs/GDD.md` et `docs/GDD_REEF.md`
- **D, F** : rien d'autre au démarrage

## 2. Qui parle à qui

- **Moaad ne parle qu'à D.** D est le seul qui lui répond.
- **D** arbitre, valide, donne le feu vert. D ne développe pas.
- **A, B, C, E** : coordination technique directe autorisée entre eux (noms, attributs, contrat des remotes, assets). **A reste propriétaire du contrat.**
- Pour un conflit entre deux zones, on n'attend pas D : on se tranche entre les deux interestés et on l'écrit dans le tableau.

## 3. Règle d'or : ne réveille personne

⚠️ **C'est la règle la plus importante du fichier.**

Le budget de Moaad est épuisé. Les réveils automatiques ont déjà coûté de l'argent pour rien.

- ❌ **Interdit** : `send_message` à une autre session « pour savoir où elle en est », « pour la relancer », « pour proposer un coup de main » sans blocage réel.
- ❌ **Interdit** : mettre en place une vérification automatique, une surveillance de PR, un rappel planifié, un « je reviens dans 15 min ».
- ❌ **Interdit** : envoie un message « ok » pourDire qu'on est vivant.
- ✅ Autorisé : écrire une question ou une décision **dans `docs/TABLEAU.md`**. C'est asynchrone, gratuit, et la personne la verra à sa prochaine session.
- ✅ Autorisé : `send_message` uniquement pour un **blocage critique** qui empêche le jeu de tourner (bug qui casse le jeu, fichier manquant, décision impossible à prendre).

**Si tu n'as rien de nouveau à dire : dis-le en une ligne et arrête-toi. Le silence coûte moins cher qu'un message.**

## 4. Budget et arrêt

- Le quota hebdo de Moaad se réinitialise le **12/10 à 21 h**.
- Si tu touches une limite de credits : **arrête-toi net**, pousse ce qui est en cours, et dis-le. Ne commence pas une tâche que tu ne peux pas finir.
- Ne lance jamais SelfTest, une suite de luau-analyze complète, ou une campagne de captures « pour être sûr » si la tâche n'est pas verifiée en jeu de toute façon.

## 5. Format de compte-rendu (3 lignes, pas plus)

```
FAIT      : ce qui est poussé, avec le commit
VÉRIFIÉ   : ce que tu as réellement exécuté (rien = « rien testé en jeu »)
BESOIN    : ce qui te manque, et de QUI
```

Un compte-rendu de 40 lignes est un compte-rendu raté.

## 6. Zones (ne pas toucher ce qui n'est pas à toi)

| Lettre | Zone | Seul à modifier |
|---|---|---|
| A | Gameplay & serveur | `ServerScriptService`, `ReplicatedStorage.Shared` (Config), `ReplicatedStorage.Remotes` |
| B | Interface & feel | `StarterGui`, `StarterPlayer`, `ReplicatedFirst` |
| C | Monde & art | `Workspace.Map`, `Terrain`, `Lighting`, `ReplicatedStorage.Assets`, `MaterialService`, `SoundService` |
| D | Coordination | `docs/` uniquement. Ne développe rien. |
| E | Concept | `docs/` uniquement, en lecture sur le reste. |
| F | Contrôle qualité | Lecture. N'écrit que dans `docs/`. |

- Changer `Config` ou les Remotes : **A seul**. Les autres écrivent une demande dans le tableau.
- **Ne jamais supprimer, renommer ni déplacer ce qu'on n'a pas créé.**
- Une seule opération lourde à la fois (terrain, `generate_*`, captures en série) : entente directe entre les deux sessions concernées.

## 7. References — qui fait foi

En cas de conflit, dans cet ordre :

1. `review/review_context.md` (contrat v2.1) — pour les noms, attributs, remotes
2. `docs/DIRECTION_V2.md` — pour la direction, le ton, le style
3. `docs/TABLEAU.md` — pour l'état des tâches et les décisions
4. `docs/GDD.md` / `docs/GDD_REEF.md` — pour le design

⚠️ **`docs/ARCHI_SERVEUR_REEF.md` est PÉRIMÉ.** Il se déclare dépassé ligne 3 et contredit le code livré. Ne l'implémente pas au littéral : il décrit une réserve (`storage`), un dictionnaire `creatures` séparé, `MoveCreature`/`SellCreature`/rebirth, `Pools/PoolN`, `Species` et `TideType` — tout ça n'existe pas dans le contrat v2.1.

## 8. Avant lundi 12/10 — la liste noire

Ne présente **jamais** à Moaad un test technique brut comme un résultat. La prochaine chose visible doit être au niveau visé.

Trois pièges connus, à vérifier avant toute présentation :

1. **La vague n'est rendue par aucun module client** (`Assets.Wave` inutilisé) et le client calcule encore sur l'ancien axe Z. Le serveur, lui, attrape les joueurs correctement → *joueurs pris par une vague invisible*. C'est la star du jeu.
2. **Le `.rbxl` du repo est en retard sur les branches.** Sans sync Rojo lundi, le fix `Net.lua` n'est pas dans la partie jouée.
3. **L'ancienne UI utilisait des emojis comme glyphes** et l'ancien décor est en blocs gris. Masqué avant toute capture, sinon on rejoue le rejet du 09/10.

## 9. Lundi 12/10 au soir — la procédure

Tout est dans `docs/IMPORT_LUNDI.md` : la liste exacte des changements que Rojo va afficher, les protections, et ce sur quoi Moaad doit cliquer « Accept » en confiance. **Le repo fait foi** : Rojo retire tout seul les vieux scripts, pas besoin de les supprimer à la main.

Rappel : tout ce qui se voit avait été rejeté par Moaad le 09/10. Ce qui reste, c'est une **scène au niveau visé**, pas un test.
