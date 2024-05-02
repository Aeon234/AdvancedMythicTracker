local addonName, AMT = ...

Difficulty_Label_XPos = 42
Difficulty_Label_YPos = 1
Tab = "          "
Whitetext = "|cffffffff"

function AMT:AMT_Visuals()
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
		WeeklyBest_Label:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 58, -25)
		WeeklyBest_Label:SetText("Weekly Best")
		WeeklyBest_Label:SetFont(WeeklyBest_Label:GetFont(), 18, "OUTLINE")
		WeeklyBest_Label:SetTextColor(1, 1, 1)
	end
	--Generates the background where the weekly best key # is going to be displayed
	if not WeeklyBest_Bg then
		WeeklyBest_Bg = CreateFrame("Frame", "WeeklyBest_Bg", AMT_Container_BG, "BackdropTemplate")
		-- WeeklyBest_Bg:SetSize(103, 42)
		WeeklyBest_Bg:SetSize(120, 42)
		WeeklyBest_Bg:SetPoint("CENTER", AMT_Container_BG, "TOPLEFT", 112, -64)

		WeeklyBest_Bg.tex = WeeklyBest_Bg:CreateTexture()
		WeeklyBest_Bg.tex:SetSize(260, 42)
		WeeklyBest_Bg.tex:SetAllPoints(WeeklyBest_Bg)
		WeeklyBest_Bg.tex:SetAtlas("CovenantChoice-Celebration-ToastBG")

		-- WeeklyBest_Bg:SetBackdrop(BackdropInfo)

		-- WeeklyBest_Bg:SetBackdropBorderColor(0, 0, 0, 0.5)
		-- WeeklyBest_Bg:SetBackdropColor(0, 0, 0, 0.5)
	end
	--Creates the container in which the Raid, Mythic Plus, and Honor items will be anchored to.
	if not WeeklyVault_Goals then
		WeeklyVault_Goals = CreateFrame("Frame", "WeeklyBest_Goals", AMT_Container_BG, "BackdropTemplate")
		WeeklyVault_Goals:SetSize(190, 192)
		WeeklyVault_Goals:SetPoint("TOPLEFT", AMT_Container_BG, "TOPLEFT", 17, -86)
		WeeklyVault_Goals:SetBackdrop(BackdropInfo)

		WeeklyVault_Goals:SetBackdropBorderColor(1, 1, 1, 0.0)
		WeeklyVault_Goals:SetBackdropColor(1, 1, 1, 0.0)
	end
	--Creates the Raid container within WeeklyBest_Goals container that will anchor the raid information
	if not Raid_Goals then
		Raid_Goals = CreateFrame("Frame", "WeeklyBest_Bg", WeeklyVault_Goals, "BackdropTemplate")
		Raid_Goals:SetSize(190, 76)
		Raid_Goals:SetPoint("TOPLEFT", WeeklyVault_Goals, "TOPLEFT", 0, -2)
		Raid_Goals:SetBackdrop(BackdropInfo)

		Raid_Goals:SetBackdropBorderColor(0, 1, 1, 0.0)
		Raid_Goals:SetBackdropColor(0, 1, 1, 0.0)
	end

	--Creates PVP container within the WeeklyBest_Goals container that will anchor the Mplus information
	if not PVP_Goals then
		PVP_Goals = CreateFrame("Frame", "PVP_Goals", WeeklyVault_Goals, "BackdropTemplate")
		PVP_Goals:SetSize(190, 34)
		PVP_Goals:SetPoint("TOP", Mplus_Mainframe, "BOTTOM", 0, -5)
		PVP_Goals:SetBackdrop(BackdropInfo)

		PVP_Goals:SetBackdropBorderColor(1, 1, 0, 0.0)
		PVP_Goals:SetBackdropColor(1, 1, 0, 0.0)
	end

	AMT:KeystoneItem_Display()
	AMT:WeeklyBest_Display()
	AMT:AMT_Raid()
	AMT:AMT_MythicPlus()
	AMT:AMT_DungeonList()
end

