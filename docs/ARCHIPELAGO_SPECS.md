# ARCHIPELAGO_SPECS.md — Cycle 1 : Archipel & Fondations Monde

**Auteur : T (World & Exploration)**
**Date : 2026-10-10**
**Statut : Specs Cycle 1 — livrables pour C (terrain/visuel), V (streaming), A (config)**
**Note :** Cycles 2-4 (exploration, expansion, performance/vie) sont **écrits mais non lancés** — quota Moaad épuisé jusqu'au 12/10 21h (AGENTS.md §4). Ce document ne couvre que le Cycle 1.

---

## 1. LES 10+ ÎLES (identités & destinations)

### Phase 1 — Île unique (déjà scopée par D)
| # | Île | Biome | Taille | Voyage ? | Statut |
|---|-----|-------|--------|----------|--------|
| 1 | **Maré** | Tropicale volcanique | 600×600 | Non (île de départ) | C construit lundi |

### Phase 2+ — Archipel (une île par grosse mise à jour)
| # | Île | Biome | Taille | Règle de vague | Espèces phares | Secret |
|---|-----|-------|--------|----------------|----------------|--------|
| 2 | **Mangrove** | Marécage paludéen | ~500×500 | Vague ralentie (racines amortissent) | Blue-Ringed Octopus, GhostCrab | Racinarium (salle sous racines) |
| 3 | **Récif Profond** | Récif corallien submergé | ~600×600 | Courants modifient trajectoire | Leopard Ray, Lionfish | Cité de corail engloutie |
| 4 | **Abysses** | Fosse océanique | ~500×500 | Vague descend puis remonte | Giant Pacific Octopus | Faille bioluminescente |
| 5 | **Volcan** | Île volcanique active | ~500×500 | Coulée de lave au reflux | Lions Mane Jelly | Chambre magmatique |
| 6 | **Glacier** | Polaire | ~500×500 | Vague de glace (gèle, slow) | Manta Ray (rare) | Épave prisonnière des glaces |
| 7 | **Cité Engloutie** | Ruines sous-marines | ~500×500 | Marée révèle les toits | Whale Shark (rare) | Salle du trône |
| 8 | **Île Céleste** | Île flottante haute | ~400×400 | Vague n'atteint pas (altitude) | Espèces aériennes P3 | Observatoire |
| 9 | **Dimension Miroir** | Réplique inversée | ~600×600 | Double vague simultanée | Toutes (variantes) | Miroir du Léviathan |
| 10 | **Atoll des Lances** | Banc de sable étroit | ~700×200 | Vague traverse tout | Espèces communes en masse | Fort des pirates |

**Règle d'or** : chaque île = **1 biome + 1 règle de vague + 1 secret + 2-3 espèces**. Jamais une île « fourre-tout ».

---

## 2. CRIQUE CENTRALE (hub d'accueil)

### Fonctions
- **Spawn** : les 8 lagons (Plots 1..8) en arc de cercle
- **Zone safe** : la vague n'y prend personne (`Config.Island.coveRadius = 110`)
- **Ancrage** : phare lointain visible depuis tous les lagons = repère d'orientation naturel
- **Pas de spawn créatures** dans la crique (contrat v2.1)

### Orientation naturelle (zéro carte, décision D)
| Repère | Visible depuis | Signification joueur |
|--------|---------------|---------------------|
| Phare | Toute la crique | "La maison est là-bas" |
| Tours (Y=34) | Plage + crique | "Abri si je cours" |
| Épave (Ouest) | Crique + plage O | "Créatures là-bas" |
| Falaise belvédère (Est) | Crique + plage E | "Belle vue là-haut" |

**Le joueur lit le monde, pas un HUD.** Boussole (B) = confirmation, jamais première source.

---

## 3. LES 8 TOURS

