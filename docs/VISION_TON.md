# VISION & TON — annexe détaillée de DIRECTION_V2 (F, 09/10)

> **Annexe de `docs/DIRECTION_V2.md`. En cas de conflit, DIRECTION_V2 l'emporte.**
> Ce document ne répète pas DIRECTION_V2. Il donne le prompt à coller en tête de chaque session, les règles détaillées par zone, la checklist de contrôle de F et la liste des éléments Roblox par défaut à remplacer (validée par D).

## 1. Prompt de session (à mettre en tête de chaque session A, B, C, E)
```
Ride the Tsunami doit avoir l'air d'un VRAI jeu, pas d'un jeu Roblox de plus.
Public : cœur 13–25 ans, accessible dès 10 ans, crédible pour un adulte de 30 ans.
Un ado de 16 ans peut le streamer sans honte ; un enfant de 10 ans comprend quoi faire sans lire.
La simplicité vient des RÈGLES, jamais d'un style bébé.

Style : réaliste stylisé. Lumière, eau, matières, animaux et sons crédibles, formes simplifiées
pour rester lisibles sur un téléphone. Pas cartoon, pas mignon, pas plastique ; pas photoréaliste lourd.

Test d'arrivée : dès la première seconde, le joueur se dit « attends… c'est sur Roblox, ça ? ».
Il reconnaît Roblox (son avatar, les contrôles) ; tout le reste est au niveau d'un jeu console.

Ton : cool, intense, premium. La vague est une menace spectaculaire, le vol est un sprint tendu,
la monture est une sensation de vitesse. Interface sobre, textes courts et assurés, aucun emoji.

Tout ce que Roblox permet de remplacer est remplacé (VISION_TON §6).
Avant de montrer quoi que ce soit à Moaad : le test de DIRECTION_V2 et la checklist VISION_TON §5 sont verts.
Référence : docs/DIRECTION_V2.md (elle prime).
```

## 2. Le juste milieu, au détail
| Trop « Roblox » (à éviter) | **La cible** | Trop loin (à éviter aussi) |
|---|---|---|
| Blocs, SmoothPlastic, couleurs bonbon | Formes organiques, matières PBR, palette naturelle avec des accents (or, turquoise du lagon) | Photoréalisme lourd qui rame sur téléphone |
| Polices rondes ou cartoon (LuckiestGuy, Fredoka, Bangers) | Police condensée nette, titres en MAJUSCULES espacées | Interface minuscule et illisible, façon PC |
| Créatures « bébé » avec de gros yeux | Vrais animaux marins, anatomie crédible, impressionnants en grandissant | Créatures gores ou effrayantes (public mineur) |
| « Yay! », « Awesome!!! », emojis | Verbes d'action : CATCH, STEAL, RIDE, SURVIVE ; « Wave in 5s » | Pavés de texte, lore obligatoire |
| Sons « boing », bruitages de jouet | Océan, vent, grondement grave de la vague, impacts lourds | Ambiance sombre et oppressante en permanence |
| Tout s'allume et clignote en même temps | Un effet fort au bon moment (rareté, vol réussi, surf, couronne) | Aucun retour : le jeu paraît mort |
| Vague = mur bleu en plastique | Vague massive : plus haute que les tours, écume, embruns, ombre, sol qui tremble | Vague « réaliste » illisible : on ne voit plus où fuir |

## 3. Règles détaillées par zone

**Monde (C)**
- Lumière Future, soleil bas, ombres douces, brume. Palette naturelle (sable, roche volcanique, bois flotté, végétation). Accents or et turquoise seulement sur ce qui compte.
- Une capture d'écran ne doit jamais ressembler à un jouet en plastique.
- Échelle réelle : avatar ≈ 5 studs ; tout le reste est cohérent avec l'avatar (DA_MONDE §0 bis).
- Horizon vivant : îles, bateaux, nuages, oiseaux. Le monde continue au-delà de la carte.

**Créatures (C, E)**
- Vrais animaux marins (exemples dans DIRECTION_V2). Proportions adultes, sans grosse tête ni gros yeux ronds.
- Les stades montrent une montée en puissance (jeune et vif → adulte → **Giant impressionnant**), pas « bébé mignon → gros mignon ». Les noms des stades suivent la même règle.
- Les mutations changent la matière et la lumière (DIRECTION_V2 : nacre, bioluminescence, arcs électriques, irisation).

**Interface (B)**
- Panneaux sombres translucides, coins de 6 à 10 px, police condensée nette (titres) et Builder Sans (texte), contraste fort.
- HUD minimal. Rien ne couvre l'action. Animations de 0,1 à 0,25 s, sans rebonds exagérés.
- Icônes dans un seul style, pleines ou au trait. Jamais d'emoji.

**Son (C, B)**
- Ambiance de mer réelle par couches (ressac, vent, mouettes au loin). Vague : grondement grave qui monte, puis impact. Interface : clics feutrés.
- Aucun bruitage de dessin animé. Musique sous licence (DIRECTION_V2) : tendue pendant l'alerte et la vague, calme ailleurs.

**Ressenti et caméra (B)**
- Le personnage a du poids : petite poussée de FOV en sprint, légère secousse à l'impact de la vague, éclaboussures. L'option « réduire les animations » est respectée.
- Arrivée : une cinématique courte qu'on peut passer, puis le contrôle tout de suite.

