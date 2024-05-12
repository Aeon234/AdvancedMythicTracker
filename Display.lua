local addonName, AMT = ...

Difficulty_Label_XPos = 42
Difficulty_Label_YPos = 1
AMT_box_size = 14
AMT_VaultRaid_Num = 6
AMT_VaultDungeons_Num = 8
Tab = "          "
Whitetext = "|cffffffff"
BG_Transperancy = { 1, 1, 1, 0.0 }

function AMT:AMT_Window_Containers()
	--[[
	First column of AMT_Window
	***Important Reminder***
	Top of the frame (title bar) is 22 pixels tall, so need to offset the top anchor by -2
	Likewise all GetHeight calculations of AMT_Window needs to have 22 subtracted from it before finding total lenght
	Left of the frame has bleed of 3 pixels.
	]]
	local AMT_Window_X_Offset = 3
	local AMT_Window_Y_Offset = 22

	if not WeeklyBest_Compartment then
		WeeklyBest_Compartment = CreateFrame("Frame", "WeeklyBest_Compartment", AMT_Window, "BackdropTemplate")
		-- WeeklyBest_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		WeeklyBest_Compartment:SetSize(180, 82)

		WeeklyBest_Compartment:SetPoint("TOPLEFT", AMT_Window, "TOPLEFT", AMT_Window_X_Offset, -AMT_Window_Y_Offset)
		WeeklyBest_Compartment:SetBackdrop(BackdropInfo)

		WeeklyBest_Compartment:SetBackdropBorderColor(1, 0, 1, 0.0)
		WeeklyBest_Compartment:SetBackdropColor(unpack(BG_Transperancy))
	end

	if not CurrentKeystone_Compartment then
		CurrentKeystone_Compartment =
			CreateFrame("Frame", "CurrentKeystone_Compartment", AMT_Window, "BackdropTemplate")
		-- CurrentKeystone_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		CurrentKeystone_Compartment:SetSize(180, 170)

		CurrentKeystone_Compartment:SetPoint("BOTTOMLEFT", AMT_Window, "BOTTOMLEFT", AMT_Window_X_Offset, 0)
		CurrentKeystone_Compartment:SetBackdrop(BackdropInfo)

		CurrentKeystone_Compartment:SetBackdropBorderColor(1, 0, 1, 0.0)
		CurrentKeystone_Compartment:SetBackdropColor(unpack(BG_Transperancy))
	end

	if not Lockouts_Comparment then
		Lockouts_Comparment = CreateFrame("Frame", "Lockouts_Comparment", AMT_Window, "BackdropTemplate")
		-- CurrentKeystone_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		Lockouts_Comparment:SetSize(
			180,
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- WeeklyBest_Compartment:GetHeight()
				- CurrentKeystone_Compartment:GetHeight()
		)

		Lockouts_Comparment:SetPoint("TOP", WeeklyBest_Compartment, "BOTTOM", 0, 0)
		Lockouts_Comparment:SetBackdrop(BackdropInfo)

		Lockouts_Comparment:SetBackdropBorderColor(1, 0, 1, 0.0)
		Lockouts_Comparment:SetBackdropColor(unpack(BG_Transperancy))
	end

	--[[
	Second column of AMT_Window
	]]
	if not MythicScore_Container then
		MythicScore_Container = CreateFrame("Frame", "WeeklyBest_Compartment", AMT_Window, "BackdropTemplate")
		-- WeeklyBest_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		MythicScore_Container:SetSize(180, 60)

		MythicScore_Container:SetPoint("TOP", AMT_Window, "TOP", 0, -AMT_Window_Y_Offset)
		MythicScore_Container:SetBackdrop(BackdropInfo)

		MythicScore_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		MythicScore_Container:SetBackdropColor(unpack(BG_Transperancy))
	end
	--[[
	Third column of AMT_Window
	]]
	if not Affixes_Compartment then
		Affixes_Compartment = CreateFrame("Frame", "WeeklyBest_Compartment", AMT_Window, "BackdropTemplate")
		-- WeeklyBest_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		Affixes_Compartment:SetSize(160, 150)

		Affixes_Compartment:SetPoint("TOPRIGHT", AMT_Window, "TOPRIGHT", 0, -AMT_Window_Y_Offset)
		Affixes_Compartment:SetBackdrop(BackdropInfo)

		Affixes_Compartment:SetBackdropBorderColor(1, 0, 1, 0.0)
		Affixes_Compartment:SetBackdropColor(unpack(BG_Transperancy))
	end

	--[[
	Bottom Dungeons column of AMT_Window
	]]

	if not DungeonIcons_Container then
		DungeonIcons_Container = CreateFrame("Frame", "DungeonIcons_Container", AMT_Window, "BackdropTemplate")
		DungeonIcons_Container:SetSize(
			AMT_Window:GetWidth() - AMT_Window_X_Offset - CurrentKeystone_Compartment:GetWidth(),
			90
			-- (AMT_Window:GetWidth() - AMT_Window_X_Offset - CurrentKeystone_Compartment:GetWidth()) / 8 --102
		)

		DungeonIcons_Container:SetPoint("BOTTOMLEFT", CurrentKeystone_Compartment, "BOTTOMRIGHT", -1, 1)
		DungeonIcons_Container:SetBackdrop(BackdropInfo)

		DungeonIcons_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		DungeonIcons_Container:SetBackdropColor(0, 1, 1, 0.0)
	end

	--Create the rune art used that'll house the current key
	if not RuneArt then
		RuneArt = CreateFrame("Frame", "RuneTexture", CurrentKeystone_Compartment)
		RuneArt:SetPoint("BOTTOM", CurrentKeystone_Compartment, "BOTTOM", 0, 4)
		RuneArt:SetSize(160, 160)
		-- RuneArt:SetFrameStrata("HIGH")

		RuneArt.tex = RuneArt:CreateTexture()
		RuneArt.tex:SetAllPoints(RuneArt)
		RuneArt.tex:SetAtlas("Artifacts-CrestRune-Gold", false)
	end
	AMT:WeeklyBest_Display()
	AMT:AMT_DungeonList_Display()
	AMT:AMT_Affixes_Display()
	AMT:AMT_MythicScore_Display()
	AMT:KeystoneItem_Display()
	AMT:AMT_Raid()
	AMT:AMT_MythicPlus()
end

