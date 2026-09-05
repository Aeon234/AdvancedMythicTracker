local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local DISPLAY = { MINIMAL = "Minimal", PANEL = "Panel", AEON = "Aeon" }
local MEDIA_MENU_WIDTH = 220
local MEDIA_MENU_ROW_HEIGHT = 20
local MEDIA_MENU_EXTENT = 320
local MEDIA_ROW_TEXT_INSET = 2
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
---@param field string
---@param media string
local function StampMedia(node, field, media)
	for _, value in pairs(node) do
		if type(value) == "table" then
			if value[field] ~= nil then
				value[field] = media
			end

			StampMedia(value, field, media)
		end
	end
end

---@param field string
---@param mediaType string
---@param decorate fun(row: table, key: string)
local function ShowMediaPicker(field, mediaType, decorate)
	MenuUtil.CreateContextMenu(nil, function(_, rootDescription)
		rootDescription:SetScrollMode(MEDIA_MENU_EXTENT)
		rootDescription:SetMinimumWidth(MEDIA_MENU_WIDTH)
		rootDescription:SetMaximumWidth(MEDIA_MENU_WIDTH)

		for _, key in ipairs(AMT.Media.List(mediaType)) do
			local entry = rootDescription:CreateButton(key, function()
				StampMedia(AMT.Profiles.active.timer, field, key)
				AMT.Profiles.Refresh()
				Options.NotifyValueChanged()
			end)

			entry:AddInitializer(function(row)
				decorate(row, key)

				return MEDIA_MENU_WIDTH, MEDIA_MENU_ROW_HEIGHT
			end)
		end
	end)
end

local function ShowFontPicker()
	ShowMediaPicker("font", "font", function(row, key)
		local fontObject = AMT.Media.FontObject(key)

		if row.fontString and fontObject then
			row.fontString:SetFontObject(fontObject)
		end
	end)
end

local function ShowTexturePicker()
	ShowMediaPicker("texture", "statusbar", function(row, key)
		local bar = row:AttachTexture()

		bar:SetDrawLayer("BACKGROUND")
		bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
		bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)

		if AMT.Media.Apply(bar, "statusbar", key) then
			bar:SetHorizTile(false)
			bar:SetVertTile(false)
		else
			bar:Hide()
		end

		if row.fontString then
			row.fontString:SetPoint("LEFT", row, "LEFT", MEDIA_ROW_TEXT_INSET, 0)
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
				type = "slider",
				label = L["Update Interval"],
				scope = "account",
				path = "updateInterval",
				min = 0.1,
				max = 3.0,
				step = 0.1,
				tooltip = L["Lower values update the timer more smoothly at a small cost in performance."],
				set = function(value)
					Options.Set("updateInterval", value, "account")
					AMT.Render.SetInterval(value)
				end,
			},

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

			{
				type = "slider",
				label = L["Overall Scale"],
				path = "timer.scale",
				min = 0.5,
				max = 2.0,
				step = 0.05,
				tooltip = L["Scales the whole timer frame. Element sizes stay relative to each other."],
			},

			{
				type = "button",
				label = L["Fonts"],
				text = L["Apply Font To All…"],
				tooltip = L["Change all the texts at same time. Size, outline and colour keep their own values."],
				set = ShowFontPicker,
			},

			{
				type = "button",
				label = L["Textures"],
				text = L["Apply Texture To All…"],
				tooltip = L["Change all the textures at same time."],
				set = ShowTexturePicker,
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
				label = L["Background Color"],
				path = "timer.background.color",
				hidden = function()
					return CurrentStyle() ~= "AEON"
				end,
			},
		})
	end,
})
