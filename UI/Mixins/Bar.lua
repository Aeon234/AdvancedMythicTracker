local AMT = select(2, ...)

local SLOT_INSET = 4

---@alias AMTAnchorable FontString|Texture

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
---@field tierColors number[][]? four {r,g,b,a} for timer
---@field showTicks boolean?
---@field tickColor number[]?

---@class AMTBarMixin : StatusBar
---@field background Texture
---@field ticks Texture[]
---@field tickFractions number[]
local Bar = {}
AMT.Mixins.Bar = Bar

function Bar:OnLoad()
	self:SetMinMaxValues(0, 1)
	self:SetValue(0)

	self.background = self:CreateTexture(nil, "BACKGROUND")
	self.background:SetAllPoints()
	self.background:Hide()

	self.ticks = {}
	self.tickFractions = {}
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

---@param region AMTAnchorable
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

---@param region AMTAnchorable
---@param fraction number 0-1
function Bar:AttachAtFraction(region, fraction)
	region:ClearAllPoints()
	region:SetPoint("RIGHT", self, "LEFT", self:GetWidth() * fraction - SLOT_INSET, 0)
end

---@param parent Frame
---@return AMTBarMixin
function AMT.Mixins.NewBar(parent)
	local bar = CreateFrame("StatusBar", nil, parent)

	Mixin(bar, Bar)
	bar:OnLoad()

	return bar
end

---@param color number[]
function Bar:SetColor(color)
	self:SetStatusBarColor(color[1], color[2], color[3], color[4])
end

---@param fractions number[]
---@param color number[]
function Bar:SetTicks(fractions, color)
	local width = self:GetWidth()

	wipe(self.tickFractions)

	for index = 1, #fractions do
		self.tickFractions[index] = fractions[index]
	end

	for index = 1, math.max(#fractions, #self.ticks) do
		local tick = self.ticks[index]

		if index <= #fractions then
			if not tick then
				tick = self:CreateTexture(nil, "OVERLAY")
				tick:SetWidth(1)
				self.ticks[index] = tick
			end

			local offset = width * fractions[index]

			tick:SetColorTexture(color[1], color[2], color[3], color[4])
			tick:ClearAllPoints()
			tick:SetPoint("TOP", self, "TOPLEFT", offset, 0)
			tick:SetPoint("BOTTOM", self, "BOTTOMLEFT", offset, 0)
			tick:Show()
		elseif tick then
			tick:Hide()
		end
	end
end

---@param progress number 0-1
function Bar:SetTickCutoff(progress)
	for index, tick in ipairs(self.ticks) do
		local fraction = self.tickFractions[index]

		tick:SetShown(fraction ~= nil and fraction >= progress)
	end
end
