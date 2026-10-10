# Directive — passer du prototype au jeu

**Émise par D le 2026-10-10. Elle prime sur la priorité de n'importe qui.**

---

## Le problème, sans filtre

Le 09/10, Moaad a vu un test et l'a rejeté : « rien ne va, tout est à revoir ». Depuis, l'équipe a produit beaucoup. Comptons ce qui existe :

- **17 services serveur** : sauvegarde, anti-triche, vol, monture, lagons, marées, boutique, Couronne royale
- **18 modules client** : HUD, intro, boutique, vol, notifications
- **World.lua** : pièce, avant-première, crêtes, embruns
- **Un monde scripté** : île 600×600, criqué, 3 anneaux, récif
- **Un GDD de 476 lignes** figé sur le contrat v2.1

Puis comptons ce qui n'existe pas :

- **Aucun playtest.** Zéro. Jamais. Personne n'a jamais vu ce jeu tourner.
- **Aucun modèle de créature.** `Config.LegacyItemToCreature` recycle des trésors : un crate et un poisson sont le même objet.
- **Aucun rendu du monde.** Le plan de situation que j'ai produit est une carte 2D, pas le jeu.
- **Aucune animation propre** à part un pack Roblox générique.

**Conclusion qui doit être lue une fois et retenue : l'écart avec un jeu fini n'est pas du polish. C'est qu'il n'y a pas encore de jeu. On a un moteur et zéro expérience jouée.**

Tout ce qui suit en découle.

---

## La règle unique, pour toute l'équipe

> **Une tâche qui ne se voit pas dans une capture n'est pas terminée.**

Elle remplace toute définition antérieure du mot « fini ».

Concrètement, une tâche est finie quand Moaad peut en faire une capture et voir la différence. Tout le reste — le code propre, l'architecture, les tests unitaires — compte, mais ne vaut pas une tâche inachevée.

---

## Ce qu'on cesse de faire, immédiatement

1. **Écrire du code que personne ne voit.** Une fonction parfaite dans un module non chargé est du travail perdu. Si le jeu ne l'appelle pas encore, on n'écrit pas.
2. **Ajouter des fonctionnalités.** Le jeu n'est pas jouable, il n'a pas besoin d'une dixième mécanique. Phase 2, semaine 2, `docs/SEMAINE_2.md` : rien ne s'ouvre tant que la Phase 1 n'est pas jouable.
3. **Réécrire ce qui marche.** La plomberie invisible est validée, on n'y touche plus.
4. **Faire des plans de monde.** L'île est scriptée. LaPriority est de la *voir*, pas de la redessiner.
5. **Compter les commits.** 12 commits d'avance sur l'intégration ne valent pas une image de plus.

---

## La barre, par rôle

### A — serveur
Ta mission n'est pas de nouvelles mécaniques. C'est que **le jeu se lance et reste stable**. Une session de 10 minutes sans crash, sans erreur console, sauvegarde et rechargement corrects. Un serveur qui plante au bout de 4 minutes ne vaut rien, quelle que soit la qualité du code.

### B — interface
Tu as le système visuel console, la police, les panneaux. Il n'a **jamais été affiché**. Ton premier livrable n'est pas une fonctionnalité : c'est une capture d'écran de l'interface en jeu, lisible, sans emoji, sans bloc gris. Le reste vient après.

### C — monde
L'île est scriptée et n'a **jamais été rendue**. Ta première tâche n'est pas un monument de plus : c'est une capture de l'île avec la vague dessus. Le monde existe en chiffres, il n'existe pas à l'écran.

### E — concept
Le GDD est écrit, il est figé, il est intégré. **Il est suffisant.** Ta seule tâche utile maintenant : clarifier en français simple ce que le joueur verra dans la première heure. Pas de nouveau système, pas de Phase 2.

### F — qualité
Tu as trouvé le vrai P0 de la vague. Continue. Mais ta mission de lancement : **définir ce que « ça marche » veut dire**, en une liste de 10 vérifications qu'on coche en Monday. Pas un audit de plus.

---

## Le vrai problème de fond

Le test rejeté du 09/10 a produit une réaction saine — tout refaire — puis une réaction malsaine : reconstruire avant d'avoir jamais regardé.

**On est en train de répéter l'erreur.** On repasse des semaines à écrire du code pour un jeu que personne n'a vu, alors que la seule chose qui manque est un coup d'œil.

La priorite n° 1 du projet n'est plus une fonctionnalité. C'est :

> **Mettre le jeu dans un navigateur Monday soir et regarder ce qui se passe.**

Tout le reste est secondaire. Si une tâche ne sert pas directement cet objectif, elle attend.

---

## Ce que D s'engage à faire

- Protéger ce temps : aucune nouvelle tâche de feature tant que le jeu n'a pas été vu.
- Ne pas demander de Decisions sur des détails d'interface tant qu'aucune capture n'existe.
- Porter à Moaad uniquement les choix qui coûte�� du temps ou de l'argent.

Et dire la vérité quand une chose est moins avancée qu'elle n'en a l'air.
