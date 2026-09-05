local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "timer.forces",
	parent = "timer",
	order = 50,
	name = L["Enemy Forces"],
	Build = function(page)
		page:SetHeader({
			description = L["The enemy forces bar and its count."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "checkbox", label = L["Enabled"], path = "timer.elements.forcesBar.enabled" },

			{ type = "media", label = L["Bar Texture"], path = "timer.forces.bar.texture", mediaType = "statusbar" },
			{ type = "slider", label = L["Bar Height"], path = "timer.forces.bar.height", min = 8, max = 48, step = 1 },

			{
				type = "color",
				label = L["Fill / Completed"],
				paths = { "timer.forces.bar.color", "timer.forces.completedColor" },
			},

			{ type = "color", label = L["Background"], path = "timer.forces.bar.background", hasOpacity = true },

			{
				type = "segmented",
				label = L["Count Format"],
				values = { { "COUNT", L["Count"] }, { "PERCENT", L["Percent"] }, { "BOTH", L["Both"] } },
				get = function()
					local count = Options.Get("timer.forces.count.enabled")
					local percent = Options.Get("timer.forces.percent.enabled")

					if count and percent then
						return "BOTH"
					elseif percent then
						return "PERCENT"
					end

					return "COUNT"
				end,
				set = function(value)
					Options.Set("timer.forces.count.enabled", value ~= "PERCENT")
					Options.Set("timer.forces.percent.enabled", value ~= "COUNT")
				end,
			},

			{
				type = "checkbox",
				label = L["Show Remaining"],
				path = "timer.forces.showRemaining",
				disabled = function()
					return not Options.Get("timer.forces.count.enabled")
				end,
			},

			{
				type = "checkbox",
				label = L["Space Around Slash"],
				path = "timer.forces.spacedSlash",
				disabled = function()
					return not Options.Get("timer.forces.count.enabled")
				end,
			},

			{
				type = "segmented",
				label = L["Percent Decimals"],
				path = "timer.forces.decimals",
				values = { { 0, "0" }, { 1, "1" }, { 2, "2" } },
				disabled = function()
					return not Options.Get("timer.forces.percent.enabled")
				end,
			},
		})

		page:AddFontGroup(L["Count Text"], "timer.forces.count.text")
		page:AddFontGroup(L["Percent Text"], "timer.forces.percent.text")
	end,
})
