local AMT = select(2, ...) ---@class AMT
---@class L
local L = AMT.L

-- Dashboard window and its PVEFrame tab. The tab uses Blizzard's stock
-- disabled-tab treatment when eligibility fails (pure check lives in Util.lua);
-- the lock reason is surfaced as a tooltip on the disabled tab, which requires
-- motion scripts to stay enabled while the button is disabled.

-- ========================
-- === Toggle Dashboard ===
-- ========================

---Toggle the dashboard. Disabled in combat and on ineligible conditions.
function AMT.ToggleDashboard()
	if InCombatLockdown() or not AMT.IsTabEligible() then
		return
	end

	AMT.Dashboard:SetShown(not AMT.Dashboard:IsShown())
end

-- ========================
-- === Main Tab State  ====
-- ========================

---Apply enabled/disabled visuals and click behavior to the Main Tab.
function AMT.UpdateMainTabState()
	local tab = AMT.MainTab
	if not tab then
		return
	end

	local eligible, reasonKey = AMT.IsTabEligible()
	tab.lockReasonKey = reasonKey

	if eligible then
		PanelTemplates_DeselectTab(tab)
	else
		PanelTemplates_SetDisabledTabState(tab)
		if AMT.Dashboard and AMT.Dashboard:IsShown() then
			AMT.Dashboard:Hide()
		end
	end
end

-- ==========================
-- === Dashboard Creation ===
-- ==========================

local AMT_WINDOW_WIDTH = 960
local AMT_FALLBACK_HEIGHT = 428

---Season data is nil early in a session; Blizzard guards the same way in ChallengesFrameMixin:UpdateTitle.
---@return string
local function GetDashboardTitle()
	local season = C_MythicPlus.GetCurrentUIDisplaySeason()
	if not season then
		return L["DASHBOARD_TITLE_NO_SEASON"]
	end

	local expName = _G["EXPANSION_NAME" .. GetExpansionLevel()]
	return string.format(L["DASHBOARD_TITLE"], expName, season)
end

local function CreateDashboard()
	if AMT.Dashboard then
		return
	end

	local f = CreateFrame("Frame", "AdvancedMythicTracker", UIParent, "AdvancedMythicTrackerBlizzard")
	f:SetSize(AMT_WINDOW_WIDTH, PVEFrame:GetHeight() or AMT_FALLBACK_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")
	f:SetTitle(GetDashboardTitle())

	-- Movable
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	f:SetScript("OnShow", function(self)
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		self:SetTitle(GetDashboardTitle()) -- season data may have arrived since creation
	end)
	f:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)

	-- Escape closes the dashboard
	table.insert(UISpecialFrames, "AdvancedMythicTracker")

	AMT.Dashboard = f

	-- PVEFrame Dashboard Tab Button
	local tabNum = PVEFrame.numTabs + 1
	local tab = CreateFrame("Button", "AdvancedMythicTrackerTab", PVEFrame, "PanelTabButtonTemplate", tabNum)
	tab:SetText(L["TAB_NAME"])
	tab:SetMotionScriptsWhileDisabled(true) -- keep OnEnter alive while disabled for the lock tooltip
	PanelTemplates_DeselectTab(tab)
	AMT.MainTab = tab

	tab:SetScript("OnClick", function()
		AMT.ToggleDashboard()
	end)
	tab:SetScript("OnEnter", function(self)
		if self.lockReasonKey then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L[self.lockReasonKey], nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	tab:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- One-time hooks. HookScript STACKS handlers — installing these inside the
	-- OnShow hook (previous code) added a duplicate set on every PVEFrame open.
	PVEFrame:HookScript("OnShow", function()
		AMT.UpdateMainTabState()

		local lastTab = AMT.GetPVEFrameTabNums()
		tab:SetPoint("LEFT", PVEFrame.Tabs[lastTab], "RIGHT", 3, 0)
	end)
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if PVEFrame_Tab then
			PVEFrame_Tab:HookScript("OnClick", function()
				AMT.UpdateMainTabState() -- re-assert deselected/disabled visuals
			end)
		end
	end

	AMT.UpdateMainTabState()
end

AMT.RegisterEvent("PLAYER_LOGIN", CreateDashboard)
AMT.RegisterEvent("PLAYER_LEVEL_UP", function()
	AMT.UpdateMainTabState()
end)
