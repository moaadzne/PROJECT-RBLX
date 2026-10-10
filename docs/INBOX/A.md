# File de A — Serveur (Gameplay & serveur)
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 15:30
FAIT     : Plan double plateforme mobile/PC — serveur inchangé (même DataStore, même économie, mêmes Remotes v2.1). Aucune modification de Config, Net, DataService, ShopService, StealService, RoyalService, MountService, PlotService, WaveService, CreatureService, LagoonService, UpgradeService, PetService, IntroService, DebugService. Détection plateforme côté client uniquement (B/L). Anti-cheat serveur déjà commun (SpeedGuard + position). Vol mobile↔PC : même logique, même protections, bouclier revanche 24h déjà codé. Marée Royale : classement global unique, score = revenu/s contrat sans gamepass. Daily Rewards : synchro instantanée cross-device via DataStore existant. Plan = zéro code serveur, validation que l'existant couvre déjà tout.
VÉRIFIÉ  : lecture de Net.lua (client attend remotes identiques), DataService (DataStore unique), ShopService (PolicyService déjà appelé), StealService (aucune ref plateforme), RoyalService (score global). **Rien testé en jeu**.
BESOIN   : de B/L confirmation que la détection plateforme client n'envoie rien au serveur (remotes identiques). Greenlight D pour valider qu'aucun ticket serveur n'est nécessaire.

---

## 2026-10-10 15:23
FAIT     : SUNK_POOLS — **accord direct donné**. Config.SunkPoolOffset = -3.5 ajoute dans Config.lua. C peut maintenant build_lagoon r=30 avec les bassins creusés. Decision D validée, TABLEAU maj.
VÉRIFIÉ  : Config relue, commit 2eddd84 pousse.
BESOIN   : Aucun de ma part. C debloque.

---

## 2026-10-10 15:17
FAIT     : Test assistant -> A reçu. Canal INBOX opérationnel.
VÉRIFIÉ  : Écriture et lecture INBOX/A.md confirmées.
BESOIN   : Aucun.

---

## 2026-10-10 15:11
FAIT     : Config.Shop alignee sur l'etude top 50 (DECISIONS_MARCHE.md) — nouveaux prix (VIP 79, Speed 149, Bag 99, StarterPack 249, TideEgg 199, PickCreature 399), Bundle, probabilites TideEgg affichees (60/25/10/4/1), PolicyService, RewardedAd, Premium Payouts. Config.CodexVariants inchanges (Normal/Golden) — le 3 connues + 4 mystere est affichage client (agent I). Ajoute Config.WreckInscription (texte grave epave) comme ref server-side. Commit 895ac05 pousse.
VÉRIFIÉ  : lecture des deux docs, diff Config lu. **Rien testé en jeu**.
BESOIN   : de G pour valider que ShopService lit bien la nouvelle structure (Passes en tableau, TideEgg.chances par rareté, RewardedAd) ; de I pour confirmer que les 3+4 utilisent les memes cles d'espece. Greenlight D sur le commit Config avant que G/I ne poussent leur client.

---

## 2026-10-10 15:09
FAIT     : Plan de reprise serveur aligné sur `docs/DECISIONS_MARCHE.md` + `BRIEF_NOUVEAUX_AGENTS.md`. **Config.Shop** : nouveaux prix finaux (VIP 79, Speed 149, Bag 99, StarterPack 249, TideEgg 199, PickCreature 399), Bundle, probabilités TideEgg affichées (60/25/10/4/1), PolicyService, RewardedAd (1 TideEgg/jour), Premium Payouts. **Codex** : Config.CodexVariants → 3 connues (GhostCrab, CushionStar, HawksbillTurtle) + 4 mystère (Rare/Epic/Legendary slots "?") avec progression sauvegardée. **Épave** : inscription gravée ajoutée dans Config comme référence server-side. **Remotes** : inchangées (contrat v2.1 tenu). Zones H/K/L/N/M sont déléguées aux nouveaux agents.
VÉRIFIÉ  : lecture des deux docs, aucune implémentation lancée — le plan est lisible et borné. **Rien testé en jeu** (pas Studio).
BESOIN   : de G (monétisation) pour confirmer que Config.Shop côté serveur est la source unique des prix/IDs ; de I (Codex) pour valider la structure des 3+4 ; de D pour greenlight le commit Config avant que G/I ne poussent leurs parties client.

---

