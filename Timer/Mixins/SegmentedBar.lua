local AMT = select(2, ...)

local GAP = 7
local FALLBACK = { 0.2, 0.2, 0.6 } -- sub +12 key

---@class AMTSegmentedBarMixin : Frame
---@field segments AMTBarMixin[] indexed by threshold: 1 is +1, 3 is +3
---@field fractions number[] each segment's share of the width
local Segmented = {}
AMT.Mixins.Segmented = Segmented

---Bands come from the upgrade times: the +3 band runs from zero, the others from the tier below.
---@return number[] fractions indexed by threshold
local function Bands()
	local limits = AMT.State.current.timeLimits
	local total = limits[1]

	if not total or total <= 0 then
		return { FALLBACK[1], FALLBACK[2], FALLBACK[3] }
	end

	return {
		((limits[1] or 0) - (limits[2] or 0)) / total,
		((limits[2] or 0) - (limits[3] or 0)) / total,
		(limits[3] or 0) / total,
	}
end

---@param style AMTBarStyle
function Segmented:ApplyStyle(style)
	for _, segment in ipairs(self.segments) do
		segment:ApplyStyle(style)
	end
end

function Segmented:Layout()
	local width = math.floor(self:GetWidth())

	if width <= 0 then
		return
	end

	self.fractions = Bands()

	local usable = width - GAP * 2
	local reversed = self.segments[1].reversed
	local consumed = 0
	local edge = 0

	for order, index in ipairs({ 3, 2, 1 }) do
		local segment = self.segments[index]

		consumed = consumed + self.fractions[index]

		local finish = math.min(math.floor(consumed * usable + 0.5), usable)
		local segmentWidth = math.max(finish - edge, 1)
		local offset = edge + (order - 1) * GAP

		segment:ClearAllPoints()
		segment:SetWidth(segmentWidth)

		if reversed then
			segment:SetPoint("TOPRIGHT", self, "TOPRIGHT", -offset, 0)
			segment:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -offset, 0)
		else
			segment:SetPoint("TOPLEFT", self, "TOPLEFT", offset, 0)
			segment:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", offset, 0)
		end

		edge = edge + segmentWidth
	end
end

---@param elapsed number
---@param limit number
function Segmented:SetValues(elapsed, limit)
	if limit <= 0 then
		for _, segment in ipairs(self.segments) do
			segment:SetValues(0, 1)
		end

		return
	end

	local limits = AMT.State.current.timeLimits
	local starts = { limits[2] or 0, limits[3] or 0, 0 }
	local ends = { limits[1] or limit, limits[2] or 0, limits[3] or 0 }

	for index = 1, 3 do
		local span = ends[index] - starts[index]
		local progress = span > 0 and (elapsed - starts[index]) / span or 0

		self.segments[index]:SetValues(math.max(math.min(progress, 1), 0), 1)
	end
end

---@param color number[]
function Segmented:SetColor(color)
	for index = 1, 3 do
		self.segments[index]:SetColor(color)
	end
end

---@param index integer threshold index
---@return AMTBarMixin
function Segmented:GetSegment(index)
	return self.segments[index]
end

---@param parent Frame
---@return AMTSegmentedBarMixin
function AMT.Mixins.NewSegmentedBar(parent)
	local frame = CreateFrame("Frame", nil, parent) --[[@as AMTSegmentedBarMixin]]

	Mixin(frame, Segmented)

	frame.segments = {}
	frame.fractions = { FALLBACK[1], FALLBACK[2], FALLBACK[3] }

	for index = 1, 3 do
		frame.segments[index] = AMT.Mixins.NewBar(frame)
	end

	frame:SetScript("OnSizeChanged", function()
		frame:Layout()
	end)

	return frame
end
