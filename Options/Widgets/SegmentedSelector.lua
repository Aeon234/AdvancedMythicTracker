local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local TRACK_HEIGHT = 26
local SEGMENT_PADDING = 14
local MIN_SEGMENT_WIDTH = 60
local SLIDE_DURATION = 0.18

local MAX_TRACK_WIDTH = 300

local SHOW_HOVER_HIGHLIGHT = false

---@param t number normalised 0-1
---@return number
local function EaseOutCubic(t)
	local inverse = 1 - t

	return 1 - inverse * inverse * inverse
end

---@class AMTSegmentedWidget : AMTOptionWidget
---@field track Frame
---@field thumb Frame
---@field segments Button[]
---@field labels FontString[]
---@field hovers AMTBorder[]
---@field segmentWidth number
---@field valuesRef table[]?
---@field thumbX number
---@field thumbStartX number?
---@field thumbTargetX number?
---@field thumbElapsed number?
---@field thumbUpdater function
local Segmented = Options.NewWidgetPrototype("segmented")

---@return number
function Segmented:GetControlHeight()
	return TRACK_HEIGHT
end

---@param elapsed number
function Segmented:OnThumbUpdate(elapsed)
	self.thumbElapsed = (self.thumbElapsed or 0) + elapsed

	local progress = self.thumbElapsed / SLIDE_DURATION

	if progress >= 1 then
		progress = 1
		self.thumb:SetScript("OnUpdate", nil)
	end

	local from = self.thumbStartX or 0
	local to = self.thumbTargetX or 0

	self.thumbX = from + (to - from) * EaseOutCubic(progress)
	self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", self.thumbX, 0)
end

---@param x number offset from the track's left edge
---@param instant boolean?
function Segmented:MoveThumb(x, instant)
	if instant or not self.thumb:IsShown() then
		self.thumb:SetScript("OnUpdate", nil)
		self.thumbX = x
		self.thumb:SetPoint("TOPLEFT", self.track, "TOPLEFT", x, 0)

		return
	end

	if self.thumbX == x then
		return
	end

	self.thumbStartX = self.thumbX
	self.thumbTargetX = x
	self.thumbElapsed = 0

	self.thumb:SetScript("OnUpdate", self.thumbUpdater)
end

---@param index integer
---@return Button
function Segmented:AcquireSegment(index)
	local existing = self.segments[index]

	if existing then
		return existing
	end

	local button = CreateFrame("Button", nil, self.track)

	button:SetFrameLevel(self.track:GetFrameLevel() + 2)
	button:RegisterForClicks("LeftButtonUp")

	local hover = AMT.NineSlice.Apply(button, "Hover", CONST.CORNER_SIZE)

	if hover then
		hover:SetShown(false)
	end

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")

	label:SetPoint("CENTER")
	label:SetTextColor(1, 1, 1)
	label:SetShadowOffset(1, -1)
	label:SetShadowColor(0, 0, 0, 1)

	button:SetScript("OnEnter", function()
		if hover then
			hover:SetShown(SHOW_HOVER_HIGHLIGHT and button:IsEnabled())
		end
	end)

	button:SetScript("OnLeave", function()
		if hover then
			hover:SetShown(false)
		end
	end)

	button:SetScript("OnClick", function()
		local values = self.info and self.info.values
		local entry = values and values[index]

		if entry and not self.disabled then
			self:SetValue(entry[1])
		end
	end)

	self.segments[index] = button
	self.labels[index] = label
	self.hovers[index] = hover

	return button
end

function Segmented:Rebuild()
	local values = (self.info and self.info.values) or {}
	local count = #values
	local widest = 0

	for index = 1, count do
		self:AcquireSegment(index)
		self.labels[index]:SetText(values[index][2])

		widest = math.max(widest, self.labels[index]:GetStringWidth())
	end

	local width = math.max(MIN_SEGMENT_WIDTH, math.ceil(widest) + SEGMENT_PADDING * 2)

	if width * count > MAX_TRACK_WIDTH then
		AMT.Util.Warn(
			"segmented selector %q needs %dpx; use a dropdown instead.",
			self.info and self.info.label or "?",
			width * count
		)
	end

	self.segmentWidth = width

	for index = 1, count do
		local button = self.segments[index]

		button:SetSize(width, TRACK_HEIGHT)
		button:SetPoint("TOPLEFT", self.track, "TOPLEFT", (index - 1) * width, 0)
		button:Show()
	end

	for index = count + 1, #self.segments do
		self.segments[index]:Hide()
	end

	self.track:SetSize(math.max(width * count, 1), TRACK_HEIGHT)
	self.thumb:SetSize(width, TRACK_HEIGHT)

	self.valuesRef = self.info and self.info.values
end

---@param parent Frame
function Segmented:Create(parent)
	Options.Widget.Create(self, parent)

	self.segments = {}
	self.labels = {}
	self.hovers = {}
	self.segmentWidth = MIN_SEGMENT_WIDTH
	self.thumbX = 0

	local track = CreateFrame("Frame", nil, self.frame)

	track:SetSize(MIN_SEGMENT_WIDTH, TRACK_HEIGHT)
	track:SetPoint("LEFT", self.frame, "LEFT", self:GetControlOffset(), 0)

	AMT.NineSlice.Apply(track, "Control", CONST.CORNER_SIZE)

	self.track = track

	local thumb = CreateFrame("Frame", nil, track)

	thumb:SetSize(MIN_SEGMENT_WIDTH, TRACK_HEIGHT)
	thumb:SetFrameLevel(track:GetFrameLevel() + 1)
	thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
	thumb:Hide()

	AMT.NineSlice.Apply(thumb, "Active", 10)

	self.thumb = thumb

	self.thumbUpdater = function(_, elapsed)
		self:OnThumbUpdate(elapsed)
	end
end

function Segmented:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	local values = info.values or {}

	if self.valuesRef ~= info.values then
		self:Rebuild()
	end

	local current = self:GetValue()
	local selected

	for index = 1, #values do
		if values[index][1] == current then
			selected = index

			break
		end
	end

	if selected then
		self:MoveThumb((selected - 1) * self.segmentWidth)
		self.thumb:Show()
	else
		self.thumb:Hide()
	end

	for index = 1, #values do
		self.segments[index]:SetEnabled(not self.disabled)
	end
end
