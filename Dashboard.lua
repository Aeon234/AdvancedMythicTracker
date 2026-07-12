local AMT = select(2, ...) ---@class AMT
local L = AMT.L ---@class L
local API = AMT.API ---@class API

-- Dashboard window styled as an extension of PVEFrame: it carries a mirrored
-- copy of PVEFrame's tab row (plus this addon's own tab, rendered active),
-- swaps in at PVEFrame's screen position when opened from the PVEFrame tab,
-- and returns to the matching PVEFrame panel when a mirrored tab is clicked.
-- Eligibility (pure check in Util.lua) gates the PVEFrame-side tab; the lock
-- reason is a tooltip on the disabled tab (motion scripts stay enabled).

-- Mirrors the private `panels` list in Blizzard_GroupFinder/Mainline/PVEFrame.lua;
-- index i corresponds to PVEFrameTab<i>.
local PVE_PANELS = { "GroupFinderFrame", "PVPUIFrame", "ChallengesFrame" }
local AMT_TAB_INDEX = #PVE_PANELS + 1

-- ==========================
-- === Show / Toggle ========
-- ==========================

---Anchor the dashboard to PVEFrame's current screen position, hide PVEFrame,
---show the dashboard. PVEFrame's own OnHide close sound plays regardless;
---unavoidable without taint.
local function SwapFromPVEFrame()
	local f = AMT.Dashboard
	local left, top = PVEFrame:GetLeft(), PVEFrame:GetTop()
	if left and top then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
	end

	HideUIPanel(PVEFrame)
	f:Show()
end

---Toggle the dashboard (slash command / future keybind path — standard open
---sound). Swaps in place of PVEFrame when it is open. No-ops in combat and
---on ineligible conditions.
function AMT.ToggleDashboard()
	if InCombatLockdown() or not AMT.IsTabEligible() then
		return
	end

	local f = AMT.Dashboard
	if f:IsShown() then
		f:Hide()
	elseif PVEFrame:IsShown() then
		SwapFromPVEFrame() -- default open sound: this path is not a tab click
	else
		f:Show()
	end
end

---PVEFrame-tab click path: same swap, but sounds like a tab click.
local function SwitchToDashboard()
	if InCombatLockdown() or not AMT.IsTabEligible() then
		return
	end

	AMT.Dashboard.openSoundKit = SOUNDKIT.IG_CHARACTER_INFO_TAB
	SwapFromPVEFrame()
end

-- ==========================
-- === Main Tab State =======
-- ==========================

---Apply enabled/disabled visuals and click behavior to the PVEFrame-side tab.
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
-- === Dashboard Tab Row ====
-- ==========================

---Mirror PVEFrame's tab row onto the dashboard: copy label and shown state of
---each Blizzard tab (IsShown, not IsVisible — PVEFrame is hidden during the
---swap), re-anchor the chain across hidden ones, and render this addon's tab
---as the selected one. Selected tabs are disabled by PanelTemplates, so the
---active tab needs no click handler.
local function UpdateDashboardTabs()
	local f = AMT.Dashboard
	local previous
	for i = 1, #PVE_PANELS do
		local source = _G["PVEFrameTab" .. i]
		local tab = f.Tabs[i]
		tab:SetText(source:GetText())
		PanelTemplates_TabResize(tab, 0)
		tab:SetShown(source:IsShown())
		if source:IsShown() then
			tab:ClearAllPoints()
			if previous then
				tab:SetPoint("LEFT", previous, "RIGHT", -16, 0)
			else
				tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 19, -30)
			end
			previous = tab
		end
	end

	local amtTab = f.Tabs[AMT_TAB_INDEX]
	amtTab:ClearAllPoints()
	if previous then
		amtTab:SetPoint("LEFT", previous, "RIGHT", -16, 0)
	else
		amtTab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 19, -30)
	end

	PanelTemplates_SetTab(f, AMT_TAB_INDEX)
end

---Click on a mirrored Blizzard tab: swap back to the matching PVEFrame panel.
---PVEFrame plays its own open sound via ShowUIPanel, so we play nothing and
---suppress our close sound to avoid stacking three sounds.
local function OnMirroredTabClick(self)
	local f = AMT.Dashboard
	f.suppressCloseSound = true
	f:Hide()
	PVEFrame_ShowFrame(PVE_PANELS[self:GetID()])
end

