# Interface — Ride the Tsunami (B) · v3

Références :
- `docs/DIRECTION_V2.md` : elle prime sur la bible pour le style ;
- `docs/VISION_TON.md` §5 (checklist de F) et §6.1 (éléments Roblox à remplacer) ;
- contrat `review/review_context.md` v2.1 ; `docs/GDD.md` v2.

## 1. Style : « jeu console », pas enfantin

- **Police.** Titres et chiffres en **Oswald Bold**, texte courant en **Builder Sans**.
  - Pourquoi Oswald : Barlow Condensed n'existe pas dans Roblox. Parmi les polices intégrées (vérifiées dans les types Roblox : Oswald, Roboto Condensed, Sarpanch, Titillium Web, Michroma…), Oswald est la condensée nette la plus proche. Comme elle est intégrée, il n'y a rien à charger ni de licence à gérer.
  - Roboto Condensed reste la solution de repli.
- **Titres en MAJUSCULES espacées** (`Theme.Caps`). Roblox n'a pas d'interlettrage : on insère une espace fine (U+200A) entre deux lettres. Les chiffres et les prix ne sont pas espacés.
- **Panneaux** (`Theme.Plate`) : nuit marine translucide (transparence 0,22), filet clair de 1 px, trait de couleur fin en option, coins de 6 à 10 px (`Theme.Corner` est bridé).
- **Aucun emoji.** Les icônes sont dessinées dans un seul style, pleines ou au trait (`Theme.Icon`).
  - Noms : lock, unlock, ride, down, shop, alert, arrow, crown, shield, revenge, close, clock, wave, spark, moon, bolt, info, coin, net, dot.
  - Une image de C dans `Assets.UI.Icons.<nom>` remplace le dessin automatiquement.
- **Couleur + icône + nom**, toujours : rareté (badge à lettre et nom), mutation, marée, médaille.
- **Textes** de 6 mots au plus, en anglais direct, sans « ! » : WAVE IN, LAGOONS OPEN, SURVIVE, RUN HOME, REVENGE, STOLEN, SURF.
- **Mobile d'abord** : écran de design 900×480 (téléphone à l'échelle 0,85), texte ≥ 17 px de design (≈ 14,5 px réels), boutons ≥ 58 px, actions placées au-dessus du bouton de saut.

## 2. Animations (DIRECTION_V2)

| Usage | Durée | Courbe |
|---|---|---|
| Appui / survol d'un bouton | 0,08 / 0,12 s | Quad / Quart, sans rebond |
| Retour sec (`Theme.Pop`) | 0,15 s | Quart |
| Panneaux, toasts, HUD | 0,15–0,25 s | Quad / Quart |
| Célébration (`Theme.Celebrate`) | 0,45 s | Back |

Les célébrations sont réservées aux vrais moments : Giant atteint, vol réussi, couronne, surf, achat accordé.
« Réduire les animations » coupe les secousses et les rebonds, plafonne les durées et saute la caméra d'intro.

## 3. Écrans et références (principe seulement, rien de copié)

