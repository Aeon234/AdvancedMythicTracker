local addonName, AMT = ...
local API = AMT.API

local BUTTON_MIN_SIZE = 27

local Mixin = API.Mixin

local select = select
local tinsert = table.insert
local floor = math.floor
local ipairs = ipairs
local unpack = unpack
local time = time
local GetTime = GetTime
local IsMouseButtonDown = IsMouseButtonDown
local GetMouseFocus = API.GetMouseFocus
local PlaySound = PlaySound
local GetSpellCharges = GetSpellCharges
local C_Item = C_Item
local GetItemCount = C_Item.GetItemCount
local GetItemIconByID = C_Item.GetItemIconByID
local GetCVarBool = C_CVar.GetCVarBool
local CreateFrame = CreateFrame
local UIParent = UIParent

local IsMouseButtonDown = IsMouseButtonDown
local PlaySound = PlaySound
local CreateFrame = CreateFrame

local function DisableSharpening(texture)
	texture:SetTexelSnappingBias(0)
	texture:SetSnapToPixelGrid(false)
end
API.DisableSharpening = DisableSharpening

do -- Checkbox
	local LABEL_OFFSET = 20
	local BUTTON_HITBOX_MIN_WIDTH = 120

	local SFX_CHECKBOX_ON = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON or 856
	local SFX_CHECKBOX_OFF = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857

	local CheckboxMixin = {}

	function CheckboxMixin:OnEnter()
		if IsMouseButtonDown() then
			return
		end

		if self.tooltip then
			GameTooltip:Hide()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.Label:GetText(), 1, 1, 1, true)
			GameTooltip:AddLine(self.tooltip, 1, 0.82, 0, true)
			GameTooltip:Show()
		end

		if self.onEnterFunc then
			self.onEnterFunc(self)
		end
	end

	function CheckboxMixin:OnLeave()
		GameTooltip:Hide()

		if self.onLeaveFunc then
			self.onLeaveFunc(self)
		end
	end

	function CheckboxMixin:OnClick()
		local newState

		if self.dbKey then
			newState = not AMT.GetDBValue(self.dbKey)
			AMT.SetDBValue(self.dbKey, newState)
			self:SetChecked(newState)
		else
			newState = not self:GetChecked()
			self:SetChecked(newState)
			print("AMT: DB Key not assigned")
		end

		if self.onClickFunc then
			self.onClickFunc(self, newState)
		end

		if self.checked then
			PlaySound(SFX_CHECKBOX_ON)
		else
			PlaySound(SFX_CHECKBOX_OFF)
		end

		GameTooltip:Hide()
	end

	function CheckboxMixin:GetChecked()
		return self.checked
	end

	function CheckboxMixin:SetChecked(state)
		state = state or false
		self.CheckedTexture:SetShown(state)
		self.checked = state
	end

	function CheckboxMixin:SetFixedWidth(width)
		self.fixedWidth = width
		self:SetWidth(width)
	end

	function CheckboxMixin:SetMaxWidth(maxWidth)
		--this width includes box and label
		self.Label:SetWidth(maxWidth - LABEL_OFFSET)
		self.SetWidth(maxWidth)
	end

	function CheckboxMixin:SetLabel(label)
		self.Label:SetText(label)
		local width = self.Label:GetWrappedWidth() + LABEL_OFFSET
		local height = self.Label:GetHeight()
		local lines = self.Label:GetNumLines()

		self.Label:ClearAllPoints()
		if lines > 1 then
			self.Label:SetPoint("TOPLEFT", self, "TOPLEFT", LABEL_OFFSET, -4)
		else
			self.Label:SetPoint("LEFT", self, "LEFT", LABEL_OFFSET, 0)
		end

		if self.fixedWidth then
			return self.fixedWidth
		else
			self:SetWidth(math.max(BUTTON_HITBOX_MIN_WIDTH, width))
			return width
		end
	end

	function CheckboxMixin:SetData(data)
		self.dbKey = data.dbKey
		self.tooltip = data.tooltip
		self.onClickFunc = data.onClickFunc
		self.onEnterFunc = data.onEnterFunc
		self.onLeaveFunc = data.onLeaveFunc

		if data.label then
			return self:SetLabel(data.label)
		else
			return 0
		end
	end

	local function CreateCheckbox(parent)
		local b = CreateFrame("Button", nil, parent)
		b:SetSize(BUTTON_MIN_SIZE, BUTTON_MIN_SIZE)

		b.Label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		b.Label:SetJustifyH("LEFT")
		b.Label:SetJustifyV("TOP")
		b.Label:SetTextColor(1, 0.82, 0) --labelcolor
		b.Label:SetPoint("LEFT", b, "LEFT", LABEL_OFFSET, 0)

		b.Border = b:CreateTexture(nil, "ARTWORK")
		b.Border:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/Checkbox")
		b.Border:SetTexCoord(0, 0.5, 0, 0.5)
		b.Border:SetPoint("CENTER", b, "LEFT", 8, 0)
		b.Border:SetSize(36, 36)
		DisableSharpening(b.Border)

		b.CheckedTexture = b:CreateTexture(nil, "OVERLAY")
		b.CheckedTexture:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/Checkbox")
		b.CheckedTexture:SetTexCoord(0.5, 0.75, 0.5, 0.75)
		b.CheckedTexture:SetPoint("CENTER", b.Border, "CENTER", 0, 0)
		b.CheckedTexture:SetSize(18, 18)
		DisableSharpening(b.CheckedTexture)
		b.CheckedTexture:Hide()

		b.Highlight = b:CreateTexture(nil, "HIGHLIGHT")
		b.Highlight:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/Checkbox")
		b.Highlight:SetTexCoord(0, 0.5, 0.5, 1)
		b.Highlight:SetPoint("CENTER", b.Border, "CENTER", 0, 0)
		b.Highlight:SetSize(36, 36)
		--b.Highlight:Hide();
		DisableSharpening(b.Highlight)

		Mixin(b, CheckboxMixin)
		b:SetScript("OnClick", CheckboxMixin.OnClick)
		b:SetScript("OnEnter", CheckboxMixin.OnEnter)
		b:SetScript("OnLeave", CheckboxMixin.OnLeave)

		return b
	end

	AMT.CreateCheckbox = CreateCheckbox
