local AMT = select(2, ...)

local Dashboard = AMT.Dashboard

local SUBDUED = 0.6
local UNPLAYED = "-"
local TIMED_COLOR = CreateColor(0.69, 0.69, 0.69)

local HAIRLINE_R, HAIRLINE_G, HAIRLINE_B, HAIRLINE_A = 0.75, 0.65, 0.45, 0.45
local HAIRLINE_INSET = 8
local RULE_ALPHA = 0.08

local HEADER_TITLE_SIZE = 16
local HEADER_TITLE_Y = -6
local HEADER_NOTE_SIZE = 11
local HEADER_NOTE_GAP = 8

local STAR_ATLAS = "CampCollection-icon-star"
local STAR_SIZE, STAR_SPACING = 11, 1
local MAX_STARS = 3
local UNEARNED_STAR_ALPHA = 0.5

local RUN_ICON_SIZE = 30
local RUN_ICON_CORNER = 16
local RUN_INFO_GAP = 5
local RUN_INFO_WIDTH = 76
local RUN_TEXT_SIZE = 14

---@class AMTDashboardParts
local Parts = {}
Dashboard.Parts = Parts

---@param parent Frame
---@param template "GameFontNormal"|"GameFontHighlight"
---@param size number
---@return FontString
function Parts.CreateText(parent, template, size)
	local text = parent:CreateFontString(nil, "ARTWORK", template)
	local path, _, flags = text:GetFont()

	if path then
		text:SetFont(path, size, flags)
	end

	Dashboard.Skin:Register(text, "text")

	return text
end

---@param parent Frame
---@param size number
---@return FontString
function Parts.CreateSubduedText(parent, size)
	local text = Parts.CreateText(parent, "GameFontHighlight", size)

	text:SetTextColor(SUBDUED, SUBDUED, SUBDUED)

	return text
end

---@param parent Frame
---@return Texture
function Parts.CreateRule(parent)
	local rule = parent:CreateTexture(nil, "ARTWORK")

	rule:SetHeight(1)
	rule:SetColorTexture(1, 1, 1, RULE_ALPHA)

	Dashboard.Skin:Register(rule, "rule")

	return rule
end

---@class AMTDashboardHairlineMixin : Frame
---@field upper Texture
---@field lower Texture
local Hairline = {}
Parts.HairlineMixin = Hairline

function Hairline:OnLoad()
	local bright = CreateColor(HAIRLINE_R, HAIRLINE_G, HAIRLINE_B, HAIRLINE_A)
	local clear = CreateColor(HAIRLINE_R, HAIRLINE_G, HAIRLINE_B, 0)

	self:SetWidth(1)

	self.upper = self:CreateTexture(nil, "ARTWORK")
	self.upper:SetColorTexture(1, 1, 1)
	self.upper:SetPoint("TOPLEFT", 0, -HAIRLINE_INSET)
	self.upper:SetPoint("BOTTOMRIGHT", self, "RIGHT")
	self.upper:SetGradient("VERTICAL", bright, clear)

	self.lower = self:CreateTexture(nil, "ARTWORK")
	self.lower:SetColorTexture(1, 1, 1)
	self.lower:SetPoint("TOPLEFT", self, "LEFT")
	self.lower:SetPoint("BOTTOMRIGHT", 0, HAIRLINE_INSET)
	self.lower:SetGradient("VERTICAL", clear, bright)

	Dashboard.Skin:Register(self, "hairline")
end

---@param parent Frame
---@return AMTDashboardHairlineMixin
function Parts.NewHairline(parent)
	local hairline = CreateFrame("Frame", nil, parent)

	Mixin(hairline, Hairline)
	hairline:OnLoad()

	return hairline
end

---@class AMTDashboardPanelHeader
---@field panel Frame
---@field padding number
---@field title FontString
---@field note FontString
local PanelHeader = {}
PanelHeader.__index = PanelHeader

---@param text string
function PanelHeader:SetTitle(text)
	self.title:SetText(text)
	self:FitNote()
end

---@param text string?
function PanelHeader:SetNote(text)
	self.note:SetText(text or "")
	self:FitNote()
end

function PanelHeader:FitNote()
	local room = self.panel:GetWidth() - 2 * self.padding - self.title:GetStringWidth() - HEADER_NOTE_GAP

	if room > 0 and self.note:GetUnboundedStringWidth() > room then
		self.note:SetWidth(room)
	else
		self.note:SetWidth(0)
	end
end

---@param panel Frame
---@param padding number
---@return AMTDashboardPanelHeader
function Parts.NewPanelHeader(panel, padding)
	local title = Parts.CreateText(panel, "GameFontNormal", HEADER_TITLE_SIZE)

	title:SetPoint("TOPLEFT", padding, HEADER_TITLE_Y)

	local note = Parts.CreateSubduedText(panel, HEADER_NOTE_SIZE)

	note:SetPoint("RIGHT", panel, "TOPRIGHT", -padding, HEADER_TITLE_Y - HEADER_TITLE_SIZE / 2)
	note:SetJustifyH("RIGHT")

	return setmetatable({ panel = panel, padding = padding, title = title, note = note }, PanelHeader)
end

---@class AMTDashboardStarRowMixin : Frame
---@field stars Texture[]
local StarRow = {}
Parts.StarRowMixin = StarRow

