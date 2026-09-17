local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "settings.analytics",
	parent = "settings",
	order = 20,
	name = L["Analytics"],
	Build = function(page)
		page:SetHeader({
			description = L["Personal bests and run history."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "checkbox",
				label = L["Record Abandoned Runs"],
				scope = "account",
				path = "recordAbandons",
				tooltip = L["Counts keys you left early in run history. Personal bests are unaffected."],
			},
		})
	end,
})
