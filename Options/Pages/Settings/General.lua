local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "settings.general",
	parent = "settings",
	order = 10,
	name = GENERAL,
	Build = function(page)
		page:SetHeader({
			description = L["Account-wide addon behaviour. These settings are shared by every profile."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "slider",
				label = L["Update Interval"],
				scope = "account",
				path = "updateInterval",
				min = 0.1,
				max = 3.0,
				step = 0.1,
				set = function(value)
					Options.Set("updateInterval", value, "account")
					AMT.Render.SetInterval(value)
				end,
			},

			{
				type = "note",
				label = "",
				text = L["Lower values update the timer more smoothly at a small cost in performance."],
			},
		})
	end,
})
