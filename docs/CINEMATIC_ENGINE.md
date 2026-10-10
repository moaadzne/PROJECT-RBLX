# CINEMATIC_ENGINE.md — Moteur cinématique (spec S)

**Auteur : S (Cinematics & Presentation)**
**Date : 2026-10-10**
**Statut : spec moteur Phase 2 — livrable design, aucun code tant que Studio n'est pas ouvert**

> **Base** : `src/StarterPlayer/StarterPlayerScripts/TideClient/CameraIntro.lua` (L, 680 l.) existe déjà et fonctionne pour les 30 s d'intro. Ce document explique comment on en fait un **moteur** sans le casser.

---

## 1. CE QUI EXISTE vs CE QU'ON AJOUTE

| Existant (CameraIntro.lua, L) | Moteur (ce document) |
|---|---|
| Timeline en dur (`TIMELINE = {...}`) | Timeline en **données** (table Lua) |
| Phases en dur (`aerial → fade → explore → ...`) | Phases = **steps** génériques |
| Caméra en dur (derrière joueur + shake) | **CameraPath** : keyframes → easing → interpolation |
| Captions écrites en dur | **Dialogue track** + choix branchements |
| Skip = booléen + `goto finish` | Skip **par paliers** (saut au prochain beat, pas à la fin) |
| Séquence unique | Plusieurs **clips** jouables, chaînables |

**Règle d'or** : CameraIntro.lua devient le **clip `intro30`**, exprimé avec l'API du moteur. Il n'est pas réécrit tant qu'il n'est pas testé en Studio (lundi). Le moteur vit dans `Cinema.lua` à côté.

---

## 2. ARCHITECTURE — 3 couches

```
Cinema (orchestrateur)     -- Play/Stop/Skip, état, priorité
├── Timeline               -- liste ordonnée de steps, durées, branches
├── CameraPath             -- keyframes CFrame, easing, cible dynamique (follow/look at)
├── Tracks (parallèles)    -- dialogue, letterbox, fades, shake, audio, effets
└── Triggers               -- ce qui DÉMARRRE un clip (serveur, monde, joueur)
```

**Pourquoi côté client (B est propriétaire de StarterPlayer)** : la caméra est locale, la latence serveur rendrait les mouvements saccadés. Le serveur ne fait que **déclarer** « cette ciné commence », jamais animer la caméra. Synchronisation par `serverNow` (déjà dans le contrat v2.1).

---

## 3. SYSTEME DE CAMERA PATH

### Format keyframes (table Lua, éditable sans recoder)

```lua
Config.CinematicClips["intro3_act2"] = {
	id = "intro3_act2",
	duration = 14.0,
	locked = true,              -- caméra verrouillée, contrôles joueur coupés
	steps = {
		{ t = 0.0,  cframe = { pos = {0, 180, -240}, look = {0, 20, 0} },   easing = "SineInOut" },
		{ t = 3.5,  cframe = { pos = {40, 90, -120},  look = {0, 40, 0} },   easing = "Quad" },
		{ t = 6.0,  target = "leviathanHeart", offset = {0, 60, 0}, follow = true },
		{ t = 10.0, target = "localPlayer",    offset = {0, 5, -14}, follow = true },
		{ t = 14.0, target = "localPlayer",    offset = {0, 3, -10}, follow = true },
	},
}
```

### Types d'étape (3 seulement, pas plus)
| Type | Usage |
|---|---|
| **fixed** | `pos` + `look` absolus — plans larges, paysages |
| **target** | suit un objet/PNJ (`target = "leviathanHeart"`, `owner` = serveur ou monde) |
| **follow** | suit le joueur avec offset — caméra épaule en mouvement |

### Easing autorisés (pas de rebond, ton premium)
`Linear`, `SineInOut`, `QuadInOut`, `CubicInOut`. **Interdit** : `Bounce`, `Elastic` (enfantin, contraire à DIRECTION_V2).

### Interpolation
Position + LookAt interpolés séparément en `CFrame.lookAt(camPos, lookPos)`. Pas de Quaternion slerp nécessaire (pas de rotation de roulis), donc pas de dérive de repère.

### Follow d'une cible qui bouge
`target` résolu à chaque frame (nom → instance, via `Util.Find(Workspace, ...)`). Si la cible disparaît (streaming, PNJ qui part), on garde la dernière position connue — **jamais de snap**.

---

## 4. DIALOGUE & CHOIX (branching)

### Rendu
- B est propriétaire de `DialogueUI.lua` (déjà demandé par O). Le moteur émet des **événements**, il ne crée pas d'UI.
- Sous-titres = track `dialogue` : `{ t, speaker, text, duration }`. Style console : RobotoCondensed, capitales, zéro emoji, panneau sombre translucide (DIRECTION_V2).