function AMT:AMT_Raid()
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

	--Create the boxes within the frames for each difficulty
	for i, difficulty in ipairs(RaidDifficulty_Levels) do
		local DifficultyName = difficulty.abbr
		for n = 1, 7 do
			local box_size = 18
			RaidBox = CreateFrame("Frame", DifficultyName .. n, _G["RaidDifficulty" .. i], "BackdropTemplate")
			RaidBox:SetSize(box_size, box_size)

			RaidBox:SetBackdrop(BackdropInfo)
			RaidBox:SetBackdropBorderColor(0.000, 0.800, 1.000, 0)
			RaidBox:SetBackdropColor(1.000, 1.000, 1.000, 0.500)

			if n == 1 then
				RaidBox:SetPoint("RIGHT", _G["RaidDifficulty" .. i], "RIGHT", -3, 0)
			else
				local previousBox = _G[DifficultyName .. (n - 1)]

				RaidBox:SetPoint("RIGHT", previousBox, "LEFT", -3, 0)
			end
		end
	end
	for num, diff in ipairs(Weekly_KillCount) do
		diff.kills = 0
		for raidIndex, raid in ipairs(SeasonalRaids) do
			for i, difficulty in ipairs(RaidDifficulty_Levels) do
				for _, encounter in ipairs(raid.encounters) do
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
								diff.kills = diff.kills + 1
							end
						end
					end
				end
			end
		end
	end
	--Create the Raid Section Header
	if not WeeklyRaid_Label then
		WeeklyRaid_Label = Raid_Goals:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyRaid_Label:SetPoint("TOPLEFT", Raid_Goals, "TOPLEFT", 0, 0)
		WeeklyRaid_Label:SetText("Raid:")
		WeeklyRaid_Label:SetFont(WeeklyRaid_Label:GetFont(), 14)
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
		KeystoneItem_Icon:SetSize(40, 40)
		KeystoneItem_Icon.tex = KeystoneItem_Icon:CreateTexture()
		KeystoneItem_Icon.tex:SetAllPoints(KeystoneItem_Icon)
	end
	--Create the Glow Texture that will exist around the Keystone Icon
	if not KeystoneItem_Glow then
		KeystoneItem_Glow = CreateFrame("Frame", "KeystoneItem_Glow", RuneArt)
		KeystoneItem_Glow:SetPoint("CENTER")
		KeystoneItem_Glow:SetSize(66, 66)
		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetSize(54, 54)
		KeystoneItem_Glow.tex:SetAllPoints(KeystoneItem_Glow)
		-- KeystoneItem_Glow.tex:SetAtlas("BonusChest-ItemBorder-Uncommon")
	end
	--If the Label text hasn't been created, create it otherwise just update the label
	if not Keystone_DungName then
		local Keystone_DungName_Bg = CreateFrame("Frame", "CurrentKey_TopLabel", AMT_Container_Data, "BackdropTemplate")
		Keystone_DungName_Bg:SetSize(68, 20)
		Keystone_DungName_Bg:SetPoint("BOTTOMLEFT", AMT_Container_Data, "BOTTOMLEFT", 76, 110)
		Keystone_DungName_Bg:SetBackdrop(BackdropInfo)

		Keystone_DungName_Bg:SetBackdropBorderColor(0, 0, 0, 0.5)
		Keystone_DungName_Bg:SetBackdropColor(0, 0, 0, 0.5)

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
		KeystoneItem_Icon:SetSize(40, 40)
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
			KeystoneItem_Icon:SetSize(40, 40)
			KeystoneItem_Glow.tex:SetAtlas("BattleBar-Button-Highlight")
		end
	end
	--No point attempting to catalog any of the blow if a keystyone is not detected. It'll throw errors
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
		GreatVault_Button = CreateFrame("Button", "GreatVault_Button", AMT_Container_Data, "BackdropTemplate")
		GreatVault_Button:SetPoint("CENTER", KeystoneItem_Icon, "BOTTOM", 0, -24)
		GreatVault_Button:SetSize(60, 18)
		GreatVault_Button:SetText("Open Vault")
		GreatVault_Button.tex = GreatVault_Button:CreateTexture()
		GreatVault_Button.tex:SetAllPoints(GreatVault_Button)
		GreatVault_Button.tex:SetAtlas("SquareMask")
		GreatVault_Button.tex:SetVertexColor(0, 0, 0, 1.0)

		GreatVault_ButtonBorder = CreateFrame("Frame", "GreatVault_ButtonBorder", GreatVault_Button)
		GreatVault_ButtonBorder:SetSize(GreatVault_Button:GetWidth() + 2, GreatVault_Button:GetHeight() + 3)
		GreatVault_ButtonBorder:SetPoint("CENTER", GreatVault_Button, "CENTER")

		GreatVault_ButtonBorder.texture = GreatVault_ButtonBorder:CreateTexture("GreatVault_ButtonBorderTexture")
		GreatVault_ButtonBorder.texture:SetAtlas("SquareMask")
		GreatVault_ButtonBorder.texture:SetVertexColor(1, 0.784, 0.047, 0.75)
		GreatVault_ButtonBorder.texture:SetAllPoints()
		GreatVault_ButtonBorder:SetFrameLevel(3)

		GreatVault_Buttonlabel = KeystoneItem_Icon:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		GreatVault_Buttonlabel:SetPoint("CENTER", GreatVault_Button, "CENTER", 0, 1)
		GreatVault_Buttonlabel:SetText(" Open Vault ")
		GreatVault_Buttonlabel:SetFont(GreatVault_Buttonlabel:GetFont(), 10)
		GreatVault_Buttonlabel:SetTextColor(1, 0.784, 0.047)
	end

	--Create the interactions on hover, unhover, and onclick
	GreatVault_Button:SetScript("OnEnter", function()
		GreatVault_ButtonBorder.texture:SetVertexColor(0, 0.624, 0.863, 1.0)
	end)

	GreatVault_Button:SetScript("OnLeave", function()
		GreatVault_ButtonBorder.texture:SetVertexColor(1, 0.784, 0.047, 0.75)
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

function AMT:AMT_MythicPlus()
	--Creates the Mythic Plus Header
	if not Mplus_Goals_Header then
		Mplus_Goals_Header = CreateFrame("Frame", "Mplus_Goals_Header", WeeklyVault_Goals, "BackdropTemplate")
		Mplus_Goals_Header:SetSize(190, 18)

		Mplus_Goals_Header:SetPoint("TOP", RaidDifficulty4, "BOTTOM", 0, -5)
		Mplus_Goals_Header:SetBackdrop(BackdropInfo)

		Mplus_Goals_Header:SetBackdropBorderColor(1, 0, 1, 0.0)
		Mplus_Goals_Header:SetBackdropColor(1, 1, 1, 0.0)
	end
	--Create the Mplus Section Header
	if not WeeklyMplus_Label then
		WeeklyMplus_Label = Mplus_Goals_Header:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyMplus_Label:SetPoint("TOPLEFT", Mplus_Goals_Header, "TOPLEFT", 0, 0)
		WeeklyMplus_Label:SetText("Mythic+:")
		WeeklyMplus_Label:SetFont(WeeklyMplus_Label:GetFont(), 14)
	end
	--Create the Mythic Plus Main Frame that will house the label and the boxes
	if not Mplus_Mainframe then
		Mplus_Mainframe = CreateFrame("Frame", "Mplus_Mainframe", WeeklyVault_Goals, "BackdropTemplate")
		Mplus_Mainframe:SetSize(190, 22)

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
		MplusDifficulty_Label:SetPoint("RIGHT", Mplus_MainFrame_LabelFrame, "RIGHT", -2, 0)
		MplusDifficulty_Label:SetText("|cffffffffM -")
		MplusDifficulty_Label:SetFont(MplusDifficulty_Label:GetFont(), 14)
		MplusDifficulty_Label:SetJustifyH("RIGHT")
		MplusDifficulty_Label:SetJustifyV("MIDDLE")

		Mplus_MainFrame_BoxFrame = CreateFrame("Frame", "Mplus_MainFrame_Label", Mplus_Mainframe, "BackdropTemplate")
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
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Top 8 Runs This Week")
		if KeysDone[1] ~= 0 then
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

	local RequiredKeys_MaxVault = 8
	if not _G["Mplus_Box" .. RequiredKeys_MaxVault] then
		for i = 1, RequiredKeys_MaxVault do
			local box_size = 16

			Mplus_Box = CreateFrame("Frame", "Mplus_Box" .. i, Mplus_MainFrame_BoxFrame, "BackdropTemplate")
			Mplus_Box:SetSize(box_size, box_size)

			Mplus_Box:SetBackdrop(BackdropInfo)
			Mplus_Box:SetBackdropBorderColor(0.000, 0.000, 1.000, 0)
			Mplus_Box:SetBackdropColor(0.800, 0.800, 0.800, 1.000)

			if i == 1 then
				Mplus_Box:SetPoint("LEFT", Mplus_MainFrame_BoxFrame, "LEFT", 0, 0)
			else
				local previousBox = _G["Mplus_Box" .. (i - 1)]
				Mplus_Box:SetPoint("LEFT", previousBox, "RIGHT", 2, 0)
			end
		end
	end

	WeeklyKeysHistory = {}

	for i = 1, RequiredKeys_MaxVault do
		if i <= #KeysDone and #WeeklyInfo > 0 then
			print(#KeysDone)
			tinsert(WeeklyKeysHistory, KeysDone[i].level)
		else
			print("breaking")
			break -- Exit the loop if KeysDone[i] or KeysDone[i].level doesn't exist
		end
	end

	for i = 1, RequiredKeys_MaxVault do
		if WeeklyKeysHistory[i] ~= nil and WeeklyKeysHistory[i] > 0 then
			if i == 1 or i == 4 or i == 8 then
				_G["Mplus_Box" .. i]:SetBackdropBorderColor(1.000, 0.824, 0.000, 0.000)
				_G["Mplus_Box" .. i]:SetBackdropColor(1, 0.784, 0.047, 1.000)
			else
				_G["Mplus_Box" .. i]:SetBackdropBorderColor(0.000, 1.000, 1.000, 0)
				_G["Mplus_Box" .. i]:SetBackdropColor(0.000, 1.000, 1.000, 1.000)
			end
		end
	end
end

function AMT:WeeklyBest_Display()
	--[[
Weekly Best Key Section
    --]]
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
			return b < a
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
	--Create the WeeklyBest_Keylevel if not already created
	if not WeeklyBest_Keylevel then
		WeeklyBest_Keylevel = WeeklyBest_Bg:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 0, 0)
	end
	if KeysDone[1] == 0 then
		WeeklyBest_Keylevel:SetTextColor(0.804, 0.804, 0.804, 1.0)
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 38)
		WeeklyBest_Keylevel:SetText("N/A")
	else
		WeeklyBest_Keylevel:SetText(WeeklyBest_Color:WrapTextInColorCode("+" .. WeeklyBest_Key))
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 42)
		WeeklyBest_Keylevel:SetTextColor(1, 1, 1, 1.0)
		-- WeeklyBest_Keylevel:SetTextColor(0, 0.624, 0.863, 1.0)
	end
