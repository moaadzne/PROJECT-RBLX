## 2026-10-10 21:15
FAIT     : 4 specs docs Phase 1 livrées et poussées — POI_SPECS_P1.md, EXTREME_TIDE_P1.md, STREAMING_SPECS_P1.md, WEATHER_SPECS_P1.md
VÉRIFIÉ  : Contenu vérifié identique dans HEAD (origin/claude/r-economy-pvp d6b3838) — malgré un reset parallèle qui avait orpheliné mon commit 4c75982, les fichiers ont été absorbés par le lot E et sont intacts sur le remote
BESOIN   : D merge mes 4 specs dans claude/e-gdd-reef avant lundi — e-gdd-reef n'a que mon plan (153b86c), pas les specs

## 2026-10-10 20:45
FAIT     : Cycle 1 ARCHIPELAGO livré — docs/ARCHIPELAGO_SPECS.md : 10 îles/biomes/règles vague/secrets, crique hub + orientation naturelle, 8 tours Y=34, terrain sculpté, streaming chunks 200×200 + LOD (mobile suppr >200)
VÉRIFIÉ  : Aligné brief D (600×600 P1, pas 800×800/jungle/grotte), contrat v2.1 (towerRadius, coveRadius=110), DA_MONDE, DECISIONS_MARCHE
BESOIN   : C implémente terrain + 8 tours lundi ; V config StreamingEnabled + chunks ; Cycles 2-4 notés NON LANCÉS (quota, reset 12/10 21h)

## 2026-10-10 20:30
FAIT     : 3 docs specs livrés — POI_SPECS_P1.md (Belvédère/Épave/Récif), EXTREME_TIDE_P1.md (timeline 25s, signs sans texte), STREAMING_SPECS_P1.md (chunks 100×100, LOD 3 niveaux, budgets mobile/PC)
VÉRIFIÉ  : Aligné DA_MONDE §0-5, DECISIONS_MARCHE §3, contrat v2.1, Config.ExtremeTide
BESOIN   : C implémente lundi (POI visuels, assets corail/mouettes, modèles LOD) ; A confirme Config.WreckInscription + ExtremeTide values ; B fog of war + boussole ; F test mobile/PC lundi

## 2026-10-10 20:00
FAIT     : Config.Island{} specs Phase 1 — center, size=600, coveRadius=110, seaMargin=30, spawnYMin/Max, towerRadius=16, rings[3] (70-150/150-225/225-300), POIs[3] (Belvédère/Epave/Recif) ; build_island_terrain.luau génère île 600x600, 8 lagons r=30
VÉRIFIÉ  : Spécifications alignées contrat v2.1 (Config.Island, Config.Rings, Config.Wave), DA_MONDE §0-4, TABLEAU P1-36
BESOIN   : C implémente build_island_terrain.luau lundi ; A confirme Config.Island values ; D valide coveRadius=110 vs 70

## 2026-10-10 19:45
FAIT     : 3 POI specs détaillés — Belvédère (sommet falaise h=30, safe spot, vue vague), Épave (repère visible + inscription Config.WreckInscription + empreinte lumineuse pulse marées), Récif marée extrême (0,0,335 r=30, 6 créatures rares 25s, 1 Golden garantie)
VÉRIFIÉ  : Belvédère h=30 < tour Y=34 (cohérent vague 30) ; Épave inscription lisible 3s (DECISIONS_MARCHE §3) ; Récif visible depuis plage
BESOIN   : C assets POI (mesh falaise/arche, épave modulaire, coraux récif) ; A Config.WreckInscription string ; K particule empreinte lumineuse

## 2026-10-10 19:30
FAIT     : Navigation & découverte Phase 1 — Boussole HUD (B) + direction vague N/E/S/O (pas carte) ; Brume de guerre révélée par proximity ; Waypoints visuels (tours Y=34, phare, épave) ; Secrets Phase 2 notés (grottes sous-marines, trésors engloutis, journal fragments O/Story)
VÉRIFIÉ  : Boussole = seul outil nav (décision D) ; Fog of war client-side, reset par cycle ; Tours/phare/épave = landmarks visibles 100+ studs
BESOIN   : B implémente boussole + fog of war reveal ; C tours Y=34 + phare visible ; O journal fragments specs Phase 2

