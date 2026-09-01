local AMT = select(2, ...)

local SLOT_INSET = 4

---@class AMTBarSlotAnchor
---@field point "LEFT"|"CENTER"|"RIGHT"
---@field relativePoint "LEFT"|"CENTER"|"RIGHT"
---@field x number

---@type table<string, AMTBarSlotAnchor>
local SLOT_ANCHORS = {
	LEFT = { point = "LEFT", relativePoint = "LEFT", x = SLOT_INSET },
	CENTER = { point = "CENTER", relativePoint = "CENTER", x = 0 },
	RIGHT = { point = "RIGHT", relativePoint = "RIGHT", x = -SLOT_INSET },
}

---@class AMTBarStyle
---@field texture string LibSharedMedia statusbar name
---@field color number[] {r, g, b, a} fill
---@field background number[]? {r, g, b, a} background
---@field height number

---@class AMTBarMixin : StatusBar
---@field background Texture
local Bar = {}
AMT.Mixins.Bar = Bar

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
	local color = style.color

	if texture then
		self:SetStatusBarTexture(texture)
	end

	self:SetStatusBarColor(color[1], color[2], color[3], color[4])

	local background = style.background

	if background then
		if texture then
			self.background:SetTexture(texture)
		end

		self.background:SetVertexColor(background[1], background[2], background[3], background[4])
		self.background:Show()
	else
		self.background:Hide()
	end

	if style.height then
		self:SetHeight(style.height)
	end
end

---@param region FontString|Texture
---@param slot "LEFT"|"CENTER"|"RIGHT"
function Bar:AttachToSlot(region, slot)
	local anchor = SLOT_ANCHORS[slot]

	if not anchor then
		AMT.Util.Warn("unknown bar slot %q", tostring(slot))

		return
	end

	region:ClearAllPoints()
	region:SetPoint(anchor.point, self, anchor.relativePoint, anchor.x, 0)
end

---@param parent Frame
---@return AMTBarMixin
function AMT.Mixins.NewBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)

	Mixin(bar, Bar)
	bar:OnLoad()

	return bar
end
