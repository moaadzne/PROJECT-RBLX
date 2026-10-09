# BIBLE QUALITÉ — Tide Rush
Prompt de direction créative et technique (copie fidèle du texte fourni par Moaad le 2026-10-08).

## 0. Comment utiliser ce document
- C'est la référence de qualité du projet. Il complète le prompt de passation, qui donne l'état du projet et l'architecture.
- En cas de conflit :
  - sur les faits du projet, le prompt de passation l'emporte ;
  - sur le niveau d'exigence, c'est ce document.
- N'applique pas tout d'un coup : suis l'ordre de la section 12.

## 1. La demande de Moaad
« Je veux un jeu très réaliste, beau et fluide, comme un vrai jeu avec un budget de 500 millions de dollars. Il ne faut pas que ça fasse Roblox. On arrive dans un nouvel univers complètement bien fait, avec du confort partout, plein de trucs pratiques et rien de chiant. Le joueur doit être complètement absorbé et vouloir revenir tout le temps. Zéro bug, de belles animations fluides. »

## 2. Audit de la demande : rendre chaque mot mesurable
| Ce qu'il a dit | Ce que ça veut dire concrètement |
|---|---|
| « Budget 500 M$ » | Pas un chiffre : ça veut dire aucun détail amateur. Tout est cohérent, fini, réactif et performant. Note honnête : Roblox impose ses limites (pas de shaders maison, avatars Roblox, téléphones modestes). La cible est un « AAA stylisé » qui pousse Roblox au maximum, vérifié par les checklists ci-dessous. |
| « Réaliste » | Crédible plutôt que photoréaliste : formes stylisées, mais lumière, matériaux, eau et sons qui se comportent comme en vrai. Proportions réelles, lumière physique (Future), matériaux PBR. |
| « Pas Roblox » | Supprimer tout ce qui trahit Roblox : interface et polices par défaut, textures à studs, ciel par défaut, SmoothPlastic partout, formes en blocs, sons par défaut, leaderboard par défaut, UI qui apparaît d'un coup. |
| « Nouvel univers » | Un vrai univers : une histoire courte, des noms, une palette cohérente, des repères visuels, de la vie ambiante. Le joueur doit sentir un lieu, pas une map. |
| « Confort partout / trucs pratiques » | La liste de qualité de vie de la section 8, avec des critères vérifiables. |
| « Rien de chiant » | La liste d'interdits de la section 9. |
| « Absorbé, revient tout le temps » | Une progression en couches (section 10), éthique et halal : jamais de manipulation, jamais de tirage payant. |
| « Animations fluides » | Les règles d'animation de la section 6 (durées, courbes, 60 FPS, rien de saccadé). |
| « Zéro bug » | La définition de « terminé » et le protocole de test de la section 11. |

Ce qui manquait dans la demande, et que j'ajoute : le public visé ; l'accessibilité ; l'audio ; les budgets de performance ; l'onboarding ; les textes de l'interface ; les indicateurs de réussite ; la méthode (prototype complet d'une zone d'abord) ; les priorités.

Public visé : joueurs Roblox, en majorité sur téléphone, environ 9–24 ans, sessions courtes mais fréquentes. Textes du jeu en anglais.

## 3. L'objectif et les 5 piliers
Objectif : « Un archipel tropical au coucher du soleil, beau comme un jeu console stylisé, fluide à 60 FPS sur un téléphone moyen, sans friction ni bug, avec une boucle de progression qui donne envie de faire encore un tour et de revenir demain. »

Chaque pilier a son test :
1. **Beau au premier regard.** Test : n'importe quelle capture d'écran pourrait servir de miniature.
2. **Agréable sous les doigts.** Test : chaque action donne un retour visuel et sonore en moins de 0,1 s.
3. **Zéro friction.** Test : tout se fait en 2 taps maximum, et rien n'oblige à lire un mode d'emploi.
4. **Envie de revenir.** Test : à tout moment, le joueur a un objectif à 30 s, un à 10 min et un pour demain.
5. **Fiable.** Test : zéro erreur en console, zéro perte de progression, et aucune triche possible côté client.

## 4. Direction artistique
**Univers** : « Tide Rush, l'archipel des Marées d'or ». Chaque soir, la Grande Marée apporte des trésors depuis les abysses et reprend tout ce qui reste sur le sable. Les joueurs sont des « Tide Runners ». Cette histoire justifie la boucle de jeu.

**Palette** : sable doré #F8DA9E, lagon turquoise #16A0A8, corail #FF7A8A, orange couchant #FFB25A ; bleu nuit #1E2A44 pour l'interface ; couleurs de rareté : gris, vert, bleu, violet, or.

**Lumière** : Technology Future, soleil bas (ClockTime vers 17) ; lumière principale chaude, ambiance et ciel froids ; Atmosphere pour la profondeur, Bloom discret (seuil haut), ColorCorrection légère, ombres douces ; pas de flou de profondeur en jeu, seulement dans les menus et cinématiques.

