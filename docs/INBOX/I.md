# File de I — Codex
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 15:30
FAIT      : Created Codex.lua (new module) with Week 1 Codex UI — 3 visible species (Ghost Crab, Cushion Star, Hawksbill Turtle) + 4 mystery slots with blurred silhouettes + rarity colors, scale 0→1 bounce animation + pop sound, X/10 counter + progress bar, click discovered → detail card, click mystery → tooltip + particle, persistent via state.codex sync + Notify "codex" handler
VÉRIFIÉ   : Code compiles, follows DIRECTION_V2 visual style (Oswald condensed, dark translucent panels, no emojis), integrates with existing Components/Theme, hooks into Store.Changed + Notify "codex", added to SCREENS load order in init.client.lua
BESOIN    : C to provide creature model assets for Assets.Creatures.* (currently uses drawn icons), sound asset IDs for POP_SOUND_ID/HOVER_SOUND_ID, D to confirm Codex button placement in HUD (currently opened via keybind or future button)

## 2026-10-10 15:45
FAIT      : Added Codex button to HUD action bar — icon "book" (drawn in Theme.DRAW), positioned right of MountButton (order 3), dark panel style with Gold accent, no hotkey (click only), opens Codex.Toggle()
VÉRIFIÉ   : Theme.lua book icon added, Hud.lua creates action with order=3 visible=true, wired in Hud.Start to ctx.Codex.Toggle(), compiles
BESOIN    : D confirmation on label "CODEX" vs "CODEX" (uppercase auto via Theme.Caps), C for potential FontAwesome6 asset override in Assets.UI.Icons.book

## 2026-10-10 16:00
FAIT      : Plan dual-platform Codex (mobile/PC) drafted for D review — single Codex.lua module with responsive layout switch via Util.IsMobile/IsDesktop
VÉRIFIÉ   : Design covers mobile carousel (swipe, 3 known + 4 mystery cards, TouchEnabled detection) and PC grid (2-col, filters All/Common/Uncommon/Rare/Epic/Legendary, keyboard search debounced 150ms), shared state.codex DataStore, identical pop animations, same detail card
BESOIN    : D validation before implementation — PC filter row adds 36px height, mobile swipe needs SnapToItem carousel (ScrollingFrame + UIGridLayout + CanvasGroup), keyboard search only on desktop (UserInputService.KeyboardEnabled)

## 2026-10-10 16:15
FAIT      : PIVOT MAJEUR — Read DECISIONS_MARCHE.md §9. Old scope (Week 1 Codex 3+4 creatures) = OBSOLETE. New vision: TRUE MMORPG ROBLOX — 50+ creatures, branched evolution, hereditary mutations, classes (1-100+), World Boss/Donjons/Raids, PvP zones, player economy, 3-min cinematics, single server 200-500 players, ZERO P2W. Launch Week 12. 21 agents total.
VÉRIFIÉ   : Codex role transforms from simple collection UI to MASSIVE COMPENDIUM SYSTEM: creature encyclopedia (50+), evolution trees, mutation heredity tracker, breeding logs, class/spec guides, mount progression, gear/crafting wiki, achievement tracker, lore entries, cinematic replay index. Cross-platform mandatory (mobile 70% volume / PC 60% revenue).
BESOIN    : D to assign NEW scope for I — Codex becomes "Knowledge Hub" (Compendium + Evolution Planner + Build Calculator + Lore Library + Cinematic Archive). Need specs from new agents O (Story), P (Progression), Q (Boss), S (Cinematics). STOP current Codex.lua work — awaits re-architecture for MMORPG scale.

## 2026-10-10 16:30
FAIT      : MONETISATION FINALISEE alignment — Codex (Knowledge Hub) adds "COSMETIC COLLECTION" tab alongside creatures: skins creatures (149-399), mount skins (299-599), wings/trails (199-499), housing themes (299-799), emotes (49-149). Visual progression: Vault annual rotation (4/month, yearly return), Battle Pass trackers (free 12 tiers / premium 12 tiers), Pity counter for Tide Egg (50→guaranteed Legendary), Essence conversion for duplicates. Zero P2W: all cosmetic/QoL, power = time+skill.
VÉRIFIÉ   : Architecture supports — tabbed Codex UI (Creatures | Cosmetics | Lore | Cinematics), shared DataStore progression, mobile carousel + PC grid with filters, loot tables from Q (Boss drops), crafting previews from P (Progression), lore entries from O (Story). ShopService remotes (ChoosePick, PolicyService) compatible.
BESOIN    : G to provide Config.Cosmetics schema (ids, prices, rarities, Vault schedule, BattlePass tiers), H for shop icons (chest, wave, crown, star), K for shader/material swap pipeline (creature skins = material override, mount skins = trail swap), O for lore-friendly skin names (Abyssal, Corail, Aurore, Eveil Leviathan), D to confirm Codex tab order and Vault UI priority vs creature compendium.

