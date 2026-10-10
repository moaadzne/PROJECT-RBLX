-- Glyph : point de substitution unique des glyphes de l'interface.
--
-- Pourquoi ce module existe : les icones definitives dependent d'une decision de Moaad qui n'est
-- pas prise (Creator Store sous licence, ou atlas dessine). Tant qu'elle n'est pas prise, l'interface
-- ne doit dependre d'aucun fichier image : elle ne doit dependre que de ce module.
--
-- Un glyphe se resout dans cet ordre, et c'est tout le contrat :
--   1. une image fournie par C dans Assets.UI.Icons.<cle>      (Decal, Texture, ImageLabel, StringValue)
--   2. Font Awesome 6 (Creator Store, SIL OFL) si charge et cle mappée
--   3. le pictogramme dessine enregistre pour cette cle         (Theme le depose a l'init)
--   4. rien du tout : le glyphe est absent                     (l'appelant decide quoi afficher)
--
-- Quand la decision de Moaad tombe, une seule source change ici : aucune brique d'interface
-- n'a besoin d'etre retouchee, parce qu'aucune d'elles ne connait autre chose que Glyph.
--
-- Regle absolue (DIRECTION_V2) : aucun emoji, nulle part. Un glyphe est soit une image,
-- soit Font Awesome, soit dessine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local Glyph = {}

-- Dessins enregistres : cle -> fonction(parent, couleur, epaisseur)
local drawn: { [string]: (parent: Instance, color: Color3, thickness: number) -> () } = {}

-- Cles declarees comme disponibles par l'interface (meme si aucune image n'existe encore).
-- Sert a distinguer « glyphe inconnu » d'une erreur de saisie : une cle inconnue tombe sur le
-- glyphe de repli et ne casse jamais l'ecran.
local declared: { [string]: boolean } = {}

-- Racine ou C depose les images. Parametrable pour les tests et les maquettes.
Glyph.SourcePath = { "Assets", "UI", "Icons" }

-- Font Awesome 6 Free Solid (Creator Store, Asset ID 12187624912, SIL OFL).
-- Charge par InsertService au premier appel. Pas de FontFace prechargee : Roblox
-- ne garantit pas l'ordre de chargement des polices externes.
local FONT_AWESOME_ASSET_ID = 12187624912
local fontAwesomeFace: Font? = nil
local fontAwesomeLoading = false

-- Mapping cle UI -> point de code Font Awesome 6 Free Solid
-- https://fontawesome.com/v6/search?m=free&s=solid
local FA_CODEPOINTS = {
	alert      = 0xF06A, -- exclamation-triangle
	arrow      = 0xF061, -- arrow-right
	bolt       = 0xF0E7, -- bolt
	clock      = 0xF017, -- clock
	close      = 0xF00D, -- times (x)
	coin       = 0xF155, -- dollar-sign
	crown      = 0xF091, -- trophy
	dot        = 0xF111, -- circle
	down       = 0xF063, -- arrow-down
	info       = 0xF05A, -- info-circle
	lock       = 0xF023, -- lock
	moon       = 0xF186, -- moon
	net        = 0xF1EB, -- wifi
	revenge    = 0xF0E7, -- bolt (reutilise)
	ride       = 0xF206, -- motorcycle (approx turtle mount)
	shield     = 0xF132, -- shield-alt
	shop       = 0xF07A, -- shopping-cart
	spark      = 0xF0D1, -- magic
	unlock     = 0xF09C, -- unlock
	wave       = 0xF773, -- water
}

-- Charge Font Awesome via InsertService (async, silencieux).
local function ensureFontAwesome()
	if fontAwesomeFace or fontAwesomeLoading then
		return
	end
	fontAwesomeLoading = true
	task.spawn(function()
		local ok, model = pcall(function()
			return InsertService:LoadAsset(FONT_AWESOME_ASSET_ID)
		end)
		if ok and model then
			local fontObj = model:FindFirstChildWhichIsA("Font", true)
			if fontObj then
				fontAwesomeFace = Font.new(fontObj.Family, Enum.FontWeight.Regular)
			end
			model:Destroy()
		end
		fontAwesomeLoading = false
	end)
end

-- Cree un TextLabel Font Awesome pour `key`, ou nil si pas charge / pas mappe.
function Glyph.FATextLabel(key: string, size: number, color: Color3): TextLabel?
	ensureFontAwesome()
	local cp = FA_CODEPOINTS[key]
	if not cp or not fontAwesomeFace then
		return nil
	end
	local label = Instance.new("TextLabel")
	label.Name = "FAIcon"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(size, size)
	label.FontFace = fontAwesomeFace
	label.Text = utf8.char(cp)
	label.TextSize = size
	label.TextColor3 = color
	label.TextScaled = false
	return label
end

--------------------------------------------------------------- Resolution d'image

local function findNode(root: Instance, segments: { string }): Instance?
	local node = root
	for _, segment in segments do
		local child = node:FindFirstChild(segment)
		if not child then
			return nil
		end
		node = child
	end
	return node
end

-- Image d'un glyphe, si C en a depose une sous Assets.UI.Icons.<cle>. nil sinon.
function Glyph.Image(key: string): string?
	local node = findNode(ReplicatedStorage, Glyph.SourcePath)
	if not node then
		return nil
	end
	node = node:FindFirstChild(key)
	if not node then
		return nil
	end
	if node:IsA("Decal") or node:IsA("Texture") then
		local texture = node.Texture
		return if texture ~= "" then texture else nil
	elseif node:IsA("ImageLabel") or node:IsA("ImageButton") then
		local image = node.Image
		return if image ~= "" then image else nil
	elseif node:IsA("StringValue") then
		local value = node.Value
		return if value ~= "" then value else nil
	end
	return nil
end

--------------------------------------------------------------- Resolution

-- kind = "image"      -> image de C (Assets.UI.Icons)
-- kind = "fontawesome" -> Font Awesome 6 charge, `label` est un TextLabel pret
-- kind = "drawn"      -> pictogramme Theme enregistre
-- kind = "none"       -> rien
function Glyph.Resolve(key: string?): { kind: string, image: string?, label: TextLabel? }
	local k = key or ""
	if k == "" then
		return { kind = "none" }
	end
	-- 1. Image de C
	local image = Glyph.Image(k)
	if image then
		return { kind = "image", image = image }
	end
	-- 2. Font Awesome
	local faLabel = Glyph.FATextLabel(k, 24, Color3.new(1, 1, 1))
	if faLabel then
		return { kind = "fontawesome", label = faLabel }
	end
	-- 3. Dessine par Theme
	if drawn[k] then
		return { kind = "drawn" }
	end
	-- 4. Rien
	return { kind = "none" }
end

-- La cle est-elle connue de l'interface ? (evite de masquer une faute de frappe derriere un repli)
function Glyph.IsDeclared(key: string?): boolean
	return key ~= nil and declared[key] == true
end

function Glyph.HasImage(key: string?): boolean
	return Glyph.Resolve(key).kind == "image"
end

function Glyph.HasFontAwesome(key: string?): boolean
	local k = key or ""
	return FA_CODEPOINTS[k] ~= nil and (fontAwesomeFace ~= nil or fontAwesomeLoading)
end

-- Dessin enregistre pour une cle, ou nil.
function Glyph.Draw(key: string?)
	if not key then
		return nil
	end
	return drawn[key]
end

--------------------------------------------------------------- Enregistrement (Theme)

-- Theme depose ses pictogrammes une fois, a l'init. C'est le seul point ou l'interface
-- ajoute du contenu visuel a ce module.
function Glyph.RegisterDraw(key: string, drawFn: (parent: Instance, color: Color3, thickness: number) -> ())
	drawn[key] = drawFn
	declared[key] = true
end

-- Declarer une cle sans dessin : elle sera servie par une image ou Font Awesome plus tard.
function Glyph.Declare(key: string)
	declared[key] = true
end

return Glyph