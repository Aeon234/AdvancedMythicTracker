local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local SWATCH_SIZE = 26

---@class AMTColorSwatchWidget : AMTOptionWidget
---@field control Button
---@field fill AMTBorder?
---@field hover AMTBorder?
local ColorSwatch = Options.NewWidgetPrototype("color")

---@return number
function ColorSwatch:GetControlHeight()
	return SWATCH_SIZE
end

---@return number r
---@return number g
---@return number b
---@return number a
function ColorSwatch:GetRGBA()
	local color = self:GetValue()

	if type(color) ~= "table" then
		return 1, 1, 1, 1
	end

	return color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1
end

function ColorSwatch:OpenPicker()
	if self.disabled then
		return
	end

	local r, g, b, a = self:GetRGBA()
	local hasOpacity = self.info ~= nil and self.info.hasOpacity == true

	-- Snapshotted here rather than trusting what the picker hands back on cancel.
	local previous = { r, g, b, a }

	local function OnPickerChanged()
		local pr, pg, pb = ColorPickerFrame:GetColorRGB()

		self:SetValue({ pr, pg, pb, hasOpacity and ColorPickerFrame:GetColorAlpha() or a })
	end

	ColorPickerFrame:SetupColorPickerAndShow({
		r = r,
		g = g,
		b = b,
		hasOpacity = hasOpacity,
		opacity = a,
		swatchFunc = OnPickerChanged,
		opacityFunc = OnPickerChanged,
		cancelFunc = function()
			self:SetValue(previous)
		end,
	})
end

---@param parent Frame
function ColorSwatch:Create(parent)
	Options.Widget.Create(self, parent)

	local control = CreateFrame("Button", nil, self.frame)

	control:SetSize(SWATCH_SIZE, SWATCH_SIZE)
	control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)
	control:RegisterForClicks("LeftButtonUp")

	AMT.NineSlice.Apply(control, "Control", CONST.CORNER_SIZE)

	self.fill = AMT.NineSlice.Apply(control, "Solid", CONST.CORNER_SIZE, "ARTWORK")

	AMT.NineSlice.Apply(control, "Ring", CONST.CORNER_SIZE, "OVERLAY")

	self.hover = AMT.NineSlice.Apply(control, "Hover", CONST.CORNER_SIZE, "OVERLAY", 1)

	if self.hover then
		self.hover:SetShown(false)
	end

	control:SetScript("OnEnter", function()
		if self.hover and control:IsEnabled() then
			self.hover:SetShown(true)
		end
	end)

	control:SetScript("OnLeave", function()
		if self.hover then
			self.hover:SetShown(false)
		end
	end)

	control:SetScript("OnClick", function()
		self:OpenPicker()
	end)

	self.control = control
end

function ColorSwatch:Update()
	if not Options.Widget.Update(self) then
		return
	end

	local r, g, b, a = self:GetRGBA()

	if self.fill then
		self.fill:SetVertexColor(r, g, b, a)
	end

	self.control:SetEnabled(not self.disabled)
end
