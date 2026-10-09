# GDD — Ride the Tsunami: Steal & Ride (concept Reef Keepers) · v3

Auteur : E (concept & game design). v1 le 2026-10-09, **v2 le 2026-10-09** après la levée des règles halal par Moaad et la décision de D (vol, monture, Marée Royale, monétisation v2). Cohérent avec docs/AUDIT_TOP10.md §6.
Statut : v2 complète et perfectible. Les chiffres sont des **valeurs de départ** à régler par playtest, pas des mesures.

**Changements v3 (Direction v2, 09/10)** : secrets et plot twist (§6 bis), contenu sans fin (§6 ter), île ouverte (§3 bis), tirage Deep Dive (§9 bis), vraies espèces (§4.2), stades Juvenile/Adult/Elder/Titan, 30 s tendues (§1 ter), ton des textes, Config (§13).

**Changements v2** : §0 (titre et miniatures), §2 (boucle avec vol), §4.6 Monture, §4.7 Vol, §4.8 Marée Royale, §7 Social, §8 (protection des nouveaux), §9 Monétisation v2, §11 Impact, §12 Phase 1 v2, §13 Config, §14. Les autres sections de la v1 restent valables.

---

## 0. Hook : titre et miniatures

### 3 titres (verbe + objet)
| Titre | Vérification (recherche web, 09/10) | Avis |
|---|---|---|
| **Ride the Tsunami** | Aucun jeu connu trouvé sous ce titre. Proches : « Escape The Tsunami », « Escape Tsunami For Brainrots ». | **Recommandé.** Unique, filmable, dit la promesse que les autres n'ont pas (surfer la vague). |
| Steal a Sea Creature | Pas de jeu trouvé, mais **« Steal a Fish »** existe déjà (vol + poissons) : trop proche, on serait vu comme un clone. | À éviter comme titre principal. |
| Catch, Steal & Ride | Rien trouvé. Plus long, moins clair en 5 s. | Bon sous-titre. |

**Titre choisi par Moaad (09/10) : « Ride the Tsunami ».**

**Recommandation** : nom affiché **« Ride the Tsunami: Steal & Ride »**. « Steal » reste dans le titre pour la recherche Roblox, mais la promesse forte est la monture sur la vague.
Limite : ma recherche web ne remplace pas la recherche Roblox. **Moaad doit taper les 3 titres dans la recherche Roblox avant de publier.**

### 3 miniatures à tester en A/B
1. **Surf** : un avatar debout sur une raie manta Titan dorée qui glisse sur la crête d'une vague énorme, bouche ouverte de joie. Ciel orange. Texte « RIDE IT! ».
2. **Vol** : un avatar qui court avec une créature arc-en-ciel dans les bras, un autre joueur qui le poursuit, la vague juste derrière. Texte « STEAL IT! ».
3. **Rareté** : une tortue Titan arc-en-ciel au centre, brillante, entourée de petites créatures normales, un avatar choqué. Texte « RAINBOW GIANT? ».
Règles : 3 éléments maximum, lisible sur un téléphone, couleurs fortes mais naturelles, key art cinématique, aucune personne réelle ni personnage existant.

## 1. Univers et histoire courte

**L'archipel de Maré.** Chaque minute, la Grande Marée se retire et laisse sur la plage des créatures marines perdues. Puis la vague revient et les reprend.
Tu es un **Reef Keeper**, un gardien de lagon. Ton travail : sauver le plus de créatures possible avant la vague, les élever dans ton lagon et reconstruire le récif.
La légende dit que lorsqu'un lagon est assez beau, le **Léviathan**, l'ancien gardien de la mer, remonte des profondeurs pour le saluer.

Ton : intense, crédible, premium (docs/DIRECTION_V2.md). La vague est une menace naturelle spectaculaire ; le vol est un sprint tendu ; la monture est une sensation de vitesse.

## 1 bis. Les piliers du fun (ce qui décide de tout le reste)

Le dernier test a montré que « rien ne va ». Le GDD part donc du **ressenti**, et la réutilisation du code n'est qu'un bonus. Si une partie de l'ancien jeu ne sert pas ces piliers, on la jette.

1. **Attraper, c'est un plaisir physique.** Chaque prise a un son, un saut de la créature dans les bras, un petit ralenti de 0,15 s, un chiffre qui saute. On doit avoir envie d'en attraper une de plus sans même penser aux pièces.
2. **Ce que j'attrape est vivant et à moi.** De vrais animaux qui fuient, nagent, réagissent quand on s'approche du lagon. Pas des objets sur des socles, et rien de mignon.
3. **La vague fait battre le cœur.** On entend la mer gronder, l'eau se retire, le ciel change. C'est une course, pas une punition : on frôle la vague, on ne meurt pas.
4. **Il y a toujours un « et si… » juste devant.** Une créature brillante un peu trop loin, une marée dorée annoncée, un juvénile qui va grandir dans 40 s.

**Ce qu'on ne garde pas de l'ancien jeu, par principe :** les trésors inanimés, les socles nus, le spawn au hub loin de tout, le premier contact avec un HUD chargé, l'absence de son et de réaction.

## 1 ter. Les 30 premières secondes, image par image (v3 : tendu et spectaculaire)

Objectif : à 30 s, le joueur a eu **une montée d'adrénaline**, possède **une créature à lui**, et a compris la vague **sans lire un mot de tutoriel**. La première vague doit **faire peur**.

