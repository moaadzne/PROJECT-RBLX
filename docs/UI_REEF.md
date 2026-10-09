# Plan d'interface — Reef Keepers (B)

Statut : **plan, pas d'implémentation** avant le « go » de D (GDD validé).
Les contenus exacts (espèces, prix, chiffres, noms) viendront de `docs/GDD.md` : ils sont notés `⟦GDD: …⟧`.
Les remotes nouveaux sont notés `⟦A: …⟧` : à demander à A via D, rien n'est supposé exister.

## 0. Règles communes

- **Unités** : px de design sur l'écran 900×480 (téléphone 844×390 → échelle 0,85, PC → 1,3 max, cf. `TideClient.client.lua`). Texte jamais sous `Theme.TextSize.Small` (17 → 14,5 px réels).
- **Zones de pouce (mobile)** : actions principales en bas à droite, joystick à gauche (rien d'interactif dans le quart bas-gauche), haut centre réservé à la marée.
- **Tailles tactiles** : 44 px minimum, 58 px pour les boutons du HUD.
- **Durées (bible §6)** : micro-retour 0,08–0,15 s ; transitions 0,2–0,35 s ; célébrations 0,6–1,2 s ; éclosion 2,5–3,5 s. Jamais `Linear` dans l'UI.
- **Réduire les animations** : pas de secousse, pas de rebond, durées plafonnées à 0,12 s (déjà dans `Util.Tween`), cérémonie d'éclosion raccourcie à 0,6 s (révélation directe).
- **Rareté** : toujours couleur + lettre (`Theme.RarityBadge`) + nom écrit (`Config.Rarities[r].label`).
- **Mutation** : même règle : couleur + icône + nom (Golden ✨ / Night 🌙 / Storm ⚡ — ⟦GDD: liste et couleurs⟧).
- **Éthique** : aucun compte à rebours lié à un achat, aucune popup forcée, aucun « dernière chance », pas de badge rouge sur la boutique. Les probabilités sont affichées **avant** l'achat d'un œuf.

## 1. HUD minimal

```
┌──────────────────────────────────────────────────────────────┐
│ [🪙 1.25K ]            ╭─ GOLDEN TIDE ─╮          [toasts ▸] │
│ [+12/s    ]            │ 🌊 0:23  ▓▓▓░ │          [toasts ▸] │
│ [🐠 3/5   ]            ╰───────────────╯                     │
│                                                              │
│                                                              │
│                                              (🏠)  (🐚)  (🛒)│
│ (joystick)                                   Home  Reef  Shop│
└──────────────────────────────────────────────────────────────┘
```

| Élément | Taille | Composant | Animation |
|---|---|---|---|
| Pièces | Pill 170×44 | `Components.Pill` + `Theme.CoinIcon` + `Components.Counter` | défilement 0,4 s, pop à la hausse |
| Revenu /s | Pill 170×36 (SubText) | `Counter` Suffix "/s" | idem |
| Filet (créatures portées / max) | Pill 130×36 | `Pill` + `CountBadge` | rebond 0,35 s Back à chaque capture |
| Marée | Glass 220×64, haut centre | `Glass` + `ProgressBar` | couleur de la marée ; pulsation rouge à 3 s (≤ 2 Hz) |
| Home / Reef / Shop | IconButton 58 | `Components.IconButton` | survol 1,05 / appui 0,92 / ressort |

- Le nom de la marée (`⟦GDD: Normal / Golden / Night / Storm⟧`) est écrit en clair + icône + couleur.
- Le bouton Home est grisé hors phase calme (`SetEnabled(false)`) ; tap = secousse + toast précis (« Home is ready in 12 s »).
- Codex et Rank sont **dans** le panneau Reef (onglets), pas sur le HUD : 3 boutons max.

## 2. Panneau du lagon (onglet « Lagoon »)

Panneau plein écran sur mobile (marges 16), 760×400 sur PC. Ouverture 0,25 s : échelle 0,9 → 1, fondu, `Back`, `BlurEffect` taille 12 dans `CurrentCamera`.

```
┌ Lagoon ─ Codex ─ Rank ──────────────────────────── [✕] ┐
│ Pools 4/6      Income +48/s      ⟦GDD: bonus lagon⟧    │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │ 🐢 R │ │ 🐠 C │ │ 🐡 E✨│ │ 🦑 U │ │  +   │ │ 🔒   │ │
│ │Turtle│ │Clown │ │Puffer│ │Squid │ │ Free │ │200🪙 │ │
│ │▓▓▓░ A│ │▓░░░ B│ │▓▓▓▓ G│ │▓▓░░ J│ │      │ │      │ │
│ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │
│                         [ Collect all ⟦GDD?⟧ ]          │
└─────────────────────────────────────────────────────────┘
```

- Carte bassin 110×140 : `Theme.ItemIcon`-like (nouvelle `Theme.CreatureIcon`, même logique que `ItemIcon`), barre de croissance `ProgressBar` 90×10, lettre de stade (B bébé / J jeune / A adulte / G géant — ⟦GDD: stades⟧).
- Bassin verrouillé : prix en pièces ; si pas assez : bouton gris + « Need 165 more coins ».
- Grille : `UIGridLayout` dans un `ScrollingFrame` (6 colonnes PC, 4 mobile).
- Tap sur une carte → fiche créature (§4).

## 3. Reef Codex (onglet « Codex »)

```
┌ Lagoon ─ Codex ─ Rank ──────────────────────────── [✕] ┐
│ 23 / ⟦GDD: total⟧ discovered      [All ▾] [Normal ✨ 🌙 ⚡]│
│ ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐        │
│ │🐢 R││🐠 C││ ?  ││🐡 E││ ?  ││ ?  ││🦀 U││ ?  │        │
│ └────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘        │
│ Reward at 25: ⟦GDD: récompense de palier⟧  ▓▓▓▓▓▓▓░░    │
└─────────────────────────────────────────────────────────┘
```

- Case 72×72. Non découverte : silhouette grise + « ? », **mais** rareté visible (couleur + lettre) pour donner un but, sans fausse rareté.
- Filtre de mutation : 4 pastilles (Normal + 3 mutations), chacune icône + nom.
- Nouvelle entrée : pop 0,35 s Back + confettis légers (`Fx.Confetti`, ×1/3 en réduire les animations).
- Source des données : `state.collection` aujourd'hui ⟦A: format codex espèce × mutation⟧.

## 4. Fiche créature

Panneau 420×300 centré (plein écran mobile).

```
┌──────────────────────────────────────────────┐
│ [ViewportFrame 160×160]   Sea Turtle          │
│   (créature qui tourne)   [R] Rare            │
│                           [🌙] Night mutation │
│ Growth  ▓▓▓▓▓▓░░░░  Adult → Giant in 2h 10m   │
│ Income  +12/s  (Giant: +30/s)                 │
│ [ Move ]   [ Release for 150🪙 ⟦GDD?⟧ ]        │
└──────────────────────────────────────────────┘
```

- `ViewportFrame` : 1 seul à la fois, rotation 20°/s via `RenderStepped` **seulement quand la fiche est ouverte** (connexion dans un `Util.Maid`, nettoyée à la fermeture).
- Temps de croissance : texte informatif, calculé côté client depuis un horodatage serveur ⟦A: `bornAt`/`growth` dans le state⟧. Ce n'est **pas** un compte à rebours d'achat : aucun bouton payant à côté.
- Le gamepass x2 croissance, s'il existe, ne s'affiche **que** dans la boutique.
- Relâcher : confirmation en 2 temps (le bouton devient « Sure? » 3 s), jamais de popup modale.

## 5. Cérémonie d'éclosion

Œufs payés **en pièces uniquement**. Écran d'achat d'abord, cérémonie ensuite.

**Écran d'achat** (`Components.Card` 220×300 par œuf) :
```
┌──────────────┐
│     🥚       │
│  Reef Egg    │
│ C  Common 60%│
│ U  Uncomm 30%│
│ R  Rare    9%│
│ E  Epic    1%│
│ [ 500 🪙 ]   │
└──────────────┘
```
- Table de probabilités **complète** sur la carte (rareté couleur + lettre + nom + %), ⟦GDD: œufs, prix, tables⟧, lue depuis `Config.Eggs` (pas de chiffres en dur côté client).
- Probabilités des mutations affichées aussi si elles s'appliquent à l'éclosion ⟦GDD⟧.

**Cérémonie** (`TideOverlay`, plein écran) — total 3,0 s, 1,2 s quand on enchaîne, 0,6 s en réduire les animations :

| t (s) | Image | Son |
|---|---|---|
| 0,00–0,25 | fond assombri (fondu 0,6), œuf monte d'échelle 0,6 → 1 (Back) | whoosh |
| 0,25–1,80 | tremblements croissants (rotation ±4° → ±12°, période 0,18 → 0,08 s) ; **pas** de couleur de rareté avant la révélation | tic-tic accéléré |
| 1,80–2,20 | fissures (3 images), léger zoom 1 → 1,1 | crack |
| 2,20–2,40 | éclat de lumière : `Fx.Flash` blanc 0,6, une seule fois | pop |
| 2,40–3,00 | créature apparaît (ViewportFrame) dans la couleur de rareté ; nom + badge rareté + mutation + bonus | jingle selon rareté |
| 3,00+ | boutons **[Equip]** (vert, mis en avant) et **[Again 500🪙]** ; tap n'importe où = fermer | — |

- Aucune animation de « presque » (pas de faux suspense qui montre une rareté supérieure avant d'atterrir sur la vraie).
- Le résultat vient du serveur (`HatchEgg` → `(true, petId, uid)` + Notify `hatch`), la cérémonie démarre **après** la réponse : jamais de résultat client.

## 6. Boutique à prix fixe

Panneau à onglets : **Coins** (œufs, bassins, filet) / **Robux** (gamepasses, cosmétiques) — ⟦GDD: liste exacte et prix⟧.

```
┌ Shop ─ [Coins] [Robux] ───────────────────────── [✕] ┐
│ ┌────────────┐ ┌────────────┐ ┌────────────┐        │
│ │ 🌱 x2 Grow │ │ 🪸 Coral   │ │ 🕸️ Big Net │        │
│ │ Creatures  │ │ Lights     │ │ +2 catch   │        │
│ │ grow 2×    │ │ Decoration │ │ radius     │        │
│ │ [ 199 R$ ] │ │ [ 49 R$ ]  │ │ [ 99 R$ ]  │        │
│ └────────────┘ └────────────┘ └────────────┘        │
│ Everything here is optional. ⟦texte à valider⟧        │
└──────────────────────────────────────────────────────┘
```

- `Components.Card` + `MarketplaceService:PromptGamePassPurchase` / `PromptProductPurchase` (A valide côté serveur).
- Prix fixe, description exacte de ce qu'on obtient, déjà possédé = « Owned » grisé.
- Interdits : prix barrés fictifs, « offre limitée », minuteur, badge rouge, ouverture automatique de la boutique, vente de pièces contre Robux, tirage payant.

## 7. Onboarding — 60 premières secondes

Pas de tutoriel bloquant ; flèches et un texte court à la fois (`Notifications.Push` priorité info + une flèche 3D `Beam` dans le monde).

| t | Étape | UI |
|---|---|---|
| 0–5 s | Arrivée : caméra d'arrivée sur la plage (2 s, sautable), puis HUD en fondu 0,3 s | « Catch creatures before the wave! » |
| 5–25 s | Première créature à < 15 studs, flèche au sol | capture : pop, icône qui vole vers le filet (`Fx.FlyTo` 0,5 s) |
| 25–40 s | Flèche vers le lagon | « Bring them home to your lagoon » |
| 40–50 s | Dépôt : la créature vole vers un bassin, « +2/s » flotte | `Counter` défile |
| 50–60 s | Marée calme : la barre de marée pulse 1 fois | « The tide comes back every minute. Stay high! » |

- Chaque étape se valide par l'action, pas par un bouton « Next ». Sauvegarde côté serveur ⟦A: flag `tutorialDone`⟧.
- Le premier œuf est offert ou très bon marché ⟦GDD⟧ : jamais une proposition Robux pendant l'onboarding.

## 8. Réutilisation

| Existant | Réutilisé pour |
|---|---|
| `Theme` (couleurs, polices, Button, RarityBadge, CoinIcon, ScaledRoot) | tout ; ajout `Theme.CreatureIcon`, `Theme.MutationBadge` |
| `Components.Glass/Pill/Counter/ProgressBar/IconButton/Card/CountBadge` | HUD, bassins, codex, boutique, œufs |
| `Notifications` (3 max, priorités, file sans doublon) | onboarding, captures, éclosions |
| `Fx` (Flash, Fade, Confetti, FlyTo, EdgeGlow, Shake) | capture, dépôt, éclosion, vague |
| `Store` (snapshot normalisé, invoke protégé, mode démo) | ajout des champs créatures ⟦A⟧ + raccourcis `HatchEgg`, `EquipPet` |
| `Settings` (reducedMotion, graphics, uiScale) | menu Réglages (à créer : 4 options, accessible depuis Reef) |

**À créer** : `Panel` générique (ouverture/fermeture + flou + Maid), écrans `Hud`, `Reef` (Lagoon/Codex/Rank), `CreatureSheet`, `Hatch`, `Shop`, `Onboarding`, `SettingsMenu`.

## 9. Demandes à A (via D)

- Champs du state : créatures (`uid, species, mutation, stage, bornAt, pool`), pools (`unlocked, max`), codex (espèce × mutation), `tutorialDone`.
- Notify : `capture {species, mutation, rarity, position, isNew}`, `grown {uid, stage}`, `codex {species, mutation}`.
- Remotes : déplacer/relâcher une créature, acheter un bassin.
- Les probabilités d'œufs (et de mutations) dans `Config`, lues par le client.
