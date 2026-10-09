# GDD — Tide Rush : Steal & Ride (concept Reef Keepers) · v2

Auteur : E (concept & game design). v1 le 2026-10-09, **v2 le 2026-10-09** après la levée des règles halal par Moaad et la décision de D (vol, monture, Marée Royale, monétisation v2). Cohérent avec docs/AUDIT_TOP10.md §6.
Statut : v2 complète et perfectible. Les chiffres sont des **valeurs de départ** à régler par playtest, pas des mesures.

**Changements v2** : §0 (titre et miniatures), §2 (boucle avec vol), §4.6 Monture, §4.7 Vol, §4.8 Marée Royale, §7 Social, §8 (protection des nouveaux), §9 Monétisation v2, §11 Impact, §12 Phase 1 v2, §13 Config, §14. Les autres sections de la v1 restent valables.

---

## 0. Hook : titre et miniatures

### 3 titres (verbe + objet)
| Titre | Vérification (recherche web, 09/10) | Avis |
|---|---|---|
| **Ride the Tsunami** | Aucun jeu connu trouvé sous ce titre. Proches : « Escape The Tsunami », « Escape Tsunami For Brainrots ». | **Recommandé.** Unique, filmable, dit la promesse que les autres n'ont pas (surfer la vague). |
| Steal a Sea Creature | Pas de jeu trouvé, mais **« Steal a Fish »** existe déjà (vol + poissons) : trop proche, on serait vu comme un clone. | À éviter comme titre principal. |
| Catch, Steal & Ride | Rien trouvé. Plus long, moins clair en 5 s. | Bon sous-titre. |

**Recommandation** : nom affiché **« Ride the Tsunami 🌊 Steal & Ride »**. « Steal » reste dans le titre pour la recherche Roblox, mais la promesse forte est la monture sur la vague.
Limite : ma recherche web ne remplace pas la recherche Roblox. **Moaad doit taper les 3 titres dans la recherche Roblox avant de publier.**

### 3 miniatures à tester en A/B
1. **Surf** : un avatar debout sur une raie géante dorée qui glisse sur la crête d'une vague énorme, bouche ouverte de joie. Ciel orange. Texte « RIDE IT! ».
2. **Vol** : un avatar qui court avec une créature arc-en-ciel dans les bras, un autre joueur qui le poursuit, la vague juste derrière. Texte « STEAL IT! ».
3. **Rareté** : une tortue Giant arc-en-ciel au centre, brillante, entourée de petites créatures normales, un avatar choqué. Texte « RAINBOW GIANT? ».
Règles : 3 éléments maximum, lisible sur un téléphone, couleurs saturées, aucune personne réelle ni personnage existant.

## 1. Univers et histoire courte

**L'archipel de Maré.** Chaque minute, la Grande Marée se retire et laisse sur la plage des créatures marines perdues. Puis la vague revient et les reprend.
Tu es un **Reef Keeper**, un gardien de lagon. Ton travail : sauver le plus de créatures possible avant la vague, les élever dans ton lagon et reconstruire le récif.
La légende dit que lorsqu'un lagon est assez beau, le **Léviathan**, l'ancien gardien de la mer, remonte des profondeurs pour le saluer.

Ton : cozy, lumineux, aventure. Aucun méchant, aucune violence : la vague est un obstacle naturel, pas un ennemi.

## 1 bis. Les piliers du fun (ce qui décide de tout le reste)

Le dernier test a montré que « rien ne va ». Le GDD part donc du **ressenti**, et la réutilisation du code n'est qu'un bonus. Si une partie de l'ancien jeu ne sert pas ces piliers, on la jette.

1. **Attraper, c'est un plaisir physique.** Chaque prise a un son, un saut de la créature dans les bras, un petit ralenti de 0,15 s, un chiffre qui saute. On doit avoir envie d'en attraper une de plus sans même penser aux pièces.
2. **Ce que j'attrape est vivant et à moi.** Les créatures ont des yeux, nagent, réagissent quand on s'approche du bassin. Ce ne sont pas des objets posés sur des socles.
3. **La vague fait battre le cœur.** On entend la mer gronder, l'eau se retire, le ciel change. C'est une course, pas une punition : on frôle la vague, on ne meurt pas.
4. **Il y a toujours un « et si… » juste devant.** Une créature brillante un peu trop loin, une marée dorée annoncée, un bébé qui va grandir dans 40 s.

**Ce qu'on ne garde pas de l'ancien jeu, par principe :** les trésors inanimés, les socles nus, le spawn au hub loin de tout, le premier contact avec un HUD chargé, l'absence de son et de réaction.

## 1 ter. Les 30 premières secondes, image par image

Objectif : à 30 s, le joueur a **ri ou souri une fois**, a **une créature à lui qui nage**, et **comprend la vague sans avoir lu un mot de tutoriel**.

