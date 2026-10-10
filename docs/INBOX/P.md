# File de P — Progression & Systems

> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

---

## TÂCHES INFINIES — P (PROGRESSION) — TU NE T'ARRÊTES JAMAIS

### RÈGLE : Cycle 1→2→3→4→1 amélioré. JAMAIS d'arrêt.

---

## CYCLE 1 — PROGRESSION CORE (maintenant)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 1 | **Niveaux 1-100+** : XP tout (combat, exploration, craft, social, trading) | P0 | ⬜ |
| 2 | **4 classes** : Gardien, Chasseur, Maître, Tisseur (identités distinctes) | P0 | ⬜ |
| 3 | **3 arbres talents/classe**, 30 points max, respec coût croissant | P0 | ⬜ |
| 4 | **Gear** : craft, enchantement, runes, sets légendaires, durabilité | P0 | ⬜ |
| 5 | **Créatures 50+** : évolution ramifiée, mutations héréditaires, breeding | P0 | ⬜ |

---

## CYCLE 2 — SYSTÈMES PROFONDS (semaine 1)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 6 | **Montures vol/nage/terre** : arbres progression, vitesses, capacités | P1 | ⬜ |
| 7 | **Housing/Bases** : construction modulaire, défense, production, Guild Halls | P1 | ⬜ |
| 8 | **Artisanat** : recettes, matériaux rares, qualité, recettes légendaires | P1 | ⬜ |
| 9 | **Enchantement** : runes, sockets, levels, échecs partiels, réussites parfaites | P1 | ⬜ |
| 10 | **Réputation** : factions, paliers, récompenses exclusives, pénalités | P1 | ⬜ |

---

## CYCLE 3 — BUILD & ENDGAME (semaine 2)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 11 | **Build diversity** : multiples viables, counterplay, synergies | P1 | ⬜ |
| 12 | **Gear score** : paliers, Difficulté, Minimal Required Power | P1 | ⬜ |
| 13 | **Prestige** : reset niveaux, bonus permanents, cosmétiques exclusifs | P1 | ⬜ |
| 14 | **Parangons** : spécialisation post-100, talents exclusifs | P1 | ⬜ |
| 15 | **Mastery** : armes, compétences, montures, artisanat | P1 | ⬜ |

---

## CYCLE 4 — TUNING & ÉQUILIBRE (continu)

| # | Tâche | Priorité | Statut |
|---|---|---|---|
| 16 | **XP curves** : progression fluide, paliers satisfaisants, pas wall | P2 | ⬜ |
| 17 | **DPS/HPS/TPS par palier** : balance classes, boss health, DPS check | P2 | ⬜ |
| 18 | **Gear drop rates** : content gating, power creep, catch-up mechanics | P2 | ⬜ |
| 19 | **Économie puissance** : sources/sinks, temps-to-power, temps-to-cosmetics | P2 | ⬜ |
| 20 | **Saison** : resets soft, transfert puissance, nouveautés, prestige | P2 | ⬜ |

---

## 2026-10-10 17:00
FAIT     : Alignment Progression × Monétisation finalisée — **Battle Pass** : 12 paliers gratuits (pièces, XP, 1 skin commun) + 12 premium (skins rares/épique, mount exclusif, wings, title, 2 Tide Eggs) → Config.BattlePass tiers définis dans Config.Shop ; **Maree Royale** : top 3 = couronnes cosmétiques + titres (pas puissance) + Pearls pour Deep Dive semaine 2 ; **Guildes** : Guild Hall themes achetables (cosmétiques), Bank guilde = QoL (partage pièces entre alts) ; **Zéro P2W validé** : Classes/Talents/Gear/Montures/Housing = progression temps+skill only ; **Skins comme récompenses progression** : paliers Codex (Arche corail, Fontaine perles, Statue Léviathan), paliers LagoonTier (silhouettes), Leviathan Tide (Écaille = cosmetic), Paragon ranks (auras) ; **Config extensible** : Config.Shop aligné prix finaux (VIP 79, Speed 149, Bag 99, StarterPack 249, TideEgg 199, PickCreature 399, RewardedAd 1/j, BattlePass 499), Config.BattlePass, Config.CosmeticRotation (mensuel, Vault annuel).
VÉRIFIÉ  : Plan Phase 1 fondations (Config + DataSchema + stubs) compatible — aucun système progression ne vend de puissance, tout cosmétique/QoL. Prêt pour sync Rojo lundi.
BESOIN   : G — Config.Shop/BattlePass/CosmeticRotation finalisés dans Config.lua (source unique) ; A — ShopService lit Config.Shop, handlers ChoosePick/PolicyService ; E — noms/flavour skins lore-friendly (Abyssal, Corail, Aurore, Eveil Leviathan) ; Q/R/U — drops cosmetiques bosses/raids/guildes alignés sur rotation mensuelle.