## 2026-10-10 19:00
FAIT     : Alignment monétisation — Housing zones/Guild Hall plots = cosmetic-only (zéro paywall, zéro puissance) ; Exploration rewards = skins/trails/themes ; Battle Pass cosmetics tied to world events (Extreme Tide, World Boss) ; Free player accès complet monde
VÉRIFIÉ  : Plan Phase 1 déjà compatible (POI accessibles à tous, marée extrême gratuite, streaming gratuit)
BESOIN   : C implémente housing/guild plots zones visuelles ; K shader skins créatures ; G BattlePassService events hooks ; O lore skins (Abyssal, Corail, Aurore)

## 2026-10-10 18:30
FAIT     : INBOX/T.md finalisé — Phase 1 specs prêtes (POI, marée extrême, streaming, météo base), branche claude/e-gdd-reef
VÉRIFIÉ  : rien testé en jeu
BESOIN   : Sync Rojo lundi 12/10 21h en Studio ; repos jusqu'à lundi

## 2026-10-10 18:15
FAIT     : Plan Phase 1 complet écrit (POI, marée extrême, streaming, météo base) — aligné brief D, branche claude/e-gdd-reef
VÉRIFIÉ  : rien testé en jeu (planification seulement)
BESOIN   : Sync Rojo lundi 21h en Studio ; C valide specs POI + assets ; A confirme extreme tide ; T en pause (semaine 2+)

## 2026-10-10 18:45
FAIT     : Prêt pour lundi 12/10 21h — Sync Rojo branche `claude/e-gdd-reef`, specs Phase 1 livrées (POI, Marée Extrême, Streaming, Météo base), zéro test lourd/capture/luau-analyze
VÉRIFIÉ  : Plan aligné TABLEAU.md P1-36, DA_MONDE, DIRECTION_V2, contrat v2.1
BESOIN   : Rien — repos jusqu'à lundi Studio

## 2026-10-10 17:30
FAIT     : Plan INBOX/T.md Phase 1 — Île 600×600, 8 lagons, 3 POI (belvédère, épave, récif), marée extrême, streaming
VÉRIFIÉ  : rien testé en jeu (planification seulement)
BESOIN   : C valide specs visuels POI + streaming chunks ; A confirme WaveState.extreme + Config.ExtremeTide ; D tranche périmètre T vs C sur Workspace.Map

---

# T — WORLD & EXPLORATION : PLAN PHASE 1 (SEMAINES 1-2)

## Périmètre Phase 1 (décision D)
- **Île unique** : 600×600 studs, crique centrale rayon 70, 8 lagons en arc
- **3 POI** : Belvédère (falaise 40-60h, abri toutes vagues), Épave (Ouest, créatures meilleures), Récif marée basse (Sud, révélé marée extrême)
- **Pas** : 800×800, jungle, grotte, carte — tout en Phase 2+
- **Vague** : 4 directions N/E/S/O, jamais 2× même, hauteur 30, tours Y=34

---

## 1. SPECS POI (pour C — implémentation visuelle)
| POI | Position | Gameplay | Visuel clé | Assets requis |
|-----|----------|----------|------------|---------------|
| **Belvédère** | Falaise Est, Y=40-60 | Safe spot, spot vidéo, vision vague | Roche volcanique, arche corail, phare lointain | Mesh falaise, arche, phare LOD |
| **Épave** | Ouest, bord anneau 225-300 | Meilleurs spawns, gravure lumineuse au sol | Coque brisée, mâts, empreinte pulse marées | Mesh épave (modulaire), particule empreinte |
| **Récif** | Sud, centre (0,0,335), rayon 30 | Marée extrême : découvert 25s, 6 créatures (1 Golden garantie) | Corail vivant, eau peu profonde, visible depuis plage | Coraux, sable mouillé, shader eau basse |

**Livrable T** : `docs/POI_SPECS_P1.md` — fiches techniques (position exacte, dimensions, collision, streaming mode, assets, triggers).

---

