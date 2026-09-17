local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local BOX_WIDTH = 72
local BOX_HEIGHT = 22

---@class AMTTextInputWidget : AMTOptionWidget
---@field shell Frame
---@field input EditBox
---@field hover AMTBorder?
local TextInput = Options.NewWidgetPrototype("text")

---@return number
function TextInput:GetControlHeight()
	return BOX_HEIGHT
end

---@return table[]
function TextInput:GetTooltipRegions()
	return { self.input }
end

function TextInput:Commit()
	local raw = self.input:GetText()

	if self.info and self.info.numeric then
		local parsed = tonumber(raw)

		if not parsed then
			self:Update()

			return
		end

		self:SetValue(parsed)

		return
	end

	self:SetValue(raw)
end

---@param parent Frame
function TextInput:Create(parent)
	Options.Widget.Create(self, parent)

	local shell = CreateFrame("Frame", nil, self.frame)

	shell:SetSize(BOX_WIDTH, BOX_HEIGHT)
	shell:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)

	AMT.NineSlice.Apply(shell, "Control", CONST.CORNER_SIZE)

	local hover = AMT.NineSlice.Apply(shell, "Hover", CONST.CORNER_SIZE, "OVERLAY")

	if hover then
		hover:SetShown(false)
	end

	local input = CreateFrame("EditBox", nil, shell)

	input:SetPoint("TOPLEFT", shell, "TOPLEFT", 5, 0)
	input:SetPoint("BOTTOMRIGHT", shell, "BOTTOMRIGHT", -5, 0)
	input:SetFontObject(CONST.FONT_SMALL)
	input:SetJustifyH("CENTER")
	input:SetAutoFocus(false)
	input:SetMaxLetters(12)

	self.shell = shell
	self.input = input
	self.hover = hover

	input:SetScript("OnEnterPressed", function(editBox)
		self:Commit()
		editBox:ClearFocus()
	end)

	input:SetScript("OnEscapePressed", function(editBox)
		self:Update()
		editBox:ClearFocus()
	end)

	input:SetScript("OnEditFocusLost", function(editBox)
		self:Update()

		if hover then
			hover:SetShown(editBox:IsMouseMotionFocus())
		end
	end)

	input:SetScript("OnEditFocusGained", function(editBox)
		editBox:HighlightText()

		if hover then
			hover:SetShown(true)
		end
	end)

	input:SetScript("OnEnter", function()
		if hover then
			hover:SetShown(true)
		end
	end)

	input:SetScript("OnLeave", function(editBox)
		if hover then
			hover:SetShown(editBox:HasFocus())
		end
	end)
end

function TextInput:Update()
	if not Options.Widget.Update(self) then
		return
	end

	local value = self:GetValue()

	self.input:SetText(value ~= nil and tostring(value) or "")
	self.input:SetCursorPosition(0)
	self.input:SetEnabled(not self.disabled)
end