function AMT:WeeklyBest_Display()
	--Initiate a table that'll store all of our weekly keys
	KeysDone = {}
	--Grab Weekly Run history for this season and only timed keys
	WeeklyInfo = C_MythicPlus.GetRunHistory(false, true)
	--Grab Vault Rewards Info
	VaultInfo = C_WeeklyRewards.GetActivities()
	--For each key done insert them into KeysDone table
	for i = 1, #WeeklyInfo do
		local KeyLevel = WeeklyInfo[i].level
		local KeyID = WeeklyInfo[i].mapChallengeModeID
		tinsert(KeysDone, { level = KeyLevel, keyid = KeyID, keyname = "" })
	end
	--Sort KeysDone so that the highest keys are at the top. This is how we'll grab top key of the week info
	if KeysDone[1] == nil then
		KeysDone = { 0 }
	else
		table.sort(KeysDone, function(a, b)
			return b.level < a.level
		end)
		for _, entry in ipairs(KeysDone) do
			for _, dungeon in ipairs(SeasonalDungeons) do
				if entry.keyid == dungeon.challengeModeID then
					entry.keyname = dungeon.name
					break -- Once found, no need to continue searching
				end
			end
		end
	end
	--Establish the highest key done for the weekly currently
	local WeeklyBest_Key
	local WeeklyBest_Color
	if KeysDone[1] ~= 0 then
		WeeklyBest_Key = KeysDone[1].level
	else
		WeeklyBest_Key = KeysDone[1]
	end
	if KeysDone[1] ~= 0 then
		WeeklyBest_Color = C_ChallengeMode.GetKeystoneLevelRarityColor(KeysDone[1].level)
	else
		WeeklyBest_Color = C_ChallengeMode.GetKeystoneLevelRarityColor(2)
	end
	--Create the Compartment Title
	if not WeeklyBest_Label then
		WeeklyBest_Label = WeeklyBest_Compartment:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
		WeeklyBest_Label:SetPoint("TOP", 0, -2) -- Set the position of the text
		WeeklyBest_Label:SetText("Weekly Best") -- Set the text content
		WeeklyBest_Label:SetFont(WeeklyBest_Label:GetFont(), 20)
		WeeklyBest_Label:SetTextColor(1, 1, 1, 1.0)
	end

	--Generates the background where the weekly best key # is going to be displayed
	if not WeeklyBest_Bg then
		WeeklyBest_Bg = CreateFrame("Frame", "WeeklyBest_Bg", WeeklyBest_Compartment)
		WeeklyBest_Bg:SetSize(112, 50)
		WeeklyBest_Bg:SetPoint("TOP", WeeklyBest_Label, "BOTTOM", 0, -4)

		WeeklyBest_Bg.tex = WeeklyBest_Bg:CreateTexture()
		WeeklyBest_Bg.tex:SetAllPoints(WeeklyBest_Bg)
		WeeklyBest_Bg.tex:SetColorTexture(0.0, 0.0, 0.0, 0.6)
	end

	--Create the WeeklyBest_Keylevel if not already created
	if not WeeklyBest_Keylevel then
		WeeklyBest_Keylevel = WeeklyBest_Bg:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	end
	if KeysDone[1] == 0 then
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 3, 0)
		WeeklyBest_Keylevel:SetTextColor(0.804, 0.804, 0.804, 1.0)
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 38)
		WeeklyBest_Keylevel:SetText("N/A")
	else
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 0, 0)
		WeeklyBest_Keylevel:SetText(WeeklyBest_Color:WrapTextInColorCode("+" .. WeeklyBest_Key))
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 42)
		WeeklyBest_Keylevel:SetTextColor(1, 1, 1, 1.0)
		-- WeeklyBest_Keylevel:SetTextColor(0, 0.624, 0.863, 1.0)
	end
end

