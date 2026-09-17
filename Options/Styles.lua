local AMT = select(2, ...)

---@alias AMTStyleKey "MINIMAL"|"PANEL"|"AEON"

---@type table<AMTStyleKey, table>
local definitions = {
	MINIMAL = {
		affixes = {
			widget = "TEXT",
		},
		background = {
			enabled = false,
		},
		bar = {
			border = false,
			height = 16,
			mode = "SEGMENTED",
			texture = "Atrocity",
		},
		clock = {
			placement = "ABOVE",
			slot = "RIGHT",
		},
		decimals = 3,
		forces = {
			bar = {
				border = false,
				texture = "Atrocity",
			},
			percent = {
				slot = "LEFT",
			},
		},
		geometry = "SIZED",
		keyInfo = {
			inline = false,
		},
		objectives = {
			icon = false,
		},
		order = {
			forces = { "forcesBar" },
			groups = { "keyInfo", "timer", "forces", "objectives" },
			keyInfo = { "deaths", "keyInfoAffixes", "keyInfoTitle" },
			objectives = { "objectiveRows" },
			timer = { "timerBar" },
		},
		splits = {
			decimals = 2,
			forcesSplit = {
				placement = "BESIDE",
			},
		},
		thresholds = {
			[2] = {
				marks = "BOTH",
			},
			[3] = {
				marks = "BOTH",
			},
		},
	},

	PANEL = {
		affixes = {
			text = {
				font = "Expressway",
				outline = "SLUG, OUTLINE",
			},
		},
		background = {
			color = { 0.06, 0.06, 0.07, 0.94 },
			padding = 10,
		},
		bar = {
			background = { 0.1, 0.1, 0.12, 0.9 },
			border = false,
			color = { 0.2, 0.45, 0.85, 1 },
			height = 20,
			texture = "Solid",
			tickWidth = 2,
		},
		clock = {
			text = {
				font = "Expressway",
				outline = "SLUG, OUTLINE",
				size = 13,
			},
		},
		deaths = {
			label = "TEXT",
			text = {
				color = { 1, 0.25, 0.25, 1 },
				font = "Expressway",
				outline = "SLUG, OUTLINE",
				size = 15,
			},
		},
		forces = {
			bar = {
				background = { 0.1, 0.1, 0.12, 0.9 },
				border = false,
				color = { 0.3, 0.7, 0.35, 1 },
				height = 18,
				texture = "Solid",
			},
			count = {
				placement = "ABOVE",
				text = {
					color = { 0.6, 0.6, 0.63, 1 },
					font = "Expressway",
					outline = "SLUG, OUTLINE",
					size = 11,
				},
			},
			percent = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
			title = {
				enabled = true,
				text = {
					color = { 0.6, 0.6, 0.63, 1 },
					font = "Expressway",
					outline = "SLUG, OUTLINE",
					size = 11,
				},
			},
		},
		keyInfo = {
			inline = true,
			level = {
				color = { 1, 0.82, 0, 1 },
				font = "Expressway",
				outline = "SLUG, OUTLINE",
				size = 15,
			},
			text = {
				color = { 1, 0.82, 0, 1 },
				font = "Expressway",
				outline = "SLUG, OUTLINE",
				size = 15,
			},
		},
		objectives = {
			completedColor = { 0.35, 0.85, 0.35, 1 },
			iconSize = 14,
			pendingColor = { 0.6, 0.6, 0.63, 1 },
			rowHeight = 20,
			text = {
				font = "Expressway",
				outline = "SLUG, OUTLINE",
			},
			time = {
				font = "Expressway",
				outline = "SLUG, OUTLINE",
			},
		},
		order = {
			forces = { "forcesBar" },
			keyInfo = { "deaths", "keyInfoAffixes", "keyInfoTitle" },
			objectives = { "objectiveRows" },
			timer = { "timerBar" },
		},
		splits = {
			bossSplit = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
			forcesSplit = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
			pbCompare = {
				nudge = { -6, 0 },
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
		},
		thresholds = {
			[1] = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
			[2] = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
			[3] = {
				text = {
					font = "Expressway",
					outline = "SLUG, OUTLINE",
				},
			},
		},
	},

	AEON = {
		affixes = {
			iconSize = 14,
			text = {
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
			},
		},
		background = {
			color = { 0.078431, 0.078431, 0.078431, 0.9 },
			nineslice = true,
			padding = 10,
		},
		bar = {
			background = { 0.1, 0.1, 0.12, 0.9 },
			color = { 0.2, 0.45, 0.85, 1 },
			height = 21,
			mode = "SEGMENTED",
			texture = "Solid",
			tickWidth = 2,
			tierColors = {
				{ 0.34902, 0.352941, 0.360784, 1 },
				{ 0.384314, 0.768628, 1, 1 },
				{ 1, 0.709804, 0, 1 },
				{ 0.25098, 0.752941, 0.25098, 1 },
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
				color = { 1, 0.25098, 0.25098, 1 },
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
		},
		decimals = 3,
		elements = {
			keyInfoAffixes = {
				enabled = false,
			},
		},
		failColor = { 0.74902, 0.14902, 0.14902, 1 },
		forces = {
			bar = {
				background = { 0.1, 0.1, 0.12, 0.9 },
				color = { 0.2, 0.576471, 0.498039, 1 },
				height = 21,
				texture = "Solid",
			},
			completedColor = { 1, 0.709804, 0, 1 },
			count = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			percent = {
				nudge = { -3, -1 },
				slot = "LEFT",
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			title = {
				text = {
					color = { 0.6, 0.6, 0.63, 1 },
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
		},
		keyInfo = {
			height = 14,
			inline = true,
			level = {
				color = { 1, 0.82, 0, 1 },
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
			text = {
				color = { 1, 0.82, 0, 1 },
				font = "Gilroy Bold",
				outline = "SLUG, OUTLINE",
				size = 16,
			},
		},
		objectives = {
			completedColor = { 0.34902, 0.85098, 0.34902, 1 },
			icon = false,
			iconSize = 14,
			pendingColor = { 0.6, 0.6, 0.63, 1 },
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
		order = {
			forces = { "forcesBar" },
			groups = { "keyInfo", "timer", "forces", "objectives" },
			keyInfo = { "deaths", "keyInfoAffixes", "keyInfoTitle" },
			objectives = { "objectiveRows" },
			timer = { "timerBar" },
		},
		splits = {
			aheadColor = { 0.34902, 0.85098, 0.34902, 1 },
			behindColor = { 1, 0.25098, 0.25098, 1 },
			bossSplit = {
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
			forcesSplit = {
				nudge = { -6, -1 },
				placement = "BESIDE",
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
			pbCompare = {
				nudge = { -6, 0 },
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
				},
			},
		},
		thresholds = {
			{
				aheadColor = { 0.34902, 0.85098, 0.34902, 1 },
				behindColor = { 1, 0.25098, 0.25098, 1 },
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			{
				aheadColor = { 0.34902, 0.85098, 0.34902, 1 },
				behindColor = { 1, 0.25098, 0.25098, 1 },
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
				},
			},
			{
				aheadColor = { 0.34902, 0.85098, 0.34902, 1 },
				behindColor = { 1, 0.25098, 0.25098, 1 },
				text = {
					font = "Gilroy Bold",
					outline = "SLUG, OUTLINE",
					size = 14,
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