| Temps | Ce qu'il voit | Ce qu'il fait | Ce qu'il ressent |
|---|---|---|---|
| 0–2 s | Caméra qui descend du ciel sur **son** lagon turquoise, au bord de la plage. Son nom sur un panneau en bois. Lumière chaude de fin d'après-midi. Musique douce + vagues. | Rien, le jeu charge en douceur. | « C'est beau, c'est chez moi. » |
| 2–4 s | Son personnage apparaît au bord du lagon. Un bébé Pebble Crab est **coincé sur le sable** à 12 studs, il agite les pinces, une petite bulle « ! » au-dessus de lui. Aucun texte, aucun menu. | Il regarde. Le joystick mobile est le seul élément d'interface visible. | Curiosité : « il est mignon, il est coincé ». |
| 4–7 s | En approchant, le crabe saute de joie (petit bond + son « pip »). | Il marche vers lui. | Le jeu réagit à moi. |
| 7–8 s | **La prise** : le crabe saute dans ses bras, flash blanc doux, son « plop », micro-ralenti, « +1 » qui rebondit. Le crabe reste visible **sur sa tête/dans ses bras**. | Il le touche (ramassage automatique au contact). | Satisfaction immédiate, à refaire. |
| 8–12 s | La caméra révèle la plage : **4 autres créatures** brillent un peu plus loin (20–40 studs), dont une **Sand Star dorée** qui scintille encore plus loin. | Il court vers elles. | « Encore ! » et « celle-là brille, je la veux ». |
| 12–18 s | Il en attrape 2 ou 3 ; elles s'empilent sur sa tête de façon comique (tour de créatures qui oscille). | Il court, il ramasse. | Ça devient drôle. |
| 18–20 s | La musique s'arrête net. Un **grondement grave**. Au loin, la mer **se retire** et découvre le sable. Le ciel fonce légèrement. Une corne de brume. | Il se retourne. | Tension : « qu'est-ce qui arrive ? » |
| 20–22 s | Un **mur d'eau** se lève à l'horizon. Une seule icône apparaît au sol : une flèche lumineuse vers son lagon (pas de texte). | Il comprend tout seul : il faut rentrer. | Le cœur s'accélère. |
| 22–27 s | Course vers le lagon. La vague arrive derrière, on l'entend grossir. La Sand Star dorée, restée sur le sable, est **avalée** par la vague. | Il court. | Adrénaline, petit regret pour la dorée. |
| 27–28 s | Il saute dans son lagon : **splash**. Les créatures plongent de sa tête dans les bassins, chacune avec un son différent. | Rien, c'est automatique. | Soulagement et fierté. |
| 28–30 s | La vague s'écrase **juste derrière la limite du lagon** et l'éclabousse sans le toucher. Les créatures nagent, des pièces commencent à sortir en bulles (+1, +2). Premier texte du jeu, une seule ligne : « Elles grandissent. La prochaine marée sera **dorée**. » | Il regarde ses créatures. | « J'y retourne, je veux la dorée. » |