**Matériaux et formes** : SurfaceAppearance PBR sur les objets principaux ; MaterialVariant pour le sable mouillé près de l'eau, le bois patiné et la pierre de corail ; jamais de grandes surfaces en SmoothPlastic uni ; MeshParts biseautés et organiques, échelle cohérente, silhouettes lisibles de loin.

**Un monument par zone** : zone 1 un phare ; zone 2 une arche de corail ; zone 3 un temple englouti ; zone 4 un bateau pirate ; zone 5 des cristaux des abysses.

**Eau** : eau animée ; bandes d'écume au bord, qui défilent côté client (Texture.OffsetStudsU) ; crête de vague avec des embruns ; sable mouillé qui sèche en 3 s après la vague.

**Vie ambiante** : mouettes en vol, crabes qui courent, poissons qui sautent ; nuages qui bougent, bateaux à l'horizon ; palmes qui ondulent légèrement côté client.

**Effets visuels** : faisceaux de rareté, étincelles, explosions au ramassage, traînées au dépôt, embruns. Budget limité de particules et de lumières.

## 5. Interface « pas Roblox »
**Système visuel** : valeurs fixes partagées (couleurs, coins arrondis de 12 à 20 px, UIStroke, UIGradient) ; Fredoka One pour les titres, Builder Sans pour le texte ; un seul style d'icônes, avec des images importées ; panneaux translucides façon verre.

**HUD** : minimal (monnaie, revenu par seconde, sac, minuteur de la vague, 3 boutons ; le reste dans des panneaux) ; zones de sécurité ; UIScale et UIAspectRatioConstraint ; testé sur téléphone (844×390), tablette et PC (1920×1080) avec le Device Emulator ; masquer PlayerList et Backpack (SetCoreGuiEnabled).

**Boutons** : survol à 1,05, appui à 0,92, avec un son, relâchement à ressort ; état désactivé bien visible ; échec = petite secousse, flash rouge et message précis (« Need 165 more coins »).

**Panneaux** : ouverture en 0,25 s, de l'échelle 0,9 avec un fondu, courbe Back ; léger flou de l'arrière-plan (BlurEffect).

**Chiffres** : ils défilent jusqu'à leur nouvelle valeur ; format court (1.2K, 3.4M).

**Textes** : courts, positifs et cohérents, en anglais ; pas de jargon.

**Notifications** : 3 maximum, disparition seule en 2,5 s ; priorité : la vague, puis les récompenses, puis les infos.

**Accessibilité** : chaque rareté a une couleur, une icône et un nom ; texte d'au moins 14 px sur mobile, bon contraste ; option « réduire les animations » ; aucun clignotement au-delà de 3 fois par seconde.

## 6. Animation et sensation
**Règles générales** : toujours une anticipation et un amorti, jamais d'animation linéaire dans l'interface ; animations interruptibles ; durées : micro-retour 0,08–0,15 s, transitions 0,2–0,35 s, célébrations 0,6–1,2 s.

**Ramasser un trésor** : gonfle à 1,3 puis disparaît ; explosion de particules dans la couleur de sa rareté ; son plus aigu quand la rareté monte ; l'icône vole en courbe vers le sac en 0,5 s, le compteur du sac rebondit.

**Déposer à la base** : les trésors volent un par un vers les socles à 0,15 s d'intervalle ; le compteur de pièces défile ; un « +X/s » flotte au-dessus.

**La vague** : 7 s avant, l'horizon s'assombrit et un grondement monte ; 3 s avant, sirène et pulsation rouge dans l'interface ; à l'arrivée, embruns et rugissement ; le joueur touché voit l'écran éclaboussé, un léger ralenti, un fondu, puis revient à sa base ; après, le sable mouillé sèche et les trésors brillent.

**Améliorations** : confettis, son, chiffre de stat animé ; effet sur le personnage (souffle de vent pour la vitesse).

