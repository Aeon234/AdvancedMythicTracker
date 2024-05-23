local addonName, AMT = ...

local E, S
if AMT.ElvUIEnabled then
	E = unpack(ElvUI)
	S = ElvUI[1]:GetModule("Skins")
	AMT_ElvUIEnabled = true
end

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
	local AMT_Window_X_Offset = 4
	local AMT_Window_Y_Offset = 22
	local AMT_Window = _G["AMT_Window"]
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

	--[[
		Third column of AMT_Window
		]]
	if not Affixes_Compartment then
		Affixes_Compartment = CreateFrame("Frame", "WeeklyBest_Compartment", AMT_Window, "BackdropTemplate")
		-- WeeklyBest_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		Affixes_Compartment:SetSize(200, 150)

		Affixes_Compartment:SetPoint("TOPRIGHT", AMT_Window, "TOPRIGHT", -AMT_Window_X_Offset, -AMT_Window_Y_Offset)
		Affixes_Compartment:SetBackdrop(BackdropInfo)

		Affixes_Compartment:SetBackdropBorderColor(1, 0, 1, 0.0)
		Affixes_Compartment:SetBackdropColor(unpack(BG_Transperancy))
	end

	if not PartyKeystone_Container then
		PartyKeystone_Container = CreateFrame("Frame", "PartyKeystone_Container", AMT_Window)
		if AMT_ElvUIEnabled then
			PartyKeystone_Container:SetTemplate("Transparent")
		end
		PartyKeystone_Container:SetSize(
			200,
			AMT_Window:GetHeight()
				- AMT_Window_Y_Offset
				- Affixes_Compartment:GetHeight()
				- DungeonIcons_Container:GetHeight()
				- 12
		)

		PartyKeystone_Container:SetPoint("TOPRIGHT", Affixes_Compartment, "BOTTOMRIGHT", 0, 0)
	end

	if not PartyKeystone_Container_Title then
		PartyKeystone_Container_Title = PartyKeystone_Container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		PartyKeystone_Container_Title:SetPoint("TOPLEFT", PartyKeystone_Container, "TOPLEFT", 6, -6)
		PartyKeystone_Container_Title:SetJustifyH("LEFT")
		PartyKeystone_Container_Title:SetFont(PartyKeystone_Container_Title:GetFont(), 14)

		PartyKeystone_Container_Title:SetText("Party Keystones")
	end
	if self.DetailsLoaded then
		if not PartyKeystone_DetailsButton then
			PartyKeystone_DetailsButton = CreateFrame("Button", nil, PartyKeystone_Container, "UIPanelButtonTemplate")
			if AMT_ElvUIEnabled then
				S:HandleButton(PartyKeystone_DetailsButton)
			end
			PartyKeystone_DetailsButton:SetSize(60, 16)
			PartyKeystone_DetailsButton:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -4, -4)
			PartyKeystone_DetailsButton:SetText("More")
			PartyKeystone_DetailsButton.Text:SetFont(PartyKeystone_DetailsButton.Text:GetFont(), 12)
		end
		PartyKeystone_DetailsButton:SetScript("OnClick", function()
			if _G.SlashCmdList["KEYSTONE"] then
				_G.SlashCmdList["KEYSTONE"]("")
			end
		end)
	else
		if not PartyKeystyone_MissingDetails then
			PartyKeystyone_MissingDetails =
				CreateFrame("Frame", "PartyKeystyone_MissingDetails", PartyKeystone_Container)
			-- PartyKeystyone_MissingDetails:SetPoint("LEFT", PartyKeystone_Container_Title, "RIGHT", 6, 0)
			PartyKeystyone_MissingDetails:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -4, -4)
			PartyKeystyone_MissingDetails:SetSize(24, 24)
			-- RuneArt:SetFrameStrata("HIGH")

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

	--[[
		Second column of AMT_Window
		]]
	if not MythicScore_Container then
		MythicScore_Container = CreateFrame("Button", "MythicScore_Container", AMT_Window, "BackdropTemplate")
		-- WeeklyBest_Compartment:SetSize(AMT_Window:GetWidth() * 0.18, 180)
		MythicScore_Container:SetSize(180, 60)

		MythicScore_Container:SetPoint("TOP", AMT_Window, "TOP", 0, -AMT_Window_Y_Offset)
		MythicScore_Container:SetBackdrop(BackdropInfo)

		MythicScore_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		MythicScore_Container:SetBackdropColor(unpack(BG_Transperancy))
	end

	if not MythicRunsGraph_Container then
		MythicRunsGraph_Container = CreateFrame("Frame", "MythicRunsGraph_Container", AMT_Window, "BackdropTemplate")
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
		MythicRunsGraph_Container:SetBackdrop(BackdropInfo)

		MythicRunsGraph_Container:SetBackdropBorderColor(1, 0, 1, 0.0)
		MythicRunsGraph_Container:SetBackdropColor(unpack(BG_Transperancy))
	end

	--Create the rune art used that'll house the current key
	if not RuneArt then
		RuneArt = CreateFrame("Frame", "RuneTexture", CurrentKeystone_Compartment)
		RuneArt:SetPoint("BOTTOM", CurrentKeystone_Compartment, "BOTTOM", 0, 4)
		RuneArt:SetSize(160, 160)

		RuneArt.tex = RuneArt:CreateTexture()
		RuneArt.tex:SetAllPoints(RuneArt)
		RuneArt.tex:SetAtlas("Artifacts-CrestRune-Gold", false)
	end
	AMT:AMT_WeeklyBest_Display()
	AMT:AMT_DungeonList_Display()
	AMT:AMT_Affixes_Display()
	AMT:AMT_MythicScore_Display()
	AMT:AMT_KeystoneItem_Display()
	AMT:AMT_Raid()
	AMT:AMT_MythicPlus()
	AMT:AMT_MythicRunsGraph()
	if IsInGroup() and Details then
		self.OpenRaidLib.RequestKeystoneDataFromParty()
		C_Timer.After(0.5, function()
			AMT:AMT_PartyKeystone()
		end)
		C_Timer.After(2, function()
			AMT:AMT_PartyKeystone()
		end)
	else
		AMT:AMT_PartyKeystone()
	end
