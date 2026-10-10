# File de S — Cinematics & Presentation

## 2026-10-10 16:35
FAIT     : Cycles infinis D recus (1 moteur / 2 sequences / 3 presentation / 4 tech). Aucune tache active en attente : Phase 1 = rien a livrer, Studio lundi 12/10 21h. Les cycles demarrent au kickoff Semaine 1-2.
VÉRIFIÉ  : Rien teste en jeu (pas de Studio)
BESOIN   : lundi : feu vert sequence pour moteur cinematique (C1.1) + O pour scripts intro 3 min (C1.2)

## 2026-10-10 16:20
FAIT     : Phase 1 = RIEN à livrer (CameraIntro.lua 30s déjà faite par L, appelée par init.client.lua). Confirmé avec D.
VÉRIFIÉ  : Rien testé en jeu (pas de Studio avant lundi 12/10 21h)
BESOIN   : Attendre semaine 2 pour scope cinématique complet.

## 2026-10-10 16:21
FAIT     : Scope Semaine 2+ défini — Moteur cinématique (Timeline, CameraPath, Trigger system), Intro 3 min (arrivée archipel + Ancien Roi Léviathan endormi), 10 chapitres cuts 2-3 min (choix branchés impactant progression), Boss intros 30s uniques (Léviathan, Kraken, Hydre), Events mondiaux serveur-synchro (Éveil Léviathan 20j + Marée Noire PvP), Replay system (auto-record dernière vague, caméra libre, export MP4).
VÉRIFIÉ  : Design only — pas de code, pas de Studio.
BESOIN   : O (scripts/storyboards), A (triggers WaveService/ExtremeTide, Notify.cinematic v3), B (letterbox, sous-titres, HUD masquable), C (décors cinématiques, éclairage), L (transition intro->gameplay), V (streaming/instancing sync 200-500j), Config.Cinematics{} (enabled, skipAllowed, letterboxRatio, subtitleLang).

## 2026-10-10 16:22
FAIT     : Alignement monétisation — Intro/boss intros/replay valorisent cosmétiques only (mount skins, vague skins, trails, titles), ZERO Pay-to-Win respecté. Coordination identifiée : G (skins IDs), K (shader swap), N (hero shots), O (skins lore-friendly), V (hot-reload).
VÉRIFIÉ  : Design only.
BESOIN   : Semaine 2 : kickoff technique avec O/A/B/C/L/V pour architecture moteur + pipeline assets. Définir format CameraPath (Bezier? Spline? Keyframes?), Timeline format, système choix (branching state machine).