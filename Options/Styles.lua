local AMT = select(2, ...)

---@alias AMTStyleKey "MINIMAL"|"PANEL"|"AEON"

---@type table<AMTStyleKey, table>
local definitions = {
	MINIMAL = {
		background = { enabled = false },
		geometry = "SIZED",
		justify = "RIGHT",
		clock = { placement = "ABOVE", slot = "RIGHT" },
		keyInfo = { inline = false },
		thresholds = { [2] = { marks = "TEXT" }, [3] = { marks = "TEXT" } },
		affixes = { widget = "TEXT" },
	},

	PANEL = {
		width = 330,
		order = { groups = { "keyInfo", "timer", "forces", "objectives" } },
		background = { color = { 0.06, 0.06, 0.07, 0.94 }, padding = 10 },
		bar = {
			texture = "Solid",
			height = 20,
			color = { 0.2, 0.45, 0.85, 1 },
			background = { 0.1, 0.1, 0.12, 0.9 },
			tickWidth = 2,
		},
		clock = { text = { size = 13, font = "Expressway", outline = "SLUG, OUTLINE" } },
		thresholds = {
			[1] = { text = { size = 13, font = "Expressway", outline = "SLUG, OUTLINE" } },
			[2] = { text = { size = 13, font = "Expressway", outline = "SLUG, OUTLINE" } },
			[3] = { text = { size = 13, font = "Expressway", outline = "SLUG, OUTLINE" } },
		},
		keyInfo = {
			inline = true,
			text = { size = 15, color = { 1, 0.82, 0, 1 }, font = "Expressway", outline = "SLUG, OUTLINE" },
			level = { size = 15, color = { 1, 0.82, 0, 1 }, font = "Expressway", outline = "SLUG, OUTLINE" },
		},
		affixes = { text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" } },
		deaths = {
			label = "TEXT",
			text = { size = 15, color = { 1, 0.25, 0.25, 1 }, font = "Expressway", outline = "SLUG, OUTLINE" },
		},
		forces = {
			bar = {
				texture = "Solid",
				height = 18,
				color = { 0.3, 0.7, 0.35, 1 },
				background = { 0.1, 0.1, 0.12, 0.9 },
			},
			title = {
				enabled = true,
				text = { size = 11, color = { 0.6, 0.6, 0.63, 1 }, font = "Expressway", outline = "SLUG, OUTLINE" },
			},
			count = {
				placement = "ABOVE",
				slot = "RIGHT",
				text = { size = 11, color = { 0.6, 0.6, 0.63, 1 }, font = "Expressway", outline = "SLUG, OUTLINE" },
			},
			percent = { text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" } },
		},
		objectives = {
			rowHeight = 20,
			iconSize = 14,
			text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" },
			time = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" },
			pendingColor = { 0.6, 0.6, 0.63, 1 },
			completedColor = { 0.35, 0.85, 0.35, 1 },
		},
		splits = {
			pbCompare = { text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" } },
			bossSplit = { text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" } },
			forcesSplit = { text = { size = 12, font = "Expressway", outline = "SLUG, OUTLINE" } },
		},
	},

	AEON = {
		background = {
			color = { 31 / 255, 24 / 255, 19 / 255, 1 },
			nineslice = true,
		},
	},
}

-- Temp Profile for Aeon
do
	local aeon = AMT.Util.Copy(definitions.PANEL)

	AMT.Util.Overlay(aeon, definitions.AEON)

	definitions.AEON = aeon
end

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
