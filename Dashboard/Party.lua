local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local PADDING = 10
local ROWS_Y = -30
local ROW_COUNT = 5
local PARTY_SIZE = 5
local ROW_TEXT_SIZE = 13
local ROW_ICON_SIZE = 22
local ROW_ICON_CORNER = 10
local ICON_TEXT_GAP = 8
local KEY_X = 150
local LEVEL_RIGHT = 18

local NOTE_SIZE = 13
local COUNT_FORMAT = "%d / %d"
local COUNT_ICON = [[Interface\AddOns\AdvancedMythicTracker\Media\Icons\PartyMembers]]
local COUNT_ICON_WIDTH, COUNT_ICON_HEIGHT = 24, 16
local COUNT_ICON_GAP = 4
local STAR_MARKUP = CreateAtlasMarkup("CampCollection-icon-star", 11, 11)

-- Known and highest first, ties and unknown by name.
---@param left AMTDashboardPartyMember
---@param right AMTDashboardPartyMember
---@return boolean
local function ByKeyLevel(left, right)
	local leftLevel = left.key and left.key.level or 0
	local rightLevel = right.key and right.key.level or 0

	if leftLevel ~= rightLevel then
		return leftLevel > rightLevel
	end

	return left.name < right.name
end

---@param members AMTDashboardPartyMember[]
---@return integer
local function CountKnownKeys(members)
	local count = 0

	for _, member in ipairs(members) do
		if member.key then
			count = count + 1
		end
	end

	return count
end

---@param left AMTDashboardPartyDungeon
---@param right AMTDashboardPartyDungeon
---@return boolean
local function ByDungeonName(left, right)
	return strcmputf8i(left.name, right.name) < 0
end

---@param dungeon AMTDashboardPartyDungeon
---@return string
local function FormatBest(dungeon)
	if dungeon.level <= 0 then
		return DUNGEON_SCORE_LINK_NO_SCORE
	end

	local level = DUNGEON_SCORE_LINK_TEXT2:format(dungeon.level)

	if dungeon.upgrades == 0 then
		return level
	end

	return STAR_MARKUP:rep(dungeon.upgrades) .. " " .. level
end

---@class AMTDashboardPartyRow
---@field frame Frame
---@field specIcon AMTDashboardIconMixin
---@field name FontString
---@field keyIcon AMTDashboardIconMixin
---@field abbrev FontString
---@field level FontString
---@field noKey FontString
---@field member AMTDashboardPartyMember?
local Row = {}
Row.__index = Row

---@param parent Frame
---@param previous AMTDashboardPartyRow?
---@param withRule boolean
---@return AMTDashboardPartyRow
function Row.New(parent, previous, withRule)
	local frame = CreateFrame("Frame", nil, parent)

	if previous then
		frame:SetPoint("TOPLEFT", previous.frame, "BOTTOMLEFT")
		frame:SetPoint("TOPRIGHT", previous.frame, "BOTTOMRIGHT")
	else
		frame:SetPoint("TOPLEFT", 0, ROWS_Y)
		frame:SetPoint("TOPRIGHT", 0, ROWS_Y)
	end

	local specIcon = Dashboard.NewIcon(frame, "Frame", ROW_ICON_SIZE, ROW_ICON_CORNER)

	specIcon:SetPoint("LEFT", PADDING, 0)

	local name = Parts.CreateText(frame, "GameFontHighlight", ROW_TEXT_SIZE)

	-- A long name truncates before the key column rather than running into it.
	name:SetPoint("LEFT", specIcon, "RIGHT", ICON_TEXT_GAP, 0)
	name:SetPoint("RIGHT", frame, "LEFT", KEY_X - ICON_TEXT_GAP, 0)
	name:SetJustifyH("LEFT")
	name:SetWordWrap(false)

	local keyIcon = Dashboard.NewIcon(frame, "Frame", ROW_ICON_SIZE, ROW_ICON_CORNER)

	keyIcon:SetPoint("LEFT", KEY_X, 0)

	local abbrev = Parts.CreateText(frame, "GameFontHighlight", ROW_TEXT_SIZE)

	abbrev:SetPoint("LEFT", keyIcon, "RIGHT", ICON_TEXT_GAP, 0)

	local level = Parts.CreateText(frame, "GameFontHighlight", ROW_TEXT_SIZE)

	level:SetPoint("RIGHT", -LEVEL_RIGHT, 0)

	local noKey = Parts.CreateSubduedText(frame, ROW_TEXT_SIZE)

	noKey:SetPoint("LEFT", KEY_X, 0)
	noKey:SetText(L["No Keystone"])

	if withRule then
		local rule = Parts.CreateRule(frame)

		rule:SetPoint("BOTTOMLEFT", PADDING, 0)
		rule:SetPoint("BOTTOMRIGHT", -PADDING, 0)
	end

	local row = setmetatable({
		frame = frame,
		specIcon = specIcon,
		name = name,
		keyIcon = keyIcon,
		abbrev = abbrev,
		level = level,
		noKey = noKey,
	}, Row)

	frame:SetMouseMotionEnabled(true)
	frame:SetScript("OnEnter", function()
		row:ShowTooltip()
	end)
	frame:SetScript("OnLeave", GameTooltip_Hide)

	row:SetMember(nil)

	return row
