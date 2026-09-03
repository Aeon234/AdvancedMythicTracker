local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local BOX_SIZE = 20
local TICK_INSET = 1
local TICK_TEXTURE = [[Interface\Buttons\UI-CheckBox-Check]]
local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

---@param parent Frame
---@param onClick fun()
---@return Button control
---@return Texture tick
---@return AMTBorder? hover
function Options.CreateCheckboxControl(parent, onClick)
	local control = CreateFrame("Button", nil, parent)

	control:SetSize(BOX_SIZE, BOX_SIZE)
	control:RegisterForClicks("LeftButtonUp")

	AMT.NineSlice.Apply(control, "Control", CONST.CORNER_SIZE)

	local tick = control:CreateTexture(nil, "ARTWORK")

	tick:SetPoint("TOPLEFT", control, "TOPLEFT", TICK_INSET, -TICK_INSET)
	tick:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", -TICK_INSET, TICK_INSET)
	tick:SetTexture(TICK_TEXTURE)
	tick:SetVertexColor(GOLD_R, GOLD_G, GOLD_B)
	tick:Hide()

	local hover = AMT.NineSlice.Apply(control, "Hover", CONST.CORNER_SIZE, "OVERLAY")

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

	control:SetScript("OnClick", onClick)

	return control, tick, hover
end

---@class AMTCheckboxWidget : AMTOptionWidget
---@field control Button
---@field tick Texture
local Checkbox = Options.NewWidgetPrototype("checkbox")

---@return number
function Checkbox:GetControlHeight()
	return BOX_SIZE
end

---@param parent Frame
function Checkbox:Create(parent)
	Options.Widget.Create(self, parent)
	local control, tick = Options.CreateCheckboxControl(self.frame, function()
		self:SetValue(not self:GetValue())
	end)

	control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)

	self.control = control
	self.tick = tick
end

function Checkbox:Update()
	if not Options.Widget.Update(self) then
		return
	end

	self.tick:SetShown(self:GetValue() == true)
	self.control:SetEnabled(not self.disabled)
end
