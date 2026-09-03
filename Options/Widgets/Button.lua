local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local BUTTON_WIDTH = 160
local BUTTON_HEIGHT = 28
local ICON_SIZE = 14
local ICON_GAP = 6
local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

---@param parent Frame
---@param onClick fun()
---@return Button control
---@return FontString label
---@return Texture icon
---@return AMTBorder? hover
function Options.CreateActionButton(parent, onClick)
	local control = CreateFrame("Button", nil, parent)

	control:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
	control:RegisterForClicks("LeftButtonUp")

	AMT.NineSlice.Apply(control, "Control", CONST.CORNER_SIZE)

	local hover = AMT.NineSlice.Apply(control, "Hover", CONST.CORNER_SIZE, "OVERLAY")

	if hover then
		hover:SetShown(false)
	end

	local label = control:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	label:SetTextColor(1, 1, 1)

	local icon = control:CreateTexture(nil, "ARTWORK")

	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("RIGHT", label, "LEFT", -ICON_GAP, 0)
	icon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B)
	icon:Hide()

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

	return control, label, icon, hover
end

---@class AMTButtonWidget : AMTOptionWidget
---@field control Button
---@field text FontString
---@field icon Texture
local ActionButton = Options.NewWidgetPrototype("button")

---@return number
function ActionButton:GetControlHeight()
	return BUTTON_HEIGHT
end

---@param parent Frame
function ActionButton:Create(parent)
	Options.Widget.Create(self, parent)

	local control, label, icon = Options.CreateActionButton(self.frame, function()
		local info = self.info

		if not info or self.disabled then
			return
		end

		if info.set then
			info.set(nil)
		end

		Options.NotifyValueChanged()
	end)

	control:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)

	self.control = control
	self.text = label
	self.icon = icon
end

function ActionButton:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	local hasIcon = info.icon ~= nil

	self.text:SetText(info.text or info.label or "")

	self.text:ClearAllPoints()
	self.text:SetPoint("CENTER", self.control, "CENTER", hasIcon and (ICON_SIZE + ICON_GAP) / 2 or 0, 0)

	if hasIcon then
		self.icon:SetTexture(info.icon)
	end

	self.icon:SetShown(hasIcon)
	self.control:SetEnabled(not self.disabled)
end
