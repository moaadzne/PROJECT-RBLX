-- ContextualHint : tutoriel invisible (Cycle 1, tâche 5 — apprendre en jouant, ZÉRO popup bloquant).
-- Principe : chaque indice apparait AU MOMENT ou le joueur vit la situation, UNE SEULE FOIS,
-- jamais bloquant (pas de pause, pas de bouton a fermer), et jamais si le joueur a deja agi seul.
-- L'ordre est celui du GDD §1.1 : on complete la cinematique par des reperes, pas par des textes.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local ContextualHint = {}

local player = Players.LocalPlayer

local Util, Theme, Fx, Store, Settings
local hintLabel: TextLabel? = nil
local hintStroke: UIStroke? = nil
local shown = {} -- [cle] = true : un seul affichage par cle
local currentKey = nil
local hideAt = 0

-- Un indice = une ligne courte, en capitales condensees (DIRECTION_V2), 2-5 mots, aucun emoji.
-- Clef = declencheur. Le texte reste factuel : il nomme ce que le joueur voit, pas ce qu'il doit lire.
local HINTS = {
	-- Post-31.5s : au tout debut du jeu libre, on rappelle le seul point focal utile
	lagoonEntry = { text = "Wait for the wave. Catch. Come home.", duration = 4 },
	-- premiere capture reussie (Notify capture)
	firstCatch = { text = "Bag full? Bring it home.", duration = 4 },
	-- alerte : pendant la fenetre de vol
	waveWindow = { text = "Lagoons open. Steal what you can.", duration = 4 },
	-- retour au lagon : depot automatique
	deposit = { text = "They swim. They grow.", duration = 3.5 },
	-- premier lagon plein / creature remplacee
	released = { text = "Trade it or keep it.", duration = 3.5 },
	-- Codex : premiere nouvelle espece
	newSpecies = { text = "New species logged.", duration = 3 },
	-- monture debloquee (Elder)
	mountable = { text = "Ride the wave. Titan surfs.", duration = 4 },
	-- Golden Tide
	goldenTide = { text = "Golden tide. Golden odds.", duration = 4 },
}

local function ensureLabel()
	if hintLabel then
		return
	end
	hintLabel = Theme.Text({
		Name = "ContextualHint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.86),
		Size = UDim2.fromOffset(640, 44),
		Text = "",
		TextSize = Theme.TextSize.Large,
		FontFace = Theme.Fonts.Title,
		TextWrapped = true,
		Visible = false,
		ZIndex = 9,
		Parent = player.PlayerGui:FindFirstChild("TideOverlay") or player.PlayerGui:FindFirstChild("TideHUD"),
	})
	hintStroke = Instance.new("UIStroke")
	hintStroke.Color = Theme.Colors.TextShadow
	hintStroke.Transparency = 0.5
	hintStroke.Thickness = 1.5
	hintStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	hintStroke.Parent = hintLabel
end

local function hide()
	if hintLabel then
		TweenService:Create(hintLabel, TweenInfo.new(Theme.Time.Fast, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
		if hintStroke then
			TweenService:Create(hintStroke, TweenInfo.new(Theme.Time.Fast, Enum.EasingStyle.Quad), { Transparency = 1 }):Play()
		end
		task.delay(Theme.Time.Fast + 0.02, function()
			if hintLabel and currentKey == nil then
				hintLabel.Visible = false
			end
		end)
	end
	currentKey = nil
end

-- Affiche un indice UNE SEULE FOIS. Renvoie true s'il a ete affiche.
function ContextualHint.Show(key: string): boolean
	if shown[key] or not HINTS[key] then
		return false
	end
	shown[key] = true
	-- un indice plus recent remplace l'ancien sans l'empiler
	hide()
	local hint = HINTS[key]
	currentKey = key
	ensureLabel()
	if not hintLabel then
		return false
	end
	hintLabel.Text = Theme.Caps(hint.text)
	hintLabel.Visible = true
	hintLabel.TextTransparency = 1
	if hintStroke then
		hintStroke.Transparency = 1
	end
	TweenService:Create(hintLabel, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
	if hintStroke then
		TweenService:Create(hintStroke, TweenInfo.new(Theme.Time.Normal, Enum.EasingStyle.Quad), { Transparency = 0.5 }):Play()
	end
	Theme.Pop(hintLabel, 0.04)
	hideAt = os.clock() + hint.duration
	return true
end

-- Indices pilotes par les evenements serveur (Store.Notified) et l'etat local :
-- aucune action du joueur n'est bloquee, chaque indice s'effface tout seul.
function ContextualHint.Start(ctx)
	Store = ctx.Store
	if not (Store and Store.Notified) then
		return
	end
	-- Kinds du contrat v2.1 : on reagit a ce que le joueur vit, pas a ce qu'on lui demande
	Store.Notified:Connect(function(kind, data)
		if kind == "capture" then
			ContextualHint.Show("firstCatch")
		elseif kind == "deposit" then
			ContextualHint.Show("deposit")
		elseif kind == "released" then
			ContextualHint.Show("released")
		elseif kind == "codex" and type(data) == "table" and data.rowComplete then
			ContextualHint.Show("newSpecies")
		end
	end)
	-- Fenetre de vol : a l'alerte, une fois par session (les lagons s'ouvrent)
	local windowHinted = false
	if Store.WaveChanged then
		Store.WaveChanged:Connect(function(wave)
			if type(wave) ~= "table" then
				return
			end
			if not windowHinted and (wave.phase == "warning" or wave.phase == "wave") then
				windowHinted = true
				ContextualHint.Show("waveWindow")
			end
			if wave.tide == "Golden" and wave.phase == "calm" then
				ContextualHint.Show("goldenTide")
			end
		end)
	end
	-- Boucle d'extinction de l'indice courant
	task.spawn(function()
		while true do
			task.wait(0.2)
			if currentKey and os.clock() >= hideAt then
				hide()
			end
		end
	end)
end

function ContextualHint.Init(ctx)
	Util, Theme, Fx, Settings, Store = ctx.Util, ctx.Theme, ctx.Fx, ctx.Settings, ctx.Store
end

-- Reinitialise tous les indices (nouveau joueur / debug)
function ContextualHint.Reset()
	shown = {}
	hide()
end

return ContextualHint