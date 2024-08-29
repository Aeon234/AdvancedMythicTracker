local _, AMT = ...
local API = AMT.API
local tinsert = table.insert
local CreateFrame = CreateFrame

local RATIO = 0.75 --h/w
local FRAME_WIDTH = 600
local PADDING = 16
local BUTTON_HEIGHT = 24
local OPTION_GAP_Y = 8
local DIFFERENT_CATEGORY_OFFSET = 8
local LEFT_SECTOR_WIDTH = math.floor(0.618 * FRAME_WIDTH + 0.5)

local CATEGORY_ORDER = {
	--Must match the keys in the localization
	[1] = "General",
	[2] = "Mythic+",
}

local DEFAULT_COLLAPSED_CATEGORY = {}

if AMT.IsGame_11_0_0 then
	-- DEFAULT_COLLAPSED_CATEGORY[10020000] = true -- If we want want to start a category collapsed, change 10020000 to the category #
end

local Config = CreateFrame("Frame", nil, UIParent)
AMT.Config = Config
Config:SetSize(FRAME_WIDTH, FRAME_WIDTH * RATIO)
Config:SetPoint("TOP", UIParent, "BOTTOM", 0, -64)
Config.modules = {}
Config:Hide()

local ScrollFrame = CreateFrame("Frame", nil, Config)
ScrollFrame:SetPoint("TOPLEFT", Config, "TOPLEFT", 0, -16)
ScrollFrame:SetPoint("BOTTOMLEFT", Config, "BOTTOMLEFT", 0, 0)
ScrollFrame:SetWidth(LEFT_SECTOR_WIDTH)
Config.ScrollFrame = ScrollFrame

local title = C_AddOns.GetAddOnMetadata("AdvancedMythicTracker", "Title")
local addonVersion = C_AddOns.GetAddOnMetadata("AdvancedMythicTracker", "Version")
local OptionsTitle = Config:CreateFontString(nil, "ARTWORK", "GameFontNormal")
OptionsTitle:SetPoint("TOPLEFT", 8, -5)
OptionsTitle:SetText(title)
OptionsTitle:SetFont(AMT.AMT_Font, 20)

do
	local OFFSET_PER_SCROLL = (BUTTON_HEIGHT + OPTION_GAP_Y) * 2

	local function ScrollFrame_OnMouseWheel(self, delta)
		if self.scrollOffset > 0 and delta > 0 then
			self.scrollOffset = self.scrollOffset - OFFSET_PER_SCROLL
			if self.scrollOffset < 0 then
				self.scrollOffset = 0
			end
			self.ScrollChild:SetPoint("TOPLEFT", self, "TOPLEFT", 0, self.scrollOffset)
		elseif self.scrollOffset < self.scrollRange and delta < 0 then
			self.scrollOffset = self.scrollOffset + OFFSET_PER_SCROLL
			if self.scrollOffset > self.scrollRange then
				self.scrollOffset = self.scrollRange
			end
			self.ScrollChild:SetPoint("TOPLEFT", self, "TOPLEFT", 0, self.scrollOffset)
		end
	end

	function Config:SetScrollRange(scrollRange)
		local scrollable = scrollRange > 0

		if scrollable then
			if not self.scrollable then
				self.scrollable = true
				self.ScrollFrame:SetClipsChildren(true)
				self.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel)
				self.ScrollFrame.scrollOffset = 0
			end
			self.ScrollFrame.scrollRange = scrollRange
		else
			if self.scrollable then
				self.scrollable = false
				self.ScrollFrame:SetClipsChildren(false)
				self.ScrollFrame.ScrollChild:SetPoint("TOPLEFT", self.ScrollFrame, "TOPLEFT", 0, 0)
				self.ScrollFrame.scrollOffset = 0
				self.ScrollFrame.scrollRange = 0
				self.ScrollFrame:SetScript("OnMouseWheel", nil)
			end
		end
	end

	function Config:UpdateScrollRange()
		local frameHeight = self.ScrollFrame:GetHeight()
		local firstButton = self.CategoryButtons[1]
		local lastObject = self.lastCategoryButton.Drawer

		local contentHeight = 2 * PADDING + firstButton:GetTop() - lastObject:GetBottom()

		self:SetScrollRange(math.ceil(contentHeight - frameHeight))
	end

	function Config:OnMouseWheel(delta)
		if self.scrollable then
		end
	end
