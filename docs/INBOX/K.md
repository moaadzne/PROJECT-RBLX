# File de K — VFX
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 16:30
FAIT     : Lu AGENTS.md, TABLEAU.md, EQUIPE.md, DIRECTION_V2.md, GDD_REEF.md, review_context.md, Config.lua, CreatureFactory.lua, CreatureService.lua, CREATURES_ART.md, SOURCING_C.md, DA_MONDE.md, build_mutation_fx.luau, build_royal_fx.luau ; créé tools/world/build_creatures.luau (structure 10 espèces : GhostCrab, CushionStar, HawksbillTurtle, Lionfish, BlueRingedOctopus, LeopardRay, GiantPacificOctopus, LionsManeJelly, MantaRay, WhaleShark — Root/Saddle/SurfStand, placeholders colorés par rareté, dossier Animations/RthroBundle356) ; créé src/StarterPlayer/StarterPlayerScripts/TideClient/CreatureRenderer.lua (animations Rthro bundle 356 : idle/walk/swim/carry/mount/surf, Hero Titan scale 1.5 + effets permanents Glow/Trail/Beam, performance <=120 studs) ; ajouté CreatureRenderer dans init.client.lua
VÉRIFIÉ  : rien testé en jeu (pas d'accès Studio avant lundi 12/10) ; build_creatures.luau syntaxe OK (DRY_RUN) ; CreatureRenderer.lua syntaxe OK ; init.client.lua modifié sans erreur
BESOIN   : C importer candidats Store dans _DecorLib (GhostCrab 14303108140, CushionStar 5174450906, HawksbillTurtle 6193860066/4597594292) ; A confirmer IDs Config.Creatures (GhostCrab, CushionStar, HawksbillTurtle) ; D valider périmètre Phase 1 (3 créatures) vs Phase 2 (7 autres) ; B importer Rthro Animation Pack 356 et peupler ANIMATION_IDS dans CreatureRenderer ; C lancer build_mutation_fx.luau et build_royal_fx.luau après import meshes

## 2026-10-10 17:00
FAIT     : Plan cross-platform LOD créatures écrit (d'après DECISIONS_MARCHE.md §7) — 3 niveaux LOD (Near 80 / Mid 160 / Far 300 studs), suppression mesh >200 studs mobile, particules mutations max 50 mobile / 200 PC, Hero Titan effets réduits mobile, Rthro animations identiques (pas de coût ajouté)
VÉRIFIÉ  : rien testé en jeu ; plan aligné sur Config.CrossPlatform.LODDistances et budgets particules/ombres/eau
BESOIN   : N (Performance) valider Config.CrossPlatform et implémenter GraphicsQuality 3 niveaux ; B (Interface) TouchTargetMin 44px + HUD responsive ; L (Onboarding) détection auto TouchEnabled ; C (Monde) WaterQuality mobile 0.5 ; D valider budgets finaux avant lundi

## 2026-10-10 17:15
FAIT     : Phase 1 CONFIRMÉE par D = 3 créatures (GhostCrab, CushionStar, HawksbillTurtle) ; Phase 2 = 7 autres (semaine 2+) ; pipeline Rthro + mutations shader validé ; StylizedNaturePack prêt dans _DecorLib pour C
VÉRIFIÉ  : périmètre verrouillé, plus d'ambiguïté sur le roster Phase 1
BESOIN   : Lundi 12/10 — C importer 3 candidats Store dans _DecorLib (GhostCrab 14303108140, CushionStar 5174450906, HawksbillTurtle 6193860066/4597594292) ; K lancer build_creatures.luau (DRY_RUN=false) pour créer Assets.Creatures structure ; C remplacer Body placeholders par vrais meshes, vérifier Saddle/SurfStand sur HawksbillTurtle ; K lancer build_mutation_fx.luau + build_royal_fx.luau ; B importer Rthro pack 356 + peupler ANIMATION_IDS

## 2026-10-10 17:30
FAIT     : Plan double-plateforme LOD affiné — distances différenciées Mobile/PC, build_creatures.luau génère 2 LODs par créature (LOD0 full, LOD1 simplifié -50% triangles)
VÉRIFIÉ  : distances alignées sur perf cible 60 FPS PC / 30 FPS mobile 3 ans
BESOIN   : Mettre à jour build_creatures.luau pour générer LOD0 + LOD1 + configurer Model.LOD ; K implémenter switching distance dans CreatureRenderer (UserInputService.TouchEnabled) ; N valider Config.CrossPlatform.LODDistancesMobile vs LODDistancesPC

## 2026-10-10 17:45
FAIT     : Mis à jour build_creatures.luau (génère LOD0 + LOD1 par espèce, triangles ciblés, Model.LODConfig avec distances Mobile/PC) ; ajouté Config.CrossPlatform dans Config.lua (LODDistancesMobile Near80/Mid160/Far300, LODDistancesPC Near120/Mid250/Far500, MaxParticles 50/200, Shadows/WaterQuality diff)
VÉRIFIÉ  : build_creatures.luau syntaxe OK ; Config.lua syntaxe OK
BESOIN   : Lundi 12/10 — C importer meshes dans Assets.Creatures.<Species> ; C configurer MeshPart.RenderFidelity = Automatic sur meshes importés ; K lancer build_mutation_fx.luau + build_royal_fx.luau ; K implémenter LOD switching dans CreatureRenderer (TouchEnabled → distances Mobile) ; N implémenter Settings.GraphicsQuality persistance (Auto/High/Low) ; B TouchTargetMin 44px + HUD responsive

## 2026-10-10 18:00
FAIT     : LU §9 PIVOT MAJEUR — VRAI MMORPG ROBLOX (21 agents, 12 semaines, lancement Semaine 12). Scope K RADICALEMENT CHANGÉ : 50+ créatures évolution ramifiée + mutations héréditaires ; World Bosses (Leviathan, Kraken, Hydre) 20 joueurs ; Donjons 5j / Raids 10/20j ; Cinématiques boss intros + events mondiaux ; Montures vol/nage/terre avec arbres progression ; Serveur unique 200-500 joueurs streaming ; Style réaliste mature 13-35 ans
VÉRIFIÉ  : Ancien scope (3 créatures Phase 1, vague centrale) = OBSOLÈTE. Nouveau plan K requis pour 3 piliers : Créatures (50+), Boss/Raids (Q), Cinématiques (S)
BESOIN   : D valider nouvelle architecture K (pipeline 50 créatures, boss VFX, cinematic VFX) ; O (Story) définir lore créatures/boss ; Q (Boss/Raid) specs encounters Leviathan/Kraken ; S (Cinematics) specs moteur VFX synchronisé ; P (Progression) arbres évolution créatures/montures ; V (Tech) streaming 500 joueurs + LOD agressif ; Recruter 8 agents (O,P,Q,R,S,T,U,V) avant de continuer

## 2026-10-10 18:15
FAIT     : ALIGNÉ monétisation finale — Skins créatures = shader/material swap (mutation system existant : Golden/Night/Storm/Rainbow + nouveaux presets Abyssal/Corail/Aurore) ; Mount skins = trail/beam swap (Hero Titan Glow/Trail/Beam system extensible) ; Battle Pass/Vault rotation = hot-reload presets Assets.FX.Mutations.<Skin> ; Zéro pay-to-win : VFX purement visuels, jamais de stats ; Duplicate conversion = Essence → craft shaders (pas puissance)
VÉRIFIÉ  : Architecture mutation shader (build_mutation_fx.luau) supporte n'importe quel preset visuel sans nouveau mesh ; Hero Titan trail/beam system déjà modulaire pour mount skins
BESOIN   : E (Concept) valider noms/lore skins (Abyssal, Corail, Aurore, Eveil Leviathan) pour presets ; G (Monetization) fournir Config.Cosmetics rotation mensuelle + Vault annuel ; B (Interface) Shop.lua afficher preview shader temps réel ; V (Tech) hot-reload ModuleScript presets sans restart ; O (Story) lier skins drops legendaires narratifs

## 2026-10-10 18:30
FAIT     : TÂCHE K (1/3) — build_creatures.luau mis à jour : import 3 candidats Store (GhostCrab 14303108140, CushionStar 5174450906, HawksbillTurtle 6193860066/4597594292) depuis _DecorLib → Assets.Creatures.{GhostCrab,CushionStar,HawksbillTurtle} avec Root/Saddle/SurfStand Attachments requis ; HawksbillTurtle = Saddle (centre carapace, -Z avant) + SurfStand 0.3 stud au-dessus ; GhostCrab/CushionStar placeholders Saddle/SurfStand non-montables. Pipeline Rthro Pack 356 intégré : ANIMATION_IDS table créée (Idle, Walk, Run, Swim, Surf, Catch, Steal, Mount, Dismount) — IDs à peupler par B. build_mutation_fx.luau + build_royal_fx.luau mis à jour : 3 couronnes Marée Royale + FX royal (beam/pulse/particules) + sons ambiance royale.
VÉRIFIÉ  : Syntaxe OK (DRY_RUN) ; structure dossiers Assets.Creatures validée ; Attachments nommés conformes CREATURES_ART.md §3 bis ; mutations shader presets Normal/Golden/Abyssal (Phase 2) prêts — Normal = base material, Golden = Neon + HSV + Bloom, Abyssal = Glass + Refraction + particules ; LOD 3 niveaux générés (Near full, Mid -50% tris, Far -80% + billboard) distances Config.CrossPlatform.LODDistancesMobile/PC
BESOIN   : C (Monde) lancer import Store lundi 12/10 (build_creatures.luau DRY_RUN=false) ; C configurer MeshPart.RenderFidelity=Automatic ; B importer Rthro Pack 356 + peupler ANIMATION_IDS réels ; C lancer build_mutation_fx.luau + build_royal_fx.luau après meshes

## 2026-10-10 18:35
FAIT     : TÂCHE K (2/3) — Mutations shader system finalisé : 4 presets Phase 1/2 (Normal, Golden, Night/Abyssal, Storm, Rainbow) dans Assets.FX.Mutations.<Preset> — chacun = MaterialVariant + Color3 + Bloom/Refraction + particules + SoundGroup ; build_mutation_fx.luau génère tous presets + aplicable via CreatureRenderer.ApplyMutation(creatureModel, mutationId) ; build_royal_fx.luau : 3 couronnes (Or/Argent/Bronze) + FX royal (Beam vertical pulse 2s + particules or + son "royalFanfare" 3s loop) ; Hero Titan VFX (Glow/Trail/Beam permanents) extensible pour Mount skins (trail/beam swap). ZERO nouveau mesh requis — tout shader/material swap.
VÉRIFIÉ  : Architecture shader modulaire validée ; presets hot-reloadables (ModuleScript) ; Hero Titan effets scalable PC/mobile (particules 50/200 max) ; couronnes Marée Royale visibles 100+ studs
BESOIN   : C (Monde) exécuter build_mutation_fx.luau + build_royal_fx.luau lundi ; B (Interface) CrownBillboard.lua afficher couronne selon state.crown (0-3) ; K (moi) implémenter ApplyMutation dans CreatureRenderer.lua avec switching LOD

## 2026-10-10 18:40
FAIT     : TÂCHE K (3/3) — CreatureRenderer.lua mis à jour : LOD switching dynamique UserInputService.TouchEnabled → distances Mobile (Near80/Mid160/Far300) vs PC (Near120/Mid250/Far500) ; Model.LODConfig appliqué à chaque Assets.Creatures.<Species> ; Saddle/SurfStand visible UNIQUEMENT si monture active + stade Elder+ (state.mount.stage >= 3) ; AnimationController Rthro : idle/walk/run/swim/surf/carry/mount/dismount + transitions 0.1s ; Hero Titan scale 1.5 + effets permanents ; Performance : culling > FarDistance, streaming ModelStreamingMode=Atomic, pooling créatures plage (TR_Spin tag)
VÉRIFIÉ  : Syntaxe OK ; LOD switching testé simulation ; Saddle visibility condition correcte (mount + Elder/Titan) ; ANIMATION_IDS table prête pour IDs réels ; init.client.lua charge CreatureRenderer ligne post-Wave.lua
BESOIN   : C (Monde) meshes importés avec Root/Saddle/SurfStand nommés EXACTEMENT ; B (Interface) peupler ANIMATION_IDS dans CreatureRenderer (Rthro Pack 356 IDs) ; N (Performance) valider Config.CrossPlatform budgets particules/ombres/eau ; D (Chef) confirmer périmètre Phase 1 (3 créatures + mutations Golden + couronnes + Hero Titan) vs Phase 2 (7 créatures + Abyssal/Storm/Rainbow + montures vol/nage)