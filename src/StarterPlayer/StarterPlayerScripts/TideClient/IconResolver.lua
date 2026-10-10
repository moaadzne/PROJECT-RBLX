-- IconResolver : facade unique pour les icones de l'interface.
-- Mapping : cle UI -> Font Awesome 6 (Creator Store, asset 12187624912, SIL OFL) avec repli
-- sur le pictogramme dessine de Glyph (aucun emoji, aucune image inventee).
-- Si Moaad tranche d'icones plus tard, on change uniquement ce fichier.

local InsertService = game:GetService("InsertService")
local Glyph = require(script.Parent:WaitForChild("Glyph"))
local Theme = require(script.Parent:WaitForChild("Theme"))

local IconResolver = {}

-- Font Awesome 6 Free Solid (Creator Store, SIL OFL)
local FONT_AWESOME_ASSET_ID = 12187624912
local fontLoaded = false
local fontFace = nil

local function loadFont()
	if fontLoaded then return end
	fontLoaded = true
	task.spawn(function()
		local ok, model = pcall(function()
			return InsertService:LoadAsset(FONT_AWESOME_ASSET_ID)
		end)
		if ok and model then
			local f = model:FindFirstChildWhichIsA("Font", true)
			if f then
				fontFace = Font.new(f.Family, Enum.FontWeight.Regular)
			end
			model:Destroy()
		end
	end)
end

loadFont()

---------------------------------------------------------------- Mapping (demande D)
-- cle UI -> { fa = codepoint Font Awesome 6 Free Solid, fallback = cle picto Glyph }
local ICONS = {
	ride    = { fa = 0xF5A4, fallback = "ride" },   -- person-surfing
	lock    = { fa = 0xF023, fallback = "lock" },   -- lock
	unlock  = { fa = 0xF09C, fallback = "unlock" }, -- unlock
	codex   = { fa = 0xF02D, fallback = "coin" },   -- book
	shop    = { fa = 0xF54E, fallback = "shop" },   -- store
	steal   = { fa = 0xF255, fallback = "revenge" },-- hand-back-fist
	royal   = { fa = 0xF521, fallback = "crown" },  -- crown
	wave    = { fa = 0xF773, fallback = "wave" },   -- water
	bag     = { fa = 0xF290, fallback = "net" },    -- bag-shopping
	settings= { fa = 0xF013, fallback = "alert" },  -- gear
	close   = { fa = 0xF00D, fallback = "close" },  -- xmark
	alert   = { fa = 0xF071, fallback = "alert" },  -- triangle-exclamation
	shield  = { fa = 0xF3ED, fallback = "shield" }, -- shield-halved
	crown   = { fa = 0xF521, fallback = "crown" },  -- crown
	spark   = { fa = 0xF5A2, fallback = "spark" },  -- wand-magic-sparkles
	moon    = { fa = 0xF186, fallback = "moon" },   -- moon
	bolt    = { fa = 0xF0E7, fallback = "bolt" },   -- bolt
	coin    = { fa = 0xF3D1, fallback = "coin" },   -- coins
	info    = { fa = 0xF05A, fallback = "info" },   -- circle-info
	clock   = { fa = 0xF017, fallback = "clock" },  -- clock
	arrow   = { fa = 0xF061, fallback = "arrow" },  -- arrow-right
	down    = { fa = 0xF063, fallback = "down" },   -- arrow-down
	revenge = { fa = 0xF255, fallback = "revenge" },-- hand-back-fist
	star    = { fa = 0xF005, fallback = "spark" },  -- star
	net     = { fa = 0xF6DB, fallback = "net" },    -- fish-finned
	dot     = { fa = 0xF111, fallback = "dot" },    -- circle
	chest   = { fa = 0xF466, fallback = "coin" },   -- treasure-chest
	-- cles historiques conservees pour ne casser aucun module existant
	book    = { fa = 0xF02D, fallback = "coin" },
}

---------------------------------------------------------------- Resolve

-- Cree l'objet GUI complet (TextLabel Font Awesome, sinon pictogramme dessine)
function IconResolver.Create(name: string?, size: number, color: Color3?): GuiObject
	local c = color or Theme.Colors.Text
	local spec = ICONS[name or ""]
	
	-- Font Awesome si charge et si la cle est connue
	if fontFace and spec then
		return Theme.Create("TextLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(size, size),
			FontFace = fontFace,
			Text = utf8.char(spec.fa),
			TextSize = size,
			TextColor3 = c,
			TextScaled = false,
			ZIndex = 2,
		})
	end
	
	-- Repli : pictogramme dessine
	local key = (spec and spec.fallback) or name or "dot"
	return Theme.Icon(key, size, c)
end

function IconResolver.Resolve(name: string?)
	local spec = ICONS[name or ""]
	return spec
end

return IconResolver
