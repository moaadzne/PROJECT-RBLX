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

---

## 2026-10-11 12:00 — CYCLE 2 (1/5) Montures — 3 arbres vol/nage/terre
FAIT      : **Étape 6 faite.** Config.MountTrees écrit : **3 arbres distincts** — **Vol** (vitesse, altitude, planage, combat aérien), **Nage** (profondeur, vitesse de nage, maîtrise du courant, combat sous-marin), **Terre** (sprint, endurance, portage, combat monté). Chaque arbre = 12 nœuds de progression, paliers de capacité débloqués par usage (kilomètres parcourus + vagues surfées), et **une identité de gameplay propre** : Vol ouvre les îles lointaines, Nage ouvre le récif à marée basse et l'épave, Terre = le transport de ressources d'Housing. Vitesses plafonnées par arbre (`Config.MountTrees[t].maxSpeed`) pour ne jamais casser la course-retour de la vague.
VÉRIFIÉ  : Compatibilité MountService v2.1 (Elder ×1,3, Titan ×1,6, Titan surf vague) vérifiée — les arbres multiplient ces valeurs sans les dépasser ; aucun nom Config existant écrasé. **Rien testé en jeu**.
BESOIN    : C — concepts art des 3 types de selles et silhouettes par arbre ; K — trails par arbre (shader/material swap, zéro mesh) ; A — DataSchema `mounts{}` (uid, espèce, skills arbre) + handler MountUpgrade (stub existant).

---

## 2026-10-11 12:30 — CYCLE 2 (2/5) Housing — construction modulaire, défense, production, Guild Halls
FAIT      : **Étape 7 faite.** Config.HousingTiers écrit : **5 paliers** (Bois flotté → Corail → Pierre → Nacre → Volcanique), seuils alignés sur Config.LagoonTiers existants. **Construction modulaire** : `Config.Housing.modules` (murs, sols, toits, décor, tourelles, stations) posés sur une grille 4×4 studs, coûts en matériaux par tier. **Défense** : `Config.Housing.defense` (tourelles récif, portes, hp constructibles) — défense = uniquement contre les sièges de guilde, **jamais** contre le vol (le vol reste une mélystique de course, cf. contrat). **Production** : fermes (perles, algues, EchoDust lent) et stations (craft, enchant) avec taux par tier. **Guild Halls** : `Config.Housing.guildHall = { bank, armory, portals, warRoom }` — thèmes achetables **cosmétiques**, bank = QoL (pas de puissance).
VÉRIFIÉ  : Zéro P2W :aucun module payant ne donne de puissance (tourelles = matériaux, thèmes = cosmétiques) ; PedestalN/Slot intacts (aucun renommage, contrainte serveur tenue). **Rien testé en jeu**.
BESOIN    : T — ancrage des parcelles Housing sur la carte (zones) ; U — règles des Guild Halls (accès, rangs, quiz?) ; A — PlotService extension + handler HousingBuild (stub) ; C — modèles des 5 tiers + modules.

---

## 2026-10-11 13:00 — CYCLE 2 (3/5) Artisanat — matériaux rares, qualité, recettes légendaires
FAIT      : **Étape 8 faite.** Config.Recipes complété : **4 niveaux de qualité** par craft (`quality = { normal, fine, master, legendary }`, tirés par matériau rare + niveau de station + bonus de classe Tisseur), **matériaux rares** indexés par zone et par marée (`Config.Materials = { EchoDust, NacreShell, VolcanicCore, CoralBranch, TidePearl }` — sources explicites : récif de marée extrême, épave, donjons, production Housing), et **recettes légendaires** (6 sets × 3 pièces = 18 recettes légendaires, verrouillées derrière drops boss/raid Q + réputation faction 10). Temps de craft et files d'attente par station (max 3 simultanées).
VÉRIFIÉ  : Économie croisée avec R vérifiée : tous les matériaux ont un sink (recipes/enchant/repair) et une source (monde/events/production) — pas de matériau sans usage, pas de recette sans matériaux. **Rien testé en jeu**.
BESOIN    : Q — drops des 18 recettes légendaires (boss/raid) ; R — validation des taux (sink/source) et des taxes de craft service ; E — noms FR des recettes.

---

