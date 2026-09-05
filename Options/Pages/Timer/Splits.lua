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
				values = { { "ALWAYS", L["Always"] }, { "AFTER", L["On Finish"] } },
			},

			{
				type = "color",
				label = L["Ahead / Even / Behind"],
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
