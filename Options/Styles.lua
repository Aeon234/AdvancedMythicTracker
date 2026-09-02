local AMT = select(2, ...)

---@alias AMTStyleKey "MINIMAL"|"PANEL"|"AEON"

---@type table<AMTStyleKey, table>
local definitions = {
	MINIMAL = {
		background = { enabled = false },
		geometry = "SIZED",
		contentWidth = 200,
		justify = "RIGHT",
		-- Ticks on the timer bar are a Panel/Aeon feature; WarpDeplete's layout has none.
		bar = { showTicks = false },
		affixes = { widget = "TEXT", justify = "RIGHT" },
		keyInfo = { combineLevel = true },
	},

	PANEL = {},

	AEON = {
		background = { color = { 31 / 255, 24 / 255, 19 / 255, 1 } },
	},
}

---@class AMTStyles
---@field ORDER AMTStyleKey[]
local Styles = {}
AMT.Options.Styles = Styles

---@type AMTStyleKey[]
local order = {}

for key in pairs(definitions) do
	order[#order + 1] = key
end

table.sort(order)

Styles.ORDER = order

---@param key AMTStyleKey
---@return table?
function Styles.GetOverride(key)
	return definitions[key]
end

---@param key string
---@return boolean
function Styles.Exists(key)
	return definitions[key] ~= nil
end
