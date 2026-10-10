
## 2026-10-10 16:45
FAIT     : Revu l'existant contre `DECISIONS_MARCHE.md` et `BRIEF_NOUVEAUX_AGENTS.md`. GDD_REEF figé inchangé. Plan de reprise : (1) Codex semaine 1 → 3 visibles + 4 "? ? ? ?" silhouettes floues + rareté colorée, barre "X/10 découvertes" ; (2) Gravure épave → texte exact "Quand la mer recule, l'ancien roi revient. La marée extrême révèle ce qu'elle a prise." + empreinte lumineuse pulsante ; (3) Monétisation Config.Shop alignée sur prix finaux (VIP 79, Speed 149, Bag 99, StarterPack 249, TideEgg 199, PickCreature 399, RewardedAd 1/jour) ; (4) Police RobotoCondensed + IconResolver Font Awesome partout, zéro emoji.
VÉRIFIÉ  : GDD_REEF déjà cohérent sur : 30s intro, roster 10, 5 marées, 5 zones/tiers, bassins/réserve/Codex/mutations Phase 2. Écart mineur : GDD dit 5 paliers Codex, marché dit 4 mystère (donc 7 au total week 1) — aligné sur le marché. Rien testé en jeu.
BESOIN   : **[D]** validation plan — agents G à N arrivent, je ne touche pas à leurs zones. Mon seul livrable restant : ce plan + mise à jour GDD_REEF §14 (Codex 7 slots week 1, gravure exacte, Config.Shop prix). Attends ton feu vert pour pousser.

## 2026-10-10 16:15
FAIT     : `PREMIERE_HEURE.md` écrit, GDD figé non retouché. L'écart signalé (âge = capture vs dépôt) est le seul point où le GDD et le code divergent sur la première heure — j'ai écrit le code.
VÉRIFIÉ  : aucune Phase 2, aucun nom de service. Rien testé en jeu.
BESOIN   : **[D]** trancher l'écart si tu veux redonner son sens au « risque du sac » (une ligne côté serveur).

## 2026-10-10 15:38
FAIT     : **`docs/PREMIERE_HEURE.md`** — la première heure en français simple, minute par minute, sans Phase 2 et sans nom de service. GDD non retouché. `SEMAINE_2.md` et `SECRET_EPAVE.md` restent écrits mais **sont garés** : rien ne s'ouvre avant que la Phase 1 soit jouable.
VÉRIFIÉ  : chaque affirmation recalée sur le code avant d'écrire (35 s de calme / 7 s d'alerte, sac de 2, 5 bassins, 1/2/10 pièces par seconde, vieux à 15 min pour un commun et 30 pour une tortue, torches au palier 30/s, marée dorée toutes les 8 min, Couronne royale à chaque marée spéciale, récif 25 s). Rien testé en jeu.
BESOIN   : **[D] un écart à trancher** — le GDD figé dit que l'âge d'une créature compte **dès la capture**, mais `CreatureService.lua:278-283` crée la créature au **dépôt**. Le code et le contrat v2.1 disent dépôt ; c'est le GDD qui dit capture. Conséquence réelle : **le temps passé à courir avec l'animal dans le sac ne compte pas** — le sac n'est pas un risque, c'est juste une limite de place. J'ai écrit le document sur le dépôt (le code). Si tu veux l'inverse, c'est une ligne à changer et ça redonne son sens à « le risque du sac ».

## 2026-10-10 15:04
FAIT     : **`SEMAINE_2.md` réécrit pour Moaad** — semaine par semaine, ce que le joueur voit et ce qui change dans son expérience. Plus aucun nom de service, plus aucun tableau technique. Le détail équipe est resté dans `SECRET_EPAVE.md`.
VÉRIFIÉ  : les faits n'ont pas bougé au passage — plongée qui remplace la boutique, gratuit quotidien, probabilités affichées, garantie anti-malchance, ce qui est acheté ne peut être volé, épave pendant la marée horaire avec raie + poulpe, gravure sans récompense, échanges repoussés. Rien testé en jeu.
BESOIN   : **[D]** rien de neuf — tes 2 questions sont déjà portées à Moaad. Le doc est prêt à lui être montré tel quel ; dis-moi s'il veut la coupe finale (quatre parties : lancement / semaine 2 / direction semaine 3 / questions ouvertes).

## 2026-10-10 14:31
FAIT     : **`docs/SECRET_EPAVE.md`** — la semaine 2 est maintenant entièrement spécifiée côté concept : Deep Dive sort, échanges glissent (§2), épave écrite (§3). Plus aucun livrable E en attente.
VÉRIFIÉ  : l'épave ne coûte **rien à B** (aucun popup, aucun texte) et **2 lignes à A** (`Config.ExtremeTide.creatures`) ; tout le travail de modélisation est pour C, qui dessine déjà le repère en Phase 1. Rien testé en jeu.
BESOIN   : **[D] 3 arbitrages, le dernier est nouveau** — (1) règles de monétisation Roblox, semaine 1 ; (2) Codex semaine 1 : 7 espèces en « ? » ou 3 connues ; (3) `SECRET_EPAVE.md` §6 : **la gravure est-elle trop explicite ?** C'est le curseur fin du plot twist, je ne peux pas le mesurer. D tranche aussi : si la semaine 2 déborde, **l'épave part en premier**, le Deep Dive n'a pas de remplaçant.