### Choix (impactants, O)
```lua
{ t = 12.0, type = "choice",
  prompt = "Le Léviathan se réveille",
  options = {
	{ id = "fight",  label = "COMBATTRE",  next = "clip_leviathan_fight" },
	{ id = "reason", label = "RAISONNER",  next = "clip_leviathan_reason" },
	{ id = "free",   label = "LIBÉRER",    next = "clip_leviathan_free" },
  },
  timeout = 20,            -- 0 = pas de timeout ; sinon on continue sur `default`
  default = "reason",
}
```
- Le choix est envoyé au serveur (remote `CinematicChoice(clipId, optionId)`), **A** le persiste dans `state.choices[questId]` (schéma v3 proposé par O).
- Conséquences : réputation PNJ, accès zones, dénouement chapitre 10 (3 fins).

### Skip par paliers
- `skipAllowed` = true → touche/skip saute au **prochain beat narratif** (fin du dialogue courant), jamais à la fin du clip.
- Choix : **jamais skippables** (l'attente est courte, timeout).
- Séquence d'arrivée joueur : skip complet autorisé à tout moment (comme CameraIntro aujourd'hui).

---

## 5. LETTERBOX & HUD MASQUABLE

- **Letterbox** : deux bandes noires animent vers ratio 2.39:1 en 0,4 s (`Config.Cinematics.letterboxRatio = 2.39`).
- **HUD masqué totalement** pendant `locked = true` (B expose `Hud.SetVisible(false)` — **demande B**).
- Mobile : les bandes ne mangent pas les zones tactiles ≥ 44 px (les contrôles sont déjà cachés). PC idem.
- Sortie de ciné : letterbox se retire en 0,3 s, HUD revient en fondu 0,2 s.

---

## 6. TRIGGERS — comment une ciné démarre

| Source | Mécanisme | Exemples |
|---|---|---|
| **Serveur** | `Notify("cinematic", {clipId, startAt})` — extension contrat v3, **demande A** | Chapitre, choix validé, événement mondial |
| **Monde** | attribut/proximité (`map.CinematicTriggers.Trigger1` avec `Clip`) | Rencontre PNJ, point de vue belvédère |
| **Joueur** | état (`state.intro`, `state.questStage`) | Intro, tutoriel |

