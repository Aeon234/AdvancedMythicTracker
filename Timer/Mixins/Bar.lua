local AMT = select(2, ...)

local RING_CORNER = 16
local RING_OUTSET = 1

local SLOT_INSET = 4
-- A row is its tallest font plus breathing room, and sits this far from the bar.
local ROW_PADDING = 2
local ROW_GAP = 2

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

local MIRRORED_SLOTS = { LEFT = "RIGHT", RIGHT = "LEFT" }

---@class AMTBarStyle
---@field texture string LibSharedMedia statusbar name
---@field color number[] {r, g, b, a} fill
---@field background number[]? {r, g, b, a} background
---@field height number
---@field mode "UNIFIED"|"SEGMENTED"? one bar with marks, or one bar per threshold band
---@field fill "RIGHT"|"LEFT"? which way the bar grows; defaults to RIGHT
---@field tickWidth number? threshold mark thickness; defaults to 1
---@field tierColors number[][]? four {r,g,b,a} for timer
---@field border boolean? draws the edge around the bar; defaults to on

---@class AMTBarMixin : StatusBar
---@field reversed boolean? fill grows right to left, so marks measure from the right edge
---@field tickWidth number?
---@field background Texture
---@field border AMTBorder?
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

	self.border = AMT.NineSlice.Apply(self, "Ring", RING_CORNER, "OVERLAY", 1, RING_OUTSET)

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
	self.reversed = style.fill == "LEFT"
	self.tickWidth = style.tickWidth

	self:SetReverseFill(self.reversed)

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

	if self.border then
		self.border:SetShown(style.border ~= false)
	end

	if style.height then
		self:SetHeight(style.height)
	end
end

---@param region AMTAnchorable
---@param slot "LEFT"|"CENTER"|"RIGHT"
function Bar:AttachToSlot(region, slot, x, y)
	local anchor = SLOT_ANCHORS[slot]

	if not anchor then
		AMT.Util.Warn("unknown bar slot %q", tostring(slot))

		return
	end

	region:ClearAllPoints()
	region:SetPoint(anchor.point, self, anchor.relativePoint, anchor.x + (x or 0), y or 0)
end

---@param region AMTAnchorable
---@param side "LEFT"|"RIGHT"
---@param x number?
---@param y number?
function Bar:AttachBeside(region, side, x, y)
	local outward = side == "LEFT" and -SLOT_INSET or SLOT_INSET

	region:ClearAllPoints()
	region:SetPoint(side == "LEFT" and "RIGHT" or "LEFT", self, side, outward + (x or 0), y or 0)
end

---@param region AMTAnchorable
---@param parent Frame
---@param slot "LEFT"|"CENTER"|"RIGHT"
---@param x number?
---@param y number?
function Bar.AttachToRow(region, parent, slot, x, y)
	local point = slot == "CENTER" and "CENTER" or slot

	region:ClearAllPoints()
	region:SetPoint(
		point,
		parent,
		point,
		(x or 0) + (slot == "RIGHT" and -SLOT_INSET or slot == "LEFT" and SLOT_INSET or 0),
		y or 0
	)
end

---@param region AMTAnchorable
---@param fraction number 0-1
function Bar:AttachAtFraction(region, fraction, x, y)
	local offset = self:GetWidth() * fraction

	region:ClearAllPoints()

	if self.reversed then
		region:SetPoint("LEFT", self, "RIGHT", -offset + SLOT_INSET + (x or 0), y or 0)

		return
	end

	region:SetPoint("RIGHT", self, "LEFT", offset - SLOT_INSET + (x or 0), y or 0)
end

---@param settings AMTPlacedTextSettings
---@param placement "ABOVE"|"BELOW"
---@return number
function Bar.RowHeightFor(settings, placement)
	if settings.placement ~= placement or settings.enabled == false then
		return 0
	end

	return settings.text.size + ROW_PADDING
end

---@param element Frame
---@param above Frame
---@param below Frame
---@param aboveHeight number
---@param belowHeight number
---@param barHeight number
---@return number height
function Bar:LayoutRows(element, above, below, aboveHeight, belowHeight, barHeight)
	local top = aboveHeight > 0 and aboveHeight + ROW_GAP or 0
	local bottom = belowHeight > 0 and belowHeight + ROW_GAP or 0

	above:ClearAllPoints()
	above:SetPoint("TOPLEFT", element, "TOPLEFT", 0, 0)
	above:SetPoint("TOPRIGHT", element, "TOPRIGHT", 0, 0)
	above:SetHeight(math.max(aboveHeight, 1))
	above:SetShown(aboveHeight > 0)

	below:ClearAllPoints()
	below:SetPoint("BOTTOMLEFT", element, "BOTTOMLEFT", 0, 0)
	below:SetPoint("BOTTOMRIGHT", element, "BOTTOMRIGHT", 0, 0)
	below:SetHeight(math.max(belowHeight, 1))
	below:SetShown(belowHeight > 0)

	self:ClearAllPoints()
	self:SetPoint("TOPLEFT", element, "TOPLEFT", 0, -top)
	self:SetPoint("TOPRIGHT", element, "TOPRIGHT", 0, -top)
	self:SetHeight(barHeight)

	return top + barHeight + bottom
end

---@param region AMTAnchorable
---@param settings AMTPlacedTextSettings
---@param above Frame
---@param below Frame
function Bar:Place(region, settings, above, below)
	local nudge = settings.nudge
	local slot = settings.slot

	if settings.placement == "ABOVE" or settings.placement == "BELOW" then
		Bar.AttachToRow(region, settings.placement == "ABOVE" and above or below, slot, nudge[1], nudge[2])

		return
	end

	if settings.placement == "BESIDE" and slot ~= "CENTER" then
		self:AttachBeside(region, slot, nudge[1], nudge[2])

		return
	end

	if self.reversed then
		slot = MIRRORED_SLOTS[slot] or slot
	end

	self:AttachToSlot(region, slot, nudge[1], nudge[2])
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

---@class AMTBarTick
---@field fraction number 0-1
---@field color number[] {r, g, b, a}

---@param marks AMTBarTick[]
function Bar:SetTicks(marks)
	local width = self:GetWidth()

	wipe(self.tickFractions)

	for index = 1, #marks do
		self.tickFractions[index] = marks[index].fraction
	end

	for index = 1, math.max(#marks, #self.ticks) do
		local tick = self.ticks[index]

		if index <= #marks then
			if not tick then
				tick = self:CreateTexture(nil, "OVERLAY")
				tick:SetWidth(self.tickWidth or 1)
				self.ticks[index] = tick
			end

			local mark = marks[index]
			local color = mark.color
			local edge = self.reversed and "RIGHT" or "LEFT"
			local offset = width * mark.fraction

			if self.reversed then
				offset = -offset
			end

			tick:SetColorTexture(color[1], color[2], color[3], color[4])
			tick:ClearAllPoints()
			tick:SetPoint("TOP", self, "TOP" .. edge, offset, 0)
			tick:SetPoint("BOTTOM", self, "BOTTOM" .. edge, offset, 0)
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