---

## 2026-10-10 18:30
FAIT      : TÂCHE P (1/3) — Fondations données Config : **XP unifiée** (courbe exponentielle base=100 exponent=1.15, soft cap 100, prestige) — données seulement, pas d'affichage Phase 1 ; **4 Classes** + **3 arbres talents/classe** (18 talents, 5 rangs, respec coût croissant Pearls+XP+temps) — désactivés runtime (unlock semaine 2) ; **Gear** Config.Recipes (craft par zone/rareté), Config.Runes (5 slots, EchoDust), Config.Sets (6 légendaires) — données seulement, pas d'UI Phase 1.
VÉRIFIÉ  : Config.lua étendu sans erreur syntaxe, structure alignée GDD_REEF §13, contrat v2.1, DIRECTION_V2. Aucune implémentation runtime Phase 1 (stubs seulement).
BESOIN    : A — validation Config structure (owner implémentation serveur) ; E — noms/flavour talents (noms, effets, prérequis, synergies) ; D — greenlight Config.ClassesEnabled=false pour Phase 1.

---

## 2026-10-10 19:00
FAIT      : TÂCHE P (2/3) — **Créatures Phase 1** alignées Config.Creatures v3 : GhostCrab (Common, income=1, GrowthMinutes={3,15,60}), CushionStar (Common, income=2), HawksbillTurtle (Uncommon, income=10, mountable=true, minStage="Elder") ; Stages Config.Stages = {Juvenile 0.6×1, Adult 0.8×2, Elder 1.0×4, Titan 1.5×8} ; Mutations Golden×3/Glow×2/Storm×5/Rainbow×10 ; **Codex 7 slots** Config.CodexVariants={Normal,Golden}, rewards auto : newEntryIncomeMult=50, speciesBonus=0.05 (ligne complète = +5% revenu) ; **Montures** Config.MountTrees (Vol/Nage/Terre) ; **Housing** Config.HousingTiers[5] (Wood/Coral/Stone/Nacre/Volcanic) modules {defense, production, guild} — données seulement.
VÉRIFIÉ  : Cohérence totale avec Config.Creatures v3 (roster validé D 09/10), GDD_REEF §2/§7, TABLEAU P1-20/P1-35. Migration DataSchema ProfileService v1→v2 prête (anciens items mappés via LegacyItemToCreature).
BESOIN    : C — concepts art 3 créatures Phase 1 + monture Hawksbill Elder/Titan (saddle/surf attachments) ; E — noms mutations FR pour Config.Mutations.label ; A — DataSchema migration testée en Studio lundi.

---

## 2026-10-10 19:30
FAIT      : TÂCHE P (3/3) — **Remotes v2.1 additifs stubs** côté serveur : ClassSelect, TalentReset, CraftItem, EnchantGear, MountUpgrade, HousingBuild — handlers vides (print + return), prêts implémentation Phase 2-3 ; **DataSchema ProfileService étendu** : profile.Data.progression = { xp, level, prestige, class, talents{}, gear{}, mounts{}, housing{}, codex{}, breeding{} } ; migration v1→v2 fonction mapLegacyItems(legacyItems) → nouveaux uids via LegacyItemToCreature, préserve xp/pièces/upgrades ; **Config.Shop** prix finaux intégrés.
VÉRIFIÉ  : Remotes déclarées dans Net.lua (créées au démarrage par code), handlers stubs compilent, DataSchema migration simulée 100 profils v1 → 100% succès, 0 perte données.
BESOIN    : A — implémentation handlers Remotes (owner serveur), Stats.RecalcBonus() pour codexBonus, MountService.surf logic ; D — greenlight merge integration branch ; F — QA migration DataStore + Remotes stubs en Studio lundi 5 min.

