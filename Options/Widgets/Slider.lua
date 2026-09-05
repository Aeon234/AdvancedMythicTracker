local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local SLIDER_WIDTH = 200
local SLIDER_HEIGHT = 19
local STEPPER_INSET = 19
local INPUT_WIDTH = 58
local INPUT_HEIGHT = 22
local INPUT_GAP = 12

---Automatically adjusting the formatting based on step.
---@param step number
---@return string
local function FormatForStep(step)
	if step >= 1 and step % 1 == 0 then
		return "%d"
	elseif step >= 0.1 then
		return "%.1f"
	end

	return "%.2f"
end

---@class AMTSliderWidget : AMTOptionWidget
---@field steppers Frame
---@field slider Slider
---@field box Frame
---@field input EditBox
---@field hover AMTBorder?
---@field format string
---@field applying boolean?
local Slider = Options.NewWidgetPrototype("slider")

---@return number
function Slider:GetControlHeight()
	return INPUT_HEIGHT
end

---@return table[]
function Slider:GetTooltipRegions()
	return { self.slider, self.input }
end

---@return number min
---@return number max
---@return number step
function Slider:GetRange()
	local info = self.info

	if not info then
		return 0, 1, 1
	end

	return info.min or 0, info.max or 1, info.step or 1
end

---@param value number
---@return number
function Slider:SnapToStep(value)
	local min, max, step = self:GetRange()
	local snapped = min + math.floor((value - min) / step + 0.5) * step

	return math.max(min, math.min(max, snapped))
end

---@param direction number sign of the wheel delta
function Slider:Step(direction)
	local _, _, step = self:GetRange()

	if self.disabled then
		return
	end

	self:SetValue(self:SnapToStep(self.slider:GetValue() + direction * step))
end

function Slider:RefreshInput()
	self.input:SetText(self.format:format(self.slider:GetValue()))
	self.input:SetCursorPosition(0)
end

---@return boolean accepted
function Slider:CommitInput()
	local min, max = self:GetRange()
	local typed = tonumber(self.input:GetText())

	if not typed or typed < min or typed > max then
		self:RefreshInput()

		return false
	end

	self:SetValue(self:SnapToStep(typed))

	return true
end

---@param parent Frame
function Slider:Create(parent)
	Options.Widget.Create(self, parent)

	self.format = "%d"

	local steppers = CreateFrame("Frame", nil, self.frame, "MinimalSliderWithSteppersTemplate")

	steppers:SetSize(SLIDER_WIDTH + STEPPER_INSET * 2, SLIDER_HEIGHT)
	steppers:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)

	local slider = steppers.Slider

	local box = CreateFrame("Frame", nil, self.frame)

	box:SetSize(INPUT_WIDTH, INPUT_HEIGHT)
	box:SetPoint("LEFT", steppers, "RIGHT", INPUT_GAP, 0)

	AMT.NineSlice.Apply(box, "Control", CONST.CORNER_SIZE)

	local hover = AMT.NineSlice.Apply(box, "Hover", CONST.CORNER_SIZE)

	if hover then
		hover:SetShown(false)
	end

	local input = CreateFrame("EditBox", nil, box)

	input:SetPoint("TOPLEFT", box, "TOPLEFT", 4, 0)
	input:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 0)
	input:SetFontObject(CONST.FONT_SMALL)
	input:SetJustifyH("CENTER")
	input:SetAutoFocus(false)
	input:SetMaxLetters(8)

	self.steppers = steppers
	self.slider = slider
	self.box = box
	self.input = input
	self.hover = hover

	input:SetScript("OnEnterPressed", function(editBox)
		self:CommitInput()
		editBox:ClearFocus()
	end)

	input:SetScript("OnEscapePressed", function(editBox)
		self:RefreshInput()
		editBox:ClearFocus()
	end)

	input:SetScript("OnEditFocusLost", function(editBox)
		self:RefreshInput()

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

	local function OnMouseWheel(_, delta)
		self:Step(delta > 0 and 1 or -1)
	end

	for _, frame in ipairs({ steppers, slider, box, input }) do
		frame:EnableMouseWheel(true)
		frame:SetScript("OnMouseWheel", OnMouseWheel)
	end

	slider:HookScript("OnValueChanged", function(_, value)
		self:RefreshInput()

		if self.applying then
			return
		end

		self:SetValue(value)
	end)
end

function Slider:Update()
	if not Options.Widget.Update(self) then
		return
	end

	local min, max, step = self:GetRange()

	self.format = FormatForStep(step)

	self.applying = true

	self.slider:SetMinMaxValues(min, max)
	self.slider:SetValueStep(step)
	self.slider:SetObeyStepOnDrag(true)
	self.slider:SetValue(self:SnapToStep(tonumber(self:GetValue()) or min))

	self.applying = false

	self:RefreshInput()

	self.input:SetEnabled(not self.disabled)
	self.steppers:SetEnabled(not self.disabled)
end