end

local function CreateNewFeatureMark(button)
	local newTag = button:CreateTexture(nil, "OVERLAY")
	newTag:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/NewFeatureMark")
	newTag:SetSize(16, 16)
	newTag:SetPoint("RIGHT", button, "LEFT", -8, 0)
	newTag:Show()
end

local CategoryButtonMixin = {}

function CategoryButtonMixin:SetCategory(categoryID)
	self.categoryID = categoryID
	self.categoryKey = CATEGORY_ORDER[categoryID]

	if self.categoryKey then
		self.Label:SetText(self.categoryKey)
	else
		self.Label:SetText("Unknown Category")
		self.categoryKey = "Unknown"
	end
end

function CategoryButtonMixin:OnLoad()
	self.collapsed = false
	self.childOptions = {}
	self:UpdateArrow()
end

function CategoryButtonMixin:UpdateArrow()
	if self.collapsed then
		self.Arrow:SetTexCoord(0, 0.5, 0, 1)
	else
		self.Arrow:SetTexCoord(0.5, 1, 0, 1)
	end
end

function CategoryButtonMixin:Expand()
	if self.collapsed then
		self.collapsed = false
		self.Drawer:SetHeight(self.drawerHeight)
		self.Drawer:Show()
		self:UpdateArrow()
		Config:UpdateScrollRange()
	end
end

function CategoryButtonMixin:Collapse()
	if not self.collapsed then
		self.collapsed = true
		self.Drawer:SetHeight(DIFFERENT_CATEGORY_OFFSET)
		self.Drawer:Hide()
		self:UpdateArrow()
		Config:UpdateScrollRange()
	end
end

function CategoryButtonMixin:ToggleCollapse()
	if self.collapsed then
		self:Expand()
	else
		self:Collapse()
	end
end

function CategoryButtonMixin:OnClick()
	self:ToggleCollapse()
end

function CategoryButtonMixin:OnEnter() end

function CategoryButtonMixin:InitializeDrawer()
	self.drawerHeight = #self.childOptions * (OPTION_GAP_Y + BUTTON_HEIGHT) + OPTION_GAP_Y + DIFFERENT_CATEGORY_OFFSET
	self.Drawer:SetHeight(self.drawerHeight)
end

function CategoryButtonMixin:UpdateModuleCount()
	if self.childOptions then
		local total = #self.childOptions
		local numEnabled = 0
		for i, checkbox in ipairs(self.childOptions) do
			if checkbox:GetChecked() then
				numEnabled = numEnabled + 1
			end
		end
		self.Count:SetText(string.format("%d/%d", numEnabled, total))
	else
		self.Count:SetText(nil)
	end
end

function CategoryButtonMixin:AddChildOption(checkbox)
	tinsert(self.childOptions, checkbox)
end

-- function CategoryButtonMixin:UpdateNineSlice(offset)
-- 	--Texture Slice don't follow its parent scale
-- 	--This texture has 4px gap in each direction
-- 	--Unused
-- 	self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset)
-- 	self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset)
-- end

