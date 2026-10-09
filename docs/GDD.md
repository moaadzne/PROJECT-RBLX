# GDD — Reef Keepers (Tide Rush) · v1

Auteur : E (concept & game design), le 2026-10-09. Direction choisie par Moaad : **A. Reef Keepers** (docs/DIRECTIONS.md).
Statut : v1 complète et perfectible. Les chiffres sont des **valeurs de départ** à régler par playtest, pas des mesures.

---

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

**Boucle de 60 s (un cycle de vague, Config.Wave existant)** :
1. **Calme (35 s)** : la plage se couvre de créatures (bébés). Tu cours, tu les attrapes (sac limité).
2. **Alerte (7 s)** : tu rentres au lagon ou tu montes sur une tour.
3. **Vague** : ce que tu portes est perdu si elle te prend (pas d'écran de mort, retour au lagon).
4. **Dépôt** : en entrant dans ton lagon, tes créatures vont dans les bassins libres. Elles nagent, **grandissent** et rapportent des pièces chaque seconde.

**Décision intéressante à chaque cycle** : aller loin (zones rares) ou rester prudent ; garder un bébé rare pour le faire grandir ou le relâcher contre des pièces ; attendre une marée spéciale pour viser une mutation.

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

- **Visite de lagon** : bouton « Visiter » sur le panneau de chaque lagon (8 lagons visibles sur la carte, ce qui est déjà le cas). Un « J'aime » par visiteur et par jour. Badge « Plus beau lagon du serveur ».
- **Pêche à plusieurs** : +10 % de chance de mutation pour chaque ami (Roblox friends) présent dans la même zone, plafonné à +30 %. Bonus multiplicatif sur la probabilité, affiché.
- **Léviathan** (§5.5) : un cadeau d'un joueur à tout le serveur.
- **Cadeaux** (Phase 2) : donner une créature à un ami du serveur. Échange limité (1 par heure, ami Roblox uniquement) pour éviter les arnaques ; pas d'échange contre des Robux.
- Pas de vol, pas de PvP.

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
- Min 8–10 : Coral Coast mis en avant (« créatures Uncommon, ×5 revenu »), premier Shell Egg proposé si les pièces suffisent.

## 9. Monétisation à prix fixe

Principe : on vend du **confort, de la vitesse et de l'expression**, jamais l'accès au contenu. Tout reste atteignable gratuitement. Aucune caisse, aucun œuf, aucune pièce vendus contre des Robux.

| Produit | Type | Prix (R$) | Ce que ça fait | Pourquoi ce prix |
|---|---|---|---|---|
| Tide Pass « Fast Growth » | Gamepass | 299 | Croissance ×2 (durées /2) | Le cœur du jeu ; achat « fan » principal |
| Big Net | Gamepass | 149 | Rayon de ramassage ×1,5 | Confort, petit prix d'entrée |
| Extra Pool | Gamepass | 249 | +1 bassin (MaxSlots 10 → 11) | Valeur durable, plafonnée à 1 |
| Deep Pockets | Gamepass | 199 | +2 places de sac | Confort |
| VIP Keeper | Gamepass | 399 | Titre doré, chat tag, décor VIP, +10 % pièces | Statut social, achat « soutien » |
| Coin Rush 15 min | Produit développeur | 39 | ×2 pièces pendant 15 min (cumul max 2 h) | Micro-achat ponctuel, pas d'obligation |
| Growth Rush 15 min | Produit développeur | 39 | Croissance ×2 pendant 15 min | Idem |
| Packs de décor de lagon | Produit développeur (contenu fixe affiché) | 49–149 | Coraux, lumières, cascades, sol | Expression, visible en visite |
| Traînées / skins de filet | Produit développeur | 49–99 | Cosmétique pur | Expression |
| Serveur privé | Roblox | 0 au lancement, puis 100/mois | Jouer entre amis | Standard |

Ce qu'on **ne vend pas** : pièces, œufs, créatures, mutations, chance de mutation, Écaille du Léviathan, rangs, cases du Codex.
UX : aucun pop-up d'achat non demandé, aucun compte à rebours sur une offre, pas de « Plus que X ! ». La boutique est un bouton du HUD.

Repère réaliste : sur un pass à 299 R$, le jeu reçoit 70 % = 209 R$ ≈ **0,79 $** via DevEx (100 000 R$ = 380 $). Aucun revenu n'est promis : tout dépend du trafic, qu'on ne connaît pas.

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

## 11. Impact pour l'équipe

### A — Serveur
- **Config** : remplacer Items par Creatures (même structure + champs `growth`), ajouter `Stages`, `Mutations`, `Tides`, `Codex`, `Rank`, `Offline` (bloc proposé §13).
- **Schéma de données v2** avec migration depuis v1 : `display` passe de `{itemId}` à `{ {id, mut, born} }` ; les anciens trésors deviennent l'espèce correspondante (table §4.2), `born = maintenant`, sans mutation. Ajout `codex`, `rank`, `scales`, `lastSeen`, `daily`.
- **WaveService** : type de marée par cycle (calendrier déterministe à partir de `cycle`), exposé dans `wave.tide` et en attribut `Tide`.
- **TreasureService → CreatureService** : tirage de mutation à l'apparition, attributs `Mutation`.
- **Income** : formule §5.1 ; stade calculé depuis `born` ; revenu hors ligne à la connexion.
- **Remotes (contrat v2, additif)** : `state.display[i] = {id, mut, stage, nextStageAt}`, `state.codex`, `state.rank`, `wave.tide`, `wave.nextSpecial` ; Notify `grow`, `mutation`, `codexNew`, `offline` ; RF `TideRank()`, `SummonLeviathan()`, `LikeLagoon(plot)`.
- Produits Roblox : MarketplaceService ProcessReceipt idempotent pour les boosts.

### B — Interface
- HUD : bandeau de marée (type courant + prochaine spéciale), revenu/s.
- Bassins : billboard compact par créature (nom, stade, mutation, barre jusqu'au prochain stade).
- Écrans : Codex (grille 10×5, probabilités), écran « Pendant ton absence », Tide Rank (ce qu'on garde / perd, très clair), boutique (§9, sans pop-up), quêtes.
- Onboarding §8 (flèche, textes uniques, bouton qui pulse une fois).
- Mobile d'abord : tout à un doigt, boutons ≥ 44 px.

### C — Monde
- **10 modèles de créatures** low-poly stylisés (le plus gros poste), Root invisible comme les Items actuels, ≤ 1 500 triangles chacun.
- Variantes de mutation **sans nouveau modèle** : 4 presets (Golden, Glow, Storm, Rainbow) appliqués par script (couleur, matériau, ParticleEmitter, PointLight) dans `ReplicatedStorage.Assets.FX.Mutations`.
- Socles → **bassins** d'eau (même noms Pedestal1..10 et attributs pour ne pas casser le serveur).
- Ambiance des marées : Lighting/Atmosphere presets par type (Golden, Night, Storm, Rainbow), changés en tween côté client.
- Phase 2+ : modèle du Léviathan (unique, décoratif, au large).

## 12. Prototype Phase 1 (qualité finale, petit périmètre)

**Dedans :**
- 1 zone : Shallows (les autres zones fermées par une barrière de récif « bientôt »).
- 1 lagon par joueur, 5→10 bassins (Slots existant).
- 2 espèces : Pebble Crab, Sand Star (2 modèles finaux).
- Croissance 4 stades, hors ligne inclus.
- Marées : Normal + **Golden Tide** uniquement (1 preset de mutation).
- Vague, tours, améliorations Speed/Bag/Slots, sauvegarde v2 avec migration.
- Les 30 premières secondes du §1 ter, **son compris**, au niveau final. C'est le premier livrable jugé.
- HUD : pièces, revenu, bandeau de marée, billboard de bassin.
- Créatures vivantes : yeux, nage, réaction à l'approche, pile sur la tête quand on les porte.
- Codex limité aux 2 espèces (Normal + Golden = 4 cases).

**Dehors (Phase 2+)** : zones 2–5, autres mutations, Rainbow, compagnons rhabillés, Léviathan, Tide Rank, quêtes, visites, boutique Robux, événements.

**Critère de sortie de la Phase 1** : sur un téléphone moyen à 60 FPS, un nouveau joueur dépose sa première créature en moins de 60 s, voit un Juvenile et une Golden en moins de 10 min, et a envie de revenir voir sa créature grandir.

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
```

## 14. Questions ouvertes pour Moaad (non bloquantes)
1. Garder le nom **Tide Rush** ou renommer le jeu **Reef Keepers** ? (Proposition : « Tide Rush: Reef Keepers ».)
2. Prix exacts des gamepasses : valeurs de départ ci-dessus, à ajuster après les premiers tests.
