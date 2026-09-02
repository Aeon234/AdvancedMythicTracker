local AMT = select(2, ...)

---@class AMTTimerModule : AMTModule
---@field element Frame
---@field bar AMTBarMixin
---@field text AMTTextMixin
---@field thresholds AMTTextMixin[]
local module = AMT.Modules.New("Timer")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("timer"))

	self.bar = AMT.Mixins.NewBar(self.element)
	self.bar:SetAllPoints()

	self.text = AMT.Mixins.NewText(self.bar)
	self.bar:AttachToSlot(self.text, "LEFT")

	self.thresholds = {}

	for index = 1, 3 do
		self.thresholds[index] = AMT.Mixins.NewText(self.bar)
	end

	AMT.Layout.RegisterElement("timer", "timerBar", self.element)

	AMT.Render.Register("timer", function()
		self:Render()
	end)

	AMT.Render.Register("keyInfo", function()
		self:RefreshMarks()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer

	self.element:SetHeight(profile.bar.height)
	self.bar:ApplyStyle(profile.bar)
	self.text:ApplyStyle(profile.text)
	for index, text in ipairs(self.thresholds) do
		text:ApplyStyle(profile.thresholds[index].text)
	end
	self:RefreshMarks()

	AMT.State.MarkDirty("layout")
end

function module:RefreshMarks()
	local bar = AMT.Profiles.active.timer.bar
	local limits = AMT.State.current.timeLimits
	local tickColor = bar.tickColor or { 1, 1, 1, 0.5 }

	if not limits[1] or limits[1] <= 0 then
		self.bar:SetTicks({}, tickColor)

		return
	end

	local fractions = {}

	for tier = 2, #limits do
		fractions[#fractions + 1] = limits[tier] / limits[1]
	end

	self.bar:SetTicks(bar.showTicks and fractions or {}, tickColor)

	for index, text in ipairs(self.thresholds) do
		self.bar:AttachAtFraction(text, limits[index] / limits[1])
	end
end

---@return string
function module:FormatDisplayTime()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer
	local separator = profile.spacedSlash and " / " or "/"
	local current

	if state.challengeCompleted and state.completionMS then
		current = AMT.Util.FormatTime(state.completionMS / 1000, profile.decimals)
	elseif profile.direction == "DOWN" then
		local remaining = state.timeLimit - state.elapsed

		current = AMT.Util.FormatTime(remaining, 0, remaining < 0)
	else
		current = AMT.Util.FormatTime(state.elapsed)
	end

	return current .. separator .. AMT.Util.FormatTime(state.timeLimit)
end

function module:RenderThresholds()
	local profile = AMT.Profiles.active.timer
	local state = AMT.State.current
	local limits = state.timeLimits

	for index, text in ipairs(self.thresholds) do
		local settings = profile.thresholds[index]
		local limit = limits[index]

		if not settings.enabled or not limit then
			text:Hide()
		elseif state.challengeCompleted then
			local achieved = (state.upgradeLevels or 0) >= index
			local difference = limit - state.elapsed

			text:SetText((achieved and "-" or "+") .. AMT.Util.FormatTime(math.abs(difference)))
			text:SetColor(achieved and settings.aheadColor or settings.behindColor)
			text:Show()
		else
			local remaining = limit - state.elapsed

			if remaining >= 0 then
				text:SetText(AMT.Util.FormatTime(remaining))
				text:SetColor(settings.text.color)
				text:Show()
			elseif index == 1 then
				text:SetText("+" .. AMT.Util.FormatTime(-remaining))
				text:SetColor(settings.behindColor)
				text:Show()
			else
				text:Hide()
			end
		end
	end
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
	self:RenderThresholds()

	if state.challengeCompleted then
		self.text:SetColor(state.completedOnTime and profile.successColor or profile.failColor)
	else
		self.text:SetColor(profile.text.color)
	end
end
