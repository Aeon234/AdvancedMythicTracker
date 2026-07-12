local AMT = select(2, ...) ---@class AMT
---@class L
local L = AMT.L

-- ========================
-- === Toggle Dashboard ===
-- ========================

function AdvancedMythicTracker_ToggleDashboard()
	if
		(InCombatLockdown())
		or (UnitLevel("player") ~= GetMaxLevelForPlayerExpansion())
		or not C_MythicPlus.IsMythicPlusActive()
		or PlayerGetTimerunningSeasonID()
	then
		return
	end

	if AMT.Dashboard:IsVisible() then
		AMT.Dashboard:Hide()
	else
		AMT.Dashboard:Show()
	end
end

-- ==========================
-- === Dashboard Creation ===
-- ==========================

local AMT_WINDOW_WIDTH = 960
local AMT_WINDOW_HEIGHT = PVEFrame:GetHeight() or 428

function AMT:CreateDashboard()
	if self.Dashboard then
		return
	end

	local f
	f = CreateFrame("Frame", "AdvancedMythicTracker", UIParent, "AdvancedMythicTrackerBlizzard")
	f:SetSize(AMT_WINDOW_WIDTH, AMT_WINDOW_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")

	-- Title
	local expName = _G["EXPANSION_NAME" .. GetExpansionLevel()]
	local season = C_MythicPlus.GetCurrentUIDisplaySeason()
	local title = "Advanced Mythic+ Tracker (" .. expName .. " Season " .. season .. ")"
	f:SetTitle(title)

	-- Set to Movable
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function()
		f:StartMoving()
	end)
	f:SetScript("OnDragStop", function()
		f:StopMovingOrSizing()
	end)

	-- On Show
	f:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		-- self:Update_PVEFrame_Panels()
	end)

	self.Dashboard = f

	-- PVEFrame Dashboard Tab Button
	local tabNum = PVEFrame.numTabs + 1
	local tab = CreateFrame("Button", "AdvancedMythicTrackerTab", PVEFrame, "PanelTabButtonTemplate", tabNum)
	PanelTemplates_DeselectTab(tab)
	tab:SetText(L["TAB_NAME"])
	tab:SetScript("OnClick", function()
		AdvancedMythicTracker_ToggleDashboard()
	end)
	self.MainTab = tab

	-- PVEFrame Hook
	PVEFrame:HookScript("OnShow", function()
		AMT.GetTabEligibility()

		local lastTab = AMT.GetPVEFrameTabNums()
		tab:SetPoint("LEFT", PVEFrame.Tabs[lastTab], "RIGHT", 3, 0)

		-- Enforce Tab Deselection
		for i = 1, PVEFrame.numTabs do
			local PVEFrame_Tab = _G["PVEFrameTab" .. i]
			PVEFrame_Tab:HookScript("OnClick", function(self, button)
				PanelTemplates_DeselectTab(tab)
			end)
		end
		local selected = PanelTemplates_GetSelectedTab(PVEFrame)
		if selected ~= (PVEFrame.numTabs + 1) then
			PanelTemplates_DeselectTab(tab)
		end
	end)
end