| Temps | Ce qu'il voit et entend | Ce qu'il fait | Ce qu'il ressent |
|---|---|---|---|
| 0–2 s | Plan aérien en mouvement au-dessus de l'île au coucher du soleil : lumière rasante, brume, lagon turquoise taillé dans la roche volcanique. Son : vent, ressac, une note grave lointaine. | Rien (chargement masqué). | « Attends… c'est Roblox, ça ? » |
| 2–4 s | La caméra se pose derrière son avatar, au bord de **son** lagon. Sur le sable humide, à 12 studs, un **Ghost Crab** détale entre les rochers. Seul élément d'interface : le joystick. | Il regarde. | Curiosité, envie de chasser. |
| 4–7 s | Le crabe fuit en zigzag quand il approche (il faut le couper). | Il court après. | Le jeu réagit, c'est vivant. |
| 7–8 s | **CATCH** : impact sec, son lourd et net, micro-ralenti 0,15 s, mot « CATCH » en capitales condensées. Le crabe est tenu sous le bras. | Contact = prise. | Satisfaction immédiate. |
| 8–12 s | La caméra s'ouvre sur la plage : 4 créatures entre les rochers, dont une **Cushion Star dorée**, reflets métalliques, loin vers le large. | Il court. | « Celle-là, je la veux. » |
| 12–18 s | Il en attrape 2 ou 3. Les mouettes s'envolent d'un coup. Le ressac s'arrête. | Il continue. | Quelque chose cloche. |
| 18–21 s | **La mer se retire** à vue d'œil : sable découvert, poissons qui sautent, coques d'épaves qui apparaissent. Grondement grave qui monte dans les basses. Le ciel s'assombrit. | Il se retourne. | Malaise, tension. |
| 21–23 s | À l'horizon, **un mur d'eau plus haut que les tours** se dresse, crête d'écume, ombre qui avale la plage. Texte unique au sol, en capitales : **RUN**. | Il comprend seul : il faut rentrer. | **Peur.** |
| 23–27 s | Course vers le lagon. Caméra plus basse, tremblement léger, embruns. Le grondement couvre tout. La Cushion Star dorée est **avalée** derrière lui. | Il sprinte. | Adrénaline, regret. |
| 27–28 s | Il franchit la barrière de corail ; les créatures plongent dans le lagon, chacune avec un son lourd. | Automatique. | Soulagement. |
| 28–30 s | La vague **s'écrase contre la barrière**, juste derrière lui ; pluie d'embruns, silence d'une seconde, puis l'eau se retire. Une seule ligne : **« NEXT TIDE: GOLDEN. »** | Il regarde le large. | « J'y retourne. » |

**Règles de cette séquence (non négociables pour B et C) :**
- Aucun texte avant 21 s sauf « CATCH » ; aucun HUD sauf le joystick. Le HUD apparaît **après** la première vague.
- Première vague **scénarisée** (18 s après le spawn), impossible d'être pris (on garde son sac). Les suivantes suivent le cycle normal.
- La 2e marée du joueur est **forcément Golden**.
- Le son est la moitié de la peur : grondement dans les basses, silence avant l'impact. Priorité Phase 1.
- Si le chargement dépasse 2 s, la caméra reste en plan aérien lent, jamais d'écran noir.

## Ton des textes du jeu (v3)
- **Anglais, capitales condensées pour les titres, verbes d'action** : CATCH, STEAL, RIDE, SURF, SURVIVE, DEFEND, REVENGE.
- **Aucun emoji, aucun diminutif, aucun « Yay », aucun « !!! ».** Phrases de 2 à 5 mots.
- Exemples : « WAVE IN 5 » · « LAGOONS OPEN » · « RUN » · « KAI STOLE YOUR HAWKSBILL TURTLE » · « REVENGE AVAILABLE » · « RECOVERED » · « ROYAL TIDE — 1ST » · « TITAN REACHED » · « NEW SPECIES LOGGED ».
- Le jeu s'adresse au joueur comme un **jeu d'action**, jamais comme une garderie.

## 2. Boucle principale

**Boucle de 60 s (un cycle de vague)** : chaque phase a un rôle.
1. **Calme (35 s) : attraper.** La plage se couvre de créatures. Tu cours (ou tu montes ta créature), tu les attrapes et tu rentres les déposer. Les lagons sont **fermés** par une barrière de corail.
2. **Alerte (7 s) : choisir.** Les barrières de tous les lagons **tombent**. Tu choisis : défendre chez toi, aller voler chez un voisin, ou surfer la vague si tu as une Titan.
3. **Vague (~17 s) : la fenêtre de vol.** Les voleurs foncent, les propriétaires défendent, les surfeurs glissent sur la crête. Sur la plage, la vague emporte ce que tu portes.
4. **Reflux (2,5 s) : le verdict.** Les barrières remontent. Un voleur qui n'est pas rentré chez lui perd la créature volée, qui retourne chez son propriétaire.

**Décisions à chaque cycle** : aller loin ou rester prudent ; voler ou défendre ; garder une créature pour la monter ou pour son revenu ; verrouiller son lagon maintenant ou garder le verrou pour plus tard.

## 3. Couches de progression

| Horizon | But | Système |
|---|---|---|
| 1 min | Attraper sa première créature, la voir nager | Boucle |
| 10 min | Remplir 5 bassins, acheter Speed/Bag, voir un Adult, débloquer Coral Coast | Améliorations, croissance |
| 1 h | Première mutation (Golden Tide), premier œuf de compagnon | Marées, compagnons |
| Plusieurs jours | Codex à 50 %, une Légendaire en Titan | Codex, croissance longue |
| Plusieurs semaines | Attirer le Léviathan, Tide Rank 3+ | Léviathan, rebirth |

## 3 bis. Île ouverte (Phase 1, légère)

Demande de Moaad : « un open world, un peu ». Décision de D : **une île ouverte et compacte**.

> **Version de lancement (décision de D, 09/10)** : île d'environ **600 × 600**, crique centrale (rayon 70) avec les 8 lagons, anneaux de rareté recalés (70–150 / 150–225 / 225–300), **vague dans les 4 directions**, **3 points d'intérêt** (belvédère, épave, récif à marée basse), **8 tours**, **boussole et direction de la vague dans le HUD, sans carte**.
> **Phase 2 (première grosse mise à jour)** : île de 800 × 800 décrite ci-dessous, jungle, grotte, carte. On abandonne la plage en couloir et ses 5 zones alignées sur Z. Le monde grandit ensuite avec les nouvelles îles (§6 ter).