end

function AMT:AMT_WeeklyBest_Display()
	--Establish the highest key done for the weekly currently
	WeeklyBest_Key = 0
	local WeeklyBest_Color
	if self.KeysDone[1] ~= 0 then
		WeeklyBest_Key = self.KeysDone[1].level
	else
		WeeklyBest_Key = self.KeysDone[1]
	end
	if self.KeysDone[1] ~= 0 then
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
	if self.KeysDone[1] == 0 then
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 3, 0)
		WeeklyBest_Keylevel:SetTextColor(0.804, 0.804, 0.804, 1.0)
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 38)
		WeeklyBest_Keylevel:SetText("-")
	else
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 0, 0)
		WeeklyBest_Keylevel:SetText(WeeklyBest_Color:WrapTextInColorCode(WeeklyBest_Key))
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 42)
		WeeklyBest_Keylevel:SetTextColor(1, 1, 1, 1.0)
		-- WeeklyBest_Keylevel:SetTextColor(0, 0.624, 0.863, 1.0)
	end
end

function AMT:AMT_DungeonList_Display()
	--Create the icon for each dungeon
	local DungIcon = {}
	if not _G["DungeonIcon_" .. #self.Current_SeasonalDung_Info] then
		for i = 1, #self.Current_SeasonalDung_Info do
			local dungIconHeight = DungeonIcons_Container:GetHeight()
			local dungIconWidth = DungeonIcons_Container:GetWidth() / 8
			DungIcon[i] =
				CreateFrame("Button", "DungeonIcon_" .. i, DungeonIcons_Container, "InsecureActionButtonTemplate")
			DungIcon[i]:SetSize(dungIconWidth, dungIconHeight)
			DungIcon.tex = DungIcon[i]:CreateTexture()
			DungIcon.tex:SetAllPoints(DungIcon[i])
			DungIcon.tex:SetTexture(self.Current_SeasonalDung_Info[i].dungIcon)

			if i == 1 then
				DungIcon[i]:SetPoint("BOTTOMLEFT", DungeonIcons_Container, "BOTTOMLEFT", 0, 0)
			else
				local previousBox = _G["DungeonIcon_" .. (i - 1)]
				DungIcon[i]:SetPoint("LEFT", previousBox, "RIGHT", 0, 0)
			end
		end
	end
	if not DungIconName_Label then
		for i = 1, #self.Current_SeasonalDung_Info do
			CurrentmapID = self.Current_SeasonalDung_Info[i].mapID
			DungIcon_Abbr = nil

			for j = 1, #AMT.SeasonalDungeons do
				if AMT.SeasonalDungeons[j].challengeModeID == CurrentmapID then
					DungIcon_Abbr = AMT.SeasonalDungeons[j].abbr
					break -- Exit loop once a match is found
				end
			end

			-- DungIcon_Abbr = DungeonAbbr[self.Current_SeasonalDung_Info[i].mapID]
			DungIconName_Label = DungIcon[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
			DungIconName_Label:SetPoint("TOP", _G["DungeonIcon_" .. i], "TOP", 0, 10)
			DungIconName_Label:SetFont(DungIconName_Label:GetFont(), 20, "OUTLINE")
			DungIconName_Label:SetTextColor(1, 1, 1)
			DungIconName_Label:SetText(DungIcon_Abbr)
		end
	end
	--Create label for Overall Dungeon Level
	if not DungOverallLevel_Label then
		for i = 1, #self.Current_SeasonalDung_Info do
			DungOverallLevel_Label =
				DungIcon[i]:CreateFontString("DungOverallLevel_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungOverallLevel_Label:SetPoint("CENTER", _G["DungeonIcon_" .. i], "CENTER", 0, 2)
			DungOverallLevel_Label:SetFont(DungOverallLevel_Label:GetFont(), 32, "OUTLINE")
			DungOverallLevel_Label:SetTextColor(1, 1, 1)
			DungOverallLevel_Label:SetText("20")
		end
	end
	--Create label for Tyrannical Score Information
	if not DungTyrScore_Label then
		for i = 1, #self.Current_SeasonalDung_Info do
			DungTyrScore_Label =
				DungIcon[i]:CreateFontString("DungTyrScore_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
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
		for i = 1, #self.Current_SeasonalDung_Info do
			DungFortScore_Label =
				DungIcon[i]:CreateFontString("DungFortScore_Label" .. i, "OVERLAY", "GameFontHighlightOutline22")
			DungFortScore_Label:SetPoint("BOTTOMRIGHT", _G["DungeonIcon_" .. i], "BOTTOMRIGHT", -2, 2)
			DungFortScore_Label:SetJustifyH("RIGHT")
			DungFortScore_Label:SetJustifyV("TOP")
			DungFortScore_Label:SetFont(DungFortScore_Label:GetFont(), 14, "OUTLINE")
			DungFortScore_Label:SetTextColor(1, 1, 1)
			DungFortScore_Label:SetText("F: 20\n242.6")
		end
	end
	--Update each of the labels with updated information each time AMT Window is opened
	for i = 1, #self.Current_SeasonalDung_Info do
		local Dung_HighestKey = 0
		local HighestKey_Label = _G["DungOverallLevel_Label" .. i]
		local Tyrranical_Label = _G["DungTyrScore_Label" .. i]
		local Fortified_Label = _G["DungFortScore_Label" .. i]
		if self.Current_SeasonalDung_Info[i].dungTyrLevel >= self.Current_SeasonalDung_Info[i].dungFortLevel then
			Dung_HighestKey = self.Current_SeasonalDung_Info[i].dungTyrLevel
		elseif self.Current_SeasonalDung_Info[i].dungFortLevel > self.Current_SeasonalDung_Info[i].dungTyrLevel then
			Dung_HighestKey = self.Current_SeasonalDung_Info[i].dungFortLevel
		else
			Dung_HighestKey = 0
		end
		--Grab the color information for the highest key level done
		Dung_HighestKey_Color = C_ChallengeMode.GetKeystoneLevelRarityColor(Dung_HighestKey)
		--Grab the color information for the tyrannical level
		TyrLevel_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrLevel).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrLevel).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrLevel).b
		)

		--Grab the color information for the fortified level
		FortLevel_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortLevel).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortLevel).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortLevel).b
		)
		--Grab the color information for the tyrannical score
		TyrScore_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrScore).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrScore).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungTyrScore).b
		)
		--Grab the color information for the fortified score
		FortScore_Color = CreateColor(
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortScore).r,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortScore).g,
			C_ChallengeMode.GetKeystoneLevelRarityColor(self.Current_SeasonalDung_Info[i].dungFortScore).b
		)
		--Set the Highest Key Level Label to be the highest key level number and appropriate color for it.
		HighestKey_Label:SetText(Dung_HighestKey)
		HighestKey_Label:SetTextColor(Dung_HighestKey_Color.r, Dung_HighestKey_Color.g, Dung_HighestKey_Color.b)

		--Set the highest Tyr dungeon score info
		Tyrranical_Label:SetText(
			"T: "
				.. TyrLevel_Color:WrapTextInColorCode(self.Current_SeasonalDung_Info[i].dungTyrLevel)
				.. "\n "
				.. TyrLevel_Color:WrapTextInColorCode(self.Current_SeasonalDung_Info[i].dungTyrScore)
		)
		--Set the highest Fort dungeon score info
		Fortified_Label:SetText(
			"F: "
				.. FortLevel_Color:WrapTextInColorCode(self.Current_SeasonalDung_Info[i].dungFortLevel)
				.. "\n"
				.. FortScore_Color:WrapTextInColorCode(self.Current_SeasonalDung_Info[i].dungFortScore)
		)
	end

	for i = 1, #self.Current_SeasonalDung_Info do
		local DungIcon = _G["DungeonIcon_" .. i]
		local DungName = self.Current_SeasonalDung_Info[i].dungName
		local DungOverallScore = self.Current_SeasonalDung_Info[i].dungOverallScore
		local inTimeInfo = self.Current_SeasonalDung_Info[i].intimeInfo
		local overtimeInfo = self.Current_SeasonalDung_Info[i].overtimeInfo
		local affixScores, _ = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(self.Current_SeasonalDung_Info[i].mapID)
		local dungSpellID
		local dungSpellName

		for _, dungeons in ipairs(AMT.Challenges_Teleports) do
			if dungeons.mapID == self.Current_SeasonalDung_Info[i].mapID then
				dungSpellID = dungeons.spellID
				dungSpellName = GetSpellInfo(dungSpellID)
			end
		end

		local isOverTimeRun = false

		local seasonBestDurationSec, seasonBestLevel, members

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
				local start, duration = GetSpellCooldown(dungSpellID)

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)

				if not start or not duration then
					GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
				elseif duration == 0 then
					GameTooltip:AddLine(READY, 0, 1, 0)
				else
					GameTooltip:AddLine(SecondsToTime(ceil(start + duration - GetTime())), 1, 0, 0)
				end
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)
				GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
			end

			GameTooltip:Show()

			-- C_Timer.After(1, function()
			-- 	self:UpdateGameTooltip(DungIcon, dungSpellID)
			-- end)
		end)
		DungIcon:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		DungIcon:RegisterForClicks("AnyUp", "AnyDown")
		DungIcon:SetAttribute("type1", "spell")
		DungIcon:SetAttribute("spell", dungSpellName)
	end
