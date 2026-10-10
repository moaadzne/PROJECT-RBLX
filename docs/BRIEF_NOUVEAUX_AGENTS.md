# NOUVEAUX AGENTS SPÉCIALISÉS — 8 conversations à créer

Crée chacune dans un onglet OpenCode, renomme-la exactement comme indiqué, colle le brief correspondant, et connecte-la au repo (`/Users/admin/Documents/claude code/tide-rush`). Elles liront `AGENTS.md` et `docs/INBOX/<lettre>.md` au démarrage.

---

## G — MONETIZATION & SHOP
**Zone** : `src/ServerScriptService/Services/ShopService.lua`, `src/ReplicatedStorage/Shared/Config.lua` (Config.Shop), `src/StarterPlayer/StarterPlayerScripts/TideClient/Shop.lua`
**Mission unique** : Implémenter la monétisation top 10 validée dans `docs/DECISIONS_MARCHE.md`.
- Config.Shop : prix finaux (VIP 79, Speed 149, Bag 99, StarterPack 249, TideEgg 199, PickCreature 399)
- Bundle StarterPack (valeur perçue 327 → prix 249)
- Probabilités TideEgg affichées AVANT achat (Common 60%, Uncommon 25%, Rare 10%, Epic 4%, Legendary 1%)
- PolicyService avant tout achat Produit Développeur
- Rewarded Video Ads : 1 TideEgg gratuit/jour (cooldown 24h)
- Premium Payouts activé
- Game Pass < 100 Robux pour capture impulsion
- A/B test framework prêt pour semaine 2 (prix 79 vs 99 vs 129)
- IDs Creator Hub : attendus de Moaad (mettre 0 en attendant)

---

## H — ICONS, FONTS & VISUAL LANGUAGE
**Zone** : `src/StarterPlayer/StarterPlayerScripts/TideClient/Theme.lua`, `src/StarterPlayer/StarterPlayerScripts/TideClient/Components.lua`, `src/ReplicatedStorage/Assets` (nouveau dossier Fonts)
**Mission unique** : Système d'icônes "Font Awesome + fallback primitives" + police RobotoCondensed.
- Upload Font Awesome (SIL OFL) comme police famille dans Creator Hub
- Module `IconResolver.lua` : `resolve(name)` → renvoie Font Awesome si chargée, sinon primitive Roblox
- Primitives : cercle (coffre), vague (vague), bouclier (protection), étoile (rare), couronne (royal), flèche (vol)
- RobotoCondensed (Enum.Font.RobotoCondensed, Bold pour titres) partout
- Remplacer TOUS les emojis restants par `IconResolver("name")`
- Atlas d'icônes unique, chargé au démarrage, fallback silencieux

---

## I — CODEX & COLLECTION UI
**Zone** : `src/StarterPlayer/StarterPlayerScripts/TideClient/Codex.lua` (nouveau), `Components.lua`, `Theme.lua`
**Mission unique** : Codex semaine 1 — 3 connues + 4 mystère, progression visible, dopamine.
- 3 visibles : Ghost Crab (Common), Cushion Star (Common), Hawksbill Turtle (Uncommon, montable Elder+)
- 4 slots "? ? ? ?" avec silhouettes floues + couleur rareté (Rare/Epic/Legendary)
- Animation d'apparition : scale 0→1 avec bounce, son "pop" satisfaisant
- Compteur "X/10 découvertes" en haut, barre de progression
- Clic sur slot découvert → fiche détaillée (revenu, stade, mutation, zone)
- Clic sur slot mystère → tooltip "Découvre-le en jouant !" + particule
- Persistant : sauvegardé dans DataService, visible entre sessions

---

## J — RETENTION, QUESTS & SOCIAL SYSTEMS
**Zone** : `src/ServerScriptService/Services/QuestService.lua` (nouveau), `DailyRewardService.lua` (nouveau), `src/StarterPlayer/StarterPlayerScripts/TideClient/Quests.lua` (nouveau)
**Mission unique** : Rétention 7 jours, quêtes journalières, battle pass léger, social.
- **Daily Rewards** : Jour 1-7 pièces croissantes, Jour 7 = TideEgg gratuit (non échangeable)
- **Quêtes journalières** (3/jour, rotation) : "Attrape 5 créatures", "Vole 1 fois", "Surfe 1 vague", "Visite 3 lagons"
- **Battle Pass léger (semaine)** : 7 paliers, gratuit pour tous, premium = récompenses x2 (cosmétiques seulement)
- **Social/Trade** : Vol entre lagons = interaction positive (pas PvP toxique), revanche = bouclier 24h
- **Friend invite** : +500 pièces si ami rejoint et joue 10 min
- **Streak protection** : 1 jour de grâce par semaine si coupure

---

## K — VFX, CREATURE MODELS & ANIMATIONS
**Zone** : `src/ReplicatedStorage/Assets/Creatures` (nouveau), `src/StarterPlayer/StarterPlayerScripts/TideClient/CreatureRenderer.lua` (nouveau), `tools/world/`
**Mission unique** : Créatures visuellement cohérentes, animations Rthro, mutations visibles.
- **10 modèles** : GhostCrab, CushionStar, HawksbillTurtle, Lionfish, BlueRingedOctopus, LeopardRay, GiantPacificOctopus, LionsManeJelly, MantaRay, WhaleShark
- Style : low-poly stylisé, palette par rareté, silhouette lisible à 50 studs
- **Rthro Animation Package** (bundle 356) : idle, walk, swim, carry, mount, surf
- **Mutations visuelles** (shader/material, pas nouveau mesh) :
  - Golden : Material=Foil, ColorShift=Gold, Trail=Gold
  - Glow : PointLight + Bloom, Pulse 2s
  - Storm : ParticleEmitter=Sparkles, Color=Gray/Blue
  - Rainbow : ColorShift=HueRotate, Trail=Rainbow