local function CreateCategoryButton(parent)
	local b = CreateFrame("Button", nil, parent)

	b:SetSize(LEFT_SECTOR_WIDTH - PADDING, BUTTON_HEIGHT)

	b.Background = b:CreateTexture(nil, "BACKGROUND")
	b.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/CategoryButton-NineSlice")
	b.Background:SetTextureSliceMargins(16, 16, 16, 16)
	b.Background:SetTextureSliceMode(0)
	b.Background:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
	b.Background:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 0, 0)

	local arrowOffsetX = 8

	b.Arrow = b:CreateTexture(nil, "OVERLAY")
	b.Arrow:SetSize(14, 14)
	b.Arrow:SetPoint("LEFT", b, "LEFT", 8, 0)
	b.Arrow:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/CollapseExpand")

	b.Label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	b.Label:SetJustifyH("LEFT")
	b.Label:SetJustifyV("TOP")
	b.Label:SetTextColor(1, 1, 1)
	b.Label:SetPoint("LEFT", b, "LEFT", 28, 0)

	b.Count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	b.Count:SetJustifyH("RIGHT")
	b.Count:SetJustifyV("TOP")
	b.Count:SetTextColor(0.5, 0.5, 0.5)
	b.Count:SetPoint("RIGHT", b, "RIGHT", -8, 0)

	b.Drawer = CreateFrame("Frame", nil, b)
	b.Drawer:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 0)
	b.Drawer:SetSize(16, 16)

	API.Mixin(b, CategoryButtonMixin)
	b:SetScript("OnClick", b.OnClick)
	b:SetScript("OnEnter", b.OnEnter)

	b:OnLoad()

	b.Label:SetText("Button Text")
	b.Count:SetText("4/4")

	return b
end

local function OptionToggle_SetFocused(optionToggle, focused)
	if focused then
		optionToggle.Texture:SetTexCoord(0.5, 1, 0, 1)
	else
		optionToggle.Texture:SetTexCoord(0, 0.5, 0, 1)
	end
end

local function OptionToggle_OnHide(self)
	OptionToggle_SetFocused(self, false)
end

local function CreateOptionToggle(checkbox, onClickFunc)
	if not checkbox.OptionToggle then
		local b = CreateFrame("Button", nil, checkbox)
		checkbox.OptionToggle = b
		b:SetSize(24, 24)
		b:SetPoint("RIGHT", checkbox, "RIGHT", 0, 0)
		b.Texture = b:CreateTexture(nil, "OVERLAY")
		b.Texture:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/OptionToggle")
		b.Texture:SetSize(16, 16)
		b.Texture:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.Texture:SetVertexColor(0.6, 0.6, 0.6)
		API.DisableSharpening(b.Texture)
		b:SetScript("OnClick", onClickFunc)
		b:SetScript("OnHide", OptionToggle_OnHide)
		b.isAMTEditModeToggle = true
		OptionToggle_SetFocused(b, false)
		return b
	end
end

