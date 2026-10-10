# Les 10 vérifications de lundi — « ça marche » veut dire ça

> Écrit par F le 2026-10-10, après `docs/DIRECTIVE_NIVEAU.md`.
> Le jeu n'a **jamais** été lancé. Chaque ligne est à cocher **en jeu**, lundi.
> Une ligne qu'on ne peut pas cocher n'est pas terminée : elle se répare ou elle s'assume.
>
> Commandes de test : `game.ServerStorage.TR_Debug:Invoke("<cmd>")` (`src/ServerScriptService/Services/DebugService.lua:20-38`).
> Toutes les valeurs de référence viennent de `src/ReplicatedStorage/Shared/Config.lua`.

---

## 0. Avant tout — la session de 10 minutes

☐ **0.1 — Ça se lance et ça ne plante pas.** Un serveur, 10 minutes, deux joueurs. Zéro crash, zéro erreur rouge dans la console serveur. *C'est la barre minimale : un serveur qui tombe au bout de 4 minutes ne vaut rien.*

☐ **0.2 — On voit l'île et on voit un personnage.** Capture d'écran. Un personnage lisible qui se déplace sur un décor qui n'est pas un cube gris. *Si on ne peut pas faire cette capture, le jeu n'existe pas.*

---

## 1. La vague — la star du jeu

☐ **1.1 — Le mur d'eau arrive par le sud.** `forceWave`. Compte à voix haute : **35 s** de calme, puis **7 s** d'alerte, puis le mur entre. Écran filmé. *Une capture sans vague ne vaut rien.*

☐ **1.2 — Le mur va dans la bonne direction, sur les 4 sens.** `direction N` puis `forceWave`, filmed. Puis E, puis W, puis S. Le mur traverse l'île **dans le bon sens** à chaque fois. *C'est le P0 que j'ai trouvé et fait corriger : si E ou W est immobile, on est sur le bug d'origine.*

☐ **1.3 — La vague attrape vraiment.** Se placer **hors de la crique** (au-delà de 70 studs du centre), pieds au sol. Le mur arrive → l'écran bascule, le sac est perdu, retour à la base **0,8 s** plus tard. Le joueur **posé sur une tour** (pieds au-dessus de 30) n'est **pas** pris.

☐ **1.4 — Le crique protège.** Entrer dans le rayon de 70 studs pendant que le mur passe : on est **pris** et rien d'autre. *C'est écrit dans le contrat, personne ne l'a jamais vu.*

---

## 2. Ce qui se gagne

☐ **2.1 — Attraper puis déposer.** Marcher sur une créature sur le sable → elle rentre dans le sac (`Bag` affiché). Entrer dans sa base → elle se pose dans un bassin. Le `leaderstats Coins` **monte de 1 en 1** chaque seconde. *Un compteur qui reste à 0 en vidant l'écran, c'est un échec.*

☐ **2.2 — Lejoueur est au bon endroit.** Sortir de la zone des anneaux, se poser **sur une tour à Y = 34**, attendre. Le compteur d'onde **monte** et le compteur de temps **recule** : les deux visibles à l'écran en même temps.

---

## 3. Les lagons

☐ **3.1 — L'lagun est visible et fermé au calme.** Un nouveau compteur rejoint le serveur. Sa barrière est **baissée**, on ne peut pas entrer. Le joueur entre chez lui.

☐ **3.2 — L'lagon s'ouvre à l'alerte et se referme au reflux.** `forceWave`. À l'alerte : la barrière **monte**. Pendant la fenêtre : on entre et on prend une créature d'un bassin avec `StartSteal` (maintenir 1 s). Au reflux : la barrière **redescend**.

---

## 4. Sauvegarde — la seule plomberie jugée sur 10 ans

☐ **4.1 — On quitte et on revient, rien n'est perdu.** `addCoins 5000`, déposer 2 créatures, **quitter le jeu**, revenir. Les 5 000 pièces et les 2 bassins sont **toujours là**. *La plomberie invisible est la seule chose qui a déjà été validée. Elle ne doit pas casser.*

---

## 5. Ce qu'on ne peut pas cocher lundi — à assumer

☐ **5.1 — Liste à écrire honnêtement.** Cocher ce qui est faisable en 10 minutes le lundi. Écrire noir sur blanc ce qui ne l'est pas. *Un test qui n'a pas été fait ne s'annonce pas comme fait.*

---

## Ce qui n'est pas dans cette liste, et pourquoi

- **Le vol entre joueurs, la monture, la boutique, la Marée Royale, la marée extrême** : cinq mécaniques, pas dix. Elles existent en code mais le jeu n'a jamais tourné — les vérifier lundi ferait échouer la moitié de la liste pour des raisons qui ne sont pas des bugs. Elles passent **derrière** la vague.
- **Le vol, en particulier** : il dépend de la protection débutant, du verrou de lagon et des 2 vagues de protection. Sur un serveur frais, un nouveau joueur est `newbie` : il ne peut ni voler ni être volé. Le test ne mesurerait pas le vol, il mesurerait la protection.

---

## La règle de la directive, rappelée ici

> Une tâche qui ne se voit pas dans une capture n'est pas terminée.

Donc, lundi, chaque ligne cochée doit pouvoir **devenir une capture**. Une ligne qu'on coche sans image, c'est une ligne qu'on n'a pas vraiment vérifiée.