function AMT:AMT_DungeonList_Display()
	--Set up the table that will hold the Season's dungeon info
	local Current_SeasonalDung_Info = {}
	--Pull the dungeon info from the API and store the dungeon id, name and icon of each dungeon in the table above.
	local currentSeasonMap = C_ChallengeMode.GetMapTable()
	for i = 1, #currentSeasonMap do
		local dungeonID = currentSeasonMap[i]
		local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(dungeonID)
		local affixScores, bestOverAllScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(dungeonID)
		local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(dungeonID)
		local dungOverallScore = bestOverAllScore ~= nil and bestOverAllScore or 0
		local TyrDungScore = affixScores ~= nil and affixScores[1] ~= nil and affixScores[1].score or 0
		local FortDungScore = affixScores ~= nil and affixScores[2] ~= nil and affixScores[2].score or 0
		local TyrDungLevel = affixScores ~= nil and affixScores[1] ~= nil and affixScores[1].level or 0
		local FortDungLevel = affixScores ~= nil and affixScores[2] ~= nil and affixScores[2].level or 0
		tinsert(Current_SeasonalDung_Info, {
			dungID = dungeonID,
			dungName = name,
			dungIcon = icon,
			dungOverallScore = dungOverallScore,
			dungTyrScore = TyrDungScore,
			dungFortScore = FortDungScore,
			dungTyrLevel = TyrDungLevel,
			dungFortLevel = FortDungLevel,
		})
	end
	--Create the icon for each dungeon
	if not _G["DungeonIcon_" .. #Current_SeasonalDung_Info] then
		for i = 1, #Current_SeasonalDung_Info do
			local dungIconHeight = DungeonIcons_Container:GetHeight()
			local dungIconWidth = DungeonIcons_Container:GetWidth() / 8
			DungIcon = CreateFrame("Frame", "DungeonIcon_" .. i, DungeonIcons_Container)
			DungIcon:SetSize(dungIconWidth, dungIconHeight)
			DungIcon.tex = DungIcon:CreateTexture()
			DungIcon.tex:SetAllPoints(DungIcon)
			DungIcon.tex:SetTexture(Current_SeasonalDung_Info[i].dungIcon)

			if i == 1 then
				DungIcon:SetPoint("BOTTOMLEFT", DungeonIcons_Container, "BOTTOMLEFT", 0, 0)
			else
				local previousBox = _G["DungeonIcon_" .. (i - 1)]
				DungIcon:SetPoint("LEFT", previousBox, "RIGHT", 0, 0)
			end
		end
	end
	if not DungIconName_Label then
		for i = 1, #Current_SeasonalDung_Info do
			CurrentDungID = Current_SeasonalDung_Info[i].dungID
			DungIcon_Abbr = nil

			for j = 1, #SeasonalDungeons do
				if SeasonalDungeons[j].challengeModeID == CurrentDungID then
					DungIcon_Abbr = SeasonalDungeons[j].abbr
					break -- Exit loop once a match is found
				end
			end

			-- DungIcon_Abbr = DungeonAbbr[Current_SeasonalDung_Info[i].dungID]
			DungIconName_Label = DungIcon:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
			DungIconName_Label:SetPoint("TOP", _G["DungeonIcon_" .. i], "TOP", 0, 10)
			DungIconName_Label:SetFont(DungIconName_Label:GetFont(), 20, "OUTLINE")
			DungIconName_Label:SetTextColor(1, 1, 1)
			DungIconName_Label:SetText(DungIcon_Abbr)
		end
	end
	--Create label for Overall Dungeon Level
	if not DungOverallLevel_Label then
		for i = 1, #Current_SeasonalDung_Info do
			DungOverallLevel_Label =
				DungIcon:CreateFontString("DungOverallLevel_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungOverallLevel_Label:SetPoint("CENTER", _G["DungeonIcon_" .. i], "CENTER", 0, 2)
			DungOverallLevel_Label:SetFont(DungOverallLevel_Label:GetFont(), 32, "OUTLINE")
			DungOverallLevel_Label:SetTextColor(1, 1, 1)
			DungOverallLevel_Label:SetText("20")
		end
	end
	--Create label for Tyrannical Score Information
	if not DungTyrScore_Label then
		for i = 1, #Current_SeasonalDung_Info do
			DungTyrScore_Label =
				DungIcon:CreateFontString("DungTyrScore_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungTyrScore_Label:SetPoint("BOTTOMLEFT", _G["DungeonIcon_" .. i], "BOTTOMLEFT", 4, 2)
			DungTyrScore_Label:SetJustifyH("LEFT")
			DungTyrScore_Label:SetJustifyV("TOP")
			DungTyrScore_Label:SetFont(DungTyrScore_Label:GetFont(), 14, "OUTLINE")
			DungTyrScore_Label:SetTextColor(1, 1, 1)
			DungTyrScore_Label:SetText("T: 12\n132.5")
		end
	end
	--Create label for Fortified Score Information
	if not DungFortScore_Label then
		for i = 1, #Current_SeasonalDung_Info do
			DungFortScore_Label =
				DungIcon:CreateFontString("DungFortScore_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungFortScore_Label:SetPoint("BOTTOMRIGHT", _G["DungeonIcon_" .. i], "BOTTOMRIGHT", -2, 2)
			DungFortScore_Label:SetJustifyH("RIGHT")
			DungFortScore_Label:SetJustifyV("TOP")
			DungFortScore_Label:SetFont(DungFortScore_Label:GetFont(), 14, "OUTLINE")
			DungFortScore_Label:SetTextColor(1, 1, 1)
			DungFortScore_Label:SetText("F: 20\n242.6")
		end
	end
	--Update each of the labels with updated information each time AMT Window is opened
	for i = 1, #Current_SeasonalDung_Info do
		local Dung_HighestKey = 0
		local HighestKey_Label = _G["DungOverallLevel_Label" .. i]
		local Tyrranical_Label = _G["DungTyrScore_Label" .. i]
		local Fortified_Label = _G["DungFortScore_Label" .. i]
		if Current_SeasonalDung_Info[i].dungTyrLevel >= Current_SeasonalDung_Info[i].dungFortLevel then
			Dung_HighestKey = Current_SeasonalDung_Info[i].dungTyrLevel
		elseif Current_SeasonalDung_Info[i].dungFortLevel > Current_SeasonalDung_Info[i].dungTyrLevel then
			Dung_HighestKey = Current_SeasonalDung_Info[i].dungFortLevel
		else
			Dung_HighestKey = 0
		end
		--Grab the color information for the highest key level done
		Dung_HighestKey_Color = C_ChallengeMode.GetKeystoneLevelRarityColor(Dung_HighestKey)
		--Grab the color information for the tyrannical level
		TyrLevel_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrLevel).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrLevel).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrLevel).b
		)

		--Grab the color information for the fortified level
		FortLevel_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortLevel).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortLevel).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortLevel).b
		)
		--Grab the color information for the tyrannical score
		TyrScore_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrScore).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrScore).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungTyrScore).b
		)
		--Grab the color information for the fortified score
		FortScore_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortScore).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortScore).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(Current_SeasonalDung_Info[i].dungFortScore).b
		)
		--Set the Highest Key Level Label to be the highest key level number and appropriate color for it.
		HighestKey_Label:SetText(Dung_HighestKey)
		HighestKey_Label:SetTextColor(Dung_HighestKey_Color.r, Dung_HighestKey_Color.g, Dung_HighestKey_Color.b)

		--Set the highest Tyr dungeon score info
		Tyrranical_Label:SetText(
			"T: "
				.. TyrLevel_Color:WrapTextInColorCode(Current_SeasonalDung_Info[i].dungTyrLevel)
				.. "\n "
				.. TyrLevel_Color:WrapTextInColorCode(Current_SeasonalDung_Info[i].dungTyrScore)
		)
		--Set the highest Fort dungeon score info
		Fortified_Label:SetText(
			"F: "
				.. FortLevel_Color:WrapTextInColorCode(Current_SeasonalDung_Info[i].dungFortLevel)
				.. "\n"
				.. FortScore_Color:WrapTextInColorCode(Current_SeasonalDung_Info[i].dungFortScore)
		)
	end
end

