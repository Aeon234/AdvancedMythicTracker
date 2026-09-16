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

local PULSE_ATLAS = "evergreen-weeklyrewards-reward-coin-selected"
local PULSE_OUTSET_X = 11
local PULSE_OUTSET_Y = 8
local PULSE_PEAK_ALPHA = 0.5
local PULSE_HALF_SECONDS = 1

local RESET_TICK_SECONDS = 60
local SECONDS_PER_DAY = 86400
local SECONDS_PER_HOUR = 3600
local SECONDS_PER_MINUTE = 60

local UNLOCK_DESCRIPTIONS = {
	GREAT_VAULT_REWARDS_MYTHIC_INCOMPLETE,
	GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_FIRST,
	GREAT_VAULT_REWARDS_MYTHIC_COMPLETED_SECOND,
}

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
---@field frame Button
---@field value FontString
---@field unit FontString
local Milestone = {}
Milestone.__index = Milestone

---@param parent Frame
---@param pipWidth number
---@return AMTDashboardVaultMilestoneView
function Milestone.New(parent, pipWidth)
	local frame = CreateFrame("Button", nil, parent)

	frame:SetSize(pipWidth + PIP_GAP, MILESTONE_HEIGHT)
	frame:SetScript("OnClick", WeeklyRewards_ShowUI)
	frame:Hide()

	local value = Parts.CreateText(frame, "GameFontNormal", MILESTONE_VALUE_SIZE)

	value:SetPoint("TOP")

	local unit = Parts.CreateSubduedText(frame, MILESTONE_UNIT_SIZE)

	unit:SetPoint("TOP", value, "BOTTOM", 0, -MILESTONE_UNIT_GAP)

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
---@field track AMTDashboardVaultTrack?
---@field pulse Texture
---@field pulseAnimation AnimationGroup
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

	self:CreatePulse(frame)

	self.milestones = {}

	for index = 1, MILESTONE_COUNT do
		local view = Milestone.New(frame, pipWidth)

		view.frame:SetScript("OnEnter", function()
			self:ShowMilestoneTooltip(index)
		end)
		view.frame:SetScript("OnLeave", GameTooltip_Hide)

		self.milestones[index] = view
	end

	local rule = Parts.CreateRule(frame)

	rule:SetPoint("BOTTOMLEFT", PADDING, 0)
	rule:SetPoint("BOTTOMRIGHT", -PADDING, 0)

	frame:SetHeight(-TRACK_Y + PIP_HEIGHT + MILESTONE_GAP + MILESTONE_HEIGHT + BOTTOM_PADDING)

	root:RegisterShowTicker(RESET_TICK_SECONDS, function()
		self:UpdateNote()
	end)

	root:RegisterShowEvent("WEEKLY_REWARDS_UPDATE", function()
		self:Refresh(Dashboard.Source:GetVault())
	end)

	root:RegisterShowEvent("ITEM_DATA_LOAD_RESULT", function()
		if self:HasPendingItemLevel() then
			self:Refresh(Dashboard.Source:GetVault())
		end
	end)
end

function Vault:UpdateNote()
	if self.track and self.track.rewardsWaiting then
		self.header:SetNote(MYTHIC_PLUS_COLLECT_GREAT_VAULT)

		return
	end

	self.header:SetNote(FormatReset(Dashboard.Source:GetSecondsUntilWeeklyReset()))
end

---@param parent Frame
function Vault:CreatePulse(parent)
	local host = CreateFrame("Frame", nil, parent)

	host:SetAllPoints()

	local pulse = host:CreateTexture(nil, "OVERLAY")

	pulse:SetAtlas(PULSE_ATLAS)
	pulse:SetPoint("TOPLEFT", self.pips[1].frame, "TOPLEFT", -PULSE_OUTSET_X, PULSE_OUTSET_Y)
	pulse:SetPoint("BOTTOMRIGHT", self.pips[PIP_COUNT].frame, "BOTTOMRIGHT", PULSE_OUTSET_X, -PULSE_OUTSET_Y)
	pulse:SetAlpha(0)
	pulse:Hide()

	local animation = pulse:CreateAnimationGroup()

	animation:SetLooping("REPEAT")

	local fadeIn = animation:CreateAnimation("Alpha")

	fadeIn:SetFromAlpha(0)
	fadeIn:SetToAlpha(PULSE_PEAK_ALPHA)
	fadeIn:SetDuration(PULSE_HALF_SECONDS)
	fadeIn:SetOrder(1)

	local fadeOut = animation:CreateAnimation("Alpha")

	fadeOut:SetFromAlpha(PULSE_PEAK_ALPHA)
	fadeOut:SetToAlpha(0)
	fadeOut:SetDuration(PULSE_HALF_SECONDS)
	fadeOut:SetStartDelay(PULSE_HALF_SECONDS)
	fadeOut:SetOrder(1)

	self.pulse = pulse
	self.pulseAnimation = animation
end

---@param waiting boolean
function Vault:SetRewardsWaiting(waiting)
	self.pulse:SetShown(waiting)

	if not waiting then
		self.pulseAnimation:Stop()
	elseif not self.pulseAnimation:IsPlaying() then
		self.pulseAnimation:Play()
	end
