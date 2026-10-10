# Cross-Platform Matrix — Support mobile ↔ PC

**Règle absolue : échec sur L'UN (mobile OU PC) = rollback complet.**
**Même jeu, même économie, même progression — contrôles adaptés, zéro disparité.**

---

## Matrice devices

| # | Plateforme | Device | OS | Spécs | Priorité |
|---|---|---|---|---|---|
| 1 | Mobile iOS | iPhone 12 | iOS 16+ | low/mid/high | P1 |
| 2 | Mobile iOS | iPad (9th gen+) | iPadOS 16+ | mid | P2 |
| 3 | Mobile Android | Galaxy A52 (mid-2021) | Android 12+ | mid | P1 |
| 4 | Mobile Android | Entrée de gamme (2 Go RAM) | Android 10+ | **low** | P1 (volume) |
| 5 | Mobile Android | Haut de gamme | Android 13+ | high | P2 |
| 6 | PC Windows | i5 + GTX 1060 | Win10/11 | high | P1 |
| 7 | PC Windows | i3 intégré | Win10/11 | **low** | P1 (volume) |
| 8 | PC macOS | MacBook Air M1 | macOS 13+ | high | P1 |
| 9 | PC macOS | MacBook Pro M2/M3 | macOS 13+ | high | P2 |
| 10 | Console | Manette | — | — | P3 (plus tard) |

---

## Contrôles par plateforme

| Système | Mobile | PC |
|---|---|---|
| **Mouvement** | Joystick virtuel natif | WASD + Flèches + Shift (sprint) |
| **Caméra** | Touch drag + pinch zoom | Clic droit drag + molette zoom |
| **Actions** | Tap zones ≥ 44 pts | Clic gauche + raccourcis 1-5, Q, E, R, F |
| **HUD** | Compact **bas**, icônes 48 pts, safe area | **Latéral** étendu, tooltips hover, raccourcis visibles |
| **Chat** | Bouton dédié + clavier virtuel | Entrée directe, historique scroll |
| **Trading / Vol** | Tap cible → confirmer | Clic droit cible → menu contextuel + raccourcis |
| **Boutique** | Grille large, scroll vertical | Grille compacte, filtres, raccourcis achat |
| **Codex** | Carrousel swipe | Grille + filtres + recherche clavier |
| **Onboarding** | Indication tap « Appuie pour avancer » | Indication « WASD / Flèches » |

---

## Détection plateforme

```lua
local UIS = game:GetService("UserInputService")
local Platform = UIS.TouchEnabled and "Mobile"
	or UIS.KeyboardEnabled and "PC"
	or UIS.GamepadEnabled and "Console"
	or "Unknown"
```

**règles** :
- Toute action accessible au **tap** (pas de hover-only).
- Tout raccourci PC = **aussi** un bouton UI (pas de feature PC-only).
- Tout bouton UI = **aussi** tactile (pas de feature mobile-only).

---

## Vérifications par item

| # | Vérification | Tous devices | Critère |
|---|---|---|---|
| 1 | Démarrage | ☐ | < 5 s cold, < 2 s warm |
| 2 | Mouvement | ☐ | Fluide, pas de rubber-band |
| 3 | Caméra | ☐ | Rotation + zoom corrects |
| 4 | HUD lisible | ☐ | Lisibilité + zones tactiles |
| 5 | Boutique | ☐ | Prix + probabilités affichés |
| 6 | Vol | ☐ | Fonctionne depuis/vers les autres devices |
| 7 | Boss / donjon / raid | ☐ | Mécaniques jouables |
| 8 | Sauvegarde | ☐ | Cross-save synchronisé |
| 9 | Performance | ☐ | Mobile ≥ 30 FPS / PC ≥ 60 FPS |
| 10 | Mémoire | ☐ | Mobile < 500 Mo / PC < 800 Mo |

---

## Test sync croisée

1. Compte A (mobile) et compte B (PC) **se connectent au même serveur**.
2. A vole B, puis B vole A → protections identiques.
3. A achète un cosmétique → visible sur B (cross-save).
4. A réclame Daily Reward → visible instantanément sur B.
5. Marée Royale : classement global identique.

---

## Notes

- Le **volume** est surtout mobile → priorités P1 sur Android low/mid et iPhone 12.
- Le **revenu** est surtout PC (ARPPU 3-5×) → tester les parcours d'achat PC en priorité.
- Les captures de test vont à D, jamais à Moaad sans validation.