local function CreateUI()
	local CHECKBOX_WIDTH = LEFT_SECTOR_WIDTH - 2 * PADDING

	local db = AMT.db
	DB = db
	local settingsOpenTime = db.settingsOpenTime or 0

	local parent = Config
	local showCloseButton = true
	local f = AMT.CreateHeaderFrame(parent, showCloseButton)
	parent.Frame = f

	local ScrollChild = CreateFrame("Frame", nil, ScrollFrame)
	ScrollFrame.ScrollChild = ScrollChild
	ScrollChild:SetSize(8, 8)
	ScrollChild:SetPoint("TOPLEFT", ScrollFrame, "TOPLEFT", 0, 0)

	local container = parent

	f:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	f:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
	f:SetTitle("Module Control")

	local headerHeight = f:GetHeaderHeight()
	local previewSize = FRAME_WIDTH - LEFT_SECTOR_WIDTH - 2 * PADDING + 4

	local preview = container:CreateTexture(nil, "OVERLAY")
	parent.Preview = preview
	preview:SetSize(previewSize, previewSize)
	preview:SetPoint("TOPRIGHT", container, "TOPRIGHT", -PADDING, -headerHeight - PADDING)
	--preview:SetColorTexture(0.25, 0.25, 0.25);

	local mask = container:CreateMaskTexture(nil, "OVERLAY")
	mask:SetPoint("TOPLEFT", preview, "TOPLEFT", 0, 0)
	mask:SetPoint("BOTTOMRIGHT", preview, "BOTTOMRIGHT", 0, 0)
	mask:SetTexture(
		"Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/PreviewMask",
		"CLAMPTOBLACKADDITIVE",
		"CLAMPTOBLACKADDITIVE"
	)
	preview:AddMaskTexture(mask)

	local description = container:CreateFontString(nil, "OVERLAY", "GameTooltipText") --GameFontNormal (ObjectiveFont), GameTooltipTextSmall
	parent.Description = description
	description:SetTextColor(0.659, 0.659, 0.659) --0.5, 0.5, 0.5
	description:SetJustifyH("LEFT")
	description:SetJustifyV("TOP")
	description:SetSpacing(2)
	local visualOffset = 4
	description:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", visualOffset + 4, -PADDING)
	description:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -PADDING - visualOffset, PADDING)
	description:SetShadowColor(0, 0, 0)
	description:SetShadowOffset(1, -1)

	local dividerTop = container:CreateTexture(nil, "OVERLAY")
	dividerTop:SetSize(16, 16)
	dividerTop:SetPoint("TOPRIGHT", container, "TOPLEFT", LEFT_SECTOR_WIDTH, -headerHeight)
	dividerTop:SetTexCoord(0, 1, 0, 0.25)

	local dividerBottom = container:CreateTexture(nil, "OVERLAY")
	dividerBottom:SetSize(16, 16)
	dividerBottom:SetPoint("BOTTOMRIGHT", container, "BOTTOMLEFT", LEFT_SECTOR_WIDTH, 0)
	dividerBottom:SetTexCoord(0, 1, 0.75, 1)

	local dividerMiddle = container:CreateTexture(nil, "OVERLAY")
	dividerMiddle:SetPoint("TOPLEFT", dividerTop, "BOTTOMLEFT", 0, 0)
	dividerMiddle:SetPoint("BOTTOMRIGHT", dividerBottom, "TOPRIGHT", 0, 0)
	dividerMiddle:SetTexCoord(0, 1, 0.25, 0.75)

	dividerTop:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/Divider_DropShadow_Vertical")
	dividerBottom:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/Divider_DropShadow_Vertical")
	dividerMiddle:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/Divider_DropShadow_Vertical")

	API.DisableSharpening(dividerTop)
	API.DisableSharpening(dividerBottom)
	API.DisableSharpening(dividerMiddle)

	local SelectionTexture = ScrollChild:CreateTexture(nil, "ARTWORK")
	SelectionTexture:SetSize(LEFT_SECTOR_WIDTH - PADDING, BUTTON_HEIGHT)
	SelectionTexture:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/SelectionTexture")
	SelectionTexture:SetVertexColor(1, 1, 1, 0.1)
	SelectionTexture:SetBlendMode("ADD")
	SelectionTexture:Hide()

	local checkbox
	local fromOffsetY = PADDING -- +headerHeight
	local numButton = 0

	parent.Checkboxs = {}
	parent.CategoryButtons = {}

	local function Checkbox_OnEnter(self)
		description:SetText(self.data.description)
		preview:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/Config/Preview_" .. self.dbKey)
		SelectionTexture:ClearAllPoints()
		SelectionTexture:SetPoint("LEFT", self, "LEFT", -PADDING, 0)
		SelectionTexture:Show()
		if self.OptionToggle then
			OptionToggle_SetFocused(self.OptionToggle, true)
		end
	end

	local function Checkbox_OnLeave(self)
		if not self:IsMouseOver() then
			SelectionTexture:Hide()
			if self.OptionToggle then
				OptionToggle_SetFocused(self.OptionToggle, false)
			end
		end
	end

	local function Checkbox_OnClick(self)
		if self.dbKey and self.data.toggleFunc then
			self.data.toggleFunc(self:GetChecked())
			Config:UpdateCategoryButtons()
		end

		if self.OptionToggle then
			self.OptionToggle:SetShown(self:GetChecked())
		end
	end

	local function OptionToggle_OnEnter(self)
		Checkbox_OnEnter(self:GetParent())
		self.Texture:SetVertexColor(1, 1, 1)
	end

	local function OptionToggle_OnLeave(self)
		Checkbox_OnLeave(self:GetParent())
		self.Texture:SetVertexColor(0.6, 0.6, 0.6)
	end

	local newCategoryPosition = {}

	local function SortFunc_Module(a, b)
		if a.categoryID ~= b.categoryID then
			return a.categoryID < b.categoryID
		end

		if a.uiOrder ~= b.uiOrder then
			return a.uiOrder < b.uiOrder
			--should be finished here
		end

		return a.name < b.name
	end

	table.sort(parent.modules, SortFunc_Module)

	local validModules = {}
	local lastCategoryID
	local numValid = 0

	for i, data in ipairs(parent.modules) do
		if (not data.validityCheck) or (data.validityCheck()) then
			numValid = numValid + 1
			if data.categoryID ~= lastCategoryID then
				lastCategoryID = data.categoryID
				newCategoryPosition[numValid] = true
			end
			tinsert(validModules, data)
		end
	end

	parent.modules = validModules

	local lastCategoryButton
	local positionInCategory

	for i, data in ipairs(parent.modules) do
		if newCategoryPosition[i] then
			local categoryButton = CreateCategoryButton(ScrollChild)
			tinsert(parent.CategoryButtons, categoryButton)

			if i == 1 then
				categoryButton:SetPoint("TOPLEFT", ScrollChild, "TOPLEFT", PADDING, -fromOffsetY)
			else
				categoryButton:SetPoint("TOPLEFT", lastCategoryButton.Drawer, "BOTTOMLEFT", 0, 0)
			end

			categoryButton:SetCategory(data.categoryID)

			lastCategoryButton = categoryButton
			positionInCategory = 0
		end

		numButton = numButton + 1
		checkbox = AMT.CreateCheckbox(lastCategoryButton.Drawer)
		parent.Checkboxs[numButton] = checkbox
		checkbox.dbKey = data.dbKey
		checkbox:SetPoint(
			"TOPLEFT",
			lastCategoryButton.Drawer,
			"TOPLEFT",
			8,
			-positionInCategory * (OPTION_GAP_Y + BUTTON_HEIGHT) - OPTION_GAP_Y
		)
		checkbox.data = data
		checkbox.onEnterFunc = Checkbox_OnEnter
		checkbox.onLeaveFunc = Checkbox_OnLeave
		checkbox.onClickFunc = Checkbox_OnClick
		checkbox:SetFixedWidth(CHECKBOX_WIDTH)
		checkbox:SetLabel(data.name)

		if data.moduleAddedTime and data.moduleAddedTime > settingsOpenTime then
			CreateNewFeatureMark(checkbox)
		end

		if data.optionToggleFunc then
			local button = CreateOptionToggle(checkbox, data.optionToggleFunc)
			button:SetScript("OnEnter", OptionToggle_OnEnter)
			button:SetScript("OnLeave", OptionToggle_OnLeave)
		end

		lastCategoryButton:AddChildOption(checkbox)
		positionInCategory = positionInCategory + 1
	end

	Config.lastCategoryButton = lastCategoryButton

	for i, categoryButton in ipairs(parent.CategoryButtons) do
		categoryButton:InitializeDrawer()
	end

	for i, categoryButton in ipairs(parent.CategoryButtons) do
		if DEFAULT_COLLAPSED_CATEGORY[categoryButton.categoryID] then
			categoryButton:Collapse()
		end
	end

	--Temporary "About" Tab
	local VersionText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal") --GameFontNormal (ObjectiveFont), GameTooltipTextSmall
	VersionText:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -PADDING, PADDING)
	VersionText:SetTextColor(0.24, 0.24, 0.24)
	VersionText:SetJustifyH("RIGHT")
	VersionText:SetJustifyV("BOTTOM")
	VersionText:SetText(addonVersion)

	db.settingsOpenTime = time()

	function Config:UpdateLayout()
		local frameWidth = math.floor(self:GetWidth() + 0.5)
		if frameWidth == self.frameWidth then
			return
		end
		self.frameWidth = frameWidth

		local leftSectorWidth = math.floor(0.618 * frameWidth + 0.5)

		dividerTop:SetPoint("TOPRIGHT", container, "TOPLEFT", leftSectorWidth, -headerHeight)
		dividerBottom:SetPoint("BOTTOMRIGHT", container, "BOTTOMLEFT", leftSectorWidth, 0)

		previewSize = frameWidth - leftSectorWidth - 2 * PADDING + 4
		preview:SetSize(previewSize, previewSize)

		ScrollFrame:SetWidth(leftSectorWidth)
	end
