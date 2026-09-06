local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

---@return boolean
local function IsMinimal()
	return Options.Get("timer.style") == "MINIMAL"
end

Options.RegisterPage({
	id = "timer.bar",
	parent = "timer",
	order = 40,
	name = L["Timer Bar"],
	Build = function(page)
		page:SetHeader({
			description = L["The timer bar's texture, size, colors and text."],
			divider = "thin",
		})

		page:AddWidgets({
			{ type = "checkbox", label = L["Enabled"], path = "timer.elements.timerBar.enabled" },
			{ type = "media", label = L["Bar Texture"], path = "timer.bar.texture", mediaType = "statusbar" },
			{ type = "slider", label = L["Bar Height"], path = "timer.bar.height", min = 8, max = 48, step = 1 },

			{
				type = "segmented",
				label = L["Fill Direction"],
				path = "timer.bar.fill",
				values = { { "LEFT", L["Left"] }, { "RIGHT", L["Right"] } },
				tooltip = L["Which way the bar grows. Threshold marks and their times follow it."],
			},

			{
				type = "segmented",
				label = L["Count Direction"],
				path = "timer.direction",
				tooltip = L["Up counts elapsed time, down counts time remaining."],
				values = { { "UP", L["Up"] }, { "DOWN", L["Down"] } },
			},

			{
				type = "checkbox",
				label = L["Space Around Slash"],
				path = "timer.spacedSlash",
				tooltip = L["Adds spaces around the slash between the elapsed time and the limit."],
			},

			{
				type = "segmented",
				label = L["Decimals"],
				path = "timer.decimals",
				tooltip = L["Fractions of a second shown on the timer text at the end of the dungeon."],
				values = { { 0, "0" }, { 1, "1" }, { 2, "2" }, { 3, "3" } },
			},

			{
				type = "color",
				label = L["Depleted / +1 / +2 / +3"],
				tooltips = {
					L["Bar color once the key can no longer be timed."],
					L["Bar color while the run is on pace to time the key."],
					L["Bar color while the run is on pace for a two-chest."],
					L["Bar color while the run is on pace for a three-chest."],
				},
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

		page:AddWidgets({
			{
				type = "segmented",
				label = L["Placement"],
				path = "timer.clock.placement",
				values = { { "ABOVE", L["Above"] }, { "BAR", L["On Bar"] }, { "BELOW", L["Below"] } },
				tooltip = L["Whether this text sits on the bar or on a row above or below it."],
			},

			{
				type = "segmented",
				label = L["Alignment"],
				hidden = IsMinimal,
				path = "timer.clock.slot",
				values = { { "LEFT", L["Left"] }, { "CENTER", L["Center"] }, { "RIGHT", L["Right"] } },
			},

			{ type = "slider", label = L["X Offset"], path = "timer.clock.nudge.1", min = -50, max = 50, step = 1 },
			{ type = "slider", label = L["Y Offset"], path = "timer.clock.nudge.2", min = -50, max = 50, step = 1 },
		})

		page:AddFontGroup(L["Timer Text"], "timer.clock.text")

		for tier = 1, 3 do
			local prefix = "timer.thresholds." .. tier

			local group = page:AddGroup({
				title = L["Threshold %s"]:format("+" .. tier),
				enabledPath = prefix .. ".enabled",
			})

			local widgets = {}

			if tier > 1 then
				widgets[#widgets + 1] = {
					type = "segmented",
					label = L["Marks"],
					path = prefix .. ".marks",
					tooltip = L["Whether this threshold draws a tick on the bar, its time as text, or both."],
					values = { { "TICK", L["Tick"] }, { "TEXT", L["Text"] }, { "BOTH", L["Both"] } },
				}

				widgets[#widgets + 1] = {
					type = "color",
					label = L["Tick Color"],
					path = prefix .. ".tickColor",
					hasOpacity = true,
					disabled = function()
						return Options.Get(prefix .. ".marks") == "TEXT"
					end,
				}
			end

			-- The tick is pinned to its fraction; only the text moves.
			widgets[#widgets + 1] =
				{ type = "slider", label = L["X Offset"], path = prefix .. ".nudge.1", min = -10, max = 10, step = 1 }

			widgets[#widgets + 1] =
				{ type = "slider", label = L["Y Offset"], path = prefix .. ".nudge.2", min = -10, max = 10, step = 1 }

			widgets[#widgets + 1] = {
				type = "color",
				label = L["Ahead / Behind"],
				tooltips = {
					L["Threshold text color while you are inside this threshold's time."],
					L["Threshold text color once this threshold's time has passed."],
				},
				paths = { prefix .. ".aheadColor", prefix .. ".behindColor" },
			}

			group.content:AddWidgets(widgets)

			group.content:AddFontGroup(L["Text"], prefix .. ".text", function()
				return Options.Get(prefix .. ".marks") == "TICK"
			end)
		end
	end,
})
