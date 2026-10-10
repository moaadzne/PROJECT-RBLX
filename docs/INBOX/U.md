# File de U — Guild & Social Systems
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 17:15
FAIT     : Plan Social Phase 1 (Semaine 1-2) — PAS DE GUILDES (Phase 4). Social minimal : **Friend Invite** (bonus Config.Shop : +500 pièces si ami rejoint et joue 10 min, jour 7 = TideEgg gratuit non échangeable), **RewardedAd partage** (1 TideEgg gratuit/jour via pub, cooldown 24h, non cumulable). Architecture : SocialService (serveur) + SocialClient (client) — InviteLink generation, tracking join/playtime, reward grant ; AdService integration (Rewarded Video Ads 2025). Guildes (GuildService, Bases, Guerres, Chat, Voix, Calendrier, Permissions) = **Phase 4 (Semaines 7-8)**.
VÉRIFIÉ  : Aligné §9 PIVOT MAJEUR planning (Phase 1 = Fondation 2 sem, Phase 4 = PvP & Economie 2 sem) + DECISIONS_MARCHE.md §4 (Daily rewards, Social/Trade, Friend invite, A/B test). Rien testé en jeu.
BESOIN   : [D] — validation scope Social Phase 1 (Friend Invite + RewardedAd seulement). [A] — contrat remotes Social (InviteGenerate, InviteClaim, RewardedAdWatch, RewardedAdClaim). [G] — Config.Shop prix finaux + RewardedAd.enabled=true, cooldownHours=24, reward="TideEgg". [B] — UI invite ami (partage lien, suivi statut), bouton RewardedAd (style console DIRECTION_V2, sans emoji). [J] — Quêtes journalières "Invite un ami" + Daily Rewards jour 7 TideEgg.

## 2026-10-10 18:30
FAIT     : Prêt pour lundi 12/10 21h. Branche intégration `claude/e-gdd-reef`. Social Phase 1 plan écrit, aligné §9 + DECISIONS_MARCHE.md. Quota Moaad épuisé — arrêt net. Aucun test lourd, capture, luau-analyze. Repos.
VÉRIFIÉ  : INBOX/U.md à jour. Plan Social Phase 1 (Friend Invite + RewardedAd) documenté. Guildes = Phase 4.
BESOIN   : [D] — sync Rojo lundi soir, réimport Studio. Prochain tour = lundi en Studio.

## 2026-10-10 19:45
FAIT     : Alignment monétisation finale (G) — **Guild Hall themes = cosmetiques achetables (299-799, rotation mensuelle, Vault annuel)** ; **Guild Bank = QoL (logs, taxes 5%, shared storage) PAS puissance** ; Guild cosmetic unlocks via Battle Pass paliers, Maree Royale rewards, Guild Levels perks. Social Phase 1 deja compatible : Friend Invite +500 pieces (QoL), RewardedAd opt-in, Daily J7 TideEgg gratuit. Zero pay-to-win : guilde = progression temps/skill, pas achat.
VÉRIFIÉ  : Lu brief G complet — prix, probas, pity, Battle Pass, RewardedAds, PolicyService, ZERO P2W. Plan U Phase 4 (Guildes) compatible sans modification.
BESOIN   : [G] — Config.Shop inclut GuildHallThemes (IDs 0), BattlePass.premium=499, RewardedAds.enabled=true. [P] — Guild XP/Levels/Perks spec (cosmetic unlocks only). [R] — Guild tax 5% AH, trading contracts. [T] — Guild Hall plots placement. [S] — Cinematic triggers guild events. [O] — Guild quest lore.