local addonName, AMT = ...

-- ==================================
-- === Initialize Main AMT Window ===
-- ==================================
local AMT_Window
if AMT.ElvUIEnabled then
	AMT_Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_ElvUITemplate")
	AMT.S:HandleFrame(AMT_Window)
else
	AMT_Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_RetailTemplate")
end

-- =================================
-- === Initialize AMT Tab Button ===
-- =================================
local AMT_TabButton = CreateFrame("Button", "AMT_Tab", PVEFrame, "PanelTabButtonTemplate", (PVEFrame.numTabs + 1))
if AMT.ElvUIEnabled then
	AMT.S:HandleTab(AMT_TabButton)
	AMT_TabButton:SetText("Keystone Tracker")
else
	AMT_TabButton:SetText("Advanced Keystone Tracker")
end
PanelTemplates_DeselectTab(AMT_TabButton) --Force newly created button to be deselected

-- =================================================
-- === Set "On Click" Actions for AMT Tab Button ===
-- =================================================
AMT_TabButton:SetScript("OnClick", function()
	if AMT_Window:IsVisible() then
		AMT_Window:Hide()
	else
		AMT_Window:ClearAllPoints()
		AMT_Window:SetPoint("TOPLEFT", PVEFrame)
		AMT_Window:Show()
		PVEFrame_ToggleFrame()
	end
end)

-- ===============================
-- === Hook PVEFrame "On Show" ===
-- ===============================
PVEFrame:HookScript("OnShow", function()
	AMT.Check_PVEFrame_TabNums()
	if UnitLevel("player") >= GetMaxLevelForPlayerExpansion() then
		if AMT.ElvUIEnabled then
			AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", -5, 0)
		else
			--Now that we've checked # of active tabs we'll anchor the AMT button to the last active tab
			AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", 3, 0)
		end
	end
	--Starting at tab 1, whenever each PVEFrame tab is click deselect the AMT Tab Button
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		PVEFrame_Tab:HookScript("OnClick", function(self, button)
			PanelTemplates_DeselectTab(AMT_TabButton)
		end)
	end
	local selected = PanelTemplates_GetSelectedTab(PVEFrame)
	if selected ~= (PVEFrame.numTabs + 1) then
		PanelTemplates_DeselectTab(AMT_TabButton)
	end
	AMT_Window:Hide()
end)

-- ================================
-- === Set AMT_Window "On Show" ===
-- ================================
AMT_Window:SetScript("OnShow", function() end)
