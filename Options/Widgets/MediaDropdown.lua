local AMT = select(2, ...)

local Options = AMT.Options

local BUTTON_WIDTH = 220
local BUTTON_HEIGHT = 25
local ARROW_RESERVE = 22
local MENU_ROW_HEIGHT = 20
local ROW_TEXT_INSET = 2
local MAX_MENU_EXTENT = 280

local BUTTON_ART_BLEED = 8
local MENU_ART_BLEED = 10
local TARGET_MENU_WIDTH = BUTTON_WIDTH + (BUTTON_ART_BLEED - MENU_ART_BLEED) * 2

local SCROLLBAR_WIDTH = 8
local SCROLLBAR_PAD = 10

---@class AMTMediaDropdownWidget : AMTOptionWidget
---@field control DropdownButton
---@field preview Texture
---@field keyIndex table<string, integer>
local MediaDropdown = Options.NewWidgetPrototype("media")

---@return number
function MediaDropdown:GetControlHeight()
	return BUTTON_HEIGHT
end

---@return string
function MediaDropdown:GetMediaType()
	return self.info and self.info.mediaType or "statusbar"
end

---@param texture Texture
---@param key string?
function MediaDropdown:ApplyMedia(texture, key)
	if not key or not AMT.Media.Apply(texture, self:GetMediaType(), key) then
		texture:Hide()

		return
	end

	texture:SetHorizTile(false)
	texture:SetVertTile(false)
	texture:Show()
end

---@param fontString FontString
---@param key string?
function MediaDropdown:ApplyFont(fontString, key)
	local path = key and AMT.Media.Fetch("font", key)

	if not path then
		return
	end

	local _, size, flags = fontString:GetFont()

	fontString:SetFont(path, size or 12, flags or "") ---@diagnostic disable-line: type-mismatch
end

---@param menu table
function MediaDropdown:ScrollToSelected(menu)
	local value = self:GetValue()
	local index = value and self.keyIndex[value]

	if not index then
		return
	end

	local scrollBox = menu and menu.ScrollBox

	if not scrollBox or not scrollBox:HasDataProvider() then
		return
	end

	local noInterpolation = true

	scrollBox:ScrollToElementDataIndex(index, ScrollBoxConstants.AlignCenter, 0, noInterpolation)
end

---Resolves issue of items registering after AMT loads.
---@param rootDescription table
function MediaDropdown:BuildMenu(rootDescription)
	rootDescription:SetScrollMode(MAX_MENU_EXTENT)

	local mediaType = self:GetMediaType()
	local isFont = mediaType == "font"
	local keys = AMT.Media.List(mediaType) or {}

	local width = TARGET_MENU_WIDTH

	if (#keys * MENU_ROW_HEIGHT) > MAX_MENU_EXTENT then
		width = width - (SCROLLBAR_WIDTH + SCROLLBAR_PAD)
	end

	rootDescription:SetMinimumWidth(width)
	rootDescription:SetMaximumWidth(width)

	wipe(self.keyIndex)

	for index, key in ipairs(keys) do
		self.keyIndex[key] = index

		local entry = rootDescription:CreateButton(key, function()
			self:SetValue(key)
		end, key)

		entry:AddInitializer(function(row)
			if row.fontString then
				row.fontString:SetPoint("LEFT", row, "LEFT", ROW_TEXT_INSET, 0)

				if isFont then
					local fontObject = AMT.Media.FontObject(key)

					if fontObject then
						row.fontString:SetFontObject(fontObject)
					end
				end
			end

			if not isFont then
				local bar = row:AttachTexture()

				bar:SetDrawLayer("BACKGROUND")
				bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
				bar:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 1)

				self:ApplyMedia(bar, key)
			end

			return width, MENU_ROW_HEIGHT
		end)
	end
end

---@param parent Frame
function MediaDropdown:Create(parent)
	Options.Widget.Create(self, parent)

	self.keyIndex = {}

	local control = CreateFrame("DropdownButton", nil, self.frame, "WowStyle1DropdownTemplate")

	control:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)
	control:SetDefaultText(NONE)

	self.preview = control:CreateTexture(nil, "ARTWORK")
	self.preview:SetPoint("TOPLEFT", control, "TOPLEFT", 3, -3)
	self.preview:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -ARROW_RESERVE, 3)

	control:SetupMenu(function(_, rootDescription)
		self:BuildMenu(rootDescription)
	end)

	local baseOnMenuOpened = control.OnMenuOpened

	control.OnMenuOpened = function(dropdown, menu)
		if baseOnMenuOpened then
			baseOnMenuOpened(dropdown, menu)
		end

		self:ScrollToSelected(menu)
	end

	self.control = control
end

function MediaDropdown:Update()
	if not Options.Widget.Update(self) then
		return
	end

	local value = self:GetValue()

	self.control:OverrideText(value or NONE)
	self.control:SetEnabled(not self.disabled)

	if self:GetMediaType() == "font" then
		self.preview:Hide()
		self:ApplyFont(self.control.Text, value)
	else
		self:ApplyMedia(self.preview, value)
	end
end
