local AMT = select(2, ...)
local L = AMT.L

-- A row is its tallest font plus breathing room, and sits this far from the bar.
local ROW_PADDING = 2
local ROW_GAP = 2

---@class AMTForcesModule : AMTModule
---@field element Frame
---@field bar AMTBarMixin
---@field aboveRow Frame
---@field belowRow Frame
---@field title AMTTextMixin
---@field count AMTTextMixin
---@field percent AMTTextMixin
---@field percentFormat string
---@field split AMTTextMixin
local module = AMT.Modules.New("Forces")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("forces"))

	self.bar = AMT.Mixins.NewBar(self.element)

	self.aboveRow = CreateFrame("Frame", nil, self.element)
	self.belowRow = CreateFrame("Frame", nil, self.element)

	self.title = AMT.Mixins.NewText(self.aboveRow)
	self.count = AMT.Mixins.NewText(self.bar)
	self.percent = AMT.Mixins.NewText(self.bar)
	self.split = AMT.Mixins.NewText(self.bar)

	AMT.Layout.RegisterElement("forces", "forcesBar", self.element)

	AMT.Render.Register("forces", function()
		self:Render()
	end)

	self:ApplyStyle()
end

---Rows are sized from the profile rather than measured, so the frame's height cannot depend on
---which pass last rendered a string.
---@return number above
---@return number below
function module:MeasureRows()
	local timer = AMT.Profiles.active.timer
	local profile = timer.forces
	local above, below = 0, 0

	if profile.title.enabled then
		above = profile.title.text.size + ROW_PADDING
	end

	local function Consider(settings)
		if not settings.enabled then
			return
		end

		local height = settings.text.size + ROW_PADDING

		if settings.placement == "ABOVE" then
			above = math.max(above, height)
		elseif settings.placement == "BELOW" then
			below = math.max(below, height)
		end
	end

	Consider(profile.count)
	Consider(profile.percent)
	Consider(timer.splits.forcesSplit)

	return above, below
end

---@param region AMTTextMixin
---@param settings AMTOverlayTextSettings
function module:Attach(region, settings)
	local nudge = settings.nudge

	if settings.placement == "ABOVE" or settings.placement == "BELOW" then
		local row = settings.placement == "ABOVE" and self.aboveRow or self.belowRow

		AMT.Mixins.Bar.AttachToRow(region, row, settings.slot, nudge[1], nudge[2])

		return
	end

	self.bar:AttachToSlot(region, settings.slot, nudge[1], nudge[2])
end

function module:ApplyStyle()
	local timer = AMT.Profiles.active.timer
	local profile = timer.forces
	local above, below = self:MeasureRows()
	local barTop = above > 0 and above + ROW_GAP or 0
	local barBottom = below > 0 and below + ROW_GAP or 0

	self.element:SetHeight(barTop + profile.bar.height + barBottom)

	self.aboveRow:ClearAllPoints()
	self.aboveRow:SetPoint("TOPLEFT", self.element, "TOPLEFT", 0, 0)
	self.aboveRow:SetPoint("TOPRIGHT", self.element, "TOPRIGHT", 0, 0)
	self.aboveRow:SetHeight(math.max(above, 1))
	self.aboveRow:SetShown(above > 0)

	self.belowRow:ClearAllPoints()
	self.belowRow:SetPoint("BOTTOMLEFT", self.element, "BOTTOMLEFT", 0, 0)
	self.belowRow:SetPoint("BOTTOMRIGHT", self.element, "BOTTOMRIGHT", 0, 0)
	self.belowRow:SetHeight(math.max(below, 1))
	self.belowRow:SetShown(below > 0)

	self.bar:ClearAllPoints()
	self.bar:SetPoint("TOPLEFT", self.element, "TOPLEFT", 0, -barTop)
	self.bar:SetPoint("TOPRIGHT", self.element, "TOPRIGHT", 0, -barTop)
	self.bar:SetHeight(profile.bar.height)
	self.bar:ApplyStyle(profile.bar)

	self.title:ApplyStyle(profile.title.text)
	self.title:ClearAllPoints()
	self.title:SetPoint("LEFT", self.aboveRow, "LEFT", 0, 0)
	self.title:SetText(L["Enemy Forces"])
	self.title:SetShown(profile.title.enabled)

	self.count:ApplyStyle(profile.count.text)
	self:Attach(self.count, profile.count)

	self.percent:ApplyStyle(profile.percent.text)
	self:Attach(self.percent, profile.percent)

	self.percentFormat = "%." .. profile.decimals .. "f%%"

	self.split:ApplyStyle(timer.splits.forcesSplit.text)
	self:Attach(self.split, timer.splits.forcesSplit)

	AMT.State.MarkDirty("layout")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer.forces
	local separator = profile.spacedSlash and " / " or "/"

	self.bar:SetValues(state.currentCount, state.totalCount)
	self.bar:SetColor(state.forcesCompleted and profile.completedColor or profile.bar.color)

	local shown = profile.showRemaining and (state.totalCount - state.currentCount) or state.currentCount

	self.count:SetText(profile.showTotal and (shown .. separator .. state.totalCount) or tostring(shown))
	self.count:SetShown(profile.count.enabled)

	self.percent:SetFormatted(self.percentFormat, state.currentPercent * 100)
	self.percent:SetShown(profile.percent.enabled)

	local splits = AMT.Profiles.active.timer.splits
	local diff = splits.forcesSplit.enabled
			and (splits.boss == "ALWAYS" or state.challengeCompleted)
			and AMT.Splits.ForcesDiffMS()
		or nil

	if diff then
		self.split:SetText(AMT.Util.FormatTime(diff / 1000, splits.decimals, true))
		self.split:SetColor(AMT.Util.SplitColor(splits, AMT.Splits.Classify(diff)))
		self.split:Show()
	else
		self.split:Hide()
	end
end