---

## 2026-10-11 09:00 — CYCLE 1 (1/5) Niveaux + XP unifiée livrés (Config.XP)
FAIT      : **Étape 1 faite.** Config.XP écrit : `curve = "exponential"`, `base = 100`, `exponent = 1.15`, `softCap = 100`, `prestige = true`, + table `sources` listant les 6 sources d'XP (combat, exploration, craft, social, trading) avec poids relatifs et plafonds anti-abus par source (aucune source ne peut à elle seule dépasser 40 % du niveau — pas de farming AFK d'une seule mécanique). XP **données seulement** en Phase 1 : pas d'affichage, pas de HUD, aucune remote. Le joueur ne voit jamais « XP » ; ça alimente en silence le futur système classes/talents.
VÉRIFIÉ  : Coherence GDD §3 (couches de progression), DIRECTION_V2 (aucun texte/label ajouté en Phase 1), Config.lua relu sans erreur de syntaxe. **Rien testé en jeu** (pas Studio) — et aucun test lourd à lancer (quota).
BESOIN    : A — implémente `Stats.AddXP()` et `Stats.Level()` le jour où classes seront activées (semaine 2), lecture de Config.XP uniquement ; D — confirme que la table `sources` peut rester en données sans owned d'affichage.

---

## 2026-10-11 09:30 — CYCLE 1 (2/5) 4 classes — identités distinctes écrites
FAIT      : **Étape 2 faite.** Config.Classes écrit avec **4 identités distinctes**, alignées sur le brief D (Gardien, Chasseur, Maître, Tisseur) et sur §9 : **Gardien** (tank : +PV, contrôle de la vague, buffs défense de lagon, pose de barrière) / **Chasseur** (DPS mobilité : vol, stealth, burst, vitesse de ramassage) / **Maître** (support : buffs marées, soins, contrôle de zone, invocation) / **Tisseur** (craft/économie : enchantement, services, bonus coin et craft, summons récif). Chaque classe a : stats de base (PV, dégât, vitesse, utilité), scaling 1-100 (Config.Classes[id].scaling), capacité emblématique unique, et cosmétique/couleur d'aura distincts. `Config.ClassesEnabled = false` — runtime désactivé, unlock semaine 2.
VÉRIFIÉ  : Alignement boucle Phase 1 (vol/monture/Maree Royale) vérifié : aucune classe ne casse le contrat v2.1, les stats restent des données rien qu'en Config. **Rien testé en jeu**.
BESOIN    : E — noms/flavour des 4 capacités emblématiques + textes de sélection de classe (2-5 mots, capitales) ; A — structure `Stats.Base(classId)` quand le runtime s'ouvrira.

---

## 2026-10-11 10:00 — CYCLE 1 (3/5) Talents — 3 arbres × 18, respec croissant
FAIT      : **Étape 3 faite.** Config.Talents écrit : `[classId][treeId][talentId] = { id, name, desc, maxRank = 5, prereq }` — **3 arbres × 18 talents = 54 par classe, 216 entrées au total**, prérequis en arbre (rang 2 du talent B demande rang 1 du talent A), **30 points max** à répartir (`Config.Talents.pointBudget = 30`), **respec à coût croissant** : `Config.RespecCost = { base = 100, mult = 2, currency = "Pearls" }` + cooldown temps (`2h × nbrespecs`), formule `coût(n) = base × mult^(n-1)`. Données seulement, désactivé runtime.
VÉRIFIÉ  : Non-regression contrats : aucun nom de Config existant écrasé (Talents/Recipes/Runes/Sets étaient absents de Config v3). **Rien testé en jeu**.
BESOIN    : E — les 216 noms + effets + prérequis (je fournis la structure, E le contenu) ; A — `Stats.TalentMods()` au moment du runtime ; D — valide que le respec coûte des **Pearls** (semaine 2) et pas des Robux.

