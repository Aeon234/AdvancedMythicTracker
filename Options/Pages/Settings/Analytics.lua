local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "addon.analytics",
	parent = "addon",
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
			},
		})
	end,
})