**Ouvrir un œuf** : cérémonie de 2,5 à 3,5 s (l'œuf tremble de plus en plus, se fissure, éclate en lumière) ; révélation dans la couleur de la rareté, avec le nom et le bonus ; bouton « Equip » mis en avant ; animation accélérée quand on enchaîne.

**Caméra et personnage** : cinématique d'arrivée ; petite poussée de FOV en gagnant de la vitesse ; légère secousse quand la vague frappe (sauf « réduire les animations ») ; bruits de pas selon le sol, éclaboussures dans l'eau, lignes de vitesse.

**Technique** : tout mouvement continu côté client, calculé avec dt ; TweenService pour l'interface, ressorts maison pour l'organique ; le serveur ne met jamais à jour un CFrame à chaque frame.

## 7. Audio
- Ambiance par zone : vagues, vent et mouettes ; bulles du récif ; craquements du bateau pirate ; bourdonnement des abysses.
- Effets : interface, ramassage selon la rareté, dépôt, achat, vague.
- Mixage : l'ambiance baisse quand la vague approche.
- Organisation : SoundGroups (Master, SFX, Ambient, UI), curseurs dans les réglages ; uniquement des sons sous licence (Creator Store ou importés par Moaad).
- Musique : demander d'abord à Moaad (préférence halal). Par défaut, pas de musique instrumentale : une ambiance sonore soignée la remplace.

## 8. Confort : checklist (chaque point doit être vrai)
**Dans la partie** : dépôt automatique en entrant dans sa base ; remplacement automatique du trésor le plus faible ; rayon d'attraction pour ramasser sans viser au pixel près ; bouton Home désactivé pendant la vague ; prochain objectif toujours affiché.

**Compagnons et récompenses** : « Equip best » en un tap ; récompense quotidienne en un tap ; résumé des gains hors ligne sur une seule carte (jamais de pluie de popups à la connexion) ; aucune micro-gestion d'inventaire obligatoire.

**Interface et réglages** : tout en 2 taps maximum ; réglages sauvegardés (graphismes, volumes, réduire les animations, taille de l'interface).

**Technique** : chargement en moins de 5 s avec préchargement ; se reconnecter ne fait jamais rien perdre ; tutoriel que l'on peut passer.

## 9. Interdits (« rien de chiant »)
- **Tutoriels et popups** : tutoriel long et forcé ; cinématique qu'on ne peut pas passer et qui se répète ; popups empilées à la connexion.
- **Progression et argent** : mur de paiement ; énergie ou stamina qui bloque le jeu ; perte de progression permanente ; faux sentiment de rareté, messages culpabilisants, compte à rebours fait pour pousser à payer.
- **Jeu** : mort sans explication ; mur invisible sans indice visuel ; longue marche sans rien à voir ni à ramasser ; grind sans variété.
- **Interface et son** : interface qui cache l'action ; boutons minuscules, icônes incohérentes, pavés de texte ; notifications en rafale ; saccade à l'ouverture d'un menu ; sons trop forts ou répétitifs, son de mort par défaut de Roblox.

## 10. Envie de revenir (éthique et halal)
**Couches de motivation** : 30 secondes (courir, ramasser, fuir) ; une session de 10–20 min (la prochaine amélioration, le prochain œuf, la prochaine zone) ; plusieurs jours (livre de collection, rebirth « Tide Rank » avec rang cosmétique, série quotidienne) ; plusieurs semaines (Night Tide chaque semaine, Golden Wave surprise et gratuite, mise à jour chaque semaine, codes).

**Social** : visiter la base de ses amis ; bonus quand on joue avec des amis ; classements.

**Récompenses** : le hasard vient uniquement du jeu et reste gratuit (trésors au sol, œufs payés en pièces gagnées) ; les séries et les jalons donnent des récompenses fixes.

**Règles halal et Roblox** : jamais de tirage aléatoire payé en Robux ; jamais de pièces vendues contre des Robux ; probabilités toujours affichées ; les joueurs gratuits peuvent tout atteindre, payer fait seulement gagner du temps ou du style.

**Objectifs internes** (à ajuster avec les vraies données) : tutoriel terminé par au moins 80 % des joueurs ; session moyenne d'au moins 15 min ; bon taux de retour le lendemain et à 7 jours. À suivre avec AnalyticsService : entonnoir des premières minutes et événements clés.

## 11. Zéro bug : définition de « terminé »
**Une fonctionnalité est terminée seulement si** : elle marche en solo et à 2 joueurs (Test → Clients and Servers) ; la console n'affiche aucune erreur ni warning ; les cas limites sont testés (sac plein, socles pleins, déconnexion pendant la vague, mort, reconnexion, clics en rafale sur les remotes, FPS bas) ; les données sont sauvegardées puis rechargées correctement ; l'affichage mobile est vérifié avec le Device Emulator ; aucune frame ne dépasse 33 ms sur la cible (MicroProfiler) ; tous les remotes sont validés côté serveur, avec une limite de fréquence.

**Données** : ne jamais écraser une sauvegarde après un chargement raté ; verrouillage de session ; schéma versionné avec migrations ; les versions DataStore (30 jours) servent de filet de sécurité.

**Régression** : une commande de test via TR_Debug rejoue les vérifications essentielles en une fois.

**En ligne** : compter les erreurs (ScriptContext.Error) et les suivre.

## 12. Méthode et ordre de travail
1. **Prototype complet d'une zone** : une zone, une base, la vague et le HUD, au niveau de qualité final.
2. Ensuite, dans cet ordre : boucle principale fonctionnelle ; sensation de la boucle ; système d'interface ; passe de beauté sur le monde ; profondeur de progression (compagnons, rebirth) ; rétention ; monétisation à prix fixe ; lancement.
3. Chaque étape se termine par des captures pour Moaad et la checklist cochée.
4. Le Mac de Moaad est faible : vérifier les visuels lourds sur un autre appareil, garder une qualité d'affichage modérée dans Studio.

## 13. Comment parler à Moaad
En français, en le tutoyant ; le verdict d'abord, en court ; pour une action manuelle, des étapes numérotées avec les clics exacts ; compte-rendu en 3 lignes (fait, testé, prochaine étape) ; si une demande dépasse ce que Roblox permet, le dire une fois et proposer la meilleure alternative.
