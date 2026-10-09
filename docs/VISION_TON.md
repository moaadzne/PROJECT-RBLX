# VISION & TON — le prompt de Moaad, amélioré (F, 09/10, à valider par D)

## 1. Ce que Moaad a dit (ses mots)
> « Pas trop enfantin, pour que ça touche la plus grande tranche d'âge possible. Pas les jeux à 2 balles qu'il y a de partout : un vrai jeu, réaliste, pas enfantin. Il faut que ça touche le plus de personnes. Il faut tout revoir, ne plus avoir l'impression d'être sur Roblox. On arrive dans le jeu et on se dit : wow, ça c'est Roblox ? Mais pas trop non plus : il faut trouver le bon entre deux. »

## 2. Le prompt amélioré (à mettre en tête de chaque session A, B, C, E)
```
Tide Rush doit avoir l'air d'un VRAI jeu, pas d'un jeu Roblox de plus.
Cible : 10 à 30 ans et plus. Un enfant de 10 ans comprend tout en 10 secondes ;
un ado ou un adulte n'a jamais honte d'y jouer ni de le montrer en vidéo.

Le style, c'est le réalisme stylisé : proportions, lumière, matières, eau et sons
crédibles, avec des formes à peine adoucies pour rester lisibles sur un téléphone.
Pas cartoon, pas mignon, pas plastique ; pas photoréaliste lourd non plus.
Repères de ton : Sea of Thieves (mer, lumière) et la bande-annonce d'un film
d'aventure océanique. Jamais un dessin animé pour enfants.

Le test d'arrivée : dans les 10 premières secondes, le joueur se dit
« attends, c'est sur Roblox, ça ? ». Il reconnaît Roblox (son avatar, les contrôles),
mais tout le reste (lumière, mer, vague, interface, sons) est au niveau d'un jeu console.

La vague est une vraie menace, pas un jouet. Les créatures sont belles et
impressionnantes, pas mignonnes. L'interface est sobre, nette et adulte.
Les textes sont courts et assurés, sans bébé-langage.

Simple à prendre en main, profond à maîtriser : la collection pour tous ;
le vol, la monture et la Marée Royale (habileté, compétition, prestige)
pour les plus grands.

Avant de montrer quoi que ce soit à Moaad : checklist §6 entièrement verte.
```

## 3. Le juste milieu
| Trop « Roblox » (à éviter) | **La cible** | Trop loin (à éviter aussi) |
|---|---|---|
| Blocs, SmoothPlastic, couleurs bonbon | Formes organiques, matières PBR, palette naturelle avec 2 ou 3 accents vifs | Photoréalisme lourd qui rame sur téléphone |
| Polices cartoon (LuckiestGuy, Fredoka, Bangers) | Police nette et moderne, grasse pour les titres | Interface minuscule et illisible façon PC |
| Créatures « bébé » avec de gros yeux | Animaux marins crédibles, majestueux en grandissant | Créatures gores ou effrayantes (public mineur) |
| « Yay! », « Awesome!!! », emojis partout | Textes courts et assurés : « Caught: Coral Ray », « Wave in 5 » | Pavés de texte, lore obligatoire |
| Sons « boing », bruitages de jouet | Mer, vent, grondement grave de la vague, impacts sourds | Ambiance sombre et oppressante en permanence |
| Tout s'allume et clignote en même temps | Un seul effet fort au bon moment (Golden Tide, Giant) | Aucun retour visuel : le jeu paraît mort |
| Vague = mur bleu en plastique | Vague massive : ombre, écume, embruns, sol qui tremble | Vague « réaliste » illisible : on ne voit plus où fuir |

## 4. Règles vérifiables par domaine

**Monde (C)**
- Lumière Future, soleil bas, ombres douces. Palette : sable, turquoise et vert d'eau, bois brun ; accents corail et or seulement sur ce qui compte (créatures rares, phares, récompenses).
- Saturation modérée : une capture d'écran ne doit jamais ressembler à un jouet en plastique.
- Échelle réelle : avatar ≈ 5 studs ; tout le reste est cohérent avec l'avatar (DA_MONDE §0 bis).
- Horizon vivant : îles, bateaux, nuages, oiseaux. Le monde continue au-delà de la carte.

**Créatures (C, E)**
- Anatomie inspirée d'animaux réels (crabe, raie, poulpe, méduse, hippocampe, baleine, serpent de mer pour le mythique). Proportions adultes, pas de tête énorme ni de gros yeux ronds.
- Les stades montrent une montée en puissance : petit et vif → adulte → **Giant impressionnant**. Ce n'est pas « bébé mignon → gros mignon ».
- Les mutations changent la matière et la lumière (or poli, bioluminescence, électricité), pas des couleurs bonbon au hasard.

