-- CosmeticIcons : atlas des icônes cosmétiques (skins, montures, wings, housing, emotes)
-- Chaque entrée renvoie un nom d'icône pour Theme.Icon() / IconResolver.Resolve()
-- Asset IDs à remplacer après upload Creator Hub

local CosmeticIcons = {}

-- Skins créatures (50+ espèces, 149-399 Robux)
CosmeticIcons.CreatureSkins = {
	Abyssal = { icon = "moon", color = Color3.fromRGB(80, 120, 255), price = 299 },
	Corail = { icon = "star", color = Color3.fromRGB(255, 100, 120), price = 149 },
	Aurore = { icon = "spark", color = Color3.fromRGB(100, 230, 200), price = 199 },
	EveilLeviathan = { icon = "crown", color = Color3.fromRGB(240, 190, 70), price = 399 }, -- drop légendaire
	-- TODO: 50+ espèces × 2-3 skins chacune
}

-- Skins montures (299-599 Robux)
CosmeticIcons.MountSkins = {
	SeaDragon = { icon = "arrow", color = Color3.fromRGB(100, 200, 255), price = 499 },
	GoldenRay = { icon = "crown", color = Color3.fromRGB(240, 190, 70), price = 599 },
	PhantomTurtle = { icon = "shield", color = Color3.fromRGB(180, 180, 200), price = 399 },
	-- TODO: 20+ montures
}

-- Ailes / Traînées (199-499 Robux)
CosmeticIcons.WingsTrails = {
	Flames = { icon = "bolt", color = Color3.fromRGB(255, 80, 40), price = 299 },
	Frost = { icon = "star", color = Color3.fromRGB(150, 220, 255), price = 299 },
	Shadow = { icon = "moon", color = Color3.fromRGB(120, 80, 180), price = 399 },
}

-- Thèmes housing (299-799 Robux)
CosmeticIcons.HousingThemes = {
	CoralReef = { icon = "star", color = Color3.fromRGB(255, 150, 150), price = 499 },
	SunkenTemple = { icon = "wave", color = Color3.fromRGB(80, 150, 200), price = 599 },
	Volcanic = { icon = "bolt", color = Color3.fromRGB(200, 80, 60), price = 699 },
}

-- Emotes (49-149 Robux)
CosmeticIcons.Emotes = {
	Dance = { icon = "crown", color = Color3.fromRGB(240, 190, 70), price = 99 },
	Wave = { icon = "wave", color = Color3.fromRGB(100, 200, 255), price = 49 },
	Flex = { icon = "shield", color = Color3.fromRGB(255, 100, 100), price = 149 },
}

-- Battle Pass (12 semaines)
CosmeticIcons.BattlePass = {
	Free = { icon = "star", color = Color3.fromRGB(150, 162, 178), price = 0 },
	Premium = { icon = "crown", color = Color3.fromRGB(240, 190, 70), price = 499 },
}

-- Vault annuel (retour garanti)
CosmeticIcons.Vault = {
	AnnualReturn = { icon = "crown", color = Color3.fromRGB(240, 190, 70), price = 0 },
}

-- Renvoie un nom d'icône pour Theme.Icon() / IconResolver.Resolve()
function CosmeticIcons.Get(category: string, name: string): string?
	local cat = CosmeticIcons[category]
	if not cat then
		return nil
	end
	local item = cat[name]
	if not item then
		return nil
	end
	return item.icon
end

-- Renvoie le prix (0 = gratuit)
function CosmeticIcons.Price(category: string, name: string): number
	local cat = CosmeticIcons[category]
	if not cat then
		return 0
	end
	local item = cat[name]
	if not item then
		return 0
	end
	return item.price or 0
end

return CosmeticIcons