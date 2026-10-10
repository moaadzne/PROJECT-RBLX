# File de F — Controle qualite (lecture)
> Protocole AGENTS.md §3. D lit ce fichier. Écris ici **à la fin de ton tour**, pas pendant.
> Une entrée = 3 lignes : FAIT / VÉRIFIÉ / BESOIN. Rien d'autre.

## 2026-10-10 14:28
FAIT     : Contrôle de Wave.lua (4955d92) : **P0 non corrigé**. Ligne 404 `base + Vector3.new(0, sink, -front)` est une translation en coordonnées MONDE ; le commentaire ligne 403 annonce une translation locale. Il faut `base * CFrame.new(0, sink, -front)`.
VÉRIFIÉ  : reproduit numériquement, front à 200 studs — N = −200 au lieu de +200 (vague à l'envers), E et W = 0 (vague immobile au centre de l'île), S correct par coïncidence. `SelfTest.lua:159` ne le voit pas car il ne teste que N et S. 967a9c8 de B est validé (nil−nil supprimé, REACH calculé, WaveFrontZ → WaveFrontD/WaveDistanceTo/WaveFrontPoint, `dir` exposé). Rien testé en jeu.
BESOIN   : [auteur P1-42] une seule ligne à changer, P0 du même niveau que la vague invisible que ce commit devait corriger — [C] `waveBoom` et `ambientBeach` n'existent dans aucun `Assets.Sounds` (dossier absent), la vague sera muette tant qu'ils manquent — [B] `Store.lua:276` `startZ` est un champ mort, écrit jamais relu, sans conséquence.

