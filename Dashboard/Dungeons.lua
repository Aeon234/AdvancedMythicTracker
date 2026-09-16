local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local PADDING = 8
local HEADINGS_Y = -30
local HEADING_SIZE = 11
local HEADING_RULE_Y = -44
local ROWS_Y = -46
local ROW_COUNT = 8

local ROW_ICON_SIZE = 24
local ROW_ICON_CORNER = 10
local ICON_TEXT_GAP = 8
local ROW_TEXT_SIZE = 13
local SCORE_SIZE = 14
local SCORE_X = 125
local BEST_X = 182
local TIME_X = 245
local UNPLAYED = "-"
local ABBREV_SCORE_GAP = 26

local UNLEARNED_ALPHA = 0.5
local TELEPORT_TICK_SECONDS = 1

---@param left AMTDashboardSeasonDungeon
---@param right AMTDashboardSeasonDungeon
---@return boolean
local function ByScore(left, right)
	if left.score ~= right.score then
		return left.score > right.score
	end

	return strcmputf8i(left.name, right.name) < 0
end

---@param parent Frame
---@param text string
---@param centreX number? nil to left-align
local function CreateHeading(parent, text, centreX)
	local heading = Parts.CreateSubduedText(parent, HEADING_SIZE)

	if centreX then
		heading:SetPoint("TOP", parent, "TOPLEFT", centreX, HEADINGS_Y)
	else
		heading:SetPoint("TOPLEFT", PADDING, HEADINGS_Y)
	end

	heading:SetText(text)
end

---@param row Frame
---@param template "GameFontNormal"|"GameFontHighlight"
---@param size number
---@param centreX number
---@return FontString
local function CreateColumnText(row, template, size, centreX)
	local text = Parts.CreateText(row, template, size)

	text:SetPoint("CENTER", row, "LEFT", centreX, 0)

	return text
end

---@class AMTDashboardDungeonRow
---@field frame Frame
---@field icon AMTDashboardIconMixin
---@field abbrev FontString
---@field score FontString
---@field best FontString
---@field time FontString
---@field dungeon AMTDashboardSeasonDungeon?
---@field cooldown number? seconds
---@field cooldownKnown boolean
local Row = {}
Row.__index = Row

---@param parent Frame
---@param previous AMTDashboardDungeonRow?
---@param withRule boolean
---@return AMTDashboardDungeonRow
function Row.New(parent, previous, withRule)
	local frame = CreateFrame("Frame", nil, parent)

	if previous then
		frame:SetPoint("TOPLEFT", previous.frame, "BOTTOMLEFT")
		frame:SetPoint("TOPRIGHT", previous.frame, "BOTTOMRIGHT")
	else
		frame:SetPoint("TOPLEFT", 0, ROWS_Y)
		frame:SetPoint("TOPRIGHT", 0, ROWS_Y)
	end

	local icon = Dashboard.NewIcon(frame, "Action", ROW_ICON_SIZE, ROW_ICON_CORNER)

	icon:SetPoint("LEFT", PADDING, 0)

	local abbrev = Parts.CreateText(frame, "GameFontHighlight", ROW_TEXT_SIZE)

	abbrev:SetPoint("LEFT", icon, "RIGHT", ICON_TEXT_GAP, 0)
	abbrev:SetPoint("RIGHT", frame, "LEFT", SCORE_X - ABBREV_SCORE_GAP, 0)
	abbrev:SetJustifyH("LEFT")
	abbrev:SetWordWrap(false)

	if withRule then
		local rule = Parts.CreateRule(frame)

		rule:SetPoint("BOTTOMLEFT", PADDING, 0)
		rule:SetPoint("BOTTOMRIGHT", -PADDING, 0)
	end

	local row = setmetatable({
		frame = frame,
		icon = icon,
		abbrev = abbrev,
		score = CreateColumnText(frame, "GameFontNormal", SCORE_SIZE, SCORE_X),
		best = CreateColumnText(frame, "GameFontHighlight", ROW_TEXT_SIZE, BEST_X),
		time = CreateColumnText(frame, "GameFontHighlight", ROW_TEXT_SIZE, TIME_X),
	}, Row)

	local function OnEnter()
		if not GameTooltip:IsOwned(frame) then
			row:ShowTooltip()
		end
	end

	local function OnLeave()
		if not frame:IsMouseOver() then
			GameTooltip_Hide()
		end
	end

	frame:SetMouseMotionEnabled(true)
	frame:SetScript("OnEnter", OnEnter)
	frame:SetScript("OnLeave", OnLeave)
	icon:SetScript("OnEnter", OnEnter)
	icon:SetScript("OnLeave", OnLeave)

	row:SetDungeon(nil)

	return row
