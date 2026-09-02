local AMT = select(2, ...)

---@param _ table
---@param key string
---@return string
local function FallBackToKey(_, key)
	return key
end

---@class AMTLocale : table<string, string>
local L = setmetatable({}, { __index = FallBackToKey })
AMT.L = L

---@type table<string, string[]>
local affixNameFilters = {
	enUS = {
		"Xal'atath's",
		"Challenger's",
		"Bargain:",
		"Eternus's",
		"Trial:",
		"Dusk",
		"of",
		"the",
		"Sands",
		"Timeways",
		"Twilight",
	},
	deDE = { "Xal'ataths", "des Herausforderers", "Handel:" },
	esES = { "Xal'atath", "contendiente", "Trato", "de", ":" },
	koKR = { "잘아타스의 제안:", "도전자의" },
	ptBR = { "Barganha de Xal'atath:" },
	zhCN = { "萨拉塔斯的交易：", "挑战者的" },
	zhTW = { "薩拉塔斯的交易：", "挑戰者的" },
}

---@class AMTLocaleUtil
local Locale = {}
AMT.Locale = Locale

---@param name string
---@return string
function Locale.FormatAffixName(name)
	local filters = affixNameFilters[GetLocale()]

	if not filters then
		return name
	end

	local result = name

	for _, filter in ipairs(filters) do
		result = result:gsub(filter, "")
	end

	-- Removing interior words leaves runs of spaces behind, so collapse before trimming.
	return AMT.Util.Trim((result:gsub("%s+", " ")))
end
