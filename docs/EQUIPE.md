# Équipe Tide Rush : qui fait quoi (mis à jour par D le 2026-10-09)

> **Depuis le 09/10 ~15 h** : l'équipe travaille dans des sessions cloud sur le repo GitHub `moaadzne/PROJECT-RBLX`, sans accès à Studio. Les sessions, les branches et les décisions sont dans `docs/TABLEAU.md`. Les comptes-rendus vont à D par send_message. Lundi 12/10 au soir, une session locale réimportera dans Studio les fichiers modifiés. Les règles ci-dessous sur Studio s'appliquent de nouveau à ce moment-là.

Toutes les conversations pilotent **le même Roblox Studio** (même place, même serveur MCP).
Le tableau commun est `ServerStorage.DevNotes` (tableau des tâches, contrat des remotes, demandes, journal).
Les identifiants de session changent à chaque redémarrage : se repérer au **nom** de session.

| Lettre | Rôle | Zone (seule à la modifier) |
|---|---|---|
| A | Gameplay & serveur | ServerScriptService, ReplicatedStorage.Shared (Config), ReplicatedStorage.Remotes |
| B | Interface & feel | StarterGui, StarterPlayer, ReplicatedFirst (effets client dans CurrentCamera, jamais Lighting) |
| C | Monde & art | Workspace.Map, Terrain, Lighting, ReplicatedStorage.Assets, MaterialService, SoundService (SoundGroups) |
| D | Coordinateur, session « CHEF DE PRJT » | Ne développe rien : crée les tâches, valide, fait circuler l'info. Seul interlocuteur de Moaad. Modifie seulement DevNotes. |
| E | Concept & game design | Aucune zone dans Studio (lecture seule). Écrit dans `tide-rush/docs/` et dans une section « CONCEPT (géré par E) » de DevNotes. |

## Règles communes
1. Relire DevNotes avant chaque tâche ; relire un script juste avant de le modifier.
2. Après chaque changement : une ligne dans le JOURNAL de DevNotes, `[lettre hh:mm] quoi, où`.
3. Changer Config ou Remotes : seulement A. Les autres écrivent une demande `[R-xx]` dans la section DEMANDES.
4. Un seul playtest à la fois (le Play est global à Studio) : `PLAYTEST X hh:mm` dans EN COURS.
5. Une seule opération lourde à la fois (terrain, insert_asset, generate_*, captures en série) : `LOURD X hh:mm` dans EN COURS.
6. Ne jamais supprimer, renommer ni déplacer ce qu'on n'a pas créé.
7. Sources locales dans `~/Documents/claude code/tide-rush/src/` (jamais dans /tmp, qui est vidé au redémarrage).
8. Sauvegarde : rien n'est gardé sans Cmd + S de Moaad. La place a été perdue deux fois, les 08 et 09/10.
9. Compte-rendu à D en 3 lignes : fait, testé, besoin.

## Documents
- `docs/PASSATION.md` : vision, concept initial, architecture, état au 08/10.
- `docs/BIBLE_QUALITE.md` : niveau d'exigence, direction artistique, confort, interdits, rétention éthique, définition de « terminé ».
- `docs/BRIEF_E.md` : mission de la conversation Concept & game design.
- `docs/GDD.md` : le concept validé, écrit par E (à venir).

## Décisions de Moaad
- 2026-10-09 : le décor actuel est « vraiment nul » ; il faut le refaire entièrement.
- 2026-10-09 : style choisi : **stylisé console** (façon Fortnite / Sea of Thieves).
- 2026-10-09 : il veut « un vrai concept », fun, avec un vrai but, et que les joueurs aient envie d'acheter : c'est la mission de la conversation E.
- 2026-10-09 : concept choisi : **Reef Keepers** (docs/GDD.md).
- 2026-10-09 : test du jour rejeté (« rien ne va, tout est à revoir ») : tout ce qui se voit est refait à partir de zéro, on ne garde que la plomberie invisible.
