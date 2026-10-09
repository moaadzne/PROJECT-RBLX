# Interface — Ride the Tsunami / Steal & Ride (B) · v2

Remplace la v1 (périmée : concept, règles et style ont changé le 09/10).
Références : `docs/GDD.md` v2, contrat `review/review_context.md` v2, `docs/BIBLE_QUALITE.md` §5–6.

## 1. Style : console, pas « Roblox par défaut »

- **Plaques** (`Theme.Plate`) : fond bleu nuit opaque en dégradé, contour sombre de 3 px, liseré de couleur en haut. Aucun panneau de verre gris.
- **Typo** : Luckiest Guy pour les titres et les chiffres, Builder Sans ExtraBold pour le texte, contour sombre de 2 px sur tout le texte.
- **Couleur + icône + nom**, toujours : rareté (badge à lettre), mutation (✨ Golden…), marée (🌊 / ✨ Golden Tide…), médailles (👑 #1).
- **Mobile d'abord** : écran de design 900×480 (téléphone à l'échelle 0,85), texte ≥ 17 px de design (≈ 14,5 px réels), boutons ≥ 58 px, actions au-dessus du bouton de saut.
- **Réduire les animations** : pas de secousse ni de rebond, durées plafonnées (`Util.Tween`), intro caméra sautée.

## 2. Écrans et référence visuelle (principe seulement, rien de copié)

