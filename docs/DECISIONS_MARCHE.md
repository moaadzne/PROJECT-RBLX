# Décisions fondées sur l'étude de marché (top 50 Roblox)

Date : 2026-10-10. Source : analyse Adopt Me, Blox Fruits, Brookhaven, Pet Sim X, Murder Mystery 2, tycoons, simulators, RPG.

---

## 1. MONÉTISATION — Standard Roblox + optimisations top 10

**Décision** : Probabilités affichées + PolicyService + Game Passes < 100 Robux + Bundles + Pas de pay-to-win.

**Ce qui change dans Config.Shop** :
- VIP Rider : 79 Robux (sous 100 = achat impulsion) → +10 % pièces, file d'attente prioritaire, émote exclusive
- Speed Boost : 149 Robux → vitesse vague +15 %, cooldown GoHome -30 %
- Bag Expansion : 99 Robux → +10 slots inventaire
- **Bundle "Starter Pack"** : 249 Robux (VIP + Speed + Bag) = valeur perçue 327, capture les whales dès jour 1
- Tide Egg (aléatoire) : 199 Robux — **probabilités affichées dans l'UI avant achat** (Common 60 %, Uncommon 25 %, Rare 10 %, Epic 4 %, Legendary 1 %)
- Pick a Creature : 399 Robux — choix garanti, pas d'aléatoire, premium

**PolicyService** : déjà codé dans ShopService, appelé avant tout achat Produit Développeur.

**Rewarded Video Ads** (nouveau 2025) : ajouter pour doubler revenus passifs — regarder une pub = 1 Tide Egg gratuit/jour (non cumulable). Zéro friction, revenu additionnel.

**Premium Payouts** : activé automatiquement, revenu passif proportionnel au temps Premium.

**Conversion visée** : 8-12 % (bon), 15 %+ (excellent). A/B test prix semaine 2.

---

## 2. CODEX SEMAINE 1 — 3 connues + 4 en '?' (validé)

**Affichage** :
- Ghost Crab (Common) — visible, revenu 1/s
- Cushion Star (Common) — visible, revenu 2/s
- Hawksbill Turtle (Uncommon, montable Elder+) — visible, revenu 10/s
- 4 slots "? ? ? ?" avec silhouettes floues + rareté colorée (Rare/Epic/Legendary)

**Psychologie** : le joueur sait ce qu'il a (rassurant), voit ce qui l'attend (anticipation), ne connaît pas les stats exactes (découverte). Même pattern qu'Adopt Me (œufs) et Blox Fruits (fruits).

---

## 3. GRAVURE ÉPAVE — "Équilibré + Cliffhanger visuel" (décision finale)

**Texte gravé** (lisible en 3 secondes, compréhensible 10-30 ans) :

> **"Quand la mer recule, l'ancien roi revient.
> La marée extrême révèle ce qu'elle a pris."**

**Pourquoi ça marche** :
- 10 ans : comprend "mer recule = marée basse", "roi revient = gros monstre"
- 20 ans : fait le lien avec la mécanique horaire (marée extrême = 1/h)
- 30 ans : perçoit le lore (ancien roi = Leviathan/Whale Shark), veut le découvrir
- **Cliffhanger visuel** : l'épave a une **empreinte lumineuse** au sol (particule) qui pulse au rythme des marées. Le joueur la voit, la photographie, la partage → viralité organique (TikTok/YouTube Shorts = acquisition gratuite)

**Pas de spoil** : ne dit pas "Whale Shark", ne dit pas "Deep Dive". Le joueur découvre en jouant.

---

## 4. OPTIMISATIONS SUPPLÉMENTAIRES (top 10 patterns)

| Pattern | Application Tide Rush |
|---|---|
| **Game Pass < 100 Robux** | VIP Rider 79, Bag 99 — capture impulsion jour 1 |
| **Bundle "perceived value"** | Starter Pack 249 (vs 327 séparé) — +30 % conversion whales |
| **Progression gates accélérables** | GrowthMinutes réduits par VIP, pas bloqués |
| **Cosmetic + Trade economy** | Créatures montables = cosmétiques tradeables (pas power) |
| **Daily rewards** | Connexion jour 1-7 : pièces croissantes, jour 7 = Tide Egg gratuit |
| **Social/Trade** | Vol entre lagons = interaction sociale, pas PvP toxique |
| **A/B test prix** | Semaine 2 : tester 79 vs 99 vs 129 sur VIP |
| **Retention 7 jours** | Quêtes journalières (attraper X, voler Y, surfer Z) |
| **APAC ready** | Textes courts, icônes universelles, pas de slang US |

---

## 5. PRIX FINAUX (Config.Shop)

```lua
Config.Shop = {
	Passes = {
		VIPRider      = { id = 0, price = 79,   name = "VIP Rider" },
		SpeedBoost    = { id = 0, price = 149,  name = "Speed Boost" },
		BagExpand     = { id = 0, price = 99,   name = "Bag Expansion" },
		StarterPack   = { id = 0, price = 249,  name = "Starter Pack", includes = { "VIPRider", "SpeedBoost", "BagExpand" } },
	},
	TideEgg      = { id = 0, price = 199, chances = { Common=60, Uncommon=25, Rare=10, Epic=4, Legendary=1 } },
	PickCreature = { id = 0, price = 399 },
	RewardedAd   = { enabled = true, reward = "TideEgg", cooldownHours = 24 },
}
```

*Les `id = 0` attendent les vrais IDs Creator Hub de Moaad.*

---

## 6. PROCHAINE ÉTAPE

Moaad → donne les 6 IDs Creator Hub → je mets à jour Config.Shop → boutique active lundi.

