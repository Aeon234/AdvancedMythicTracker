local AMT = select(2, ...)

---@class AMTForcesModule : AMTModule
---@field element Frame
---@field bar AMTBarMixin
---@field count AMTTextMixin
---@field percent AMTTextMixin
---@field percentFormat string
---@field split AMTTextMixin
local module = AMT.Modules.New("Forces")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("forces"))

	self.bar = AMT.Mixins.NewBar(self.element)
	self.bar:SetAllPoints()

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
	local profile = AMT.Profiles.active.timer.forces

	self.element:SetHeight(profile.bar.height)
	self.bar:ApplyStyle(profile.bar)

	self.count:ApplyStyle(profile.count.text)
	self.bar:AttachToSlot(self.count, profile.count.slot)

	self.percent:ApplyStyle(profile.percent.text)
	self.bar:AttachToSlot(self.percent, profile.percent.slot)

	self.percentFormat = "%." .. profile.decimals .. "f%%"

	local splits = AMT.Profiles.active.timer.splits
	self.split:ApplyStyle(splits.forcesSplit.text)
	self.bar:AttachToSlot(self.split, splits.forcesSplit.slot)

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

	self.count:SetText(state.currentCount .. separator .. state.totalCount)
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