| Écran | Module | Référence | Principe repris |
|---|---|---|---|
| HUD : pièces, revenu, marée | `Hud` | Fortnite (HUD de match) | Peu d'éléments, chiffres gros et contourés, tout est lisible en 0,5 s |
| Bandeau de marée + compte à rebours | `Hud` | Sea of Thieves (alerte de tempête) | Un seul bandeau en haut au centre, couleur = type d'événement, pulsation à 3 s seulement |
| Étiquette de bassin | `PoolBillboards` | Animal Crossing (étiquettes d'objets) | Carte compacte au-dessus de l'objet : nom, état et une barre, rien de plus |
| Intro des 30 s | `Onboarding` | Journey (ouverture) | Pas de texte, la caméra et une flèche au sol guident ; le HUD arrive après la première émotion |
| Alerte de vol + flèche | `StealHud` | Sea of Thieves (navire attaqué) | Alerte rouge en haut + flèche au bord de l'écran vers la menace |
| Maintien pour voler | `StealHud` | Fortnite (ouvrir un coffre) | Bouton à maintenir avec jauge, interrompu si on bouge |
| Marée Royale | `RoyalHud` | Mario Kart (classement en course) | Top 3 en direct et ma place, médailles or / argent / bronze |
| Boutique | `Shop` | Clash Royale (boutique) | Cartes à prix fixe, probabilités sur la carte avant l'achat, s'ouvre seulement sur demande |

## 3. Disposition (design 900×480)

```
┌──────────────────────────────────────────────────────────────┐
│ [🪙 1.25K ]          ┌ ✨ Golden Tide      0:23 ┐   [toasts] │
│ [+12/s]              └ Next wave in ▓▓▓▓░░░░░░ ┘   [toasts] │
│ [🛡 Shield 12:30]      [🚨 Someone is stealing…]  [toasts] │
│ [⚔ Revenge on X ]                                            │
│ [👑 Royal Tide  ]                                            │
│ [1 Moaad   1.2K ]                                            │
│                                           (🔒)(🐢)(🛒)       │
│ (joystick)                                Lock Ride Shop (⤴) │
└──────────────────────────────────────────────────────────────┘
```

## 4. Durées (bible §6)

| Animation | Durée |
|---|---|
| Survol / appui / ressort d'un bouton | 0,08 s / 0,3 s Back |
| Fondu du HUD après la 1re vague | 0,5 s |
| Ouverture de la boutique (échelle 0,9 → 1, flou de la caméra) | 0,25 s Back |
| Croissance d'une créature (rebond ×1,15) | 0,6 s |
| Lumière d'une marée (presets de C) | 2 s Sine |
| Barrière de lagon (descente / remontée) | 0,5 s / 0,45 s Back |
| Intro caméra (vue large → derrière le joueur) | 2,4 s, sautable au toucher |

## 5. Modules client (src/StarterPlayer/StarterPlayerScripts/TideClient)

| Module | Rôle |
|---|---|
| `init.client.lua` | Point d'entrée (LocalScript TideClient), charge les modules dans l'ordre |
| `Util`, `Settings`, `Sfx`, `Fx` | Plomberie gardée (signal, tweens, ressorts, sons, effets d'écran) |
| `Store` | État et remotes, contrat v2 ; **seul endroit** où vivent les hypothèses de contrat (§7) |
| `Theme`, `Components` | Style console, briques d'interface |
| `Notifications` | Toasts (3 max, priorités) ; messages gardés pendant que le HUD est caché |
| `Hud` | Porte-monnaie, marée, colonne d'états, boutons d'action, classement |
| `PoolBillboards` | Étiquettes des bassins (1 Hz) |
| `World` | Flottement des créatures, échelle du stade, look de mutation, intro des autres cachée |
| `Ambience` | Lumière des marées, barrières des lagons |
| `StealHud` | Vol : alerte, flèche, maintien, verrou, revanche, bouclier |
| `RoyalHud` | Marée Royale : classement, couronnes |
| `MountButton` | Monter / Descendre |
| `Shop` | Boutique de lancement |
| `Onboarding` | Intro des 30 s, puis la flèche vers les tours |

## 6. Ce que le client attend du monde (C)

- `Assets.FX.Mutations.<Mutation>` et `Assets.FX.TidePresets.<Tide>` : format de `tools/world/build_mutation_fx.luau`.
- `PlotN.Barrier` : ModelStreamingMode Atomic, parties ancrées ; la position construite est la position **fermée**.
- Sons dans `Assets.Sounds` : `click`, `whoosh`, `purchase`, `deny`, `siren`, `grow`, `alarm`, `barrierOpen`, `barrierClose`, `royalStart`. Un son absent est ignoré sans erreur.

## 7. Hypothèses à valider par A (forme provisoire, toutes dans `Store`)

- `state.policy = {paidRandomItemsRestricted}`. Sans ce champ, le client considère l'achat aléatoire restreint.
- `state.mounts = {uid…}`, `state.mount = uid | nil`, `state.protection = {active, endsAt}`.
- RF `LockLagoon()` ; attributs PlotN `LockedUntil` et `LockReadyAt`. `Open` est lu sur `PlotN.Barrier`, sinon sur `PlotN`.
- Notify `stolen {thief, species, mutation, text}` au début d'un vol ; `StealResult` à la fin. Notify `royalResult {rank, reward}`.
- `Config.Shop` (ids, prix, `tideEgg.odds`, `goldenChance`, `pick.species`) et RF `PickCreature(species)` appelé avant l'achat.
- Le serveur ne déplace jamais `PlotN.Barrier` : il ne change que `Open` et la collision.

## 8. Import de lundi (Rojo)

- **Nouveaux modules** : Hud, PoolBillboards, World, Ambience, StealHud, RoyalHud, MountButton, Shop, Onboarding.
- **Modifiés** : Store, Theme, Components, Notifications.
- **Renommé** : `TideClient.client.lua` → `init.client.lua`.
- **À tester en priorité** sur téléphone (844×390) :
  - l'intro des 30 s ;
  - la lisibilité du bandeau de marée ;
  - le maintien pour voler au doigt ;
  - la boutique (ne doit rien couper).
- **Mode démo** (Studio sans serveur) : il démarre seul. On le pilote avec `Players.LocalPlayer.TR_ClientDebug` (commandes listées dans Store).