end

---@param dungeon AMTDashboardSeasonDungeon? nil for a row with no dungeon to show
function Row:SetDungeon(dungeon)
	self.dungeon = dungeon

	if dungeon and dungeon.teleportKnown and dungeon.teleportSpellID then
		self.icon:SetSpell(dungeon.teleportSpellID)
	else
		self.icon:ClearSpell()
	end

	if not dungeon then
		self.icon:SetIcon(nil)
		self.abbrev:SetText(UNPLAYED)
		self.score:SetText(UNPLAYED)
		self.score:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		self.best:SetText(UNPLAYED)
		self.time:SetText(UNPLAYED)
		self.time:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())

		return
	end

	self.icon:SetIcon(dungeon.texture)
	self.abbrev:SetText(dungeon.abbrev)

	if dungeon.score <= 0 then
		self.score:SetText(UNPLAYED)
		self.score:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())
		self.best:SetText(UNPLAYED)
		self.time:SetText(UNPLAYED)
		self.time:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())

		return
	end

	local timeColor = dungeon.timed and HIGHLIGHT_FONT_COLOR or RED_FONT_COLOR

	self.score:SetText(tostring(dungeon.score))
	self.score:SetTextColor(C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(dungeon.score):GetRGB())
	self.best:SetText(("+%d"):format(dungeon.level))
	self.time:SetText(AMT.Util.FormatTime(dungeon.seconds))
	self.time:SetTextColor(timeColor:GetRGB())
end

---@param cooldown number? nil keeps the last state (for secret values)
function Row:SetCooldown(cooldown)
	if cooldown ~= nil then
		self.cooldown = cooldown
	end

	self.cooldownKnown = cooldown ~= nil

	local dungeon = self.dungeon
	local unlearned = dungeon ~= nil and not dungeon.teleportKnown
	local onCooldown = dungeon ~= nil and not unlearned and (self.cooldown or 0) > 0

	self.icon:SetIconDesaturated(unlearned or onCooldown)
	self.icon:SetAlpha(unlearned and UNLEARNED_ALPHA or 1)
end

function Row:AddTeleportLines()
	local dungeon = self.dungeon

	if not dungeon or not dungeon.teleportSpellID then
		return
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddHighlightLine(GameTooltip, dungeon.teleportName)

	if not dungeon.teleportKnown then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddErrorLine(
			GameTooltip,
			L["Time this dungeon at Mythic %d or higher to unlock its teleport."]:format(dungeon.teleportUnlockLevel)
		)

		return
	end

	local cooldown = self.cooldown

	if self.cooldownKnown and cooldown then
		if cooldown > 0 then
			GameTooltip_AddErrorLine(GameTooltip, SecondsToTime(cooldown))
		else
			GameTooltip_AddColoredLine(GameTooltip, READY, GREEN_FONT_COLOR)
		end
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddInstructionLine(GameTooltip, L["Click the dungeon icon to teleport."])
end