end

do -- Common Frame with Header (and close button)
	local function CloseButton_OnClick(self)
		local parent = self:GetParent()
		if parent.CloseUI then
			parent:CloseUI()
		else
			parent:Hide()
		end
	end

	local function CloseButton_ShowNormalTexture(self)
		self.Texture:SetTexCoord(0, 0.5, 0, 0.5)
		self.Highlight:SetTexCoord(0, 0.5, 0.5, 1)
	end

	local function CloseButton_ShowPushedTexture(self)
		self.Texture:SetTexCoord(0.5, 1, 0, 0.5)
		self.Highlight:SetTexCoord(0.5, 1, 0.5, 1)
	end

	local function CreateCloseButton(parent)
		local b = CreateFrame("Button", nil, parent)
		b:SetSize(BUTTON_MIN_SIZE, BUTTON_MIN_SIZE)

		b.Texture = b:CreateTexture(nil, "ARTWORK")
		b.Texture:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/CloseButton")
		b.Texture:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.Texture:SetSize(32, 32)
		DisableSharpening(b.Texture)

		b.Highlight = b:CreateTexture(nil, "HIGHLIGHT")
		b.Highlight:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/CloseButton")
		b.Highlight:SetPoint("CENTER", b, "CENTER", 0, 0)
		b.Highlight:SetSize(32, 32)
		DisableSharpening(b.Highlight)

		CloseButton_ShowNormalTexture(b)

		b:SetScript("OnClick", CloseButton_OnClick)
		b:SetScript("OnMouseUp", CloseButton_ShowNormalTexture)
		b:SetScript("OnMouseDown", CloseButton_ShowPushedTexture)
		b:SetScript("OnShow", CloseButton_ShowNormalTexture)

		return b
	end

	local CategoryDividerMixin = {}

	function CategoryDividerMixin:HideDivider()
		self.Divider:Hide()
	end

	local function CreateCategoryDivider(parent, alignCenter)
		local fontString = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		if alignCenter then
			fontString:SetJustifyH("CENTER")
		else
			fontString:SetJustifyH("LEFT")
		end

		fontString:SetJustifyV("TOP")
		fontString:SetTextColor(1, 1, 1)

		local divider = parent:CreateTexture(nil, "OVERLAY")
		divider:SetHeight(4)
		--divider:SetWidth(240);
		divider:SetPoint("TOPLEFT", fontString, "BOTTOMLEFT", 0, -4)
		divider:SetPoint("RIGHT", parent, "RIGHT", -8, 0)

		divider:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/Divider_Gradient_Horizontal")
		divider:SetVertexColor(0.5, 0.5, 0.5)
		DisableSharpening(divider)

		Mixin(fontString, CategoryDividerMixin)

		return fontString
	end

	AMT.CreateCategoryDivider = CreateCategoryDivider

	local HeaderFrameMixin = {}

	function HeaderFrameMixin:SetCornerSize(a) end

	function HeaderFrameMixin:ShowCloseButton(state)
		self.CloseButton:SetShown(state)
	end

	function HeaderFrameMixin:SetTitle(title)
		self.Title:SetText(title)
	end

	function HeaderFrameMixin:GetHeaderHeight()
		return 18
	end

	local function CreateHeaderFrame(parent, showCloseButton)
		local f = CreateFrame("Frame", nil, parent)
		f:ClearAllPoints()

		local p = {}
		f.pieces = p

		f.Title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		f.Title:SetJustifyH("CENTER")
		f.Title:SetJustifyV("MIDDLE")
		f.Title:SetTextColor(1, 0.82, 0)
		f.Title:SetPoint("CENTER", f, "TOP", 0, -8 - 1)

		f.CloseButton = CreateCloseButton(f)
		f.CloseButton:SetPoint("CENTER", f, "TOPRIGHT", -9, -9)
		-- 1 2 3
		-- 4 5 6
		-- 7 8 9

		local tex = "Interface/AddOns/AdvancedMythicTracker/Media/Frame/CommonFrameWithHeader_Opaque"

		for i = 1, 9 do
			p[i] = f:CreateTexture(nil, "BORDER")
			p[i]:SetTexture(tex)
			DisableSharpening(p[i])
			p[i]:ClearAllPoints()
		end

		p[1]:SetPoint("CENTER", f, "TOPLEFT", 0, -8)
		p[3]:SetPoint("CENTER", f, "TOPRIGHT", 0, -8)
		p[7]:SetPoint("CENTER", f, "BOTTOMLEFT", 0, 0)
		p[9]:SetPoint("CENTER", f, "BOTTOMRIGHT", 0, 0)
		p[2]:SetPoint("TOPLEFT", p[1], "TOPRIGHT", 0, 0)
		p[2]:SetPoint("BOTTOMRIGHT", p[3], "BOTTOMLEFT", 0, 0)
		p[4]:SetPoint("TOPLEFT", p[1], "BOTTOMLEFT", 0, 0)
		p[4]:SetPoint("BOTTOMRIGHT", p[7], "TOPRIGHT", 0, 0)
		p[5]:SetPoint("TOPLEFT", p[1], "BOTTOMRIGHT", 0, 0)
		p[5]:SetPoint("BOTTOMRIGHT", p[9], "TOPLEFT", 0, 0)
		p[6]:SetPoint("TOPLEFT", p[3], "BOTTOMLEFT", 0, 0)
		p[6]:SetPoint("BOTTOMRIGHT", p[9], "TOPRIGHT", 0, 0)
		p[8]:SetPoint("TOPLEFT", p[7], "TOPRIGHT", 0, 0)
		p[8]:SetPoint("BOTTOMRIGHT", p[9], "BOTTOMLEFT", 0, 0)

		p[1]:SetSize(16, 32)
		p[3]:SetSize(16, 32)
		p[7]:SetSize(16, 16)
		p[9]:SetSize(16, 16)

		p[1]:SetTexCoord(0, 0.25, 0, 0.5)
		p[2]:SetTexCoord(0.25, 0.75, 0, 0.5)
		p[3]:SetTexCoord(0.75, 1, 0, 0.5)
		p[4]:SetTexCoord(0, 0.25, 0.5, 0.75)
		p[5]:SetTexCoord(0.25, 0.75, 0.5, 0.75)
		p[6]:SetTexCoord(0.75, 1, 0.5, 0.75)
		p[7]:SetTexCoord(0, 0.25, 0.75, 1)
		p[8]:SetTexCoord(0.25, 0.75, 0.75, 1)
		p[9]:SetTexCoord(0.75, 1, 0.75, 1)

		Mixin(f, HeaderFrameMixin)
		f:ShowCloseButton(showCloseButton)
		f:EnableMouse(true)

		return f
	end

	AMT.CreateHeaderFrame = CreateHeaderFrame