## 2. MARÉE EXTRÊME — SYSTÈME COMPLET (P1)
- **Trigger** : `Config.ExtremeTide` (cycle % 58 == 29), 1/h, pendant calme seulement
- **Visuel (C/B)** : Mer recule 2×, sable mouillé étendu, récif émerge, mouettes fuient, silence → houle 55 studs
- **Gameplay (A)** : 6 créatures spawn (70% Hawksbill, 30% Lionfish), chances Golden, **1 Golden garantie** (reprise logique IntroService)
- **Signes joueur** : Zéro texte. Mouettes (son/visuel), mer recule, grondement grave, empreinte épave pulse
- **Nettoyage** : Serveur retire créatures à `endsAt`, mer revient (client joue d'après `wave.extreme`)

**Livrable T** : `docs/EXTREME_TIDE_P1.md` — timeline seconde par seconde, specs client/serveur, assets sons/particules.

---

## 3. STREAMING & PERFORMANCE (P1 critique mobile)
- **StreamingEnabled** : true, `StreamingTargetRadius` = 300 (mobile) / 500 (PC)
- **Chunks** : Grille 100×100 = 36 chunks. Crique = `Persistent`. Anneaux 70-300 = `Atomic`. POI = `Atomic`. Large = non streamé.
- **ModelStreamingMode** : Créatures/bassins/barrières/tours = `Atomic`. Végétation/rochers/décor = `NonAtomic`.
- **LOD** : 3 niveaux (Near <80, Mid 80-160, Far 160-300). Imposters >300. Budget ≤3000 parts visibles, ≤15 émetteurs, ≤12 sons.
- **Cross-platform** : Segments vague 15 (mobile) / 30 (PC), particules 50/200, ombres off/on.

**Livrable T** : `docs/STREAMING_SPECS_P1.md` — config StreamingEnabled, grille chunks, LOD tables, budgets, test plan mobile/PC.

---

## 4. EXPLORATION RÉCOMPENSÉE — FONDATIONS P1
- **Gravure épave** : Employée lumineuse pulse (DECISIONS_MARCHE §3) — clue visuel unique, partageable
- **Récif marée basse** : Seulement accessible marée extrême → récompense exploration (créatures rares + Golden)
- **Belvédère** : Meilleur point de vue vague → incite exploration, spot vidéo naturel
- **Codex Exploration (P2+)** : Cases îles/POI/secrets — P1 = fondations seulement (pas d'UI)

---

## 5. MÉTÉO JOUR/NUIT — BASE P1
- **Cycle** : 20 min réel = 24h jeu. `Lighting.ClockTime` piloté serveur → `WeatherState` RemoteEvent
- **Phases** : Jour (7-18), Crépuscule (18-20), Nuit (20-5), Aube (5-7)
- **Impact P1** : Visuel seulement (Lighting presets C). Gameplay (spawn nuit, visibilité) = P2

**Livrable T** : `docs/WEATHER_SPECS_P1.md` — cycle timing, presets Lighting par phase, RemoteEvent schema.

---

## 6. COORDINATION IMMÉDIATE (cette semaine)
| Action | Avec | Bloquant |
|--------|------|----------|
| Valider specs POI (positions, collisions, streaming) | C | C commence build lundi |
| Confirmer WaveState.extreme + Config.ExtremeTide valeurs | A | Déjà codé, vérif cohérence |
| Définir assets manquants ReplicatedStorage.Assets (POI, coraux, épave, particule empreinte) | C | Build bloque sans assets |
| Écrire 3 specs docs (POI, Extreme Tide, Streaming) | — | Prêt pour review D mercredi |

---

## 7. HORS PHASE 1 (noté pour P2+)
- Archipel 5+ îles, navigation monture, classes/progression, boss/raids, PvP/économie, cinématiques
- Secrets Phase 2 (grotte reflux, rogue wave, espèce fantôme, gravures lore)
- Météo gameplay (pluie/brouillard/neige impact spawn/visibilité/vitesse)
- Donjons instanciés (grotte, épave intérieure)
- World Boss, Raids 10/20, Guerres guilde

---

## 2026-10-10 17:30
FAIT     : Plan Phase 1 focalisé (POI, marée extrême, streaming, météo base) — aligné brief D
VÉRIFIÉ  : rien testé en jeu
BESOIN   : C valide specs POI + assets lundi ; A confirme extreme tide values ; D confirme périmètre T (specs) vs C (implémentation visuelle Workspace.Map)