end

function AMT:AMT_DungeonList()
	if not DungeonList_MainFrame then
		DungeonList_MainFrame = CreateFrame("Frame", "DungeonList_MainFrame", AMT_Container_BG, "BackdropTemplate")
		DungeonList_MainFrame:SetSize(570, 69)
		DungeonList_MainFrame:SetPoint("BOTTOMLEFT", AMT_Container_BG, "BOTTOMLEFT", 218, 2)
		DungeonList_MainFrame:SetBackdrop(BackdropInfo)

		DungeonList_MainFrame:SetBackdropBorderColor(1, 1, 1, 0.0)
		DungeonList_MainFrame:SetBackdropColor(1, 1, 1, 0.000)
	end
	local Current_SeasonalDung_Info = {}
	local currentSeasonMap = C_ChallengeMode.GetMapTable()
	for i = 1, #currentSeasonMap do
		local dungeonID = currentSeasonMap[i]
		local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(dungeonID)
		local alts, score = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(dungeonID)
		tinsert(Current_SeasonalDung_Info, { dungID = dungeonID, dungName = name, dungIcon = icon })
	end
	if not _G["DungeonIcon_" .. #Current_SeasonalDung_Info] then
		for i = 1, #Current_SeasonalDung_Info do
			local dungIconHeight = DungeonList_MainFrame:GetHeight()
			local dungIconWidth = dungIconHeight

			DungIcon = CreateFrame("Frame", "DungeonIcon_" .. i, DungeonList_MainFrame)
			DungIcon:SetSize(dungIconWidth, dungIconHeight)
			DungIcon.tex = DungIcon:CreateTexture()
			DungIcon.tex:SetAllPoints(DungIcon)
			DungIcon.tex:SetTexture(Current_SeasonalDung_Info[i].dungIcon)

			if i == 1 then
				DungIcon:SetPoint("LEFT", DungeonList_MainFrame, "LEFT", 0, 0)
			else
				local previousBox = _G["DungeonIcon_" .. (i - 1)]
				DungIcon:SetPoint("LEFT", previousBox, "RIGHT", 2, 0)
			end
		end
	end
	if not DungIcon_Label then
		for i = 1, #Current_SeasonalDung_Info do
			DungIcon_Abbr = DungeonAbbr[Current_SeasonalDung_Info[i].dungID]
			DungIcon_Label = DungIcon:CreateFontString(nil, "OVERLAY", "GameFontNormalCenter")
			DungIcon_Label:SetPoint("TOP", _G["DungeonIcon_" .. i], "TOP", 0, -1)
			DungIcon_Label:SetFont(DungIcon_Label:GetFont(), 16, "OUTLINE")
			DungIcon_Label:SetTextColor(1, 1, 1)
			DungIcon_Label:SetText(DungIcon_Abbr)
		end
	end
end
