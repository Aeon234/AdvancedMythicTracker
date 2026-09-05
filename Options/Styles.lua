local AMT = select(2, ...)

---@alias AMTStyleKey "MINIMAL"|"PANEL"|"AEON"

---@type table<AMTStyleKey, table>
local definitions = {
	MINIMAL = {
		background = { enabled = false },
		geometry = "SIZED",
		contentWidth = 200,
		justify = "RIGHT",
		bar = { showTicks = false },
		affixes = { widget = "TEXT", justify = "RIGHT" },
	},

	PANEL = {},

	AEON = {
		background = {
			color = { 31 / 255, 24 / 255, 19 / 255, 1 },
			nineslice = true,
		},
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
