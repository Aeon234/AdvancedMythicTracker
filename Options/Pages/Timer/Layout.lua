local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

---@return string[]
local function DefaultGroupOrder()
	local override = Options.Styles.GetOverride(Options.Get("timer.style"))
	local stamped = override and override.order and override.order.groups

	return stamped or AMT.Profiles.TimerDefaults().order.groups
end

local function ResetOrder()
	Options.Set("timer.order.groups", AMT.Util.Copy(DefaultGroupOrder()))

	for _, groupKey in ipairs(AMT.Layout.GetGroupKeys()) do
		Options.Set("timer.order." .. groupKey, AMT.Layout.GetRegisteredMembers(groupKey))

		-- Justification is arrangement too, so a reset that fixed the order and left every element
		-- pointing a different way would have done half its job. Back to the frame-wide value, which
		-- is what an element follows until someone gives it one of its own.
		for _, elementKey in ipairs(AMT.Layout.GetRegisteredMembers(groupKey)) do
			Options.Set("timer.elements." .. elementKey .. ".justify", Options.Get("timer.justify"))
		end
	end
end

Options.RegisterPage({
	id = "timer.layout",
	hidden = Options.IsTimerDisabled,
	parent = "timer",
	order = 20,
	name = L["Layout"],
	Build = function(page)
		page:SetHeader({
			description = L["Drag a row to reorder it. Rows stay inside their own group."],
			divider = "thin",
		})

		-- In the page body rather than the header: the header's right-hand slot is where the Timer
		-- pages carry Unlock / Preview / Animate preview, and an action button lands on top of them.
		page:AddWidget({
			type = "button",
			label = "",
			text = L["Reset Order"],
			tooltip = L["Restores the current style's group order and each element's default alignment."],
			set = ResetOrder,
		})

		local list = page:AddWidget({
			type = "reorder",
			set = function(value)
				local path = value.groupKey and ("timer.order." .. value.groupKey) or "timer.order.groups"

				Options.Set(path, value.keys)
			end,
		})

		if list then
			-- The list grows and shrinks as groups open, and a widget's height is otherwise fixed at
			-- Create, so the page's own container has to be told to reflow.
			list.onResized = function()
				page.container:Layout()
			end
		end
	end,
})
