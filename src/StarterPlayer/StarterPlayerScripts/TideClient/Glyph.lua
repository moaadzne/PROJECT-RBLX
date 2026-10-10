-- Glyph : point de substitution unique des glyphes de l'interface.
--
-- Pourquoi ce module existe : les icones definitives dependent d'une decision de Moaad qui n'est
-- pas prise (Creator Store sous licence, ou atlas dessine). Tant qu'elle ne l'est pas, l'interface
-- ne doit dependre d'aucun fichier image : elle ne doit dependre que de ce module.
--
-- Un glyphe se resout dans cet ordre, et c'est tout le contrat :
--   1. une image fournie par C dans Assets.UI.Icons.<cle>      (Decal, Texture, ImageLabel, StringValue)
--   2. le pictogramme dessine enregistre pour cette cle         (Theme le depose a l'init)
--   3. rien du tout : le glyphe est absent                     (l'appelant decide quoi afficher)
--
-- Quand la decision de Moaad tombe, une seule source change ici : aucune brique d'interface
-- n'a besoin d'etre retouchee, parce qu'aucune d'elles ne connait autre chose que Glyph.
--
-- Regle absolue (DIRECTION_V2) : aucun emoji, nulle part. Un glyphe est soit une image, soit dessine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Glyph = {}

-- Dessins enregistres : cle -> fonction(parent, couleur, epaisseur)
local drawn: { [string]: (parent: Instance, color: Color3, thickness: number) -> () } = {}

-- Cles declarees comme disponibles par l'interface (meme si aucune image n'existe encore).
-- Sert a distinguer « glyphe inconnu » d'une erreur de saisie : une cle inconnue tombe sur le
-- glyphe de repli et ne casse jamais l'ecran.
local declared: { [string]: boolean } = {}

-- Racine ou C depose les images. Parametrable pour les tests et les maquettes.
Glyph.SourcePath = { "Assets", "UI", "Icons" }

---------------------------------------------------------------- Resolution d'image

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

---------------------------------------------------------------- Resolution

-- kind = "image"  -> une image est disponible, `image` contient son id
-- kind = "drawn"  -> aucun fichier, un pictogramme est enregistre pour cette cle
-- kind = "none"   -> ni l'un ni l'autre : l'appelant n'affiche aucun glyphe
function Glyph.Resolve(key: string?): { kind: string, image: string? }
	local k = key or ""
	if k == "" then
		return { kind = "none" }
	end
	local image = Glyph.Image(k)
	if image then
		return { kind = "image", image = image }
	end
	if drawn[k] then
		return { kind = "drawn" }
	end
	return { kind = "none" }
end

-- La cle est-elle connue de l'interface ? (evite de masquer une faute de frappe derriere un repli)
function Glyph.IsDeclared(key: string?): boolean
	return key ~= nil and declared[key] == true
end

function Glyph.HasImage(key: string?): boolean
	return Glyph.Resolve(key).kind == "image"
end

-- Dessin enregistre pour une cle, ou nil.
function Glyph.Draw(key: string?)
	if not key then
		return nil
	end
	return drawn[key]
end

---------------------------------------------------------------- Enregistrement (Theme)

-- Theme depose ses pictogrammes une fois, a l'init. C'est le seul point ou l'interface
-- ajoute du contenu visuel a ce module.
function Glyph.RegisterDraw(key: string, drawFn: (parent: Instance, color: Color3, thickness: number) -> ())
	drawn[key] = drawFn
	declared[key] = true
end

-- Declarer une cle sans dessin : elle sera servie par une image plus tard, ou rien du tout.
function Glyph.Declare(key: string)
	declared[key] = true
end

return Glyph
