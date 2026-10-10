## 2026-10-10 18:00
FAIT     : ShopService.lua complet — ProcessReceipt idempotent, GetPlayerPasses, BuyPass, ChoosePick, ClaimRewardedAd (cooldown 24h partagé), GetShopState, PremiumPayouts listener, A/B priceVariants VIP (79/99/129 mobile/PC), PolicyService gating (TideEgg caché, PickCreature visible si restreint), Bundle StarterPack = 3 passes (VIP+Speed+Net valeur 327→249), Analytics funnel (PurchaseAttempted/Completed/Failed, RewardedAdWatched/Failed), Pity TideEgg 50 essais → Legendary garantie.
VÉRIFIÉ  : Code écrit, cohérent avec Config.Shop final ; aucun test en jeu (pas Studio cloud).
BESOIN   : Moaad → 6 IDs Creator Hub (VIPRider, SpeedBoost, BagExpand, StarterPack, TideEgg, PickCreature) + DeepDive (semaine 2) + BattlePass. A → remotes Net.lua déjà créées. B → UI Shop.lua affiche pity, battlepass, rotation cosmetiques.

## 2026-10-10 18:05
FAIT     : Config.Shop finalisé — VIPRider 79 (priceVariants A/B/C), SpeedBoost 149, BagExpand 99, StarterPack 249 (includes 3 passes), TideEgg 199 (chances 60/25/10/4/1 + goldenChance 10 + pity 50), PickCreature 399 (6 espèces), DeepDive 399 (Pearls, enabled=false semaine 2), RewardedAd 0 (gratuit, cooldown 24h), BattlePass 499 (12 sem, 12 free/premium tiers), CosmeticRotation mensuelle + Vault annuel 365j. CrossPlatform prix unifiés mobile/PC.
VÉRIFIÉ  : Config.lua mis à jour, lu par ShopService et client Shop.lua ; prix cohérents DECISIONS_MARCHE.md.
BESOIN   : Moaad → validation BattlePass 499 + activation Rewarded Ads + Premium Payouts. H → icônes shop (coffre, vague, couronne, étoile). K → shader skins créatures (material swap).

## 2026-10-10 18:10
FAIT     : Préparation IDs Creator Hub — liste 6 passes/produits pour Moaad : VIPRider, SpeedBoost, BagExpand, StarterPack (gamepasses), TideEgg, PickCreature (produits développeur). DeepDive + BattlePass pour semaine 2. PriceVariants A/B test prêt (mobile/PC séparés). PolicyService gating testé logique (pas en jeu). Analytics events structurés. Tout code prêt pour sync Rojo lundi 21h.
VÉRIFIÉ  : Fichiers modifiés : Config.lua, ShopService.lua. Client Shop.lua à mettre à jour pour pity/battlepass/rotation (B). Aucune capture, aucun luau-analyze, quota Moaad respecté.
BESOIN   : Lundi Studio → Moaad rentre 6 IDs → tests achat mobile+PC complets (F) → launch checklist (M).