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
AMT_Window:SetSize(960, PVEFrame:GetHeight()) -- Set Size
AMT_Window:Raise() --Set frame layer to be at the top of others
AMT_Window:SetToplevel(true)
AMT_Window:Hide() --Hide Window
AMT_Window:SetClampedToScreen(true) -- Clamp to screen
AMT_Window:SetMovable(true) -- Set frame to be movable
AMT_Window:EnableMouse(true) -- Capture mouse interaction with window
AMT_Window:RegisterForDrag("LeftButton") -- Register left mouse button click for dragging
AMT_Window:SetScript("OnDragStart", function(self, button)
	self:StartMoving()
end)
AMT_Window:SetScript("OnDragStop", function(self, button)
	self:StopMovingOrSizing()
end)

-- =================================
-- === Initialize AMT Icon Button ===
-- =================================
local AMT_PVEFrame_IconFrame = CreateFrame("Button", "AMT_PVEFrame_IconFrame", PVEFrame) --, "BackdropTemplate"
-- AMT_PVEFrame_IconFrame:SetSize(112, 48)
AMT_PVEFrame_IconFrame:SetSize(80, 32)
AMT_PVEFrame_IconFrame:SetPoint("BOTTOMLEFT", PVEFrame, "TOPLEFT", 60, -29)
AMT_PVEFrame_IconFrame:Raise()
AMT_PVEFrame_IconFrame:SetToplevel(true)
AMT_PVEFrame_IconFrame:SetFrameLevel(1000)
AMT_PVEFrame_IconFrame.tex = AMT_PVEFrame_IconFrame:CreateTexture()
AMT_PVEFrame_IconFrame.tex:SetAllPoints(AMT_PVEFrame_IconFrame)
AMT_PVEFrame_IconFrame.tex:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Art/AMT_Logo_Test.png")
-- AMT_PVEFrame_IconFrame.mask = AMT_PVEFrame_IconFrame:CreateMaskTexture()
-- AMT_PVEFrame_IconFrame.mask:SetAllPoints(AMT_PVEFrame_IconFrame.tex)
-- AMT_PVEFrame_IconFrame.mask:SetTexture("Interface/AddOns/AdvancedMythicTracker/Art/AMT_PVEFrame_BaseIcon_Mask")
-- AMT_PVEFrame_IconFrame.tex:AddMaskTexture(AMT_PVEFrame_IconFrame.mask)
AMT_PVEFrame_IconFrame.highlight = AMT_PVEFrame_IconFrame:CreateTexture(nil, "HIGHLIGHT")
AMT_PVEFrame_IconFrame.highlight:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
AMT_PVEFrame_IconFrame.highlight:SetBlendMode("ADD")
AMT_PVEFrame_IconFrame.highlight:SetAllPoints(AMT_PVEFrame_IconFrame)
AMT_PVEFrame_IconFrame.highlight:Hide() -- Initially hide the highlight
-- Set up the OnEnter and OnLeave scripts to handle the highlight effect
AMT_PVEFrame_IconFrame:SetScript("OnEnter", function(self)
	AMT_PVEFrame_IconFrame.highlight:Show()
end)

AMT_PVEFrame_IconFrame:SetScript("OnLeave", function(self)
	AMT_PVEFrame_IconFrame.highlight:Hide()
end)

AMT_PVEFrame_IconFrame:SetScript("OnClick", function(self)
	if AMT_Window:IsVisible() then
		AMT_Window:Hide()
	else
		AMT_Window:ClearAllPoints()
		AMT_Window:SetPoint("TOPLEFT", PVEFrame)
		AMT_Window:Show()
		PVEFrame_ToggleFrame()
	end
end)

-- =================================
-- === Initialize AMT Tab Button ===
-- =================================
local AMT_TabButton = CreateFrame("Button", "AMT_Tab", PVEFrame, "PanelTabButtonTemplate", (PVEFrame.numTabs + 1))
if AMT.ElvUIEnabled then
	AMT.S:HandleTab(AMT_TabButton)
	AMT_TabButton:SetText("Mythic Tracker")
else
	AMT_TabButton:SetText("Mythic Tracker")
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
	AMT:Check_PVEFrame_TabNums()
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
AMT_Window:SetScript("OnShow", function()
	AMT:Update_PVEFrame_Panels()
	AMT:Pull_VaultRequirements()
	AMT:AMT_UpdateRaidProg()
	AMT:AMT_UpdateAffixInformation()
	AMT:Update_PlayerDungeonInfo()
	AMT:AMT_Update_PlayerMplus_Score()
	if AMT.AMT_CreationComplete then
		AMT:AMT_DataUpdate()
	else
		AMT:AMT_Creation()
	end
end)