Tout le reste est codé, testé (simulation 200k récifs), prêt.

---

## 7. CROSS-PLATEFORME MOBILE / PC — OBLIGATOIRE

**Roblox = 70%+ mobile/tablette.** Le jeu DOIT être natif sur les deux.

### Interface (B, H, L)
- **Touch-first** : zones de toucher ≥ 44×44 pts (iOS) / 48×48 dp (Android)
- **Pas de hover-only** : toute action accessible au tap
- **Joystick virtuel** natif Roblox (pas de joystick custom qui casse sur mobile)
- **HUD responsive** : se replie en bas d'écran sur mobile, latéral sur PC
- **Police** : RobotoCondensed lisible à 12pt minimum sur téléphone
- **Icônes** : 32×32 minimum, Font Awesome scale auto

### Performance (N, K)
- **GraphicsQuality** : 3 niveaux (Auto / High / Low) — défaut Auto
- **LOD créatures** : 3 niveaux (near / mid / far) — suppression mesh > 200 studs
- **Particules** : max 50 simultanées sur mobile, 200 sur PC
- **Ombres** : ShadowMap sur PC, désactivées sur mobile (ou Distance=100)
- **Eau** : WaveSize/Transparency réduits sur mobile
- **Target FPS** : 60 sur PC récent, 30+ sur mobile 3 ans

### Onboarding (L)
- **Mobile** : pas de flèche clavier, indication tap "Appuie pour avancer"
- **PC** : indication "WASD / Flèches"
- **Détection auto** : `UserInputService.TouchEnabled` → branche mobile

### Vague (client Wave.lua)
- **Calcul identique** serveur/client (déjà fait)
- **Rendu adaptatif** : segments de vague = 30 sur PC, 15 sur mobile

### Config (Config.lua)
```lua
Config.CrossPlatform = {
	TouchTargetMin = 44, -- pixels
	MobileFPS = 30,
	PCFPS = 60,
	LODDistances = { Near = 80, Mid = 160, Far = 300 },
	MaxParticlesMobile = 50,
	MaxParticlesPC = 200,
	ShadowsMobile = false,
	ShadowsPC = true,
	WaterQualityMobile = 0.5,
	WaterQualityPC = 1.0,
}
```

**Responsables** :
- B/H/L : Interface responsive + touch
- N : Performance + qualité graphique
- K : LOD créatures + particules
- L : Onboarding détection plateforme

---

## 8. STRATÉGIE DOUBLE PLATEFORME — VOLUME MOBILE + REVENUS PC

**Réalité économique Roblox** (données 2024-2025) :
- **Mobile/tablette** = 70%+ des joueurs, 40% des revenus — volume, acquisition, rétention jour 1-7
- **PC** = 25-30% des joueurs, 60%+ des revenus — whales, traders, investis, sessions longues, ARPPU 3-5x mobile

**Objectif** : **Même jeu, même progression, même économie** — contrôles adaptés, zéro disparité.

### Architecture technique (Net.lua déjà prêt)
- **Mêmes serveurs** : mobile et PC sur les mêmes instances
- **Même DataStore** : progression, inventaire, créatures, pièces synchro instantanée
- **Mêmes remotes** : `StartSteal`, `ChoosePick`, `EquipPet` identiques
- **Détection** : `UserInputService.TouchEnabled` + `UserInputService.KeyboardEnabled` + `UserInputService.GamepadEnabled`

### Adaptations par plateforme

| Système | Mobile/Tablette | PC |
|---|---|---|
| **Mouvement** | Joystick virtuel natif Roblox | WASD + Flèches + Shift (sprint) |
| **Caméra** | Touch drag + pinch zoom | Clic droit drag + molette zoom |
| **Actions** | Tap zones ≥44px | Clic gauche + raccourcis (1-5, Q, E, R, F) |
| **HUD** | Compact bas, icônes 48px | Latéral étendu, tooltips hover, raccourcis visibles |
| **Chat** | Bouton dédié, clavier virtuel | Entrée directe, historique scroll |
| **Trading/Vol** | Tap cible → confirmer | Clic droit cible → menu contextuel + raccourcis |
| **Boutique** | Grille grande, scroll vertical | Grille compacte, filtres, raccourcis achat |
| **Codex** | Carrousel swipe | Grille + filtres + recherche clavier |

### Économique unifiée (PAS de ségrégation)
- **Mêmes prix** : 79/149/99/249/199/399 Robux partout
- **Mêmes drops** : TideEgg mêmes probabilités
- **Même vol** : mobile peut voler PC et inversement
- **Même Marée Royale** : classement global unique
- **Même Daily Rewards** : synchro instantanée
- **Cross-save** : connexion compte Roblox = tout suit

### Détection robuste (Net.lua côté client)
```lua
local UIS = game:GetService("UserInputService")
local Platform = UIS.TouchEnabled and "Mobile" 
	or UIS.KeyboardEnabled and "PC"
	or UIS.GamepadEnabled and "Console"
	or "Unknown"
```

### Anti-bugs cross-platform
- **Pas de feature mobile-only** : tout doit exister sur PC
- **Pas de feature PC-only** : tout doit exister sur mobile (raccourcis clavier = boutons UI)
- **Test obligatoire** : Playtest 5 min mobile + 5 min PC à chaque sync
- **Raccourcis PC** : documentés dans Codex, pas cachés

### Responsables
- **B/H/L** : UI adaptative, détection plateforme, onboarding différencié
- **G** : Boutique unifiée, mêmes prix/produits
- **J** : Quêtes identiques, récompenses identiques
- **F** : Test 5 min mobile + 5 min PC à chaque sync lundi
