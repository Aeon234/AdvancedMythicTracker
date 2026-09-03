local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "timer.bar",
	parent = "timer",
	order = 30,
	name = L["Timer Bar"],
	Build = function(page)
		page:SetHeader({
			description = L["The timer bar's texture, size, colours and text."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "media", label = L["Bar Texture"], path = "timer.bar.texture", mediaType = "statusbar" },
			{ type = "slider", label = L["Bar Height"], path = "timer.bar.height", min = 8, max = 48, step = 1 },

			{
				type = "segmented",
				label = L["Count Direction"],
				path = "timer.direction",
				values = { { "UP", L["Up"] }, { "DOWN", L["Down"] } },
			},

			{ type = "checkbox", label = L["Space Around Slash"], path = "timer.spacedSlash" },

			{
				type = "segmented",
				label = L["Decimals"],
				path = "timer.decimals",
				values = { { 0, "0" }, { 1, "1" }, { 2, "2" }, { 3, "3" } },
			},

			{ type = "checkbox", label = L["Show Threshold Marks"], path = "timer.bar.showTicks" },

			{
				type = "color",
				label = L["Mark Colour"],
				path = "timer.bar.tickColor",
				hasOpacity = true,
				disabled = function()
					return not Options.Get("timer.bar.showTicks")
				end,
			},

			{
				type = "color",
				label = L["Depleted / +1 / +2 / +3"],
				paths = {
					"timer.bar.tierColors.1",
					"timer.bar.tierColors.2",
					"timer.bar.tierColors.3",
					"timer.bar.tierColors.4",
				},
			},

			{
				type = "color",
				label = L["Completed / Depleted Text"],
				paths = { "timer.successColor", "timer.failColor" },
			},
		})

		page:AddFontGroup(L["Timer Text"], "timer.text")
	end,
})
