local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local TITLE_SIZE = 12
local TITLE_BASELINE = 10
local VALUE_GAP = 2
local ICON_GAP = 4
local UNPLAYED = "-"

local KEYSTONE_ICON_SIZE = 40
local KEYSTONE_ICON_CORNER = 16
local KEYSTONE_CENTRE_GAP = 5
local KEYSTONE_LEVEL_SIZE = 20
local KEYSTONE_ABBREV_SIZE = 16
local KEYSTONE_ABBREV_GREY = 0.8
local NO_KEYSTONE_TEXTURE = 4352494
local PERCENT_INCREASE = "+%d%%"

local RATING_SIZE = 30

local AFFIX_ICON_SIZE = 30
local AFFIX_ICON_CORNER = 16
local AFFIX_SPACING = 8

local COPY_URL_DIALOG = "ADVANCEDMYTHICTRACKER_COPY_URL"

StaticPopupDialogs[COPY_URL_DIALOG] = {
	text = L["Copy this link to open your Raider.IO profile."],
	button1 = CLOSE,
	hasEditBox = true,
	editBoxWidth = 260,
	OnShow = function(dialog, url)
		local editBox = dialog:GetEditBox()

		editBox:SetText(url)
		editBox:SetFocus()
		editBox:HighlightText()
	end,
	EditBoxOnTextChanged = function(editBox, url)
		if editBox:IsVisible() and editBox:GetText() ~= url then
			editBox:SetText(url)
			editBox:HighlightText()
		end
	end,
	EditBoxOnEnterPressed = function(editBox)
		editBox:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
	hideOnEscape = true,
	whileDead = true,
	timeout = 0,
}

---@class AMTDashboardBand
---@field keystoneIcon AMTDashboardIconMixin
---@field keystoneLevel FontString
---@field keystoneAbbrev FontString
---@field rating FontString
---@field weeklyBest AMTDashboardRunBlockMixin
---@field seasonBest AMTDashboardRunBlockMixin
---@field affixRow Frame
---@field affixIcons AMTDashboardIconMixin[]
---@field affixes AMTDashboardAffix[]
---@field raiderIOURL string?
---@field keystone AMTDashboardKeystone?
local Band = {}
Dashboard.Band = Band

---@param section Frame
---@param text string
---@return FontString
local function CreateSectionTitle(section, text)
	local title = Parts.CreateText(section, "GameFontNormal", TITLE_SIZE)

	title:SetPoint("BOTTOM", section, "CENTER", 0, TITLE_BASELINE)
	title:SetText(text)

	return title
end

---@param section Frame
---@param text string
---@return AMTDashboardRunBlockMixin
local function CreateBestRun(section, text)
	local block = Parts.NewRunBlock(section)

	block:SetPoint("TOP", section, "CENTER", 0, TITLE_BASELINE - ICON_GAP)

	local title = Parts.CreateText(section, "GameFontNormal", TITLE_SIZE)

	title:SetPoint("BOTTOMLEFT", block, "TOPLEFT", 0, ICON_GAP)
	title:SetText(text)

	return block
end

---@param heading string
---@param health integer
---@param damage integer
local function AddModifierLines(heading, health, damage)
	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddNormalLine(GameTooltip, heading)
	GameTooltip_AddColoredDoubleLine(
		GameTooltip,
		HEALTH,
		PERCENT_INCREASE:format(health),
		HIGHLIGHT_FONT_COLOR,
		HIGHLIGHT_FONT_COLOR
	)
	GameTooltip_AddColoredDoubleLine(
		GameTooltip,
		DAMAGE,
		PERCENT_INCREASE:format(damage),
		HIGHLIGHT_FONT_COLOR,
		HIGHLIGHT_FONT_COLOR
	)
end

---@param label string
---@param itemLevel number?
local function AddRewardLine(label, itemLevel)
	if not itemLevel then
		return
	end

	GameTooltip_AddColoredDoubleLine(
		GameTooltip,
		label,
		ITEM_LEVEL:format(itemLevel),
		NORMAL_FONT_COLOR,
		HIGHLIGHT_FONT_COLOR
	)
end

