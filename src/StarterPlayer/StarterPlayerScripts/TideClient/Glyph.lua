-- Glyph : chargeur Font Awesome 6 Free (SIL OFL) — catalogue 200+ icones categorisees.
-- Asset ID Creator Store : 12187624912 (police famille Font Awesome 6 Free)
-- Fallback : nil si l'asset n'est pas uploade/configure — IconResolver utilise alors les primitives.
--
-- NOTE : FA6 Free Solid n'a PAS d'icones crabe/tortue/meduse/requin/etoile de mer/coquillage.
-- Ces 6 espaces sont couverts par CreatureIcons.lua (silhouettes dessinees, zone de H).

local Glyph = {}

---------------------------------------------------------------------- Police
-- Asset ID de la police Font Awesome 6 Free sur Roblox.
-- Remplacer par l'asset ID genere apres upload sur Creator Hub si different.
local FA_ASSET_ID = "rbxassetid://12187624912"

local faFontFace: Font? = nil
local attempted = false

-- Charge la FontFace une fois, renvoie nil si indisponible (silencieux)
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

function Glyph.IsLoaded(): boolean
	return Glyph.GetFont() ~= nil
end

-- Reinitialise le cache (debug / hot-reload)
function Glyph.Reload()
	attempted = false
	faFontFace = nil
end

