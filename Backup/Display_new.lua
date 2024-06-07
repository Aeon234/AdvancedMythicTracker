local addonName, AMT = ...

-- ==================================
-- === Complete AMT_Window Set-up ===
-- ==================================

function AMT:AMT_Creation()
	-- =============================
	-- === AMT Window Properties ===
	-- =============================
	local AMT_Window = _G["AMT_Window"]
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

	-- ==============================
	-- === AMT Window Tabs Set-up ===
	-- ==============================
	AMT.Update_PVEFrame_Panels()
	local VisiblePanels = {}
	-- Filter out visible panels
	for i = 1, #self.PVEFrame_Panels do
		if self.PVEFrame_Panels[i].isVisible then
			tinsert(VisiblePanels, {
				text = self.PVEFrame_Panels[i].text,
				frameName = self.PVEFrame_Panels[i].frameName,
				isVisible = self.PVEFrame_Panels[i].isVisible,
			})
		end
	end
	-- Create each tab button to reference back to PVEFrame
	local AMT_Window_TabButton
	if not _G["AMT_Window_Tab" .. #VisiblePanels] then
		for i = 1, #VisiblePanels do
			if self.PVEFrame_Panels[i].isVisible then
				AMT_Window_TabButton =
					CreateFrame("Button", "AMT_Window_Tab" .. i, AMT_Window, "PanelTabButtonTemplate")
				AMT_Window_TabButton:SetText(VisiblePanels[i].text)
				AMT_Window_TabButton:SetFrameStrata("HIGH")
				local tabButton = _G["AMT_Window_Tab" .. i]
				-- On Tab Click, show the PVEFrame that is clicked
				tabButton:SetScript("OnClick", function()
					PVEFrame_ToggleFrame(VisiblePanels[i].frameName)
				end)
				-- Set placement of the tabs
				if self.ElvUIEnabled then
					self.S:HandleTab(AMT_Window_TabButton)
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", AMT_Window, "BOTTOMLEFT", -3, 0)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", -5, 0)
					end
				else
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", AMT_Window, "BOTTOMLEFT", 19, 2)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", 3, 0)
					end
				end
			end
		end
	end
	-- Set the proper sizes for each tab button and make AMT tab active
	for i = 1, #VisiblePanels do
		local AMTtab = _G["AMT_Window_Tab" .. i]
		local sideWidths = AMTtab.Left:GetWidth() + AMTtab.Right:GetWidth()
		local minWidth = minWidth or sideWidths

		PanelTemplates_TabResize(AMTtab, 0, nil, minWidth)

		if i == #AMT.PVEFrame_Panels then
			PanelTemplates_SelectTab(_G["AMT_Window_Tab" .. #AMT.PVEFrame_Panels])
		else
			PanelTemplates_DeselectTab(_G["AMT_Window_Tab" .. i])
		end
	end
	-- ===============================
	-- === AMT Window Title Set-up ===
	-- ===============================
	--Find out the current expansion and season information to format the title.
	local currentDisplaySeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	--Format the title of the tab to be "Advanced Mythic Tracker (Expansion Season #)"
	local currExpID = GetExpansionLevel()
	local expName = _G["EXPANSION_NAME" .. currExpID]
	local title = "Advanced Mythic Tracker (" .. expName .. " Season " .. currentDisplaySeason .. ")"
	AMT_WindowTitleText:SetText(title) --Set Window Title

	-- =================================
	-- === AMT Window Content Set-up ===
	-- ===    Top of frame = 22px    ===
	-- ===   Left side bleed = 4px   ===
	-- =================================
	local AMT_Window_X_Offset = 4
	local AMT_Window_Y_Offset = 22
	-- MARK: Create Weekly Best M+ Container
	local WeeklyBest_Compartment
	if not _G["AMT_WeeklyBest_Compartment"] then
		WeeklyBest_Compartment = CreateFrame("Frame", "AMT_WeeklyBest_Compartment", AMT_Window)
		WeeklyBest_Compartment:SetSize(180, 82)
		WeeklyBest_Compartment:SetPoint("TOPLEFT", AMT_Window, "TOPLEFT", AMT_Window_X_Offset, -AMT_Window_Y_Offset)
		WeeklyBest_Compartment.tex = WeeklyBest_Compartment:CreateTexture()
		WeeklyBest_Compartment.tex:SetAllPoints(WeeklyBest_Compartment)
		WeeklyBest_Compartment.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
	-- MARK: Create Current Keystone Compartment
	local CurrentKeystone_Compartment
	if not _G["AMT_CurrentKeystone_Compartment"] then
		CurrentKeystone_Compartment = CreateFrame("Frame", "AMT_CurrentKeystone_Compartment", AMT_Window)
		CurrentKeystone_Compartment:SetSize(180, 164)
		CurrentKeystone_Compartment:SetPoint("BOTTOMLEFT", AMT_Window, "BOTTOMLEFT", AMT_Window_X_Offset, 0)
		CurrentKeystone_Compartment.tex = CurrentKeystone_Compartment:CreateTexture()
		CurrentKeystone_Compartment.tex:SetAllPoints(CurrentKeystone_Compartment)
		CurrentKeystone_Compartment.tex:SetColorTexture(unpack(AMT.BackgroundClear))
		-- Create the Rune Art that'll house the Keystone Icon
		local RuneArt
		if not _G["AMT_RuneTexture"] then
			RuneArt = CreateFrame("Frame", "AMT_RuneTexture", CurrentKeystone_Compartment)
			RuneArt:SetPoint("BOTTOM", CurrentKeystone_Compartment, "BOTTOM", 0, 5)
			RuneArt:SetSize(155, 155)
			RuneArt.tex = RuneArt:CreateTexture()
			RuneArt.tex:SetAllPoints(RuneArt)
			RuneArt.tex:SetAtlas("Artifacts-CrestRune-Gold", false)
		end
	end
	-- MARK: Create Lockouts Compartment to show Vault Content Progress
	local Lockouts_Comparment
	if not _G["AMT_Lockouts_Comparment"] then
		Lockouts_Comparment = CreateFrame("Frame", "AMT_Lockouts_Comparment", AMT_Window)
		Lockouts_Comparment:SetSize(
			180,
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- WeeklyBest_Compartment:GetHeight()
				- CurrentKeystone_Compartment:GetHeight()
		)
		Lockouts_Comparment:SetPoint("TOP", WeeklyBest_Compartment, "BOTTOM", 0, 0)
		Lockouts_Comparment.tex = Lockouts_Comparment:CreateTexture()
		Lockouts_Comparment.tex:SetAllPoints(Lockouts_Comparment)
		Lockouts_Comparment.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
	-- MARK: Create Dungeons Icon Container
	local DungeonIcons_Container
	if not _G["AMT_DungeonIcons_Container"] then
		DungeonIcons_Container = CreateFrame("Frame", "AMT_DungeonIcons_Container", AMT_Window)
		DungeonIcons_Container:SetSize(
			AMT_Window:GetWidth() - AMT_Window_X_Offset - CurrentKeystone_Compartment:GetWidth(),
			90
		)
		DungeonIcons_Container:SetPoint("BOTTOMLEFT", CurrentKeystone_Compartment, "BOTTOMRIGHT", -1, 1)
		DungeonIcons_Container.tex = DungeonIcons_Container:CreateTexture()
		DungeonIcons_Container.tex:SetAllPoints(DungeonIcons_Container)
		DungeonIcons_Container.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
	-- MARK: Create Affixes Container
	local Affixes_Compartment
	if not _G["AMT_Affixes_Compartment"] then
		Affixes_Compartment = CreateFrame("Frame", "AMT_Affixes_Compartment", AMT_Window)
		Affixes_Compartment:SetSize(200, 150)
		Affixes_Compartment:SetPoint("TOPRIGHT", AMT_Window, "TOPRIGHT", -AMT_Window_X_Offset, -AMT_Window_Y_Offset)
		Affixes_Compartment.tex = Affixes_Compartment:CreateTexture()
		Affixes_Compartment.tex:SetAllPoints(Affixes_Compartment)
		Affixes_Compartment.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
	-- MARK: Create Party Keystone Container
	local PartyKeystone_Container
	if not _G["AMT_PartyKeystone_Container"] then
		PartyKeystone_Container = CreateFrame("Frame", "AMT_PartyKeystone_Container", AMT_Window)
		PartyKeystone_Container:SetSize(
			200,
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- Affixes_Compartment:GetHeight()
				- DungeonIcons_Container:GetHeight()
				- 12
		)
		if self.ElvUIEnabled then
			PartyKeystone_Container:SetTemplate("Transparent")
		else
			PartyKeystone_Container.tex = PartyKeystone_Container:CreateTexture()
			PartyKeystone_Container.tex:SetAllPoints(PartyKeystone_Container)
			PartyKeystone_Container.tex:SetColorTexture(unpack(AMT.BackgroundDark))
		end
		PartyKeystone_Container:SetPoint("TOPRIGHT", Affixes_Compartment, "BOTTOMRIGHT", 0, 0)
		-- Set the title text for the container
		local PartyKeystone_Container_Title = PartyKeystone_Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		PartyKeystone_Container_Title:SetPoint("TOPLEFT", PartyKeystone_Container, "TOPLEFT", 6, -6)
		PartyKeystone_Container_Title:SetJustifyH("LEFT")
		PartyKeystone_Container_Title:SetFont(PartyKeystone_Container_Title:GetFont(), 14)
		PartyKeystone_Container_Title:SetText("Party Keystones")
		-- Create the Party Keystone Buttons
		local PartyKeystone_DetailsButton
		local PartyKeystone_RefreshButton
		local PartyKeystone_RollButton
		if self.DetailsEnabled then
			if not _G["AMT_PartyKeystone_DetailsButton"] then
				PartyKeystone_DetailsButton = CreateFrame(
					"Button",
					"AMT_PartyKeystone_DetailsButton",
					PartyKeystone_Container,
					"UIPanelButtonTemplate"
				)
				if AMT.ElvUIEnabled then
					AMT.S:HandleButton(PartyKeystone_DetailsButton)
				end
				PartyKeystone_DetailsButton:SetSize(20, 16)
				PartyKeystone_DetailsButton:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -4, -4)
				PartyKeystone_DetailsButton:SetText("!")
				PartyKeystone_DetailsButton.Text:SetFont(PartyKeystone_DetailsButton.Text:GetFont(), 12)
			end
			PartyKeystone_DetailsButton:SetScript("OnClick", function()
				if _G.SlashCmdList["KEYSTONE"] then
					_G.SlashCmdList["KEYSTONE"]("")
				end
			end)
			if not _G["AMT_PartyKeystone_RefreshButton"] then
				PartyKeystone_RefreshButton = CreateFrame(
					"Button",
					"AMT_PartyKeystone_RefreshButton",
					PartyKeystone_Container,
					"UIPanelButtonTemplate"
				)
				if AMT.ElvUIEnabled then
					AMT.S:HandleButton(PartyKeystone_RefreshButton)
				end
				PartyKeystone_RefreshButton:SetSize(40, 16)
				PartyKeystone_RefreshButton:SetPoint("RIGHT", PartyKeystone_DetailsButton, "LEFT", -4, 0)
				PartyKeystone_RefreshButton:SetText("Refresh")
				PartyKeystone_RefreshButton.Text:SetFont(PartyKeystone_RefreshButton.Text:GetFont(), 12)
			end
			PartyKeystone_RefreshButton:SetScript("OnClick", function()
				if IsInGroup() and Details then
					self.OpenRaidLib.RequestKeystoneDataFromParty()
					C_Timer.After(0.5, function()
						AMT:AMT_PartyKeystone()
					end)
					C_Timer.After(2, function()
						AMT:AMT_PartyKeystone()
					end)
				end
			end)
			if not _G["AMT_PartyKeystone_RollButton"] then
				PartyKeystone_RollButton = CreateFrame(
					"Button",
					"AMT_PartyKeystone_RollButton",
					PartyKeystone_Container,
					"UIPanelButtonTemplate"
				)
				if AMT.ElvUIEnabled then
					AMT.S:HandleButton(PartyKeystone_RollButton)
				end
				PartyKeystone_RollButton:SetSize(40, 16)
				PartyKeystone_RollButton:SetPoint("RIGHT", PartyKeystone_RefreshButton, "LEFT", -4, 0)
				PartyKeystone_RollButton:SetText("Roll")
				PartyKeystone_RollButton.Text:SetFont(PartyKeystone_RollButton.Text:GetFont(), 12)
			end
			PartyKeystone_RollButton:SetScript("OnClick", function()
				if IsInGroup() and Details then
					print("Rolling Key")
				else
					print("Must be in a group with multiple keystones to roll")
				end
			end)
		else
			--If Details! is missing create the Missing Icon/Tooltip
			local PartyKeystyone_MissingDetails
			if not _G["AMT_PartyKeystyone_MissingDetails"] then
				PartyKeystyone_MissingDetails =
					CreateFrame("Frame", "AMT_PartyKeystyone_MissingDetails", PartyKeystone_Container)
				PartyKeystyone_MissingDetails:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -4, -4)
				PartyKeystyone_MissingDetails:SetSize(24, 24)
				PartyKeystyone_MissingDetails.tex = PartyKeystyone_MissingDetails:CreateTexture()
				PartyKeystyone_MissingDetails.tex:SetAllPoints(PartyKeystyone_MissingDetails)
				PartyKeystyone_MissingDetails.tex:SetAtlas("Campaign-QuestLog-LoreBook-Back", false)
			end
			PartyKeystyone_MissingDetails:SetScript("OnEnter", function()
				GameTooltip:ClearAllPoints()
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(PartyKeystyone_MissingDetails, "ANCHOR_RIGHT", 0, 0)
				GameTooltip:SetText("Details! Missing", 1, 1, 1, 1)
				GameTooltip:AddLine("To see a list of your group's Keystones,\ninstall/enable Details!.", true)
				GameTooltip:Show()
			end)
			PartyKeystyone_MissingDetails:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
	end
	-- MARK: Create M+ Score Container
	local MythicScore_Container
	if not _G["AMT_MythicScore_Container"] then
		MythicScore_Container = CreateFrame("Button", "AMT_MythicScore_Container", AMT_Window)
		MythicScore_Container:SetSize(180, 60)
		MythicScore_Container:SetPoint("TOP", AMT_Window, "TOP", 0, -AMT_Window_Y_Offset)
		MythicScore_Container.tex = MythicScore_Container:CreateTexture()
		MythicScore_Container.tex:SetAllPoints(MythicScore_Container)
		MythicScore_Container.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
	-- MARK: Create M+ Runs Graph Container
	local MythicRunsGraph_Container
	if not _G["AMT_MythicRunsGraph_Container"] then
		MythicRunsGraph_Container = CreateFrame("Frame", "AMT_MythicRunsGraph_Container", AMT_Window)
		MythicRunsGraph_Container:SetSize(
			AMT_Window:GetWidth()
				- AMT_Window_X_Offset * 2
				- Lockouts_Comparment:GetWidth()
				- PartyKeystone_Container:GetWidth(),
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- MythicScore_Container:GetHeight()
				- DungeonIcons_Container:GetHeight()
				- 12
		)
		MythicRunsGraph_Container:SetPoint("TOP", MythicScore_Container, "BOTTOM", -AMT_Window_X_Offset * 2 - 2, 0)
		MythicRunsGraph_Container.tex = MythicRunsGraph_Container:CreateTexture()
		MythicRunsGraph_Container.tex:SetAllPoints(MythicRunsGraph_Container)
		MythicRunsGraph_Container.tex:SetColorTexture(unpack(AMT.BackgroundClear))
	end
end