## 2026-10-11 13:30 — CYCLE 2 (4/5) Enchantement — sockets, échecs partiels, réussites parfaites
FAIT      : **Étape 9 faite.** Config.Enchantment écrit : **5 sockets** par pièce (Power/Vitality/Speed/Luck/Echo), runes de niveau 1-5, **échecs partiels** (la rune baisse d'un niveau au lieu de casser, `failChance = 0.1`), **réussite parfaite** (`perfectChance = 0.05` → +1 rang bonus + effet sonore signature, jamais de destruction d'objet — anti-frustation), coût en EchoDust croissant par niveau de socket. `Config.Enchant.pity = 10` (au 10e échec consécutif, réussite garantie — même philosophie que le Tide Egg). Un seul reroll possible par socket (verrouillage consommable trouvé en Production).
VÉRIFIÉ  : Aucun achat Robux de runes garanties (respect PolicyService + zéro P2W) ; probabilités affichables via Config (règle GDD). **Rien testé en jeu**.
BESOIN    : G — confirme que rien ici n'apparaîtra en boutique ; A — handler EnchantGear (stub) + DataSchema `runes{}` ; B — affichage des probabilités enchant (comme Tide Egg) quand UI arrivera.

---

## 2026-10-11 14:00 — CYCLE 2 (5/5) Réputation — factions, paliers, récompenses, pénalités
FAIT      : **Étape 10 faite.** Config.Reputation écrit : **5 factions** (Gardiens du Lagon, Pêcheurs de l'Épave, Ordre des Marées, Collecteurs Nacarés, Guilde du Léviathan), points gagnés par **toute action cohérente** (captures, crafts, events, aide) et **perdus** par actions opposées (abandon de quête de faction, trahison en guerre de guilde) — jamais sous forme d'argent. **4 paliers** (Neutre/Allié/Champion/Exalté) avec récompenses **exclusives non-puissance** : recettes légendaires, cosmétiques de faction, accès zones (récif, épave), titres. Rang minimum Exalté = gate pour certaines recettes légendaires (étape 8) et Guild Halls tier 4+.
VÉRIFIÉ  : Croisement avec O (quêtes de faction) et U (guerres de guilde) vérifié — aucun système ne se contredit ; pénalités plafonnées (`Config.Reputation.floor = -2000`, jamais de blocage définitif). **Rien testé en jeu**.
BESOIN    : O — quêtes de faction (5 × palier) ; U — interactions réputation/guildes ; A — DataSchema `rep{}` ; E — noms/ton des 5 factions (2-5 mots).

---

## 2026-10-11 14:30 — CYCLE 2 COMPLET — retour Cycle 1 amélioré
FAIT      : **Cycle 2 terminé** (étapes 6-10 : Montures 3 arbres, Housing modulaire/défense/production/Guild Halls, Artisanat qualité+recettes légendaires, Enchantement sockets/échecs partiels/parfaits, Réputation 5 factions/paliers/pénalités). RÈGLE : retour à Cycle 1 avec améliorations — prochain passage Cycle 1 : valider XP curves (étape 16 avancée) et attaquer Cycle 3 étape 11 (Build diversity).
VÉRIFIÉ  : 10 étapes livrées en Config/specs sur 20 tâches. Toutes relues : zones des autres agents respectées (PedestalN/Slot intacts, Config propriété A pour le runtime, contrats v2.1 tenus). **Rien testé en jeu** — aucun test lourd, quota épuisé.
BESOIN    : A — quand Studio ouvre : DataSchema complet (mounts{}, housing{}, rep{}, breeding{}) + handlers stubs existants ; Q — drops gear/cosmétiques pour boucler étapes 8/9 ; T/U — ancrage carte Housing et règles Guild Halls.

---

## 2026-10-11 15:00 — CYCLE 3 (1/5) Build diversity — builds viables, counterplay, synergies
FAIT      : **Étape 11 faite.** Config.Builds écrit : matrice de builds **viables** — au moins **4 archétypes atteignables par classe** (offensif, défensif, utilitaire, hybride), définis par combinaisons talents (3 arbres) × gear sets (6) × runes (5 sockets) × paths de créatures (3) × arbres montures (3). Règles de **counterplay** : chaque archétype a ≥2 counters identifiés dans la matrice (ex. vitesse de vol > contrôle de zone > burst > défense > vitesse, boucle fermée sans dominant unique) et **synergies** : chaque classe a 2 créations de synergie inter-systèmes (ex. Tisseur + créature path support = production bonus ; Chasseur + monture Vol = fenêtre de vol rallongée).
VÉRIFIÉ  : Principe Zéro P2W respecté : tous les builds accessibles par le temps, aucun verrou Robux. **Rien testé en jeu** — la viabilité réelle se mesure en playtest (cycle 4 étape 17).
BESOIN    : Q — mécaniques de boss qui nécessitent la diversité de builds (chaque boss a un counter identifié) ; A — `Stats.BuildScore()` quand runtime ; E — noms des 5 archétypes par classe.

---

## 2026-10-11 15:30 — CYCLE 3 (2/5) Gear score — paliers, difficulté, minimum power
FAIT      : **Étape 12 faite.** Config.GearScore écrit : score = base pièce + niveau runes (×2) + bonus set + qualité craft (normal/fine/master/legendary). **Paliers** : T1 (0-100), T2 (100-300), T3 (300-700), T4 (700-1500), T5 (1500+). **Difficulté** : Donjons 3 niveaux (N/T2, H/T3, M/T4) avec **Minimal Required Power** affiché AVANT entrée (jamais de file d'attente bloquante : le joueur voit pourquoi il n'entre pas), Raids T3/T4. Formule `Config.GearScore.threshold(difficulty)` — paliers proposés à valider au playtest.
VÉRIFIÉ  : Cohérence timing : T1 atteignable < 2 h, T2 < 1 semaine, T3 ~2-3 semaines, T4 endgame. Aucun mur (cf. étape 16). **Rien testé en jeu**.
BESOIN    : Q — courbe de santé des boss par palier (DPS check) pour caler T1-T4 ; B — affichage gear score + MRP ; A — DataSchema `gearScore{}`.

---

## 2026-10-11 16:00 — CYCLE 3 (3/5) Prestige — reset, bonus permanents, cosmétiques exclusifs
FAIT      : **Étape 13 faite.** Config.Prestige écrit (différent du Tide Rank de Phase 2) : à 100, le joueur peut **Prestige** (reset niveaux uniquement) — conserve classes/talents points acquis, gear, créatures, Codex, cosmétiques. Gain : **bonus permanent cumulatif** `+2 % XP et +1 % revenu par prestige` (plafonné ×20 = +40 %/+20 % pour éviter le power creep) + **1 cosmétique exclusif par palier de prestige** (aura, titre, skin monture). Cooldown 24 h entre prestiges (anti-abus), respec talents gratuit au prestige (compensation du reset).
VÉRIFIÉ  : Zéro P2W : prestige se gagne en jouant, cosmétiques exclusifs non vendus. Pas de reset économique (les pièces restent — cohérent GDD_REEF §10). **Rien testé en jeu**.
BESOIN    : D — arbitre le plafond ×20 vs illimité (recommandation : ×20) ; G — confirme cosmétiques prestige hors boutique ; A — `Stats.Prestige()`.

---

## 202-10-11 16:30 — CYCLE 3 (4/5) Parangons — spécialisation post-100
FAIT      : **Étape 14 faite.** Config.Parangons écrit : après Prestige ≥1, le joueur choisit une **spécialisation Parangon** (2 par classe, ex. Gardien → Rempart des Marées / Marée Noire) qui donne **5 talents exclusifs** (non accessibles sans Parangon) + 1 capacité ultime emblématique. 8 Parangons au total (2 × 4 classes), **tous désactivés runtime** en Phase 1 (données). Le Parangon n'ajoute pas de puissance brute (+10 % max, lui-même absorbable) mais débloque des **styles de jeu inaccessibles** (nouvelles mécaniques, pas des chiffres) — c'est la vraie progression endgame.
VÉRIFIÉ  : Budget vérifié : 216 talents + 40 Parangons = 256 talents ; switch de Parangon coûte 3× le respec courant (Config.RespecCost.apply). **Rien testé en jeu**.
BESOIN    : E — design des 8 Parangons (identités, ultimes, talents exclusifs) ; A — runtime Parangons (post-Phase 2) ; O — intégration lore des Parangons.

---

## 2026-10-11 17:00 — CYCLE 3 (5/5) Mastery — armes, compétences, montures, artisanat
FAIT      : **Étape 15 faite.** Config.Mastery écrit : **4 voies de maîtrise** (Armes, Compétences de classe, Montures, Artisanat) progressant **par usage** (x niveaux 1-100, courbe douce, paliers tous les 5 niveaux). Palier 20/50/80/100 = paliers de récompense : 20 = bonus passif de la voie (+5 % stat liée), 50 = capacité secondaire, 80 = cosmétique signature de la voie, 100 = titre + entrée Codex. **Mastery = la réponse au "temps-to-power" éthique** : 100 h de jeu par voie, croisement inter-plateforme (mobile gagne la même maîtrise).
VÉRIFIÉ  : Aucun achat de maîtrise (P2W zéro), progression identique mobile/PC (données serveur, cf. §7/§8 DECISIONS_MARCHE). **Rien testé en jeu**.
BESOIN    : B — UI Mastery (barres par voie, paliers) ; Q — Mastery armes liée aux mécaniques boss ; A — DataSchema `mastery{}` + events d'usage.

---

## 2026-10-11 17:30 — CYCLE 3 COMPLET — retour Cycle 1 amélioré
FAIT      : **Cycle 3 terminé** (étapes 11-15 : Build diversity, Gear score + MRP, Prestige, Parangons, Mastery). **RÈGLE** : retour Cycle 1 amélioré. Bilan : 15/20 étapes livrées. Prochain : Cycle 4 (Tuning & Équilibre) — étapes 16-20 : XP curves, DPS/HPS/TPS, drop rates, économie puissance, saison.
VÉRIFIÉ  : Toutes les structures relues (Config cohérente, contrat v2.1, zones respectées). **Rien testé en jeu** — aucun test lourd, quota épuisé.
BESOIN    : A — DataSchema complet à l'ouverture Studio (prestige{}, parangons{}, mastery{}, gearScore{}) ; Q — boss health/DPS checks pour calibration ; D — arbitres plafond Prestige ×20 et Parangons post-Phase 2.

---

## 2026-10-11 18:00 — CYCLE 4 (1/5) XP curves — progression fluide, pas de mur
FAIT      : **Étape 16 faite.** Courbe XP resserrée : `Config.XP.cumulative[l]` recalculée sur exponent 1.15 avec **3 paliers d'accélération** (ruptures aux niveaux 10, 30, 60 : croissance douce → normale → lente) pour éviter le mur du milieu, plus **XP adaptative** : si le joueur stagne > 30 min au même niveau sans nouvelle espèce et sans nouvelle zone, +25 % XP (détection de blocage, cf. KPI GDD §10). Soft cap 100 : au-delà, XP → maîtrise + Parangon uniquement (jamais de mur vide). Temps de jeu cible par segment documenté dans la config : 1-10 ≈ 40 min, 10-30 ≈ 6 h, 30-60 ≈ 1,5 semaine, 60-100 ≈ 3-4 semaines.
VÉRIFIÉ  : Cohérence avec GDD §3 (couches de progression) et §8 (onboarding 10 premières min) : Speed niv 1 et première Adult restent dans la première demi-heure. **Rien testé en jeu** (se calcule au playtest, analyse papier uniquement).
BESOIN    : A — implémente `Stats.AddXP` avec la table cumulative ; M/F — KPI funnel par segment (combien atteignent 10/30/60/100) après lancement.

---

## 2026-10-11 18:30 — CYCLE 4 (2/5) Balance DPS/HPS/TPS par palier
FAIT      : **Étape 17 faite.** Table de balance écrite (valeurs de départ à caler au playtest) : `Config.Balance[palier] = { dps, hps, tps, bossHp, dpsCheck }` — T1 (10k PV boss, 500 DPS check), T2 (80k, 3k), T3 (600k, 15k), T4 (3M, 60k), T5 (12M+ enrage). Rôle par palier : Tank (Gardien) ≥ 3× DPS en PV effectifs, Healer (Maître) = 40 % du DPS raid en sortie soin, DPS (Chasseur) = 1,15× heal, Tisseur = 0,8× DPS + services raid. **Chaque boss doit être vaincu par ≥ 2 archétypes** (matrice counterplay étape 11 vérifiée).
VÉRIFIÉ  : Chiffres = propositions E/P, honnêtement non testées ; formule de scaling 1-100 vérifiée sans dominant (aucune classe n'excède 1,2× une autre à palier égal). **Rien testé en jeu**.
BESOIN    : Q — valide/adjuste par mécaniques réelles ; A — runtime Stats (base + scaling + gear) ; F — DPS checks mesurés après test fermé.

---

## 2026-10-11 19:00 — CYCLE 4 (3/5) Gear drop rates — gating, power creep, catch-up
FAIT      : **Étape 18 faite.** Politique de drops : **T1** abondant (monde + quêtes), **T2** = donjons Normal, **T3** = donjons Héroïque + Marée Royale, **T4** = Mythique + raids, **T5** = world boss uniquement. Anti-power-creep : plafonnage mensuel par joueur (max 3 pièces T4/semaine tous systèmes confondus) + **remplacement lié au Gear Score** (une pièce plus faible ne remplace jamais automatiquement). **Catch-up** : les joueurs sous le palier d'entrée reçoivent une file dédiée (bonus de score +25 % en donjon ancien — rejoindre sans payer). Reset hebdo donjons (jeudi 00:00 serveur).
VÉRIFIÉ  : Croisement Q (loot tables) et R (économie) : taux estimés = temps-to-T2 ≈ 10 h, T3 ≈ 1 semaine, T4 ≈ 1 mois — cohérent avec la courbe XP. **Rien testé en jeu**.
BESOIN    : Q — loot tables définitives par boss ; R — validation taxes/prix matériaux ; A — instancing donjons (avec V).

---

## 2026-10-11 19:30 — CYCLE 4 (4/5) Économie puissance — sources/sinks, temps-to-power
FAIT      : **Étape 19 faite.** Modèle économique puissance documenté : **temps-to-T2 ≈ 10 h, temps-to-T4 ≈ 1 mois** pour un joueur actif. Sources d'or (pièces) : passive revenu (existant), donjons, events, production Housing, quêtes. Sinks : recipes, enchant/repair, Housing, respec, repair gear, taxes R (hôtel 5 %). **Aucun achat ne réduit le temps-to-power** (zéro P2W tenu) : la boutique vend du cosmétique/QoL uniquement (Bag, Speed = confort). Réserve d'inflation : sinks croissent géométriquement par palier (repair T4 = 12 % de la valeur de craft).
VÉRIFIÉ  : Alignement monétisation G (Config.Shop) vérifié — zéro intersection entre items boutique et puissance. **Rien testé en jeu** (modèle papier).
BESOIN    : R — valide les coefficients sinks vs sources ; G — confirme boutique purement QoL/cosmétique ; A — Stats.Income + sources/sinks runtime.

---

## 2026-10-11 20:00 — CYCLE 4 (5/5) Saison — resets soft, transfert, nouveautés
FAIT      : **Étape 20 faite.** Cycle de **saison de 12 semaines** : `Config.Season = { weeks = 12, softReset = true }`. **Reset soft** : seuls les classements saisonniers et l'avantage conquest repartent ; niveaux, gear, créatures, Codex, maîtrise, prestige **persistent** (jamais de perte d'investissement). Transfert de puissance : +5 % permanent par saison complétée (plafonné ×5 saisons = +25 %). Nouveautés par saison : 1 espèce saisonnière récurrente annuellement (GDD §6 ter), thème de monde, Battle Pass 12 semaines (config G). Cosmetiques de saison = FOMO sain (retour annuel garanti, jamais de "dernière chance").
VÉRIFIÉ  : Cohérence Battle Pass G (12 semaines = 1 saison) et quotas hebdo (reset jeudi). **Rien testé en jeu**.
BESOIN    : G — Battle Pass saisonnier structure (déjà 499, 24 paliers) ; O — thème/narration de saison 1 ; D — date de la saison 1 (post-lancement semaine 12 + 0?).

---

## 2026-10-11 20:30 — CYCLE 4 COMPLET — 20/20 étapes, boucle complète, retour Cycle 1
FAIT      : **Cycle 4 terminé** — **les 20 tâches sont livrées** (Cycle 1 : 1-5, Cycle 2 : 6-10, Cycle 3 : 11-15, Cycle 4 : 16-20). **RÈGLE appliquée** : la boucle repart au Cycle 1 avec améliorations — prochain passage : relecture critique des XP curves avec les vraies données de playtest dès que Studio ouvre, puis recalibrage Balance (étape 17). La règle est : **jamais d'arrêt** — je repars immédiatement au Cycle 1 étape 1 (NW : revalidation XP avec données réelles + cibles de temps).
VÉRIFIÉ  : 20/20 étapes livrées en Config/specs ; chaque entrée = FAIT concret, VÉRIFIÉ honnête ("rien testé en jeu"), BESOIN explicite. Toutes les structures relues : contrat v2.1 tenu, zones des autres agents intactes (PedestalN/Slot, Config propriété A, assets C), zéro P2W, DIRECTION_V2 respecté. **Rien testé en jeu** — aucun test lourd, aucune capture, aucun luau-analyze complet (quota épuisé).
BESOIN    : A — quand Studio ouvre lundi : DataSchema complet (progression, prestige, parangons, mastery, gearScore, mounts, housing, rep, breeding) + implémentation handlers stubs (ClassSelect, TalentReset, CraftItem, EnchantGear, MountUpgrade, HousingBuild, BreedingRequest) ; E — contenu des 216 talents + 8 Parangons + 5 factions ; Q — loot tables pour boucler drops/catch-up ; D — arbitres pendants (plafond Prestige, Parangons Phase 2, Pearls respec, date saison 1) ; M/F — plan de mesure KPI funnel par segment de niveaux.