**Textes et noms (E, B)**
- Anglais simple et assuré. Pas de bébé-langage, pas de « !!! », pas de diminutifs.

**Public large (E, A)**
- 10 ans : la boucle se comprend sans lire. 13–25 ans : habileté (vol pendant la vague, trajectoire de monture), compétition (Marée Royale) et prestige visible (Giant, lagon palier 5).

## 4. Les 10 premières secondes
1. Écran de chargement maison : une image de la baie au coucher du soleil, le logo et une barre fine. Aucun élément Roblox par défaut.
2. La caméra glisse au ras de l'eau vers la plage. Au loin, une vague gronde. La lumière est dorée, l'écume brille.
3. La caméra se pose derrière l'avatar, au bord de son lagon. Une seule indication discrète montre la première créature à attraper.
4. Dès la 1re vague : l'horizon s'assombrit, le son monte, le sol vibre. Le joueur court, se met à l'abri et voit la vague passer. C'est cette image qu'il racontera.

## 5. Checklist de contrôle (F, sur chaque push de B et C, et avant toute capture pour Moaad)
- [ ] Aucune police ronde ou cartoon (LuckiestGuy, FredokaOne, Bangers, Cartoon, Arcade).
- [ ] Aucun SmoothPlastic visible de plus de 2×2 studs. Aucun Part en bloc visible de plus de 4 studs.
- [ ] Aucune couleur saturée hors palette sur une grande surface.
- [ ] Aucun emoji, « !!! » ni bébé-langage dans l'interface. Textes d'interface de 6 mots au plus.
- [ ] Créatures aux proportions crédibles. Aucun nom de créature ni de stade qui fait bébé.
- [ ] La vague fait peur pour de vrai (son, lumière, échelle) tout en restant lisible : on sait où fuir.
- [ ] Aucun élément du tableau §6.1 sous sa forme Roblox par défaut.
- [ ] La capture d'arrivée pourrait servir de miniature ou de bande-annonce.
- [ ] 60 FPS sur un téléphone moyen : le réalisme ne passe jamais avant la fluidité.

## 6. Remplacer les bases de Roblox (demande de Moaad, VALIDÉ par D le 09/10)
Règle : **tout ce que Roblox permet de remplacer est remplacé.** Seul ce qui est imposé reste (§6.2).

### 6.1 Ce qu'on remplace
| Élément Roblox par défaut | Remplacé par | Qui | Comment |
|---|---|---|---|
| Écran de chargement Roblox | Écran maison (image de la baie, barre fine) | B | `ReplicatedFirst` + `RemoveDefaultLoadingScreen()` |
| Leaderboard, sac (Backpack), barre de vie, roue d'emotes | Masqués, remplacés par nos panneaux | B | `SetCoreGuiEnabled(…, false)` |
| Nom et vie au-dessus des têtes | Étiquette maison (nom, rang, titre de la Marée Royale) | A + B | `Humanoid.DisplayDistanceType = None` (A) + BillboardGui (B) |
| Chat (fenêtre et bulles) | Notre police, nos couleurs, notre position | B | `TextChatService` : ChatWindowConfiguration et BubbleChatConfiguration |
| Caméra | Caméra maison : FOV dynamique, secousse de la vague, cinématique d'arrivée | B | Module caméra client, avec les contrôles standards gardés |
| Joystick et bouton de saut sur mobile | Notre apparence, même comportement | B | Seulement si c'est sûr : des contrôles cassés = joueurs perdus |
| Animations du personnage (marche, course, saut, nage) | Pack d'animations plus naturel, identique pour tous | C (choix du pack) + B (branchement) + Moaad (réglage) | Script `Animate` dans `src/StarterPlayer/StarterCharacterScripts` (mappé par Rojo) + Animation = Standard (IMPORT_LUNDI §5) |
| Sons du personnage (pas, saut, « oof ») | Pas selon le sol (sable, bois, eau), éclaboussures | C (sons) + B (script) | LocalScript nommé `RbxCharacterSounds` dans StarterPlayerScripts, qui remplace celui de Roblox |
| Proportions des avatars | R15 obligatoire, proportions identiques pour tous | Moaad | Réglage Avatar (IMPORT_LUNDI §5) |
| Mort et réapparition | Jamais de mort : retour à la base, déjà prévu | A | Déjà dans le serveur |
| Invites « Appuyer sur E » | Notre style | A (prompts créés par le serveur) + B (interface) | `ProximityPrompt.Style = Custom` (A) + `ProximityPromptService.PromptShown` (B) |
| Curseur (PC) | Curseur maison | B | `UserInputService.MouseIcon` |
| Ciel, lumière, eau | Déjà remplacés | C | DA_MONDE |

### 6.2 Ce que Roblox impose (impossible à retirer)
- Le bouton du menu Roblox en haut de l'écran et le menu Échap.
- Les fenêtres d'achat en Robux.
- Certains messages système : déconnexion, erreurs réseau.

### 6.3 Avatars (décision de D, 09/10)
On **garde l'avatar de chaque joueur**, avec R15, des proportions identiques pour tous et nos animations. Pas de personnage unique imposé : l'avatar fait l'identité du joueur et se voit dans ses vidéos. Une tenue « Reef Keeper » pourra exister en cosmétique.
