local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local PREVIEW_WHITE = { 1, 1, 1 }

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

	return ("|T%s:0|t %s"):format(module.SKULL, text)
end

Options.RegisterPage({
	id = "timer.deaths",
	parent = "timer",
	order = 70,
	name = L["Deaths"],
	Build = function(page)
		page:SetHeader({
			description = L["How the death count and its time penalty are displayed."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "checkbox", label = L["Enabled"], path = "timer.elements.deaths.enabled" },

			{
				type = "segmented",
				label = L["Label"],
				path = "timer.deaths.label",
				values = { { "SKULL", L["Icon"] }, { "TEXT", L["Text"] }, { "NONE", L["None"] } },
			},

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

			{ type = "checkbox", label = L["Colour Red"], path = "timer.deaths.red" },
			{ type = "checkbox", label = L["Show Tooltip"], path = "timer.deaths.tooltip" },

			{ type = "note", label = "", get = PreviewText, color = PREVIEW_WHITE },
		})

		page:AddFontGroup(L["Text"], "timer.deaths.text")
	end,
})
