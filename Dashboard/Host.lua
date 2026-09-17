local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard

local TAB_ID = 4
local PANEL_WIDTH = 950
local ICON = 4352494

local BLIZZARD_PANELS = { "GroupFinderFrame", "PVPUIFrame", "ChallengesFrame" }

---@class AMTDashboardHost
---@field attached boolean
---@field tab Button
---@field panel AMTDashboardPanelRoot
---@field lastWasTracker boolean
---@field unavailableReason string?

local Host = {}
Dashboard.Host = Host

Host.attached = false
Host.lastWasTracker = false

---@return string?
local function GetUnavailableReason()
	if PlayerIsTimerunning() then
		return L["The Tracker is not available to Timerunners."]
	end

	local maxLevel = GetMaxLevelForPlayerExpansion()
	local level = UnitLevel("player")

	if not issecretvalue(level) and level < maxLevel then
		return FEATURE_BECOMES_AVAILABLE_AT_LEVEL:format(maxLevel)
	end

	if not C_MythicPlus.IsMythicPlusActive() then
		return MYTHIC_PLUS_TAB_DISABLE_TEXT
	end
end

-- Premade Groups Filter compatibility
local function UpdatePremadeGroupsFilter()
	local addon = _G.PremadeGroupsFilter
	local dialog = addon and addon.DialogFrame

	if dialog and dialog.Toggle then
		dialog:Toggle()
	end
end

---@return string
local function GetTitle()
	local season = C_MythicPlus.GetCurrentUIDisplaySeason()
	local expansion = _G["EXPANSION_NAME" .. GetExpansionLevel()]

	if not season or not expansion then
		return AMT.title
	end

	return L["Advanced Mythic Tracker (%s Season %d)"]:format(expansion, season)
end

function Host:UpdateAvailability()
	self.unavailableReason = GetUnavailableReason()

	PanelTemplates_SetTabEnabled(PVEFrame, TAB_ID, self.unavailableReason == nil)
end

function Host:AnchorTab()
	local tab = self.tab
	local anchor = Dashboard.Skin:GetTabAnchor()

	tab:ClearAllPoints()

	for index = TAB_ID - 1, 1, -1 do
		local previous = PVEFrame.Tabs[index]

		if previous:IsShown() then
			tab:SetPoint("TOPLEFT", previous, "TOPRIGHT", anchor.gap, 0)

			return
		end
	end

	tab:SetPoint(anchor.point, PVEFrame, "BOTTOMLEFT", anchor.x, anchor.y)
end

---@param silent boolean
function Host:Select(silent)
	if self.unavailableReason or self.panel:IsShown() then
		return
	end

	if not silent then
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
	end

	for _, name in ipairs(BLIZZARD_PANELS) do
		local panel = _G[name]

		if panel then
			panel:Hide()
		end
	end

	UpdatePremadeGroupsFilter()

	PanelTemplates_SetTab(PVEFrame, TAB_ID)
	PVEFrame:SetWidth(PANEL_WIDTH)
	PVEFrame_HideLeftInset()
	PVEFrame:SetPortraitToAsset(ICON)
	UpdateUIPanelPositions(PVEFrame)
	PVEFrame:SetTitle(GetTitle())
	self.panel:Show()

	self.lastWasTracker = true
end

---@param sidePanelName string?
function Host:OnShowFrame(sidePanelName)
	self.panel:Hide()

	if sidePanelName then
		self.lastWasTracker = false
	elseif self.lastWasTracker then
		self:Select(true)
	end
end

function Host:ShowUnavailableTooltip()
	if not self.unavailableReason then
		return
	end

	local tooltip = GetAppropriateTooltip()

	tooltip:SetOwner(self.tab, "ANCHOR_RIGHT")
	tooltip:SetText(self.tab:GetText())
	GameTooltip_AddErrorLine(tooltip, self.unavailableReason, true)
	tooltip:Show()
end

function Host:Toggle()
	if not self.attached then
		return
	end

	local closing = PVEFrame:IsShown() and self.panel:IsShown()

	if InCombatLockdown() and (closing or not PVEFrame:IsShown()) then
		AMT.Util.Warn(L["The dashboard cannot be opened or closed in combat."])

		return
	end

	if closing then
		HideUIPanel(PVEFrame)

		return
	end

	if GetUnavailableReason() then
		return
	end

	local wasShown = PVEFrame:IsShown()

	if not wasShown then
		PVEFrame_ToggleFrame()

		if not PVEFrame:IsShown() then
			return
		end
	end

	self:Select(not wasShown)
end

function Host:Attach()
	if PVEFrame.Tabs[TAB_ID] then
		AMT.Util.Warn(L["another addon already added a fourth Group Finder tab; the Tracker tab was not added."])

		return
	end

	local tab = CreateFrame("Button", "AdvancedMythicTrackerDashboardTab", PVEFrame, "PanelTabButtonTemplate")

	tab:SetID(TAB_ID)
	tab:SetText(L["Tracker"])
	Dashboard.Skin:Register(tab, "tab")
	tab:SetScript("OnClick", function()
		self:Select(false)
	end)
	tab:HookScript("OnEnter", function()
		self:ShowUnavailableTooltip()
	end)

	self.tab = tab
	self.panel = Dashboard.Panel.Build(PVEFrame)
	self.attached = true

	Dashboard.Skin:Start()

	PanelTemplates_SetNumTabs(PVEFrame, TAB_ID)

	PVEFrame:HookScript("OnShow", function()
		self:UpdateAvailability()
		self:AnchorTab()
	end)

	hooksecurefunc("PVEFrame_ShowFrame", function(sidePanelName)
		self:OnShowFrame(sidePanelName)
	end)
end

BINDING_NAME_AMT_DASHBOARD = L["Toggle Dashboard"]

function AdvancedMythicTracker_ToggleDashboard()
	Host:Toggle()
end

local loader = CreateFrame("Frame")

loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)

	Host:Attach()
end)
