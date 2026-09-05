local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local DISPLAY = { MINIMAL = "Minimal", PANEL = "Panel", AEON = "Aeon" }
local FONT_MENU_WIDTH = 220
local FONT_MENU_ROW_HEIGHT = 20
local FONT_MENU_EXTENT = 320
local STYLE_WIDTH = 200
local UNDO_WIDTH = 160

StaticPopupDialogs["AMT_CONFIRM_STYLE"] = {
	text = L["Switching to %s will reset every Timer customisation to that style's defaults.\n\nYou can undo this until you switch again, or export your profile first."],
	button1 = L["Switch style"],
	button2 = CANCEL,
	OnAccept = function(_, styleKey)
		AMT.Style.Apply(styleKey)
		Options.NotifyValueChanged()
	end,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

---@param node table
---@param font string
local function StampFontFamily(node, font)
	for _, value in pairs(node) do
		if type(value) == "table" then
			if value.font ~= nil then
				value.font = font
			end

			StampFontFamily(value, font)
		end
	end
end

local function ShowFontPicker()
	MenuUtil.CreateContextMenu(nil, function(_, rootDescription)
		rootDescription:SetScrollMode(FONT_MENU_EXTENT)
		rootDescription:SetMinimumWidth(FONT_MENU_WIDTH)
		rootDescription:SetMaximumWidth(FONT_MENU_WIDTH)

		for _, key in ipairs(AMT.Media.List("font")) do
			local entry = rootDescription:CreateButton(key, function()
				StampFontFamily(AMT.Profiles.active.timer, key)
				AMT.Profiles.Refresh()
				Options.NotifyValueChanged()
			end)

			entry:AddInitializer(function(row)
				local fontObject = AMT.Media.FontObject(key)

				if row.fontString and fontObject then
					row.fontString:SetFontObject(fontObject)
				end

				return FONT_MENU_WIDTH, FONT_MENU_ROW_HEIGHT
			end)
		end
	end)
end

---@return table[]
local function StyleValues()
	local values = {}

	for _, key in ipairs(Options.Styles.ORDER) do
		values[#values + 1] = { key, L[DISPLAY[key] or key] }
	end

	return values
end

---@return string
local function CurrentStyle()
	return Options.Get("timer.style")
end

Options.RegisterPage({
	id = "timer.general",
	parent = "timer",
	order = 10,
	name = L["General"],
	Build = function(page)
		page:SetHeader({
			description = L["Overall look and placement of the timer."],
			divider = "thin",
		})

		page:AddWidgets({
			{
				type = "row",
				label = L["Style"],
				items = {
					{
						type = "dropdown",
						width = STYLE_WIDTH,
						values = StyleValues(),
						get = CurrentStyle,
						set = function(value)
							StaticPopup_Show("AMT_CONFIRM_STYLE", L[DISPLAY[value] or value], nil, value)
						end,
					},

					{
						type = "button",
						width = UNDO_WIDTH,
						align = "RIGHT",
						text = L["Undo style change"],
						set = function()
							AMT.Style.Undo()
						end,
						hidden = function()
							return not AMT.Style.CanUndo()
						end,
					},
				},
			},

			{
				type = "note",
				label = "",
				text = L["Selecting a style resets every Timer customisation. Other features are untouched."],
			},

			{ type = "slider", label = L["Overall Scale"], path = "timer.scale", min = 0.5, max = 2.0, step = 0.05 },

			{
				type = "button",
				label = L["Fonts"],
				text = L["Apply Font To All…"],
				set = ShowFontPicker,
			},

			{
				type = "checkbox",
				label = L["Unlock Frame"],
				get = function()
					return AMT.Frames.IsUnlocked()
				end,
				set = function(value)
					AMT.Frames.SetUnlocked(value == true)
				end,
			},

			{
				type = "segmented",
				label = L["Text Alignment"],
				path = "timer.justify",
				values = { { "LEFT", L["Left"] }, { "RIGHT", L["Right"] } },
				hidden = function()
					return CurrentStyle() ~= "MINIMAL"
				end,
			},

			{
				type = "slider",
				label = L["Background Opacity"],
				path = "timer.background.color.4",
				min = 0,
				max = 1,
				step = 0.05,
				hidden = function()
					return CurrentStyle() == "MINIMAL"
				end,
			},

			{
				type = "color",
				label = L["Background Colour"],
				path = "timer.background.color",
				hidden = function()
					return CurrentStyle() ~= "AEON"
				end,
			},
		})
	end,
})
