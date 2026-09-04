local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local BOX_HEIGHT = 120
local TEXT_INSET = 6

---@class AMTTextAreaWidget : AMTOptionWidget
---@field control Frame
---@field hover AMTBorder?
---@field readOnlyText string?
local TextArea = Options.NewWidgetPrototype("textarea")

---@return number
function TextArea:GetControlHeight()
	return BOX_HEIGHT
end

---@return string
function TextArea:GetText()
	return self.control:GetInputText() or ""
end

---@param text string
function TextArea:SetText(text)
	self.control:SetText(text)
end

---@param parent Frame
function TextArea:Create(parent)
	Options.Widget.Create(self, parent)

	local shell = CreateFrame("Frame", nil, self.frame)

	shell:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self:GetControlOffset(), -CONST.CORNER_SIZE / 2)
	shell:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", 0, CONST.CORNER_SIZE / 2)

	AMT.NineSlice.Apply(shell, "Control", CONST.CORNER_SIZE)

	local hover = AMT.NineSlice.Apply(shell, "Hover", CONST.CORNER_SIZE, "OVERLAY")

	if hover then
		hover:SetShown(false)
	end

	local control = CreateFrame("Frame", nil, shell, "ScrollingEditBoxTemplate")

	control:SetPoint("TOPLEFT", shell, "TOPLEFT", TEXT_INSET, -TEXT_INSET)
	control:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -TEXT_INSET, TEXT_INSET)
	control:SetFontObject("GameFontHighlightSmall")

	self.control = control
	self.hover = hover

	control:RegisterCallback(ScrollingEditBoxMixin.Event.OnTextChanged, function()
		if self.readOnlyText and self:GetText() ~= self.readOnlyText then
			self:SetText(self.readOnlyText)

			return
		end

		if not self.readOnlyText then
			Options.NotifyValueChanged()
		end
	end, self)

	control:RegisterCallback(ScrollingEditBoxMixin.Event.OnFocusGained, function()
		if hover then
			hover:SetShown(true)
		end

		if self.readOnlyText then
			control:GetEditBox():HighlightText()
		end
	end, self)

	control:RegisterCallback(ScrollingEditBoxMixin.Event.OnFocusLost, function()
		if hover then
			hover:SetShown(false)
		end
	end, self)
end

function TextArea:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	if info.readOnly then
		local text = tostring(self:GetValue() or "")

		self.readOnlyText = text
		self:SetText(text)
	else
		self.readOnlyText = nil
	end

	self.control:SetEnabled(not self.disabled)
end