| Écran | Module | Référence | Principe |
|---|---|---|---|
| HUD : pièces, revenu, marée | `Hud` | Fortnite (HUD de match) | Peu d'éléments, chiffres nets, lisibles en 0,5 s |
| Bandeau de marée | `Hud` | Sea of Thieves (alerte de tempête) | Un bandeau en haut au centre, couleur = type de marée |
| Étiquette de bassin | `PoolBillboards` | Animal Crossing (étiquettes d'objets) | Nom, stade, barre, rien de plus |
| Intro des 30 s | `Onboarding` | Journey (ouverture) | Pas de texte ; caméra et flèche au sol |
| Vol (alerte, flèche, maintien) | `StealHud` | Sea of Thieves (navire attaqué) | Alerte rouge et flèche au bord de l'écran vers la menace |
| Marée Royale | `RoyalHud`, `NameTags` | Mario Kart (classement en course) | Top 3 en direct, médailles or, argent, bronze |
| Boutique | `Shop` | Clash Royale (boutique) | Cartes à prix fixe, probabilités avant l'achat, ouverture sur demande |
| Invites « appuyer sur E » | `Prompts` | The Last of Us (invites contextuelles) | Touche + verbe, discret, jauge si maintien |

## 4. Disposition (design 900×480)

```
┌──────────────────────────────────────────────────────────────┐
│ [o 1.25K   ]       [~ GOLDEN TIDE         0:23]   [toasts]   │
│ [+12/s]            [   WAVE IN  ━━━━━━━━━━━━━ ]   [toasts]   │
│ [# PROTECTED 12:30]     [! KAI HAS YOUR CRAB ]    [toasts]   │
│ [x REVENGE: KAI    ]                                         │
│ [ROYAL TIDE        ]                                         │
│ [1  Moaad     1.2K ]                                         │
│                                         [LOCK] [RIDE] [SHOP] │
│ (joystick)                                         (saut)    │
└──────────────────────────────────────────────────────────────┘
```

## 5. Éléments Roblox remplacés (VISION_TON §6.1)

| Élément | Remplacement | Où | État |
|---|---|---|---|
| Écran de chargement | Image de la baie, titre, barre fine | `src/ReplicatedFirst/LoadingScreen.client.lua` | Fait. Image = attribut `LoadingImage` sur ReplicatedFirst (C) |
| Classement, sac, vie, emotes | Masqués | `init.client.lua` | Fait |
| Nom au-dessus des têtes | Étiquette maison (nom, couronne, VIP, bouclier, voleur) | `NameTags` | Fait. A met `DisplayDistanceType = None` |
| Chat | Police, couleurs, position | `ChatStyle` (TextChatService) | Fait |
| Caméra | FOV dynamique, grondement et choc de la vague, surf, intro | `Feel`, `Onboarding` | Fait. Contrôles standards gardés |
| Invites ProximityPrompt | Interface maison, utilisable au doigt | `Prompts` | Fait (Style Custom) |
| Curseur PC | Image de C | `Feel` | Prêt. Attend `Assets.UI.Cursor` |
| Animations du personnage | Script `Animate` | `src/StarterPlayer/StarterCharacterScripts` | En attente du pack choisi par C |
| Sons du personnage | `RbxCharacterSounds` maison | StarterPlayerScripts | En attente des sons de C |
| Joystick et saut mobiles | Non touchés | — | Volontaire : des contrôles cassés font perdre des joueurs |

## 6. Modules client (`src/StarterPlayer/StarterPlayerScripts/TideClient`)

| Module | Rôle |
|---|---|
| `init.client.lua` | Point d'entrée (LocalScript TideClient), charge les modules dans l'ordre |
| `Util`, `Settings`, `Sfx`, `Fx` | Plomberie : signal, tweens, sons, effets d'écran |
| `Store` | État et remotes du contrat v2.1 ; mode démo dans Studio |
| `Theme`, `Components` | Système visuel console, icônes dessinées |
| `Notifications` | Toasts (3 au plus) ; messages gardés pendant que le HUD est caché |
| `Hud` | Porte-monnaie, marée, alerte, colonne d'états, boutons d'action, classement |
| `Prompts` | Invites maison |
| `PoolBillboards` | Étiquettes des bassins (1 Hz) |
| `NameTags` | Étiquettes des joueurs |
| `World` | Flottement des créatures, échelle du stade, look de mutation |
| `Ambience` | Lumière des marées (presets de C), barrières des lagons |
| `Feel` | FOV, vague, surf, curseur |
| `ChatStyle` | Habillage du chat |
| `StealHud` | Vol : alerte, flèche, maintien, RUN HOME, verrou, bouclier, revanche |
| `RoyalHud` | Marée Royale |
| `MountButton` | RIDE / GET OFF |
| `Shop` | Boutique de lancement |
| `Onboarding` | Intro des 30 s, flèche vers le lagon puis vers les tours |

## 7. Attendu des autres

- **C**, sons dans `Assets.Sounds` (ceux de build_sounds sont branchés). Il manque :
  - click, deny, purchase, whoosh (interface) ;
  - grow.
- **C**, autres éléments :
  - icônes `Assets.UI.Icons.*` (facultatif) et curseur `Assets.UI.Cursor` ;
  - image de chargement ;
  - `PlotN.Barrier` en Atomic, parties ancrées ;
  - choix du pack d'animations.
- **A** : `DisplayDistanceType = None`. Réponses attendues sur Mounted/Carried dans Display et sur les montures. Retirer les emojis de `Config.Upgrades` (champ `icon`).
- **E** : noms affichés des stades (le client affiche YOUNG au lieu de Baby ; les ids de Config ne changent pas).

## 8. Import de lundi (Rojo)

- **Nouveaux fichiers** :
  - `src/ReplicatedFirst/LoadingScreen.client.lua` ;
  - modules TideClient : Hud, Prompts, PoolBillboards, NameTags, World, Ambience, Feel, ChatStyle, StealHud, RoyalHud, MountButton, Shop, Onboarding.
- **Modifiés** : Store, Theme, Components, Notifications, Fx, init.client.lua (renommé depuis TideClient.client.lua).
- **À tester en priorité** sur téléphone (844×390) :
  - l'intro et l'écran de chargement ;
  - la lisibilité du bandeau et d'Oswald ;
  - le bouton STEAL et sa jauge au doigt ;
  - la boutique ;
  - le chat qui ne recouvre rien.
- **Mode démo** (Studio sans serveur) : il démarre seul. On le pilote avec `Players.LocalPlayer.TR_ClientDebug` (commandes listées dans Store).
