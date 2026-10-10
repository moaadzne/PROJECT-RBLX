# Le secret de l'épave — proposition E pour la semaine 2 (10/10)

**Statut : proposition d'E, à trancher par D.** Je n'ai pas inventé de lore neuf : le socle est déjà écrit par E dans `GDD.md` §6 bis (épave, gravures, plot twist du dormeur) et §4.2 (espèces). Ici je **découpe ce qui peut être construit lundi**, avec ce que ça coûte à chacun.

> **Rappel de la règle qui gouverne tout ce document** (`GDD.md` §6 bis) : *chaque secret se **voit** avant d'être lu. Un joueur de 10 ans le remarque, un joueur de 25 ans veut comprendre.* Aucun texte, aucun clic, aucune vidéo. Un indice visuel ou sonore, rien d'autre.

## 1. Ce qui est déjà en Phase 1, et ce qui s'y ajoute

| | Phase 1 (lancement) | Semaine 2 (le présent document) |
|---|---|---|
| L'épave | **repère visible** sur la plage (`DA_MONDE.md` §4.1, POI ouest) | émerge, et se voit |
| Ce qu'elle contient | rien | la cale, ouverte par la marée extrême |
| Créatures | aucune | `LeopardRay` (Rare) + `GiantPacificOctopus` (Epic) |

**Point important : l'épave n'est pas une nouvelle zone à construire.** C'est le même objet `Map.POIs.Wreck` que C dessine déjà en Phase 1 comme repère. La semaine 2 ne change pas sa position ni sa silhouette — **elle change ce qui se passe quand la mer se retire**. C'est la différence entre un décor et un secret.

## 2. Les trois temps, et le repère visuel de chacun

La cale n'est accessible que pendant la fenêtre de la marée extrême (`Config.ExtremeTide`, ~25 s, ~1 fois par heure). Donc **le secret a une horloge**. C'est ce qui le rend stressant, et c'est gratuit : aucune logique serveur nouvelle.

### Temps 1 — le signe (à T−15 s, avant même que la mer recule)

- Les **mouettes** du secteur se envolent en même temps et **volent vers l'intérieur de l'île**, pas vers le large. C'est le seul indice, et il suffit.
- Le sable autour de l'épave commence à **sonner creux** quand on marche dessus : le bruit change sous les pas.
- Pas de texte, pas d'icône, pas de popup.

### Temps 2 — l'émergence (pendant la fenêtre)

La mer se retire plus loin que d'habitude. **L'épave bascule** : elle est posée de travers sur le sable, proue vers le large, et elle **descend d'un cran** quand l'eau baisse. Le joueur qui court vers elle voit la cale s'ouvrir.
- Le sons : un grincement de bois et de métal, long, une seule fois.
- La cale est **dans l'eau basse**, pas sèche : c'est une baignade, pas une fouille.

### Temps 3 — la gravure (le vrai secret)

Au fond de la cale, **une gravure sur la quille**, que l'eau masque presque. Pas de texte, **une silhouette immense et arrondie** sous l'île, et une série de lignes qui montent vers la surface.

C'est le plot twist de `GDD.md` §6 bis : **la mer n'est pas vide, les tsunamis ne sont pas naturels, chaque vague est une respiration.** Le joueur ne lit rien — il voit une forme. Il ne compris pas ce qu'il vient de regarder, et c'est exactement ce qu'il faut.

> **⚠️ Point de conception à respecter absolument.** Cette gravure **ne donne aucun pouvoir, aucune créature, aucune pièce**. Elle est purement narrative. Un secret qui récompense est un secret qui se vengera quand on le nerf : ici il n'y a rien à nerfer, donc il peut rester gratuit pour toujours. C'est aussi la règle « aucun secret payant, aucun secret indispensable » de §6 bis.

## 3. Ce qu'on y gagne

| Espèce | Rareté | Pourquoi elle est là |
|---|---|---|
| `LeopardRay` | Rare | Elle vit par petits groupes dans les épaves. C'est **biologiquement vrai**, donc ça ne sonne pas comme un loot-hoard posé là. |
| `GiantPacificOctopus` | Epic | Même raison : un poulpe géant s'installe dans une coque de bateau. |

Ce sont les deux espèces que `GDD_REEF.md` §14 nº 2 a assignées à l'épave, et **les deux sont déjà dans `Config.Creatures`** — A n'a rien à ajouter, C a deux modèles à faire. C'est le lot de la semaine 2 le plus honnête qu'on puisse sortir : il rend un POI déjà visible suddenly vivant, avec le contenu exact que le design prévoyait.

**Elles repartent avec la mer.** Comme celles du récif (`Config.ExtremeTide`), le serveur les retire à la fin de la fenêtre. Personne ne peut camper l'épave.

## 4. Ce que ça ne doit pas devenir

- **Pas de mini-boss, pas de combat, pas de chronomètre à l'écran.** Le stress vient de la vague qui revient, pas d'un HUD.
- **Pas de porte à ouvrir, pas de clé, pas d'énigme.** Le joueur court, il regarde, il repart.
- **Pas de vidéo.** Le secret le plus puissant du jeu ne doit pas être une lecture.
- **Pas de récompense unique non répétable.** Si l'épave ne se reproduit pas, les joueurs vidéogames l'épuisent en 3 jours et c'est fini. Elle revient chaque marée extrême, comme le récif.

## 5. Répartition — ce qui est à qui

**[C] monde et art** (le vrai travail)
- Émergence de l'épave : la proue qui descend, ~1 s, jouable par le client depuis `wave.extreme` qu'il reçoit déjà.
- La cale : fond de coque, bordées, algues. **Peu de pièces** — c'est un détail vu 25 s, une fois par heure.
- La gravure sur la quille : une seule silhouette, incrustée, **pas de texte, pas de glyphes**. Le point le plus important du doc pour C.
- Son de grincement + changement de pas sur le sable creux.

**[A] serveur** — **presque rien, et c'est voulu**
- Tirer les 2 espèces dans `Config.ExtremeTide.creatures` au lieu des 2 actuelles. C'est 2 lignes, pas un service.
- ⚠️ **Si A ne le fait pas, le secret n'existe pas** : l'épave restera un décor posé sur le sable. C'est le seul point du doc où le serveur n'est pas optionnel.

**[B] interface** — **rien du tout**
- Aucun popup, aucun texte, aucun bouton. Le seul signe utile est déjà prévu par le contrat : le `Notify extreme` que A envoie à tous (`review_context.md`).
- Si B a déjà un HUD de marée extrême, il n'y a rien à ajouter. **C'est un bon signe : un secret bien conçu ne coûte rien en interface.**

## 6. Les 2 points que je ne tranche pas

| # | Question | Pourquoi c'est D |
|---|---|---|
| 1 | **La gravure est-elle trop explicite ?** J'ai écrit « une forme immense sous l'île ». Trop = on spoile le plot twist dans une capture YouTube. Pas assez = les joueurs ne la remarquent jamais. Le curseur est fin, c'est un arbitrage de D, pas une mesure. |
| 2 | **La semaine 2 tient-elle avec ce lot ?** Deep Dive + épave + variante Abyssal, c'est déjà beaucoup pour une équipe de 5 lettres. Si c'est trop, **je sacrifie l'épave en premier** : le Deep Dive est demandé par Moaad et l'épave est un bonus. Le Deep Dive n'a pas de remplaçant ; l'épave, si. |

---

*Proposition E, 10/10/2026. Cohérent avec `GDD.md` §6 bis et `GDD_REEF.md` §14 nº 2. Si un détail diverge de `Config.lua` ou du contrat v2.1, **le code gagne**.*