**Interface (B)**
- Une police nette pour les titres et Builder Sans pour le texte. Panneaux sombres translucides, coins arrondis modérés, contraste fort.
- HUD minimal. Rien qui couvre l'action. Animations courtes et précises, sans rebonds exagérés.
- Icônes dans un seul style, détourées et réalistes, pas des emojis.

**Son (C, B)**
- Ambiance de mer réelle par couches (ressac, vent, mouettes au loin). La vague : grondement grave qui monte, puis impact. Interface : clics feutrés.
- Aucun bruitage de dessin animé. Musique : seulement si Moaad la valide, discrète et cinématique.

**Ressenti et caméra (B)**
- Le personnage a du poids : petite poussée de FOV en sprint, légère secousse à l'impact de la vague, éclaboussures. Option « réduire les animations » respectée.
- Arrivée : une cinématique courte qu'on peut passer, puis le contrôle tout de suite.

**Textes et noms (E, B)**
- Anglais simple et assuré. Pas de bébé-langage, de « !!! » ni d'emojis dans l'interface.
- Les noms des créatures et des stades sonnent comme un jeu d'aventure, pas comme une crèche (§7).

**Public large (E, A)**
- 10 ans : la boucle se comprend sans lire. 15–30 ans : habileté (vol pendant la vague, trajectoire de monture), compétition (Marée Royale) et prestige visible (Giant, lagon palier 5).
- Rien de condescendant. Pas de tutoriel bavard : on apprend en jouant.

## 5. Les 10 premières secondes (« wow, c'est Roblox ? »)
1. Écran de chargement maison : une image fixe de la baie au coucher du soleil, le logo et une barre fine. Aucun élément Roblox par défaut.
2. La caméra glisse au ras de l'eau vers la plage. Au loin, une vague gronde. La lumière est dorée, l'écume brille.
3. La caméra se pose derrière l'avatar, au bord de son lagon. Une seule indication discrète montre la première créature à attraper.
4. Dès la 1re vague : l'horizon s'assombrit, le son monte, le sol vibre. Le joueur court, se met à l'abri et voit la vague passer. C'est cette image qu'il racontera.

## 6. Checklist « anti-enfantin / anti-Roblox » (contrôle de F sur chaque push de B et C, et avant toute capture pour Moaad)
- [ ] Aucune police cartoon (LuckiestGuy, FredokaOne, Bangers, Cartoon, Arcade).
- [ ] Aucun SmoothPlastic visible de plus de 2×2 studs. Aucun Part en bloc visible de plus de 4 studs.
- [ ] Aucune couleur saturée hors palette sur une grande surface.
- [ ] Aucun texte avec emoji, « !!! » ou bébé-langage. Chaque texte d'interface fait 6 mots au plus.
- [ ] Les créatures ont des proportions crédibles (pas de tête énorme ni de gros yeux ronds).
- [ ] La vague fait peur pour de vrai (son, lumière, échelle) tout en restant lisible : on sait où fuir.
- [ ] Aucun élément d'interface Roblox par défaut visible (leaderboard, backpack, police par défaut).
- [ ] La capture d'arrivée pourrait servir de miniature ou de bande-annonce.
- [ ] 60 FPS sur un téléphone moyen : le réalisme ne passe jamais avant la fluidité.

## 7. Ce qui contredit déjà ce prompt dans le repo (constats de F, à trancher par D)
| Où | Constat | Proposition |
|---|---|---|
| `src/StarterPlayer/StarterPlayerScripts/TideClient/Theme.lua:47` (branche B) | Titres en `Enum.Font.LuckiestGuy`, une police cartoon | Police nette et grasse (Montserrat ou Builder Sans Bold) |
| `docs/BIBLE_QUALITE.md` §5 | « Fredoka One pour les titres » : police ronde, très enfantine | Remplacer par la même police que ci-dessus |
| `docs/DA_MONDE.md` (en-tête « Style ») | « couleurs saturées mais chaudes » | « palette naturelle, saturation modérée, 2 ou 3 accents » |
| `docs/GDD.md` §1 ter (2–4 s) | Émotion visée : « il est mignon, il est coincé » | « une créature rare échouée, il faut la sauver avant la vague » |
| `Config.Creatures` et GDD §4.2 | Noms qui font crèche : Reef Hatchling, Bubble Puffer, Star Whale Calf | Exemples : Sea Turtle, Spiny Puffer, Star Whale ; à décider par E |
| Noms des stades (Config.Stages) | À vérifier : si le 1er stade s'appelle « Baby », il fait enfantin | Exemples : Young / Adult / Elder / Giant |