### Specs (déjà fixées par D et le contrat v2.1)
- **Plateformes** : Y = 34 (> hauteur vague 30 = safe)
- **Position** : réparties sur le pourtour, visibles depuis la crique
- **Rayon d'occupation** : `towerRadius = 16` (pas de spawn créatures dessus)
- **Structure** : roche volcanique + plateforme bois flotté + corail

### Rôle triple
1. **Gameplay** : abri pendant la vague
2. **Waypoint** : landmark de navigation
3. **Parkour** : rochers empilés = grimpe naturelle vers la plateforme (déjà partiellement dans `build_lagoon.luau`)

### Spec T pour C
- Silhouette lisible à 100 studs sur téléphone (1 tour = 1 colonne de roche + 1 dalle claire)
- Aucune part visible > 4 studs sauf l'eau (DA_MONDE §1)
- LOD : complet <100, simplifié 100-250, imposter >250

---

## 4. TERRAIN SCULPTÉ (build_island_terrain.luau)

### Reliefs Phase 1
| Zone | Relief | Fonction |
|------|--------|----------|
| Crique | Cuve rocheuse, eau calme | Lague, safe |
| Plages (anneaux 70-150) | Sable plat, légère pente | Spawns zone de départ |
| Dunes (150-225) | Dunes hautes, végétation dense | Spawns, cachettes |
| Outer shore (225-300) | Rochers, pente vers mer | Spawns risqués |
| Falaise Est (Y=30) | Paroi verticale + sommet plat | Belvédère |
| Côte Ouest | Plage + épave échouée | POI |
| Sud | Banc de sable qui s'étend | Récif marée extrême |
| Fonds marins | Pente douce sous l'eau | Profondeur, futur récif sous-marin |

### Génération (C, par script — déjà décidé)
- Généré par blocs dans `build_island_terrain.luau` (Mac lent = risque, décision C validée)
- Matériaux : Sand, Mud pour spawns (`Config.Island.spawnMaterials`)
- Eau : Terrain water océan seulement

### Phase 2 (noté, pas lancé)
- Grottes : entrées rocheuses, grottes sous-marines (respiration = mécanique P2)
- Fond marins creusés, cavernes

---

## 5. STREAMINGENABLED & CHUNKS

### Config (V/tech implémente)
```lua
Workspace.StreamingEnabled = true
Workspace.StreamingTargetRadius = 300  -- mobile ; 500 PC
```

### Grille chunks (T spécifie, C implémente)
- **Taille chunk** : 200×200 studs (brief D) → île 600×600 = 3×3 = 9 chunks
- **Toujours chargé (Persistent)** : crique centrale + lagons + tours
- **Streaming normal (Atomic)** : plages, POI, décor gameplay
- **Non streamé** : océan (Terrain water)
- **NonAtomic** : végétation, rochers, décor dense

| Chunk | Contenu | Mode |
|-------|---------|------|
| Centre | Crique, 8 lagons, tours proches | Persistent |
| Bords | Plages, POI (Épave O, Récif S, Belvédère E) | Atomic |
| Large | Océan, horizon | Non streamé |

### LOD distances (N implémente)
| Niveau | Mobile | PC |
|--------|--------|-----|
| Near | 0-80 | 0-100 |
| Mid | 80-160 | 100-200 |
| Far | 160-200 (suppression) | 200-300 |
| Imposter | — | >300 |

**Décision T** : sur mobile, suppression mesh > 200 studs (brief D §16). PC garde jusqu'à 300.

---

## 6. CE QUI EST QUEUED (PAS LANCÉ — quota)

Cycle 2 (Exploration) : 50+ POI, 25+ secrets, météo, events dynamiques, écosystème — **specs écrites plus tard**.
Cycle 3 (Expansion) : 7 nouvelles îles, grottes sous-marines, donjons ouverts, zones raids/PvP.
Cycle 4 (Performance & vie) : particules, ombres, hot-reload, ambient vivant.

**Ces cycles ne démarrent pas** : AGENTS.md §4 — quota épuisé jusqu'au 12/10 21h, pas de tâche qu'on ne peut pas finir.