function StarRow:OnLoad()
	self:SetSize(MAX_STARS * STAR_SIZE + (MAX_STARS - 1) * STAR_SPACING, STAR_SIZE)

	self.stars = {}

	for index = 1, MAX_STARS do
		local star = self:CreateTexture(nil, "ARTWORK")

		star:SetAtlas(STAR_ATLAS)
		star:SetSize(STAR_SIZE, STAR_SIZE)
		star:SetPoint("LEFT", (index - 1) * (STAR_SIZE + STAR_SPACING), 0)

		self.stars[index] = star
	end

	self:SetEarned(0)
end

---@param earned integer 0 for a run over time, 1-3 for a timed one
function StarRow:SetEarned(earned)
	for index, star in ipairs(self.stars) do
		local lit = index <= earned

		star:SetDesaturated(not lit)
		star:SetAlpha(lit and 1 or UNEARNED_STAR_ALPHA)
	end
end

---@param parent Frame
---@return AMTDashboardStarRowMixin
function Parts.NewStarRow(parent)
	local row = CreateFrame("Frame", nil, parent)

	Mixin(row, StarRow)
	row:OnLoad()

	return row
end

---@class AMTDashboardRunSummary
---@field name string
---@field abbrev string
---@field texture number|string|nil
---@field level integer
---@field seconds number
---@field chests integer 0 for a run over time, 1-3 for a timed one

---@class AMTDashboardRunBlockMixin : Frame
---@field icon AMTDashboardIconMixin
---@field level FontString
---@field abbrev FontString
---@field time FontString
---@field stars AMTDashboardStarRowMixin
---@field run AMTDashboardRunSummary?
local RunBlock = {}
Parts.RunBlockMixin = RunBlock

function RunBlock:OnLoad()
	self:SetSize(RUN_ICON_SIZE + RUN_INFO_GAP + RUN_INFO_WIDTH, RUN_ICON_SIZE)

	self.icon = Dashboard.NewIcon(self, "Frame", RUN_ICON_SIZE, RUN_ICON_CORNER)
	self.icon:SetPoint("TOPLEFT")
	self.icon:SetMouseMotionEnabled(true)
	self.icon:SetScript("OnEnter", function()
		self:ShowTooltip()
	end)
	self.icon:SetScript("OnLeave", GameTooltip_Hide)

	local info = CreateFrame("Frame", nil, self)

	info:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", RUN_INFO_GAP, 0)
	info:SetPoint("BOTTOMRIGHT")

	self.level = Parts.CreateText(info, "GameFontNormal", RUN_TEXT_SIZE)
	self.level:SetPoint("TOPLEFT")

	self.abbrev = Parts.CreateText(info, "GameFontHighlight", RUN_TEXT_SIZE)
	self.abbrev:SetPoint("BOTTOMLEFT")

	self.time = Parts.CreateText(info, "GameFontHighlight", RUN_TEXT_SIZE)
	self.time:SetPoint("BOTTOMRIGHT")

	self.stars = Parts.NewStarRow(info)
	-- Centred on the level's line, not hung from the corner.
	self.stars:SetPoint("TOPRIGHT", 0, -(RUN_TEXT_SIZE - STAR_SIZE) / 2)

	self:SetRun(nil)
end

---@param run AMTDashboardRunSummary? nil when there is no run to show
function RunBlock:SetRun(run)
	self.run = run

	if not run then
		self.icon:SetIcon(nil)
		self.level:SetText(UNPLAYED)
		self.level:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
		self.abbrev:SetText("")
		self.time:SetText(UNPLAYED)
		self.time:SetTextColor(TIMED_COLOR:GetRGB())
		self.stars:SetEarned(0)

		return
	end

	local timeColor = run.chests == 0 and RED_FONT_COLOR or TIMED_COLOR

	self.icon:SetIcon(run.texture)
	self.level:SetText(tostring(run.level))
	self.level:SetTextColor(C_ChallengeMode.GetKeystoneLevelRarityColor(run.level):GetRGB())
	self.abbrev:SetText(run.abbrev)
	self.time:SetText(AMT.Util.FormatTime(run.seconds))
	self.time:SetTextColor(timeColor:GetRGB())
	self.stars:SetEarned(run.chests)
end

-- Mirroring Blizzards own tooltip for dungeons
function RunBlock:ShowTooltip()
	local run = self.run

	if not run then
		return
	end

	local duration = AMT.Util.FormatTime(run.seconds)

	GameTooltip:SetOwner(self.icon, "ANCHOR_RIGHT")
	GameTooltip:SetText(run.name, HIGHLIGHT_FONT_COLOR:GetRGB())
	GameTooltip_AddColoredLine(GameTooltip, MYTHIC_PLUS_POWER_LEVEL:format(run.level), HIGHLIGHT_FONT_COLOR)

	if run.chests == 0 then
		GameTooltip_AddColoredLine(GameTooltip, DUNGEON_SCORE_OVERTIME_TIME:format(duration), LIGHTGRAY_FONT_COLOR)
	else
		GameTooltip_AddColoredLine(GameTooltip, duration, HIGHLIGHT_FONT_COLOR)
	end

	GameTooltip:Show()
end

---@param parent Frame
---@return AMTDashboardRunBlockMixin
function Parts.NewRunBlock(parent)
	local block = CreateFrame("Frame", nil, parent)

	Mixin(block, RunBlock)
	block:OnLoad()

	return block
end