end

---@param member AMTDashboardPartyMember? nil for a blank row
function Row:SetMember(member)
	self.member = member

	local key = member and member.key

	self.specIcon:SetShown(member ~= nil)
	self.name:SetShown(member ~= nil)
	self.keyIcon:SetShown(key ~= nil)
	self.abbrev:SetShown(key ~= nil)
	self.level:SetShown(key ~= nil)
	self.noKey:SetShown(member ~= nil and key == nil)

	if not member then
		return
	end

	if member.specIcon then
		self.specIcon:SetIcon(member.specIcon)
	else
		self.specIcon:SetIconAtlas(GetClassAtlas(member.classFile))
	end

	self.name:SetText(member.name)
	self.name:SetTextColor(C_ClassColor.GetClassColor(member.classFile):GetRGB())

	if key then
		self.keyIcon:SetIcon(key.texture)
		self.abbrev:SetText(key.abbrev)
		self.level:SetText(("+%d"):format(key.level))
	end
end

function Row:ShowTooltip()
	local member = self.member

	if not member then
		return
	end

	GameTooltip:SetOwner(self.frame, "ANCHOR_TOP")
	GameTooltip_SetTitle(GameTooltip, member.name, C_ClassColor.GetClassColor(member.classFile))

	local key = member.key

	if key then
		GameTooltip_AddColoredDoubleLine(
			GameTooltip,
			CHALLENGE_MODE_KEYSTONE_NAME:format(key.name),
			DUNGEON_SCORE_LINK_TEXT2:format(key.level),
			NORMAL_FONT_COLOR,
			HIGHLIGHT_FONT_COLOR
		)
	end

	local rating = member.rating

	if rating then
		local color = C_ChallengeMode.GetDungeonScoreRarityColor(rating)

		GameTooltip_AddNormalLine(
			GameTooltip,
			DUNGEON_SCORE_LINK_RATING:format(color:WrapTextInColorCode(tostring(rating)))
		)
	end

	if #member.dungeons > 0 then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)

		for _, dungeon in ipairs(member.dungeons) do
			GameTooltip_AddColoredDoubleLine(
				GameTooltip,
				DUNGEON_SCORE_LINK_TEXT1:format(dungeon.name),
				FormatBest(dungeon),
				NORMAL_FONT_COLOR,
				dungeon.timed and HIGHLIGHT_FONT_COLOR or GRAY_FONT_COLOR
			)
		end
	end

	GameTooltip:Show()
end

---@class AMTDashboardParty
---@field header AMTDashboardPanelHeader
---@field countIcon Texture
---@field solo FontString
---@field rows AMTDashboardPartyRow[]
local Party = {}
Dashboard.Party = Party

---@param root AMTDashboardPanelRoot
function Party:Build(root)
	local frame = root.party

	self.header = Parts.NewPanelHeader(frame, PADDING)
	self.header:SetTitle(L["Party Keystones"])
	Parts.ResizeText(self.header.note, NOTE_SIZE)
	self.header.note:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGB())

	self.countIcon = frame:CreateTexture(nil, "ARTWORK")
	self.countIcon:SetTexture(COUNT_ICON)
	self.countIcon:SetSize(COUNT_ICON_WIDTH, COUNT_ICON_HEIGHT)
	self.countIcon:SetPoint("RIGHT", self.header.note, "LEFT", -COUNT_ICON_GAP, 0)

	self.rows = {}

	for index = 1, ROW_COUNT do
		self.rows[index] = Row.New(frame, self.rows[index - 1], index < ROW_COUNT)
	end

	-- Centred on the rows' area, below the title.
	self.solo = Parts.CreateSubduedText(frame, ROW_TEXT_SIZE)
	self.solo:SetPoint("CENTER", frame, "CENTER", 0, ROWS_Y / 2)
	self.solo:SetText(L["Not in a Group"])
	self.solo:Hide()

	-- The column's height comes from its anchors, which resolve after this runs.
	frame:SetScript("OnSizeChanged", function(_, _, height)
		self:LayoutRows(height)
	end)
	self:LayoutRows(frame:GetHeight())
end

---@param height number
function Party:LayoutRows(height)
	local rowHeight = (height + ROWS_Y) / ROW_COUNT

	if rowHeight <= 0 then
		return
	end

	for _, row in ipairs(self.rows) do
		row.frame:SetHeight(rowHeight)
	end
end

---@param roster AMTDashboardPartyRoster
function Party:Refresh(roster)
	local members = roster.members
	local solo = not roster.inGroup

	table.sort(members, ByKeyLevel)

	for _, member in ipairs(members) do
		table.sort(member.dungeons, ByDungeonName)
	end

	for index, row in ipairs(self.rows) do
		if solo then
			row:SetMember(nil)
		else
			row:SetMember(members[index])
		end
	end

	self.solo:SetShown(solo)
	self.countIcon:SetShown(not solo)

	if solo then
		self.header:SetNote(nil)
	else
		self.header:SetNote(COUNT_FORMAT:format(CountKnownKeys(members), PARTY_SIZE))
	end
end
