local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local SWATCH_SIZE = 26
local SWATCH_GAP = 8

---@class AMTColorSwatchWidget : AMTOptionWidget
---@field controls Button[]
---@field fills AMTBorder[]
---@field hovers AMTBorder[]
local ColorSwatch = Options.NewWidgetPrototype("color")

---@return number
function ColorSwatch:GetControlHeight()
	return SWATCH_SIZE
end

---@return string[]
function ColorSwatch:GetPaths()
	local info = self.info

	if not info then
		return {}
	end

	return info.paths or { info.path }
end

---@param index integer
---@return number r
---@return number g
---@return number b
---@return number a
function ColorSwatch:ReadColor(index)
	local info = self.info
	local color

	if info and not info.paths then
		color = self:GetValue()
	else
		local path = self:GetPaths()[index]

		color = path and Options.Get(path, info and info.scope) or nil
	end

	if type(color) ~= "table" then
		return 1, 1, 1, 1
	end

	return color[1] or 0, color[2] or 0, color[3] or 0, color[4] or 1
end

---@param index integer
---@param value number[]
function ColorSwatch:WriteColor(index, value)
	local info = self.info

	if info and not info.paths then
		self:SetValue(value)

		return
	end

	local path = self:GetPaths()[index]

	if path then
		Options.Set(path, value, info and info.scope)
		self:Update()
		Options.NotifyValueChanged()
	end
end

---@param index integer
function ColorSwatch:OpenPicker(index)
	if self.disabled then
		return
	end

	local r, g, b, a = self:ReadColor(index)
	local hasOpacity = self.info ~= nil and self.info.hasOpacity == true
	local previous = { r, g, b, a }

	local function OnPickerChanged()
		local pr, pg, pb = ColorPickerFrame:GetColorRGB()

		self:WriteColor(index, { pr, pg, pb, hasOpacity and ColorPickerFrame:GetColorAlpha() or a })
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
			self:WriteColor(index, previous)
		end,
	})
end

---@param index integer
---@return Button
function ColorSwatch:AcquireSwatch(index)
	local existing = self.controls[index]

	if existing then
		return existing
	end

	local control = CreateFrame("Button", nil, self.frame)

	control:SetSize(SWATCH_SIZE, SWATCH_SIZE)
	control:RegisterForClicks("LeftButtonUp")

	if index == 1 then
		control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)
	else
		control:SetPoint("LEFT", self.controls[index - 1], "RIGHT", SWATCH_GAP, 0)
	end

	AMT.NineSlice.Apply(control, "Control", CONST.CORNER_SIZE)

	local fill = AMT.NineSlice.Apply(control, "Solid", CONST.CORNER_SIZE, "ARTWORK")

	AMT.NineSlice.Apply(control, "Ring", CONST.CORNER_SIZE, "OVERLAY")

	local hover = AMT.NineSlice.Apply(control, "Hover", CONST.CORNER_SIZE, "OVERLAY", 1)

	if hover then
		hover:SetShown(false)
	end

	control:SetScript("OnEnter", function()
		if hover and control:IsEnabled() then
			hover:SetShown(true)
		end
	end)

	control:SetScript("OnLeave", function()
		if hover then
			hover:SetShown(false)
		end
	end)

	control:SetScript("OnClick", function()
		self:OpenPicker(index)
	end)

	self.controls[index] = control
	self.fills[index] = fill
	self.hovers[index] = hover

	return control
end

---@param parent Frame
function ColorSwatch:Create(parent)
	Options.Widget.Create(self, parent)

	self.controls = {}
	self.fills = {}
	self.hovers = {}
end

function ColorSwatch:Update()
	if not Options.Widget.Update(self) then
		return
	end

	local paths = self:GetPaths()

	for index = 1, #paths do
		local control = self:AcquireSwatch(index)
		local r, g, b, a = self:ReadColor(index)

		if self.fills[index] then
			self.fills[index]:SetVertexColor(r, g, b, a)
		end

		control:SetEnabled(not self.disabled)
		control:Show()
	end

	for index = #paths + 1, #self.controls do
		self.controls[index]:Hide()
	end
end
