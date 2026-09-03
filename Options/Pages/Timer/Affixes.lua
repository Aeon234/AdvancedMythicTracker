local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

---@return boolean
local function IsTextMode()
	return Options.Get("timer.affixes.widget") == "TEXT"
end

Options.RegisterPage({
	id = "timer.affixes",
	parent = "timer",
	order = 80,
	name = L["Affixes"],
	Build = function(page)
		page:SetHeader({
			description = L["How this week's affixes are shown."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "checkbox", label = L["Enabled"], path = "timer.elements.keyInfoAffixes.enabled" },

			{
				type = "segmented",
				label = L["Widget"],
				path = "timer.affixes.widget",
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
				hidden = function()
					return not IsTextMode()
				end,
			},
		})

		page:AddFontGroup(L["Text"], "timer.affixes.text", function()
			return not IsTextMode()
		end)
	end,
})
