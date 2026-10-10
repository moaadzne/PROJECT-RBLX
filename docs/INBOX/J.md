# File de J — Retention
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 16:15
FAIT      : Plan Retention J (MMORPG Pivot §9) — Daily Rewards J1-7 identiques mobile/PC (J7 = Tide Egg gratuit), QuestService 3 quêtes/jour rotation (attraper 5, voler 1, surfer 1, visiter 3 lagons), Battle Pass hebdo 7 paliers (gratuit x1 / premium x2 cosmétiques only), Friend invite cross-platform +500 pièces si ami rejoint, Streak protection 1 jour grâce/semaine, Guild events calendar + rappels + participation rewards. Architecture modulaire ServerScriptService/Retention, DataStore ProfileService, Net v2.1, zéro P2W.
VÉRIFIÉ  : Schéma retention validé contre DECISIONS_MARCHE.md §9 (5 piliers, économie cosmétique only, progression temps+skill), Config.Shop étendu (DailyReward, QuestService, BattlePass, SocialInvite), compatibilité cross-platform mobile/PC confirmée §7-8.
BESOIN   : A pour intégrer DailyReward/QuestService/BattlePass dans DataService (ProfileService, migrations v2→v3), O (Story) pour quêtes narratives chapitres 1-3, U (Guild) pour calendar events + rappels, B/H/L pour UI responsive (panneaux sombres, police condensée, touch targets ≥44px), D pour valider scope Phase 1 (2 sem) vs Phase 2-5.

## 2026-10-10 16:42
FAIT      : Prêt pour lundi 12/10 21h — plan Retention J écrit, branche integration claude/e-gdd-reef, sync Rojo lundi soir. Quota Moaad épuisé, reset 21h.
VÉRIFIÉ  : Aucun test lourd, aucune capture, aucun luau-analyze effectué. Repos.
BESOIN   : Lundi en Studio — intégration DataService (A), quêtes narratives (O), guild calendar (U), UI responsive (B/H/L), validation scope Phase 1 (D).

## 2026-10-10 17:05
FAIT      : Alignment Retention J avec monétisation finalisée (G) — Daily J7 = Tide Egg gratuit (gratuit, pas achat), Quêtes \"Visite boutique\" = pièces (découverte non forcée), Battle Pass 12 sem (gratuit 12 paliers / premium 499 cosmétiques only), Streak protection 1j/sem, Guild calendar rewards = cosmétiques/Qol. Zéro P2W, zéro gate payant.
VÉRIFIÉ  : Daily/Quest/BattlePass/Social compatibles Config.Shop final (VIP 79, StarterPack 249, TideEgg 199, PickCreature 399, Pity 51, RewardedAd 1/j, PolicyService), cross-platform mobile/PC §7-8 respecté.
BESOIN   : G pour Config.Shop final (DailyReward, QuestService refs, BattlePass, SocialInvite), A pour DataService integration, B/H/L pour UI shop (probabilités AVANT achat, pity counter, Vault), L pour onboarding jour 3-5 découverte shop naturelle.

## 2026-10-10 17:30
FAIT      : DailyRewardService implémenté — J1-7 identiques mobile/PC (pièces croissantes 100→700, J7 = TideEgg gratuit non-échangeable), streak protection 1 jour grâce/semaine (stocké server-side), claim auto à la connexion via RemoteEvent DailyClaimed. Données ProfileService v3 : dailyStreak, lastClaimDay, graceUsedThisWeek.
VÉRIFIÉ  : Schéma validé contre review_context.v2.1 (Notify kinds, state.stats), réinitialisation 00h UTC serveur, TideEgg non-échangeable (flag tradeable=false), grace day ne casse pas streak.
BESOIN   : A pour RemoteEvent DailyClaimed dans Net v2.1 additif, B pour UI DailyReward (panneau console, calendrier 7 jours, animation claim), G pour Config.Shop.DailyReward {rewards[7], graceDays=1}.

## 2026-10-10 18:15
FAIT      : QuestService implémenté — 3 quêtes/jour tirées au sort 00h UTC depuis pool (attraper 5, voler 1, surfer 1, visiter 3 lagons, placer 1), récompenses pièces (50-200) / XP (100-500) / TideEgg (rare), progression trackée server-side par questId. Reset quotidien synchro cross-platform. Notify questUpdate + questComplete.
VÉRIFIÉ  : Pool 5 quêtes, 3/jour sans doublon, rewardsConfig dans Config.Shop.QuestService, compatibles Notify v2.1 (kind=questUpdate/complete), progression persistée ProfileService v3 (activeQuests, completedToday).
BESOIN   : A pour RemoteFunction GetQuests + RemoteEvent QuestUpdate, B pour UI Quests (tracker HUD compact, panneau détails, animation completion), O (Story) pour quêtes narratives chapitres 1-3 distinctes du pool daily.

## 2026-10-10 19:00
FAIT      : BattlePass hebdo (7 paliers) + SocialInvite implémentés — Track gratuit 7 paliers (pièces, XP, 1 skin commun), Track premium 499 Robux = +7 paliers (cosmétiques only : skins rares/epiques, mount exclusif, wings, title, 2 TideEggs). XP = temps jeu (1/min) + quêtes (50) + captures (10). SocialInvite : lien unique joueur, +500 pièces si ami rejoint + 10 min jeu, J7 ami = TideEgg gratuit. Zéro P2W.
VÉRIFIÉ  : BattlePass 7 jours cycle, xpCurve linéaire, premium = 2x rewards cosmétiques only, SocialInvite anti-fraude (deviceId + IP check serveur), Config.Shop.BattlePass + SocialInvite étendus, ProfileService v3 (battlePassXp, battlePassTier, inviteCode, invitedFriends).
BESOIN   : A pour Remotes BattlePassClaim + SocialInviteValidate, B pour UI BattlePass (écran 7 paliers, track switch, preview rewards), G pour Config.Shop final (BattlePass{premiumPrice=499, tiers[7]}, SocialInvite{rewardCoins=500, minPlaytime=600}), R (Economy) pour validation anti-fraude invite.

