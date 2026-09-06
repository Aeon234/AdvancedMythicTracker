local AMT = select(2, ...)
local L = AMT.L

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

function module:ApplyStyle()
	local timer = AMT.Profiles.active.timer
	local profile = timer.forces
	local Bar = AMT.Mixins.Bar
	local split = timer.splits.forcesSplit
	local above = math.max(
		profile.title.enabled and profile.title.text.size + 2 or 0,
		Bar.RowHeightFor(profile.count, "ABOVE"),
		Bar.RowHeightFor(profile.percent, "ABOVE"),
		Bar.RowHeightFor(split, "ABOVE")
	)
	local below = math.max(
		Bar.RowHeightFor(profile.count, "BELOW"),
		Bar.RowHeightFor(profile.percent, "BELOW"),
		Bar.RowHeightFor(split, "BELOW")
	)

	self.element:SetHeight(self.bar:LayoutRows(self.element, self.aboveRow, self.belowRow, above, below, profile.bar.height))
	self.bar:ApplyStyle(profile.bar)

	self.title:ApplyStyle(profile.title.text)
	self.title:ClearAllPoints()
	self.title:SetPoint(timer.justify, self.aboveRow, timer.justify, 0, 0)
	self.title:SetText(L["Enemy Forces"])
	self.title:SetShown(profile.title.enabled)

	self.count:ApplyStyle(profile.count.text)
	self.bar:Place(self.count, profile.count, self.aboveRow, self.belowRow)

	self.percent:ApplyStyle(profile.percent.text)
	self.bar:Place(self.percent, profile.percent, self.aboveRow, self.belowRow)

	self.percentFormat = "%." .. profile.decimals .. "f%%"

	self.split:ApplyStyle(split.text)
	self.bar:Place(self.split, split, self.aboveRow, self.belowRow)

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