- **Hero creatures** (Titan) : échelle 1.5, effets permanents, son unique
- Génération par `tools/world/build_creatures.luau` (reproductible)

---

## L — ONBOARDING, FIRST 30s & UX CLARITY
**Zone** : `src/StarterPlayer/StarterPlayerScripts/TideClient/Onboarding.lua`, `CameraIntro.lua` (nouveau), `src/StarterGui/ScreenGui`
**Mission unique** : Les 30 premières secondes = "Wow, c'est sur Roblox ça ?" + clarté totale.
- **0-1.5s** : Écran chargement custom (pas Roblox), plan aérien lent île au couchant, brume, lagon turquoise
- **1.5-7.6s** : Caméra s'ouvre sur le lagon du joueur, 4 créatures posées, il en attrape 2-3
- **7.6-16s** : Mouettes s'enfuient, ressac s'arrête → vague arrive, il court, il chope
- **16-29.6s** : Il place sa créature sur le bassin, barre s'ouvre, "NEXT TIDE: GOLDEN"
- **29.6-31.5s** : Vague s'écrase, embruns, une ligne : "TA BASE. TA CRÉATURE. TA VAGUE."
- **Zéro texte explicatif** : tout se comprend par l'image et l'action
- **Flèche unique** (pas de joystick visible) : "Va là" → il y va
- **Pas de HUD avant 31.5s** — seulement la flèche et la caméra

---

## M — LAUNCH, ROJO SYNC & QA CHECKLIST
**Zone** : `docs/IMPORT_LUNDI.md`, `default.project.json`, scripts de vérification
**Mission unique** : Lundi soir = zéro friction, zéro surprise, tout vérifié.
- **Checklist 20 points** (copier-coller dans Studio lundi) :
  1. Sauvegarde `.rbxl` + copie travail
  2. `git pull` branche `claude/e-gdd-reef`
  3. `rojo serve` → Connect → Accept
  4. Vérifier : ReplicatedStorage.Shared, ServerScriptService, StarterPlayerScripts identiques au repo
  5. Remotes v2.1 créées (StartSteal, ChoosePick, WaveFrontD, etc.)
  6. Wave.lua présent, P0 corrigé (base * CFrame)
  7. Store.lua = WaveFrontD, StartSteal, ChoosePick
  8. Config.Shop prix finaux (79/149/99/249/199/399)
  9. Theme.lua = RobotoCondensed + IconResolver
  10. Codex.lua 3 connues + 4 mystère
  11. QuestService + DailyRewardService chargés
  12. CreatureRenderer + 10 modèles chargés
  13. Onboarding 0-31.5s jouable
  14. SelfTest serveur = tout PASS
  15. Playtest 5 min : 0 erreur console, vague visible 4 directions, interface lisible
  16. Avatar R15 proportions identiques (min=max)
  17. Lighting = Future + Atmosphere + Bloom + ColorCorrection
  18. Assets._DecorLib présent (cabanes, palmiers, ponton)
  19. Sons waveBoom + ambientBeach dans Assets.Sounds
  20. Cmd + S → Save to Roblox
- **Rollback plan** : fermer sans sauvegarder → rouvrir sauvegarde → prévenir D

---

## N — VISUAL POLISH, LIGHTING & ART DIRECTION
**Zone** : `Workspace.Map`, `Lighting`, `ReplicatedStorage.Assets`, `MaterialService`, `SoundService`, `tools/world/`
**Mission unique** : Niveau visuel "Fortnite/Sea of Thieves stylisé" — pas blocs gris, pas placeholder.
- **Lighting** : Technology=Future, Atmosphere (Density=0.3, Haze=2, Glare=1), Bloom (Intensity=0.5), ColorCorrection (Saturation=1.1, Contrast=0.1)
- **Eau** : Color=#1a7aa6, Transparency=0.4, WaveSize=0.8, WaveSpeed=8
- **Lagon** : fond sable (#e8d5b7), barrière corail (Material=Corail, Color=#ff6b35), ponton bois
- **5 zones** : palettes distinctes (Crique turquoise, Dunes sable/or, Récif corail, Falaise gris/vert, Épave bleu nuit)
- **Créatures** : ombres projetées (ShadowMap), LOD distance
- **Vague** : houle 55 studs horizon, crête 30, tours à 34 (safe), spray particules
- **Sons** : waveBoom (impact), ambientBeach (ressac), footSand/footWater/footRock, caught (remplace oof)
- **Hero shot** : caméra (-112, 14, 78) → (-60, 3, -110), FOV 60, coucher soleil, lagon tiers gauche, phare tiers droit

---

## RÈGLES COMMUNES POUR LES 8

1. **Lis `AGENTS.md` et `docs/INBOX/<ta lettre>.md` au démarrage**
2. **Écris ton résultat dans `docs/INBOX/<ta lettre>.md`** (3 lignes : FAIT/VÉRIFIÉ/BESOIN)
3. **Ne touche qu'à ta zone** (tableau ci-dessus)
4. **Commit souvent, push souvent** sur `claude/e-gdd-reef`
4. **Budget** : quota épuisé, réinitialisation 12/10 21h — pas de test lourd
5. **Objectif** : niveau visé = capture montrée à Moaad, pas test technique

---

## COMMANDES POUR TOI (copie-colle)

```bash
# Dans chaque onglet OpenCode, après avoir renommé la session :
# 1. Va dans le repo
cd "/Users/admin/Documents/claude code/tide-rush"

# 2. Lis les règles
cat AGENTS.md

# 3. Lis ta boîte
cat docs/INBOX/G.md   # ou H, I, J, K, L, M, N

# 4. Commence le travail
```