end

function Config:ShowUI(onBlizzardOptionsUI)
	if CreateUI then
		CreateUI()
		CreateUI = nil
	end

	self:Show()
	self.Frame:SetShown(not onBlizzardOptionsUI)
	self:UpdateLayout()
	self:UpdateButtonStates()
	self:UpdateScrollRange()
end

function Config:InitializeModules()
	--Initial Enable/Disable Modules
	local db = AMT.db

	for _, moduleData in pairs(self.modules) do
		if (not moduleData.validityCheck) or (moduleData.validityCheck()) then
			moduleData.toggleFunc(db[moduleData.dbKey])
		end
	end
end

function Config:UpdateCategoryButtons()
	for _, categoryButton in pairs(self.CategoryButtons) do
		categoryButton:UpdateModuleCount()
	end
end

function Config:UpdateButtonStates()
	local db = AMT.db

	for _, button in pairs(self.Checkboxs) do
		if button.dbKey then
			button:SetChecked(db[button.dbKey])
			if button.OptionToggle then
				button.OptionToggle:SetShown(button:GetChecked())
			end
		else
			button:SetChecked(false)
		end
	end

	self:UpdateCategoryButtons()
end

function Config:AddModule(moduleData)
	--moduleData = {name = ModuleName, dbKey = AMT.db[key], description = string, toggleFunc = function, validityCheck = function, categoryID = number, uiOrder = number}

	if not moduleData.categoryID then
		moduleData.categoryID = 0
		moduleData.uiOrder = 0
		print("AMT Debug:", moduleData.name, "No Category")
	end

	table.insert(self.modules, moduleData)