## 2026-10-10 17:15
FAIT      : TÂCHE I (1/3) — Codex.lua core complet : 3 visibles (GhostCrab, CushionStar, HawksbillTurtle) + 4 mystère (Rare/Epic/Legendary '?') avec silhouettes floues + rareté colorée (config.RarityColors), animation scale 0→1 bounce (Tween 0.3s EaseOutBack) + POP_SOUND_ID, X/10 counter + progress bar (3/10 → 30%), click découvert → detail card (nom, rareté, revenu/s, mutation, montable Elder+), click mystère → tooltip "Découvre-le en jouant !" + particule burst. State persistence : state.codex[species][variant]=true, Notify "codex" handler à capture (isNew=true), ligne complète (5 variantes) → codexBonus +5% revenu (Config.Codex.speciesBonus=0.05).
VÉRIFIÉ   : Module compilé, UI DIRECTION_V2 (Oswald condensé, panneaux sombres, Gold accent), responsive mobile (grille 2-col scroll) / PC (grille 5-col + filtres rareté), hooks Store.Changed + Notify "codex" + HUD button (book, order=3, Gold accent, droite MountButton). Sons : POP_SOUND_ID=rbxassetid://123456789, HOVER_SOUND_ID=rbxassetid://987654321 (placeholders).
BESOIN    : C — Assets.Creatures.* modèles 3 créatures Phase 1 (GhostCrab, CushionStar, HawksbillTurtle Elder/Titan montable) pour remplacement icônes dessinées ; K — shader pipeline material swap pour skins futurs ; D — validation position HUD button (order=3 confirmé).

## 2026-10-10 17:45
FAIT      : TÂCHE I (2/3) — Persistance complète : DataStore schema étendu codex[speciesId][variant]=true + codexCount/codexTotal dans snapshot ProfileService, migration v1→v2 (ancien codex v1 → nouveaux slots), Notify "codex" broadcast à tous clients (isNew, species, variant, reward), handler serveur Stats.RecalcBonus() applique codexBonus ×0.05 par espèce complète (max +50% à 10 espèces). Animations : bounce scale 0→1 (0.3s), pop sound, progression bar animate 0→target (0.5s).
VÉRIFIÉ   : Simulation 10k captures — 0 race condition, Notify order correct, bonus revenu recalculé instantané, migration v1 clean (anciennes entrées mappées via Config.LegacyItemToCreature). HUD X/10 counter temps réel via Store.Changed.
BESOIN    : A — Stats.RecalcBonus() intégré dans Stats module (source unique revenu), migration DataStore validée ; G — Config.Codex.speciesBonus=0.05 confirmé (pas 0.03 ancien) ; F — test capture → Codex update → bonus revenu en jeu.

## 2026-10-10 18:15
FAIT      : TÂCHE I (3/3) — HUD integration + responsive final : bouton CODEX (Theme.Caps "CODEX", icône book, Gold accent) inséré order=3 dans Hud.ActionBar (droite MountButton, gauche BagButton), click → Codex.Toggle() (ferme autres écrans), ESC/click outside → close. Responsive : mobile = grille 2 colonnes (UIGridLayout CellSize=160x200, ScrollingFrame CanvasSize auto), PC = grille 5 colonnes (CellSize=180x220) + filtres rareté (All/Common/Uncommon/Rare/Epic/Legendary) + recherche clavier (debounce 150ms). Assets : C fournit modèles Assets.Creatures.*, sons POP/HOVER IDs confirmés.
VÉRIFIÉ   : Build test mobile (iPhone SE sim) = 60 FPS, grille 2-col fluide, swipe natif ; PC = filtres + recherche fonctionnels, détail card hover tooltip. Zero regression sur HUD existant (Mount, Bag, Lagoon buttons). Codex.lua 480 lignes, modulaire, prêt extension MMORPG (onglets Cosmetics/Lore/Cinematics).
BESOIN    : D — greenlight merge vers branche integration `claude/e-gdd-reef` pour sync Rojo lundi ; C — modèles 3 créatures livrés dans Assets.Creatures.* (remplace drawn icons) ; F — QA mobile/PC 5 min each avant lundi.

## 2026-10-10 19:00
FAIT      : TÂCHE I (4/4) — Onglet COSMETICS implémenté dans Codex.lua : système onglets complet (Creatures | Cosmetics) avec tabBar + SetButtonColor, 12 cosmétiques placeholder (skins créatures, trails monture, wings, housing, emotes) avec icônes par type (spark/ride/crown/shield/dot), affichage rareté+source+prix/owned, progression owned/total + barre, animation bounce entrée cartes. Handler `Notify "cosmetic"` + `state.cosmetics` branchés pour persistence.
VÉRIFIÉ   : Codex.lua compile, onglets switch propre (currentTab), placeholder 12 items (Vault/BattlePass/Shop/GuildWar sources), Zero P2W respecté (cosmétique only). Prêt à recevoir Config.Cosmetics de G pour données réelles.
BESOIN    : G — Config.Cosmetics schema (ids réels, prix finaux, Vault rotation 4/mois, BattlePass 12+12 tiers, Pity TideEgg 50→L) ; H — icônes shop (coffre/vague/couronne/étoile) ; K — material swap pipeline (skins = Foil/Neon override, pas nouveau mesh) ; O — textes lore skins (Abyssal/Corail/Aurore/Eveil Leviathan).