end

do --EditMode
	local Round = API.Round
	local EditModeSelectionMixin = {}

	function EditModeSelectionMixin:OnDragStart()
		self.parent:OnDragStart()
	end

	function EditModeSelectionMixin:OnDragStop()
		self.parent:OnDragStop()
	end

	function EditModeSelectionMixin:ShowHighlighted()
		--Blue
		if not self.parent:IsShown() then
			return
		end
		self.isSelected = false
		self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/EditModeHighlighted")
		self:Show()
		self.Label:Hide()
	end

	function EditModeSelectionMixin:ShowSelected()
		--Yellow
		if not self.parent:IsShown() then
			return
		end
		self.isSelected = true
		self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/EditModeSelected")
		self:Show()

		if not self.hideLabel then
			self.Label:Show()
		end
	end

	function EditModeSelectionMixin:OnShow()
		local offset = API.GetPixelForWidget(self, 6)
		self.Background:SetPoint("TOPLEFT", self, "TOPLEFT", -offset, offset)
		self.Background:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", offset, -offset)
		self:RegisterEvent("GLOBAL_MOUSE_DOWN")
	end

	function EditModeSelectionMixin:OnHide()
		self:UnregisterEvent("GLOBAL_MOUSE_DOWN")
	end

	local function IsMouseOverOptionToggle()
		local obj = GetMouseFocus()
		if obj and obj.isAMTEditModeToggle then
			return true
		else
			return false
		end
	end

	function EditModeSelectionMixin:OnEvent(event, ...)
		if event == "GLOBAL_MOUSE_DOWN" then
			if self:IsShown() and not (self.parent:IsFocused() or IsMouseOverOptionToggle()) then
				self:ShowHighlighted()
				self.parent:ShowOptions(false)
			end
		end
	end

	function EditModeSelectionMixin:OnMouseDown()
		self:ShowSelected()
		self.parent:ShowOptions(true)

		if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem then
			EditModeManagerFrame:ClearSelectedSystem()
		end
	end

	local function CreateEditModeSelection(parent, uiName, hideLabel)
		local f = CreateFrame("Frame", nil, parent)
		f:Hide()
		f:SetAllPoints(true)
		f:SetFrameStrata(parent:GetFrameStrata())
		f:SetToplevel(true)
		f:SetFrameLevel(999)
		f:EnableMouse(true)
		f:RegisterForDrag("LeftButton")
		f:SetIgnoreParentAlpha(true)

		f.Label = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
		f.Label:SetText(uiName)
		f.Label:SetJustifyH("CENTER")
		f.Label:SetPoint("CENTER", f, "CENTER", 0, 0)

		f.Background = f:CreateTexture(nil, "BACKGROUND")
		f.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/EditModeHighlighted")
		f.Background:SetTextureSliceMargins(16, 16, 16, 16)
		f.Background:SetTextureSliceMode(0)
		f.Background:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		f.Background:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

		Mixin(f, EditModeSelectionMixin)

		f:SetScript("OnShow", f.OnShow)
		f:SetScript("OnHide", f.OnHide)
		f:SetScript("OnEvent", f.OnEvent)
		f:SetScript("OnMouseDown", f.OnMouseDown)
		f:SetScript("OnDragStart", f.OnDragStart)
		f:SetScript("OnDragStop", f.OnDragStop)

		parent.Selection = f
		f.parent = parent
		f.hideLabel = hideLabel

		return f
	end
	AMT.CreateEditModeSelection = CreateEditModeSelection

	local EditModeSettingsDialog
	local DIALOG_WIDTH = 382

	local EditModeSettingsDialogMixin = {}

	function EditModeSettingsDialogMixin:Exit()
		self:Hide()
		self:ClearAllPoints()
		self.requireResetPosition = true
		if self.parent then
			if self.parent.Selection then
				self.parent.Selection:ShowHighlighted()
			end
			if self.parent.ExitEditMode and not API.IsInEditMode() then
				self.parent:ExitEditMode()
			end
			self.parent = nil
		end
	end

	function EditModeSettingsDialogMixin:ReleaseAllWidgets()
		for _, widget in pairs(self.widgets) do
			widget:Hide()
			widget:ClearAllPoints()
		end

		self.activeWidgets = {}
	end

	function EditModeSettingsDialogMixin:Layout()
		local leftPadding = 20
		local topPadding = 48
		local bottomPadding = 20
		local OPTION_GAP_Y = 8 --consistent with ControlCenter
		local height = topPadding
		local widgetHeight
		local contentWidth = DIALOG_WIDTH - 2 * leftPadding

		for order, widget in ipairs(self.activeWidgets) do
			if widget.isGap then
				height = height + 8 + OPTION_GAP_Y
			else
				widget:SetPoint("TOPLEFT", self, "TOPLEFT", leftPadding, -height)
				widgetHeight = Round(widget:GetHeight())
				height = height + widgetHeight + OPTION_GAP_Y
				if widget.matchParentWidth then
					widget:SetWidth(contentWidth)
				end
			end
		end

		height = height - OPTION_GAP_Y + bottomPadding
		self:SetHeight(height)
	end

	function EditModeSettingsDialogMixin:AcquireWidgetByType(type)
		local widget

		if type == "Checkbox" then
			if not self.checkboxes then
				self.checkboxes = {}
			end
			widget = AMT.CreateCheckbox(self)
		elseif type == "Slider" then
			if not self.sliders then
				self.sliders = {}
			end
			widget = AMT.CreateSlider(self)
		elseif type == "UIPanelButton" then
			widget = AMT.CreateUIPanelButton(self)
		elseif type == "Texture" then
			widget = self:CreateTexture(nil, "OVERLAY")
			widget.isDivider = nil
			widget.matchParentWidth = nil
		elseif type == "FontString" then
			widget = self:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			widget.matchParentWidth = true
		end

		widget:Show()

		return widget
	end

	function EditModeSettingsDialogMixin:CreateCheckbox(widgetData)
		local checkbox = self:AcquireWidgetByType("Checkbox")

		checkbox.Label:SetFontObject("GameFontHighlightMedium") --Fonts in EditMode and Options are different
		checkbox.Label:SetTextColor(1, 1, 1)

		checkbox:SetData(widgetData)
		checkbox:SetChecked(AMT.GetDBValue(checkbox.dbKey))

		return checkbox
	end

	function EditModeSettingsDialogMixin:CreateSlider(widgetData)
		local slider = self:AcquireWidgetByType("Slider")

		slider:SetLabel(widgetData.label)
		slider:SetMinMaxValues(widgetData.minValue, widgetData.maxValue)

		if widgetData.valueStep then
			slider:SetObeyStepOnDrag(true)
			slider:SetValueStep(widgetData.valueStep)
		else
			slider:SetObeyStepOnDrag(false)
		end

		slider:SetFormatValueFunc(widgetData.formatValueFunc)
		slider:SetOnValueChangedFunc(widgetData.onValueChangedFunc)

		if widgetData.dbKey and AMT.GetDBValue(widgetData.dbKey) then
			slider:SetValue(AMT.GetDBValue(widgetData.dbKey))
		end

		return slider
	end

	function EditModeSettingsDialogMixin:CreateUIPanelButton(widgetData)
		local button = self:AcquireWidgetByType("UIPanelButton")
		button:SetButtonText(widgetData.label)
		button:SetScript("OnClick", widgetData.onClickFunc)
		if (not widgetData.stateCheckFunc) or (widgetData.stateCheckFunc()) then
			button:Enable()
		else
			button:Disable()
		end
		button.matchParentWidth = true
		return button
	end

	function EditModeSettingsDialogMixin:CreateDivider(widgetData)
		local texture = self:AcquireWidgetByType("Texture")
		texture:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/Divider_NineSlice")
		texture:SetTextureSliceMargins(48, 4, 48, 4)
		texture:SetTextureSliceMode(0)
		texture:SetHeight(4)
		texture.isDivider = true
		texture.matchParentWidth = true
		return texture
	end

	function EditModeSettingsDialogMixin:CreateHeader(widgetData)
		local fontString = self:AcquireWidgetByType("FontString")
		fontString:SetJustifyH("CENTER")
		fontString:SetJustifyV("TOP")
		fontString:SetSpacing(2)
		fontString.matchParentWidth = true
		fontString:SetText(widgetData.label)
		return fontString
	end

	function EditModeSettingsDialogMixin:SetupOptions(schematic)
		self:ReleaseAllWidgets()
		self:SetTitle(schematic.title)

		if schematic.widgets then
			for order, widgetData in ipairs(schematic.widgets) do
				local widget
				if widgetData.type == "Checkbox" then
					widget = self:CreateCheckbox(widgetData)
				elseif widgetData.type == "RadioGroup" then
				elseif widgetData.type == "Slider" then
					widget = self:CreateSlider(widgetData)
				elseif widgetData.type == "UIPanelButton" then
					widget = self:CreateUIPanelButton(widgetData)
				elseif widgetData.type == "Divider" then
					widget = self:CreateDivider(widgetData)
				elseif widgetData.type == "Header" then
					widget = self:CreateHeader(widgetData)
				end

				if widget then
					tinsert(self.activeWidgets, widget)
					widget.widgetKey = widgetData.widgetKey
				end
			end
		end
		self:Layout()
	end

	function EditModeSettingsDialogMixin:FindWidget(widgetKey)
		if self.activeWidgets then
			for _, widget in pairs(self.activeWidgets) do
				if widget.widgetKey == widgetKey then
					return widget
				end
			end
		end
	end

	function EditModeSettingsDialogMixin:OnDragStart()
		self:StartMoving()
	end

	function EditModeSettingsDialogMixin:OnDragStop()
		self:StopMovingOrSizing()
	end

	function EditModeSettingsDialogMixin:SetTitle(title)
		self.Title:SetText(title)
	end

	local function SetupSettingsDialog(parent, schematic)
		if not EditModeSettingsDialog then
			local f = CreateFrame("Frame", nil, UIParent)
			EditModeSettingsDialog = f
			f:Hide()
			f:SetSize(DIALOG_WIDTH, 350)
			f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			f:SetMovable(true)
			f:SetClampedToScreen(true)
			f:RegisterForDrag("LeftButton")
			f:SetDontSavePosition(true)
			f:SetFrameStrata("DIALOG")
			f:SetFrameLevel(200)
			f:EnableMouse(true)

			f.widgets = {}
			f.requireResetPosition = true

			Mixin(f, EditModeSettingsDialogMixin)

			f.Border = CreateFrame("Frame", nil, f, "DialogBorderTranslucentTemplate")
			f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
			f.CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
			f.CloseButton:SetScript("OnClick", function()
				f:Exit()
			end)
			f.Title = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
			f.Title:SetPoint("TOP", f, "TOP", 0, -16)
			f.Title:SetText("Title")

			f:SetScript("OnDragStart", f.OnDragStart)
			f:SetScript("OnDragStop", f.OnDragStop)
		end

		if schematic ~= EditModeSettingsDialog.schematic then
			EditModeSettingsDialog.requireResetPosition = true
			EditModeSettingsDialog.schematic = schematic
			EditModeSettingsDialog:ClearAllPoints()
			EditModeSettingsDialog:SetupOptions(schematic)
		end

		EditModeSettingsDialog.parent = parent

		return EditModeSettingsDialog
	end
	AMT.SetupSettingsDialog = SetupSettingsDialog
