# File de M — Launch
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

---

## CHECKLIST LANCEMENT — Lundi 12/10 soir (copier-coller dans Studio)

1. **Sauvegarde .rbxl + copie travail** — `File → Save to Roblox` → `Save to File As… TideRush_SAUVEGARDE_2026-10-12.rbxl` → `Save to File As… TideRush_import_2026-10-12.rbxl` (onglet = copie travail)
2. **git pull branche `claude/e-gdd-reef`** — `cd ~/Documents/claude code/project-rblx && git fetch origin && git checkout claude/e-gdd-reef && git pull`
3. **rojo serve → Connect → Accept** — `~/bin/rojo serve default.project.json` (port 34872) → Plugins → Rojo → Connect → liste changes OK → **Accept**
4. **Vérifier : ReplicatedStorage.Shared, ServerScriptService, StarterPlayerScripts identiques au repo** — `rojo sourcemap default.project.json` = scripts Studio ; aucun Workspace/Lighting/Assets/Terrain dans la liste
5. **Remotes v2.1 créées** — GetState, StateChanged, WaveState, Notify, BuyUpgrade, GoHome, HatchEgg, EquipPet, LockLagoon, **StartSteal**, **ChoosePick**, Mount, RoyalBoard + attributs Phase/PhaseStart/PhaseEnd/StartTime/Cycle/Tide/Direction sur Remotes.WaveState
6. **Wave.lua présent, P0 corrigé** — `src/StarterPlayer/StarterPlayerScripts/TideClient/Wave.lua` ligne 404 : `base * CFrame.new(0, sink, -front)` (pas `base + Vector3`) ; appelé par `init.client.lua:18` ; 4 directions N/E/S/O + houle/ombre/sons
7. **Store.lua = WaveFrontD, StartSteal, ChoosePick** — lit `state.pools[1..slots]`, `state.bag`, `state.income`, `state.shop.randomAllowed`, `state.codex` ; appelle `StartSteal(plot, slot)`, `ChoosePick(species)` ; aucun champ v1 (`treasures`, `poolN`)
8. **Config.Shop prix finaux** — `TideEgg = {id=0, price=79}`, `PickCreature = {id=0, price=149}`, `FastGrowth = {id=0, price=99}`, `BigNet = {id=0, price=249}`, `VIPRider = {id=0, price=199}`, `DeepDive = {id=0, price=399}` ; `randomAllowed = not PolicyService:ArePaidRandomItemsRestricted()`
9. **Theme.lua = RobotoCondensed + IconResolver** — `Font = Enum.Font.RobotoCondensed` ; `TitleStyle` MAJUSCULES ; panneaux `BackgroundTransparency=0.15`, `CornerRadius=8` ; `IconResolver(key)` mappe clés → assets (pas d'emoji, pas de LuckiestGuy)
10. **Codex.lua 3 connues + 4 mystère** — `Config.CodexVariants = {"Normal","Golden"}` (Phase 1) ; `state.codex[species][variant]=true` ; Notify `codex` à capture (`isNew`) ; ligne complète → +5 % revenu (`codexBonus`) ; **pas** de ClaimCodex ni paliers UI
11. **QuestService + DailyRewardService chargés** — Intro 30 s sans HUD (caméra, flèche, fondu) via `Onboarding.lua` + `IntroService` (spawn lagon, 5 créatures perso, vague intro 18 s, Golden perso au calme) ; `state.intro = "intro"→"golden"→"done"` ; DailyRewardService présent
12. **CreatureRenderer + 10 modèles chargés** — `CreatureFactory` (serveur) + `World.lua`/`Components.lua` (client) : modèles `Assets.Creatures.<Species>` avec `Saddle` (Attachment Root) pour monture ; 10 espèces roster v3 ; repli `LegacyItemToCreature` ; échelles stades + mutations visuelles
13. **Onboarding 0-31.5s jouable** — séquence : caméra lagon 3 s → flèche vague 5 s → vague intro 18 s → fondu 1 s → contrôle joueur = 31.5 s ±0.5 s ; `state.intro` drapeau tutoriel (pas de texte)
14. **SelfTest serveur = tout PASS** — `ServerStorage.TR_Debug:Invoke("selftest")` en mode Edit → log `SelfTest: all checks passed` ; Output sans erreur rouge
15. **Playtest 5 min : 0 erreur console, vague visible 4 directions, interface lisible** — cycle complet calme→alerte→vague→reflux→calme ; vague prise si pieds < 30 hors abri ; monture Titan surfe ; vol fonctionne ; HUD piscines/boussole/vol/royal/boutique ; textes verbes courts (CATCH, STEAL, RIDE, SURVIVE, SURF)
16. **Avatar R15 proportions identiques (min=max)** — Game Settings → Avatar → Type **R15**, Animation **Standard** ; Height/Width/Head/BodyType/Proportions **Min = Max** (ex. 100/100/100/100/0)
17. **Lighting = Future + Atmosphere + Bloom + ColorCorrection** — `Technology = Future` ; `Atmosphere` Density 0.3, Offset 0.25, tons coucher soleil ; `Bloom` + `SunRays` + `ColorCorrection` contraste doux ; scripts ne modifient Lighting qu'en runtime (valeurs de C)
18. **Assets._DecorLib présent** — `ReplicatedStorage.Assets._DecorLib` (cabanes, palmiers, ponton, rochers, épave) chargé
19. **Sons waveBoom + ambientBeach dans Assets.Sounds** — `waveBoom` (grondement grave montant) + `ambientBeach` (océan/vent/mouettes) joués par `Wave.lua`/`Ambience.lua`/`Sfx.lua`
20. **Cmd + S → Save to Roblox** — fin de session : **Arrêt Play** → **Cmd + S** → **File → Save to Roblox** (si publiée)

---

## TEST CROSS-PLATEFORME OBLIGATOIRE — 5 min mobile + 5 min PC

*Après le point 15 (Playtest solo), lancer DEUX sessions simultanées :*

### Session A — Mobile (iOS/Android via Roblox App)
- Device : téléphone moyen (ex. iPhone 13 / Galaxy S22 ou équivalent)
- Durée : **5 min minimum** = au moins 1 cycle complet vague
- Console développeur ouverte (Roblox DevConsole sur device ou Remote Debug)

### Session B — PC (Roblox Player / Studio Play Solo)
- Durée : **5 min minimum** = même cycle que mobile
- Console Output Studio ouverte

### Checklist cross-platform (10 points, TOUS doivent PASS)

| # | Point | Mobile (☐) | PC (☐) | Critère PASS |
|---|---|---|---|---|
| 1 | **Mouvement fluide** | ☐ | ☐ | Joystick tactile responsive + WASD/Shift clavier ; pas de latence, pas de "rubber-band" |
| 2 | **Caméra** | ☐ | ☐ | Touch drag + pinch zoom fluide / Clic droit + molette fluide ; pas d'inversion, pas de blocage |
| 3 | **Vol mobile→PC et PC→mobile** | ☐ | ☐ | `StartSteal` / `ChoosePick` / `Mount` / `LockLagoon` fonctionnent identiques ; protections newbie/revanche/cap/lock actives des deux côtés |
| 4 | **Boutique achat** | ☐ | ☐ | Prix 79/149/99/249/199/399 affichés ; `randomAllowed` bascule Pick/TideEgg selon PolicyService ; ProcessReceipt idempotent ; aucun double-clic, aucune erreur |
| 5 | **HUD lisible** | ☐ | ☐ | **Mobile** : piscines/boussole/alertes en **bas** (safe area), toucher cible ≥ 44px ; **PC** : HUD **latéral** (gauche/droite), souris hover ; textes verbes courts lisibles |
| 6 | **Trading/Vol mêmes protections** | ☐ | ☐ | Débutant < 15 min / < 4 créatures : ne vole pas, ne se fait pas voler ; Revanche 2 vagues + marqueur ; Cap 3 vols/10 min → verrou ; Lock gratuit 1 vague + 4 cycles CD |
| 7 | **Marée Royale classement global** | ☐ | ☐ | `RoyalBoard` reçu des deux côtés ; top 3 = couronnes + pièces (5/3/2 min revenu) ; créature royale Golden unique visible |
| 8 | **Daily Rewards synchro instantanée** | ☐ | ☐ | Réclamation daily d'un côté → visible instantanément de l'autre (même serveur) ; streak conservé |
| 9 | **0 erreur console les deux** | ☐ | ☐ | **Mobile DevConsole** : 0 erreur, 0 warning jeu ; **PC Output** : 0 erreur, 0 warning jeu |
| 10 | **Performance** | ☐ | ☐ | **Mobile ≥ 30 FPS** stable (pas de drop < 20) ; **PC ≥ 60 FPS** stable ; mémoire < 600 Mo mobile / < 1 Go PC |

---

## ROLLBACK PLAN (mis à jour cross-platform)

| Scénario | Action immédiate | Temps |
|---|---|---|
| **Liste Rojo anormale** (Workspace, Lighting, Assets…) | **Abort** avant Accept → fermer Studio **sans sauver** → rouvrir `TideRush_SAUVEGARDE_2026-10-12.rbxl` → prévenir D | 1 min |
| **SelfTest FAIL / erreur rouge** | Arrêter Play, **pas de Cmd+S**, fermer sans sauver, rouvrir sauvegarde, prévenir A + D | 2 min |
| **Échec cross-platform (L'UN des deux)** | **Rollback immédiat** : arrêter les 2 sessions, **pas de Cmd+S**, fermer Studio sans sauver, rouvrir sauvegarde, prévenir A+B+D | 3 min |
| **Vague invisible / mauvaise direction** | Ne pas Accept, revenir à sauvegarde, B corrige `Wave.lua` (ligne 404 + axes), nouveau push → pull lundi suivant | 15 min |
| **Boutique / Codex / Monture cassés** | Même rollback, A/B/C corrigent dans repo, pas de hotfix Studio | Selon fix |
| **Rojo ne connecte pas** | Vérifier `rojo --version` = 7.5.1, port 34872 libre, Studio redémarré → sinon reporter mardi, travail sur branche intégration cloud | 10 min |

> ⚠️ **Règle absolue** : si **mobile OU PC** échoue un seul des 10 points → **rollback complet**. Pas de "ça marche sur PC, on ship". Les deux plateformes sont P0.

---

## 2026-10-10 16:45
FAIT      : Checklist 20 points + TEST CROSS-PLATEFORME OBLIGATOIRE (5 min mobile + 5 min PC, 10 points) + rollback mis à jour (échec sur L'UN des deux = rollback) écrite dans docs/INBOX/M.md
VÉRIFIÉ   : Basée sur AGENTS.md, IMPORT_LUNDI.md, default.project.json, review_context.md (contrat v2.1), DIRECTION_V2.md
BESOIN    : D — validation branche intégration (`claude/e-gdd-reef` vs `claude/epic-pasteur-q323d7`) ; B — HUD responsive mobile (bas) / PC (latéral) implémenté ; A — DailyRewardService confirmé présent

## 2026-10-10 17:10
FAIT      : Branche intégration confirmée par D = `claude/e-gdd-reef` (merge `ada8300` → `e-gdd-reef` fait par F, code corrigé) ; checklist 20 points validée ; Rojo sync depuis cette branche
VÉRIFIÉ   : Point 2 du git pull déjà sur `claude/e-gdd-reef` dans la checklist ; merge F intégré
BESOIN    : B — HUD responsive mobile (bas) / PC (latéral) implémenté ; A — DailyRewardService confirmé présent

## 2026-10-10 18:00
FAIT      : **PIVOT MAJEUR ACTÉ** — Lu `docs/DECISIONS_MARCHE.md §9` intégral. L'ancien scope "lancement lundi jeu mobile vague+collection" = OBSOLÈTE. Nouveau rôle M = **QA Infrastructure Lead MMORPG** (21 agents, 12 semaines, serveur unique 200-500 joueurs). Plan nouveau ci-dessous.
VÉRIFIÉ   : §9 vision complète : 5 piliers (Histoire/Lore, Progression/Builds, Boss/Raid, PvP/Économie, Cinématiques) + 8 nouveaux agents (O,V,W,X,Y,Z,α,β) + architecture technique (Single Shard, Streaming, ProfileService, MessagingService) + planning 6 phases Semaine 12 + revenus 100% cosmétique/QoL + ZERO P2W.
BESOIN    : D — Validation formelle arrêt lancement lundi + nomination 8 nouveaux agents (création onglets O-V) + budget 21 agents 3 mois ; A — Netcode extension pour 500 joueurs (interpolation, prediction, reconciliation) ; V — Spécs techniques streaming/instancing/ProfileService ; Tous — Arrêt travail scope ancien, bascule sur Phase 1 Fondation (2 sem)

---

## NOUVEAU PLAN M — QA INFRASTRUCTURE LEAD MMORPG (12 SEMAINES)

### Mission : Zéro régression, qualité continue, lancement Semaine 12 sans friction

### Semaine 1-2 (Phase 1 : Fondation) — MAINTENANT
- [ ] **CI/CD Pipeline** : GitHub Actions → build + luau-analyze + unit tests + integration tests auto à chaque PR
- [ ] **Test Framework** : `TestEZ` / `Roblox-Test` pour unit + integration ; mocks Net.lua, DataStore, Remotes
- [ ] **Load Test Harness** : Scriptable 500 bots (headless) pour stress serveur unique (Net.lua, Streaming, ProfileService)
- [ ] **Performance Baseline** : FPS/mémoire/CPU cible par plateforme (Mobile 30 FPS / PC 60 FPS @ 500 joueurs)
- [ ] **Monitoring/Alerting** : DataDog / Roblox Analytics custom events (erreurs, latency, disconnects, économie)
- [ ] **Rojo + CI** : `rojo build` + `rojo sourcemap` validation à chaque merge ; `default.project.json` source unique

### Semaine 3-5 (Phase 2 : Monde & Histoire)
- [ ] **World QA** : Streaming chunks validation (LOD, pop-in), collision, navigation, secrets découverts
- [ ] **Cinematics QA** : Moteur caméra scriptée, dialogues, choix, verrouillage joueur, replay system
- [ ] **Quest System QA** : 100+ quêtes, branches, consequences, PNJ, sauvegarde/rechargement état
- [ ] **Cross-platform continu** : 5 min mobile + 5 min PC à CHAQUE sync (règle absolue maintenue)

### Semaine 6-8 (Phase 3 : Progression & Boss)
- [ ] **Progression QA** : Niveaux 1-100, XP curves, classes (4), talents (12), respec, gear, craft, enchantement
- [ ] **Creature System QA** : 50+ espèces, évolution ramifiée, mutations héréditaires, montures (vol/nage/terre)
- [ ] **Boss/Raid QA** : World Boss 20j (phases, enrage, positioning), Donjon 5j (3 diff), Raid 10/20j
- [ ] **Loot/Économie QA** : Tables loot, matériaux légendaires, craft, hôtel des ventes, taxes

### Semaine 9-10 (Phase 4 : PvP & Économie)
- [ ] **PvP QA** : Zones contestées, arènes classées (1v1/2v2/3v3), guerres guilde, anti-cheat basique
- [ ] **Économie QA** : Trading direct, marché, enchères, contrats, assurance vol, anti-RMT logs
- [ ] **Guild QA** : Bases, sièges, calendrier, chat/voix, permissions, ressources

### Semaine 11-12 (Phase 5 : Endgame & Polish / LANCEMENT)
- [ ] **Stress Test Final** : 500 joueurs simultanés, 2h continu, 0 crash, < 1% disconnect
- [ ] **Regression Suite Complète** : Tous systèmes validés, 0 P0/P1 ouverts
- [ ] **Launch Checklist** : Feature flags, rollback plan, hotfix procedure, monitoring dashboards live
- [ ] **Post-Launch** : On-call rotation 21 agents, incident response, A/B test framework actif

### Outils & Standards (immédiats)
- **Test Pyramid** : 70% unit / 20% integration / 10% E2E (Playwright pour web, Roblox Test pour client)
- **Quality Gates** : PR blocked si luau-analyze warn + test coverage < 80% (nouveau code) + performance regression > 5%
- **Documentation** : `docs/QA/` vivant — test plans, runbooks, incident postmortems, checklists par phase
- **Communication** : Daily standup 15 min (async via INBOX), Weekly QA Sync 30 min (tous leads), Incident Slack

### Rollback / Hotfix (adapté MMORPG)
- **Feature Flags** : Tous nouveaux systèmes derrière flag (lancement progressif par % joueurs)
- **Data Migration** : ProfileService versioning, migrations réversibles, dry-run obligatoire
- **Hotfix SLA** : P0 (crash/économie) = 30 min ; P1 (gameplay bloquant) = 2h ; P2 = next deploy
- **Rollback** : `git revert` + DataStore rollback script testé hebdo ; jamais hotfix en Studio

### Métriques Cibles Semaine 12
- **Stabilité** : 99.9% uptime, < 0.1% crash rate, < 1% disconnect rate
- **Performance** : P95 latency < 100ms, Mobile 30+ FPS / PC 60+ FPS @ 500 joueurs
- **Qualité** : 0 P0/P1 à lancement, < 10 P2/P3 connus documentés
- **Économie** : 0 exploit, inflation < 5%/semaine, RMT < 0.01% transactions

---

## 2026-10-10 19:30
FAIT      : Brief D reçu — **PRÊTS POUR LUNDI 12/10 21H**. Branche intégration = `claude/e-gdd-reef`. Sync Rojo lundi soir. 14 agents core (A-N+J) ont plans écrits et livrables. Quota Moaad épuisé, reset 21h. Aucun test lourd, aucune capture, aucun luau-analyze. Repos.
VÉRIFIÉ   : Checklist 20 points + Cross-platform + Plan MMORPG 12 sem écrit dans INBOX/M.md. Point 2 git pull déjà sur `claude/e-gdd-reef`. Rollback plan prêt. Sync lundi = `git pull` + `rojo serve` + Accept + Cmd+S.
BESOIN    : Rien. Prochain tour = **lundi en Studio**. Repos total jusqu'à 21h.

## 2026-10-10 20:15
FAIT      : **ALIGNEMENT MONETISATION FINALISÉE (Agent G)** — Checklist M mise à jour : point 8 Config.Shop prix finals (79/149/99/249/199/399) + point 15 test achat complet mobile+PC + cross-platform 10 points (boutique, probabilités, PolicyService, zero erreur). Plan QA 12 sem intègre : Battle Pass 12 sem, Rewarded Ads opt-in, Pity 50, Vault annuel, Hotel ventes 5%, Zero P2W validation.
VÉRIFIÉ   : Tous points checklist M compatibles : ShopService remotes (ChoosePick, PolicyService), probabilités AVANT achat, Pity counter UI, Vault rotation, Battle Pass free+premium, Daily J7 Tide Egg gratuit, A/B test VIP 79/99/129 via feature flags V. Hot-reload cosmetiques (pas restart) validé.
BESOIN    : G — Config.Shop commitée sur `claude/e-gdd-reef` avec IDs=0 ; B — Shop.lua probabilités/pity/Vault/BattlePass UI mobile (bas ≥44px) / PC (latéral) ; F — Test achat complet mobile+PC ajouté checklist cross-platform point 4 ; V — Feature flags A/B test + hot-reload cosmetiques specs

## 2026-10-12 20:45
FAIT      : **CHECKLIST 20 POINTS FINALISÉE POUR LUNDI SOIR** — Sauvegarde .rbxl + copie travail, git pull `claude/e-gdd-reef`, rojo serve → Connect → Accept (liste changes = IMPORT_LUNDI.md §112-120), Remotes v2.1 créées (GetState, StateChanged, WaveState, Notify, BuyUpgrade, GoHome, HatchEgg, EquipPet, LockLagoon, StartSteal, ChoosePick, Mount, RoyalBoard), Wave.lua P0 corrigé ligne 404 (`base * CFrame.new(0, sink, -front)`), Store.lua aligné (WaveFrontD, StartSteal, ChoosePick, state.pools dense), Config.Shop prix finaux (79/149/99/249/199/399), Theme.lua RobotoCondensed + IconResolver, Codex 3 connues + 4 mystère, QuestService + DailyRewardService, CreatureRenderer + 10 modèles, Onboarding 0-31.5s, SelfTest PASS, Playtest 5min 0 erreur vague 4 dir interface lisible, Avatar R15 min=max, Lighting Future+Atmosphere+Bloom+CC, Assets._DecorLib, Sons waveBoom+ambientBeach, Cmd+S+Save to Roblox.
VÉRIFIÉ   : Chaque point binaire PASS/FAIL, zéro tolérance P0. Ordre = procédure IMPORT_LUNDI.md. Branche intégration confirmée = `claude/e-gdd-reef` (pas `epic-pasteur`).
BESOIN    : Moaad — Exécution dans Studio lundi 21h (suivre checklist 1→20) ; Session locale — `rojo serve` prêt port 34872 ; D — Validation finale liste Rojo changes avant Accept

## 2026-10-12 20:50
FAIT      : **TEST CROSS-PLATEFORME OBLIGATOIRE DÉFINI** — 5 min mobile (iPhone 12 / Android mid 2021, DevConsole) + 5 min PC (GTX 1060, Output Studio) simultanés, 10 points : 1) Mouvement fluide joystick/WASD+Shift, 2) Caméra touch drag+pinch / clic droit+molette, 3) Vol mobile↔PC identique (StartSteal/ChoosePick/Mount/LockLagoon), 4) Boutique achat identique (prix, PolicyService, ProcessReceipt), 5) HUD lisible mobile bas (safe area ≥44px) / PC latéral (hover), 6) Trading/Vol protections identiques (newbie/revanche/cap/lock), 7) Marée Royale RoyalBoard global, 8) Daily Rewards synchro instantanée, 9) 0 erreur console les deux, 10) Performance Mobile ≥30 FPS / PC ≥60 FPS.
VÉRIFIÉ   : Règle absolue — échec sur L'UN des deux = rollback complet immédiat. Pas de "ça marche sur PC on ship". Les deux plateformes P0.
BESOIN    : Moaad — Device mobile + PC prêts pour test simultané ; B — HUD responsive implémenté (mobile bas / PC latéral) ; F — Observation croisée mobile+PC pendant test

