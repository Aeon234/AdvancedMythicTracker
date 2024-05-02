--Create an invisible frame called AMT_Container_BG which will be the tab we use. We attach it to PVEFrame as another tab alongside it's exisiting tabs such as Dungeon & Raids and Player vs Player.
local AMT_Container_BG = CreateFrame("Frame", nil, PVEFrame)
AMT_Container_BG:SetAllPoints(PVEFrame)
--Create an invisible frame that is layered on top of AMT_Container_BG which will be used to display data above the textures we establish on AMT_Container_BG
local AMT_Container_Data = CreateFrame("Frame", nil, AMT_Container_BG)
AMT_Container_Data:SetAllPoints(AMT_Container_BG)

local PVEFrame_TabNums = 0
local function Check_PVEFrame_TabNums()
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if not PVEFrame_Tab:IsVisible() then
			PVEFrame_TabNums = i - 1
			break
		else
			PVEFrame_TabNums = PVEFrame.numTabs
		end
	end
end

local function SetAMTTitle()
	local currentDisplaySeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	if not currentDisplaySeason then
		PVEFrame:SetTitle(CHALLENGES)
		return
	end

	local currExpID = GetExpansionLevel()
	local expName = _G["EXPANSION_NAME" .. currExpID]
	local title = "Advanced Mythic Tracker (" .. expName .. " Season " .. currentDisplaySeason .. ")"
	PVEFrame:SetTitle(title)
end

--Create the button that we will use to toggle into our newly created tab.
local AMT_TabButton = CreateFrame("Button", nil, PVEFrame, "PanelTabButtonTemplate")

AMT_TabButton:SetText("Advanced Keystone Tracker")
PanelTemplates_TabResize(AMT_TabButton, 0)
PanelTemplates_SetNumTabs(AMT_TabButton, 1)
PanelTemplates_DeselectTab(AMT_TabButton)

local function AMT_Visuals()
	if not RuneArt then
		RuneArt = CreateFrame("Frame", "RuneTexture", AMT_Container_BG)
		RuneArt:SetPoint("BOTTOMLEFT", AMT_Container_BG, "BOTTOMLEFT", 45, 14)
		RuneArt:SetSize(132, 132)
		RuneArt:SetFrameStrata("MEDIUM")

		RuneArt.tex = RuneArt:CreateTexture()
		RuneArt.tex:SetAllPoints(RuneArt)
		RuneArt.tex:SetAtlas("Artifacts-CrestRune-Gold", false)
	end

	if not WeeklyBest_Label then
		WeeklyBest_Label = AMT_Container_BG:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge2")
		WeeklyBest_Label:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 70, -30)
		WeeklyBest_Label:SetText("Weekly Best")
	end
end

local function AMT_Button()
	if not GreatVault_Button then
		GreatVault_Button = CreateFrame("Button", nil, AMT_Container_Data, "UIPanelButtonTemplate")
		GreatVault_Button:SetPoint("BOTTOMLEFT", AMT_Container_Data, "BOTTOMLEFT", 76, -30)
		GreatVault_Button:SetSize(90, 30)
		GreatVault_Button:SetText("Open Vault")

		-- print(PVEFrameTab4:GetText())

		GreatVault_Button:SetScript("OnClick", function()
			C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
			WeeklyRewardsFrame:Show()
			if WeeklyRewardsFrame.Overlay then
				WeeklyRewardsFrame.Overlay:Hide()
				WeeklyRewardsFrame.Blackout:Hide()
			end
		end)
	end
end

--Set On Click actions for the AMT Button
AMT_TabButton:SetScript("OnClick", function()
	PVEFrameTab4:Click()
	--Deselect the regular PVEFrame tabs
	for _, t in ipairs(PVEFrame.Tabs) do
		PanelTemplates_DeselectTab(t)
		SetAMTTitle()
	end
	--   for _, t in ipairs(AMT_Container_BG.Tabs) do
	--     PanelTemplates_DeselectTab(t)
	--   end
	--Set AMT Button as selected

	PVPUIFrame:Hide()
	PVEFrame:SetPortraitToAsset("Interface\\Icons\\Ability_BossMagistrix_TimeWarp2")
	AMT_Container_BG:Show()

	PanelTemplates_SelectTab(AMT_TabButton)
	AMT_Visuals()
	AMT_Button()
	SetAMTTitle()
end)

--When we exit the PVEFrame, deselect the AMT Tab.
PVEFrame:HookScript("OnHide", function()
	PanelTemplates_DeselectTab(AMT_TabButton)
	AMT_Container_BG:Hide()
end)

--Hook into PVEFrame when it becomes visible
PVEFrame:HookScript("OnShow", function()
	Check_PVEFrame_TabNums()
	AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", 3, 0)
	--Starting at tab 1, whenever each PVEFrame tab is click deselect the AMT Tab Button
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		PVEFrame_Tab:HookScript("OnClick", function(self, button)
			PanelTemplates_DeselectTab(AMT_TabButton)
			AMT_Container_BG:Hide()
		end)
	end
end)