**Règles de cette séquence (non négociables pour B et C) :**
- Aucun texte avant 28 s, aucune fenêtre, aucun HUD sauf le joystick. Les pièces et le reste du HUD apparaissent **après** la première vague.
- La première vague est **scénarisée** : déclenchée 18 s après le spawn (pas le cycle global), et elle ne peut pas attraper le joueur (on garde son sac quoi qu'il arrive). Les vagues suivantes suivent le cycle normal.
- La deuxième marée du joueur est **forcément Golden** (pour lui), pour tenir la promesse de la dernière ligne.
- Son à chaque action. Sans le son, cette séquence ne marche pas : c'est une priorité Phase 1, pas un bonus.
- Temps de chargement masqué par la descente de caméra. Si le chargement dépasse 2 s, la caméra attend en vue large du lagon, pas sur un écran noir.

## 2. Boucle principale

**Boucle de 60 s (un cycle de vague)** : chaque phase a un rôle.
1. **Calme (35 s) : attraper.** La plage se couvre de créatures. Tu cours (ou tu montes ta créature), tu les attrapes et tu rentres les déposer. Les lagons sont **fermés** par une barrière de corail.
2. **Alerte (7 s) : choisir.** Les barrières de tous les lagons **tombent**. Tu choisis : défendre chez toi, aller voler chez un voisin, ou surfer la vague si tu as une Giant.
3. **Vague (~17 s) : la fenêtre de vol.** Les voleurs foncent, les propriétaires défendent, les surfeurs glissent sur la crête. Sur la plage, la vague emporte ce que tu portes.
4. **Reflux (2,5 s) : le verdict.** Les barrières remontent. Un voleur qui n'est pas rentré chez lui perd la créature volée, qui retourne chez son propriétaire.

**Décisions à chaque cycle** : aller loin ou rester prudent ; voler ou défendre ; garder une créature pour la monter ou pour son revenu ; verrouiller son lagon maintenant ou garder le verrou pour plus tard.

## 3. Couches de progression

| Horizon | But | Système |
|---|---|---|
| 1 min | Attraper sa première créature, la voir nager | Boucle |
| 10 min | Remplir 5 bassins, acheter Speed/Bag, voir un Juvenile, débloquer Coral Coast | Améliorations, croissance |
| 1 h | Première mutation (Golden Tide), premier œuf de compagnon | Marées, compagnons |
| Plusieurs jours | Codex à 50 %, une Légendaire en Giant | Codex, croissance longue |
| Plusieurs semaines | Attirer le Léviathan, Tide Rank 3+ | Léviathan, rebirth |

## 4. Contenu

### 4.1 Zones (reprend Config.Zones, mêmes limites Z)
| # | Zone | Rareté | Créatures |
|---|---|---|---|
| 1 | Shallows | Common | Pebble Crab, Sand Star |
| 2 | Coral Coast | Uncommon | Bubble Puffer, Reef Hatchling (bébé tortue) |
| 3 | Sunken Reef | Rare | Lantern Seahorse, Coral Ray |
| 4 | Pirate Cove → **Wreck Cove** | Epic | Ink Octopus, Moon Jelly |
| 5 | Abyss Shore | Legendary | Star Whale Calf, Abyss Serpent |

Renommer Pirate Cove en Wreck Cove est optionnel (plus cohérent, mais simple texte).

### 4.2 Créatures : **10 espèces, 10 modèles**
Une espèce = **un seul modèle 3D**. Les stades et les mutations sont faits sur ce même modèle (échelle, couleur, matériau, particules). C'est la clé pour tenir la charge de C.
Les remplaçants directs des 10 trésors actuels (même rareté, même revenu de base) :

| Id (Config) | Nom | Rareté | Revenu bébé /s | Remplace |
|---|---|---|---|---|
| PebbleCrab | Pebble Crab | Common | 1 | Shell |
| SandStar | Sand Star | Common | 2 | Starfish |
| BubblePuffer | Bubble Puffer | Uncommon | 6 | Pearl |
| ReefHatchling | Reef Hatchling | Uncommon | 10 | BlueCrab |
| LanternSeahorse | Lantern Seahorse | Rare | 30 | CoralCrown |
| CoralRay | Coral Ray | Rare | 50 | GoldenCrab |
| InkOctopus | Ink Octopus | Epic | 150 | TreasureChest |
| MoonJelly | Moon Jelly | Epic | 250 | AbyssCrystal |
| StarWhaleCalf | Star Whale Calf | Legendary | 800 | MoonPearl |
| AbyssSerpent | Abyss Serpent | Legendary | 1500 | TideHeart |

Animation minimum : idle « nage » par tween (bob + rotation lente, déjà fait côté client avec TR_Spin/Bob). Pas d'animation squelettique obligatoire.

### 4.3 Croissance (même hors ligne)
4 stades. Le stade se calcule à partir de l'heure de naissance (`born`, os.time serveur) : **aucun timer qui tourne**, donc la croissance hors ligne est automatique.

| Stade | Échelle visuelle | Multiplicateur de revenu |
|---|---|---|
| Baby | 0,6 | ×1 |
| Juvenile | 0,8 | ×2 |
| Adult | 1,0 | ×4 |
| Giant | 1,5 | ×8 |

Durée **cumulée** pour atteindre chaque stade (minutes) :

| Rareté | Juvenile | Adult | Giant |
|---|---|---|---|
| Common | 3 | 15 | 60 |
| Uncommon | 5 | 30 | 120 |
| Rare | 10 | 60 | 240 |
| Epic | 20 | 120 | 480 |
| Legendary | 30 | 240 | 1 200 (20 h) |

Une Légendaire atteint Giant en environ un jour : c'est le « reviens demain » naturel, sans pression.

### 4.4 Types de marée et mutations
Chaque cycle a un type de marée, **annoncé à l'avance** dans le HUD (« Prochaine marée spéciale : Night Tide dans 6 vagues »). Le calendrier est fixe et identique pour tout le serveur.

- Cycles normaux : marée **Normal**.
- Tous les **8 cycles** (≈ 8 min), une marée spéciale, en rotation : Golden → Night → Storm → Golden…
- Toutes les **heures pile** (heure serveur) : une **Rainbow Tide** de 1 cycle, à la place de la marée prévue.

Chance de mutation **par créature apparue** (probabilités affichées dans le Codex et le HUD) :

| Mutation | Effet visuel (même modèle) | Mult. revenu | Normal | Golden Tide | Night Tide | Storm Tide | Rainbow Tide |
|---|---|---|---|---|---|---|---|
| Golden | Matériau Foil doré + étincelles | ×3 | 0,5 % | 30 % | — | — | — |
| Glow | Neon bleu-vert, lumière ponctuelle | ×2 | — | — | 35 % | — | — |
| Storm | Teinte violette + particules éclair | ×5 | — | — | — | 15 % | — |
| Rainbow | Couleur animée arc-en-ciel | ×10 | 0,05 % | 2 % | 2 % | 2 % | 25 % |

Une seule mutation par créature. Le tirage se fait côté serveur à l'apparition, sur ce qu'on obtient **gratuitement en jouant** : ce n'est jamais un tirage payé.

### 4.5 Compagnons (système existant, rhabillé)
On garde Config.Pets et Config.Eggs **tels quels** (œufs en pièces uniquement, probabilités affichées, 3 équipés, 40 en inventaire). Ce sont des « esprits du récif » qui suivent le joueur et boostent le revenu. Seul le texte change. Pas de nouveau modèle exigé en Phase 1 (sphères colorées acceptables).

### 4.6 Monture
- Espèces montables (grandes formes) : **Reef Hatchling** (tortue), **Coral Ray**, **Star Whale Calf**, **Abyss Serpent**.
- Montables à partir du stade **Adult**. Bouton « Monter » sur le billboard du bassin ou dans l'inventaire. Une seule monture active.
- Vitesse : Adult **×1,3**, Giant **×1,6**, multipliée par l'amélioration Speed.
- **Les Giant surfent la vague** : un joueur sur une Giant n'est jamais pris. Quand la vague l'atteint, il glisse sur la crête (animation de surf) jusqu'à la limite des lagons, et **garde son sac**. C'est le moment vidéo du jeu.
- Une créature montée continue de rapporter son revenu (pas de punition), ne peut pas être volée, et **ne peut pas porter une créature volée** : pour voler, il faut descendre. Ça garde le vol lisible et la poursuite possible.

### 4.7 Vol entre lagons (version complète)
**Fenêtre** : de l'alerte à la fin de la vague (≈ 24 s). En dehors, les barrières sont fermées et le vol est impossible.

**Voler**
- Entrer dans un lagon ouvert, toucher une créature dans un bassin (maintien de 1,0 s, interrompu si on bouge) : elle saute dans tes bras.
- **1 créature volée à la fois.** Un voleur porteur va **×0,8** moins vite et ne peut pas monter.
- **Rentrer chez soi avant la fin du reflux** : la créature est à toi, avec son stade et sa mutation. Sinon, elle retourne chez son propriétaire.
- Pris par la vague sur la plage (s'il fait un détour) : la créature retourne chez son propriétaire.

**Défendre**
- **Le propriétaire touche le voleur** avant qu'il rentre : la créature revient dans son bassin et le voleur est repoussé (petit recul, pas de dégâts).
- Alerte immédiate du propriétaire : son, flèche vers le voleur et la créature qui brille au-dessus de lui.
- **Verrou gratuit** : bouton « Fermer le lagon ». Il garde la barrière levée pendant **1 vague complète**, puis recharge pendant **4 cycles** (≈ 4 min).
- **Hors ligne** : un joueur absent n'a pas de lagon sur le serveur, il ne peut donc pas être volé. On ne perd jamais rien en dormant.
- **Après un vol réussi chez toi** : ton lagon est **protégé pendant les 2 vagues suivantes** (anti-acharnement), et tu reçois un marqueur **« Revanche »** : la barrière du voleur s'ouvre pour toi dès le début de l'alerte suivante.

**Ce qu'on ne peut pas voler**
- La **dernière** créature d'un lagon (on garde toujours au moins 1 créature).
- Une créature **montée**.
- Les créatures d'un joueur en **protection débutant** : ses **15 premières minutes de jeu cumulé**, ou tant qu'il a moins de 4 créatures. Pendant ce temps, il ne peut pas voler non plus.
- Max **3 vols subis par joueur et par 10 minutes** ; au-delà, le lagon est verrouillé automatiquement.

**Pourquoi c'est équilibré** : un nouveau ne perd jamais rien pendant qu'il apprend. Un petit garde toujours sa dernière créature, sa monture et un verrou gratuit. Le gros joueur, qui a beaucoup à perdre, a aussi le plus de raisons de défendre. La vague donne une fenêtre courte, donc chacun joue « 24 s de tension, 35 s de calme ».

**Pas de protection payante au lancement** (décision de D). À réévaluer selon les données, jamais sous forme d'immunité totale.

### 4.8 Marée Royale (compétition sans vol)
- À chaque **marée spéciale** (toutes les 8 vagues, §4.4), une manche Marée Royale démarre pour tout le serveur pendant ce cycle.
- Score = valeur (revenu/s) des créatures attrapées **et** volées pendant ce cycle. Classement en direct en haut de l'écran.
- **Top 3** : couronne d'or, d'argent ou de bronze au-dessus de la tête jusqu'à la marée spéciale suivante, et pièces = 5 / 3 / 2 min de leur revenu.
- **Créature royale** : une créature **unique par serveur** apparaît au bout de la zone pendant la manche, toujours mutée (Golden en Phase 1). Le premier qui la ramène chez lui la garde. Elle se vole comme les autres ensuite : c'est la cible de tout le serveur.

## 5. Économie (prête pour Config)

### 5.1 Revenu
```
revenu/s d'une créature = base × stageMult × mutationMult
revenu total/s = Σ créatures × (1 + petBoost + codexBonus + rankBonus) × boostX2 (si actif)
```
- Hors ligne : la croissance continue à 100 %. Les pièces gagnées hors ligne = **50 % du revenu, plafonné à 8 h**, versées à la connexion avec un écran « Pendant ton absence… ». (Ce n'est pas une punition : c'est un cadeau de retour.)
- Lagon plein : la créature attrapée remplace la plus faible si elle vaut plus (logique actuelle). Sinon, elle est **relâchée** contre `revenu bébé × SellMultiplier (20)` pièces (logique « sold » actuelle).
- Remplacement : la valeur comparée = revenu/s courant (stade et mutation inclus). Un Giant commun n'est donc pas écrasé par un bébé rare de valeur inférieure.

### 5.2 Améliorations : inchangées (Speed, Bag, Slots dans Config.Upgrades)
Contrôle rapide : 5 Pebble Crab/Sand Star bébés ≈ 7 pièces/s ; à Adult ≈ 30 /s. Speed niveau 1 (50) en 10 s, Slots niveau 1 (200) en < 1 min : le rythme des 10 premières minutes est bon.

### 5.3 Œufs de compagnons : inchangés (2 500 / 60 000 / 1 500 000)
Shell Egg atteignable vers 5–8 min, Coral Egg vers 45–60 min, Abyss Egg en jours. À valider en playtest.

### 5.4 Reef Codex : 10 espèces × 5 variantes (Normal, Golden, Glow, Storm, Rainbow) = **50 cases**
| Événement | Récompense |
|---|---|
| Nouvelle case | `revenu bébé × 50` pièces |
| Ligne d'une espèce complète (5 variantes) | +5 % de revenu permanent (codexBonus) |
| 10 / 25 / 40 / 50 cases | décor de lagon exclusif (non achetable) : Coquillage géant, Arche de corail, Fontaine de perles, Statue du Léviathan |
Le Codex **n'est jamais réinitialisé** (ni par le rebirth).

### 5.5 Le Léviathan (but des semaines)
Condition : **Codex ≥ 30 cases** ET **tous les bassins occupés par des créatures Adult ou Giant**.
Le joueur active un « Chant du récif » dans son lagon : au cycle suivant, **Leviathan Tide** pour tout le serveur. Le Léviathan passe au large (grand modèle, unique, non jouable), mutation Rainbow à 25 % pour **tous** les joueurs du serveur pendant ce cycle. L'invocateur reçoit une **Écaille du Léviathan** (requise pour les Tide Rank 5+) et un titre.
Cooldown : 1 invocation par joueur toutes les 24 h. C'est l'événement social par excellence : un joueur avancé fait un cadeau à tout le serveur.

### 5.6 Tide Rank (rebirth)
| Rank | Coût (pièces, cumul de la session courante) | Bonus permanent |
|---|---|---|
| 1 | 1 000 000 | +25 % revenu |
| 2 | 5 000 000 | +50 %, +1 au sac |
| 3 | 25 000 000 | +75 % |
| 4 | 125 000 000 | +100 %, +1 au sac |
| 5 | 625 000 000 + 1 Écaille | +150 %, aura de rang |
| n > 5 | 625 M × 5^(n−5) + 1 Écaille | +50 % par rang |
Formule : `cost(n) = 1e6 × 5^(n−1)`. **Remis à zéro** : pièces, améliorations, créatures du lagon. **Gardé** : Codex, compagnons, décors, gamepasses, rang.

## 6. Méta

- **Codex** (§5.4) : écran collection, cases grises avec silhouette et probabilité affichée.
- **Quêtes quotidiennes** : 3 par jour, simples, choisies parmi une liste (attraper 20 créatures, survivre à 5 vagues, faire grandir 1 Adult, visiter 2 lagons). Récompense : pièces = 10 min de revenu courant, plus 1 jeton de décor. Elles **ne disparaissent pas** si on ne se connecte pas : on garde celles du jour en cours, sans compteur alarmant.
- **Cadeau quotidien** : on compte les **jours joués au total** (paliers à 3, 7, 14, 30 jours → décors). Il n'y a **pas de série qui se casse**.
- **Événements** (Phase 3) : une marée thématique par mois (ex. « Marée des lanternes ») avec 1 espèce saisonnière qui **revient chaque année** et des décors gagnables en jouant. Pas de récompense vendue « dernière chance ».

## 7. Social

- **Vol et revanche** (§4.7) : le cœur social. Chaque vol crée une histoire entre deux joueurs.
- **Marée Royale** (§4.8) : compétition visible, couronnes.
- **Monture** visible par tous (§4.6) : on montre sa Giant arc-en-ciel.
- **Visite de lagon** et « J'aime » : gardés (Phase 2).
- **Pêche à plusieurs** : +10 % de chance de mutation par ami Roblox dans la même zone, plafonné à +30 % (Phase 2).
- **Échanges** : **mise à jour de la semaine 2**, pas au lancement. Raison : il faut une interface anti-arnaque solide (double confirmation, aperçu des valeurs), et au lancement le vol couvre déjà le besoin de « prendre la créature des autres ». Règles : entre joueurs du même serveur, après 30 min de jeu cumulé, jamais contre des Robux.
- Léviathan (§5.5) : reporté en mise à jour.

## 8. Onboarding

### 60 premières secondes
- 0–30 s : voir §1 ter (séquence scénarisée, sans texte).
- 30–45 s : le HUD apparaît en fondu (pièces, revenu). Une flèche au sol montre les tours : « Les tours te protègent aussi. »
- 45–60 s : retour sur la plage, nouvelles créatures. Le joueur joue seul, sans guide.

### 10 premières minutes
- Min 1–2 : achat guidé de Speed niv. 1 (bouton qui pulse doucement, une fois).
- Min 2–4 : 5 bassins pleins, premier Juvenile (3 min) avec animation de croissance et « ×2 revenu ! ».
- Min 1–3 : deuxième marée **forcée Golden** pour ce joueur (promesse du §1 ter), pour qu'il voie une mutation tôt. Ensuite le calendrier normal reprend.
- Min 6–8 : ouverture du Codex (« 3/50 »), première récompense de case.
- Min 8–15 : protection débutant active (bouclier visible). Vers 12 min, un message unique : « Dans 3 min, ton lagon pourra être visité par des voleurs pendant la vague… et toi aussi tu pourras voler ! » avec le bouton Verrou mis en avant.
- Min 8–10 : Coral Coast mis en avant (« créatures Uncommon, ×5 revenu »), premier Shell Egg proposé si les pièces suffisent.

## 9. Monétisation v2

Règles halal levées par Moaad (09/10). Restent obligatoires : **probabilités affichées avant tout achat aléatoire**, `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted` → l'achat aléatoire est **caché** et remplacé par un achat direct, `ProcessReceipt` idempotent, règles de monétisation Roblox.
Garde-fous gardés pour éviter une sanction et des plaintes de parents : pas de faux compte à rebours, pas d'achat aléatoire présenté comme gratuit, aucune immunité au vol vendue.

### Boutique de lancement (minimale, pour mesurer la conversion)
| Produit | Type | Prix (R$) | Effet |
|---|---|---|---|
| Fast Growth | Gamepass | 299 | Croissance ×2 |
| Big Net | Gamepass | 149 | Rayon de ramassage ×1,5 |
| VIP Rider | Gamepass | 399 | Titre, traînée de monture, +10 % pièces, +10 % vitesse de monture |
| **Tide Egg** | Produit développeur (aléatoire, probas affichées) | 79 | Une créature de la zone, avec 10 % de chance de Golden |
| **Pick a Creature** (alternative sans tirage, montrée **à la place** du Tide Egg si `ArePaidRandomItemsRestricted`) | Produit développeur | 149 | Le joueur choisit l'espèce, en Baby normal |

Probabilités du Tide Egg en Phase 1 (affichées sur le bouton) : Pebble Crab 50 %, Sand Star 35 %, Reef Hatchling 15 % ; puis Golden 10 % sur le résultat.

### Plus tard (selon les données)
Œufs Robux par zone (49 / 149 / 399), Extra Pool (249), Deep Pockets (199), boosts de 15 min (39), packs de pièces (montants qui valent des heures de jeu, pas des semaines), cosmétiques de lagon et de monture, serveur privé.

Repère réaliste : sur 299 R$, le jeu touche 70 % = 209 R$ ≈ **0,79 $** via DevEx. Aucun revenu promis.

## 10. Rétention et KPI

### Calendrier
| Moment | Raison de revenir (positive) |
|---|---|
| Chaque minute | La vague, une nouvelle plage |
| Toutes les 8 min | Marée spéciale annoncée |
| Chaque heure | Rainbow Tide |
| Chaque jour | Légendaire qui devient Giant, 3 quêtes, revenu hors ligne, Léviathan disponible |
| Chaque semaine | Mise à jour : 1 décor ou 1 quête nouvelle (Phase 3) |
| Chaque mois | Marée événement + espèce saisonnière (récurrente) |

### KPI (objectifs internes, à mesurer avec AnalyticsService ; ce ne sont pas des références d'autres jeux)
- Funnel onboarding : % qui déposent 1 créature (< 60 s), 5 créatures, voient une mutation, achètent 1 amélioration.
- D1, D7, D30 et durée moyenne de session.
- Mutations vues par session, cases de Codex par jour, invocations du Léviathan par serveur.
- Visites de lagon par session (santé du social).
- Taux de payeurs et revenu par joueur (suivi, pas d'objectif poussé dans le design).
- Ticket « je suis bloqué » : nombre de joueurs qui stagnent > 20 min sans nouvelle créature (alerte d'équilibrage).

## 11. Impact pour l'équipe (v2)

### A — Serveur
- Config : Creatures, Stages, Mutations, Tides, **Mount, Steal, Royal, Shop** (§13).
- Schéma de données v2 + migration v1 (display → `{id, mut, born}`), plus `playTime`, `lockReadyAt`, `protectedUntil`.
- WaveService : type de marée par cycle ; **phases qui pilotent l'ouverture des lagons** (attribut `Open` par plot).
- **StealService** : prise (maintien 1 s), portage (1 max, vitesse ×0,8), retour à la fin du reflux, contact propriétaire → retour, protections (débutant, dernière créature, montée, 2 vagues après un vol, 3 vols / 10 min), verrou + recharge, revanche. Tout est validé côté serveur.
- **MountService** : monter/descendre, vitesse, Giant = jamais pris par la vague + surf.
- **RoyalService** : score par cycle spécial, top 3, couronnes, créature royale unique.
- Revenu stade × mutation, hors ligne.
- Remotes (v2, additif) : RF `Mount(uid|nil)`, `LockLagoon()`, `StartSteal(plot, slot)` ; Notify `stealStart`, `stolen`, `stealFail`, `recovered`, `royal`, `grow`, `mutation` ; `wave.tide`, `wave.royal`.
- Marketplace : 3 gamepasses, Tide Egg + Pick a Creature selon PolicyService.

### B — Interface
- Intro de 30 s (§1 ter) sans HUD, puis fondu.
- **HUD de vol** : alerte « Ton lagon est ouvert ! », flèche vers le voleur, barre de maintien, bouton Verrou avec recharge, marqueur Revanche, bouclier débutant visible.
- **HUD Marée Royale** : classement top 3 en direct, couronnes.
- Bouton Monter/Descendre, bandeau de marée, billboard de bassin (stade, mutation, barre).
- Boutique minimale avec probabilités visibles et bascule PolicyService.
- Mobile d'abord : tout à un doigt.

### C — Monde
- **3 modèles** pour la Phase 1 : Pebble Crab, Sand Star, Reef Hatchling (**montable** : siège, posture du joueur, animation de surf).
- Barrière de corail par lagon (visuel ouvert / fermé, son), portes qui ne gênent pas la poursuite.
- Preset FX Golden, presets d'ambiance Golden Tide.
- Couronnes (3 accessoires), effet « créature royale » (lumière + faisceau).
- Sons : prise, vol, alerte, barrière, surf.

## 12. Prototype Phase 1 v2 (qualité finale, petit périmètre)

**Dedans :**
- Les 30 premières secondes du §1 ter, **son compris** : c'est le premier livrable jugé.
- 1 zone : Shallows (les autres zones fermées par une barrière de récif « bientôt »).
- **3 espèces** : Pebble Crab, Sand Star, **Reef Hatchling** (montable, apparaît dans Shallows à 10 % pendant cette phase).
- Croissance 4 stades, hors ligne inclus. Pour tester la monture vite, durées Common/Uncommon du §4.3.
- **Monture** (Adult ×1,3, Giant ×1,6 + surf).
- **Vol complet** (§4.7) avec toutes les protections.
- Marées : Normal + **Golden Tide** ; **Marée Royale** à chaque Golden Tide.
- Améliorations Speed/Bag/Slots, sauvegarde v2 avec migration.
- Boutique minimale (§9) avec bascule PolicyService.

**Dehors** : zones 2–5, autres mutations, Codex complet, Léviathan, Tide Rank, échanges (semaine 2), visites, quêtes, compagnons.

**Critère de sortie** : sur un téléphone moyen à 60 FPS, un nouveau joueur dépose sa première créature en < 60 s, monte une créature en < 15 min, vit un vol (subi ou réussi) dans sa première session après la protection, et revient le lendemain.

## 13. Bloc Config proposé (pour A)

```lua
Config.Creatures = {
	PebbleCrab = { name = "Pebble Crab", rarity = "Common", income = 1 },
	SandStar = { name = "Sand Star", rarity = "Common", income = 2 },
	BubblePuffer = { name = "Bubble Puffer", rarity = "Uncommon", income = 6 },
	ReefHatchling = { name = "Reef Hatchling", rarity = "Uncommon", income = 10 },
	LanternSeahorse = { name = "Lantern Seahorse", rarity = "Rare", income = 30 },
	CoralRay = { name = "Coral Ray", rarity = "Rare", income = 50 },
	InkOctopus = { name = "Ink Octopus", rarity = "Epic", income = 150 },
	MoonJelly = { name = "Moon Jelly", rarity = "Epic", income = 250 },
	StarWhaleCalf = { name = "Star Whale Calf", rarity = "Legendary", income = 800 },
	AbyssSerpent = { name = "Abyss Serpent", rarity = "Legendary", income = 1500 },
}
-- migration v1 -> v2
Config.LegacyItemToCreature = {
	Shell = "PebbleCrab", Starfish = "SandStar", Pearl = "BubblePuffer", BlueCrab = "ReefHatchling",
	CoralCrown = "LanternSeahorse", GoldenCrab = "CoralRay", TreasureChest = "InkOctopus",
	AbyssCrystal = "MoonJelly", MoonPearl = "StarWhaleCalf", TideHeart = "AbyssSerpent",
}

Config.Stages = {
	{ id = "Baby", scale = 0.6, mult = 1 },
	{ id = "Juvenile", scale = 0.8, mult = 2 },
	{ id = "Adult", scale = 1.0, mult = 4 },
	{ id = "Giant", scale = 1.5, mult = 8 },
}
-- minutes cumulees pour atteindre Juvenile, Adult, Giant
Config.GrowthMinutes = {
	Common = { 3, 15, 60 },
	Uncommon = { 5, 30, 120 },
	Rare = { 10, 60, 240 },
	Epic = { 20, 120, 480 },
	Legendary = { 30, 240, 1200 },
}

Config.Mutations = {
	Golden = { mult = 3, label = "Golden" },
	Glow = { mult = 2, label = "Glow" },
	Storm = { mult = 5, label = "Storm" },
	Rainbow = { mult = 10, label = "Rainbow" },
}
-- chances en % par creature apparue, affichees au joueur
Config.Tides = {
	Normal = { odds = { Golden = 0.5, Rainbow = 0.05 } },
	Golden = { odds = { Golden = 30, Rainbow = 2 } },
	Night = { odds = { Glow = 35, Rainbow = 2 } },
	Storm = { odds = { Storm = 15, Rainbow = 2 } },
	Rainbow = { odds = { Rainbow = 25 } },
}
Config.TideSchedule = { every = 8, rotation = { "Golden", "Night", "Storm" }, rainbowOnHour = true }
Config.FriendMutationBonus = { perFriend = 0.10, max = 0.30 } -- multiplicatif sur la chance

Config.Offline = { incomeRate = 0.5, maxHours = 8 }
Config.Codex = { newEntryIncomeMult = 50, speciesBonus = 0.05 }
Config.Leviathan = { minCodex = 30, minStage = "Adult", cooldownHours = 24, rainbowOdds = 25 }
Config.Rank = { baseCost = 1e6, costMult = 5, incomeBonus = { 0.25, 0.50, 0.75, 1.00, 1.50 }, bonusAfter = 0.50, scaleFromRank = 5 }

function Config.GetRankCost(rank: number): number
	return Config.Rank.baseCost * Config.Rank.costMult ^ (rank - 1)
end

-- v2 : monture, vol, Maree Royale, boutique
Config.Mount = { species = { ReefHatchling = true, CoralRay = true, StarWhaleCalf = true, AbyssSerpent = true }, minStage = "Adult", speedMult = { Adult = 1.3, Giant = 1.6 }, giantSurfs = true }
Config.Steal = {
	grabHold = 1.0, carrySpeedMult = 0.8, maxCarry = 1,
	lockDurationWaves = 1, lockCooldownCycles = 4,
	protectAfterStolenWaves = 2, maxStolenPer10Min = 3,
	newbieMinutes = 15, newbieMinCreatures = 4,
}
Config.Royal = { onSpecialTides = true, rewardMinutes = { 5, 3, 2 }, uniquePerServer = 1, royalMutation = "Golden" }
Config.Shop = {
	Passes = { FastGrowth = 299, BigNet = 149, VIPRider = 399 }, -- ids Roblox a remplir
	TideEgg = { price = 79, odds = { { "PebbleCrab", 50 }, { "SandStar", 35 }, { "ReefHatchling", 15 } }, goldenChance = 10 },
	PickCreature = { price = 149 }, -- remplace TideEgg si ArePaidRandomItemsRestricted
}
```

## 14. Questions ouvertes pour Moaad
1. Titre : **« Ride the Tsunami »** (recommandé) ? À vérifier dans la recherche Roblox avant de publier.
2. Prix de la boutique de lancement : valeurs de départ, à ajuster après 1 semaine de données.