end

Config:RegisterEvent("PLAYER_ENTERING_WORLD")

Config:SetScript("OnEvent", function(self, event, ...)
	self:UnregisterEvent(event)
	self:SetScript("OnEvent", nil)
	Config:InitializeModules()
end)

Config:SetScript("OnShow", function(self)
	local hideBackground = true
	self:ShowUI(hideBackground)
end)

local AMT_SettingsID

if Settings then
	local panel = Config
	local category = Settings.RegisterCanvasLayoutCategory(panel, "Advanced Mythic Tracker")
	Settings.RegisterAddOnCategory(category)
	AMT_SettingsID = category:GetID()
end

do
	function Config:ShouldShowNavigatorOnDreamseedPins()
		return AMT.db.Navigator_Dreamseed and not AMT.db.Navigator_MasterSwitch
	end

	function Config:EnableSuperTracking()
		AMT.db.Navigator_MasterSwitch = true
		local SuperTrackFrame = AMT.GetSuperTrackFrame()
		SuperTrackFrame:TryEnableByModule()
	end
end

-- =========================
-- === Set Slash Command ===
-- =========================
local function AMT_DebugCommands(msg)
	if msg == "debug" then
		AMT.DebugMode = not AMT.DebugMode
		if AMT.DebugMode then
			print("|cff18a8ffAMT|r Debug Mode: |cff19ff19Activated|r")
		else
			print("|cff18a8ffAMT|r Debug Mode: |c3fff2114Disabled|r")
		end
	elseif AMT.DebugMode and msg:match("^add") then
		local command, dungeon, keylevel = msg:match("^(%S*)%s*(%S*)%s*(%S*)$")
		if command == "add" then
			if dungeon and keylevel then
				print("running updatehighestkey")
				-- Update the highest key for the specified dungeon
				AMT:UpdateHighestKey(dungeon, keylevel)
			else
				print("Usage: /amt add <dungeon_abbr> <key_level>")
			end
		end
	else
		Settings.OpenToCategory(AMT_SettingsID)
	end
end
SLASH_AMT1 = "/amt"
SlashCmdList["AMT"] = AMT_DebugCommands
