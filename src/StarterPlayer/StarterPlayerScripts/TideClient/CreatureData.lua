-- CreatureData : donnees du Knowledge Hub (Codex) — compendium detaille.
-- Contenu cote client, enrichi pour les fiches : habitat, comportement, regime,
-- difficulte de capture, statistiques, arbre d'evolution (conditions), indices mystere.
-- Coherent avec Config.Creatures / Config.Stages / Config.Mount (A).
-- Phase 1 : 3 especes detaillees. Les autres ont des fiches partielles (Phase 2).

local CreatureData = {}

-- Durees de croissance (reprises de Config.GrowthMinutes) pour l'affichage des paliers
local STAGE_NAMES = { "Juvenile", "Adult", "Elder", "Titan" }

-- Lore + fiches — 3 especes Phase 1 (source : GDD §4.2, CREATURES_ART, DECISIONS_MARCHE §2)
CreatureData.Entries = {
	GhostCrab = {
		habitat = "Cove Beach · Dunes",
		behavior = "Flees in zigzag when approached — cut it off to catch it.",
		diet = "Small crustaceans, detritus",
		captureDifficulty = "Easy",
		height = "low",
		-- Statistiques (echelle 1..5)
		stats = { speed = 4, stealth = 5, power = 1, agility = 4 },
		notes = "Nearly invisible on pale sand. Stalked eyes give it away.",
		evolution = {
			branched = false,
			path = { { stage = "Adult", minutes = 3 }, { stage = "Elder", minutes = 15 }, { stage = "Titan", minutes = 60 } },
		},
	},
	CushionStar = {
		habitat = "Dunes · Outer Shore",
		behavior = "Slow crawler, clings to rock. Rarely escapes once reached.",
		diet = "Algae, coral polyps",
		captureDifficulty = "Easy",
		height = "low",
		stats = { speed = 1, stealth = 2, power = 1, agility = 1 },
		notes = "Thick texture, red and cream patterns — the finest catch of the shore.",
		evolution = {
			branched = false,
			path = { { stage = "Adult", minutes = 3 }, { stage = "Elder", minutes = 15 }, { stage = "Titan", minutes = 60 } },
		},
	},
	HawksbillTurtle = {
		habitat = "Outer Shore · The Drowned Reef",
		behavior = "Swims to deep water when startled. First mount of the game.",
		diet = "Sponges, sea anemones",
		captureDifficulty = "Medium",
		height = "medium",
		mountable = true,
		stats = { speed = 2, stealth = 3, power = 3, agility = 2 },
		notes = "Scuted shell. Mountable from Elder — the turtles of surfers.",
		evolution = {
			branched = false,
			path = { { stage = "Adult", minutes = 5 }, { stage = "Elder", minutes = 30 }, { stage = "Titan", minutes = 120 } },
		},
	},

	-- Phase 2 — fiches partielles (statuts + indices, pas de comportement verrouille)
	Lionfish = {
		habitat = "The Drowned Reef",
		behavior = "Reef ambusher.",
		captureDifficulty = "Hard",
		stats = { speed = 3, stealth = 4, power = 4, agility = 3 },
	},
	BlueRingedOctopus = {
		habitat = "The Drowned Reef",
		behavior = "Night only — glows from afar.",
		captureDifficulty = "Hard",
		stats = { speed = 3, stealth = 5, power = 5, agility = 3 },
	},
	LeopardRay = {
		habitat = "Wreck Cove",
		behavior = "Glides in open water.",
		mountable = true,
		captureDifficulty = "Medium",
		stats = { speed = 4, stealth = 3, power = 3, agility = 4 },
	},
	GiantPacificOctopus = {
		habitat = "Wreck Cove",
		behavior = "Changes colour in the pool.",
		captureDifficulty = "Hard",
		stats = { speed = 2, stealth = 4, power = 5, agility = 2 },
	},
	LionsManeJelly = {
		habitat = "Open sea",
		behavior = "Drifts with currents, amber glow.",
		captureDifficulty = "Medium",
		stats = { speed = 1, stealth = 3, power = 4, agility = 1 },
	},
	MantaRay = {
		habitat = "Golden Tide · open sea",
		behavior = "Leaps from the water.",
		mountable = true,
		captureDifficulty = "Hard",
		stats = { speed = 4, stealth = 2, power = 5, agility = 4 },
	},
	WhaleShark = {
		habitat = "Event only",
		behavior = "The largest fish in the world.",
		mountable = true,
		captureDifficulty = "Very Hard",
		stats = { speed = 3, stealth = 1, power = 5, agility = 2 },
	},
}

-- Indices pour les 4 slots mystere (revelation progressive)
-- index 1..4 -> Rare, Epic, Legendary + 1 mystere
CreatureData.MysteryHints = {
	[1] = { rarity = "Rare", hint = "Glowing rings light up in the dark." },
	[2] = { rarity = "Epic", hint = "Eight arms, one mind." },
	[3] = { rarity = "Legendary", hint = "Wider than a tower." },
	[4] = { rarity = "Legendary", hint = "It is said to sleep beneath the island." },
}

-- Un indice supplementaire se deverrouille par tranche d'especes decouvertes
CreatureData.MysteryHintUnlock = { 1, 3, 5, 8 } -- nb d'especes (total) pour reveler l'indice N

-- Recupere une fiche (nil si espece inconnue)
function CreatureData.Get(speciesId: string)
	return CreatureData.Entries[speciesId]
end

-- Nb d'especes connues du roster complet (10)
function CreatureData.SpeciesCount(): number
	local n = 0
	for _ in pairs(CreatureData.Entries) do
		n += 1
	end
	return n
end

-- Niveau de difficulte -> score 1..5 (pour barres)
function CreatureData.DifficultyScore(difficulty: string?): number
	local map = { Easy = 1, Medium = 3, Hard = 4, ["Very Hard"] = 5, Hard_ = 4 }
	return map[difficulty or "Easy"] or 1
end

return CreatureData