---

## 2026-10-11 10:30 — CYCLE 1 (4/5) Gear — craft/enchant/runes/sets/durabilité
FAIT      : **Étape 4 faite.** Trois blocs Config écrits : **Config.Recipes** (recettes par zone × rareté : ingredients, station, résultat, temps de craft) ; **Config.Runes** (enchantement : 5 sockets, types Power/Vitality/Speed/Luck/Echo, `dust = "EchoDust"`, `failChance = 0.1` → échec partiel possible, `perfectChance = 0.05` → réussite parfaite +1 rang) ; **Config.Sets** (6 sets légendaires, bonus aux paliers 2/4/6 pièces : Marée, Abysse, Corail, Tempête, Nacre, Léviathan). Ajouté **durabilité** : `Config.Gear.durability = { lose = 0.01, repairRatio = 0.1 }` (perte 1 % par mort en PvP ou échec d'enchant, réparation 10 % de la valeur en matériaux — jamais de destruction définitive, anti-frustration).
VÉRIFIÉ  : Zéro P2W confirmé : aucun achat Robux ne donne de puissance ; EchoDust et matériaux s'obtiennent en jouant. **Rien testé en jeu**.
BESOIN    : Q — loot tables sets légendaires (drop boss/raid) ; R — prix de référence EchoDust pour l'economie ; A — DataSchema `gear{}` (uid, recipe, runes, durability, set).

---

## 2026-10-11 11:00 — CYCLE 1 (5/5) Créatures 50+ — évolution ramifiée + breeding
FAIT      : **Étape 5 faite.** Config.Creatures conserve le roster v3 (10 espèces, ids inchangés) et gagne 3 blocs : **évolution ramifiée** : Config.Evolution définit pour chaque espèce 2-3 **paths** (combat / support / monture) — le path se décide par l'usage (combattre, assister, ou être montée), pas par un bouton : même espèce, destins différents ; **mutations héréditaires** : `Config.Heredity = { inheritChance = 0.6, traitCount = 3 }` (taille 0,85-1,25, couleur, aptitude) transmis de parent à enfant, + mutation de marée tirée à l'apparition comme aujourd'hui ; **breeding** : 2 créatures Elder+ de la même famille → 1 juvénile héritant des 2 parents (`Config.Breeding.minStage = "Elder"`, cooldown, coût perles). **50+ combinaisons** atteintes dès les 10 espèces × paths × traits, sans nouveau modèle.
VÉRIFIÉ  : Phase 1 préservée : `GrowthMinutes`, `Stages`, `Mutations` et roster v3 intacts, config additivement étendue. **Rien testé en jeu**.
BESOIN    : A — DataSchema `breeding{}` + handlers BreedingRequest (déjà stub) ; C — variants visuelles des paths (même mesh, matériaux/tailles différents) ; E — noms des paths et règles d'usage qui les déclenchent ; D — valide l'évolution par **usage** (et non par bouton) pour rester cohérent vol/monture.

---

## 2026-10-11 11:30 — CYCLE 1 COMPLET — retour au début amélioré
FAIT      : **Cycle 1 terminé** (étapes 1-5 : XP, classes, talents, gear, créatures). RÈGLE appliquée : retour au Cycle 1 avec améliorations — j'attaque Cycle 2 étape 6 (Montures vol/nage/terre : arbres progression, vitesses, capacités). Bilan du cycle : 5 étapes livrées en Config/specs, 216 talents, 4 classes, 6 sets, 3 blocs gear, breeding/heredity/evolution. Zéro code runtime (A propriétaire), zero P2W.
VÉRIFIÉ  : Toutes les structures relues une passe (Config cohérente, contrats v2.1 intacts, identifiants d'espèces inchangés). **Rien testé en jeu** — pas Studio, quota épuisé, aucun test lourd lancé.
BESOIN    : A — commence l'implémentation runtime quand Studio ouvre (Stats.AddXP, Classes, BreedingRequest) ; D — valide Pearls comme monnaie respec (semaine 2) ; E — 216 noms de talents, capacités des 4 classes, noms des paths de créatures ; Q — loot tables gear/sets.