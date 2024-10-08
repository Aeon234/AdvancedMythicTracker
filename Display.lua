local addonName, AMT = ...

-- ==================================
-- === Complete AMT_Window Set-up ===
-- ==================================

function AMT:AMT_Creation()
	local AMT_Window = _G["AMT_Window"]

	-- ==============================
	-- === AMT Window Tabs Set-up ===
	-- ==============================
	AMT:Update_PVEFrame_Panels()
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

		if i == #self.PVEFrame_Panels then
			PanelTemplates_SelectTab(_G["AMT_Window_Tab" .. #self.PVEFrame_Panels])
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
	-- MARK: Create Current Keystone Compartment
	local CurrentKeystone_Compartment
	if not _G["AMT_CurrentKeystone_Compartment"] then
		CurrentKeystone_Compartment = CreateFrame("Frame", "AMT_CurrentKeystone_Compartment", AMT_Window)
		CurrentKeystone_Compartment:SetSize(180, 100)
		CurrentKeystone_Compartment:SetPoint(
			"TOPLEFT",
			AMT_Window,
			"TOPLEFT",
			AMT_Window_X_Offset,
			-AMT_Window_Y_Offset
		)
		CurrentKeystone_Compartment.tex = CurrentKeystone_Compartment:CreateTexture()
		CurrentKeystone_Compartment.tex:SetAllPoints(CurrentKeystone_Compartment)
		CurrentKeystone_Compartment.tex:SetColorTexture(unpack(self.BackgroundClear))

		--Create the frame which will contain the icon texture of the Keystone
		local KeystoneItem_Icon = CreateFrame("Frame", "AMT_KeystoneItem_Icon", CurrentKeystone_Compartment)
		KeystoneItem_Icon:SetPoint("TOP", 0, -30)
		KeystoneItem_Icon.tex = KeystoneItem_Icon:CreateTexture()
		-- KeystoneItem_Icon.tex:SetTexCoord(0.02, 0.98, 0.02, 0.98)
		KeystoneItem_Icon.tex:SetAllPoints(KeystoneItem_Icon)
		--Create the Glow Texture that will exist around the Keystone Icon
		local KeystoneItem_Glow = CreateFrame("Frame", "AMT_KeystoneItem_Glow", CurrentKeystone_Compartment)
		KeystoneItem_Glow:SetPoint("TOP", 0, -12)
		KeystoneItem_Glow:SetSize(96, 96)
		KeystoneItem_Glow:SetFrameLevel(5)
		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetSize(78, 78)
		KeystoneItem_Glow.tex:SetAllPoints(KeystoneItem_Glow)
		--Create the label for Keystone's Dungeon Name Background
		local Keystone_DungName_Bg = CreateFrame("Frame", "AMT_Keystone_DungName_Bg", CurrentKeystone_Compartment)
		Keystone_DungName_Bg:SetPoint("BOTTOM", KeystoneItem_Icon, "TOP", 0, 6)
		Keystone_DungName_Bg:SetSize(120, 22) --76
		Keystone_DungName_Bg.tex = Keystone_DungName_Bg:CreateTexture(nil, "ARTWORK")
		-- Keystone_DungName_Bg.tex:SetAtlas("AftLevelup-ToastBG")
		Keystone_DungName_Bg.tex:SetAtlas("minortalents-descriptionshadow")
		Keystone_DungName_Bg.tex:SetSize(1, 1)
		Keystone_DungName_Bg.tex:SetAllPoints(Keystone_DungName_Bg)
		-- Keystone_DungName_Bg.tex:SetColorTexture(0, 0, 0, 0.75)
		--Create the label for Keystone's Dungeon Name Label
		local Keystone_DungName =
			Keystone_DungName_Bg:CreateFontString("AMT_Keystone_DungName", "OVERLAY", "MovieSubtitleFont")
		Keystone_DungName:SetPoint("CENTER", Keystone_DungName_Bg, "CENTER", 0, 0)
		Keystone_DungName:SetFont(self.AMT_Font, 14)
		Keystone_DungName:SetText("Key Missing")

		-- MARK: Create the Great Vault Button
		local GreatVault_Button = CreateFrame("Button", "AMT_GreatVault_Button", AMT_Window)
		GreatVault_Button:SetPoint("TOP", KeystoneItem_Icon, "BOTTOM", 0, -200)
		GreatVault_Button:SetSize(74, 22)
		GreatVault_Button:SetText("Open Vault")
		GreatVault_Button_bg = GreatVault_Button:CreateTexture(nil, "ARTWORK")
		GreatVault_Button_bg:SetAllPoints(GreatVault_Button)
		GreatVault_Button_bg:SetColorTexture(0, 0, 0, 1)
		-- Create the font string and attach it to the button
		local GreatVault_Buttonlabel =
			GreatVault_Button:CreateFontString("AMT_GreatVault_Buttonlabel", "OVERLAY", "MovieSubtitleFont")
		GreatVault_Buttonlabel:SetPoint("CENTER", GreatVault_Button, "CENTER", 0, 0) -- Center the text on the button
		GreatVault_Buttonlabel:SetFont(self.AMT_Font, 12, "OUTLINE")
		GreatVault_Buttonlabel:SetText(" Open Vault")

		-- Create border textures
		local GreatVault_Button_borderTop = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderTop:SetHeight(1)
		GreatVault_Button_borderTop:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderTop:SetPoint("TOPLEFT", GreatVault_Button, "TOPLEFT", -1, 1)
		GreatVault_Button_borderTop:SetPoint("TOPRIGHT", GreatVault_Button, "TOPRIGHT", 1, 1)

		local GreatVault_Button_borderBottom = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderBottom:SetHeight(1)
		GreatVault_Button_borderBottom:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderBottom:SetPoint("BOTTOMLEFT", GreatVault_Button, "BOTTOMLEFT", -1, -1)
		GreatVault_Button_borderBottom:SetPoint("BOTTOMRIGHT", GreatVault_Button, "BOTTOMRIGHT", 1, -1)

		local GreatVault_Button_borderLeft = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderLeft:SetWidth(1)
		GreatVault_Button_borderLeft:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderLeft:SetPoint("TOPLEFT", GreatVault_Button, "TOPLEFT", -1, 1)
		GreatVault_Button_borderLeft:SetPoint("BOTTOMLEFT", GreatVault_Button, "BOTTOMLEFT", -1, -1)

		local GreatVault_Button_borderRight = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderRight:SetWidth(1)
		GreatVault_Button_borderRight:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderRight:SetPoint("TOPRIGHT", GreatVault_Button, "TOPRIGHT", 1, 1)
		GreatVault_Button_borderRight:SetPoint("BOTTOMRIGHT", GreatVault_Button, "BOTTOMRIGHT", 1, -1)

		-- Hide the border by default
		GreatVault_Button_borderTop:Hide()
		GreatVault_Button_borderBottom:Hide()
		GreatVault_Button_borderLeft:Hide()
		GreatVault_Button_borderRight:Hide()

		GreatVault_Button:SetScript("OnEnter", function()
			GreatVault_Button_borderTop:Show()
			GreatVault_Button_borderBottom:Show()
			GreatVault_Button_borderLeft:Show()
			GreatVault_Button_borderRight:Show()
		end)

		GreatVault_Button:SetScript("OnLeave", function()
			GreatVault_Button_borderTop:Hide()
			GreatVault_Button_borderBottom:Hide()
			GreatVault_Button_borderLeft:Hide()
			GreatVault_Button_borderRight:Hide()
		end)

		GreatVault_Button:SetScript("OnClick", function()
			C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
			if not WeeklyRewardsFrame:IsVisible() then
				WeeklyRewardsFrame:Show()
			else
				WeeklyRewardsFrame:Hide()
			end
		end)
	end
	-- MARK: Create Lockouts Compartment to show Vault Content Progress
	local Lockouts_Comparment
	if not _G["AMT_Lockouts_Comparment"] then
		Lockouts_Comparment = CreateFrame("Frame", "AMT_Lockouts_Comparment", AMT_Window)
		Lockouts_Comparment:SetSize(
			180,
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- CurrentKeystone_Compartment:GetHeight()
				- CurrentKeystone_Compartment:GetHeight()
		)
		Lockouts_Comparment:SetPoint("TOP", CurrentKeystone_Compartment, "BOTTOM", 0, 0)
		Lockouts_Comparment.tex = Lockouts_Comparment:CreateTexture()
		Lockouts_Comparment.tex:SetAllPoints(Lockouts_Comparment)
		Lockouts_Comparment.tex:SetColorTexture(unpack(self.BackgroundClear))

		--Create the Raid Header
		local Raid_Goals_Header = CreateFrame("Frame", "AMT_Raid_Goals_Header", Lockouts_Comparment)
		Raid_Goals_Header:SetSize(180, 18)
		Raid_Goals_Header:SetPoint("TOP", Lockouts_Comparment, "TOP", 0, -2)
		Raid_Goals_Header.tex = Raid_Goals_Header:CreateTexture()
		Raid_Goals_Header.tex:SetAllPoints(Raid_Goals_Header)
		Raid_Goals_Header.tex:SetColorTexture(unpack(self.BackgroundClear))
		--Create the Raid Label Text
		local WeeklyRaid_Label = Raid_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyRaid_Label:SetPoint("TOP", Raid_Goals_Header, "TOP", 0, 0)
		WeeklyRaid_Label:SetText("Raid")
		WeeklyRaid_Label:SetFont(self.AMT_Font, 14)

		--Create the frames that will store the boxes for each difficulty, running through each difficulty level for the current season's Raid
		local Raid_MainFrame = {}
		local Raid_MainFrame_LabelFrame = {}
		local RaidDifficulty_Label = {}
		local Raid_MainFrame_BoxFrame = {}
		for i, difficulty in ipairs(self.RaidDifficulty_Levels) do
			-- Create the Frames for each difficulty
			Raid_MainFrame[i] = CreateFrame("Frame", "AMT_RaidDifficulty" .. i, Lockouts_Comparment)
			Raid_MainFrame[i]:SetSize(180, 20)
			Raid_MainFrame[i].tex = Raid_MainFrame[i]:CreateTexture()
			Raid_MainFrame[i].tex:SetAllPoints(Raid_MainFrame[i])
			Raid_MainFrame[i].tex:SetColorTexture(unpack(self.BackgroundClear))

			-- Create the frame that will hold the boxes for each difficulty
			Raid_MainFrame_BoxFrame[i] = CreateFrame("Frame", "AMT_Raid_MainFrame_BoxFrame" .. i, Raid_MainFrame[i])
			Raid_MainFrame_BoxFrame[i]:SetSize(180, 22)
			Raid_MainFrame_BoxFrame[i]:SetPoint("CENTER", Raid_MainFrame[i], "CENTER", 0, 0)
			Raid_MainFrame_BoxFrame[i].tex = Raid_MainFrame_BoxFrame[i]:CreateTexture()
			Raid_MainFrame_BoxFrame[i].tex:SetAllPoints(Raid_MainFrame_BoxFrame[i])
			Raid_MainFrame_BoxFrame[i].tex:SetColorTexture(unpack(self.BackgroundClear))
			-- Set the position of each frame
			if i == 1 then
				Raid_MainFrame[i]:SetPoint("TOPLEFT", Raid_Goals_Header, "BOTTOMLEFT", 4, 4)
			else
				local previousFrame = _G["AMT_RaidDifficulty" .. (i - 1)]
				Raid_MainFrame[i]:SetPoint("TOP", previousFrame, "BOTTOM", 0, 0)
			end
			local Raid_BoxMargin = (
				Raid_MainFrame[1]:GetWidth()
				- ((self.Vault_BoxSize * self.Vault_RaidReq) + (3 * (self.Vault_RaidReq - 1)))
			) / 2
			-- Create the Frame that will house the label for the difficulty
			Raid_MainFrame_LabelFrame[i] =
				CreateFrame("Frame", "AMT_Raid_MainFrame_Label" .. i, _G["AMT_RaidDifficulty" .. i])
			Raid_MainFrame_LabelFrame[i]:SetSize(42, 22)
			Raid_MainFrame_LabelFrame[i]:SetPoint(
				"RIGHT",
				_G["AMT_Raid_MainFrame_BoxFrame" .. i],
				"LEFT",
				Raid_BoxMargin,
				0
			)
			Raid_MainFrame_LabelFrame[i].tex = Raid_MainFrame_LabelFrame[i]:CreateTexture()
			Raid_MainFrame_LabelFrame[i].tex:SetAllPoints(Raid_MainFrame_LabelFrame[i])
			Raid_MainFrame_LabelFrame[i].tex:SetColorTexture(unpack(self.BackgroundClear))

			-- Create the label for the difficulty
			RaidDifficulty_Label[i] = Raid_MainFrame_LabelFrame[i]:CreateFontString(
				"AMT_RaidDifficulty_Label" .. i,
				"OVERLAY",
				"MovieSubtitleFont"
			)
			RaidDifficulty_Label[i]:SetPoint("RIGHT", Raid_MainFrame_LabelFrame[i], "RIGHT", 0, 0)
			RaidDifficulty_Label[i]:SetText("|cffffffff" .. difficulty.abbr)
			RaidDifficulty_Label[i]:SetFont(self.AMT_Font, 12)
			RaidDifficulty_Label[i]:SetJustifyH("RIGHT")
			RaidDifficulty_Label[i]:SetJustifyV("MIDDLE")
			Raid_MainFrame[i]:SetScript("OnEnter", function()
				GameTooltip:ClearAllPoints()
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(Raid_MainFrame[i], "ANCHOR_RIGHT")
				GameTooltip:SetText(difficulty.name .. " Progress", 1, 1, 1, 1, true)
				Raid_LockoutInfo = AMT:Filter_LockedBosses(self.SeasonalRaids, difficulty.abbr)
				for index, encounter in ipairs(self.RaidVault_Bosses) do
					local name, description, encounterID, rootSectionID, link, instanceID =
						EJ_GetEncounterInfo(encounter.encounterID)
					if instanceID ~= lastInstanceID then
						local instanceName = EJ_GetInstanceInfo(instanceID)
						GameTooltip_AddBlankLineToTooltip(GameTooltip)
						GameTooltip:AddLine(instanceName)
						lastInstanceID = instanceID
					end
					if name then
						local killed = AMT:Check_BossLockout(Raid_LockoutInfo, name)
						if killed then
							local completedDifficultyName = DifficultyUtil.GetDifficultyName(encounter.bestDifficulty)
							GameTooltip_AddColoredLine(
								GameTooltip,
								string.format(DASH_WITH_TEXT, name),
								GREEN_FONT_COLOR
							)
						else
							GameTooltip_AddColoredLine(
								GameTooltip,
								string.format(DASH_WITH_TEXT, name),
								DISABLED_FONT_COLOR
							)
						end
					end
				end
				GameTooltip:Show()
				Raid_MainFrame[i].tex:SetColorTexture(unpack(self.BackgroundHover))
			end)
			Raid_MainFrame[i]:SetScript("OnLeave", function()
				GameTooltip:Hide()
				Raid_MainFrame[i].tex:SetColorTexture(unpack(self.BackgroundClear))
			end)
		end
		--Create the boxes within the frames for each difficulty
		local Raid_BoxSpacing = 3
		local Raid_BoxMargin = (
			Raid_MainFrame[1]:GetWidth()
			- ((self.Vault_BoxSize * self.Vault_RaidReq) + (Raid_BoxSpacing * (self.Vault_RaidReq - 1)))
		) / 2
		for i, difficulty in ipairs(self.RaidDifficulty_Levels) do
			local DifficultyName = difficulty.abbr
			local RaidBox = {}
			for n = 1, self.Vault_RaidReq do
				RaidBox[i] = CreateFrame("Frame", "AMT_" .. DifficultyName .. n, _G["AMT_RaidDifficulty" .. i])
				RaidBox[i]:SetSize(self.Vault_BoxSize, self.Vault_BoxSize)
				RaidBox[i].tex = RaidBox[i]:CreateTexture()
				RaidBox[i].tex:SetAllPoints(RaidBox[i])
				RaidBox[i].tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)
				if n == 1 then
					RaidBox[i]:SetPoint("LEFT", _G["AMT_Raid_MainFrame_BoxFrame" .. i], "LEFT", Raid_BoxMargin, 0)
				else
					local previousBox = _G["AMT_" .. DifficultyName .. (n - 1)]
					RaidBox[i]:SetPoint("LEFT", previousBox, "RIGHT", Raid_BoxSpacing, 0)
				end
			end
		end
		--Create the M+ Header Container
		local Mplus_Goals_Header = CreateFrame("Frame", "AMT_Mplus_Goals_Header", Lockouts_Comparment)
		Mplus_Goals_Header:SetSize(180, 18)
		Mplus_Goals_Header:SetPoint("TOP", _G["AMT_RaidDifficulty4"], "BOTTOM", 0, 0)
		Mplus_Goals_Header.tex = Mplus_Goals_Header:CreateTexture()
		Mplus_Goals_Header.tex:SetAllPoints(Mplus_Goals_Header)
		Mplus_Goals_Header.tex:SetColorTexture(unpack(self.BackgroundClear))

		--Create the M+ Section Label
		local WeeklyMplus_Label = Mplus_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyMplus_Label:SetPoint("TOP", Mplus_Goals_Header, "TOP", 0, -2)
		WeeklyMplus_Label:SetText("Mythic+")
		WeeklyMplus_Label:SetFont(self.AMT_Font, 14)

		--Create the Mythic Plus Main Frame that will house the label and the boxes
		local Mplus_Mainframe = CreateFrame("Frame", "AMT_Mplus_Mainframe", Lockouts_Comparment)
		Mplus_Mainframe:SetSize(180, 22)
		Mplus_Mainframe:SetPoint("TOPLEFT", Mplus_Goals_Header, "BOTTOMLEFT", 0, 0)
		Mplus_Mainframe.tex = Mplus_Mainframe:CreateTexture()
		Mplus_Mainframe.tex:SetAllPoints(Mplus_Mainframe)
		Mplus_Mainframe.tex:SetColorTexture(unpack(self.BackgroundClear))

		--Create the M+ Boxes Container
		local Mplus_MainFrame_BoxFrame = CreateFrame("Frame", "AMT_Mplus_MainFrame_BoxFrame", Mplus_Mainframe)
		Mplus_MainFrame_BoxFrame:SetSize(180, 22)
		Mplus_MainFrame_BoxFrame:SetPoint("CENTER", Mplus_Mainframe, "CENTER", 0, 0)
		Mplus_MainFrame_BoxFrame.tex = Mplus_MainFrame_BoxFrame:CreateTexture()
		Mplus_MainFrame_BoxFrame.tex:SetAllPoints(Mplus_MainFrame_BoxFrame)
		Mplus_MainFrame_BoxFrame.tex:SetColorTexture(unpack(self.BackgroundClear))
		--Set up the Tooltip info for M+
		Mplus_Mainframe:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(Mplus_Mainframe, "ANCHOR_RIGHT")
			GameTooltip:SetText("Mythic Plus Progress", 1, 1, 1, 1, true)
			if self.KeysDone[1] ~= 0 then
				GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", #self.KeysDone))
			else
				GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", 0))
			end
			if self.KeysDone[1] ~= 0 then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Top 8 Runs This Week")
				for i = 1, 8 do
					if self.KeysDone[i] and (i == 1 or i == 4 or i == 8) then
						GameTooltip:AddLine("|cff00ff12" .. self.KeysDone[i].level .. " - " .. self.KeysDone[i].keyname)
					elseif self.KeysDone[i] then
						GameTooltip:AddLine("|cffffffff" .. self.KeysDone[i].level .. " - " .. self.KeysDone[i].keyname)
					end
				end
			end
			Mplus_Mainframe.tex:SetColorTexture(unpack(self.BackgroundHover))
			GameTooltip:Show()
		end)
		Mplus_Mainframe:SetScript("OnLeave", function()
			GameTooltip:Hide()
			Mplus_Mainframe.tex:SetColorTexture(unpack(self.BackgroundClear))
		end)

		--Create the M+ Boxes
		local Mplus_Box = {}
		local Mplus_BoxSpacing = 3
		local Mplus_BoxMargin = (
			Mplus_Mainframe:GetWidth()
			- ((self.Vault_BoxSize * self.Vault_DungeonReq) + (Mplus_BoxSpacing * (self.Vault_DungeonReq - 1)))
		) / 2
		for i = 1, self.Vault_DungeonReq do
			Mplus_Box[i] = CreateFrame("Frame", "AMT_Mplus_Box" .. i, Mplus_MainFrame_BoxFrame)
			Mplus_Box[i]:SetSize(self.Vault_BoxSize, self.Vault_BoxSize)
			Mplus_Box[i].tex = Mplus_Box[i]:CreateTexture()
			Mplus_Box[i].tex:SetAllPoints(Mplus_Box[i])
			Mplus_Box[i].tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

			if i == 1 then
				Mplus_Box[i]:SetPoint("LEFT", Mplus_MainFrame_BoxFrame, "LEFT", Mplus_BoxMargin, 0)
			else
				local previousBox = _G["AMT_Mplus_Box" .. (i - 1)]
				Mplus_Box[i]:SetPoint("LEFT", previousBox, "RIGHT", Mplus_BoxSpacing, 0)
			end
		end
	end
	-- MARK: Create World Container
	--Create the World Activities Header Container
	local World_Goals_Header = CreateFrame("Frame", "AMT_World_Goals_Header", Lockouts_Comparment)
	World_Goals_Header:SetSize(180, 18)
	World_Goals_Header:SetPoint("TOP", _G["AMT_Mplus_Mainframe"], "BOTTOM", 0, 0)
	World_Goals_Header.tex = World_Goals_Header:CreateTexture()
	World_Goals_Header.tex:SetAllPoints(World_Goals_Header)
	World_Goals_Header.tex:SetColorTexture(unpack(self.BackgroundClear))

	--Create the World Activities Section Label
	local WeeklyWorld_Label = World_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	WeeklyWorld_Label:SetPoint("TOP", World_Goals_Header, "TOP", 0, 0)
	WeeklyWorld_Label:SetText("World")
	WeeklyWorld_Label:SetFont(self.AMT_Font, 14)

	--Create the World Activities Main Frame that will house the label and the boxes
	local World_Mainframe = CreateFrame("Frame", "AMT_World_Mainframe", Lockouts_Comparment)
	World_Mainframe:SetSize(180, 22)
	World_Mainframe:SetPoint("TOPLEFT", World_Goals_Header, "BOTTOMLEFT", 0, 2)
	World_Mainframe.tex = World_Mainframe:CreateTexture()
	World_Mainframe.tex:SetAllPoints(World_Mainframe)
	World_Mainframe.tex:SetColorTexture(unpack(self.BackgroundClear))

	--Create the World Activities Boxes Container
	local World_Mainframe_BoxFrame = CreateFrame("Frame", "AMT_World_Mainframe_BoxFrame", World_Mainframe)
	World_Mainframe_BoxFrame:SetSize(180, 22)
	World_Mainframe_BoxFrame:SetPoint("CENTER", World_Mainframe, "CENTER", 0, 0)
	World_Mainframe_BoxFrame.tex = World_Mainframe_BoxFrame:CreateTexture()
	World_Mainframe_BoxFrame.tex:SetAllPoints(World_Mainframe_BoxFrame)
	World_Mainframe_BoxFrame.tex:SetColorTexture(unpack(self.BackgroundClear))

	--Set up the Tooltip info for World Activities
	World_Mainframe:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(World_Mainframe, "ANCHOR_RIGHT")
		GameTooltip:SetText("Delves and World Activities", 1, 1, 1, 1, true)
		if self.KeysDone[1] ~= 0 then
			GameTooltip:AddLine(
				format("Number of Delves and World Activities done this week: |cffffffff%s|r", self.World_VaultTracker)
			)
		else
			GameTooltip:AddLine(format("Number of Delves and World Activities done this week: |cffffffff%s|r", 0))
		end
		-- if self.KeysDone[1] ~= 0 then
		-- 	GameTooltip:AddLine(" ")
		-- 	GameTooltip:AddLine("Top 8 Runs This Week")
		-- 	for i = 1, 8 do
		-- 		if self.KeysDone[i] and (i == 1 or i == 4 or i == 8) then
		-- 			GameTooltip:AddLine("|cff00ff12" .. self.KeysDone[i].level .. " - " .. self.KeysDone[i].keyname)
		-- 		elseif self.KeysDone[i] then
		-- 			GameTooltip:AddLine("|cffffffff" .. self.KeysDone[i].level .. " - " .. self.KeysDone[i].keyname)
		-- 		end
		-- 	end
		-- end
		World_Mainframe.tex:SetColorTexture(unpack(self.BackgroundHover))
		GameTooltip:Show()
	end)
	World_Mainframe:SetScript("OnLeave", function()
		GameTooltip:Hide()
		World_Mainframe.tex:SetColorTexture(unpack(self.BackgroundClear))
	end)

	--Create the World Boxes
	local World_Box = {}
	local World_BoxSpacing = 3
	local World_BoxMargin = (
		World_Mainframe:GetWidth()
		- ((self.Vault_BoxSize * self.Vault_WorldReq) + (World_BoxSpacing * (self.Vault_WorldReq - 1)))
	) / 2
	for i = 1, self.Vault_WorldReq do
		World_Box[i] = CreateFrame("Frame", "AMT_World_Box" .. i, World_Mainframe_BoxFrame)
		World_Box[i]:SetSize(self.Vault_BoxSize, self.Vault_BoxSize)
		World_Box[i].tex = World_Box[i]:CreateTexture()
		World_Box[i].tex:SetAllPoints(World_Box[i])
		World_Box[i].tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

		if i == 1 then
			World_Box[i]:SetPoint("LEFT", World_Mainframe_BoxFrame, "LEFT", World_BoxMargin, 0)
		else
			local previousBox = _G["AMT_World_Box" .. (i - 1)]
			World_Box[i]:SetPoint("LEFT", previousBox, "RIGHT", World_BoxSpacing, 0)
		end
	end

	-- MARK: Create Dungeons Icon Container
	local DungeonIcons_Container
	if not _G["AMT_DungeonIcons_Container"] then
		local Container_Margin = AMT_Window_X_Offset - 2
		DungeonIcons_Container = CreateFrame("Frame", "AMT_DungeonIcons_Container", AMT_Window)
		if self.ElvUIEnabled then
			DungeonIcons_Container:SetSize(AMT_Window:GetWidth() - Container_Margin * 5, 80)
		else
			DungeonIcons_Container:SetSize(AMT_Window:GetWidth() - Container_Margin * 4, 80)
		end
		DungeonIcons_Container:SetPoint("BOTTOMLEFT", AMT_Window, "BOTTOMLEFT", AMT_Window_X_Offset + 2, 4)
		DungeonIcons_Container.tex = DungeonIcons_Container:CreateTexture()
		DungeonIcons_Container.tex:SetAllPoints(DungeonIcons_Container)
		DungeonIcons_Container.tex:SetColorTexture(unpack(self.BackgroundHover))

		-- Create the icon for each dungeon
		local DungIcon = {}
		for i = 1, #self.Current_SeasonalDung_Info do
			local DungIconWidth = DungeonIcons_Container:GetWidth() / 8
			local DungIconHeight = DungeonIcons_Container:GetHeight()
			local DungIconAspectRatio = DungIconWidth / DungIconHeight

			local DungIconSize = math.max(DungIconHeight, DungIconWidth)
			local DungIconMargin = (DungIconSize - math.min(DungIconHeight, DungIconWidth)) / 2
			local DungIconCrop = DungIconMargin / DungIconSize
			DungIcon[i] =
				CreateFrame("Button", "AMT_DungeonIcon_" .. i, DungeonIcons_Container, "InsecureActionButtonTemplate")
			DungIcon[i]:SetSize(DungIconWidth, DungIconHeight)

			DungIcon.tex = DungIcon[i]:CreateTexture(nil, "BACKGROUND")
			DungIcon.tex:SetTexture(self.Current_SeasonalDung_Info[i].dungIcon)
			if DungIconAspectRatio > 1 then
				DungIcon.tex:SetTexCoord(0, 1, DungIconCrop, 1 - DungIconCrop)
			elseif DungIconAspectRatio < 1 then
				DungIcon.tex:SetTexCoord(DungIconCrop, 1 - DungIconCrop, 0, 1)
			end

			DungIcon.tex:SetSize(DungIconSize, DungIconSize)

			DungIcon.tex:ClearAllPoints()
			DungIcon.tex:SetAllPoints(DungIcon[i])

			if i == 1 then
				DungIcon[i]:SetPoint("BOTTOMLEFT", DungeonIcons_Container, "BOTTOMLEFT", 0, 0)
			else
				local previousBox = _G["AMT_DungeonIcon_" .. (i - 1)]
				DungIcon[i]:SetPoint("LEFT", previousBox, "RIGHT", 0, 0)
			end
		end
		-- Create Name Labels over the Dungeon Icons
		for i = 1, #self.Current_SeasonalDung_Info do
			CurrentmapID = self.Current_SeasonalDung_Info[i].mapID
			DungIcon_Abbr = nil

			for j = 1, #self.SeasonalDungeons do
				if self.SeasonalDungeons[j].mapID == CurrentmapID then
					DungIcon_Abbr = self.SeasonalDungeons[j].abbr
					break -- Exit loop once a match is found
				end
			end
			local DungIconName_Label = DungIcon[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
			DungIconName_Label:SetPoint("TOP", _G["AMT_DungeonIcon_" .. i], "TOP", 0, 0)
			DungIconName_Label:SetFont(self.AMT_Font, 20, "OUTLINE")
			DungIconName_Label:SetTextColor(1, 1, 1)
			DungIconName_Label:SetText(DungIcon_Abbr)
		end
		-- Create the label for highest dungeon level done for either Fort/Tyr (depending on what week it is)
		for i = 1, #self.Current_SeasonalDung_Info do
			local DungWeekLevel_Label =
				DungIcon[i]:CreateFontString("AMT_DungWeekLevel_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungWeekLevel_Label:SetPoint("CENTER", _G["AMT_DungeonIcon_" .. i], "CENTER", 0, 2)
			DungWeekLevel_Label:SetFont(self.AMT_Font, 32, "OUTLINE")
			DungWeekLevel_Label:SetTextColor(1, 1, 1)
			DungWeekLevel_Label:SetText("20")

			local DungWeekScore_Label =
				DungIcon[i]:CreateFontString("AMT_DungWeekScore_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungWeekScore_Label:SetPoint("BOTTOM", _G["AMT_DungeonIcon_" .. i], "BOTTOM", 0, 4)
			DungWeekScore_Label:SetFont(self.AMT_Font, 18, "OUTLINE")
			DungWeekScore_Label:SetTextColor(1, 1, 1)
			DungWeekScore_Label:SetText("174.5")
		end
		for i = 1, #self.Current_SeasonalDung_Info do
			local DungIcon = _G["AMT_DungeonIcon_" .. i]
			local DungName = self.Current_SeasonalDung_Info[i].dungName
			local DungOverallScore = self.Current_SeasonalDung_Info[i].dungOverallScore
			local inTimeInfo = self.Current_SeasonalDung_Info[i].intimeInfo
			local overtimeInfo = self.Current_SeasonalDung_Info[i].overtimeInfo
			local affixScores, _ =
				C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(self.Current_SeasonalDung_Info[i].mapID)
			local dungSpellID
			local dungSpellName
			for _, dungeons in ipairs(self.SeasonalDungeons) do
				if dungeons.mapID == self.Current_SeasonalDung_Info[i].mapID then
					dungSpellID = dungeons.spellID
					dungSpellName = C_Spell.GetSpellName(dungSpellID)
				end
			end

			DungIcon:SetScript("OnEnter", function()
				GameTooltip:ClearAllPoints()
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(DungIcon, "ANCHOR_RIGHT")
				GameTooltip:SetText(DungName, 1, 1, 1, 1, true)

				if DungOverallScore and (inTimeInfo or overtimeInfo) then
					local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(DungOverallScore)
					if not color then
						color = HIGHLIGHT_FONT_COLOR
					end
					GameTooltip_AddNormalLine(
						GameTooltip,
						DUNGEON_SCORE_TOTAL_SCORE:format(color:WrapTextInColorCode(DungOverallScore)),
						GREEN_FONT_COLOR
					)
				end

				if affixScores and #affixScores > 0 then
					for _, affixInfo in ipairs(affixScores) do
						GameTooltip_AddBlankLineToTooltip(GameTooltip)
						GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_BEST_AFFIX:format(affixInfo.name))
						GameTooltip_AddColoredLine(
							GameTooltip,
							MYTHIC_PLUS_POWER_LEVEL:format(affixInfo.level),
							HIGHLIGHT_FONT_COLOR
						)
						if affixInfo.overTime then
							if affixInfo.durationSec >= SECONDS_PER_HOUR then
								GameTooltip_AddColoredLine(
									GameTooltip,
									DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(affixInfo.durationSec, true)),
									LIGHTGRAY_FONT_COLOR
								)
							else
								GameTooltip_AddColoredLine(
									GameTooltip,
									DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(affixInfo.durationSec, false)),
									LIGHTGRAY_FONT_COLOR
								)
							end
						else
							if affixInfo.durationSec >= SECONDS_PER_HOUR then
								GameTooltip_AddColoredLine(
									GameTooltip,
									SecondsToClock(affixInfo.durationSec, true),
									HIGHLIGHT_FONT_COLOR
								)
							else
								GameTooltip_AddColoredLine(
									GameTooltip,
									SecondsToClock(affixInfo.durationSec, false),
									HIGHLIGHT_FONT_COLOR
								)
							end
						end
					end
				end
				if IsSpellKnown(dungSpellID, false) then
					local spellCooldownInfo = C_Spell.GetSpellCooldown(dungSpellID)

					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)

					if not spellCooldownInfo.startTime or not spellCooldownInfo.duration then
						GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
					elseif spellCooldownInfo.duration == 0 then
						GameTooltip:AddLine(READY, 0, 1, 0)
					else
						GameTooltip:AddLine(
							SecondsToTime(ceil(spellCooldownInfo.startTime + spellCooldownInfo.duration - GetTime())),
							1,
							0,
							0
						)
					end
				else
					GameTooltip:AddLine(" ")
					GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)
					GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
				end
				GameTooltip:Show()
			end)
			DungIcon:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			DungIcon:RegisterForClicks("AnyUp", "AnyDown")
			DungIcon:SetAttribute("type1", "spell")
			DungIcon:SetAttribute("spell", dungSpellName)
		end
	end
	-- MARK: Create Affixes Container
	local Affixes_Compartment
	if not _G["AMT_Affixes_Compartment"] then
		Affixes_Compartment = CreateFrame("Frame", "AMT_Affixes_Compartment", AMT_Window)
		Affixes_Compartment:SetSize(200, 150)
		Affixes_Compartment:SetPoint("TOPRIGHT", AMT_Window, "TOPRIGHT", -AMT_Window_X_Offset, -AMT_Window_Y_Offset)
		Affixes_Compartment.tex = Affixes_Compartment:CreateTexture()
		Affixes_Compartment.tex:SetAllPoints(Affixes_Compartment)
		Affixes_Compartment.tex:SetColorTexture(unpack(self.BackgroundClear))
		-- Create this week's Label
		local CurrentAffixes_Label =
			Affixes_Compartment:CreateFontString("AMT_CurrentAffixes_Label", "OVERLAY", "GameFontHighlightOutline22")
		CurrentAffixes_Label:SetPoint("TOPLEFT", 2, -2) -- Set the position of the text
		CurrentAffixes_Label:SetText("This Week") -- Set the text content
		CurrentAffixes_Label:SetFont(self.AMT_Font, 20)
		CurrentAffixes_Label:SetTextColor(1, 1, 1, 1.0)

		-- Create Current Affixes Container
		local CurrentAffixes_Container = CreateFrame("Frame", "AMT_CurrentAffixes_Container", Affixes_Compartment)
		CurrentAffixes_Container:SetSize(Affixes_Compartment:GetWidth(), 50)

		CurrentAffixes_Container:SetPoint("TOP", Affixes_Compartment, "TOP", 0, -CurrentAffixes_Label:GetHeight())
		CurrentAffixes_Container.tex = CurrentAffixes_Container:CreateTexture()
		CurrentAffixes_Container.tex:SetAllPoints(CurrentAffixes_Container)
		CurrentAffixes_Container.tex:SetColorTexture(unpack(self.BackgroundClear))

		-- Create next week's Label
		local NextWeekAffixes_Label =
			Affixes_Compartment:CreateFontString("AMT_NextWeekAffixes_Label", "OVERLAY", "GameFontHighlightOutline22")
		NextWeekAffixes_Label:SetPoint("TOPLEFT", CurrentAffixes_Container, "BOTTOMLEFT", 2, -4) -- Set the position of the text
		NextWeekAffixes_Label:SetText("Next Week") -- Set the text content
		NextWeekAffixes_Label:SetFont(self.AMT_Font, 20)
		NextWeekAffixes_Label:SetTextColor(1, 1, 1, 1.0)

		-- Create next week's affixes container
		local NextWeekAffixes_Container =
			CreateFrame("Frame", "AMT_NextWeekAffixes_Container", Affixes_Compartment, "BackdropTemplate")
		-- CurrentKeystone_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		NextWeekAffixes_Container:SetSize(Affixes_Compartment:GetWidth(), CurrentAffixes_Container:GetHeight())
		local _, _, _, _, NextWeekAffixes_Label_y = NextWeekAffixes_Label:GetPoint()
		NextWeekAffixes_Container:SetPoint(
			"TOP",
			CurrentAffixes_Container,
			"BOTTOM",
			0,
			-NextWeekAffixes_Label_y - NextWeekAffixes_Label:GetHeight() - 6
		)

		-- Create the icons for the current affixes
		for i = 1, #self.GetCurrentAffixesTable do
			for _, affixID in ipairs(self.CurrentWeek_AffixTable) do
				local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])
				local AffixIcon = {}
				local iconSize = 34
				local iconPadding = 4
				AffixIcon[i] = CreateFrame("Frame", "AMT_CurrentAffixIcon" .. i, CurrentAffixes_Container)
				AffixIcon[i]:SetSize(iconSize, iconSize)
				AffixIcon[i].tex = AffixIcon[i]:CreateTexture()
				AffixIcon[i].tex:SetAllPoints(AffixIcon[i])
				AffixIcon[i].tex:SetTexture(filedataid)
				AffixIcon[i].tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				if i == 1 then
					AffixIcon[i]:SetPoint(
						"LEFT",
						CurrentAffixes_Container,
						"LEFT",
						(
							AffixIcon[i]:GetParent():GetWidth()
							- (iconSize * #self.GetCurrentAffixesTable)
							- (iconPadding * (#self.GetCurrentAffixesTable - 1))
						) / 2,
						0
					)
				else
					AffixIcon[i]:SetPoint("LEFT", _G["AMT_CurrentAffixIcon" .. i - 1], "RIGHT", iconPadding, 0)
				end
				AffixIcon[i]:SetScript("OnEnter", function()
					GameTooltip:ClearAllPoints()
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(_G["AMT_CurrentAffixIcon" .. i], "ANCHOR_RIGHT")
					GameTooltip:SetText(name, 1, 1, 1, 1, true)
					GameTooltip:AddLine(description, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				AffixIcon[i]:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			end
		end
		-- Create next week's affix icons
		for i = 1, #self.GetCurrentAffixesTable do
			for _, affixID in ipairs(NextWeek_AffixTable) do
				local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])
				local AffixIcon = {}
				local iconSize = 34
				local iconPadding = 4
				AffixIcon[i] = CreateFrame("Frame", "AMT_NexWeek_AffixIcon" .. i, NextWeekAffixes_Container)
				AffixIcon[i]:SetSize(iconSize, iconSize)
				AffixIcon[i].tex = AffixIcon[i]:CreateTexture()
				AffixIcon[i].tex:SetAllPoints(AffixIcon[i])
				AffixIcon[i].tex:SetTexture(filedataid)
				AffixIcon[i].tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				if i == 1 then
					AffixIcon[i]:SetPoint(
						"LEFT",
						NextWeekAffixes_Container,
						"LEFT",
						(
							AffixIcon[i]:GetParent():GetWidth()
							- (iconSize * #self.GetCurrentAffixesTable)
							- (iconPadding * (#self.GetCurrentAffixesTable - 1))
						) / 2,
						0
					)
				else
					AffixIcon[i]:SetPoint("LEFT", _G["AMT_NexWeek_AffixIcon" .. i - 1], "RIGHT", iconPadding, 0)
				end
				AffixIcon[i]:SetScript("OnEnter", function()
					GameTooltip:ClearAllPoints()
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(_G["AMT_NexWeek_AffixIcon" .. i], "ANCHOR_RIGHT")
					GameTooltip:SetText(name, 1, 1, 1, 1, true)
					GameTooltip:AddLine(description, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				AffixIcon[i]:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			end
		end
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
			PartyKeystone_Container.tex:SetColorTexture(unpack(self.BackgroundDark))
		end
		PartyKeystone_Container:SetPoint("TOPRIGHT", Affixes_Compartment, "BOTTOMRIGHT", 0, 0)
		-- Set the title text for the container
		local PartyKeystone_Container_Title = PartyKeystone_Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		PartyKeystone_Container_Title:SetPoint("TOPLEFT", PartyKeystone_Container, "TOPLEFT", 6, -6)
		PartyKeystone_Container_Title:SetJustifyH("LEFT")
		PartyKeystone_Container_Title:SetFont(self.AMT_Font, 14)
		PartyKeystone_Container_Title:SetText("Party Keystones")
		-- Create the Party Keystone Buttons
		local PartyKeystone_DetailsButton
		local PartyKeystone_RefreshButton
		local PartyKeystone_RollButton
		if self.DetailsEnabled then
			PartyKeystone_DetailsButton = AMT_CreateBorderButton(
				PartyKeystone_Container,
				"AMT_PartyKeystone_DetailsButton",
				"TOPRIGHT",
				PartyKeystone_Container,
				"TOPRIGHT",
				-4,
				-4,
				16,
				16,
				"!"
			)

			PartyKeystone_DetailsButton:SetScript("OnClick", function()
				if _G.SlashCmdList["KEYSTONE"] then
					_G.SlashCmdList["KEYSTONE"]("")
				end
			end)

			PartyKeystone_RefreshButton = AMT_CreateBorderButton(
				PartyKeystone_Container,
				"AMT_PartyKeystone_RefreshButton",
				"RIGHT",
				PartyKeystone_DetailsButton,
				"LEFT",
				-4,
				0,
				50,
				16,
				"Refresh"
			)
			PartyKeystone_RefreshButton:SetScript("OnClick", function()
				AMT:AMT_PartyKeystoneRefreshRequest()
			end)

			PartyKeystone_RollButton = AMT_CreateBorderButton(
				PartyKeystone_Container,
				"AMT_PartyKeystone_RollButton",
				"BOTTOM",
				PartyKeystone_Container,
				"BOTTOM",
				0,
				3,
				90,
				16,
				"Random Key"
			)

			PartyKeystone_RollButton:SetScript("OnClick", function()
				if IsInGroup() and not IsInRaid() and #self.GroupKeystone_Info > 0 then
					AMT:AMT_RandomKeystonePicker()
				else
					print("|cff18a8ffAMT|r: Must be in a group with multiple keystones to roll")
				end
			end)
			PartyKeystone_Container.lines = {}

			for i = 1, 5 do
				--Create the 5 lines of text we'll use of player name and keystone info
				local yOffset = -23
				local PartyKeystone_Rightext = PartyKeystone_Container:CreateFontString(
					"AMT_PartyKeystyone_Right" .. i,
					"OVERLAY",
					"GameFontNormalWTF2"
				)
				PartyKeystone_Rightext:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -6, yOffset * i - 2)
				PartyKeystone_Rightext:SetJustifyH("RIGHT")
				PartyKeystone_Rightext:SetWidth(90)
				PartyKeystone_Rightext:SetFont(self.AMT_Font, 14)
				PartyKeystone_Rightext:SetText("")

				PartyKeystone_Lefttext = PartyKeystone_Container:CreateFontString(
					"AMT_PartyKeystyone_Left" .. i,
					"OVERLAY",
					"GameFontNormalWTF2"
				)
				PartyKeystone_Lefttext:SetPoint("TOPLEFT", PartyKeystone_Container, "TOPLEFT", 6, yOffset * i)
				PartyKeystone_Lefttext:SetJustifyH("LEFT")
				PartyKeystone_Lefttext:SetWidth(92)
				PartyKeystone_Lefttext:SetFont(self.AMT_Font, 14)
				PartyKeystone_Lefttext:SetText("")
				PartyKeystone_Container.lines[i] = {
					left = PartyKeystone_Lefttext,
					right = PartyKeystone_Rightext,
				}
			end
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
		MythicScore_Container.tex:SetColorTexture(unpack(self.BackgroundClear))

		--Create the Dragon Borders
		local MythicScore_LeftDragon = CreateFrame("Frame", "MythicScore_LeftDragon", MythicScore_Container)
		MythicScore_LeftDragon:SetPoint("RIGHT", MythicScore_Container, "LEFT", 20, 10)
		MythicScore_LeftDragon:SetSize(80, 37)
		MythicScore_LeftDragon.tex = MythicScore_LeftDragon:CreateTexture()
		MythicScore_LeftDragon.tex:SetAllPoints(MythicScore_LeftDragon)
		MythicScore_LeftDragon.tex:SetAtlas("Dragonflight-DragonHeadLeft", false)

		local MythicScore_RightDragon = CreateFrame("Frame", "MythicScore_LeftDragon", MythicScore_Container)
		MythicScore_RightDragon:SetPoint("LEFT", MythicScore_Container, "RIGHT", -20, 10)
		MythicScore_RightDragon:SetSize(80, 37)
		MythicScore_RightDragon.tex = MythicScore_RightDragon:CreateTexture()
		MythicScore_RightDragon.tex:SetAllPoints(MythicScore_RightDragon)
		MythicScore_RightDragon.tex:SetAtlas("Dragonflight-DragonHeadLeft", false)
		MythicScore_RightDragon.tex:SetTexCoord(1, 0, 0, 1)

		-- Create label
		local MythicScore_Title_Label = MythicScore_Container:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		MythicScore_Title_Label:SetPoint("TOP", 0, -4)
		MythicScore_Title_Label:SetText("Mythic+ Rating")
		MythicScore_Title_Label:SetFont(self.AMT_Font, 20)
		MythicScore_Title_Label:SetTextColor(1, 1, 1, 1.0)

		-- Create the text string for mythic score
		local MythicScore_Label =
			MythicScore_Container:CreateFontString("MythicScore_Label", "OVERLAY", "GameFontNormal")
		MythicScore_Label:SetPoint("TOP", MythicScore_Title_Label, "BOTTOM", 0, -4)
		MythicScore_Label:SetText(self.Player_Mplus_Summary.currentSeasonScore)
		MythicScore_Label:SetFont(self.AMT_Font, 28)
		MythicScore_Label:SetTextColor(
			self.Player_Mplus_ScoreColor.r,
			self.Player_Mplus_ScoreColor.g,
			self.Player_Mplus_ScoreColor.b,
			1.0
		)

		--Set Script for Tooltip
		MythicScore_Container:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(MythicScore_Container, "ANCHOR_RIGHT", 0, 0)
			GameTooltip_SetTitle(GameTooltip, DUNGEON_SCORE)
			GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_DESC)
			GameTooltip:Show()
		end)
		MythicScore_Container:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		-- On Click paste into chat the rating link.
		-- Copied from Blizzard_ChallengesUI.lua > DungeonScoreInfoMixin:OnClick()
		-- Uses ItemRef.lua > GetDungeonScoreLink(dungeonScore, playerName)
		MythicScore_Container:SetScript("OnClick", function()
			if IsModifiedClick("CHATLINK") then
				local dungeonScore = C_ChallengeMode.GetOverallDungeonScore()
				local link = GetDungeonScoreLink(dungeonScore, UnitName("player"))
				if not ChatEdit_InsertLink(link) then
					ChatFrame_OpenChat(link)
				end
			end
		end)
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
		MythicRunsGraph_Container.tex:SetColorTexture(unpack(self.BackgroundClear))

		local graphline = {}
		local graphline_label = {}
		for i = 1, 4 do
			--Create the Line Dividers for the M+ Graph
			graphline[i] = MythicRunsGraph_Container:CreateLine("AMT_GraphLine" .. i)
			graphline[i]:SetThickness(2)
			graphline[i]:SetColorTexture(0.4, 0.4, 0.4, 1.000)
			local Starting_XPos = 60
			local YPos_Start = -16
			local YPos_End = 34
			if i == 1 then
				-- x = 44
				local xOffset = Starting_XPos
				graphline[i]:SetColorTexture(1, 1, 1, 0)
				graphline[i]:SetStartPoint("TOPLEFT", xOffset, YPos_Start)
				graphline[i]:SetEndPoint("BOTTOMLEFT", xOffset, YPos_End)
			elseif i == 2 then
				-- x = 186
				local xOffset = Starting_XPos + 142
				graphline[i]:SetStartPoint("TOPLEFT", xOffset, YPos_Start)
				graphline[i]:SetEndPoint("BOTTOMLEFT", xOffset, YPos_End)
			elseif i > 2 then
				-- 3 // x = 336
				-- 4 // x = 486
				local xOffset = Starting_XPos + 142 + 150 * (i - 2)
				graphline[i]:SetStartPoint("TOPLEFT", xOffset, YPos_Start)
				graphline[i]:SetEndPoint("BOTTOMLEFT", xOffset, YPos_End)
			end
		end
		-- Create the Line Labels
		for i = 1, 3 do
			graphline_label[i] =
				MythicRunsGraph_Container:CreateFontString("AMT_Graphline_Label" .. i, "BACKGROUND", "GameFontNormal")
			graphline_label[i]:SetText(tostring(i * 10))
			graphline_label[i]:SetJustifyH("CENTER")
			graphline_label[i]:SetPoint("BOTTOM", _G["AMT_GraphLine" .. i + 1], "TOP", 0, 4)
		end
		-- Create the dungeon name labels on the first invisible divider
		local graphDung_label = {}
		for i = 1, #self.Current_SeasonalDung_Info do
			local graphline = _G["AMT_GraphLine1"]
			local dungID = self.Current_SeasonalDung_Info[i].mapID
			local dungAbbr = ""
			for _, dungeon in ipairs(self.SeasonalDungeons) do
				if dungID == dungeon.mapID then
					dungAbbr = dungeon.abbr
				end
			end
			local yMargin = 12 -- Margin we set at top and bottom
			local yOffset = 26 -- Margin between each dungeon name
			graphDung_label[i] = MythicRunsGraph_Container:CreateFontString(
				"AMT_GraphDung_Label" .. i,
				"BACKGROUND",
				"MovieSubtitleFont"
			)

			graphDung_label[i]:SetFont(self.AMT_Font, 14)
			graphDung_label[i]:SetText(dungAbbr)
			graphDung_label[i]:SetJustifyH("RIGHT")
			if i == 1 then
				graphDung_label[i]:SetPoint("RIGHT", graphline, "TOPLEFT", -4, -yMargin)
			else
				graphDung_label[i]:SetPoint("RIGHT", graphline, "TOPLEFT", -4, -yMargin - (yOffset * (i - 1)))
			end
		end
	end
	-- MARK: Create Crests Tracker Container
	local CrestsTracker_Container
	if not _G["AMT_CrestsTracker_Container"] then
		CrestsTracker_Container = CreateFrame("Frame", "AMT_CrestsTracker_Container", AMT_Window)
		CrestsTracker_Container:SetPoint("BOTTOM", MythicRunsGraph_Container, "BOTTOM")
		CrestsTracker_Container:SetSize(MythicRunsGraph_Container:GetWidth(), 30)
		CrestsTracker_Container.tex = CrestsTracker_Container:CreateTexture()
		CrestsTracker_Container.tex:SetAllPoints(CrestsTracker_Container)
		CrestsTracker_Container.tex:SetColorTexture(unpack(self.BackgroundClear))
		-- Create each of the Crest Tracker Progress Bars
		local ProgBar_Width = 120
		local ProgBar_Height = 14

		for i = 1, #self.Crests do
			local ProgBar_Frame, ProgBar, ProgBar_Text, ProgBar_Bg = AMT:CreateProgressBar(
				self.Crests[i].name,
				AMT.Clean_StatusBar,
				self.Crests[i].color,
				CrestsTracker_Container,
				ProgBar_Width,
				ProgBar_Height
			)
			if i == 1 then
				ProgBar_Frame:SetPoint("BOTTOMLEFT", CrestsTracker_Container, "BOTTOMLEFT", 20, 0)
			else
				local previousFrame = _G[self.Crests[i - 1].name .. "_Frame"]
				ProgBar_Frame:SetPoint("LEFT", previousFrame, "RIGHT", 20, 0)
			end
			ProgBar_Text:SetText(self.Crests[i].name)
			ProgBar_Text:SetFont(self.AMT_Font, 12)
			ProgBar_Bg:SetVertexColor(0.25, 0.25, 0.25, 0.5)
			ProgBar:SetMinMaxValues(0, 1)
			ProgBar:SetValue(0)
			ProgBar:SetStatusBarColor(unpack(self.Crests[i].color))

			-- Establish the Hover Properties
			ProgBar_Frame:SetScript("OnEnter", function()
				GameTooltip:ClearAllPoints()
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(ProgBar_Text, "ANCHOR_RIGHT")
				GameTooltip:SetText(
					CreateTextureMarkup(self.Crests[i].textureID, 64, 64, 16, 16, 0.07, 0.93, 0.07, 0.93)
						.. " "
						.. self.Crests[i].displayName,
					self.Crests[i].color[1],
					self.Crests[i].color[2],
					self.Crests[i].color[3],
					self.Crests[i].color[4],
					true
				)
				GameTooltip:AddLine(self.Crests[i].CurrencyDescription, 1.000, 0.824, 0.000, true)
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Total: " .. self.Whitetext .. self.Crests[i].CurrentAmount)
				GameTooltip:AddLine(
					"Season Maximum: "
						.. self.Whitetext
						.. self.Crests[i].CurrencyTotalEarned
						.. "/"
						.. self.Crests[i].CurrencyCapacity
				)
				GameTooltip:AddLine(
					"You need to time " .. self.Whitetext .. self.Crests[i].NumOfRunsNeeded .. "|r M+ keys to cap."
				)
				GameTooltip:Show()
				ProgBar:SetMinMaxValues(0, 1)
				ProgBar:SetValue(self.Crests[i].CurrencyTotalEarned / self.Crests[i].CurrencyCapacity)
				ProgBar_Bg:SetVertexColor(0.25, 0.25, 0.25, 0.25)
			end)
			ProgBar_Frame:SetScript("OnLeave", function()
				GameTooltip:Hide()
				ProgBar:SetStatusBarColor(
					self.Crests[i].color[1],
					self.Crests[i].color[2],
					self.Crests[i].color[3],
					self.Crests[i].color[4]
				)
				ProgBar_Bg:SetVertexColor(0.25, 0.25, 0.25, 0.5)
			end)
		end
	end
	self.AMT_CreationComplete = true
	AMT:AMT_DataUpdate()
end

function AMT:AMT_DataUpdate()
	-- ========================================
	-- === MARK: Update Raid Vault Progress ===
	-- ========================================
	local PreviousRaidDifficulty_Kills = 0
	local VaultUnlock_CurrentMax = 0 --store the highest # of bosses killed in all previous categories analyzed so we can see if current difficulty unlocks new rewards in Vault
	local LastReward_Unlocked = false
	for i = 1, #self.Weekly_KillCount do
		local RaidBosses_Killed
		if self.Weekly_KillCount[i].kills <= self.Vault_RaidReq then
			RaidBosses_Killed = self.Weekly_KillCount[i].kills
		elseif self.Weekly_KillCount[i].kills > self.Vault_RaidReq then
			RaidBosses_Killed = self.Vault_RaidReq
		end
		local difficulty = self.Weekly_KillCount[i].abbr
		for j = 1, RaidBosses_Killed do
			if
				(j == self.Raid_VaultUnlocks[3] and RaidBosses_Killed == self.Raid_VaultUnlocks[3])
				and not LastReward_Unlocked
			then
				_G["AMT_" .. difficulty .. j].tex:SetColorTexture(1, 0.784, 0.047, 1.0) -- Gold
				LastReward_Unlocked = true
			elseif
				(
					(j == self.Raid_VaultUnlocks[1] and VaultUnlock_CurrentMax < self.Raid_VaultUnlocks[1])
					or (j == self.Raid_VaultUnlocks[2] and VaultUnlock_CurrentMax < self.Raid_VaultUnlocks[2])
				) and not LastReward_Unlocked
			then
				_G["AMT_" .. difficulty .. j].tex:SetColorTexture(1, 0.784, 0.047, 1.0) -- Gold
			else
				_G["AMT_" .. difficulty .. j].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0) -- Green
			end
		end
		if RaidBosses_Killed > PreviousRaidDifficulty_Kills then
			VaultUnlock_CurrentMax = RaidBosses_Killed
		end
		PreviousRaidDifficulty_Kills = RaidBosses_Killed
	end
	-- =======================================
	-- === MARK: Update M+ Vault Progress ===
	-- =======================================
	local WeeklyKeysHistory = {}

	for i = 1, self.Vault_DungeonReq do
		if i <= #self.KeysDone and #self.RunHistory > 0 then
			tinsert(WeeklyKeysHistory, self.KeysDone[i].level)
		else
			break -- Exit the loop if self.KeysDone[i] or self.KeysDone[i].level doesn't exist
		end
	end

	for i = 1, self.Vault_DungeonReq do
		if WeeklyKeysHistory[i] ~= nil and WeeklyKeysHistory[i] > 0 then
			if
				i == self.Mplus_VaultUnlocks[1]
				or i == self.Mplus_VaultUnlocks[2]
				or i == self.Mplus_VaultUnlocks[3]
			then
				_G["AMT_Mplus_Box" .. i].tex:SetColorTexture(1, 0.784, 0.047, 1.0)
			else
				_G["AMT_Mplus_Box" .. i].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0)
			end
		end
	end

	-- =========================================
	-- === MARK: Update World Vault Progress ===
	-- =========================================
	local World_VaultProg = C_WeeklyRewards.GetActivities(6)
	for i = 1, World_VaultProg[#World_VaultProg].progress do
		if i <= self.Vault_WorldReq then
			if
				i == self.World_VaultUnlocks[1]
				or i == self.World_VaultUnlocks[2]
				or i == self.World_VaultUnlocks[3]
			then
				_G["AMT_World_Box" .. i].tex:SetColorTexture(1, 0.784, 0.047, 1.0)
			else
				_G["AMT_World_Box" .. i].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0)
			end
		end
	end

	-- =====================================
	-- === MARK: Update M+ Score Display ===
	-- =====================================

	local MythicScore_Label = _G["MythicScore_Label"]
	self.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	MythicScore_Label:SetText(self.Player_Mplus_Summary.currentSeasonScore)

	-- =========================================
	-- === MARK: Update Keystone Information ===
	-- =========================================
	local KeystoneItem_Icon = _G["AMT_KeystoneItem_Icon"]
	local KeystoneItem_Glow = _G["AMT_KeystoneItem_Glow"]
	local Keystone_DungName = _G["AMT_Keystone_DungName"]
	Keystone_DungName_Bg = _G["AMT_Keystone_DungName_Bg"]
	CurrentKeystone_Compartment = _G["AMT_CurrentKeystone_Compartment"]
	local weekly_modifier = {}
	local keystone_ID, keystone_name, keystone_icontex, keystone_level, keystone_abbr, keystone_dungname, keystone_mod, vaultReward, dungeonReward
	local keystone_mod_tt, keystone_info_tt, keystone_dungeonmodifiers_tt, keystone_rewards_tt, noKeystone_tt
	local rio_total_tt, rio_1R, rio_2R, rio_3R, rio_4R, rio_5R
	local rio_title_tt = "|cffffffffTimed Runs:"
	local rio_1L = "   • For +12 "
	local rio_2L = "   • For +10 - 11 "
	local rio_3L = "   • For +7 - 9 "
	local rio_4L = "   • For +4 - 6 "
	local rio_5L = "   • For +2 - 3 "

	--If a Keystone level is detected create the Icon Texture that belongs to the dungeon.
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		keystone_ID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		keystone_name, _, _, keystone_icontex = C_ChallengeMode.GetMapUIInfo(keystone_ID)
		keystone_abbr = AMT:GetAbbrFromChallengeModeID(keystone_ID)
		keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
		-- vaultReward, dungeonReward = C_MythicPlus.GetRewardLevelForDifficultyLevel(keystone_level) --dungeonRewards API is broken for the time being
		vaultReward, dungeonReward = AMT:AMT_GetKeystoneRewards(keystone_level)
		Keystone_DungName:SetText("+" .. keystone_level .. " " .. keystone_abbr)
		Keystone_DungName:SetFont(self.AMT_Font, 14)
		--Set the icon textures
		KeystoneItem_Icon.tex:SetTexture(keystone_icontex)
		KeystoneItem_Icon:SetSize(62, 62)
		KeystoneItem_Icon.tex:SetDesaturated(false)
		--Since Keystone was detected we now create a glow around the icon.
		KeystoneItem_Glow.tex:SetAtlas("BattleBar-Button-Highlight")
		--Start grabbing the information that will be displayed on the tooltip of the icon.
		keystone_mod = C_ChallengeMode.GetPowerLevelDamageHealthMod(keystone_level)
		--Get current affixes and assign the appropriate modifiers for Tyr/Fort.
		local affix = self.CurrentWeek_AffixTable[1]
		if affix and keystone_level >= 10 then
			weekly_modifier = self.Keystone_Modifiers[3].values
		elseif affix and affix[2] == 9 then
			weekly_modifier = self.Keystone_Modifiers[1].values
		elseif affix and affix[2] == 10 then
			weekly_modifier = self.Keystone_Modifiers[2].values
		end
		-- Creating the modifiers portion of the tooltip
		keystone_mod_tt = BOSS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. keystone_mod + weekly_modifier[1]
			.. "%\n"
			.. BOSS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. keystone_mod + weekly_modifier[2]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. keystone_mod + weekly_modifier[3]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. keystone_mod + weekly_modifier[4]
			.. "%"
		-- Creating the main keystone tooltip categories
		keystone_info_tt = "|cffffffffKeystone: |cffc845fa" .. keystone_name .. " +" .. keystone_level .. "\n\n"
		keystone_dungeonmodifiers_tt = "|cffffffffDungeon Modifiers:|r\n" .. keystone_mod_tt .. "\n\n"
		keystone_rewards_tt = "|cffffffffRewards:|r"
			.. "\n"
			.. "End of Dungeon: |cffffffff"
			.. dungeonReward
			.. "|r\n"
			.. "Great Vault: |cffffffff"
			.. vaultReward
			.. "|r\n\n"
	else
		--If Great Vault Rewards are uncollected create the
		if C_WeeklyRewards.HasAvailableRewards() then
			Keystone_DungName:SetText("Pending Vault")
			Keystone_DungName:SetFont(self.AMT_Font, 14)
			KeystoneItem_Icon.tex:SetAtlas("CovenantChoice-Celebration-Content-Soulbind")
			KeystoneItem_Icon:SetSize(64, 64)
			KeystoneItem_Icon.tex:SetDesaturated(false)
		else
			Keystone_DungName:SetText("No Key") -- No Key
			Keystone_DungName:SetFont(self.AMT_Font, 14)
			--If a Keystone level is not detected, we'll set the texture of the keystone to a default texture and a glow
			KeystoneItem_Icon.tex:SetTexture(self.Keystone_Icon)
			KeystoneItem_Icon:SetSize(60, 60)
			KeystoneItem_Glow.tex:SetAtlas("BattleBar-Button-Highlight")
		end
	end
	if C_WeeklyRewards.HasAvailableRewards() then
		noKeystone_tt = "Visit the Great Vault to collect your reward!"
	else
		noKeystone_tt = "Get your Keystone by"
			.. "\n|cffffffff"
			.. " • Completing any Dungeon on Mythic or Mythic Plus Difficulty"
			.. "\n"
			.. " • Speaking with Lindormi in Valdrakken"
	end
	-- local RIO_PlayerProfile
	AMTTestTable = RaiderIO.GetProfile("player")
	if RaiderIO and RaiderIO.GetProfile("player") then
		--Grab the timed runs information for the player from the RIO addon
		RIO_PlayerProfile = RaiderIO.GetProfile("player")
		if
			RIO_PlayerProfile ~= nil
			and RIO_PlayerProfile.mythicKeystoneProfile ~= nil
			and RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone4 ~= nil
		then
			rio_total_tt = "|cff009dd5"
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone2 + RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone4 + RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone7 + RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone10 + RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone12 + RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone15
				.. "+"
			rio_1R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone12
				+ RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone15

			rio_2R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone10
			rio_3R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone7
			rio_4R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone4
			rio_5R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneMilestone2
		end
	end
	--Set up the tooltip for the Keystone Icon
	KeystoneItem_Icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if not C_MythicPlus.GetOwnedKeystoneLevel() then
			GameTooltip:AddLine(noKeystone_tt)
		else
			GameTooltip:AddLine(keystone_info_tt)
			GameTooltip:AddLine(keystone_dungeonmodifiers_tt)
			GameTooltip:AddLine(keystone_rewards_tt)
			if RaiderIO and RaiderIO.GetProfile("player") then
				if RIO_PlayerProfile ~= nil and RIO_PlayerProfile.mythicKeystoneProfile ~= nil then
					GameTooltip:AddDoubleLine(rio_title_tt, rio_total_tt)
					if rio_1R and rio_1R ~= 0 then
						GameTooltip:AddDoubleLine(rio_1L, rio_1R .. "  ")
					end
					if rio_2R and rio_2R ~= 0 then
						GameTooltip:AddDoubleLine(rio_2L, rio_2R .. "  ")
					end
					if rio_3R and rio_3R ~= 0 then
						GameTooltip:AddDoubleLine(rio_3L, rio_3R .. "  ")
					end
					if rio_4R and rio_4R ~= 0 then
						GameTooltip:AddDoubleLine(rio_4L, rio_4R .. "  ")
					end
					if rio_5R and rio_5R ~= 0 then
						GameTooltip:AddDoubleLine(rio_5L, rio_5R .. "  ")
					end
				else
					GameTooltip:AddLine("No timed runs found.")
				end
			else
				GameTooltip:AddLine(
					"If you'd like detailed breakdown of your keys,\ninstall & enable the |cffffffffRaider.IO|r addon."
				)
			end
		end
		GameTooltip:Show()
	end)

	--Hide tooltip when mouse is moved away
	KeystoneItem_Icon:SetScript("OnLeave", function()
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	end)

	-- =========================================
	-- === MARK: Update Dungeon Icon Buttons ===
	-- =========================================
	--Update each of the labels with updated information each time AMT Window is opened
	for i = 1, #self.Current_SeasonalDung_Info do
		local DungWeekLevel_Label = _G["AMT_DungWeekLevel_Label" .. i]
		local DungWeekScore_Label = _G["AMT_DungWeekScore_Label" .. i]

		Dung_WeekScore = self.Current_SeasonalDung_Info[i].dungeonScore
		Dung_WeekLevel = self.Current_SeasonalDung_Info[i].dungeonLevel
		--Grab the color information for the current dungeon score
		local DungScore_Color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(Dung_WeekScore)
		--Set the Highest Key Level Label to be the highest key level number and appropriate color for it.
		DungWeekLevel_Label:SetText(Dung_WeekLevel)
		DungWeekLevel_Label:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)
		--Repeat for the Score
		DungWeekScore_Label:SetText(Dung_WeekScore)
		DungWeekScore_Label:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)
	end

	-- ==================================
	-- === MARK: Update M+ Runs Graph ===
	-- ==================================
	local dungLines = {}
	for i = 1, #self.BestKeys_per_Dungeon do
		local MythicRunsGraph_Container = _G["AMT_MythicRunsGraph_Container"]
		local graphlabel = _G["AMT_GraphDung_Label" .. i]
		local dungeonLine = _G["AMT_Dung_AntTrail" .. i]
		if not dungeonLine then
			dungLines[i] =
				MythicRunsGraph_Container:CreateFontString("AMT_Dung_AntTrail" .. i, "ARTWORK", "GameFontNormal")
			dungLines[i]:SetFont(AMT.AntTrail_Font, 14)
		else
			dungLines[i] = dungeonLine
		end

		local dungLine = dungLines[i]

		--If the key actually exists/was done, set the ant trail
		if self.BestKeys_per_Dungeon[i].HighestKey > 0 then
			dungLine:SetPoint("LEFT", graphlabel, "RIGHT", 6, -1)
			dungLine:SetText(self.BestKeys_per_Dungeon[i].DungBullets .. self.BestKeys_per_Dungeon[i].HighestKey)
			--If highest key done is same as the current weekly best color the line gold
			if self.BestKeys_per_Dungeon[i].HighestKey == self.KeysDone[1].level then
				dungLine:SetTextColor(1.000, 0.824, 0.000, 1.000)
			else
				--Otherwise color it white
				dungLine:SetTextColor(1, 1, 1, 1.0)
			end
		end
	end

	-- ==================================
	-- === MARK: Update Crest Tracker ===
	-- ==================================

	AMT:Update_Crests()

	-- ====================================
	-- === MARK: Update Party Keystones ===
	-- ====================================
	-- Pull the group's keystone information
	AMT:AMT_PartyKeystoneRefresh()
end

function AMT:Update_Crests()
	for i = 1, #self.Crests do
		local name = self.Crests[i].name
		local ProgBar = _G[name .. "_StatusBar"]
		local CurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(self.Crests[i].currencyID)
		self.Crests[i].CurrencyDescription = CurrencyInfo.description
		self.Crests[i].CurrentAmount = CurrencyInfo.quantity or 0
		self.Crests[i].CurrencyTotalEarned = CurrencyInfo.totalEarned
		if CurrencyInfo.maxQuantity ~= 0 then
			self.Crests[i].CurrencyCapacity = CurrencyInfo.maxQuantity
		else
			self.Crests[i].CurrencyCapacity = 999
		end
		self.Crests[i].NumOfRunsNeeded =
			math.max(0, math.ceil((self.Crests[i].CurrencyCapacity - self.Crests[i].CurrencyTotalEarned) / 12))
		ProgBar:SetValue(self.Crests[i].CurrencyTotalEarned / self.Crests[i].CurrencyCapacity)
	end
end