**Synchronisation serveur-synchro** (Éveil Léviathan, O/LORE_EVENTS.md) :
- Le serveur envoie `cinematic` avec `startAt = serverNow + 2` à tous les joueurs concernés.
- Chaque client schedule le clip à `startAt`, puis dérive de ±1 s max (tolérable : c'est une ciné, pas un combat).
- Pendant la ciné, le combat est **gelé** côté serveur (Q coordonne les phases raid).
- Replay : la ciné est auto-enregistrée chez chaque joueur.

---

## 7. INTRO 3 MIN — contrat (demande de O)

Format : **in-game temps réel** (pas pré-rendu, pas d'asset lourd, 60 FPS mobile maintenu).

| # | Act | Durée | Contenu (LORE_ARCHIPEL) | Ancres monde (C/T) |
|---|---|---|---|---|
| 1 | Naissance de l'archipel | 35 s | Plan large : l'île émerge, volcan, mer se retire | Terrain île 600×600, phare lointain |
| 2 | Appel de la marée | 45 s | Le joueur arrive sur la plage, GhostCrab fuit, 1re capture | Spawns anneaux 1 (déjà en place) |
| 3 | La marée extrême | 40 s | Le gravage de l'épave s'allume, la mer se retire 2× | Épave O + empreinte lumineuse (pulse) |
| 4 | Le réveil | 40 s | L'ombre du Léviathan sous l'île, un œil s'ouvre, première vague | « Cœur Léviathan » : attribut monde, **demande T/C** |
| 5 | Retour au contrôle | 20 s | Caméra revient au joueur, letterbox sort, HUD apparaît | Transition vers boucle (L) |

**Décision à valider par D** : l'intro 3 min remplace-t-elle `CameraIntro.lua` (30 s) ou s'ajoute-t-elle après ? Position S : les 30 s actuelles sont **supérieures sur le plan pédagogique** (apprentissage sans texte). Recommandation : garder la version 30 s en Phase 1, et n'ajouter les actes 1/4 (naissance + Léviathan) qu'en Phase 2 où ils deviennent le prologue.

**Montage possible** (si D veut la durée 3 min) : actes 1 + 4 encadrant les 30 s existantes, soit ~1 min 40 — ou allonger les plans larges. À trancher lundi.

---

## 8. EVENTS MONDIAUX — ciné serveur-synchro

### ÉVEIL DU LÉVIATHAN (Phase 3, raid 20 j) — demande de O
- **3 min, tous joueurs** déclenche une fois : `ExtremeTide + Royal + 5 joueurs rang 3+`.
- 6 temps (d'après LORE_EVENTS.md) : la mer se retire → gravage pulse → l'épave s'ouvre → la tête émerge → la vague titanesque → le cri.
- `locked = true` pour tous, **mais** les joueurs déjà en combat raid voient la ciné en fond (skip normal, pas de punition).
- Caméra différente par joueur : chacun voit la **crête depuis sa position** (caméra `follow` + orientation vers le Léviathan), pas un plan fixe — sinon les joueurs dos à l'épave voient du noir.
- Les 3 phases combat (ÉVEIL / COLÈRE / REPOS) utilisent les **mêmes outils** : boss intro 30 s par phase, avec tells lisibles.

### MARÉE NOIRE (Phase 4, PvP)
- Ciné courte 15-20 s à chaque bascule de zone (nappes noires qui avancent), **non skippable** si le joueur est dans la zone (c'est l'information de gameplay) — sinon il se fait tuer sans comprendre.
- Replay coupé pendant la ciné (pas de spoil de la position ennemie).

---

## 9. BOSS INTROS — 30 s uniques (Q, C)
Format par boss : **1 plan signature + 1 tell + 1 son**.
- Léviathan : œil qui s'ouvre sous la surface + grondement grave.
- Kraken : tentacules qui sortent + ombre qui avale la lumière.
- Hydre : 3 têtes qui émergent à 3 endroits.
Chaque intro se termine par un **tell** (télégraphe) lisible — irriter les yeux du joueur, pas juste de la déco. Durée max 30 s, skippable après 5 s (un joueur qui refait le boss ne veut pas la revoir).

---

## 10. REPLAY SYSTEM — Phase 3 (pas Phase 1)
- **Auto-record** : les 90 dernières secondes de mouvement caméra + joueurs visibles sont bufferisées (anneau circulaire).
- **Caméra libre** : après mort ou victoire raid, caméra détachée du joueur (contrôles séparés, touche dédiée).
- **Timeline scrubbing** : pause, ralenti 0.25×/0.5×, retour arrière 10 s.
- **Export vidéo** : ⚠️ Roblox ne permet pas d'encoder une vidéo dans un fichier directement. Options : (a) capture d'écran + assemblage externe par le joueur, (b) passer par une API de capture non documentée = **fragile, à ne pas promettre**. **Décider plus tard** — ne rien inscrire au GDD comme acquis.
- **Limites perf** : buffer de positions caméra = ~90 s × 30/s × 3 vecteurs ≈ 8 000 points, négligeable. Position des autres joueurs si on veut un vrai replay multi-joueur = plus lourd (DataStore), à étudier (V).

---

## 11. CONFIG.CINEMATICS — à ajouter par A

```lua
Config.Cinematics = {
	enabled       = true,
	skipAllowed   = true,     -- skippable global (sauf exceptions par clip)
	letterboxRatio = 2.39,
	subtitleLang   = "en",    -- le jeu est en anglais
	subtitleSize   = 18,      -- min lisible mobile ; adapte via plateforme
	fadeIn         = 0.4,
	fadeOut        = 0.3,
	skipGrace      = 5.0,     -- délai avant que skip soit actif (boss intros)
}
```
→ **Demande A** : ce bloc dans `ReplicatedStorage.Shared.Config` (zone A).

---

## 12. PERFORMANCE (60 FPS mobile/PC)
- **Temps réel, jamais pré-rendu** : pas d'asset vidéo, pas de UnrealRemote.
- Interpolation caméra : 1 calcul par frame (`Heartbeat` après rendu, `RenderStepped` pas dispo en client script — utiliser `RunService.RenderStepped` :BindToRenderStep priorité basse).
- Shake : bruit déterministe (seed) pour éviter la nausée mobile + respecter `Settings.reducedMotion` (déjà fait dans CameraIntro — à conserver).
- Aucun chargement d'asset pendant une ciné : précharger les modèles de boss/PNJ **avant** le trigger (spinner si manquant, jamais de hitch).

---

## 13. CE DONT J'AI BESOIN (relances)

| Qui | Quoi |
|---|---|
| **A** | `Notify("cinematic", {clipId, startAt})` + `CinematicChoice(clipId, optionId)` dans le contrat v3 ; `Config.Cinematics{}` ; `state.choices` |
| **B** | DialogueUI.lua (O a déjà spécifié), letterbox, `Hud.SetVisible(false)`, masquage contrôles mobiles |
| **T/C** | ancres nommées : `Map.CinematicTriggers.TriggerN` (attribut `Clip`), `leviathanHeart`, épave + empreinte lumineuse (gravage déjà spécifié) |
| **V** | sync 200-500 joueurs pendant Éveil Léviathan ; streaming des gros modèles |

## 14. Prochaines étapes S
1. Attendre le kickoff lundi 12/10 21h (Studio).
2. Là, écrire `Cinema.lua` (squelette orchestrateur) — 1 séance.
3. Y migrer `CameraIntro.lua` comme clip `intro30` — valider non-régression.
4. Écrire le clip `intro3` (actes 1 + 4 encadrants) si D valide le montage.
5. Chaîner `EveilLeviathan` avec O/Q.
