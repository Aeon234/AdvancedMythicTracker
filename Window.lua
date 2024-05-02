local addonName, AMT = ...

BackdropInfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 40,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

Difficulty_Label_XPos = 42
Difficulty_Label_YPos = 1

function AMT:AMT_Visuals()
	--Set the Portrait of the PVEFrame
	PVEFrame:SetPortraitToAsset("Interface\\Icons\\Ability_BossMagistrix_TimeWarp2")

	--Create the rune art used that'll house the current key
	if not RuneArt then
		RuneArt = CreateFrame("Frame", "RuneTexture", AMT_Container_BG)
		RuneArt:SetPoint("BOTTOMLEFT", AMT_Container_BG, "BOTTOMLEFT", 45, 14)
		RuneArt:SetSize(132, 132)
		RuneArt:SetFrameStrata("MEDIUM")

		RuneArt.tex = RuneArt:CreateTexture()
		RuneArt.tex:SetAllPoints(RuneArt)
		RuneArt.tex:SetAtlas("Artifacts-CrestRune-Gold", false)
	end

	--Set the title "Weekly Best" Label at the top left of the window
	if not WeeklyBest_Label then
		WeeklyBest_Label = AMT_Container_BG:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge2")
		WeeklyBest_Label:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 62, -25)
		WeeklyBest_Label:SetText("Weekly Best")
		WeeklyBest_Label:SetFont(WeeklyBest_Label:GetFont(), 18, "OUTLINE")
		WeeklyBest_Label:SetTextColor(1, 1, 1)
	end
	-- Incomplete - needs to generate the box background
	if not WeeklyBest_Bg then
		WeeklyBest_Bg = CreateFrame("Frame", "WeeklyBest_Bg", AMT_Container_BG, "BackdropTemplate")
		WeeklyBest_Bg:SetSize(103, 42)
		WeeklyBest_Bg:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 61, -42)
		WeeklyBest_Bg:SetBackdrop(BackdropInfo)

		WeeklyBest_Bg:SetBackdropBorderColor(0, 0, 0, 0.5)
		WeeklyBest_Bg:SetBackdropColor(0, 0, 0, 0.5)
	end
	if not WeeklyVault_Goals then
		WeeklyVault_Goals = CreateFrame("Frame", "WeeklyBest_Goals", AMT_Container_BG, "BackdropTemplate")
		WeeklyVault_Goals:SetSize(190, 192)
		WeeklyVault_Goals:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 17, -86)
		WeeklyVault_Goals:SetBackdrop(BackdropInfo)

		WeeklyVault_Goals:SetBackdropBorderColor(1, 1, 1, 0.0)
		WeeklyVault_Goals:SetBackdropColor(1, 1, 1, 0.0)
	end

	if not Raid_Goals then
		Raid_Goals = CreateFrame("Frame", "WeeklyBest_Bg", WeeklyVault_Goals, "BackdropTemplate")
		Raid_Goals:SetSize(190, 76)
		Raid_Goals:SetPoint("TOPLEFT", WeeklyVault_Goals, "TOPLEFT", 0, -2)
		Raid_Goals:SetBackdrop(BackdropInfo)

		Raid_Goals:SetBackdropBorderColor(0, 1, 1, 0.0)
		Raid_Goals:SetBackdropColor(0, 1, 1, 0.0)
	end

	if not RaidDifficulty_Goals then
		for raidIndex, raid in ipairs(SeasonalRaids) do
			for i, difficulty in ipairs(RaidDifficulty_Levels) do
				RaidDifficulty_Goals =
					CreateFrame("Frame", "RaidDifficulty" .. i, WeeklyVault_Goals, "BackdropTemplate")
				RaidDifficulty_Goals:SetSize(190, 20)

				RaidDifficulty_Goals:SetBackdrop(BackdropInfo)

				RaidDifficulty_Goals:SetBackdropBorderColor(1, 0, 1, 0.00)
				RaidDifficulty_Goals:SetBackdropColor(1, 1, 1, 0.00)

				local RaidDifficulty_Label =
					RaidDifficulty_Goals:CreateFontString("RaidDifficuly_Label" .. i, "OVERLAY", "MovieSubtitleFont")
				RaidDifficulty_Label:SetPoint(
					"RIGHT",
					RaidDifficulty_Goals,
					"LEFT",
					Difficulty_Label_XPos,
					Difficulty_Label_YPos
				)
				RaidDifficulty_Label:SetText("|cffffffff" .. difficulty.label)
				RaidDifficulty_Label:SetFont(RaidDifficulty_Label:GetFont(), 14)
				RaidDifficulty_Label:SetJustifyH("RIGHT")
				RaidDifficulty_Label:SetJustifyV("MIDDLE")

				if i == 1 then
					RaidDifficulty_Goals:SetPoint("TOP", Raid_Goals, "TOP", 0, -16)
				else
					local previousFrame = _G["RaidDifficulty" .. (i - 1)]
					RaidDifficulty_Goals:SetPoint("TOP", previousFrame, "BOTTOM", 0, -2)
				end

				RaidDifficulty_Goals:SetScript("OnEnter", function()
					GameTooltip:ClearAllPoints()
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(_G["RaidDifficulty" .. i], "ANCHOR_RIGHT")
					GameTooltip:SetText("Raid Progress", 1, 1, 1, 1, true)
					GameTooltip:AddLine(
						format("Difficulty: |cffffffff%s|r", difficulty.short and difficulty.short or difficulty.name)
					)
					if raids.savedInstances ~= nil then
						local savedInstance = AMT:Find_Table(raids.savedInstances, function(savedInstance)
							return savedInstance.difficultyID == difficulty.id
								and savedInstance.instanceID == raid.instanceID
								and savedInstance.expires > time()
						end)
						if savedInstance ~= nil then
							GameTooltip:AddLine(format("Expires: |cffffffff%s|r", date("%c", savedInstance.expires)))
						end
					end
					GameTooltip:AddLine(" ")
					for _, encounter in ipairs(raid.encounters) do
						local color = LIGHTGRAY_FONT_COLOR
						if raids.savedInstances then
							local savedInstance = AMT:Find_Table(raids.savedInstances, function(savedInstance)
								return savedInstance.difficultyID == difficulty.id
									and savedInstance.instanceID == raid.instanceID
									and savedInstance.expires > time()
							end)
							if savedInstance ~= nil then
								local savedEncounter = AMT:Find_Table(savedInstance.encounters, function(enc)
									if strcmputf8i(enc.bossName, encounter.name) == 0 then
										return strcmputf8i(enc.bossName, encounter.name) == 0
											and enc.instanceEncounterID == encounter.instanceEncounterID
											and enc.killed == true
									end
								end)
								if savedEncounter ~= nil then
									color = GREEN_FONT_COLOR
								end
							end
						end
						GameTooltip:AddLine(encounter.name, color.r, color.g, color.b)
					end
					GameTooltip:Show()
					_G["RaidDifficulty" .. i]:SetBackdropColor(1, 1, 1, 0.25)
				end)
				RaidDifficulty_Goals:SetScript("OnLeave", function()
					GameTooltip:Hide()
					_G["RaidDifficulty" .. i]:SetBackdropColor(1, 1, 1, 0)
				end)
			end
		end
	end

	if not Mplus_Goals then
		Mplus_Goals = CreateFrame("Frame", "Mplus_Goals", WeeklyVault_Goals, "BackdropTemplate")
		Mplus_Goals:SetSize(190, 34)

		Mplus_Goals:SetPoint("TOP", RaidDifficulty4, "BOTTOM", 0, -5)
		Mplus_Goals:SetBackdrop(BackdropInfo)

		Mplus_Goals:SetBackdropBorderColor(1, 0, 1, 0.0)
		Mplus_Goals:SetBackdropColor(1, 0, 1, 0.0)
	end

	if not MplusDifficulty_Goals then
		MplusDifficulty_Goals = CreateFrame("Frame", "MplusDifficulty_Goals", WeeklyVault_Goals, "BackdropTemplate")
		MplusDifficulty_Goals:SetSize(190, 20)

		MplusDifficulty_Goals:SetBackdrop(BackdropInfo)
		MplusDifficulty_Goals:SetPoint("TOP", Mplus_Goals, "TOP", 0, -16)
		MplusDifficulty_Goals:SetBackdropBorderColor(1, 0, 1, 0.00)
		MplusDifficulty_Goals:SetBackdropColor(1, 0, 1, 0.00)

		local MplusDifficulty_Label =
			Mplus_Goals:CreateFontString("MplusDifficulty_Label", "OVERLAY", "MovieSubtitleFont")
		MplusDifficulty_Label:SetPoint(
			"RIGHT",
			MplusDifficulty_Goals,
			"LEFT",
			Difficulty_Label_XPos,
			Difficulty_Label_YPos
		)
		MplusDifficulty_Label:SetText("|cffffffffM -")
		MplusDifficulty_Label:SetFont(MplusDifficulty_Label:GetFont(), 14)
		MplusDifficulty_Label:SetJustifyH("RIGHT")
		MplusDifficulty_Label:SetJustifyV("MIDDLE")
	end
	MplusDifficulty_Goals:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(MplusDifficulty_Goals, "ANCHOR_RIGHT")
		GameTooltip:SetText("Mythic Plus Progress", 1, 1, 1, 1, true)
		GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", #KeysDone))
		GameTooltip:AddLine(" ")
		MplusDifficulty_Goals:SetBackdropColor(1, 1, 1, 0.25)
		GameTooltip:Show()
	end)
	MplusDifficulty_Goals:SetScript("OnLeave", function()
		GameTooltip:Hide()
		MplusDifficulty_Goals:SetBackdropColor(1, 1, 1, 0)
	end)

	if not PVP_Goals then
		PVP_Goals = CreateFrame("Frame", "PVP_Goals", WeeklyVault_Goals, "BackdropTemplate")
		PVP_Goals:SetSize(190, 34)
		PVP_Goals:SetPoint("TOP", MplusDifficulty_Goals, "BOTTOM", 0, -5)
		PVP_Goals:SetBackdrop(BackdropInfo)

		PVP_Goals:SetBackdropBorderColor(1, 1, 0, 0.0)
		PVP_Goals:SetBackdropColor(1, 1, 0, 0.0)
	end

	if not PVPHonor_Goals then
		PVPHonor_Goals = CreateFrame("Frame", "PVPHonor_Goals", WeeklyVault_Goals, "BackdropTemplate")
		PVPHonor_Goals:SetSize(190, 20)

		PVPHonor_Goals:SetBackdrop(BackdropInfo)
		PVPHonor_Goals:SetPoint("TOP", PVP_Goals, "TOP", 0, -16)
		PVPHonor_Goals:SetBackdropBorderColor(1, 0, 1, 0.00)
		PVPHonor_Goals:SetBackdropColor(1, 0, 1, 0.00)

		local PVPHonor_Label = PVPHonor_Goals:CreateFontString("MplusDifficulty_Label", "OVERLAY", "MovieSubtitleFont")
		PVPHonor_Label:SetPoint("RIGHT", PVPHonor_Goals, "LEFT", Difficulty_Label_XPos + 10, Difficulty_Label_YPos)
		PVPHonor_Label:SetText("|cffffffffHonor -")
		PVPHonor_Label:SetFont(PVPHonor_Label:GetFont(), 14)
		PVPHonor_Label:SetJustifyH("RIGHT")
		PVPHonor_Label:SetJustifyV("MIDDLE")
	end

	if not WeeklyRaid_Label then
		WeeklyRaid_Label = Raid_Goals:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyRaid_Label:SetPoint("TOPLEFT", Raid_Goals, "TOPLEFT", 0, 0)
		WeeklyRaid_Label:SetText("Raid:")
		WeeklyRaid_Label:SetFont(WeeklyRaid_Label:GetFont(), 14)
	end

	if not WeeklyMplus_Label then
		WeeklyMplus_Label = Mplus_Goals:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyMplus_Label:SetPoint("TOPLEFT", Mplus_Goals, "TOPLEFT", 0, 0)
		WeeklyMplus_Label:SetText("Mythic+:")
		WeeklyMplus_Label:SetFont(WeeklyMplus_Label:GetFont(), 14)
	end

	if not WeeklyPVP_Label then
		WeeklyPVP_Label = PVP_Goals:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyPVP_Label:SetPoint("TOPLEFT", PVP_Goals, "TOPLEFT", 0, 0)
		WeeklyPVP_Label:SetText("PVP:")
		WeeklyPVP_Label:SetFont(WeeklyPVP_Label:GetFont(), 14)
	end
end

function AMT:AMT_Title()
	--Find out the current expansion and season information to format the title.
	local currentDisplaySeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	if not currentDisplaySeason then
		PVEFrame:SetTitle(CHALLENGES)
		return
	end
	--Format the title of the tab to be "Advanced Mythic Tracker (Expansion Season #)"
	local currExpID = GetExpansionLevel()
	local expName = _G["EXPANSION_NAME" .. currExpID]
	local title = "Advanced Mythic Tracker (" .. expName .. " Season " .. currentDisplaySeason .. ")"
	PVEFrame:SetTitle(title)
end
