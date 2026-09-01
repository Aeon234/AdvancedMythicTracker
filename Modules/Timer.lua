local AMT = select(2, ...)

---@class AMTTimerModule : AMTModule
---@field bar AMTBarMixin
---@field text AMTTextMixin
local module = AMT.Modules.New("Timer")

function module:OnInitialize()
	local profile = AMT.Profiles.active.timer

	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("timer"))

	self.bar = AMT.Mixins.NewBar(self.element)
	self.bar:SetAllPoints()

	self.text = AMT.Mixins.NewText(self.bar)
	self.bar:AttachToSlot(self.text, "LEFT")

	AMT.Layout.RegisterElement("timer", "timerBar", self.element)
	AMT.Render.Register("timer", function()
		self:Render()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer

	self.element:SetHeight(profile.bar.height)
	self.bar:ApplyStyle(profile.bar)
	self.text:ApplyStyle(profile.text)

	-- A height change moves everything below it.
	AMT.State.MarkDirty("layout")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local state = AMT.State.current

	self.bar:SetValues(state.elapsed, state.timeLimit)
	self.text:SetText(AMT.Util.FormatTime(state.elapsed))
end