-- Blizzard's dungeon icon tooltip from the Mythic+ tab.
function Row:ShowTooltip()
	local dungeon = self.dungeon

	if not dungeon then
		return
	end

	GameTooltip:SetOwner(self.frame, "ANCHOR_RIGHT")
	GameTooltip:SetText(dungeon.name, HIGHLIGHT_FONT_COLOR:GetRGB())

	if dungeon.score > 0 then
		local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(dungeon.score)

		GameTooltip_AddNormalLine(
			GameTooltip,
			DUNGEON_SCORE_TOTAL_SCORE:format(color:WrapTextInColorCode(tostring(dungeon.score)))
		)
	end

	local fastest = dungeon.fastest

	if fastest then
		local duration = SecondsToClock(fastest.seconds, fastest.seconds >= SECONDS_PER_HOUR)

		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		GameTooltip_AddNormalLine(GameTooltip, LFG_LIST_BEST_RUN)
		GameTooltip_AddColoredLine(GameTooltip, MYTHIC_PLUS_POWER_LEVEL:format(fastest.level), HIGHLIGHT_FONT_COLOR)

		if fastest.overTime then
			GameTooltip_AddColoredLine(GameTooltip, DUNGEON_SCORE_OVERTIME_TIME:format(duration), LIGHTGRAY_FONT_COLOR)
		else
			GameTooltip_AddColoredLine(GameTooltip, duration, HIGHLIGHT_FONT_COLOR)
		end
	end

	self:AddTeleportLines()

	GameTooltip:Show()
end

---@class AMTDashboardDungeons
---@field header AMTDashboardPanelHeader
---@field rows AMTDashboardDungeonRow[]
local Dungeons = {}
Dashboard.Dungeons = Dungeons

---@param root AMTDashboardPanelRoot
function Dungeons:Build(root)
	local frame = root.dungeons

	self.header = Parts.NewPanelHeader(frame, PADDING)
	self.header:SetTitle(L["Season Dungeons"])

	CreateHeading(frame, LFG_TYPE_DUNGEON)
	CreateHeading(frame, L["Score"], SCORE_X)
	CreateHeading(frame, BEST, BEST_X)
	CreateHeading(frame, L["Time"], TIME_X)

	local rule = Parts.CreateRule(frame)

	rule:SetPoint("TOPLEFT", PADDING, HEADING_RULE_Y)
	rule:SetPoint("TOPRIGHT", -PADDING, HEADING_RULE_Y)

	self.rows = {}

	for index = 1, ROW_COUNT do
		self.rows[index] = Row.New(frame, self.rows[index - 1], index < ROW_COUNT)
	end

	frame:SetScript("OnSizeChanged", function(_, _, height)
		self:LayoutRows(height)
	end)
	self:LayoutRows(frame:GetHeight())

	root:RegisterShowTicker(TELEPORT_TICK_SECONDS, function()
		self:UpdateTeleports()
	end)
end

---@param height number
function Dungeons:LayoutRows(height)
	local rowHeight = (height + ROWS_Y) / ROW_COUNT

	if rowHeight <= 0 then
		return
	end

	for _, row in ipairs(self.rows) do
		row.frame:SetHeight(rowHeight)
	end
end

function Dungeons:UpdateTeleports()
	local cooldown = Dashboard.Source:GetTeleportCooldown()

	for _, row in ipairs(self.rows) do
		row:SetCooldown(cooldown)

		if GameTooltip:IsOwned(row.frame) then
			row:ShowTooltip()
		end
	end

	if cooldown and cooldown > 0 then
		self.header:SetNote(L["Teleports ready in %s"]:format(SecondsToTime(cooldown, false, false, 2)))
	else
		self.header:SetNote(nil)
	end
end

---@param dungeons AMTDashboardSeasonDungeon[]
function Dungeons:Refresh(dungeons)
	table.sort(dungeons, ByScore)

	for index, row in ipairs(self.rows) do
		row:SetDungeon(dungeons[index])
	end

	self:UpdateTeleports()
end