---@param sections Frame[] the band's five sections, left to right
function Band:Build(sections)
	self:BuildKeystone(sections[1])
	self:BuildRating(sections[2])
	self.weeklyBest = CreateBestRun(sections[3], MYTHIC_PLUS_WEEKLY_BEST)
	self.seasonBest = CreateBestRun(sections[4], MYTHIC_PLUS_SEASON_BEST)
	self:BuildAffixes(sections[5])
end

---@param section Frame
function Band:BuildKeystone(section)
	self.keystoneIcon = Dashboard.NewIcon(section, "Frame", KEYSTONE_ICON_SIZE, KEYSTONE_ICON_CORNER)
	self.keystoneIcon:SetPoint("RIGHT", section, "CENTER", -KEYSTONE_CENTRE_GAP, 0)

	self.keystoneIcon:SetMouseMotionEnabled(true)
	self.keystoneIcon:SetScript("OnEnter", function()
		self:ShowKeystoneTooltip()
	end)
	self.keystoneIcon:SetScript("OnLeave", GameTooltip_Hide)

	self.keystoneLevel = Parts.CreateText(section, "GameFontHighlight", KEYSTONE_LEVEL_SIZE)
	-- self.keystoneLevel:SetPoint("BOTTOMLEFT", section, "CENTER", KEYSTONE_CENTRE_GAP, -KEYSTONE_LEVEL_DROP)
	self.keystoneLevel:SetPoint("TOPLEFT", self.keystoneIcon, "TOPRIGHT", KEYSTONE_CENTRE_GAP, 0)

	self.keystoneAbbrev = Parts.CreateText(section, "GameFontHighlight", KEYSTONE_ABBREV_SIZE)
	-- self.keystoneAbbrev:SetPoint("TOPLEFT", self.keystoneLevel, "BOTTOMLEFT", 0, -KEYSTONE_ABBREV_GAP)
	self.keystoneAbbrev:SetPoint("BOTTOMLEFT", self.keystoneIcon, "BOTTOMRIGHT", KEYSTONE_CENTRE_GAP, 0)
	self.keystoneAbbrev:SetTextColor(KEYSTONE_ABBREV_GREY, KEYSTONE_ABBREV_GREY, KEYSTONE_ABBREV_GREY)
end

function Band:ShowKeystoneTooltip()
	local keystone = self.keystone

	if not keystone then
		return
	end

	local modifiers = keystone.modifiers

	GameTooltip:SetOwner(self.keystoneIcon, "ANCHOR_RIGHT")
	GameTooltip:SetText(keystone.name, HIGHLIGHT_FONT_COLOR:GetRGB())
	GameTooltip_AddColoredLine(GameTooltip, MYTHIC_PLUS_POWER_LEVEL:format(keystone.level), HIGHLIGHT_FONT_COLOR)

	AddModifierLines(BOSS, modifiers.bossHealth, modifiers.bossDamage)
	AddModifierLines(UNIT_NAME_ENEMY_MINIONS, modifiers.minionHealth, modifiers.minionDamage)

	if keystone.lootItemLevel or keystone.vaultItemLevel then
		GameTooltip_AddBlankLineToTooltip(GameTooltip)
		AddRewardLine(LOOT_NOUN, keystone.lootItemLevel)
		AddRewardLine(L["Great Vault"], keystone.vaultItemLevel)
	end

	GameTooltip:Show()
end

---@param section Frame
function Band:BuildRating(section)
	local button = CreateFrame("Button", nil, section)

	button:SetAllPoints()
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnEnter", function()
		self:ShowRatingTooltip(button)
	end)
	button:SetScript("OnLeave", GameTooltip_Hide)
	button:SetScript("OnClick", function(_, mouseButton)
		self:OnRatingClick(mouseButton)
	end)

	local title = CreateSectionTitle(button, DUNGEON_SCORE)

	self.rating = Parts.CreateText(button, "GameFontNormal", RATING_SIZE)
	self.rating:SetPoint("TOP", title, "BOTTOM", 0, -VALUE_GAP)
end

