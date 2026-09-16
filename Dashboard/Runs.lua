local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local TITLE_PADDING = 5
local LIST_PADDING = 10
local LIST_Y = -30
local SCROLLBAR_GAP = 4

local CARD_HEIGHT = 56
local CARD_CORNER = 10
local CARD_BLEED = CARD_CORNER / 2
local CARD_SPACING = CARD_CORNER
local CARD_INSET = 8
local CARD_ICON_SIZE = 36
local CARD_ICON_CORNER = 16
local CARD_TEXT_SIZE = 14
local SCORE_SIZE = 16
local WHEN_SIZE = 11
local MIDDLE_X = 100
local TIME_X = 190

local STAR_ATLAS = "CampCollection-icon-star"
local STAR_SIZE, STAR_SPACING = 11, 1
local MAX_STARS = 3
local UNEARNED_STAR_ALPHA = 0.5

local PARTY_SIZE = 5
local CLASS_ICON_SIZE = 14
local CLASS_ICON_SPACING = 2
local CROP_MIN, CROP_MAX = 0.07, 0.93

local TIMED_COLOR = CreateColor(0.69, 0.69, 0.69)
local MILLISECONDS_PER_SECOND = 1000

---@param completedAt number
---@return string
local function FormatDay(completedAt)
	local run = date("*t", completedAt)
	local today = date("*t")

	if run.yday == today.yday and run.year == today.year then
		return L["Today"]
	end

	return CALENDAR_WEEKDAY_NAMES[run.wday]
end

---@class AMTDashboardRunCard : Frame
---@field background AMTBorder?
---@field highlight AMTBorder?
---@field icon AMTDashboardIconMixin
---@field abbrev FontString
---@field level FontString
---@field stars Texture[]
---@field party Texture[]
---@field unrecorded FontString
---@field time FontString
---@field score FontString
---@field when FontString
---@field run AMTDashboardRun?
local Card = {}

function Card:OnLoad()
	self.background = AMT.NineSlice.Apply(self, "Inset", CARD_CORNER)
	self.highlight = AMT.NineSlice.Apply(self, "Hover", CARD_CORNER, "OVERLAY")

	if self.highlight then
		self.highlight:SetShown(false)
	end

	Dashboard.Skin:Register(self, "Inset")
	Dashboard.Skin:Register(self, "Hover")

	self:SetMouseMotionEnabled(true)
	self:SetScript("OnEnter", function()
		self:SetHighlighted(true)
		self:ShowTooltip()
	end)
	self:SetScript("OnLeave", function()
		self:SetHighlighted(false)
		GameTooltip_Hide()
	end)

	self.icon = Dashboard.NewIcon(self, "Frame", CARD_ICON_SIZE, CARD_ICON_CORNER)
	self.icon:SetPoint("LEFT", CARD_INSET, 0)

	self.abbrev = Parts.CreateText(self, "GameFontHighlight", CARD_TEXT_SIZE)
	self.abbrev:SetPoint("TOPLEFT", self.icon, "TOPRIGHT", CARD_INSET, -1)

	self.level = Parts.CreateText(self, "GameFontNormal", CARD_TEXT_SIZE)
	self.level:SetPoint("BOTTOMLEFT", self.icon, "BOTTOMRIGHT", CARD_INSET, 1)

	self.stars = {}

	for index = 1, MAX_STARS do
		local star = self:CreateTexture(nil, "ARTWORK")

		star:SetAtlas(STAR_ATLAS)
		star:SetSize(STAR_SIZE, STAR_SIZE)
		star:SetPoint("TOPLEFT", MIDDLE_X + (index - 1) * (STAR_SIZE + STAR_SPACING), -CARD_INSET)

		self.stars[index] = star
	end

	self.party = {}

	for index = 1, PARTY_SIZE do
		local member = self:CreateTexture(nil, "ARTWORK")

		member:SetSize(CLASS_ICON_SIZE, CLASS_ICON_SIZE)
		member:SetPoint("BOTTOMLEFT", MIDDLE_X + (index - 1) * (CLASS_ICON_SIZE + CLASS_ICON_SPACING), CARD_INSET)

		self.party[index] = member
	end

	self.unrecorded = Parts.CreateSubduedText(self, WHEN_SIZE)
	self.unrecorded:SetPoint("BOTTOMLEFT", MIDDLE_X, CARD_INSET)
	self.unrecorded:SetText(L["Non-AMT recorded run"])

	self.time = Parts.CreateText(self, "GameFontHighlight", CARD_TEXT_SIZE)
	self.time:SetPoint("TOPLEFT", TIME_X, -CARD_INSET)

	self.score = Parts.CreateText(self, "GameFontNormal", SCORE_SIZE)
	self.score:SetPoint("TOPRIGHT", -CARD_INSET, -CARD_INSET)

	self.when = Parts.CreateSubduedText(self, WHEN_SIZE)
	self.when:SetPoint("BOTTOMRIGHT", -CARD_INSET, CARD_INSET)
end

---@param highlighted boolean
function Card:SetHighlighted(highlighted)
	if self.highlight then
		self.highlight:SetShown(highlighted)
	end
end

