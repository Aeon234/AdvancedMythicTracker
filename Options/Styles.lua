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
		elements = { keyInfoAffixes = { enabled = false } },
		order = { groups = { "keyInfo", "timer", "forces", "objectives" } },
		affixes = {
			iconSize = 14,
			text = {
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
			},
		},
		background = {
			color = {
				0.121569,
				0.094118,
				0.07451,
				1,
			},
			nineslice = true,
			padding = 10,
		},
		bar = {
			background = {
				0.1,
				0.1,
				0.12,
				0.9,
			},
			color = {
				0.2,
				0.45,
				0.85,
				1,
			},
			height = 21,
			texture = "Solid",
			tickWidth = 2,
			tierColors = {
				{
					0.34902,
					0.352941,
					0.360784,
					1,
				},
				{
					0.384314,
					0.768628,
					1,
					1,
				},
				{
					0.384314,
					0.768628,
					1,
					1,
				},
				{
					0.25098,
					0.752941,
					0.25098,
					1,
				},
			},
		},
		clock = {
			text = {
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 14,
			},
		},
		deaths = {
			text = {
				color = {
					1,
					0.25098,
					0.25098,
					1,
				},
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
		},
		decimals = 3,
		failColor = {
			0.74902,
			0.14902,
			0.14902,
			1,
		},
		forces = {
			bar = {
				background = {
					0.1,
					0.1,
					0.12,
					0.9,
				},
				color = {
					0.2,
					0.576471,
					0.498039,
					1,
				},
				height = 21,
				texture = "Solid",
			},
			completedColor = {
				1,
				0.709804,
				0,
				1,
			},
			count = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			percent = {
				slot = "LEFT",
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			title = {
				text = {
					color = {
						0.6,
						0.6,
						0.63,
						1,
					},
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
		},
		keyInfo = {
			height = 14,
			inline = true,
			level = {
				color = {
					1,
					0.82,
					0,
					1,
				},
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
			text = {
				color = {
					1,
					0.82,
					0,
					1,
				},
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
		},
		objectives = {
			completedColor = {
				0.34902,
				0.85098,
				0.34902,
				1,
			},
			icon = false,
			iconSize = 14,
			pendingColor = {
				0.6,
				0.6,
				0.63,
				1,
			},
			rowHeight = 18,
			spacing = 0,
			text = {
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 14,
			},
			time = {
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 14,
			},
		},
		splits = {
			aheadColor = {
				0.34902,
				0.85098,
				0.34902,
				1,
			},
			behindColor = {
				1,
				0.25098,
				0.25098,
				1,
			},
			bossSplit = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
			forcesSplit = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
			pbCompare = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
		},
		thresholds = {
			{
				aheadColor = {
					0.34902,
					0.85098,
					0.34902,
					1,
				},
				behindColor = {
					1,
					0.25098,
					0.25098,
					1,
				},
				enabled = true,
				marks = "TEXT",
				nudge = {
					0,
					0,
				},
				text = {
					color = {
						1,
						1,
						1,
						1,
					},
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
				tickColor = {
					1,
					1,
					1,
					0.5,
				},
			},
			{
				aheadColor = {
					0.34902,
					0.85098,
					0.34902,
					1,
				},
				behindColor = {
					1,
					0.25098,
					0.25098,
					1,
				},
				enabled = true,
				marks = "BOTH",
				nudge = {
					0,
					0,
				},
				text = {
					color = {
						1,
						1,
						1,
						1,
					},
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
				tickColor = {
					1,
					1,
					1,
					0.5,
				},
			},
			{
				aheadColor = {
					0.34902,
					0.85098,
					0.34902,
					1,
				},
				behindColor = {
					1,
					0.25098,
					0.25098,
					1,
				},
				enabled = true,
				marks = "BOTH",
				nudge = {
					0,
					0,
				},
				text = {
					color = {
						1,
						1,
						1,
						1,
					},
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
				tickColor = {
					1,
					1,
					1,
					0.5,
				},
			},
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