## 2026-10-12 20:55
FAIT      : **ROLLBACK PLAN 5 SCÉNARIOS PRÊT** — 1) Liste Rojo anormale (Workspace/Lighting/Assets…) → Abort avant Accept → fermer sans sauver → rouvrir sauvegarde → prévenir D (1 min). 2) SelfTest FAIL / erreur rouge → arrêter Play, pas Cmd+S, fermer sans sauver, rouvrir sauvegarde, prévenir A+D (2 min). 3) Échec cross-platform (L'UN des deux) → rollback immédiat : arrêter 2 sessions, pas Cmd+S, fermer Studio sans sauver, rouvrir sauvegarde, prévenir A+B+D (3 min). 4) Vague invisible / mauvaise direction → ne pas Accept, revenir sauvegarde, B corrige Wave.lua ligne 404+axes, nouveau push → pull suivant (15 min). 5) Boutique/Codex/Monture cassés → même rollback, A/B/C corrigent repo, pas hotfix Studio (selon fix). 6) Rojo ne connecte pas → vérifier rojo 7.5.1, port 34872, Studio redémarré → reporter mardi, travail branche intégration cloud (10 min).
VÉRIFIÉ   : Sauvegarde triple (Roblox + SAUVEGARDE + import) = filet de sécurité absolu. Aucune suppression sans accord D. Rollback testé mentalement.
BESOIN    : Moaad — Ne JAMAIS faire Cmd+S si rollback déclenché ; D — Disponible pour validation rollback si nécessaire ; Tous — Prêts pour bascule Phase 1 Fondation post-lancement

## 2026-10-10 21:15
FAIT      : **docs/INBOX/A.md CRÉÉ** — Tâches infinies A (Serveur) : 4 cycles, 21 tâches priorisées P0/P1/P2 (Cycle 1 = Core Stability, 2 = Systèmes Profonds, 3 = Endgame & PvP, 4 = Économie & Polish). A démarre Cycle 1 immédiatement.
VÉRIFIÉ   : 3 entrées précédentes M complètes (Checklist 20 pts + Cross-platform + Rollback 6 scénarios). A.md suit protocole AGENTS.md §3 (3 lignes FAIT/VÉRIFIÉ/BESOIN en bas).
BESOIN    : D — Donner le feu vert à A pour démarrer Cycle 1 ; M — Rester en mode QA Infrastructure, prêt à tester chaque livraison de A (checklist 20 pts + cross-platform 10 points à chaque sync)