## 8. Limites honnêtes (Roblox)
- Les avatars des joueurs restent ceux de Roblox. Réglage possible (décision de D) : Game Settings → Avatar → R15 et des proportions plus réalistes. Les avatars restent quand même ceux des joueurs.
- Le téléphone moyen fixe le plafond : peu de lumières dynamiques, des particules dosées, StreamingEnabled. Le « wow » vient de la lumière, de l'eau, du son et de la mise en scène, pas du nombre de polygones.

## 8 bis. Remplacer les bases de Roblox (demande de Moaad : « faut tout changer, même les bases de Roblox, tout modifier »)
Règle : **tout ce que Roblox permet de remplacer est remplacé.** Seul ce qui est imposé reste (tableau 2).

**1. Ce qu'on remplace**
| Élément Roblox par défaut | Remplacé par | Qui | Comment |
|---|---|---|---|
| Écran de chargement Roblox | Écran maison (image de la baie, barre fine) | B | `ReplicatedFirst` + `RemoveDefaultLoadingScreen()` |
| Leaderboard, sac (Backpack), barre de vie, roue d'emotes | Masqués, remplacés par nos panneaux | B | `SetCoreGuiEnabled(…, false)` |
| Nom et vie au-dessus des têtes | Étiquette maison (nom, rang, titre de la Marée Royale) | A + B | `Humanoid.DisplayDistanceType = None` (A) + BillboardGui (B) |
| Chat (fenêtre et bulles) | Notre police, nos couleurs, notre position | B | `TextChatService` : ChatWindowConfiguration et BubbleChatConfiguration |
| Caméra | Caméra maison : FOV dynamique, secousse de la vague, cinématique d'arrivée | B | Module caméra client, avec les contrôles standards gardés |
| Joystick et bouton de saut sur mobile | Notre apparence, même comportement | B | Seulement si c'est sûr : des contrôles cassés = joueurs perdus |
| Animations du personnage (marche, course, saut, nage) | Pack d'animations plus naturel, identique pour tous | Moaad + B | Game Settings → Avatar → Animation, ou script `Animate` dans StarterCharacterScripts |
| Sons du personnage (pas, saut, « oof ») | Pas selon le sol (sable, bois, eau), éclaboussures | C + B | Remplacer `RbxCharacterSounds` dans StarterPlayerScripts |
| Proportions des avatars | R15 obligatoire, proportions réalistes et identiques | Moaad + D | Game Settings → Avatar (type R15, plages d'échelle) |
| Mort et réapparition | Jamais de mort : retour à la base, déjà prévu | A | Déjà dans le serveur |
| Invites « Appuyer sur E » | Notre style | B | `ProximityPrompt.Style = Custom` |
| Curseur (PC) | Curseur maison | B | Icône de souris personnalisée |
| Ciel, lumière, eau | Déjà remplacés | C | DA_MONDE |

**2. Ce que Roblox impose (impossible à retirer)**
- Le bouton du menu Roblox en haut de l'écran et le menu Échap.
- Les fenêtres d'achat en Robux.
- Certains messages système : déconnexion, erreurs réseau.

**Avis de F (à trancher par D avec Moaad)** : remplacer l'avatar de chaque joueur par un personnage unique imposé (StarterCharacter) est possible. Mais les joueurs perdent leur identité, et leur avatar est ce qu'ils montrent dans leurs vidéos et à leurs amis. Je recommande plutôt : avatar du joueur gardé, proportions réalistes identiques pour tous, nos animations, et une tenue « Reef Keeper » en cosmétique.

À ajouter à la checklist §6 : aucun élément du tableau 1 n'apparaît sous sa forme Roblox par défaut.

Pour Rojo : `src/StarterPlayer/StarterCharacterScripts` est maintenant mappé (chemin optionnel, protégé), pour le script `Animate` et les sons du personnage.

## 9. Application (proposée à D, qui décide et distribue)
- **E** : noms des créatures et des stades, émotion de l'onboarding (§7), ton des textes de la boucle.
- **B** : police des titres, style des panneaux et des icônes, cinématique d'arrivée et ressenti (§4, §5).
- **C** : palette et saturation dans DA_MONDE, proportions des créatures, son de la vague (§4).
- **A** : rien de visuel. Seulement les noms dans Config, si E les change.
- **F** : applique la checklist §6 à chaque push de B et C et envoie les écarts directement à l'auteur.