### 1. Plan de l'île cible (Phase 2 : 800 × 800 ; le lancement en est la version réduite)
- **Taille** : île d'environ **800 × 800 studs** (la plage actuelle fait environ 264 × 908, donc une surface du même ordre, × 2,5). Mer jouable autour jusqu'à 1 000 × 1 000. Le centre de la crique est en (0, 0).
- **Crique centrale protégée** : les 8 lagons, en arc de cercle, dans une baie fermée par des falaises (rayon d'environ 90 studs). **La vague ne la touche jamais.**
- **Rayons de rareté** : plus on s'éloigne de la crique, plus c'est rare et risqué (plus long à rentrer avant la vague).

```
                         N  (vague possible)
          ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
        ~   . . . . PLAGE NORD (rare) . . . .   ~
      ~   .  [T]     JUNGLE ######        [T]  .   ~
     ~   .        ######## (grotte G)           .   ~
W   ~  EPAVE    ##########         ^^^^^^         .  ~   E
~ ~ ~  (W)  .   ######  +--------+ ^ FALAISE ^ [T] .  ~ ~ ~
     ~   .  [T]         | CRIQUE | ^ belvédère^     .  ~
      ~   .  plage W    | 8 lagons|  ^^^^^^   plage E  ~
       ~   .            +---  ---+                .   ~
        ~   .  [T]     plage SUD (commune)   [T] .   ~
         ~    . . . . . RÉCIF (marée basse) . . .   ~
           ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~ ~
                         S
[T] = tour SAFE (8 tours, plateformes à 26 studs)   ### = jungle   ^^^ = falaise
```

| Anneau (distance au centre) | Rareté | Phase 1 |
|---|---|---|
| 90–200 | Common | Ghost Crab |
| 200–300 | Common/Uncommon | Cushion Star, Lionfish (plus tard) |
| 300–400 + points d'intérêt | Uncommon et plus | Hawksbill Turtle (montable) |

**Points d'intérêt** :
- **Falaise-belvédère** (E, 40–60 studs de haut) : à l'abri de toutes les vagues, la vue sur la vague qui traverse l'île. C'est le spot vidéo.
- **Épave** (W) : créatures meilleures, loin de la crique.
- **Récif à marée basse** (S) : apparaît pendant le reflux et la marée extrême (§6 bis).
- **Jungle et grotte** (N) : la grotte est en Phase 2 ; en Phase 1, la jungle est un raccourci boisé (le terrain haut est à l'abri).

### 2. La vague dans un monde ouvert
- **Direction par cycle** : N, E, S ou O, tirée au hasard, jamais 2 fois de suite la même. Annonce au début de l'alerte : **« WAVE FROM THE NORTH »** + flèche sur la boussole + ciel qui s'assombrit de ce côté.
- **Physique serveur** (même formule qu'aujourd'hui, projetée) : `d` = vecteur de direction, `front` avance de -R à +R. Un joueur est pris si `front - thickness ≤ p·d ≤ front`, `p.Y < height` et qu'il n'est pas à l'abri.
- **À l'abri** : la crique (rayon 90), les tours, tout terrain plus haut que la vague (falaise, collines de la jungle). Une Titan montée surfe (§4.6).
- **Le côté opposé à la vague est plus sûr** : les joueurs lisent l'annonce et choisissent leur plage. C'est une vraie décision.
- **Vol** : les lagons s'ouvrent à l'alerte comme avant. Le voleur doit traverser la crique puis rentrer **à son propre lagon** ; s'il s'enfuit vers une plage, la vague peut le prendre et la créature retourne chez son propriétaire.

### 3. Ce qui pousse à explorer
- Créatures propres à un biome : Hawksbill Turtle sur la plage E et à l'épave, Ghost Crab partout. Plus tard : Lionfish au récif, Blue-Ringed Octopus de nuit dans la grotte.
- Secrets du §6 bis placés dans le monde : l'épave pendant la marée extrême, le récif, puis la grotte et les gravures.
- **La monture** : traverser l'île en 10 s au lieu de 25 ouvre les plages lointaines.
- **Le belvédère** : le plus bel endroit du jeu pour regarder la vague, et l'endroit où on filme.

### 4. Impact et calendrier
| Qui | Travail | Estimation |
|---|---|---|
| A | Vague à direction (projection sur `d`), zones en anneaux et biomes à la place de Z, zones à l'abri (crique, tours, hauteur), spawn sur Terrain dans des anneaux | ~1,5 jour |
| B | Boussole + flèche de direction de la vague, annonce « WAVE FROM … », petite carte (image fixe + points des joueurs) | ~1 jour |
| C | Terrain de l'île (généré par script dans Studio puis retouché), crique et 8 lagons, falaise, épave, 8 tours, vague qui balaie dans 4 directions | **3 à 4 jours** : le gros risque |

**Risque sur le 29/10** : moyen. C est le goulot (île + créatures + vague). **Version minimale qui garde la sensation d'open world** si on prend du retard :
- île de **600 × 600** ;
- **2 directions de vague** (N et S) au lieu de 4 ;
- 3 points d'intérêt : falaise-belvédère, épave, récif (jungle et grotte en semaine 2) ;
- 6 tours ;
- carte remplacée par la boussole seule.
Gain estimé : environ 1,5 jour pour C et 0,5 jour pour B.

**Config proposée (pour A)** :
```lua
-- Version de lancement (600x600). Phase 2 : size = 800, coveRadius = 90, anneaux 90/200/300/400.
Config.Island = { size = 600, coveRadius = 70, waveDirections = { "N", "E", "S", "W" }, noRepeatDirection = true }
Config.Rings = {
	{ rMin = 70, rMax = 150, rarity = "Common", items = { { "GhostCrab", 100 } } },
	{ rMin = 150, rMax = 225, rarity = "Common", items = { { "GhostCrab", 40 }, { "CushionStar", 60 } } },
	{ rMin = 225, rMax = 300, rarity = "Uncommon", items = { { "CushionStar", 60 }, { "HawksbillTurtle", 40 } } },
}
```

## 4. Contenu

### 4.1 Zones (reprend Config.Zones, mêmes limites Z)
| # | Zone | Rareté | Créatures |
|---|---|---|---|
| 1 | Shallows | Common | Ghost Crab, Cushion Star |
| 2 | Coral Coast | Uncommon | Lionfish, Hawksbill Turtle  |
| 3 | Sunken Reef | Rare | Blue-Ringed Octopus, Leopard Ray |
| 4 | Pirate Cove → **Wreck Cove** | Epic | Titan Pacific Octopus, Lion's Mane Jelly |
| 5 | Abyss Shore | Legendary | Manta Ray, Whale Shark |

Renommer Pirate Cove en Wreck Cove est optionnel (plus cohérent, mais simple texte).

### 4.2 Créatures : **10 vraies espèces, 10 modèles** (v3, Direction v2)
Animaux marins réels, proportions et couleurs crédibles. **Interdit** : gros yeux, visages kawaii, couleurs bonbon. La rareté se lit par la **taille**, le **matériau**, la **lumière** et les **particules**. Même rareté et même revenu de base que les ids qu'elles remplacent.

| Id Config | Nom | Rareté | Revenu /s (Juvenile) | Montable | Ce qui la rend désirable |
|---|---|---|---|---|---|
| GhostCrab | Ghost Crab | Common | 1 | — | Rapide, presque invisible sur le sable, yeux pédonculés : il faut le **chasser**. |
| CushionStar | Cushion Star | Common | 2 | — | Texture épaisse, motifs rouge et crème : la plus belle prise du rivage. |
| Lionfish | Lionfish | Uncommon | 6 | — | Venimeux, nageoires en éventail spectaculaires. |
| HawksbillTurtle | Hawksbill Turtle | Uncommon | 10 | **Oui** | Carapace écaille ; la première monture, la tortue des surfeurs. |
| BlueRingedOctopus | Blue-Ringed Octopus | Rare | 30 | — | Un des animaux les plus venimeux au monde ; anneaux bleus qui s'allument quand on approche. |
| LeopardRay | Leopard Ray | Rare | 50 | **Oui** | Taches de léopard, vol sous-marin : monture rapide. |
| GiantPacificOctopus | Giant Pacific Octopus | Epic | 150 | — | Énorme, intelligent, change de couleur dans le bassin. |
| LionsManeJelly | Lion's Mane Jelly | Epic | 250 | — | La plus grande méduse connue, tentacules de plusieurs mètres, lueur ambrée. |
| MantaRay | Manta Ray | Legendary | 800 | **Oui** | Envergure immense, sauts hors de l'eau : la monture de prestige. |
| WhaleShark | Whale Shark | Legendary | 1500 | **Oui** | Le plus grand poisson du monde. En Titan, on surfe le tsunami dessus. |

Table de migration pour A : §13 (`Config.LegacyItemToCreature`).

### 4.3 Croissance (même hors ligne)
4 stades. Le stade se calcule à partir de l'heure de naissance (`born`, os.time serveur) : **aucun timer qui tourne**, donc la croissance hors ligne est automatique.

| Stade | Échelle visuelle | Multiplicateur de revenu |
|---|---|---|
| Juvenile | 0,6 | ×1 |
| Adult | 0,8 | ×2 |
| Elder | 1,0 | ×4 |
| Titan | 1,5 | ×8 |

Durée **cumulée** pour atteindre chaque stade (minutes) :

| Rareté | Adult | Elder | Titan |
|---|---|---|---|
| Common | 3 | 15 | 60 |
| Uncommon | 5 | 30 | 120 |
| Rare | 10 | 60 | 240 |
| Epic | 20 | 120 | 480 |
| Legendary | 30 | 240 | 1 200 (20 h) |

Une Légendaire atteint Titan en environ un jour : c'est le « reviens demain » naturel, sans pression.

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
- Espèces montables (grandes formes) : **Hawksbill Turtle** (tortue), **Leopard Ray**, **Manta Ray**, **Whale Shark**.
- Montables à partir du stade **Elder**. Bouton « Monter » sur le billboard du bassin ou dans l'inventaire. Une seule monture active.
- Vitesse : Elder **×1,3**, Titan **×1,6**, multipliée par l'amélioration Speed.
- **Les Titan surfent la vague** : un joueur sur une Titan n'est jamais pris. Quand la vague l'atteint, il glisse sur la crête (animation de surf) jusqu'à la limite des lagons, et **garde son sac**. C'est le moment vidéo du jeu.
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
- Lagon plein : la créature attrapée remplace la plus faible si elle vaut plus (logique actuelle). Sinon, elle est **relâchée** contre `revenu juvénile × SellMultiplier (20)` pièces (logique « sold » actuelle).
- Remplacement : la valeur comparée = revenu/s courant (stade et mutation inclus). Un Titan commun n'est donc pas écrasé par un juvénile rare de valeur inférieure.

### 5.2 Améliorations : inchangées (Speed, Bag, Slots dans Config.Upgrades)
Contrôle rapide : 5 Ghost Crab/Cushion Star juvéniles ≈ 7 pièces/s ; à Elder ≈ 30 /s. Speed niveau 1 (50) en 10 s, Slots niveau 1 (200) en < 1 min : le rythme des 10 premières minutes est bon.

### 5.3 Œufs de compagnons : inchangés (2 500 / 60 000 / 1 500 000)
Shell Egg atteignable vers 5–8 min, Coral Egg vers 45–60 min, Abyss Egg en jours. À valider en playtest.

### 5.4 Reef Codex : 10 espèces × 5 variantes (Normal, Golden, Glow, Storm, Rainbow) = **50 cases**
| Événement | Récompense |
|---|---|
| Nouvelle case | `revenu juvénile × 50` pièces |
| Ligne d'une espèce complète (5 variantes) | +5 % de revenu permanent (codexBonus) |
| 10 / 25 / 40 / 50 cases | décor de lagon exclusif (non achetable) : Coquillage géant, Arche de corail, Fontaine de perles, Statue du Léviathan |
Le Codex **n'est jamais réinitialisé** (ni par le rebirth).

### 5.5 Le Léviathan (but des semaines)
Condition : **Codex ≥ 30 cases** ET **tous les bassins occupés par des créatures Elder ou Titan**.
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
- **Quêtes quotidiennes** : 3 par jour, simples, choisies parmi une liste (attraper 20 créatures, survivre à 5 vagues, faire grandir 1 Elder, visiter 2 lagons). Récompense : pièces = 10 min de revenu courant, plus 1 jeton de décor. Elles **ne disparaissent pas** si on ne se connecte pas : on garde celles du jour en cours, sans compteur alarmant.
- **Cadeau quotidien** : on compte les **jours joués au total** (paliers à 3, 7, 14, 30 jours → décors). Il n'y a **pas de série qui se casse**.
- **Événements** (Phase 3) : une marée thématique par mois (ex. « Marée des lanternes ») avec 1 espèce saisonnière qui **revient chaque année** et des décors gagnables en jouant. Pas de récompense vendue « dernière chance ».

## 6 bis. Secrets et plot twists (à découvrir, compris sans lire)

Principe : chaque secret se **voit** avant de se lire. Un joueur de 10 ans le remarque (lumière, son, forme bizarre) ; un joueur de 25 ans veut comprendre et en parle. Les découvertes alimentent les vidéos (« vous saviez que… ? ») et donnent une raison de revenir.

| Secret | Comment on le découvre | Ce que ça donne | Phase |
|---|---|---|---|
| **La marée extrême** | 1 fois par heure environ (annoncée seulement par un signe : les mouettes s'enfuient, la mer se retire 2× plus loin) | Une **épave** émerge au large, avec une créature unique dans la cale. 20 s pour y aller et revenir. | 1 |
| **Créatures de nuit** | Quand l'heure du serveur passe la nuit, certaines espèces n'apparaissent **que dans l'obscurité** (Blue-Ringed Octopus qui brille, Lion's Mane Jelly) | Nouvelles cases de Codex, lueur visible de loin | 2 |
| **La grotte du reflux** | Pendant le reflux, une entrée s'ouvre 3 s sous une falaise. Un indice visuel : de la lumière qui sort de la roche | Une salle avec une créature rare et une gravure | 2 |
| **La rogue wave** | Toutes les 100 vagues d'un serveur, une vague **2× plus haute** : les tours ne suffisent plus, seuls le lagon et les Titans en surf sauvent | Moment collectif ; badge « SURVIVED THE ROGUE WAVE » | 2 |
| **L'espèce fantôme** | Le Codex montre une case **« ??? »** avec une silhouette. Elle se débloque quand un joueur du serveur réunit 3 mutations différentes de la même espèce | **Coelacanth**, poisson qu'on croyait disparu depuis des millions d'années (animal réel) ; annonce à tout le serveur | 2 |
| **Les gravures** | Dans la grotte, l'épave et le lagon niveau max : des gravures sur la roche, sans texte, qui montrent une silhouette immense sous l'île | Fil de l'histoire, collection de gravures | 2–3 |

**Le plot twist de fond (révélé par étapes en mises à jour)** : les tsunamis ne sont pas naturels. Une créature colossale **dort sous l'île** et chaque vague est sa respiration. Les gravures le laissent deviner ; la rogue wave est un « soupir » plus fort ; le Léviathan (§5.5) est la révélation finale : il se réveille. Personne n'est obligé de suivre l'histoire pour jouer, mais ceux qui la suivent la racontent.

Règles : aucun secret payant, aucun secret indispensable pour progresser, un indice visuel ou sonore pour chacun.

## 6 ter. Ne jamais avoir fait le tour

Le contenu fait à la main s'épuise toujours : un joueur motivé finit en quelques jours ce qu'on met des semaines à produire. On ne vise donc pas « assez de contenu » mais des **systèmes qui produisent de la nouveauté tout seuls**, et un monde qui **s'agrandit**.

### 1. Des combinaisons au lieu de contenu (zéro modèle en plus)
- **Mutations cumulables** (Phase 2) : une créature peut porter 1 mutation de marée **et** 1 trait rare (Albinos 1 %, Mélanique 1 %, Balafré 2 %, Géant record). Ça donne 10 espèces × 5 mutations × 5 traits = **250 combinaisons**, avec les probabilités affichées.
- **Taille unique** : chaque créature a une taille (de 0,85 à 1,25, distribution affichée). « La plus grande Manta du serveur » ou « du jeu » : un record à battre, sans fin.
- **Marées combinées** : de temps en temps, deux marées à la fois (Golden + Storm), qui ouvrent des mutations doubles.

### 2. Un monde qui s'agrandit
- **Nouvelles îles** (une par grosse mise à jour) : Mangrove, Récif profond, Glacier, Volcan sous-marin. Chacune apporte 2 à 3 espèces, une règle de vague différente (vague de glace qui ralentit, coulée de lave au reflux) et un secret.
- On voyage entre les îles en **chevauchant sa monture** au large : la monture devient le moyen d'explorer.

### 3. Toujours un objectif devant (jamais « plus rien à faire »)
| Rythme | Objectif |
|---|---|
| Chaque minute | La vague, une nouvelle plage, un vol possible |
| Chaque heure | Marée extrême (épave), Rainbow Tide |
| Chaque jour | 3 défis du jour (changés à minuit), Titan qui arrive à maturité, Léviathan disponible |
| Chaque semaine | **Marée de la semaine** : une règle spéciale (vague double, vol interdit, toutes les créatures sont Night…) + 1 défi de serveur collectif |
| Chaque mois | **Saison** : un pass de saison gratuit (les paliers payants sont optionnels), 1 espèce saisonnière qui revient l'année suivante, classement de saison |
| Sans fin | Codex à 250 combinaisons, records de taille, Tide Rank, gravures de l'histoire |

### 4. Le contenu que les joueurs créent eux-mêmes
- **Le vol et la revanche** : chaque serveur raconte une histoire différente.
- **Les échanges** (semaine 2) : une économie qui bouge chaque jour (« combien vaut une Lionfish Storm albinos ? »).
- **Les records** : plus grand Titan, plus de vols dans une vague, plus longue série de vagues survécues. Affichés sur des panneaux en jeu.
- **Les mystères de serveur** : un indice visuel caché apparaît pour tout le serveur, et le premier qui le résout débloque quelque chose pour tous.

### 5. Le rythme de mises à jour (réaliste pour l'équipe)
- **Chaque semaine** : une petite mise à jour (1 événement, 1 défi, 1 secret ou 1 trait).
- **Toutes les 3 à 4 semaines** : une grosse mise à jour (1 île ou 2 à 3 espèces, et un chapitre de l'histoire de la créature sous l'île).
- **Le point dur reste les modèles 3D** : 2 à 3 espèces par mois est réaliste seulement avec un modéliste ou des packs. Les systèmes 1, 3 et 4 ne demandent **aucun** nouveau modèle : c'est là qu'on met l'effort entre deux grosses mises à jour.

## 7. Social

- **Vol et revanche** (§4.7) : le cœur social. Chaque vol crée une histoire entre deux joueurs.
- **Marée Royale** (§4.8) : compétition visible, couronnes.
- **Monture** visible par tous (§4.6) : on montre sa Titan arc-en-ciel.
- **Visite de lagon** et « J'aime » : gardés (Phase 2).
- **Pêche à plusieurs** : +10 % de chance de mutation par ami Roblox dans la même zone, plafonné à +30 % (Phase 2).
- **Échanges** : **mise à jour de la semaine 2**, pas au lancement. Raison : il faut une interface anti-arnaque solide (double confirmation, aperçu des valeurs), et au lancement le vol couvre déjà le besoin de « prendre la créature des autres ». Règles : entre joueurs du même serveur, après 30 min de jeu cumulé, jamais contre des Robux.
- Léviathan (§5.5) : reporté en mise à jour.

## 8. Onboarding

### 60 premières secondes
- 0–30 s : voir §1 ter (séquence scénarisée, sans texte).
- 30–45 s : le HUD apparaît en fondu (pièces, revenu). Une flèche au sol montre les tours : « TOWERS = SAFE »
- 45–60 s : retour sur la plage, nouvelles créatures. Le joueur joue seul, sans guide.

### 10 premières minutes
- Min 1–2 : achat guidé de Speed niv. 1 (bouton qui pulse doucement, une fois).
- Min 2–4 : 5 bassins pleins, premier Adult (3 min) avec animation de croissance et « ×2 revenu ! ».
- Min 1–3 : deuxième marée **forcée Golden** pour ce joueur (promesse du §1 ter), pour qu'il voie une mutation tôt. Ensuite le calendrier normal reprend.
- Min 6–8 : ouverture du Codex (« 3/50 »), première récompense de case.
- Min 8–15 : protection débutant active (bouclier visible). Vers 12 min, un message unique : « PROTECTION ENDS IN 3:00 — LOCK YOUR LAGOON » avec le bouton Verrou mis en avant.
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
| **Pick a Creature** (alternative sans tirage, montrée **à la place** du Tide Egg si `ArePaidRandomItemsRestricted`) | Produit développeur | 149 | Le joueur choisit l'espèce, en Juvenile normal |

Probabilités du Tide Egg en Phase 1 (affichées sur le bouton) : Ghost Crab 50 %, Cushion Star 35 %, Hawksbill Turtle 15 % ; puis Golden 10 % sur le résultat.

### Plus tard (selon les données)
Œufs Robux par zone (49 / 149 / 399), Extra Pool (249), Deep Pockets (199), boosts de 15 min (39), packs de pièces (montants qui valent des heures de jeu, pas des semaines), cosmétiques de lagon et de monture, serveur privé.

Repère réaliste : sur 299 R$, le jeu touche 70 % = 209 R$ ≈ **0,79 $** via DevEx. Aucun revenu promis.

## 9 bis. Deep Dive : le tirage (demande de Moaad, 09/10)

> **Calendrier (décision de D, 09/10)** : Deep Dive sort en **semaine 2** (première mise à jour), réglé avec les données de la semaine 1. Au lancement : boutique minimale du §9 (3 passes + Tide Egg / Pick a Creature).

### Le prompt (demande de Moaad, améliorée)
> Ride the Tsunami a un système de tirage au sort, **Deep Dive**, qui est le moteur principal de collection rare et de revenu.
> Chaque plongée tire une récompense dans un pool à raretés claires (Common → Mythic), avec une animation courte, fluide et spectaculaire, et un multi-tirage ×10.
> Les objets les plus rares (créatures et variantes **exclusives**) s'obtiennent **surtout en payant** : la monnaie premium, les **Pearls**, s'achète en Robux.
> On en gagne aussi **un peu en jouant** : environ une plongée gratuite par semaine pour un joueur régulier. Ça suffit pour goûter au système et espérer, pas pour tout avoir.
> Obligatoire : probabilités affichées avant chaque achat, garantie (pity) contre la malchance, alternative sans tirage dans les pays où `ArePaidRandomItemsRestricted` est vrai, aucune fausse rareté.

### Monnaie : Pearls
| Source | Quantité |
|---|---|
| Packs Robux | 100 = 99 R$ · 550 = 499 R$ · 1 200 = 999 R$ · 2 600 = 1 999 R$ |
| Défis du jour (les 3) | 3 / jour |
| Victoire Marée Royale (top 1) | 5 |
| Paliers de jours joués (§6) | 10 à 30 |
Joueur régulier gratuit : environ **20–30 Pearls par semaine**, donc environ 1 plongée gratuite par semaine. Les packs Robux ne donnent pas de bonus caché : le prix au Pearl baisse visiblement avec la taille du pack.

### La plongée
- **1 plongée = 100 Pearls**, **10 plongées = 900 Pearls** (une gratuite).
- Animation de 3 s : la caméra plonge dans une fosse sombre ; une lueur de la couleur de la rareté monte des profondeurs avant la révélation. Passable après la première. Le ×10 révèle une grille de 10 cartes qui se retournent une par une (2 s au total).
- **Pool fixe par saison** (pas de rotation hebdomadaire au lancement) :

| Rareté | Chance | Contenu |
|---|---|---|
| Common | 55 % | Créature commune de l'île, 50–200 pièces |
| Rare | 30 % | Créature Uncommon/Rare, traînée de monture |
| Epic | 12 % | Créature Epic, ou créature avec mutation garantie (Golden ou Storm) |
| Legendary | 2,9 % | Créature Legendary (Manta Ray, Whale Shark) en Adult |
| Mythic | 0,1 % | **Variante exclusive Abyssal** (peau noire, bioluminescence rouge) : uniquement par Deep Dive |

- **Pity** : une Legendary garantie au plus tard à la **80e plongée** sans Legendary ; une Mythic garantie à la **400e**. Les compteurs sont visibles.
- **Pas de doublons inutiles** : un doublon se convertit en **Shards**, et 10 Shards de la même espèce = +1 stade de croissance. Même un mauvais tirage sert.

### L'entre-deux (réglage validé avec Moaad, 09/10)
Principe : **tout le monde tire, les payeurs tirent plus et plus profond.**
- **Shallow Dive gratuite, 1 par jour** pour tout le monde : même animation, pool plus modeste (Common 70 / Rare 25 / Epic 5 / Legendary 0 %). Chaque jour, chaque joueur a son petit moment de tirage, et une raison de revenir.
- **Deep Dive** (payante en Pearls) : le seul accès aux Legendary et Mythic par tirage.
- **Les plongées gratuites font avancer la pity** des Deep Dive à 50 % : un joueur gratuit fidèle progresse aussi vers sa Legendary.
- **Le pouvoir reste gagnable en jouant** : les Legendary normales existent aussi sur l'île (anneau extérieur, futures îles), en Juvenile. Deep Dive fait gagner du **temps** (Adult directement) et donne l'**exclusif** (Abyssal). Un gratuit peut tout faire ; un payeur va plus vite et se montre.
- **Indicateurs pour régler** : si D7 chute, +1 Shallow Dive le week-end ou plus de Pearls par défi ; si la conversion est trop basse, plus de visibilité sur l'Abyssal (en jeu, sur les autres joueurs), pas de pression.

### Règles avec le reste du jeu
- Les créatures **Abyssal** et toutes celles obtenues par Deep Dive sont **liées** : on ne peut ni les voler ni les échanger. Un joueur qui paie ne se fait pas prendre ce qu'il a payé, et ça empêche la revente contre de l'argent réel.
- Elles comptent dans le Codex et les classements.
- **Pays restreints** (`ArePaidRandomItemsRestricted`) : Deep Dive est caché et remplacé par la **Pearl Shop**, l'achat direct d'un objet précis du pool à prix fixe (Legendary 1 500 Pearls, Abyssal 8 000 Pearls).
- **À partir de la semaine 2**, le **Tide Egg** du §9 est remplacé par Deep Dive. Pick a Creature devient une ligne de la Pearl Shop.

### Interface (B)
- Bouton **DIVE** dans le HUD (pas de pop-up automatique).
- Écran Deep Dive : probabilités sur l'écran principal (pas cachées), compteurs de pity, solde de Pearls, boutons ×1 et ×10.

### Limites à connaître
- Roblox impose les probabilités affichées et le respect de PolicyService. Les règles évoluent : vérifier les règles de monétisation Roblox avant la sortie.
- Plus le gratuit est dur, plus la majorité non payante part. On garde donc l'environ 1 plongée gratuite par semaine et on règle selon les données (rétention D7 contre conversion).
- Repère réaliste : sur un pack de 499 R$, le jeu touche environ 349 R$, soit environ 1,33 $ via DevEx. Aucun revenu promis.

## 10. Rétention et KPI

### Calendrier
| Moment | Raison de revenir (positive) |
|---|---|
| Chaque minute | La vague, une nouvelle plage |
| Toutes les 8 min | Marée spéciale annoncée |
| Chaque heure | Rainbow Tide |
| Chaque jour | Légendaire qui devient Titan, 3 quêtes, revenu hors ligne, Léviathan disponible |
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
- **MountService** : monter/descendre, vitesse, Titan = jamais pris par la vague + surf.
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
- **3 modèles** pour la Phase 1 : Ghost Crab, Cushion Star, Hawksbill Turtle (**montable** : siège, posture du joueur, animation de surf).
- Barrière de corail par lagon (visuel ouvert / fermé, son), portes qui ne gênent pas la poursuite.
- Preset FX Golden, presets d'ambiance Golden Tide.
- Couronnes (3 accessoires), effet « créature royale » (lumière + faisceau).
- Sons : prise, vol, alerte, barrière, surf.

## 12. Prototype Phase 1 v2 (qualité finale, petit périmètre)

**Dedans :**
- Les 30 premières secondes du §1 ter, **son compris** : c'est le premier livrable jugé.
- 1 zone : Shallows (les autres zones fermées par une barrière de récif « bientôt »).
- **3 espèces** : Ghost Crab, Cushion Star, **Hawksbill Turtle** (montable, apparaît dans Shallows à 10 % pendant cette phase).
- Croissance 4 stades, hors ligne inclus. Pour tester la monture vite, durées Common/Uncommon du §4.3.
- **Monture** (Elder ×1,3, Titan ×1,6 + surf).
- **Vol complet** (§4.7) avec toutes les protections.
- Marées : Normal + **Golden Tide** ; **Marée Royale** à chaque Golden Tide.
- Améliorations Speed/Bag/Slots, sauvegarde v2 avec migration.
- Boutique minimale (§9) avec bascule PolicyService.

**Dehors** : zones 2–5, autres mutations, Codex complet, Léviathan, Tide Rank, échanges (semaine 2), visites, quêtes, compagnons.

**Critère de sortie** : sur un téléphone moyen à 60 FPS, un nouveau joueur dépose sa première créature en < 60 s, monte une créature en < 15 min, vit un vol (subi ou réussi) dans sa première session après la protection, et revient le lendemain.

## 13. Bloc Config proposé (pour A)

```lua
Config.Creatures = {
	GhostCrab = { name = "Ghost Crab", rarity = "Common", income = 1 },
	CushionStar = { name = "Cushion Star", rarity = "Common", income = 2 },
	Lionfish = { name = "Lionfish", rarity = "Uncommon", income = 6 },
	HawksbillTurtle = { name = "Hawksbill Turtle", rarity = "Uncommon", income = 10 },
	BlueRingedOctopus = { name = "Blue-Ringed Octopus", rarity = "Rare", income = 30 },
	LeopardRay = { name = "Leopard Ray", rarity = "Rare", income = 50 },
	TitanPacificOctopus = { name = "Titan Pacific Octopus", rarity = "Epic", income = 150 },
	LionsManeJelly = { name = "Lion's Mane Jelly", rarity = "Epic", income = 250 },
	MantaRay = { name = "Manta Ray", rarity = "Legendary", income = 800 },
	WhaleShark = { name = "Whale Shark", rarity = "Legendary", income = 1500 },
}
-- migration v1 -> v2
Config.LegacyItemToCreature = {
	-- ancien Item v1 -> nouvel id
	Shell = "GhostCrab", Starfish = "CushionStar", Pearl = "Lionfish", BlueCrab = "HawksbillTurtle",
	CoralCrown = "BlueRingedOctopus", GoldenCrab = "LeopardRay", TreasureChest = "GiantPacificOctopus",
	AbyssCrystal = "LionsManeJelly", MoonPearl = "MantaRay", TideHeart = "WhaleShark",
	-- ids du GDD v2 (si deja utilises dans une branche) -> nouvel id
	PebbleCrab = "GhostCrab", SandStar = "CushionStar", BubblePuffer = "Lionfish", ReefHatchling = "HawksbillTurtle",
	LanternSeahorse = "BlueRingedOctopus", CoralRay = "LeopardRay", InkOctopus = "GiantPacificOctopus",
	MoonJelly = "LionsManeJelly", StarWhaleCalf = "MantaRay", AbyssSerpent = "WhaleShark",
}

Config.Stages = {
	{ id = "Juvenile", scale = 0.6, mult = 1 },
	{ id = "Adult", scale = 0.8, mult = 2 },
	{ id = "Elder", scale = 1.0, mult = 4 },
	{ id = "Titan", scale = 1.5, mult = 8 },
} -- v3 : stades renommes (plus de Baby/Giant)
-- minutes cumulees pour atteindre Adult, Elder, Titan
Config.GrowthMinutes = {
	Common = { 3, 15, 60 },
	Uncommon = { 5, 30, 120 },
	Rare = { 10, 60, 240 },
	Epic = { 20, 120, 480 },
	Legendary = { 30, 240, 1200 },
}

Config.Mutations = {
	Golden = { mult = 3, label = "Golden" },
	Glow = { mult = 2, label = "Bioluminescent" },
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
Config.Leviathan = { minCodex = 30, minStage = "Elder", cooldownHours = 24, rainbowOdds = 25 }
Config.Rank = { baseCost = 1e6, costMult = 5, incomeBonus = { 0.25, 0.50, 0.75, 1.00, 1.50 }, bonusAfter = 0.50, scaleFromRank = 5 }

function Config.GetRankCost(rank: number): number
	return Config.Rank.baseCost * Config.Rank.costMult ^ (rank - 1)
end

-- Paliers visuels du lagon (revenu/s total, lu par C). Cale sur l'economie :
-- T2 ~15 min (5 communes Elder), T3 = haut de la Phase 1 (Hawksbill Titan doree = 240/s),
-- T4 = Epic/Rare en Elder (jours), T5 = Legendaires Titan (semaines).
Config.LagoonTiers = { 0, 30, 200, 5000, 100000 }

-- v2 : monture, vol, Maree Royale, boutique
Config.Mount = { species = { HawksbillTurtle = true, LeopardRay = true, MantaRay = true, WhaleShark = true }, minStage = "Elder", speedMult = { Elder = 1.3, Titan = 1.6 }, giantSurfs = true }
Config.Steal = {
	grabHold = 1.0, carrySpeedMult = 0.8, maxCarry = 1,
	lockDurationWaves = 1, lockCooldownCycles = 4,
	protectAfterStolenWaves = 2, maxStolenPer10Min = 3,
	newbieMinutes = 15, newbieMinCreatures = 4,
}
Config.Royal = { onSpecialTides = true, rewardMinutes = { 5, 3, 2 }, uniquePerServer = 1, royalMutation = "Golden" }
Config.Shop = {
	Passes = { FastGrowth = 299, BigNet = 149, VIPRider = 399 }, -- ids Roblox a remplir
	TideEgg = { price = 79, odds = { { "GhostCrab", 50 }, { "CushionStar", 35 }, { "HawksbillTurtle", 15 } }, goldenChance = 10 },
	PickCreature = { price = 149 }, -- remplace TideEgg si ArePaidRandomItemsRestricted
}
```

## 14. Questions ouvertes pour Moaad
1. Titre : **« Ride the Tsunami: Steal & Ride »** (validé par Moaad le 09/10). Dernière vérification dans la recherche Roblox avant de publier.
2. Prix de la boutique de lancement : valeurs de départ, à ajuster après 1 semaine de données.
