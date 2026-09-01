local AMT = select(2, ...)

---@class AMTTimerModule : AMTModule
---@field bar AMTBarMixin
---@field text AMTTextMixin
local module = AMT.Modules.New("Timer")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("timer"))

	self.bar = AMT.Mixins.NewBar(self.element)
	self.bar:SetAllPoints()

	self.text = AMT.Mixins.NewText(self.bar)
	self.bar:AttachToSlot(self.text, "LEFT")

	AMT.Layout.RegisterElement("timer", "timerBar", self.element)

	AMT.Render.Register("timer", function()
		self:Render()
	end)

	AMT.Render.Register("keyInfo", function()
		self:RefreshTicks()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer

	self.element:SetHeight(profile.bar.height)
	self.bar:ApplyStyle(profile.bar)
	self.text:ApplyStyle(profile.text)
	self:RefreshTicks()

	AMT.State.MarkDirty("layout")
end

function module:RefreshTicks()
	local bar = AMT.Profiles.active.timer.bar
	local limits = AMT.State.current.timeLimits

	if not bar.showTicks or not limits[1] or limits[1] <= 0 then
		self.bar:SetTicks({}, bar.tickColor or { 1, 1, 1, 0.5 })

		return
	end

	local fractions = {}

	for tier = 2, #limits do
		fractions[#fractions + 1] = limits[tier] / limits[1]
	end

	self.bar:SetTicks(fractions, bar.tickColor or { 1, 1, 1, 0.5 })
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local state = AMT.State.current
	local tierColors = AMT.Profiles.active.timer.bar.tierColors

	self.bar:SetValues(state.elapsed, state.timeLimit)
	self.text:SetText(AMT.Util.FormatTime(state.elapsed))
	self.bar:SetTickCutoff(state.timeLimit > 0 and state.elapsed / state.timeLimit or 0)

	if tierColors then
		self.bar:SetColor(tierColors[AMT.Challenge.GetUpgradeTier() + 1])
	end
end
