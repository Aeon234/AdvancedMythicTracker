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

---@return string
function module:FormatDisplayTime()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer

	if state.challengeCompleted and state.completionMS then
		return AMT.Util.FormatTime(state.completionMS / 1000, profile.decimals)
	end

	if profile.direction == "DOWN" then
		local remaining = state.timeLimit - state.elapsed

		return AMT.Util.FormatTime(remaining, 0, remaining < 0)
	end

	return AMT.Util.FormatTime(state.elapsed)
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer
	local completed = state.challengeCompleted and state.completionMS
	local seconds = completed and (state.completionMS / 1000) or state.elapsed

	self.bar:SetValues(seconds, state.timeLimit)
	self.bar:SetTickCutoff(state.timeLimit > 0 and seconds / state.timeLimit or 0)

	if profile.bar.tierColors then
		self.bar:SetColor(profile.bar.tierColors[AMT.Challenge.GetUpgradeTier() + 1])
	end

	self.text:SetText(self:FormatDisplayTime())

	if state.challengeCompleted then
		self.text:SetColor(state.completedOnTime and profile.successColor or profile.failColor)
	else
		self.text:SetColor(profile.text.color)
	end
end