end

---@return boolean
function Vault:HasPendingItemLevel()
	local track = self.track

	if not track then
		return false
	end

	for _, milestone in ipairs(track.milestones) do
		if track.progress >= milestone.threshold and not milestone.itemLevel then
			return true
		end
	end

	return false
end

---@param track AMTDashboardVaultTrack
function Vault:Refresh(track)
	self.track = track

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

		if milestone and GameTooltip:IsOwned(view.frame) then
			self:ShowMilestoneTooltip(index)
		end
	end

	self:SetRewardsWaiting(track.rewardsWaiting)
	self:UpdateNote()
end

---@param threshold integer
function Vault:AddTopRuns(threshold)
	local track = self.track

	if not track then
		return
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MYTHIC_TOP_RUNS:format(threshold))

	for index = 1, math.min(threshold, #track.topRuns) do
		local run = track.topRuns[index]

		GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MYTHIC_RUN_INFO:format(run.level, run.name))
	end

	local missing = math.max(threshold - #track.topRuns, 0)
	local mythic = math.min(track.mythicRuns, missing)
	local heroic = math.min(track.heroicRuns, missing - mythic)

	for _ = 1, mythic do
		GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_MYTHIC:format(WeeklyRewardsUtil.MythicLevel))
	end

	for _ = 1, heroic do
		GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_HEROIC)
	end
end

---@param milestone AMTDashboardVaultMilestone
function Vault:AddRewardLines(milestone)
	GameTooltip_SetTitle(GameTooltip, WEEKLY_REWARDS_CURRENT_REWARD)

	local itemLevel = milestone.itemLevel

	if not itemLevel then
		GameTooltip_AddErrorLine(GameTooltip, RETRIEVING_ITEM_INFO)

		return
	end

	if milestone.heroic then
		GameTooltip_AddNormalLine(GameTooltip, WEEKLY_REWARDS_ITEM_LEVEL_HEROIC:format(itemLevel))
	else
		GameTooltip_AddNormalLine(GameTooltip, WEEKLY_REWARDS_ITEM_LEVEL_MYTHIC:format(itemLevel, milestone.level))
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)

	local upgradeItemLevel = milestone.upgradeItemLevel

	if not upgradeItemLevel then
		GameTooltip_AddColoredLine(GameTooltip, WEEKLY_REWARDS_MAXED_REWARD, GREEN_FONT_COLOR)

		return
	end

	GameTooltip_AddColoredLine(
		GameTooltip,
		WEEKLY_REWARDS_IMPROVE_ITEM_LEVEL:format(upgradeItemLevel),
		GREEN_FONT_COLOR
	)

	if milestone.threshold > 1 then
		GameTooltip_AddHighlightLine(
			GameTooltip,
			WEEKLY_REWARDS_COMPLETE_MYTHIC:format(milestone.nextLevel, milestone.threshold)
		)
		self:AddTopRuns(milestone.threshold)
	elseif milestone.heroic then
		GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_COMPLETE_HEROIC_SHORT)
	else
		GameTooltip_AddHighlightLine(GameTooltip, WEEKLY_REWARDS_COMPLETE_MYTHIC_SHORT:format(milestone.nextLevel))
	end
end

---@param milestone AMTDashboardVaultMilestone
---@param progress integer
function Vault:AddUnlockLines(milestone, progress)
	GameTooltip_SetTitle(GameTooltip, WEEKLY_REWARDS_UNLOCK_REWARD)

	local description = UNLOCK_DESCRIPTIONS[milestone.index] or UNLOCK_DESCRIPTIONS[1]

	if milestone.index > 1 then
		description = description:format(math.max(milestone.threshold - progress, 0))
	end

	GameTooltip_AddNormalLine(GameTooltip, description)

	local lowestLevel = milestone.lowestLevel

	if progress == 0 or not lowestLevel then
		return
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)

	if lowestLevel == WeeklyRewardsUtil.HeroicLevel then
		GameTooltip_AddNormalLine(GameTooltip, GREAT_VAULT_REWARDS_CURRENT_LEVEL_HEROIC:format(milestone.threshold))
	else
		GameTooltip_AddNormalLine(
			GameTooltip,
			GREAT_VAULT_REWARDS_CURRENT_LEVEL_MYTHIC:format(milestone.threshold, lowestLevel)
		)
	end

	self:AddTopRuns(milestone.threshold)
end

-- Blizzard's own vault tooltip for the dungeon track.
---@param index integer
function Vault:ShowMilestoneTooltip(index)
	local track = self.track
	local milestone = track and track.milestones[index]

	if not track or not milestone then
		return
	end

	GameTooltip:SetOwner(self.milestones[index].frame, "ANCHOR_RIGHT")

	if track.progress >= milestone.threshold and not track.canClaim then
		self:AddRewardLines(milestone)
	else
		self:AddUnlockLines(milestone, track.progress)
	end

	GameTooltip_AddBlankLineToTooltip(GameTooltip)
	GameTooltip_AddInstructionLine(GameTooltip, L["Click to open the Great Vault"])
	GameTooltip:Show()
end
