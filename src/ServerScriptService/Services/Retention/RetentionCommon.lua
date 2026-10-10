-- RetentionCommon : helpers partages par les services de retention (J).
-- Aucun effet de bord ici : horloge, nombres surs, bus d'evenements internes,
-- notifications (toujours via un kind du contrat, voir plus bas) et analytics.
--
-- Notifications : le client (Notifications.lua, zone B) n'affiche un toast que pour
-- les kinds de son KIND_STYLE. Les kinds de retention n'y sont pas encore : on
-- envoie donc tout en kind "info" (style existant) avec data.text en anglais et
-- data.retention = tag, pour que B puisse plus tard brancher des styles dedies
-- sans rien perdre d'ici la.
local Net = require(script.Parent.Parent.Net)

local RetentionCommon = {}

-- Journee de retention : bascule a 4h du matin UTC (decision D : reset 4h du matin)
function RetentionCommon.DayNumber()
	return math.floor((os.time() - 4 * 3600) / 86400)
end

-- Numero de semaine (bascule lundi 4h du matin UTC)
function RetentionCommon.WeekNumber()
	return math.floor((os.time() - 4 * 3600) / 604800)
end

function RetentionCommon.Num(value, default, minValue, maxValue)
	if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return default
	end
	if minValue and value < minValue then
		value = minValue
	end
	if maxValue and value > maxValue then
		value = maxValue
	end
	return value
end

-- Notification de retention : kind "info" du contrat + tag pour le client
function RetentionCommon.Notify(player, tag, text, extra)
	local data = { text = text, retention = tag }
	if type(extra) == "table" then
		for key, value in pairs(extra) do
			data[key] = value
		end
	end
	Net.Notify(player, "info", data)
end

function RetentionCommon.NotifyAll(tag, text, extra)
	local players = game:GetService("Players")
	for _, player in ipairs(players:GetPlayers()) do
		RetentionCommon.Notify(player, tag, text, extra)
	end
end

-- Analytics sans risque : jamais dans le fil de jeu, jamais bloquant
function RetentionCommon.Analytics(name, fields)
	local ok, analytics = pcall(function()
		return game:GetService("AnalyticsService")
	end)
	if not ok then
		return
	end
	pcall(function()
		analytics:FireEvent(name, fields)
	end)
end

-- Bus interne : un service emet, les autres ecoutent (aucune dependance entre modules)
local bus = {}

function RetentionCommon.On(event, fn)
	local list = bus[event]
	if not list then
		list = {}
		bus[event] = list
	end
	table.insert(list, fn)
end

function RetentionCommon.Emit(event, player, ...)
	local list = bus[event]
	if not list then
		return
	end
	for _, fn in ipairs(list) do
		local ok, err = pcall(fn, player, ...)
		if not ok then
			warn("[TideRush] retention bus " .. event .. " : " .. tostring(err))
		end
	end
end

-- Code d'invitation deterministe : memee calcul cote client possible (aucun remote necessaire).
-- Base36 du UserId, prefixe lisible, checksum leger.
local BASE36 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function RetentionCommon.InviteCode(userId)
	local n = math.floor(RetentionCommon.Num(userId, 0, 0))
	local out = {}
	repeat
		local rest = n % 36
		table.insert(out, 1, BASE36:sub(rest + 1, rest + 1))
		n = math.floor(n / 36)
	until n == 0
	local code = table.concat(out)
	if #code < 6 then
		code = string.rep("0", 6 - #code) .. code
	end
	return "TIDE-" .. code
end

-- Decode un code en UserId (0 si invalide)
function RetentionCommon.DecodeInvite(code)
	if type(code) ~= "string" or not string.match(code, "^TIDE%-[0-9A-Z]+$") then
		return 0
	end
	local body = string.sub(code, 6)
	local n = 0
	for i = 1, #body do
		local digit = string.find(BASE36, body:sub(i, i)) - 1
		if digit < 0 then
			return 0
		end
		n = n * 36 + digit
	end
	return n
end

return RetentionCommon