---------------------------------------------------------------------- Catalogue
-- Codepoints Font Awesome 6 Free (Solid). Cle lisible -> codepoint Unicode prive FA.
Glyph.Codes = {
	-- ============================ ACTIONS / COMBAT ============================
	["arrow-right"] = "\u{f061}",
	arrow = "\u{f061}",
	["arrow-left"] = "\u{f060}",
	["arrow-up"] = "\u{f062}",
	["arrow-down"] = "\u{f063}",
	["arrows-rotate"] = "\u{f021}",
	sync = "\u{f021}",
	bolt = "\u{f0e7}",
	["bolt-lightning"] = "\u{e0b7}",
	fire = "\u{f06d}",
	snowflake = "\u{f2dc}",
	droplet = "\u{f043}",
	swords = "\u{f71e}",
	sword = "\u{f71e}",
	shield = "\u{f132}",
	["shield-halved"] = "\u{f3ed}",
	hammer = "\u{f6e3}",
	fist = "\u{f6de}",
	["hand-fist"] = "\u{f6de}",
	run = "\u{f70c}",
	["person-running"] = "\u{f70c}",
	swim = "\u{f5c4}",
	["person-swimming"] = "\u{f5c4}",
	crosshairs = "\u{f05b}",
	target = "\u{f05b}",
	burst = "\u{f4e2}",
	explosion = "\u{f4e2}",
	rocket = "\u{f135}",
	wand = "\u{f72b}",
	["wand-magic"] = "\u{f72b}",

	-- ============================ OBJETS / ECONOMIE ============================
	chest = "\u{f217}",
	box = "\u{f466}",
	["box-open"] = "\u{f49e}",
	cube = "\u{f1b2}",
	cubes = "\u{f1b1}",
	coin = "\u{f3d1}",
	coins = "\u{f51e}",
	["sack-dollar"] = "\u{f81f}",
	gem = "\u{f3a5}",
	["money-bill"] = "\u{f0d6}",
	cash = "\u{f0d6}",
	["money-bill-wave"] = "\u{f53a}",
	["credit-card"] = "\u{f09d}",
	wallet = "\u{f555}",
	gift = "\u{f06b}",
	star = "\u{f005}",
	["star-half"] = "\u{f089}",
	["star-half-stroke"] = "\u{f5c7}",
	heart = "\u{f004}",
	crown = "\u{f521}",
	spark = "\u{f890}",
	sparkles = "\u{f890}",
	trophy = "\u{f091}",
	medal = "\u{f5a2}",
	ribbon = "\u{f4d6}",
	key = "\u{f084}",
	["puzzle-piece"] = "\u{f12e}",
	puzzle = "\u{f12e}",
	feather = "\u{f56d}",
	dice = "\u{f522}",
	["dice-d20"] = "\u{f6cf}",
	d20 = "\u{f6cf}",
	["basket-shopping"] = "\u{f291}",
	["cart-shopping"] = "\u{f07a}",
	cart = "\u{f07a}",
	barcode = "\u{f02a}",
	["scale-balanced"] = "\u{f24e}",
	scale = "\u{f24e}",
	receipt = "\u{f543}",
	["file-invoice-dollar"] = "\u{f570}",
	bag = "\u{f290}",
	["shopping-bag"] = "\u{f290}",
	backpack = "\u{f5d4}",
	seedling = "\u{f4d8}",
	leaf = "\u{f06c}",

	-- ============================ NATURE / OCEAN ============================
	water = "\u{f773}",
	wave = "\u{f773}",
	["umbrella-beach"] = "\u{f5ca}",
	sun = "\u{f185}",
	moon = "\u{f186}",
	cloud = "\u{f0c2}",
	["cloud-rain"] = "\u{f73d}",
	rain = "\u{f73d}",
	["cloud-bolt"] = "\u{f76c}",
	["cloud-showers-heavy"] = "\u{f740}",
	wind = "\u{f72e}",
	tornado = "\u{f76f}",
	mountain = "\u{f6fc}",
	tree = "\u{f1bb}",
	volcano = "\u{f770}",
	compass = "\u{f14c}",
	["location-dot"] = "\u{f3c5}",
	route = "\u{f4d7}",
	flag = "\u{f024}",
	anchor = "\u{f13d}",
	ship = "\u{f21a}",
	fish = "\u{f578}",
	shrimp = "\u{f448}",
	otter = "\u{f70c}",
	dove = "\u{f4ba}",
	crow = "\u{f520}",
	horse = "\u{f6f0}",
	frog = "\u{f52e}",
	cat = "\u{f6be}",
	dog = "\u{f6d3}",
	paw = "\u{f1b0}",
	ghost = "\u{f6e2}",
	skull = "\u{f54c}",

	-- ============================ UI / NAVIGATION ============================
	lock = "\u{f023}",
	unlock = "\u{f09c}",
	["lock-open"] = "\u{f09c}",
	eye = "\u{f06e}",
	["eye-slash"] = "\u{f070}",
	close = "\u{f00d}",
	xmark = "\u{f00d}",
	check = "\u{f00c}",
	["circle-check"] = "\u{f058}",
	["circle-xmark"] = "\u{f057}",
	plus = "\u{f067}",
	minus = "\u{f068}",
	["circle-plus"] = "\u{f055}",
	["circle-minus"] = "\u{f056}",
	clock = "\u{f017}",
	["clock-rotate-left"] = "\u{f1da}",
	history = "\u{f1da}",
	hourglass = "\u{f254}",
	["hourglass-half"] = "\u{f252}",
	alert = "\u{f071}",
	["triangle-exclamation"] = "\u{f071}",
	info = "\u{f05a}",
	["circle-info"] = "\u{f05a}",
	question = "\u{f128}",
	["circle-question"] = "\u{f059}",
	gear = "\u{f013}",
	cog = "\u{f013}",
	gears = "\u{f085}",
	sliders = "\u{f1de}",
	["sliders-h"] = "\u{f1de}",
	bars = "\u{f0c9}",
	table = "\u{f0ce}",
	list = "\u{f03a}",
	["list-ul"] = "\u{f03a}",
	search = "\u{f002}",
	filter = "\u{f0b0}",
	sort = "\u{f0dc}",
	expand = "\u{f065}",
	compress = "\u{f066}",
	home = "\u{f015}",
	house = "\u{f015}",
	["arrow-left-long"] = "\u{f177}",
	back = "\u{f053}",
	up = "\u{f062}",
	down = "\u{f063}",
	left = "\u{f060}",
	right = "\u{f061}",
	["chevron-right"] = "\u{f054}",
	["chevron-left"] = "\u{f053}",
	["chevron-up"] = "\u{f077}",
	["chevron-down"] = "\u{f078}",
	["angles-up"] = "\u{f102}",
	["angles-down"] = "\u{f103}",
	["angles-right"] = "\u{f101}",
	map = "\u{f279}",
	["map-location-dot"] = "\u{f5a0}",
	["map-pin"] = "\u{f276}",
	pin = "\u{f276}",
	["signs-post"] = "\u{f277}",
	signpost = "\u{f277}",
	bookmark = "\u{f02e}",
	bell = "\u{f0f3}",
	envelope = "\u{f0e0}",
	tag = "\u{f02b}",
	tags = "\u{f02c}",
	ellipsis = "\u{f141}",

	-- ============================ HUD / STATS ============================
	heartbeat = "\u{f21e}",
	["battery-full"] = "\u{f240}",
	signal = "\u{f012}",
	wifi = "\u{f1eb}",
	["gauge-high"] = "\u{f625}",
	gauge = "\u{f625}",
	stopwatch = "\u{f2f2}",
	["ranking-star"] = "\u{f261}",
	ranking = "\u{f261}",
	["chart-line"] = "\u{f080}",
	chart = "\u{f080}",
	["chart-column"] = "\u{e0e3}",
	bullseye = "\u{f140}",
	["circle-dot"] = "\u{f192}",
	dot = "\u{f192}",
	square = "\u{f0c8}",
	circle = "\u{f111}",
	triangle = "\u{f2d2}",
	hexagon = "\u{f312}",
	percentage = "\u{f541}",

	-- ============================ SOCIAL / GUILDE ============================
	user = "\u{f007}",
	users = "\u{f0c0}",
	["user-plus"] = "\u{f234}",
	["user-minus"] = "\u{f503}",
	["user-group"] = "\u{f543}",
	["user-gear"] = "\u{f4fe}",
	["user-shield"] = "\u{f505}",
	["user-crown"] = "\u{f6a4}",
	["user-check"] = "\u{f4fc}",
	handshake = "\u{f2b5}",
	comment = "\u{f075}",
	["comment-dots"] = "\u{f4ad}",
	comments = "\u{f086}",
	bullhorn = "\u{f0a1}",
	megaphone = "\u{f0a1}",
	["cake-candles"] = "\u{f1fd}",
	cake = "\u{f1fd}",
	calendar = "\u{f133}",
	["calendar-days"] = "\u{f073}",
	["calendar-xmark"] = "\u{f273}",
	["calendar-check"] = "\u{f274}",
	["calendar-plus"] = "\u{f271}",
	landmark = "\u{f66f}",
	bank = "\u{f19c}",
	["building-columns"] = "\u{f19c}",
	certificate = "\u{f0a3}",
	scroll = "\u{f70e}",
	newspaper = "\u{f1ea}",
	quote = "\u{f10d}",
	["thumbs-up"] = "\u{f164}",
	["thumbs-down"] = "\u{f165}",
	shieldheart = "\u{f132}",

	-- ============================ CLASSES MMORPG ============================
	guardian = "\u{f3ed}",
	["shield-halved-class"] = "\u{f3ed}",
	hunter = "\u{f05b}",
	["crosshairs-class"] = "\u{f05b}",
	master = "\u{f19d}",
	["graduation-cap"] = "\u{f19d}",
	mage = "\u{f6e8}",
	["hat-wizard"] = "\u{f6e8}",
	staff = "\u{f71e}",
	weaver = "\u{f72e}",
	["wind-class"] = "\u{f72e}",
	["hands-holding-circle"] = "\u{f4fb}",
	summon = "\u{f0c4}",

	-- ============================ SYSTEMES / CONFIG ============================
	download = "\u{f019}",
	upload = "\u{f093}",
	power = "\u{f011}",
	["power-off"] = "\u{f011}",
	plug = "\u{f1e6}",
	database = "\u{f1c0}",
	server = "\u{f233}",
	hdd = "\u{f0a0}",
	memory = "\u{f538}",
	["microchip"] = "\u{f2db}",
	cpu = "\u{f2db}",
	["network-wired"] = "\u{f6ff}",
	network = "\u{f6ff}",
	["share-nodes"] = "\u{f1e0}",
	share = "\u{f1e0}",
	link = "\u{f0c1}",
	["link-slash"] = "\u{f127}",
	clipboard = "\u{f328}",
	["clipboard-list"] = "\u{f46d}",
	["list-check"] = "\u{f0ae}",
	task = "\u{f0ae}",
	toolbox = "\u{f552}",
	["screwdriver-wrench"] = "\u{f7d9}",
	wrench = "\u{f7d9}",
	bug = "\u{f188}",
	terminal = "\u{f120}",
	code = "\u{f121}",
	file = "\u{f15b}",
	["file-code"] = "\u{f1c9}",
	folder = "\u{f07b}",
	["folder-open"] = "\u{f07c}",
	archive = "\u{f187}",
	trash = "\u{f1f8}",
	["pen-to-square"] = "\u{f044}",
	edit = "\u{f044}",
	pen = "\u{f303}",
	["eyedropper"] = "\u{f1fb}",
	palette = "\u{f53f}",
	image = "\u{f03e}",
	images = "\u{f302}",
	camera = "\u{f030}",
	video = "\u{f03d}",
	film = "\u{f008}",
	music = "\u{f001}",
	["volume-high"] = "\u{f028}",
	["volume-xmark"] = "\u{f6a9}",
	play = "\u{f04b}",
	pause = "\u{f04c}",
	stop = "\u{f04d}",
	forward = "\u{f04e}",
	backward = "\u{f04a}",
	rotate = "\u{f2f1}",
	["clock-four"] = "\u{f017}",

	-- ============================ FINANCE / MONETISATION ============================
	robux = "\u{f158}",
	["ruble-sign"] = "\u{f158}",
	premium = "\u{f5a2}",
	vip = "\u{f521}",
	gamepass = "\u{f11b}",
	gamepad = "\u{f11b}",
	ticket = "\u{f145}",
	["badge-check"] = "\u{f02e}",
	gemstone = "\u{f3a5}",
}

---------------------------------------------------------------------- API

-- Renvoie le codepoint FA6 pour un nom, ou nil
function Glyph.Code(name: string): string?
	return Glyph.Codes[name]
end

-- Renvoie la liste triée des noms disponibles
function Glyph.Names(): { string }
	local out = {}
	for name in Glyph.Codes do
		table.insert(out, name)
	end
	table.sort(out)
	return out
end

function Glyph.Count(): number
	local n = 0
	for _ in Glyph.Codes do
		n += 1
	end
	return n
end

return Glyph
