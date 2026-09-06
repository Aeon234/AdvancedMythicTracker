local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

---@return boolean
local function IsMinimal()
	return Options.Get("timer.style") == "MINIMAL"
end

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
				type = "segmented",
				label = L["Fill Direction"],
				path = "timer.forces.bar.fill",
				values = { { "LEFT", L["Left"] }, { "RIGHT", L["Right"] } },
				tooltip = L["Which way the bar grows as forces are counted."],
			},

			{
				type = "color",
				label = L["Fill / Completed"],
				paths = { "timer.forces.bar.color", "timer.forces.completedColor" },
				tooltips = {
					L["Bar color while forces are still being counted."],
					L["Bar color once the forces requirement is met."],
				},
			},

			{ type = "color", label = L["Background"], path = "timer.forces.bar.background", hasOpacity = true },

			{
				type = "checkbox",
				label = L["Show Forces Title"],
				path = "timer.forces.title.enabled",
				tooltip = L["Puts a label above the bar. The row it needs adds to the frame's height."],
			},
		})

		page:AddFontGroup(L["Title Text"], "timer.forces.title.text", function()
			return Options.Get("timer.forces.title.enabled") ~= true
		end)

		local count = page:AddGroup({
			title = L["Count"],
			enabledPath = "timer.forces.count.enabled",
		})

		count.content:AddWidgets({
			{
				type = "checkbox",
				label = L["Show Total"],
				path = "timer.forces.showTotal",
				tooltip = L["Shows the pull total alongside the current count."],
			},

			{
				type = "checkbox",
				label = L["Space Around Slash"],
				path = "timer.forces.spacedSlash",
				tooltip = L["Adds spaces around the slash between the current and total counts."],
				disabled = function()
					return Options.Get("timer.forces.showTotal") ~= true
				end,
			},

			{
				type = "checkbox",
				label = L["Show Remaining"],
				path = "timer.forces.showRemaining",
				tooltip = L["Counts down what is left instead of up from zero."],
			},

			{
				type = "segmented",
				label = L["Placement"],
				path = "timer.forces.count.placement",
				values = { { "ABOVE", L["Above"] }, { "BAR", L["On Bar"] }, { "BELOW", L["Below"] } },
				tooltip = L["Whether this text sits on the bar or on a row above or below it."],
			},

			{
				type = "segmented",
				label = L["Alignment"],
				hidden = IsMinimal,
				path = "timer.forces.count.slot",
				values = { { "LEFT", L["Left"] }, { "CENTER", L["Center"] }, { "RIGHT", L["Right"] } },
			},

			{
				type = "slider",
				label = L["X Offset"],
				path = "timer.forces.count.nudge.1",
				min = -50,
				max = 50,
				step = 1,
			},

			{
				type = "slider",
				label = L["Y Offset"],
				path = "timer.forces.count.nudge.2",
				min = -50,
				max = 50,
				step = 1,
			},
		})

		count.content:AddFontGroup(L["Text"], "timer.forces.count.text")

		local percent = page:AddGroup({
			title = L["Percent"],
			enabledPath = "timer.forces.percent.enabled",
		})

		percent.content:AddWidgets({
			{
				type = "segmented",
				label = L["Percent Decimals"],
				path = "timer.forces.decimals",
				values = { { 0, "0" }, { 1, "1" }, { 2, "2" } },
				tooltip = L["Fractions of a percent shown on the forces count."],
			},

			{
				type = "segmented",
				label = L["Placement"],
				path = "timer.forces.percent.placement",
				values = { { "ABOVE", L["Above"] }, { "BAR", L["On Bar"] }, { "BELOW", L["Below"] } },
				tooltip = L["Whether this text sits on the bar or on a row above or below it."],
			},

			{
				type = "segmented",
				label = L["Alignment"],
				hidden = IsMinimal,
				path = "timer.forces.percent.slot",
				values = { { "LEFT", L["Left"] }, { "CENTER", L["Center"] }, { "RIGHT", L["Right"] } },
			},

			{
				type = "slider",
				label = L["X Offset"],
				path = "timer.forces.percent.nudge.1",
				min = -50,
				max = 50,
				step = 1,
			},

			{
				type = "slider",
				label = L["Y Offset"],
				path = "timer.forces.percent.nudge.2",
				min = -50,
				max = 50,
				step = 1,
			},
		})

		percent.content:AddFontGroup(L["Text"], "timer.forces.percent.text")
	end,
})