end

do --UIPanelButton
	local UIPanelButtonMixin = {}

	function UIPanelButtonMixin:OnClick(button) end

	function UIPanelButtonMixin:OnMouseDown(button)
		if self:IsEnabled() then
			self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Down")
		end
	end

	function UIPanelButtonMixin:OnMouseUp(button)
		if self:IsEnabled() then
			self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Up")
		end
	end

	function UIPanelButtonMixin:OnDisable()
		self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Disabled")
	end

	function UIPanelButtonMixin:OnEnable()
		self.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Up")
	end

	function UIPanelButtonMixin:OnEnter() end

	function UIPanelButtonMixin:OnLeave() end

	function UIPanelButtonMixin:SetButtonText(text)
		self:SetText(text)
	end

	local function CreateUIPanelButton(parent)
		local f = CreateFrame("Button", nil, parent)
		f:SetSize(144, 24)
		Mixin(f, UIPanelButtonMixin)

		f:SetScript("OnMouseDown", f.OnMouseDown)
		f:SetScript("OnMouseUp", f.OnMouseUp)
		f:SetScript("OnEnter", f.OnEnter)
		f:SetScript("OnLeave", f.OnLeave)
		f:SetScript("OnEnable", f.OnEnable)
		f:SetScript("OnDisable", f.OnDisable)

		f.Background = f:CreateTexture(nil, "BACKGROUND")
		f.Background:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Up")
		f.Background:SetTextureSliceMargins(32, 16, 32, 16)
		f.Background:SetTextureSliceMode(1)
		f.Background:SetAllPoints(true)
		DisableSharpening(f.Background)

		f.Highlight = f:CreateTexture(nil, "HIGHLIGHT")
		f.Highlight:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Button/UIPanelButton-Highlight")
		f.Highlight:SetTextureSliceMargins(32, 16, 32, 16)
		f.Highlight:SetTextureSliceMode(0)
		f.Highlight:SetAllPoints(true)
		f.Highlight:SetBlendMode("ADD")
		f.Highlight:SetVertexColor(0.5, 0.5, 0.5)

		f:SetNormalFontObject("GameFontNormal")
		f:SetHighlightFontObject("GameFontHighlight")
		f:SetDisabledFontObject("GameFontDisable")
		f:SetPushedTextOffset(0, -1)

		return f
	end
	AMT.CreateUIPanelButton = CreateUIPanelButton
end
