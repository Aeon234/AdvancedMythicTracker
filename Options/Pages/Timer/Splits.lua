local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

Options.RegisterPage({
	id = "timer.splits",
	parent = "timer",
	order = 70,
	name = L["Splits"],
	Build = function(page)
		page:SetHeader({
			description = L["Comparisons against your best run for this dungeon and level."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "dropdown",
				label = L["Dungeon PB"],
				path = "timer.splits.overall",
				tooltip = L["When to show your best time for this dungeon and key level. Start & Finish hides it during the run."],
				values = {
					{ "ALWAYS", L["Always"] },
					{ "COUNTDOWN_AND_AFTER", L["Start & Finish"] },
					{ "NEVER", L["Never"] },
				},
			},

			{
				type = "segmented",
				label = L["Boss Splits"],
				path = "timer.splits.boss",
				tooltip = L["When to show each boss's time against your best run."],
				values = { { "ALWAYS", L["Always"] }, { "AFTER", L["On Finish"] } },
			},

			{
				type = "color",
				label = L["Ahead / Even / Behind"],
				tooltip = L["Split colour when you are faster than, level with, or slower than your best run."],
				paths = {
					"timer.splits.aheadColor",
					"timer.splits.equalColor",
					"timer.splits.behindColor",
				},
			},

			{
				type = "segmented",
				label = L["Decimals"],
				path = "timer.splits.decimals",
				tooltip = L["Fractions of a second shown on split times."],
				values = { { 0, "0" }, { 1, "1" }, { 2, "2" } },
			},
		})

		local texts = {
			{ title = L["Dungeon PB Text"], prefix = "timer.splits.pbCompare" },
			{ title = L["Boss Split Text"], prefix = "timer.splits.bossSplit" },
			{ title = L["Forces Split Text"], prefix = "timer.splits.forcesSplit" },
		}

		for _, entry in ipairs(texts) do
			local group = page:AddGroup({
				title = entry.title,
				enabledPath = entry.prefix .. ".enabled",
			})

			group.content:AddFontGroup(L["Text"], entry.prefix .. ".text")
		end
	end,
})
