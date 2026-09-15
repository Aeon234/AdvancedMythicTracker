local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local PADDING = 10
local TRACK_Y = -32
local BOTTOM_PADDING = 10

local PIP_COUNT = 8
local PIP_HEIGHT = 12
local PIP_CORNER = 8
local PIP_GAP = 8

local MILESTONE_COUNT = 3
local MILESTONE_GAP = 6
local MILESTONE_HEIGHT = 43
local MILESTONE_VALUE_SIZE = 14
local MILESTONE_UNIT_SIZE = 11
local MILESTONE_UNIT_GAP = 1
local LOCKED_GREY = 0.5
local PENDING = "..."

local RESET_TICK_SECONDS = 60
local SECONDS_PER_DAY = 86400
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_MINUTE = 60

---@param seconds number
---@return string
local function FormatReset(seconds)
	local days = math.floor(seconds / SECONDS_PER_DAY)
	local hours = math.floor(seconds % SECONDS_PER_DAY / SECONDS_PER_HOUR)

	if days > 0 then
		return L["Resets in %dd %dh"]:format(days, hours)
	end

	return L["Resets in %dh %dm"]:format(hours, math.floor(seconds % SECONDS_PER_HOUR / SECONDS_PER_MINUTE))
end

---@class AMTDashboardVaultPip
---@field frame Frame
---@field fill AMTBorder?
local Pip = {}
Pip.__index = Pip

---@param parent Frame
---@param index integer
---@param width number
---@return AMTDashboardVaultPip
function Pip.New(parent, index, width)
	local frame = CreateFrame("Frame", nil, parent)

	frame:SetSize(width, PIP_HEIGHT)
	frame:SetPoint("TOPLEFT", PADDING + (index - 1) * (width + PIP_GAP), TRACK_Y)

	AMT.NineSlice.Apply(frame, "Control", PIP_CORNER)

	local fill = AMT.NineSlice.Apply(frame, "Solid", PIP_CORNER, "ARTWORK")

	if fill then
		fill:SetVertexColor(NORMAL_FONT_COLOR:GetRGB())
		fill:SetShown(false)
	end

	Dashboard.Skin:Register(frame, "Control")
	Dashboard.Skin:Register(frame, "Solid")

	return setmetatable({ frame = frame, fill = fill }, Pip)
end

---@param lit boolean
function Pip:SetLit(lit)
	if self.fill then
		self.fill:SetShown(lit)
	end
end

---@class AMTDashboardVaultMilestoneView
---@field frame Frame
---@field value FontString
---@field unit FontString
local Milestone = {}
Milestone.__index = Milestone

---@param parent Frame
---@param pipWidth number
---@return AMTDashboardVaultMilestoneView
function Milestone.New(parent, pipWidth)
	local frame = CreateFrame("Frame", nil, parent)

	frame:SetSize(pipWidth + PIP_GAP, MILESTONE_HEIGHT)

	local value = Parts.CreateText(frame, "GameFontNormal", MILESTONE_VALUE_SIZE)

	value:SetPoint("TOP")

	local unit = Parts.CreateSubduedText(frame, MILESTONE_UNIT_SIZE)

	unit:SetPoint("TOP", value, "BOTTOM", 0, -MILESTONE_UNIT_GAP)

	frame:Hide()

	return setmetatable({ frame = frame, value = value, unit = unit }, Milestone)
end

---@param pip AMTDashboardVaultPip
function Milestone:AnchorUnder(pip)
	self.frame:ClearAllPoints()
	self.frame:SetPoint("TOP", pip.frame, "BOTTOM", 0, -MILESTONE_GAP)
end

---@param milestone AMTDashboardVaultMilestone
---@param progress integer
function Milestone:Refresh(milestone, progress)
	if progress >= milestone.threshold then
		self.value:SetText(milestone.itemLevel and tostring(milestone.itemLevel) or PENDING)
		self.value:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		self.unit:SetText(ITEM_LEVEL_ABBR)

		return
	end

	self.value:SetText(("%d/%d"):format(progress, milestone.threshold))
	self.value:SetTextColor(LOCKED_GREY, LOCKED_GREY, LOCKED_GREY)
	self.unit:SetText(L["runs"])
end

---@class AMTDashboardVault
---@field header AMTDashboardPanelHeader
---@field pips AMTDashboardVaultPip[]
---@field milestones AMTDashboardVaultMilestoneView[]
local Vault = {}
Dashboard.Vault = Vault

---@param root AMTDashboardPanelRoot
function Vault:Build(root)
	local frame = root.vault
	local pipWidth = (frame:GetWidth() - 2 * PADDING - (PIP_COUNT - 1) * PIP_GAP) / PIP_COUNT

	self.header = Parts.NewPanelHeader(frame, PADDING)
	self.header:SetTitle(L["Great Vault"])

	self.pips = {}

	for index = 1, PIP_COUNT do
		self.pips[index] = Pip.New(frame, index, pipWidth)
	end

	self.milestones = {}

	for index = 1, MILESTONE_COUNT do
		self.milestones[index] = Milestone.New(frame, pipWidth)
	end

	local rule = Parts.CreateRule(frame)

	rule:SetPoint("BOTTOMLEFT", PADDING, 0)
	rule:SetPoint("BOTTOMRIGHT", -PADDING, 0)

	frame:SetHeight(-TRACK_Y + PIP_HEIGHT + MILESTONE_GAP + MILESTONE_HEIGHT + BOTTOM_PADDING)

	root:RegisterShowTicker(RESET_TICK_SECONDS, function()
		self:UpdateResetNote()
	end)
end

function Vault:UpdateResetNote()
	self.header:SetNote(FormatReset(Dashboard.Source:GetSecondsUntilWeeklyReset()))
end

---@param track AMTDashboardVaultTrack
function Vault:Refresh(track)
	for index, pip in ipairs(self.pips) do
		pip:SetLit(index <= track.progress)
	end

	for index, view in ipairs(self.milestones) do
		local milestone = track.milestones[index]

		if milestone then
			view:AnchorUnder(self.pips[math.min(math.max(milestone.threshold, 1), PIP_COUNT)])
			view:Refresh(milestone, track.progress)
		end

		view.frame:SetShown(milestone ~= nil)
	end
end
