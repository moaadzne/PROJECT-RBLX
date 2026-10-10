-- Glyph : chargeur Font Awesome 6 Free (SIL OFL) via FontFace Roblox
-- Asset ID Creator Store : 12187624912 (Font Awesome 6 Free, police famille)
-- Fallback : nil si l'asset n'est pas uploadé/configuré — IconResolver utilise alors les primitives.

local Glyph = {}

-- Asset ID de la police Font Awesome 6 Free sur Roblox (Creator Store)
-- À remplacer par l'asset ID généré après upload sur Creator Hub si besoin
local FA_ASSET_ID = "rbxassetid://12187624912"

-- Police FA6 chargée (une seule fois)
local faFontFace: Font? = nil
local attempted = false

-- Charge la FontFace Font Awesome 6 Free une fois, renvoie nil si indisponible
function Glyph.GetFont(): Font?
	if attempted then
		return faFontFace
	end
	attempted = true
	local ok, font = pcall(function()
		return Font.new(FA_ASSET_ID, Enum.FontWeight.Regular)
	end)
	if ok and font then
		faFontFace = font
	end
	return faFontFace
end

-- Renvoie true si Font Awesome est chargé
function Glyph.IsLoaded(): boolean
	return Glyph.GetFont() ~= nil
end

-- Codepoints Font Awesome 6 Free (Solid) — sous-ensemble utile à Tide Rush
-- Clé lisible -> codepoint Unicode privé/FA
Glyph.Codes = {
	-- Actions / combat
	arrow = "\u{f061}",
	["arrow-right"] = "\u{f061}",
	["arrow-left"] = "\u{f060}",
	["arrow-up"] = "\u{f062}",
	["arrow-down"] = "\u{f063}",
	bolt = "\u{f0e7}",
	sword = "\u{f71e}",
	shield = "\u{f132}",
	["shield-alt"] = "\u{f132}",
	hammer = "\u{f6e3}",
	hammerAlt = "\u{f6e3}",
	-- Objets / économie
	chest = "\u{f217}",
	box = "\u{f466}",
	coin = "\u{f3d1}",
	gem = "\u{f3a5}",
	star = "\u{f005}",
	["star-half"] = "\u{f089}",
	crown = "\u{f521}",
	spark = "\u{f5a2}",
	fire = "\u{f06d}",
	key = "\u{f084}",
	-- Nature / thème marin
	wave = "\u{f773}",
	water = "\u{f773}",
	fish = "\u{f578}",
	moon = "\u{f186}",
	sun = "\u{f185}",
	leaf = "\u{f06c}",
	mountain = "\u{f6fc}",
	compass = "\u{f14c}",
	gemAlt = "\u{f3a5}",
	-- Statuts
	lock = "\u{f023}",
	unlock = "\u{f09c}",
	close = "\u{f00d}",
	check = "\u{f00c}",
	clock = "\u{f017}",
	alert = "\u{f071}",
	["exclamation"] = "\u{f12a}",
	info = "\u{f05a}",
	-- Divers
	bag = "\u{f290}",
	["shopping-bag"] = "\u{f290}",
	["shopping-cart"] = "\u{f07a}",
	users = "\u{f0c0}",
	user = "\u{f007}",
	home = "\u{f015}",
	map = "\u{f279}",
	cog = "\u{f013}",
	gear = "\u{f013}",
	trophy = "\u{f091}",
	heart = "\u{f004}",
	plus = "\u{f067}",
	minus = "\u{f068}",
	search = "\u{f002}",
	filter = "\u{f0b0}",
	["ellipsis-h"] = "\u{f141}",
	bars = "\u{f0c9}",
	-- Liaison / social
	wifi = "\u{f1eb}",
	globe = "\u{f0ac}",
	link = "\u{f0c1}",
	share = "\u{f064}",
	-- Classes MMORPG (proxy FA6 les plus proches)
	guardian = "\u{f3ed}",
	hunter = "\u{f6e0}",
	["crosshairs"] = "\u{f05b}",
	master = "\u{f19c}",
	["graduation-cap"] = "\u{f19d}",
	weaver = "\u{f7f0}",
}

-- Renvoie le codepoint FA6 pour un nom, ou nil
function Glyph.Code(name: string): string?
	return Glyph.Codes[name]
end

-- Renvoie la liste des noms disponibles
function Glyph.Names(): { string }
	local out = {}
	for name in Glyph.Codes do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

return Glyph