local function CreateDashboardTabs(f)
	f.Tabs = {}
	f.numTabs = AMT_TAB_INDEX

	for i = 1, #PVE_PANELS do
		local tab = CreateFrame("Button", "AdvancedMythicTrackerTab" .. i, f, "PanelTabButtonTemplate", i)
		tab:SetScript("OnClick", OnMirroredTabClick)
		f.Tabs[i] = tab
	end

	local amtTab =
		CreateFrame("Button", "AdvancedMythicTrackerTab" .. AMT_TAB_INDEX, f, "PanelTabButtonTemplate", AMT_TAB_INDEX)
	amtTab:SetText(L["TAB_NAME"])
	PanelTemplates_TabResize(amtTab, 0)
	f.Tabs[AMT_TAB_INDEX] = amtTab

	UpdateDashboardTabs()
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
		-- openSoundKit is a one-shot override set by SwitchToDashboard (tab
		-- transitions sound like tab clicks; everything else sounds like a window).
		PlaySound(self.openSoundKit or SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		self.openSoundKit = nil
		self:SetTitle(GetDashboardTitle()) -- season data may have arrived since creation
		UpdateDashboardTabs()
		-- Mutual exclusivity from this side too, in case a future code path
		-- shows the dashboard without going through the swap helpers.
		if PVEFrame:IsShown() then
			HideUIPanel(PVEFrame)
		end
	end)
	f:SetScript("OnHide", function(self)
		if self.suppressCloseSound then
			self.suppressCloseSound = nil
		else
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		end
	end)

	-- Escape closes the dashboard
	table.insert(UISpecialFrames, "AdvancedMythicTracker")

	AMT.Dashboard = f

	CreateDashboardTabs(f)

	-- PVEFrame Dashboard Tab Button
	local tabNum = PVEFrame.numTabs + 1
	local tab = CreateFrame("Button", "AdvancedMythicTrackerTab", PVEFrame, "PanelTabButtonTemplate", tabNum)
	tab:SetText(L["TAB_NAME"])
	tab:SetMotionScriptsWhileDisabled(true) -- keep OnEnter alive while disabled for the lock tooltip
	PanelTemplates_DeselectTab(tab)
	AMT.MainTab = tab

	tab:SetScript("OnClick", function()
		SwitchToDashboard()
	end)
	tab:SetScript("OnEnter", function(self)
		if self.lockReasonKey then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["TAB_NAME"], 1, 1, 1)
			GameTooltip:AddLine(L[self.lockReasonKey], nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	tab:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- One-time hooks. HookScript STACKS handlers — installing these inside the
	-- OnShow hook would add a duplicate set on every PVEFrame open.
	PVEFrame:HookScript("OnShow", function()
		-- Mutual exclusivity: PVEFrame appearing through ANY path (keybind,
		-- micro button, LFG events) replaces the dashboard, mirroring how the
		-- dashboard replaces PVEFrame. PVEFrame's open sound already plays, so
		-- our close sound stays silent.
		if f:IsShown() then
			f.suppressCloseSound = true
			f:Hide()
		end

		AMT.UpdateMainTabState()

		-- PVEFrame.Tabs does not exist (XML only sets parentKey tab1..3);
		-- resolve by global name like PanelTemplates itself does. For
		-- timerunners Blizzard hides every PVEFrame tab, so anchor only when
		-- at least one is visible and hide ours alongside theirs.
		local lastTab = AMT.GetPVEFrameTabNums()
		local anchorTab = lastTab > 0 and _G["PVEFrameTab" .. lastTab] or nil
		tab:SetShown(anchorTab ~= nil)
		if anchorTab then
			tab:SetPoint("LEFT", anchorTab, "RIGHT", 3, 0)
		end
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
	AMT:PopulateDashboard()
end

AMT.RegisterEvent("PLAYER_LOGIN", function()
	CreateDashboard()
end)
AMT.RegisterEvent("PLAYER_LEVEL_UP", function()
	AMT.UpdateMainTabState()
end)

-- ==========================
-- === Dashboard Content ===
-- ==========================

function AMT:PopulateDashboard()
	local f = API.CreateNineSliceFrame(self.Dashboard, "Brown")
	f:SetPoint("TOPLEFT", 9, -25) --Dashboard has a 20px header and 8px LEFT padding
	f:SetSize(150, 60)

	local title = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetPoint("TOPLEFT", 8, -6)
	title:SetText("Mythic+ Rating")

	local font, size, flag = title:GetFont()

	local score = f:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	score:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
	score:SetText("3218")

	title:SetFont(font, 16, flag)
	score:SetFont(font, 26, flag)
	score:SetTextColor(0.7, 0.8, 0.5, 1)
end
