local addonName, AMT = ...

local E, S
if ElvUI then
	E = unpack(ElvUI)
	S = ElvUI[1]:GetModule("Skins")
end

function LoadTrackingData()
	for _, raid in pairs(SeasonalRaids) do
		-- EncounterJournal Quirk: This has to be called first before we can get encounter journal info.
		EJ_SelectInstance(raid.journalInstanceID)
		wipe(raid.encounters or {})
		for encounterIndex = 1, raid.numEncounters do
			local name, description, journalEncounterID, journalEncounterSectionID, journalLink, journalInstanceID, instanceEncounterID, instanceID =
				EJ_GetEncounterInfoByIndex(encounterIndex, raid.journalInstanceID)
			local encounter = {
				index = encounterIndex,
				name = name,
				description = description,
				journalEncounterID = journalEncounterID,
				journalEncounterSectionID = journalEncounterSectionID,
				journalLink = journalLink,
				journalInstanceID = journalInstanceID,
				instanceEncounterID = instanceEncounterID,
				instanceID = instanceID,
			}
			raid.encounters[encounterIndex] = encounter
		end
		raid.modifiedInstanceInfo = C_ModifiedInstance.GetModifiedInstanceInfoFromMapID(raid.instanceID)
	end
end
--Create an invisible frame called AMT_Container_BG which will be the tab we use. We attach it to PVEFrame as another tab alongside it's exisiting tabs such as Dungeon & Raids and Player vs Player.
AMT_Container_BG = CreateFrame("Frame", nil, PVEFrame)
AMT_Container_BG:SetAllPoints(PVEFrame)

--Create an invisible frame that is layered on top of AMT_Container_BG which will be used to display data above the textures we establish on AMT_Container_BG
AMT_Container_Data = CreateFrame("Frame", nil, AMT_Container_BG)
AMT_Container_Data:SetAllPoints(AMT_Container_BG)

-- Calculate how many tabs are currently displayed in PVEFrame
local PVEFrame_TabNums = 2
--Stores what tab # our AMT button will be (Max tabs + 1)
local AMT_TabNum = 3
--Sets up variable so we can call our AMT Tab
local AMT_TabDirectory = "PVEFrameTab" .. (PVEFrame.numTabs + 1)

local function Check_PVEFrame_TabNums()
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if not PVEFrame_Tab:IsVisible() then
			PVEFrame_TabNums = i - 1
			AMT_TabNum = i
			break
		else
			PVEFrame_TabNums = PVEFrame.numTabs
			AMT_TabNum = PVEFrame.numTabs + 1
		end
	end
end
Check_PVEFrame_TabNums()
--Create the tab button that will open up the AMT Tab in PVEFrame.
local AMT_TabButton = CreateFrame("Button", "AMT_Tab", PVEFrame, "PanelTabButtonTemplate", (PVEFrame.numTabs + 1))
if ElvUI then
	S:HandleTab(AMT_Tab)
	AMT_TabButton:SetText("Keystone Tracker")
else
	AMT_TabButton:SetText("Advanced Keystone Tracker")
end
--Force the state of the tab to be deselected. Otherwise when you first open up the PVEFrame it will be stuck in both a selected and deselected phase.
PanelTemplates_DeselectTab(AMT_TabButton)

-- EventRegistry:RegisterFrameEventAndCallback("PVPQUEUE_ANYWHERE_SHOW", function()
-- 	local selected = PanelTemplates_GetSelectedTab(PVEFrame)
-- 	if selected == (PVEFrame.numTabs + 1) then
-- 		AMT:AMT_Title()
-- 		for _, t in ipairs(PVEFrame.Tabs) do
-- 			PanelTemplates_DeselectTab(t)
-- 		end
-- 		PanelTemplates_SelectTab(AMT_TabButton)
-- 	end
-- end)

hooksecurefunc("PVEFrame_ToggleFrame", function()
	Check_PVEFrame_TabNums()
	if ElvUI then
		AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", -5, 0)
	else
		--Now that we've checked # of active tabs we'll anchor the AMT button to the last active tab
		AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", 3, 0)
	end
	--Starting at tab 1, whenever each PVEFrame tab is click deselect the AMT Tab Button
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		PVEFrame_Tab:HookScript("OnClick", function(self, button)
			PanelTemplates_DeselectTab(AMT_TabButton)
			AMT_Container_BG:Hide()
		end)
	end
	-- print("DEBUG: PVEFrame_OnEvent is run")
	local selected = PanelTemplates_GetSelectedTab(PVEFrame)
	if selected ~= (PVEFrame.numTabs + 1) then
		AMT_Container_BG:Hide()
		PanelTemplates_DeselectTab(AMT_TabButton)
	end
end)

--When we exit the PVEFrame, deselect the AMT Tab.
PVEFrame:HookScript("OnHide", function()
	PanelTemplates_DeselectTab(AMT_TabButton)
	AMT_Container_BG:Hide()
end)

--Set On Click actions for the AMT Button
AMT_TabButton:SetScript("OnClick", function()
	LoadTrackingData()
	PanelTemplates_SetTab(PVEFrame, 4)
	PVEFrameTab2:Click()
	--Deselect the regular PVEFrame tabs
	for _, t in ipairs(PVEFrame.Tabs) do
		PanelTemplates_DeselectTab(t)
	end
	PanelTemplates_SelectTab(AMT_TabButton)
	PVPUIFrame:Hide()

	AMT_Container_BG:Show()

	AMT:AMT_Visuals()
	PanelTemplates_SetTab(PVEFrame, 4)

	-- AMT:AMT_Title()
	-- AMT:Display_Data()
end)