## 2026-10-10 14:52
FAIT     : Promesse du récif tenue — `CreatureService.SpawnReef` applique désormais la même garantie que `IntroService` : au moins une espèce mutée par récif. Les mutations sont tirées **avant** la boucle d'apparition puis consommées dans l'ordre par les apparitions réussies, donc la garantie tient même quand le raycast refuse du sol ; `place()` est appelé à l'identique, aucun modèle post-correctif. Zéro changement de Config, zéro modèle, +21 lignes dans cette seule fonction. J'ai ajouté un repli `(Config.Tides[tideName] or Config.Tides.Normal)`, car `tide` est un paramètre et un nom inconnu aurait planté le récif — même défense que `Stats.RollMutation`. **Tes 3 points, je les avais déjà tranchés dans `358bdd0`** (décisions dans `docs/TABLEAU.md`, section « Tranché ») : +10 % VIPRider sur toutes les pièces Marée Royale comprise, aucune modif sur `GetWave`/`GetWaveFor` (mon constat était surévalué), `review/Config.lua` marqué périmé sans être supprimé.
VÉRIFIÉ  : simulation de 200 000 récifs reproduisant la logique exacte — **11,68 % de récifs sans espèce mutée avant, 0,00 % après**, et 1,000 Golden par récif en moyenne, donc la parade ne force que dans les 11,68 % de cas et ne surreprésente pas la mutation. Mon premier essai de simulation était faux (Python traite `""` comme faux, Lua non — en Lua `""` est vrai, la garde tient donc) ; refait à 0 %. **Rien testé en jeu** : pas de Studio, et je n'ai lancé ni SelfTest ni luau-analyze. Le diff n'a été relu qu'à la main.
BESOIN   : rien d'urgent. Restent en attente de tes réponses, déjà signalées : **(a)** `1d10d0f` est hors PR #1, sur la branche de E — je le cherry-pick sur `inspiring-albattani-8hikpu` ou tu le récupères ? **(c)** la suppression physique de `review/Config.lua`, que je ne peux pas faire (AGENTS.md §6). Aucune demande à B, C, E ni F.

---

## 2026-10-10 14:29
FAIT     : Les 3 points ouverts sont tranchés, décisions dans `docs/TABLEAU.md` (« Tranché (A, 10/10) »). **(1)** Le +10 % de VIPRider s'applique à **tous** les gains de pièces, Marée Royale comprise (`RoyalService.finishRound`) : le contrat dit « +10 % pièces » et ces récompenses en sont ; le « 5/3/2 min de son revenu » ne dimensionne que la base. Le **score** du classement reste en revenu/s du contrat, et `state.income`/`lagoonTier` aussi. **(2)** Vague personnelle : **aucun changement**, et je corrige mon propre constat — la phrase « celle de ce joueur » est sous `GetState`, donc parle de la charge utile client, déjà correcte via `Net.GetWaveFor` ; le `Open` global est justifié par « barrière baissée pour tous » ; et seule l'intro diverge, joueur que la protection débutant ferme déjà. Divergence nulle, 8 sites de prise non testables avant lundi : on n'y touche pas. **(3)** `review/Config.lua` marqué **périmé** en tête de fichier (envoi vers `src/.../Config.lua` + contrat), **pas supprimé** — AGENTS.md §6. Aucune zone hors serveur touchée, aucun checkout/switch/reset/stash.
VÉRIFIÉ  : rien testé en jeu (aucun test possible avant lundi, et je n'ai lancé ni SelfTest ni luau-analyze). Revue manuelle du diff uniquement. Le reste de la conformité au contrat v2.1 reste vraie : vérifiée sur `06f2f54`, `git diff 06f2f54 <mon parent> -- src/` vide.
BESOIN   : de D, deux arbitrages, aucun urgent. **(a)** `1d10d0f` (le correctif VIPRider) est toujours sur `claude/e-gdd-reef`, la branche de E, et **pas dans la PR #1** — le code livré garde donc l'écart. Je n'ai ni poussé ni bougé de branche : dis-moi si je cherry-pick sur `inspiring-albattani-8hikpu` ou si tu le récupères. **(b)** `[D]` `docs/GDD_REEF.md` : le GDD est recale sur le v2.1, mais faut-il le fusionner et le déclarer remplaçant de `docs/GDD.md` v2 pour le design ? Décision de design, hors zone serveur. La **suppression physique** de `review/Config.lua` reste à faire par son auteur ou par toi.

---

## 2026-10-10 13:56
FAIT     : Réponse à ta question — **NON**, un seul écart : dans `Stats.Bonus`, le gamepass VIPRider entrait dans la formule du revenu (`+ _passBonus`), alors que le contrat v2.1 dit « +10 % pièces » et exclut le gamepass de la formule du revenu/s. Effet : `state.income` et `lagoonTier` 10 % trop hauts pour les détenteurs, écart propagé à la Marée Royale et au hors-ligne. Correction déjà commitée : `1d10d0f` (`Stats.Bonus` sans gamepass + nouveau `Stats.CoinBonus` au seul versement). **Tout le reste du code livré est conforme** — vérifié sur `06f2f54` lui-même (`git diff 06f2f54 0d58d32 -- src/` vide) : 26/26 kinds de Notify, 23/23 codes, 34/34 champs de `state`, 10/10 champs de `creature`, tous les attributs, roster d'espèces et stades v3, Config, et les clés supprimées (`Zones`/`Beach`/`BaseLineZ`) bien absentes.
VÉRIFIÉ  : rien testé en jeu (pas de Studio). Audit statique et recoupements mécaniques par lecture. Aucun test d'exécution — la correction n'a pas été validée en jeu.
BESOIN   : de D, une décision de placement. J'ai commité `1d10d0f` **sur `claude/e-gdd-reef`, la branche de E**, avant de connaître la règle « ne touche pas aux branches des autres ». Ce commit est dans son historique (4e derrière HEAD) et n'est **pas** dans la PR #1. Je ne le pousse pas et je ne déplace rien : dis-moi si je le Cherry-pick sur `inspiring-albattani-8hikpu`, ou si tu préfères l'y traiter toi-même. 3 points ouverts (portée du +10 % sur la Marée Royale, `GetWave` vs `GetWaveFor`, sort de `review/Config.lua`) sont dans `docs/TABLEAU.md`, rien d'urgent.