-- Blizzard's own tooltip from Mythic+ tab.
---@param owner Button
function Band:ShowRatingTooltip(owner)
	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip_SetTitle(GameTooltip, DUNGEON_SCORE)
	GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_DESC)

	if self.raiderIOURL then
		GameTooltip_AddInstructionLine(GameTooltip, L["<Right Click for Raider.IO Link>"])
	end

	GameTooltip:Show()
end

---@param mouseButton string
function Band:OnRatingClick(mouseButton)
	if mouseButton == "RightButton" then
		if self.raiderIOURL then
			StaticPopup_Show(COPY_URL_DIALOG, nil, nil, self.raiderIOURL)
		end

		return
	end

	-- Built at click time from the live score, as Blizzard's own rating does.
	if IsModifiedClick("CHATLINK") then
		local link = GetDungeonScoreLink(C_ChallengeMode.GetOverallDungeonScore(), UnitName("player"))

		if not ChatFrameUtil.InsertLink(link) then
			ChatFrameUtil.OpenChat(link)
		end
	end
end

---@param section Frame
function Band:BuildAffixes(section)
	local title = CreateSectionTitle(section, L["Current Affixes"])

	self.affixRow = CreateFrame("Frame", nil, section)
	self.affixRow:SetPoint("TOP", title, "BOTTOM", 0, -ICON_GAP)
	self.affixRow:SetHeight(AFFIX_ICON_SIZE)

	self.affixIcons = {}
	self.affixes = {}
end

---@param index integer
function Band:CreateAffixIcon(index)
	local icon = Dashboard.NewIcon(self.affixRow, "Frame", AFFIX_ICON_SIZE, AFFIX_ICON_CORNER)

	icon:SetPoint("LEFT", (index - 1) * (AFFIX_ICON_SIZE + AFFIX_SPACING), 0)
	icon:SetMouseMotionEnabled(true)
	icon:SetScript("OnEnter", function()
		self:ShowAffixTooltip(icon, index)
	end)
	icon:SetScript("OnLeave", GameTooltip_Hide)

	self.affixIcons[index] = icon
end

---@param icon AMTDashboardIconMixin
---@param index integer
function Band:ShowAffixTooltip(icon, index)
	local affix = self.affixes[index]

	if not affix then
		return
	end

	GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
	GameTooltip_SetTitle(GameTooltip, affix.name)
	GameTooltip_AddNormalLine(GameTooltip, affix.description)
	GameTooltip:Show()
end

---@param header AMTDashboardHeader
function Band:Refresh(header)
	self.raiderIOURL = header.raiderIOURL
	self:RefreshKeystone(header.keystone)
	self:RefreshRating(header.rating)
	self.weeklyBest:SetRun(header.weeklyBest)
	self.seasonBest:SetRun(header.seasonBest)
	self:RefreshAffixes(header.affixes)
end

---@param keystone AMTDashboardKeystone?
function Band:RefreshKeystone(keystone)
	self.keystone = keystone
	local icon = self.keystoneIcon

	if not keystone then
		icon:SetIcon(NO_KEYSTONE_TEXTURE)
		icon:SetIconDesaturated(true)
		self.keystoneLevel:SetText(UNPLAYED)
		self.keystoneAbbrev:SetText(UNPLAYED)

		return
	end

	icon:SetIcon(keystone.texture)
	icon:SetIconDesaturated(false)
	self.keystoneLevel:SetText(("+%d"):format(keystone.level))
	self.keystoneAbbrev:SetText(keystone.abbrev)
end

---@param rating number
function Band:RefreshRating(rating)
	self.rating:SetText(tostring(rating))
	self.rating:SetTextColor(C_ChallengeMode.GetDungeonScoreRarityColor(rating):GetRGB())
end

---@param affixes AMTDashboardAffix[]
function Band:RefreshAffixes(affixes)
	local count = #affixes

	self.affixes = affixes

	for index = #self.affixIcons + 1, count do
		self:CreateAffixIcon(index)
	end

	for index, icon in ipairs(self.affixIcons) do
		local affix = affixes[index]

		if affix then
			icon:SetIcon(affix.texture)
		end

		icon:SetShown(affix ~= nil)
	end

	self.affixRow:SetWidth(math.max(count * AFFIX_ICON_SIZE + (count - 1) * AFFIX_SPACING, 1))
end
