local AMT = select(2, ...)

local SLOT_INSET = 4

local SLOT_ANCHORS = {
	LEFT = { "LEFT", "LEFT", SLOT_INSET },
	CENTER = { "CENTER", "CENTER", 0 },
	RIGHT = { "RIGHT", "RIGHT", -SLOT_INSET },
}

---@class AMTBarStyle
---@field texture string? LibSharedMedia statusbar name
---@field color number[] {r, g, b, a} fill
---@field background number[]? {r, g, b, a} background
---@field height number?

---@class AMTBarMixin
local Bar = {}
AMT.Mixins.Bar = Bar

---@class AMTBar : StatusBar, AMTBarMixin

function Bar:OnLoad()
	self:SetMinMaxValues(0, 1)
	self:SetValue(0)

	self.background = self:CreateTexture(nil, "BACKGROUND")
	self.background:SetAllPoints()
	self.background:Hide()
end

---@param current number
---@param max number
function Bar:SetValues(current, max)
	if max <= 0 then
		self:SetMinMaxValues(0, 1)
		self:SetValue(0)

		return
	end

	self:SetMinMaxValues(0, max)
	self:SetValue(math.min(current, max))
end

---@param style AMTBarStyle
function Bar:ApplyStyle(style)
	local texture = AMT.Media.Statusbar(style.texture)

	if texture then
		self:SetStatusBarTexture(texture)
	end

	self:SetStatusBarColor(unpack(style.color))

	if style.background then
		if texture then
			self.background:SetTexture(texture)
		end

		self.background:SetVertexColor(unpack(style.background))
		self.background:Show()
	else
		self.background:Hide()
	end

	if style.height then
		self:SetHeight(style.height)
	end
end

---@param region Region
---@param slot "LEFT"|"CENTER"|"RIGHT"
function Bar:AttachToSlot(region, slot)
	local anchor = SLOT_ANCHORS[slot]

	if not anchor then
		AMT.Util.Warn("unknown bar slot %q", tostring(slot))

		return
	end

	region:ClearAllPoints()
	region:SetPoint(anchor[1], self, anchor[2], anchor[3], 0)
end

---@param parent Frame
---@return AMTBar
function AMT.Mixins.NewBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)

	Mixin(bar, Bar)
	bar:OnLoad()

	return bar
end