end

function AMT:AMT_Affixes_Display()
	--Affixes_Compartment

	if #AMT.GetCurrentAffixesTable == 0 then
		local currentAffixes = C_MythicPlus.GetCurrentAffixes()
		if currentAffixes then
			AMT.GetCurrentAffixesTable = currentAffixes
		end
	end
	if #self.CurrentWeek_AffixTable == 0 then
		table.insert(
			self.CurrentWeek_AffixTable,
			{ AMT.GetCurrentAffixesTable[1].id, AMT.GetCurrentAffixesTable[2].id, AMT.GetCurrentAffixesTable[3].id }
		)
	end

	if not CurrentAffixes_Label then
		CurrentAffixes_Label = Affixes_Compartment:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
		CurrentAffixes_Label:SetPoint("TOPLEFT", 35, -2) -- Set the position of the text
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
		NextWeekAffixes_Label:SetPoint("TOPLEFT", CurrentAffixes_Container, "BOTTOMLEFT", 35, -4) -- Set the position of the text
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

	AMT:GetNextAffixRotation(self.CurrentWeek_AffixTable, self.AffixRotation)

	for i = 1, #self.GetCurrentAffixesTable do
		for _, affixID in ipairs(self.CurrentWeek_AffixTable) do
			local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])

			if not _G["AffixIcon" .. #self.GetCurrentAffixesTable] then
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
							- (iconSize * #AMT.GetCurrentAffixesTable)
							- (iconPadding * (#AMT.GetCurrentAffixesTable - 1))
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

	for i = 1, #AMT.GetCurrentAffixesTable do
		for _, affixID in ipairs(NextWeek_AffixTable) do
			local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])

			if not _G["NexWeek_AffixIcon" .. #AMT.GetCurrentAffixesTable] then
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
							- (iconSize * #AMT.GetCurrentAffixesTable)
							- (iconPadding * (#AMT.GetCurrentAffixesTable - 1))
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
	-- Creates the tooltip on hover of the score.
	-- Uses Blizzard_ChallengesUI.lua > DungeonScoreInfoMixin:OnEnter()
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

function AMT:AMT_KeystoneItem_Display()
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
		local Keystone_DungName_Bg = CreateFrame("Frame", "Keystone_DungName_Bg", RuneArt)
		Keystone_DungName_Bg:SetPoint("TOP", KeystoneItem_Icon, "TOP", 0, 36)
		Keystone_DungName_Bg:SetSize(78, 22)

		-- Add black background texture
		Keystone_DungName_Bg.tex = Keystone_DungName_Bg:CreateTexture(nil, "ARTWORK")
		Keystone_DungName_Bg.tex:SetAllPoints(Keystone_DungName_Bg)
		Keystone_DungName_Bg.tex:SetColorTexture(0, 0, 0, 0.75)

		Keystone_DungName = Keystone_DungName_Bg:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		Keystone_DungName:SetPoint("CENTER", Keystone_DungName_Bg, "CENTER", 0, 0)
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
		local abbr = AMT:GetAbbrFromChallengeModeID(Keystone_ID)
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
		GreatVault_Button = CreateFrame("Button", "GreatVault_Button", RuneArt)
		GreatVault_Button:SetPoint("BOTTOM", KeystoneItem_Icon, "BOTTOM", 0, -32)
		GreatVault_Button:SetSize(76, 22)
		GreatVault_Button:SetText("Open Vault")

		-- Add black background texture
		GreatVault_Button_bg = GreatVault_Button:CreateTexture(nil, "ARTWORK")
		GreatVault_Button_bg:SetAllPoints(GreatVault_Button)
		GreatVault_Button_bg:SetColorTexture(0, 0, 0, 1)

		-- Create the font string and attach it to the button
		local GreatVault_Buttonlabel =
			GreatVault_Button:CreateFontString("GreatVault_Buttonlabel", "OVERLAY", "MovieSubtitleFont")
		GreatVault_Buttonlabel:SetPoint("CENTER", GreatVault_Button, "CENTER", 0, 0) -- Center the text on the button
		GreatVault_Buttonlabel:SetFont(GreatVault_Buttonlabel:GetFont(), 12, "OUTLINE")
		GreatVault_Buttonlabel:SetText(" Open Vault")

		-- Create border textures
		GreatVault_Button_borderTop = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderTop:SetHeight(1)
		GreatVault_Button_borderTop:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderTop:SetPoint("TOPLEFT", GreatVault_Button, "TOPLEFT", -1, 1)
		GreatVault_Button_borderTop:SetPoint("TOPRIGHT", GreatVault_Button, "TOPRIGHT", 1, 1)

		GreatVault_Button_borderBottom = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderBottom:SetHeight(1)
		GreatVault_Button_borderBottom:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderBottom:SetPoint("BOTTOMLEFT", GreatVault_Button, "BOTTOMLEFT", -1, -1)
		GreatVault_Button_borderBottom:SetPoint("BOTTOMRIGHT", GreatVault_Button, "BOTTOMRIGHT", 1, -1)

		GreatVault_Button_borderLeft = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderLeft:SetWidth(1)
		GreatVault_Button_borderLeft:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderLeft:SetPoint("TOPLEFT", GreatVault_Button, "TOPLEFT", -1, 1)
		GreatVault_Button_borderLeft:SetPoint("BOTTOMLEFT", GreatVault_Button, "BOTTOMLEFT", -1, -1)

		GreatVault_Button_borderRight = GreatVault_Button:CreateTexture(nil, "OVERLAY")
		GreatVault_Button_borderRight:SetWidth(1)
		GreatVault_Button_borderRight:SetColorTexture(0, 0.624, 0.863, 1) -- White color
		GreatVault_Button_borderRight:SetPoint("TOPRIGHT", GreatVault_Button, "TOPRIGHT", 1, 1)
		GreatVault_Button_borderRight:SetPoint("BOTTOMRIGHT", GreatVault_Button, "BOTTOMRIGHT", 1, -1)

		-- Hide the border by default
		GreatVault_Button_borderTop:Hide()
		GreatVault_Button_borderBottom:Hide()
		GreatVault_Button_borderLeft:Hide()
		GreatVault_Button_borderRight:Hide()

		-- GreatVault_Button.tex = GreatVault_Button:CreateTexture()
		-- GreatVault_Button.tex:SetAllPoints(GreatVault_Button)
		-- GreatVault_Button.tex:SetColorTexture(0, 0, 0, 0.75)

		-- PartyKeystone_DetailsButton = CreateFrame("Button", nil, PartyKeystone_Container, "UIPanelButtonTemplate")
		-- if AMT_ElvUIEnabled then
		-- 	S:HandleButton(PartyKeystone_DetailsButton)
		-- end
		-- PartyKeystone_DetailsButton:SetSize(60, 16)
		-- PartyKeystone_DetailsButton:SetPoint("TOPRIGHT", PartyKeystone_Container, "TOPRIGHT", -4, -4)
		-- PartyKeystone_DetailsButton:SetText("More")
		-- PartyKeystone_DetailsButton.Text:SetFont(PartyKeystone_DetailsButton.Text:GetFont(), 12)

		-- GreatVault_ButtonBorder = CreateFrame("Frame", "GreatVault_ButtonBorder", GreatVault_Button)
		-- GreatVault_ButtonBorder:SetSize(GreatVault_Button:GetWidth() + 2, GreatVault_Button:GetHeight() + 3)
		-- GreatVault_ButtonBorder:SetPoint("CENTER", GreatVault_Button, "CENTER")

		-- GreatVault_ButtonBorder.tex = GreatVault_ButtonBorder:CreateTexture("GreatVault_ButtonBorderTexture")
		-- GreatVault_ButtonBorder.tex:SetAtlas("SquareMask")
		-- GreatVault_ButtonBorder.tex:SetVertexColor(1, 0.784, 0.047, 0.75)
		-- GreatVault_ButtonBorder.tex:SetAllPoints()
		-- GreatVault_ButtonBorder:SetFrameLevel(3)

		-- GreatVault_Buttonlabel = KeystoneItem_Icon:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		-- GreatVault_Buttonlabel:SetPoint("CENTER", GreatVault_Button, "CENTER", 0, 1)
		-- GreatVault_Buttonlabel:SetText(" Open Vault ")
		-- GreatVault_Buttonlabel:SetFont(GreatVault_Buttonlabel:GetFont(), 12, "OUTLINE")
		-- GreatVault_Buttonlabel:SetTextColor(1, 0.784, 0.047)
	end

	--Create the interactions on hover, unhover, and onclick
	GreatVault_Button:SetScript("OnEnter", function()
		GreatVault_Button_borderTop:Show()
		GreatVault_Button_borderBottom:Show()
		GreatVault_Button_borderLeft:Show()
		GreatVault_Button_borderRight:Show()
		-- GreatVault_ButtonBorder.tex:SetVertexColor(0, 0.624, 0.863, 1.0)
	end)

	GreatVault_Button:SetScript("OnLeave", function()
		GreatVault_Button_borderTop:Hide()
		GreatVault_Button_borderBottom:Hide()
		GreatVault_Button_borderLeft:Hide()
		GreatVault_Button_borderRight:Hide()
		-- GreatVault_ButtonBorder.tex:SetVertexColor(1, 0.784, 0.047, 0.75)
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
	raids = AMT:Filter_Table(self.SeasonalRaids, function(SeasonalRaids)
		return self.SeasonalRaids.seasonID == seasonID
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
			local BossKill_Num = 0
			local temp_encounters = {}
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
				if killed == true then
					BossKill_Num = BossKill_Num + 1
				end
				local encounter = {
					index = encounterIndex,
					instanceEncounterID = instanceEncounterID,
					bossName = bossName,
					fileDataID = fileDataID or 0,
					killed = killed,
				}
				temp_encounters[encounterIndex] = encounter
			end
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
				encounters = temp_encounters,
				bosseskilled = BossKill_Num,
			}
			if reset and reset > 0 then
				savedInstance.expires = reset + time()
			end
			for i = 1, #AMT.SeasonalRaids do
				if savedInstance.instanceID == AMT.SeasonalRaids[i].instanceID then
					raids.savedInstances[savedInstanceIndex] = savedInstance
				end
			end
			-- raids.savedInstances[savedInstanceIndex] = savedInstance
		end
	end
	--Create the frames that will store the boxes for each difficulty, running through each difficulty level for the current season's Raid
	if not Raid_MainFrame then
		for i, difficulty in ipairs(AMT.RaidDifficulty_Levels) do
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
			for raidIndex, raid in ipairs(self.SeasonalRaids) do
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
	if not RaidBox then
		for i, difficulty in ipairs(AMT.RaidDifficulty_Levels) do
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
	end

	local RaidKills_Count = { 0, 0, 0, 0 }

	-- Check for Raid ID kills
	Raidinfo = C_WeeklyRewards.GetActivityEncounterInfo(3, 1)

	for _, instance in pairs(raids.savedInstances) do
		if instance.difficultyID == 16 and instance.instanceID == 2522 then
			RaidKills_Count[1] = RaidKills_Count[1] + instance.bosseskilled
			-- print("Mythic: " .. RaidKills_Count[1])
		elseif instance.difficultyID == 15 and instance.instanceID == 2522 then
			RaidKills_Count[2] = RaidKills_Count[2] + instance.bosseskilled
			-- print("Heroic: " .. RaidKills_Count[2])
		elseif instance.difficultyID == 14 and instance.instanceID == 2522 then
			RaidKills_Count[3] = RaidKills_Count[3] + instance.bosseskilled
			-- print("Normal: " .. RaidKills_Count[3])
		elseif instance.difficultyID == 17 and instance.instanceID == 2522 then
			RaidKills_Count[4] = RaidKills_Count[4] + instance.bosseskilled
			-- print("LFR: " .. RaidKills_Count[4])
		end
	end

	for i = 1, #AMT.RaidDifficulty_Levels do
		local DifficultyName = AMT.RaidDifficulty_Levels[i].abbr
		local Difficulty_KillCount = RaidKills_Count[i]
		if Difficulty_KillCount ~= 0 then
			for n = 1, Difficulty_KillCount do
				if n == 2 or n == 4 or n == 6 then
					_G[DifficultyName .. n].tex:SetColorTexture(1, 0.784, 0.047, 1.0)
				elseif n <= AMT_VaultRaid_Num then
					_G[DifficultyName .. n].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0)
				end
			end
		end
	end
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
		if self.KeysDone[1] ~= 0 then
			GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", #KeysDone))
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
					GameTooltip:AddLine(Whitetext .. self.KeysDone[i].level .. " - " .. self.KeysDone[i].keyname)
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
			AMT.box_size = 14

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
		if i <= #self.KeysDone and #self.RunHistory > 0 then
			tinsert(WeeklyKeysHistory, self.KeysDone[i].level)
		else
			break -- Exit the loop if self.KeysDone[i] or self.KeysDone[i].level doesn't exist
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

function AMT:AMT_PartyKeystone()
	GroupKeystone_Info = {}

	if self.DetailsLoaded then
		for i = 1, 5 do
			local unitID = i == 1 and "player" or "party" .. i - 1
			local data = self.OpenRaidLib.GetKeystoneInfo(unitID)
			local mapID = data and data.mythicPlusMapID
			for _, dungeon in ipairs(self.DungeonAbbr) do
				if dungeon.mapID == mapID then
					Keyname_abbr = dungeon.Abbr
					if mapID and Keyname_abbr then
						local level = data.level
						local playerClass = UnitClassBase(unitID)
						local playerName = UnitName(unitID)
						local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

						tinsert(GroupKeystone_Info, {
							level = level,
							name = Keyname_abbr,
							player = AMT_ClassColorString(playerName, playerClass),
							icon = texture,
						})
					end
				end
			end
		end
		-- for i = 1, 5 do
		-- 	local unitID = i == 1 and "player" or "party" .. i - 1
		-- 	local data = AMT_OpenRaidLib.GetKeystoneInfo(unitID)
		-- 	local mapID = data and data.mythicPlusMapID
		-- 	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		-- 		if dungeon.challengeModeID == mapID then
		-- 			Keyname_abbr = dungeon.abbr
		-- 			if mapID and Keyname_abbr then
		-- 				local level = data.level
		-- 				local playerClass = UnitClassBase(unitID)
		-- 				local playerName = UnitName(unitID)
		-- 				local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

		-- 				tinsert(GroupKeystone_Info, {
		-- 					level = level,
		-- 					name = Keyname_abbr,
		-- 					player = AMT_ClassColorString(playerName, "DEMONHUNTER"),
		-- 					icon = texture,
		-- 				})
		-- 			end
		-- 		end
		-- 	end
		-- end
		-- for i = 1, 5 do
		-- 	local unitID = i == 1 and "player" or "party" .. i - 1
		-- 	local data = AMT_OpenRaidLib.GetKeystoneInfo(unitID)
		-- 	local mapID = data and data.mythicPlusMapID
		-- 	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		-- 		if dungeon.challengeModeID == mapID then
		-- 			Keyname_abbr = dungeon.abbr
		-- 			if mapID and Keyname_abbr then
		-- 				local level = data.level
		-- 				local playerClass = UnitClassBase(unitID)
		-- 				local playerName = UnitName(unitID)
		-- 				local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

		-- 				tinsert(GroupKeystone_Info, {
		-- 					level = 32,
		-- 					name = "UNDR",
		-- 					player = AMT_ClassColorString("Bigdumlock", "WARLOCK"),
		-- 					icon = texture,
		-- 				})
		-- 			end
		-- 		end
		-- 	end
		-- end
		-- for i = 1, 5 do
		-- 	local unitID = i == 1 and "player" or "party" .. i - 1
		-- 	local data = AMT_OpenRaidLib.GetKeystoneInfo(unitID)
		-- 	local mapID = data and data.mythicPlusMapID
		-- 	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		-- 		if dungeon.challengeModeID == mapID then
		-- 			Keyname_abbr = dungeon.abbr
		-- 			if mapID and Keyname_abbr then
		-- 				local level = data.level
		-- 				local playerClass = UnitClassBase(unitID)
		-- 				local playerName = UnitName(unitID)
		-- 				local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

		-- 				tinsert(GroupKeystone_Info, {
		-- 					level = 37,
		-- 					name = "UNDR",
		-- 					player = AMT_ClassColorString("Darkdrpepper", "DEATHKNIGHT"),
		-- 					icon = texture,
		-- 				})
		-- 			end
		-- 		end
		-- 	end
		-- end
		-- for i = 1, 5 do
		-- 	local unitID = i == 1 and "player" or "party" .. i - 1
		-- 	local data = AMT_OpenRaidLib.GetKeystoneInfo(unitID)
		-- 	local mapID = data and data.mythicPlusMapID
		-- 	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		-- 		if dungeon.challengeModeID == mapID then
		-- 			Keyname_abbr = dungeon.abbr
		-- 			if mapID and Keyname_abbr then
		-- 				local level = data.level
		-- 				local playerClass = UnitClassBase(unitID)
		-- 				local playerName = UnitName(unitID)
		-- 				local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

		-- 				tinsert(GroupKeystone_Info, {
		-- 					level = level,
		-- 					name = Keyname_abbr,
		-- 					player = AMT_ClassColorString("Mysophobia", "DRUID"),
		-- 					icon = texture,
		-- 				})
		-- 			end
		-- 		end
		-- 	end
		-- end

		PartyKeystone_Container.lines = {}

		for i = 1, 5 do
			local yOffset = 10
			if not _G["PartyKeystyone_Right" .. i] and not _G["PartyKeystyone_Left" .. i] then
				PartyKeystone_Rightext =
					PartyKeystone_Container:CreateFontString("PartyKeystyone_Right" .. i, "OVERLAY")
				PartyKeystone_Rightext:SetPoint("BOTTOMRIGHT", PartyKeystone_Container, "BOTTOMRIGHT", -10, yOffset)
				PartyKeystone_Rightext:SetJustifyH("RIGHT")
				PartyKeystone_Rightext:SetWidth(90)

				PartyKeystone_Lefttext = PartyKeystone_Container:CreateFontString("PartyKeystyone_Left" .. i, "OVERLAY")
				PartyKeystone_Lefttext:SetPoint("BOTTOMRIGHT", PartyKeystone_Container, "BOTTOMRIGHT", -100, yOffset)
				PartyKeystone_Lefttext:SetJustifyH("LEFT")
				PartyKeystone_Lefttext:SetWidth(90)
			end
			PartyKeystone_Container.lines[i] = {
				left = PartyKeystone_Lefttext,
				right = PartyKeystone_Rightext,
			}
		end

		for i = 1, 5 do
			local yOffset = 25 + 25 * (i - 1)
			local xOffset = 6
			PartyKeystone_Container.lines[i].right:ClearAllPoints()
			PartyKeystone_Container.lines[i].left:ClearAllPoints()

			PartyKeystone_Container.lines[i].right:SetPoint(
				"TOPRIGHT",
				PartyKeystone_Container,
				"TOPRIGHT",
				-4,
				-yOffset - 4
			)
			PartyKeystone_Container.lines[i].right:SetFont(PartyKeystone_DetailsButton.Text:GetFont(), 13)
			PartyKeystone_Container.lines[i].right:SetJustifyH("RIGHT")
			PartyKeystone_Container.lines[i].right:SetWidth(100)

			PartyKeystone_Container.lines[i].left:SetPoint(
				"TOPLEFT",
				PartyKeystone_Container,
				"TOPLEFT",
				xOffset,
				-yOffset
			)
			PartyKeystone_Container.lines[i].left:SetFont(PartyKeystone_DetailsButton.Text:GetFont(), 13)
			PartyKeystone_Container.lines[i].left:SetJustifyH("LEFT")
			PartyKeystone_Container.lines[i].left:SetWidth(100)

			if GroupKeystone_Info[i] then
				PartyKeystone_Container.lines[i].right:SetText(GroupKeystone_Info[i].player)
				PartyKeystone_Container.lines[i].left:SetText(
					format(
						"|T%s:20:20:0:0:64:64:4:60:7:57:255:255:255|t |c%s%s - %s|r",
						GroupKeystone_Info[i].icon,
						AMT_getKeystoneLevelColor(GroupKeystone_Info[i].level),
						GroupKeystone_Info[i].level,
						GroupKeystone_Info[i].name
					)
				)
			else
				PartyKeystone_Container.lines[i].right:SetText("")
				PartyKeystone_Container.lines[i].left:SetText("")
			end
		end
	end
end

function AMT:AMT_MythicRunsGraph()
	--MythicRunsGraph_Container
	print("running MythicRunsGraph")
	for i = 1, 4 do
		local graphline = MythicRunsGraph_Container:CreateLine("GraphLine" .. i)
		graphline:SetThickness(2)
		graphline:SetColorTexture(0.4, 0.4, 0.4, 1.000)
		if i == 1 then
			local xOffset = 44
			graphline:SetColorTexture(1, 1, 1, 0)
			graphline:SetStartPoint("TOPLEFT", xOffset, -30)
			graphline:SetEndPoint("BOTTOMLEFT", xOffset, 20)
		elseif i == 2 then
			local xOffset = 56 + 130 * (i - 1)
			-- print("2: " .. xOffset) 186
			graphline:SetStartPoint("TOPLEFT", xOffset, -30)
			graphline:SetEndPoint("BOTTOMLEFT", xOffset, 20)
		elseif i == 3 then
			local xOffset = 76 + 130 * (i - 1)
			-- print("3: " .. xOffset) 336
			graphline:SetStartPoint("TOPLEFT", xOffset, -30)
			graphline:SetEndPoint("BOTTOMLEFT", xOffset, 20)
		elseif i == 4 then
			local xOffset = 96 + 130 * (i - 1)
			-- print("4: " .. xOffset) 486
			graphline:SetStartPoint("TOPLEFT", xOffset, -30)
			graphline:SetEndPoint("BOTTOMLEFT", xOffset, 20)
		end
	end

	for i = 1, 4 do
		if not _G["Graphline_Label" .. i] then
			Graphline_Label =
				MythicRunsGraph_Container:CreateFontString("Graphline_Label" .. i, "BACKGROUND", "GameFontNormal")
		end
		Graphline_Label:SetText(tostring(i * 10))
		Graphline_Label:SetJustifyH("CENTER")
		Graphline_Label:SetPoint("BOTTOM", _G["GraphLine" .. i + 1], "TOP", 0, 4)
	end

	for i = 1, #self.Current_SeasonalDung_Info do
		local graphline = _G["GraphLine1"]
		local dungID = self.Current_SeasonalDung_Info[i].mapID
		local dungAbbr = ""
		for _, dungeon in ipairs(self.DungeonAbbr) do
			if dungID == dungeon.mapID then
				dungAbbr = dungeon.Abbr
			end
		end
		local yMargin = 12 -- Margin we set at top and bottom
		local yOffset = 24 -- Margin between each dungeon name
		if not _G["GraphDung_Label" .. i] then
			GraphDung_Label =
				MythicRunsGraph_Container:CreateFontString("GraphDung_Label" .. i, "BACKGROUND", "MovieSubtitleFont")
		end
		GraphDung_Label:SetFont(GraphDung_Label:GetFont(), 14)
		GraphDung_Label:SetText(dungAbbr)
		GraphDung_Label:SetJustifyH("RIGHT")
		if i == 1 then
			GraphDung_Label:SetPoint("RIGHT", graphline, "TOPLEFT", -4, -yMargin)
		else
			GraphDung_Label:SetPoint("RIGHT", graphline, "TOPLEFT", -4, -yMargin - (yOffset * (i - 1)))
		end
	end
	local dungLines = {}
	for i = 1, #self.BestKeys_per_Dungeon do
		local graphlabel = _G["GraphDung_Label" .. i]
		if not dungLines[i] then
			dungLines[i] = MythicRunsGraph_Container:CreateFontString("Dung_AntTrail" .. i, "ARTWORK", "GameFontNormal")
		end

		local dungLine = dungLines[i]

		--If highest key done is same as the current weekly best color the line gold
		if self.BestKeys_per_Dungeon[i].HighestKey == WeeklyBest_Key then
			dungLine:SetTextColor(1.000, 0.824, 0.000, 1.000)
		else
			--Otherwise color it white
			dungLine:SetTextColor(1, 1, 1, 1.0)
		end
		--If the key actually exists/was done, set the ant trail
		if self.BestKeys_per_Dungeon[i].HighestKey > 0 then
			dungLine:SetPoint("LEFT", graphlabel, "RIGHT", 6, -1)
			dungLine:SetText(self.BestKeys_per_Dungeon[i].DungBullets .. self.BestKeys_per_Dungeon[i].HighestKey)
		end
	end
	-- AMT:AMT_UpdateMythicGraph()
end
