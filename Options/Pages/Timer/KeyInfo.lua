local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local PREVIEW_WHITE = { 1, 1, 1 }

---@return boolean
local function IsInline()
	return Options.Get("timer.keyInfo.inline") == true
end

---@return boolean
local function IsStacked()
	return not IsInline()
end

---@return boolean
local function IsTextMode()
	return Options.Get("timer.affixes.widget") == "TEXT"
end

---@return string
local function PreviewText()
	local module = AMT.Modules.Get("Deaths") --[[@as AMTDeathsModule]]

	if not module then
		return ""
	end

	local text = module:FormatText()

	if text == "" or Options.Get("timer.deaths.label") ~= "SKULL" then
		return text
	end

	return ("%s |T%s:0|t"):format(text, module.SKULL)
end

Options.RegisterPage({
	id = "timer.keyInfo",
	parent = "timer",
	order = 30,
	name = L["Key Info"],
	Build = function(page)
		page:SetHeader({
			description = L["The dungeon name, this week's affixes and the death count."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "checkbox",
				label = L["Combine Into A Single Line"],
				path = "timer.keyInfo.inline",
				tooltip = L["Combines the name, affixes and deaths into a single row."],
			},

			{
				type = "slider",
				label = L["Row Height"],
				path = "timer.keyInfo.height",
				min = 10,
				max = 32,
				step = 1,
				hidden = IsStacked,
			},
		})

		local title = page:AddGroup({
			title = L["Dungeon Name & Level"],
			enabledPath = "timer.elements.keyInfoTitle.enabled",
		})

		title.content:AddWidgets({
			{
				type = "slider",
				label = L["Row Height"],
				path = "timer.keyInfo.height",
				min = 10,
				max = 32,
				step = 1,
				hidden = IsInline,
			},

			{
				type = "segmented",
				label = SHOW,
				path = "timer.keyInfo.show",
				tooltip = L["Show the key level, the dungeon name, or both."],
				values = { { "LEVEL", LEVEL }, { "NAME", NAME }, { "BOTH", L["Both"] } },
			},

			{
				type = "segmented",
				label = L["Order"],
				path = "timer.keyInfo.order",
				tooltip = L["Which comes first when both are shown."],
				values = { { "LEVEL_FIRST", L["Level First"] }, { "NAME_FIRST", L["Name First"] } },
				hidden = function()
					return Options.Get("timer.keyInfo.show") ~= "BOTH"
				end,
			},
		})

		title.content:AddFontGroup(NAME, "timer.keyInfo.text", function()
			return Options.Get("timer.keyInfo.show") == "LEVEL"
		end)

		title.content:AddFontGroup(LEVEL, "timer.keyInfo.level", function()
			return Options.Get("timer.keyInfo.show") == "NAME"
		end)

		local affixes = page:AddGroup({
			title = L["Affixes"],
			enabledPath = "timer.elements.keyInfoAffixes.enabled",
		})

		affixes.content:AddWidgets({
			{
				type = "slider",
				label = L["Row Height"],
				path = "timer.affixes.height",
				min = 10,
				max = 32,
				step = 1,
				hidden = IsInline,
			},

			{
				type = "segmented",
				label = L["Widget"],
				path = "timer.affixes.widget",
				tooltip = L["Icons, or full affix names joined by a separator."],
				values = { { "ICON", L["Icons"] }, { "TEXT", L["Text"] } },
			},

			{
				type = "slider",
				label = L["Icon Size"],
				path = "timer.affixes.iconSize",
				min = 8,
				max = 28,
				step = 1,
				hidden = IsTextMode,
			},

			{
				type = "slider",
				label = L["Icon Spacing"],
				path = "timer.affixes.spacing",
				min = 0,
				max = 12,
				step = 1,
				hidden = IsTextMode,
			},

			{
				type = "text",
				label = L["Separator"],
				path = "timer.affixes.separator",
				tooltip = L["Text placed between affix names."],
				hidden = function()
					return not IsTextMode()
				end,
			},
		})

		affixes.content:AddFontGroup(L["Text"], "timer.affixes.text", function()
			return not IsTextMode()
		end)

		local deaths = page:AddGroup({
			title = DEATHS,
			enabledPath = "timer.elements.deaths.enabled",
		})

		deaths.content:AddWidgets({
			{
				type = "slider",
				label = L["Row Height"],
				path = "timer.deaths.height",
				min = 10,
				max = 32,
				step = 1,
				hidden = IsInline,
			},

			{
				type = "segmented",
				label = L["Label"],
				path = "timer.deaths.label",
				values = { { "SKULL", L["Icon"] }, { "TEXT", L["Text"] }, { "NONE", L["None"] } },
			},

			{ type = "note", label = "", get = PreviewText, color = PREVIEW_WHITE },

			{
				type = "slider",
				label = L["Icon Size"],
				path = "timer.deaths.iconSize",
				min = 8,
				max = 24,
				step = 1,
				hidden = function()
					return Options.Get("timer.deaths.label") ~= "SKULL"
				end,
			},

			{ type = "checkbox", label = L["Show Penalty"], path = "timer.deaths.penalty" },

			{
				type = "segmented",
				label = L["Brackets"],
				path = "timer.deaths.brackets",
				values = { { "PAREN", "( )" }, { "SQUARE", "[ ]" } },
				disabled = function()
					return not Options.Get("timer.deaths.penalty")
				end,
			},

			{
				type = "checkbox",
				label = L["Show Tooltip"],
				path = "timer.deaths.tooltip",
				tooltip = L["Hovering the death count lists who died and when."],
			},
		})

		deaths.content:AddFontGroup(L["Text"], "timer.deaths.text")
	end,
})
