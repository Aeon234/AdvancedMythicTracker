local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "timer.objectives",
	parent = "timer",
	order = 60,
	name = L["Objectives"],
	Build = function(page)
		page:SetHeader({
			description = L["The boss list and its completion times."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "checkbox", label = L["Enabled"], path = "timer.elements.objectiveRows.enabled" },

			{
				type = "slider",
				label = L["Row Height"],
				path = "timer.objectives.rowHeight",
				min = 8,
				max = 28,
				step = 1,
			},
			{
				type = "slider",
				label = L["Row Spacing"],
				path = "timer.objectives.spacing",
				min = 0,
				max = 12,
				step = 1,
			},

			{ type = "checkbox", label = L["Show Boss Icons"], path = "timer.objectives.icon" },

			{
				type = "slider",
				label = L["Icon Size"],
				path = "timer.objectives.iconSize",
				min = 8,
				max = 24,
				step = 1,
				disabled = function()
					return not Options.Get("timer.objectives.icon")
				end,
			},

			{ type = "checkbox", label = L["Show Completion Times"], path = "timer.objectives.showTime" },

			{
				type = "color",
				label = L["Pending / Completed"],
				paths = { "timer.objectives.pendingColor", "timer.objectives.completedColor" },
			},
		})

		page:AddFontGroup(L["Boss Name"], "timer.objectives.text")
		page:AddFontGroup(L["Completion Time"], "timer.objectives.time")
	end,
})
