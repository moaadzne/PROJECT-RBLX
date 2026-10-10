# Rollback Plan — Procédures de secours

Filet de sécurité absolu : **sauvegarde triple** avant toute opération.
1. `File → Save to Roblox` (place publiée)
2. `Save to File As… TideRush_SAUVEGARDE_<date>.rbxl` — jamais modifiée
3. `Save to File As… TideRush_import_<date>.rbxl` — copie de travail

**Retour arrière universel** : fermer Studio **sans sauvegarder** → rouvrir `TideRush_SAUVEGARDE_<date>.rbxl`.

---

## Scénario 1 — Liste Rojo anormale
**Symptôme** : la liste Rojo contient `Workspace`, `Terrain`, `Lighting`, `ReplicatedStorage.Assets`, `MaterialService`, `SoundService`, `ServerStorage`.

**Action** :
1. **Abort** (avant Accept).
2. Fermer Studio **sans sauvegarder**.
3. Rouvrir la sauvegarde.
4. Prévenir **D**.
5. Vérifier que `default.project.json` n'a pas changé (source unique du repo).

**Temps : ~1 min.**

---

## Scénario 2 — SelfTest FAIL / erreur rouge
**Symptôme** : `ServerStorage.TR_Debug:Invoke("selftest")` ne renvoie pas tout PASS, ou Output rouge en mode Edit.

**Action** :
1. Arrêter le Play. **PAS de Cmd + S.**
2. Fermer Studio sans sauvegarder.
3. Rouvrir la sauvegarde.
4. Prévenir **A + D**.

**Temps : ~2 min.**

---

## Scénario 3 — Échec cross-platform (L'UN des deux)
**Symptôme** : un seul des 10 points échoue sur mobile **ou** sur PC.

**Action** :
1. **Rollback immédiat** — arrêter les 2 sessions.
2. **PAS de Cmd + S.** Fermer Studio sans sauvegarder.
3. Rouvrir la sauvegarde.
4. Prévenir **A + B + D**.
5. L'auteur corrige dans le **repo**, pas dans Studio.

**Temps : ~3 min.**

---

## Scénario 4 — Vague invisible / mauvaise direction
**Symptôme** : la vague n'est pas rendue, ou vient de la mauvaise direction.

**Action** :
1. Ne **pas** Accept les changements Rojo (si pas encore fait).
2. Revenir à la sauvegarde.
3. **B** corrige `Wave.lua` — ligne 404 doit être `base * CFrame.new(0, sink, -front)` (PAS `base + Vector3`) — et vérifie les 4 axes N/E/S/O.
4. Nouveau push → nouveau pull au prochain créneau.

**Temps : ~15 min.**

---

## Scénario 5 — Boutique / Codex / Monture cassés
**Symptôme** : achat impossible, probabilités non affichées, Codex incohérent, monture (Elder/Titan) non fonctionnelle.

**Action** :
1. Même rollback que scénario 3.
2. **A / B / C** corrigent dans le repo.
3. **Aucun hotfix en Studio** (Rojo l'écraserait au prochain sync).

**Temps : selon le fix.**

---

## Scénario 6 — Rojo ne connecte pas
**Symptôme** : le plugin Rojo ne trouve pas le serveur, ou erreur de connection.

**Action** :
1. Vérifier `rojo --version` = **7.5.1**.
2. Vérifier que le port **34872** est libre (`lsof -i :34872`).
3. Vérifier que Studio a été **redémarré** après l'installation du plugin.
4. Si échec : reporter au lendemain, travailler sur la **branche d'intégration** dans le cloud.

**Temps : ~10 min.**

---

## Rappels critiques (AGENTS.md §8)

- ⚠️ **L'ancienne UI** (emojis, blocs gris) reste dans `StarterGui` — Rojo ne la touche pas. **La masquer avant toute capture** (sinon rejet du 09/10 rejoué).
- ⚠️ **Ne jamais merger `claude/wave-client-p42`** : commit orphelin qui réintroduit le bug `base + Vector3`.
- ⚠️ **`testbuild/TestWaveRenderer.client.lua`** = doublon périmé, non mappé, ne pas éditer.
- ⚠️ **Quota Moaad** : si limite atteinte → **arrêt net**, pousser ce qui est en cours, prévenir. Pas de nouvelle tâche.

---

## Règle universelle

> **Jamais de Cmd + S pendant un rollback.** Fermer sans sauvegarder = retour garanti à la sauvegarde.