function AMT:AMT_Affixes_Display()
	--Affixes_Compartment

	if #GetCurrentAffixesTable == 0 then
		local currentAffixes = C_MythicPlus.GetCurrentAffixes()
		if currentAffixes then
			GetCurrentAffixesTable = currentAffixes
		end
	end
	if #CurrentWeek_AffixTable == 0 then
		table.insert(
			CurrentWeek_AffixTable,
			{ GetCurrentAffixesTable[1].id, GetCurrentAffixesTable[2].id, GetCurrentAffixesTable[3].id }
		)
	end

	if not CurrentAffixes_Label then
		CurrentAffixes_Label = Affixes_Compartment:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
		CurrentAffixes_Label:SetPoint("TOPLEFT", 15, -2) -- Set the position of the text
		CurrentAffixes_Label:SetText("This Week") -- Set the text content
		CurrentAffixes_Label:SetFont(CurrentAffixes_Label:GetFont(), 20)
		CurrentAffixes_Label:SetTextColor(1, 1, 1, 1.0)
	end

	if not CurrentAffixes_Container then
		CurrentAffixes_Container = CreateFrame("Frame", "CurrentAffixes", Affixes_Compartment, "BackdropTemplate")
		-- CurrentKeystone_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		CurrentAffixes_Container:SetSize(Affixes_Compartment:GetWidth(), 50)

		CurrentAffixes_Container:SetPoint("TOP", Affixes_Compartment, "TOP", 0, -CurrentAffixes_Label:GetHeight())
		CurrentAffixes_Container:SetBackdrop(BackdropInfo)

		CurrentAffixes_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		CurrentAffixes_Container:SetBackdropColor(1, 0, 1, 0.0)
	end

	if not NextWeekAffixes_Label then
		NextWeekAffixes_Label = Affixes_Compartment:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
		NextWeekAffixes_Label:SetPoint("TOPLEFT", CurrentAffixes_Container, "BOTTOMLEFT", 15, -4) -- Set the position of the text
		NextWeekAffixes_Label:SetText("Next Week") -- Set the text content
		NextWeekAffixes_Label:SetFont(NextWeekAffixes_Label:GetFont(), 20)
		NextWeekAffixes_Label:SetTextColor(1, 1, 1, 1.0)
	end

	if not NextWeekAffixes_Container then
		NextWeekAffixes_Container = CreateFrame("Frame", "CurrentAffixes", Affixes_Compartment, "BackdropTemplate")
		-- CurrentKeystone_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		NextWeekAffixes_Container:SetSize(Affixes_Compartment:GetWidth(), CurrentAffixes:GetHeight())
		local _, _, _, _, NextWeekAffixes_Label_y = NextWeekAffixes_Label:GetPoint()
		NextWeekAffixes_Container:SetPoint(
			"TOP",
			CurrentAffixes_Container,
			"BOTTOM",
			0,
			-NextWeekAffixes_Label_y - NextWeekAffixes_Label:GetHeight() - 6
		)
		NextWeekAffixes_Container:SetBackdrop(BackdropInfo)

		NextWeekAffixes_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		NextWeekAffixes_Container:SetBackdropColor(1, 0, 1, 0.0)
	end

	GetNextAffixRotation(CurrentWeek_AffixTable, AffixRotation)

	for i = 1, #GetCurrentAffixesTable do
		for _, affixID in ipairs(CurrentWeek_AffixTable) do
			local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])

			if not _G["AffixIcon" .. #GetCurrentAffixesTable] then
				local iconSize = 40
				local iconPadding = 5
				AffixIcon = CreateFrame("Frame", "AffixIcon" .. i, CurrentAffixes_Container)
				AffixIcon:SetSize(iconSize, iconSize)
				AffixIcon.tex = AffixIcon:CreateTexture()
				AffixIcon.tex:SetAllPoints(AffixIcon)
				AffixIcon.tex:SetTexture(filedataid)
				if i == 1 then
					AffixIcon:SetPoint(
						"LEFT",
						CurrentAffixes_Container,
						"LEFT",
						(
							AffixIcon:GetParent():GetWidth()
							- (iconSize * #GetCurrentAffixesTable)
							- (iconPadding * (#GetCurrentAffixesTable - 1))
						) / 2,
						0
					)
				else
					AffixIcon:SetPoint("LEFT", _G["AffixIcon" .. i - 1], "RIGHT", iconPadding, 0)
				end
				AffixIcon:SetScript("OnEnter", function()
					GameTooltip:ClearAllPoints()
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(_G["AffixIcon" .. i], "ANCHOR_RIGHT")
					GameTooltip:SetText(name, 1, 1, 1, 1, true)
					GameTooltip:AddLine(description, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				AffixIcon:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			end
		end
	end

	for i = 1, #GetCurrentAffixesTable do
		for _, affixID in ipairs(NextWeek_AffixTable) do
			local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])

			if not _G["NexWeek_AffixIcon" .. #GetCurrentAffixesTable] then
				local iconSize = 40
				local iconPadding = 5
				AffixIcon = CreateFrame("Frame", "NexWeek_AffixIcon" .. i, NextWeekAffixes_Container)
				AffixIcon:SetSize(iconSize, iconSize)
				AffixIcon.tex = AffixIcon:CreateTexture()
				AffixIcon.tex:SetAllPoints(AffixIcon)
				AffixIcon.tex:SetTexture(filedataid)
				if i == 1 then
					AffixIcon:SetPoint(
						"LEFT",
						NextWeekAffixes_Container,
						"LEFT",
						(
							AffixIcon:GetParent():GetWidth()
							- (iconSize * #GetCurrentAffixesTable)
							- (iconPadding * (#GetCurrentAffixesTable - 1))
						) / 2,
						0
					)
				else
					AffixIcon:SetPoint("LEFT", _G["NexWeek_AffixIcon" .. i - 1], "RIGHT", iconPadding, 0)
				end
				AffixIcon:SetScript("OnEnter", function()
					GameTooltip:ClearAllPoints()
					GameTooltip:ClearLines()
					GameTooltip:SetOwner(_G["NexWeek_AffixIcon" .. i], "ANCHOR_RIGHT")
					GameTooltip:SetText(name, 1, 1, 1, 1, true)
					GameTooltip:AddLine(description, nil, nil, nil, true)
					GameTooltip:Show()
				end)
				AffixIcon:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)
			end
		end
	end
end

function AMT:AMT_MythicScore_Display()
	if not MythicScore_Title_Label then
		MythicScore_Title_Label = MythicScore_Container:CreateFontString(nil, "OVERLAY", "GameFontWhite")
		MythicScore_Title_Label:SetPoint("TOP", 0, -4)
		MythicScore_Title_Label:SetText("Mythic+ Rating")
		MythicScore_Title_Label:SetFont(MythicScore_Title_Label:GetFont(), 20)
		MythicScore_Title_Label:SetTextColor(1, 1, 1, 1.0)
	end
	--Update the player score + score color prior to generating the score label
	AMT:AMT_Update_PlayerMplus_Score()

	if not MythicScore_Label then
		MythicScore_Label = MythicScore_Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		MythicScore_Label:SetPoint("TOP", MythicScore_Title_Label, "BOTTOM", 0, -4)
		MythicScore_Label:SetText(Player_Mplus_Summary.currentSeasonScore)
		MythicScore_Label:SetFont(MythicScore_Label:GetFont(), 28)
		MythicScore_Label:SetTextColor(
			Player_Mplus_ScoreColor.r,
			Player_Mplus_ScoreColor.g,
			Player_Mplus_ScoreColor.b,
			1.0
		)
	else
		MythicScore_Label:SetText(Player_Mplus_Summary.currentSeasonScore)
		MythicScore_Label:SetTextColor(
			Player_Mplus_ScoreColor.r,
			Player_Mplus_ScoreColor.g,
			Player_Mplus_ScoreColor.b,
			1.0
		)
	end
end

function AMT:KeystoneItem_Display()
	--[[
Mythic Keystone Section
    --]]
	--Create the frame which will contain the icon texture of the Keystone
	if not KeystoneItem_Icon then
		KeystoneItem_Icon = CreateFrame("Frame", "KeystoneItem_Icon", RuneArt)
		KeystoneItem_Icon:SetPoint("CENTER")
		KeystoneItem_Icon.tex = KeystoneItem_Icon:CreateTexture()
		KeystoneItem_Icon.tex:SetAllPoints(KeystoneItem_Icon)
	end
	--Create the Glow Texture that will exist around the Keystone Icon
	if not KeystoneItem_Glow then
		KeystoneItem_Glow = CreateFrame("Frame", "KeystoneItem_Glow", RuneArt)
		KeystoneItem_Glow:SetPoint("CENTER")
		KeystoneItem_Glow:SetSize(80, 80)
		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetSize(65, 65)
		KeystoneItem_Glow.tex:SetAllPoints(KeystoneItem_Glow)
		-- KeystoneItem_Glow.tex:SetAtlas("BonusChest-ItemBorder-Uncommon")
	end
	--If the Label text hasn't been created, create it otherwise just update the label
	if not Keystone_DungName then
		local Keystone_DungName_Bg = CreateFrame("Frame", "CurrentKey_TopLabel", AMT_Window, "BackdropTemplate")
		Keystone_DungName_Bg:SetFrameLevel(4)
		Keystone_DungName_Bg:SetSize(78, 22)
		Keystone_DungName_Bg:SetPoint("BOTTOM", KeystoneItem_Icon, "TOP", 0, 12)
		Keystone_DungName_Bg:SetBackdrop(BackdropInfo)

		Keystone_DungName_Bg:SetBackdropBorderColor(0, 0, 0, 0.0)
		Keystone_DungName_Bg:SetBackdropColor(0, 0, 0, 0.50)

		Keystone_DungName = KeystoneItem_Icon:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		Keystone_DungName:SetPoint("CENTER", Keystone_DungName_Bg, "CENTER", 0, 1)
		Keystone_DungName:SetFont(Keystone_DungName:GetFont(), 14)
		--Create the frame that will hold the label above the Keystone Icon that shows the current key level and abbreviated name
	end
	--If a Keystone level is detected create the Icon Texture that belongs to the dungeon.
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		--Grab the ID of the Keystone player is holding
		local Keystone_ID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		--Grab the name and icon of the Dungeon the Keystone belongs to
		Keystone_Name, _, _, Keystone_Icon = C_ChallengeMode.GetMapUIInfo(Keystone_ID)
		--Get the abbreviated name of the dungeon the player has a key for
		local abbr = GetAbbrFromChallengeModeID(Keystone_ID)
		--Get the Keystone level
		Keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
		--Set Label text for Keystone info
		Keystone_DungName:SetText("+" .. Keystone_level .. " " .. abbr)
		--Set the icon textures
		KeystoneItem_Icon.tex:SetTexture(Keystone_Icon)
		KeystoneItem_Icon:SetSize(48, 48)
		KeystoneItem_Icon.tex:SetDesaturated(false)

		--Since Keystone was detected we now create a glow around the icon.
		KeystoneItem_Glow.tex:SetAtlas("BattleBar-Button-Highlight")
	else
		--If Great Vault Rewards are uncollected create the
		if C_WeeklyRewards.HasAvailableRewards() then
			Keystone_DungName:SetText("Pending Vault")
			KeystoneItem_Icon.tex:SetAtlas("CovenantChoice-Celebration-Content-Soulbind")
			KeystoneItem_Icon:SetSize(60, 60)
			KeystoneItem_Icon.tex:SetDesaturated(false)
		else
			Keystone_DungName:SetText("No Key")
			--If a Keystone level is not detected, we'll set the texture of the keystone to a default texture and a glow
			KeystoneItem_Icon.tex:SetTexture(4352494)
			KeystoneItem_Icon.tex:SetDesaturated(true)
			KeystoneItem_Icon:SetSize(48, 48)
			KeystoneItem_Glow.tex:SetAtlas("BattleBar-Button-Highlight")
		end
	end
	--No point attempting to catalog any of the below if a keystyone is not detected. It'll throw errors
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		--Start grabbing the information that will be displayed on the tooltip of the icon.
		local Keystone_mod = C_ChallengeMode.GetPowerLevelDamageHealthMod(Keystone_level)
		--% Modifier on Tyran/Fort weeks. Default is Tyran (id=9)
		local modFort = { 30, 15, 0, 0 }
		--Get current affixes and check to see if it's foritifed, if so adjust the modifiers.
		local affix = C_MythicPlus.GetCurrentAffixes()
		if affix then
			if affix[1].id == 10 then
				modFort = { 0, 0, 20, 30 }
			end
		end
		--Create modifiers which will store the tooltip info for the modifier info for the keystone held by the player
		Keystone_modifiers = BOSS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. Keystone_mod + modFort[1]
			.. "%\n"
			.. BOSS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. Keystone_mod + modFort[2]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. Keystone_mod + modFort[3]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. Keystone_mod + modFort[4]
			.. "%"
		--What would be the vault reward for completing this key
		VaultReward, DungeonReward = C_MythicPlus.GetRewardLevelForDifficultyLevel(Keystone_level)
		--Establish sections for current keystyone, modifiers, and TT rewards
		TT_KeystoneInfo = "|cffffffffKeystone: |cffc845fa" .. Keystone_Name .. " +" .. Keystone_level .. "\n\n"
		TT_DungeonModifiers = "|cffffffffDungeon Modifiers:|r\n" .. Keystone_modifiers .. "\n\n"
		TT_Rewards = "|cffffffffRewards:|r"
			.. "\n"
			.. "End of Dungeon: "
			.. DungeonReward
			.. "\n"
			.. "Great Vault: "
			.. VaultReward
			.. "\n\n"
	end
	-- local tab = "          "
	-- local Whitetext = "|cffffffff"
	--Create the default tooltip text for when the player doesn't have a Keystone
	if C_WeeklyRewards.HasAvailableRewards() then
		TT_NoKeystone = "Visit the Great Vault to collect your reward!"
	else
		TT_NoKeystone = "Get your Keystone by"
			.. "\n"
			.. Whitetext
			.. " • Completing any Dungeon on Mythic or Mythic Plus Difficulty"
			.. "\n"
			.. " • Speaking with Lindormi in Valdrakken"
	end
	--If player has RaiderIO enabled
	if RaiderIO then
		RIO_PlayerProfile = RaiderIO.GetProfile("player")
		--Grab the timed runs information for the player from the RIO addon
		if
			RIO_PlayerProfile == nil
			or RIO_PlayerProfile.mythicKeystoneProfile == nil
			or RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus == nil
		then
			--If timed runs don't exist create a default message
			TT_RaiderIO_NoRuns = "No timed runs found."
		else
			--If run information exists store that information so that we can use it in the tooltip.
			TT_RaiderIO_Title = "|cffffffffTimed Runs:"
			TT_RaiderIO_Total = "|cff009dd5"
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneTwentyPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneFifteenPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneTenPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus
				.. "+"
			TT_RaiderIO_20L = "   • For +20 "
			TT_RaiderIO_20R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneTwentyPlus .. "+"
			TT_RaiderIO_15L = "   • For +15 - 19 "
			TT_RaiderIO_15R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneFifteenPlus .. "+"
			TT_RaiderIO_10L = "   • For +10 - 14 "
			TT_RaiderIO_10R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneTenPlus .. "+"
			TT_RaiderIO_5L = "   • For +5 - 9 "
			TT_RaiderIO_5R = RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus .. "+"
			TT_RaiderIO = "Timed Runs|cff009dd5"
				.. Tab
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneTwentyPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneFifteenPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneTenPlus + RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus
				.. "+"
				.. "\n \n   • for +20 "
				.. Whitetext
				.. Tab
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneTwentyPlus
				.. "+"
				.. "\n\n   • for +15 "
				.. Whitetext
				.. Tab
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneFifteenPlus
				.. "+"
				.. "\n\n   • for +10 "
				.. Whitetext
				.. Tab
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneTenPlus
				.. "+"
				.. "\n\n   • for +5   "
				.. Whitetext
				.. Tab
				.. RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus
				.. "+"
		end
	end
	--Set up the tooltip for the Keystone Icon
	KeystoneItem_Icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if not C_MythicPlus.GetOwnedKeystoneLevel() then
			GameTooltip:AddLine(TT_NoKeystone)
		else
			GameTooltip:AddLine(TT_KeystoneInfo)
			GameTooltip:AddLine(TT_DungeonModifiers)
			GameTooltip:AddLine(TT_Rewards)
			if RaiderIO then
				if
					RIO_PlayerProfile == nil
					or RIO_PlayerProfile.mythicKeystoneProfile == nil
					or RIO_PlayerProfile.mythicKeystoneProfile.keystoneFivePlus == nil
				then
					GameTooltip:AddLine(TT_RaiderIO_NoRuns)
				else
					GameTooltip:AddDoubleLine(TT_RaiderIO_Title, TT_RaiderIO_Total)
					GameTooltip:AddDoubleLine(TT_RaiderIO_20L, TT_RaiderIO_20R)
					GameTooltip:AddDoubleLine(TT_RaiderIO_15L, TT_RaiderIO_15R)
					GameTooltip:AddDoubleLine(TT_RaiderIO_10L, TT_RaiderIO_10R)
					GameTooltip:AddDoubleLine(TT_RaiderIO_5L, TT_RaiderIO_5R)
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

	--Create the Great Vault Button
	if not GreatVault_Button then
		GreatVault_Button = CreateFrame("Button", "GreatVault_Button", AMT_Window, "BackdropTemplate")
		GreatVault_Button:SetPoint("TOP", KeystoneItem_Icon, "BOTTOM", 0, -16)
		GreatVault_Button:SetFrameLevel(4)
		GreatVault_Button:SetSize(76, 22)
		GreatVault_Button:SetText("Open Vault")
		GreatVault_Button.tex = GreatVault_Button:CreateTexture()
		GreatVault_Button.tex:SetAllPoints(GreatVault_Button)
		GreatVault_Button.tex:SetAtlas("SquareMask")
		GreatVault_Button.tex:SetVertexColor(0, 0, 0, 1.0)

		GreatVault_ButtonBorder = CreateFrame("Frame", "GreatVault_ButtonBorder", GreatVault_Button)
		GreatVault_ButtonBorder:SetSize(GreatVault_Button:GetWidth() + 2, GreatVault_Button:GetHeight() + 3)
		GreatVault_ButtonBorder:SetPoint("CENTER", GreatVault_Button, "CENTER")

		GreatVault_ButtonBorder.tex = GreatVault_ButtonBorder:CreateTexture("GreatVault_ButtonBorderTexture")
		GreatVault_ButtonBorder.tex:SetAtlas("SquareMask")
		GreatVault_ButtonBorder.tex:SetVertexColor(1, 0.784, 0.047, 0.75)
		GreatVault_ButtonBorder.tex:SetAllPoints()
		GreatVault_ButtonBorder:SetFrameLevel(3)

		GreatVault_Buttonlabel = KeystoneItem_Icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		GreatVault_Buttonlabel:SetPoint("CENTER", GreatVault_Button, "CENTER", 0, 1)
		GreatVault_Buttonlabel:SetText(" Open Vault ")
		GreatVault_Buttonlabel:SetFont(GreatVault_Buttonlabel:GetFont(), 12, "OUTLINE")
		GreatVault_Buttonlabel:SetTextColor(1, 0.784, 0.047)
	end

	--Create the interactions on hover, unhover, and onclick
	GreatVault_Button:SetScript("OnEnter", function()
		GreatVault_ButtonBorder.tex:SetVertexColor(0, 0.624, 0.863, 1.0)
	end)

	GreatVault_Button:SetScript("OnLeave", function()
		GreatVault_ButtonBorder.tex:SetVertexColor(1, 0.784, 0.047, 0.75)
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

function AMT:AMT_Raid()
	--Creates the Raid Header
	if not Raid_Goals_Header then
		Raid_Goals_Header = CreateFrame("Frame", "Raid_Goals_Header", Lockouts_Comparment, "BackdropTemplate")
		Raid_Goals_Header:SetSize(180, 18)

		Raid_Goals_Header:SetPoint("TOP", Lockouts_Comparment, "TOP", 0, 0)
		Raid_Goals_Header:SetBackdrop(BackdropInfo)

		Raid_Goals_Header:SetBackdropBorderColor(1, 0, 1, 0.0)
		Raid_Goals_Header:SetBackdropColor(1, 1, 1, 0.0)
	end
	--Create the Raid Section Header
	if not WeeklyRaid_Label then
		WeeklyRaid_Label = Raid_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyRaid_Label:SetPoint("TOPLEFT", Lockouts_Comparment, "TOPLEFT", 6, 0)
		WeeklyRaid_Label:SetText("Raid:")
		WeeklyRaid_Label:SetFont(WeeklyRaid_Label:GetFont(), 14)
	end
	--[[
Raid Lockout / Raid Kills per Difficulty
]]
	--
	--Get what the current season is and establish the name of the raid
	local seasonID = C_MythicPlus.GetCurrentSeason()
	raids = AMT:Filter_Table(SeasonalRaids, function(SeasonalRaids)
		return SeasonalRaids.seasonID == seasonID
	end)

	table.sort(raids, function(a, b)
		return a.order < b.order
	end)
	--Check Instance Lockouts. For each lockout save lockout information
	local numSavedInstances = GetNumSavedInstances()
	raids.savedInstances = {}
	if numSavedInstances > 0 then
		for savedInstanceIndex = 1, numSavedInstances do
			local name, lockoutId, reset, difficultyID, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID =
				GetSavedInstanceInfo(savedInstanceIndex)
			local raid = AMT:Get_Table(raids, "instanceID", instanceID)
			local savedInstance = {
				index = savedInstanceIndex,
				id = lockoutId,
				name = name,
				lockoutId = lockoutId,
				reset = reset,
				difficultyID = difficultyID,
				locked = locked,
				extended = extended,
				instanceIDMostSig = instanceIDMostSig,
				isRaid = isRaid,
				maxPlayers = maxPlayers,
				difficultyName = difficultyName,
				numEncounters = numEncounters,
				encounterProgress = encounterProgress,
				extendDisabled = extendDisabled,
				instanceID = instanceID,
				link = GetSavedInstanceChatLink(savedInstanceIndex),
				expires = 0,
				encounters = {},
			}
			if reset and reset > 0 then
				savedInstance.expires = reset + time()
			end
			--For each instance, go through each boss/encounter of the raid and see whether they've been killed.
			for encounterIndex = 1, numEncounters do
				local bossName, fileDataID, killed = GetSavedInstanceEncounterInfo(savedInstanceIndex, encounterIndex)
				local instanceEncounterID = 0
				if raid then
					AMT:Table_Recall(raid.encounters, function(encounter)
						if string.lower(encounter.name) == string.lower(bossName) then
							instanceEncounterID = encounter.instanceEncounterID
						end
					end)
				end
				local encounter = {
					index = encounterIndex,
					instanceEncounterID = instanceEncounterID,
					bossName = bossName,
					fileDataID = fileDataID or 0,
					killed = killed,
				}
				savedInstance.encounters[encounterIndex] = encounter
			end
			raids.savedInstances[savedInstanceIndex] = savedInstance
		end
	end
	--Create the frames that will store the boxes for each difficulty, running through each difficulty level for the current season's Raid
	if not Raid_MainFrame then
		for i, difficulty in ipairs(RaidDifficulty_Levels) do
			Raid_MainFrame = CreateFrame("Frame", "RaidDifficulty" .. i, Lockouts_Comparment, "BackdropTemplate")
			Raid_MainFrame:SetSize(180, 20)

			Raid_MainFrame:SetBackdrop(BackdropInfo)
			Raid_MainFrame:SetBackdropBorderColor(1, 0, 1, 0.00)
			Raid_MainFrame:SetBackdropColor(1, 1, 1, 0.00)

			Raid_MainFrame_LabelFrame =
				CreateFrame("Frame", "Raid_MainFrame_Label" .. i, _G["RaidDifficulty" .. i], "BackdropTemplate")
			Raid_MainFrame_LabelFrame:SetSize(42, 22)
			Raid_MainFrame_LabelFrame:SetBackdrop(BackdropInfo)
			Raid_MainFrame_LabelFrame:SetPoint("LEFT", _G["RaidDifficulty" .. i], "LEFT", 0, 0)
			Raid_MainFrame_LabelFrame:SetBackdropBorderColor(1, 0, 1, 0.00)
			Raid_MainFrame_LabelFrame:SetBackdropColor(0, 1, 1, 0.00)

			local RaidDifficulty_Label =
				Raid_MainFrame_LabelFrame:CreateFontString("RaidDifficuly_Label" .. i, "OVERLAY", "MovieSubtitleFont")
			RaidDifficulty_Label:SetPoint("RIGHT", Raid_MainFrame_LabelFrame, "RIGHT", 0, 0)
			RaidDifficulty_Label:SetText("|cffffffff" .. difficulty.label)
			RaidDifficulty_Label:SetFont(RaidDifficulty_Label:GetFont(), 14)
			RaidDifficulty_Label:SetJustifyH("RIGHT")
			RaidDifficulty_Label:SetJustifyV("MIDDLE")

			Raid_MainFrame_BoxFrame =
				CreateFrame("Frame", "Raid_MainFrame_BoxFrame" .. i, Raid_MainFrame, "BackdropTemplate")
			Raid_MainFrame_BoxFrame:SetSize(148, 22)
			Raid_MainFrame_BoxFrame:SetBackdrop(BackdropInfo)
			Raid_MainFrame_BoxFrame:SetPoint("LEFT", RaidDifficulty_Label, "RIGHT", 0, 0)
			Raid_MainFrame_BoxFrame:SetBackdropBorderColor(1, 0, 1, 0.00)
			Raid_MainFrame_BoxFrame:SetBackdropColor(1, 1, 0, 0.00)

			if i == 1 then
				Raid_MainFrame:SetPoint("TOPLEFT", Raid_Goals_Header, "BOTTOMLEFT", 0, 4)
			else
				local previousFrame = _G["RaidDifficulty" .. (i - 1)]
				Raid_MainFrame:SetPoint("TOP", previousFrame, "BOTTOM", 0, 0)
			end
			for raidIndex, raid in ipairs(SeasonalRaids) do
				Raid_MainFrame:SetScript("OnEnter", function()
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
				Raid_MainFrame:SetScript("OnLeave", function()
					GameTooltip:Hide()
					_G["RaidDifficulty" .. i]:SetBackdropColor(1, 1, 1, 0)
				end)
			end
		end
	end
	--Create the boxes within the frames for each difficulty
	for i, difficulty in ipairs(RaidDifficulty_Levels) do
		local DifficultyName = difficulty.abbr
		for n = 1, AMT_VaultRaid_Num do
			RaidBox = CreateFrame("Frame", DifficultyName .. n, _G["RaidDifficulty" .. i])
			RaidBox:SetSize(AMT_box_size, AMT_box_size)

			RaidBox.tex = RaidBox:CreateTexture()
			RaidBox.tex:SetAllPoints(RaidBox)
			RaidBox.tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

			if n == 1 then
				RaidBox:SetPoint("LEFT", _G["Raid_MainFrame_BoxFrame" .. i], "LEFT", 0, 0)
			else
				local previousBox = _G[DifficultyName .. (n - 1)]

				RaidBox:SetPoint("LEFT", previousBox, "RIGHT", 3, 0)
			end
		end
	end
	-- for num, diff in ipairs(Weekly_KillCount) do
	-- 	diff.kills = 0
	-- 	for raidIndex, raid in ipairs(SeasonalRaids) do
	-- 		for i, difficulty in ipairs(RaidDifficulty_Levels) do
	-- 			for _, encounter in ipairs(raid.encounters) do
	-- 				if raids.savedInstances then
	-- 					local savedInstance = AMT:Find_Table(raids.savedInstances, function(savedInstance)
	-- 						return savedInstance.difficultyID == difficulty.id
	-- 							and savedInstance.instanceID == raid.instanceID
	-- 							and savedInstance.expires > time()
	-- 					end)
	-- 					if savedInstance ~= nil then
	-- 						local savedEncounter = AMT:Find_Table(savedInstance.encounters, function(enc)
	-- 							if strcmputf8i(enc.bossName, encounter.name) == 0 then
	-- 								return strcmputf8i(enc.bossName, encounter.name) == 0
	-- 									and enc.instanceEncounterID == encounter.instanceEncounterID
	-- 									and enc.killed == true
	-- 							end
	-- 						end)
	-- 						if savedEncounter ~= nil then
	-- 							diff.kills = diff.kills + 1
	-- 						end
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function AMT:AMT_MythicPlus()
	--Creates the Mythic Plus Header
	if not Mplus_Goals_Header then
		Mplus_Goals_Header = CreateFrame("Frame", "Mplus_Goals_Header", Lockouts_Comparment, "BackdropTemplate")
		Mplus_Goals_Header:SetSize(180, 18)

		Mplus_Goals_Header:SetPoint("TOP", RaidDifficulty4, "BOTTOM", 0, 0)
		Mplus_Goals_Header:SetBackdrop(BackdropInfo)

		Mplus_Goals_Header:SetBackdropBorderColor(1, 0, 1, 0.0)
		Mplus_Goals_Header:SetBackdropColor(1, 1, 1, 0.0)
	end
	--Create the Mplus Section Header
	if not WeeklyMplus_Label then
		WeeklyMplus_Label = Mplus_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyMplus_Label:SetPoint("TOPLEFT", Mplus_Goals_Header, "TOPLEFT", 6, 0)
		WeeklyMplus_Label:SetText("Mythic+:")
		WeeklyMplus_Label:SetFont(WeeklyMplus_Label:GetFont(), 14)
	end
	--Create the Mythic Plus Main Frame that will house the label and the boxes
	if not Mplus_Mainframe then
		Mplus_Mainframe = CreateFrame("Frame", "Mplus_Mainframe", Lockouts_Comparment, "BackdropTemplate")
		Mplus_Mainframe:SetSize(180, 22)

		Mplus_Mainframe:SetBackdrop(BackdropInfo)
		Mplus_Mainframe:SetPoint("TOPLEFT", Mplus_Goals_Header, "BOTTOMLEFT", 0, 4)
		Mplus_Mainframe:SetBackdropBorderColor(1, 0, 1, 0.00)
		Mplus_Mainframe:SetBackdropColor(1, 0, 1, 0.00)

		Mplus_MainFrame_LabelFrame = CreateFrame("Frame", "Mplus_MainFrame_Label", Mplus_Mainframe, "BackdropTemplate")
		Mplus_MainFrame_LabelFrame:SetSize(42, 22)
		Mplus_MainFrame_LabelFrame:SetBackdrop(BackdropInfo)
		Mplus_MainFrame_LabelFrame:SetPoint("LEFT", Mplus_Mainframe, "LEFT", 0, 0)
		Mplus_MainFrame_LabelFrame:SetBackdropBorderColor(1, 0, 1, 0.00)
		Mplus_MainFrame_LabelFrame:SetBackdropColor(0, 1, 1, 0.00)

		local MplusDifficulty_Label =
			Mplus_MainFrame_LabelFrame:CreateFontString("MplusDifficulty_Label", "OVERLAY", "MovieSubtitleFont")
		MplusDifficulty_Label:SetPoint("RIGHT", Mplus_MainFrame_LabelFrame, "RIGHT", 0, 0)
		MplusDifficulty_Label:SetText("|cffffffffM - ")
		MplusDifficulty_Label:SetFont(MplusDifficulty_Label:GetFont(), 14)
		MplusDifficulty_Label:SetJustifyH("RIGHT")
		MplusDifficulty_Label:SetJustifyV("MIDDLE")

		Mplus_MainFrame_BoxFrame = CreateFrame("Frame", "Mplus_MainFrame_BoxFrame", Mplus_Mainframe, "BackdropTemplate")
		Mplus_MainFrame_BoxFrame:SetSize(148, 22)
		Mplus_MainFrame_BoxFrame:SetBackdrop(BackdropInfo)
		Mplus_MainFrame_BoxFrame:SetPoint("LEFT", Mplus_MainFrame_LabelFrame, "RIGHT", 0, 0)
		Mplus_MainFrame_BoxFrame:SetBackdropBorderColor(1, 0, 1, 0.00)
		Mplus_MainFrame_BoxFrame:SetBackdropColor(1, 1, 0, 0.00)
	end
	Mplus_Mainframe:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(Mplus_Mainframe, "ANCHOR_RIGHT")
		GameTooltip:SetText("Mythic Plus Progress", 1, 1, 1, 1, true)
		if KeysDone[1] ~= 0 then
			GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", #KeysDone))
		else
			GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", 0))
		end
		if KeysDone[1] ~= 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Top 8 Runs This Week")
			for i = 1, 8 do
				if KeysDone[i] then
					GameTooltip:AddLine(Whitetext .. KeysDone[i].level .. " - " .. KeysDone[i].keyname)
				end
			end
		end
		Mplus_Mainframe:SetBackdropColor(1, 1, 1, 0.25)
		GameTooltip:Show()
	end)
	Mplus_Mainframe:SetScript("OnLeave", function()
		GameTooltip:Hide()
		Mplus_Mainframe:SetBackdropColor(1, 1, 1, 0)
	end)

	if not _G["Mplus_Box" .. AMT_VaultDungeons_Num] then
		for i = 1, AMT_VaultDungeons_Num do
			local AMT_box_size = 14

			Mplus_Box = CreateFrame("Frame", "Mplus_Box" .. i, Mplus_MainFrame_BoxFrame)
			Mplus_Box:SetSize(AMT_box_size, AMT_box_size)

			Mplus_Box.tex = Mplus_Box:CreateTexture()
			Mplus_Box.tex:SetAllPoints(Mplus_Box)
			Mplus_Box.tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

			if i == 1 then
				Mplus_Box:SetPoint("LEFT", Mplus_MainFrame_BoxFrame, "LEFT", 0, 0)
			else
				local previousBox = _G["Mplus_Box" .. (i - 1)]
				Mplus_Box:SetPoint("LEFT", previousBox, "RIGHT", 3, 0)
			end
		end
	end

	WeeklyKeysHistory = {}

	for i = 1, AMT_VaultDungeons_Num do
		if i <= #KeysDone and #WeeklyInfo > 0 then
			tinsert(WeeklyKeysHistory, KeysDone[i].level)
		else
			break -- Exit the loop if KeysDone[i] or KeysDone[i].level doesn't exist
		end
	end

	for i = 1, AMT_VaultDungeons_Num do
		if WeeklyKeysHistory[i] ~= nil and WeeklyKeysHistory[i] > 0 then
			if i == 1 or i == 4 or i == 8 then
				_G["Mplus_Box" .. i].tex:SetColorTexture(1, 0.784, 0.047, 1.0)
			else
				_G["Mplus_Box" .. i].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0)
			end
		end
	end
end
