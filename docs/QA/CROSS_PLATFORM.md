# Cross-Platform Test — Obligatoire à CHAQUE sync

**Règle absolue : échec sur L'UN (mobile OU PC) = rollback complet immédiat.**
Pas de « ça marche sur PC, on ship ». Les deux plateformes sont P0.

---

## Devices de référence

| Plateforme | Device | Console |
|---|---|---|
| **Mobile A** | iPhone 12 | Roblox DevConsole + ` MetaBreakpointManager` |
| **Mobile B** | Android mid-2021 (ex. Galaxy A52) | Roblox DevConsole |
| **PC** | GTX 1060 / 16 Go RAM | Studio Output (Play Solo / Play avec clients) |

## Protocole

1. Lancer **PC et Mobile simultanément** sur le **même serveur** (Play → Start + joindre depuis mobile).
2. **5 minutes minimum** chacun = au moins 1 cycle vague complet (calme → alerte → vague → reflux).
3. Cocher les 10 points ci-dessous **pour chaque plateforme**.
4. Si un seul point échoue sur une seule plateforme → **ROLLBACK COMPLET** (voir ROLLBACK.md).

---

## Checklist 10 points

| # | Point | Mobile ☐ | PC ☐ | Critère PASS |
|---|---|---|---|---|
| 1 | **Mouvement fluide** | ☐ | ☐ | Joystick tactile responsive / WASD + Shift sprint. Pas de latence, pas de rubber-band, pas de glissade. |
| 2 | **Caméra** | ☐ | ☐ | Touch drag rotation + pinch zoom / clic droit drag + molette zoom. Pas d'inversion, pas de blocage, sens correct. |
| 3 | **Vol mobile↔PC** | ☐ | ☐ | `StartSteal(plot, slot)` (maintien 1 s), `ChoosePick(species)`, `Mount(uid/nil)`, `LockLagoon()` fonctionnent **identiques** des deux côtés. |
| 4 | **Boutique** | ☐ | ☐ | Prix affichés (79/149/99/249/199/399) ; **probabilités AVANT achat** (Tide Egg 60/25/10/4/1) ; `PolicyService:ArePaidRandomItemsRestricted()` appelé ; `ProcessReceipt` idempotent ; 0 erreur console. |
| 5 | **HUD lisible** | ☐ | ☐ | **Mobile** : piscines / boussole / alertes en **bas** d'écran (safe area), cibles tactile **≥ 44×44 pts**. **PC** : HUD **latéral**, tooltips hover. Textes lisibles (RobotoCondensed ≥ 12 pt). |
| 6 | **Trading / Vol protections** | ☐ | ☐ | Débutant (< 15 min OU < 4 créatures) ne peut ni voler ni être volé ; protection après vol (2 vagues) ; Revanche active ; Cap 3 vols/10 min → verrou ; Lock gratuit 1 vague + 4 cycles cooldown. |
| 7 | **Marée Royale** | ☐ | ☐ | `RoyalBoard` reçu des deux côtés ; top 3 = couronnes + pièces (5/3/2 min de revenu) ; créature royale Golden unique visible. |
| 8 | **Daily Rewards** | ☐ | ☐ | Réclamation journalière sur **un** device → visible **instantanément** sur l'autre (même serveur) ; streak conservé. |
| 9 | **Console** | ☐ | ☐ | **Mobile DevConsole** : 0 erreur, 0 warning du jeu. **PC Output** : 0 erreur, 0 warning du jeu. |
| 10 | **Performance** | ☐ | ☐ | **Mobile ≥ 30 FPS** stable (aucun drop < 20) ; **PC ≥ 60 FPS** stable. Mémoire mobile < 600 Mo / PC < 1 Go. |

---

## Notes

- **Pendant tout le test** : conserver l'Output/DevConsole ouvert et le surveiller, pas seulement cocher à l'aveugle.
- **Test vol croisé** : joueur A (mobile) vole joueur B (PC), puis inversement — vérifier les protections des deux côtés.
- **Test boutique** : ne pas faire d'achat réel (ids = 0), vérifier l'**affichage** (prix, probabilités, Pity counter) et le **refus** PolicyService simulé.
- **En cas d'échec** : arrêter les 2 sessions, **PAS de Cmd + S**, fermer Studio sans sauvegarder, rouvrir `TideRush_SAUVEGARDE_*.rbxl`, prévenir A + B + D.
