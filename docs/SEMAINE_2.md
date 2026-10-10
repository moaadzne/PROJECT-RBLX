# Semaine 2 — première mise à jour (E, 10/10)

**Ce n'est pas une spec d'implémentation.** `GDD.md` §9 bis décrit déjà le Deep Dive en détail : ne pas le réécrire. Ce document tranche ce qui **manque encore** pour que A, B et C puissent commencer lundi, et dit ce qui sort et ce qui glisse.

> **État au 10/10.** Phase 1 = test fermé ~20-23/10, premier test public ~26/10, une mise à jour par semaine. La semaine 2 tombe donc **juste après le premier test public**. Tout ce qui est écrit ici doit pouvoir être construit pendant que les données de la semaine 1 arrivent. C'est la seule contrainte de planification qui compte.

## 1. Ce qui sort, et ce qui glisse

| Contenu prévu (`TABLEAU.md`) | Statut | Décision E |
|---|---|---|
| **Deep Dive** — `DiveService` + Pearls | ✅ **semaine 2** | C'est le moteur de collection rare demandé par Moaad. Ne glisse pas. |
| **Secret complet de l'épave** | ✅ **semaine 2** | Va de pair avec le Deep Dive : c'est ce qui rend le tirage « lecture d'une histoire » et pas « roulette ». Mais attention au coût (voir §2). |
| **Échanges entre joueurs** | ⏸️ **glisse** | C'est le seul gros morceau qui n'a **aucune** base technique : pas de marché, pas d'inventaire partagé, pas de validation anti-triche, et un vrai risque d'arnaque à l'argent réel. Ça fait une mise à jour à part, pas une troisième brique. |
| Créatures Légendaires dans la nature | ⏸️ **semaine 3** | Ordre de retour fixé dans `GDD_REEF.md` §14 nº 2. Ne pas les avancer : elles sont la promesse du Deep Dive, elles arrivent **avec** lui. |

## 2. Le vrai risque de la semaine 2 : ce qui peut l'arrêter

Ce n'est pas le code. C'est **la règle de Roblox**, et elle n'est pas de notre ressort.

- **Vérifier les règles de monétisation Roblox avant d'ouvrir la boutique.** Elles ont bougé pendant l'année. Un tirage payant avec Pearls + une variante « Mythic » exclusive peut être accepté ou non selon le texte en vigueur. **À faire lire par D et Moaad en semaine 1, pas en semaine 2** — au pire, on découvre le problème au moment de publier.
- **`ArePaidRandomItemsRestricted`** : dans les pays restreints, le Deep Dive **disparaît** et est remplacé par la Pearl Shop (achat direct, prix fixe). C'est déjà écrit dans `GDD.md` §9 bis et A a déjà le toggle pour la boutique (`Config.Shop` / `shop.randomAllowed`). **Il faut que ce remplacement soit implémenté le jour 1 du Deep Dive**, pas « plus tard » : un pays restreint sans repli voit un bouton mort.
- **Aucun faux badge payant.** Les récompenses du Deep Dive sont en jeu ou en Pearls gagnées en jouant. Jamais de badge en Robux, jamais.

## 3. Ce que chaque lettre doit savoir

**[A] — DiveService**
- Le Deep Dive **remplace le `Tide Egg`** en semaine 2 (`GDD.md` §9 bis, dernier point). `Pick a Creature` devient une ligne de la Pearl Shop. Ne garde pas les deux en vie : deux systèmes de tirage qui se marchent dessus, c'est le joueur qui ne sait pas lequel jouer.
- Les creatures tirées naissent **directement au stade `Adult`** pour les Legendary (Deep Dive fait gagner du temps, pas de l'espèce rare). C'est la règle qui justifie le prix face au gratuit.
- **Créatures liées** : ni volables ni échangeables. Vérifie que `StealService` et les protections du §4.7 les ignorent, sinon un joueur paie et se fait voler son Abyssal — c'est le bug qui fait fermer une boutique.
- Le **pity partagé** entre Shallow Dive et Deep Dive (50 %) est une obligation d'équité : c'est lui qui autorise psychologiquement le Tirage gratuit quotidien.

**[B] — écran Dive**
- **Probabilités sur l'écran principal, pas dans un menu caché.** C'est une obligation Roblox, pas un choix de design. Le ×10 doit montrer la grille qui se retourne ; le pity et le solde de Pearls sont visibles en permanence, pas seulement à l'achat.
- **Bouton `DIVE` dans le HUD**, jamais de pop-up automatique : une fenêtre qui s'ouvre toute seule pendant une vague est une fenêtre qui fait perdre la partie.
- Si le joueur est en **pays restreint**, le bouton affiche `Pearl Shop` et l'achat direct — jamais un tirage.

**[C] — FX et variante Abyssal**
- La **variante Abyssal** est un preset de mutation comme les autres, **pas un nouveau modèle** : peau noire, bioluminescence rouge. Elle se range à côté de `Assets.FX.Mutations`, pas dans `Assets.Creatures`. (Cohérent avec `GDD_REEF.md` §8 : une mutation ne demande jamais un modèle.)
- **Animation de plongée de 3 s**, passable après la première. Si on la rejoue à chaque fois, le joueur finit par l'écran noir de la semaine 2.
- **L'épave qui émerge** (secret de la semaine 2) doit être **repérable avant qu'elle émerge** : c'est la règle des secrets de `GDD.md` §6 bis — on voit le secret avant de le lire. Un signe visuel, aucun texte.

## 4. Les 3 décisions qui bloquent, et à qui elles revient

| # | Décision | Qui | Quand |
|---|---|---|---|
| 1 | **Règles de monétisation Roblox en vigueur** : le Deep Dive + la variante Abyssal passent-ils ? | D + Moaad | **semaine 1** — c'est le seul vrai risque de calendrier |
| 2 | **Codex : montrer les 7 espèces verrouillées en « ? », ou ne montrer que les 3 connues ?** | D | avant le test public ~26/10 (c'est du contenu d'écran, ça se voit sur les captures) |
| 3 | **Contenu exact du secret de l'épave** | E le propose, D tranche | avant que C ne modélise, donc semaine 2 |

Le point 3 est le seul que je peux préparer sans arbitrage. **Ce n'est pas fait ici** : la commande reçue était de trancher le §14 nº 2 et de préparer la semaine 2, pas d'écrire le contenu de l'épave. Je le fais à la demande, ou après le retour de D sur les points 1 et 2.

---

*Écrit par E le 2026-10-10. Ce qui diverge de `Config.lua` ou de `review/review_context.md` : **le code gagne**.*