---@param run AMTDashboardRun
function Card:SetRun(run)
	self.run = run

	self.icon:SetIcon(run.texture)
	self.abbrev:SetText(run.abbrev)
	self.level:SetText(("+%d"):format(run.level))
	self.level:SetTextColor(C_ChallengeMode.GetKeystoneLevelRarityColor(run.level):GetRGB())

	for index, star in ipairs(self.stars) do
		local lit = index <= run.chests

		star:SetDesaturated(not lit)
		star:SetAlpha(lit and 1 or UNEARNED_STAR_ALPHA)
	end

	for index, member in ipairs(self.party) do
		local recorded = run.party and run.party[index]

		if recorded then
			if recorded.specIcon then
				member:SetTexture(recorded.specIcon)
				member:SetTexCoord(CROP_MIN, CROP_MAX, CROP_MIN, CROP_MAX)
			else
				member:SetAtlas(GetClassAtlas(recorded.classFile))
			end
		end

		member:SetShown(recorded ~= nil)
	end

	self.unrecorded:SetShown(run.party == nil)

	self.time:SetText(AMT.Util.FormatTime(run.seconds))
	self.time:SetTextColor((run.chests == 0 and RED_FONT_COLOR or TIMED_COLOR):GetRGB())

	self.score:SetText(tostring(run.score))
	self.score:SetTextColor(C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(run.score):GetRGB())

	self.when:SetText(FormatDay(run.completedAt))

	self:SetHighlighted(false)
end

---@param splits AMTDashboardRunSplit[]
function Card:AddSplitLines(splits)
	if #splits == 0 then
		return
	end

	local settings = AMT.Profiles.active.timer.splits

	GameTooltip_AddBlankLineToTooltip(GameTooltip)

	for _, split in ipairs(splits) do
		local elapsed = AMT.Util.FormatTime(split.timeMS / MILLISECONDS_PER_SECOND)

		if split.diffMS then
			local colour = AMT.Util.SplitColor(settings, AMT.Splits.Classify(split.diffMS))
			local difference = AMT.Util.FormatTime(split.diffMS / MILLISECONDS_PER_SECOND, settings.decimals, true)

			elapsed = ("%s %s"):format(
				elapsed,
				CreateColor(colour[1], colour[2], colour[3]):WrapTextInColorCode(difference)
			)
		end

		GameTooltip_AddColoredDoubleLine(GameTooltip, split.name, elapsed, NORMAL_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
	end
end

function Card:ShowTooltip()
	local run = self.run

	if not run then
		return
	end

	local result = run.chests == 0 and L["Depleted"]
		or L["Timed +%d in %s"]:format(run.chests, AMT.Util.FormatTime(run.seconds))

	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(run.name, HIGHLIGHT_FONT_COLOR:GetRGB())
	GameTooltip_AddColoredLine(GameTooltip, MYTHIC_PLUS_POWER_LEVEL:format(run.level), HIGHLIGHT_FONT_COLOR)
	GameTooltip_AddNormalLine(GameTooltip, result)
	GameTooltip_AddNormalLine(
		GameTooltip,
		DUNGEON_SCORE_TOTAL_SCORE:format(
			C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(run.score)
				:WrapTextInColorCode(tostring(run.score))
		)
	)
	GameTooltip_AddDisabledLine(GameTooltip, FormatDay(run.completedAt))

	if run.splits then
		self:AddSplitLines(run.splits)
	end

	GameTooltip:Show()
end

---@class AMTDashboardRuns
---@field scrollBox Frame
---@field empty FontString
local Runs = {}
Dashboard.Runs = Runs

---@param root AMTDashboardPanelRoot
function Runs:Build(root)
	local frame = root.runs
	local header = Parts.NewPanelHeader(frame, TITLE_PADDING)

	header:SetTitle(L["This Week's Runs"])

	local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

	scrollBar:SetPoint("TOPRIGHT", -LIST_PADDING, LIST_Y)
	scrollBar:SetPoint("BOTTOMRIGHT", -LIST_PADDING, CARD_BLEED)
	Dashboard.Skin:Register(scrollBar, "scrollbar")

	local scrollBox = CreateFrame("Frame", nil, frame, "WowScrollBoxList")

	scrollBox:SetPoint("TOPLEFT", 0, LIST_Y)
	scrollBox:SetPoint("BOTTOMRIGHT", scrollBar, "BOTTOMLEFT", -SCROLLBAR_GAP, 0)

	local view = CreateScrollBoxListLinearView(CARD_BLEED, CARD_BLEED, CARD_BLEED, CARD_BLEED, CARD_SPACING)

	view:SetElementExtent(CARD_HEIGHT)
	view:SetElementInitializer("Frame", function(card, run)
		if not card.icon then
			Mixin(card, Card)
			card:OnLoad()
		end

		card:SetRun(run)
	end)

	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

	self.scrollBox = scrollBox

	self.empty = Parts.CreateSubduedText(frame, CARD_TEXT_SIZE)
	self.empty:SetPoint("CENTER", frame, "CENTER", 0, LIST_Y / 2)
	self.empty:SetText(L["No runs recorded yet"])
	self.empty:Hide()
end

---@param runs AMTDashboardRun[]
function Runs:Refresh(runs)
	self.scrollBox:SetDataProvider(CreateDataProvider(runs))
	self.empty:SetShown(#runs == 0)
end
