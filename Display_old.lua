local addonName, AMT = ...

WeeklyInfo = C_MythicPlus.GetRunHistory(false, true)
VaultInfo = C_WeeklyRewards.GetActivities()

function GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(SeasonalDungeons) do
		if dungeon.challengeModeID == id then
			return dungeon.abbr
		end
	end
	return nil -- Return nil if no matching dungeon is found
end

function AMT:WeeklyBest()
	local RaiderIO = _G["RaiderIO"]
	local WeeklyBest_Key_Color
	KeysDone = {}

	for i = 1, #WeeklyInfo do
		local KeyLevel = WeeklyInfo[i].level
		tinsert(KeysDone, KeyLevel)
	end

	if KeysDone[1] == nil then
		KeysDone = { 0 }
	else
		table.sort(KeysDone, function(a, b)
			return b < a
		end)
	end
	if RaiderIO and KeysDone[1] ~= nil then
		-- AvgRIOScore = RaiderIO.GetKeystoneAverageScoreForLevel(KeysDone[1])
		WeeklyBest_Key_Color = CreateColor(RaiderIO.GetScoreColor(2000, false))
	end

	local WeeklyBest_Key = KeysDone[1]
	if not WeeklyBest_Keylevel then
		WeeklyBest_Keylevel = WeeklyBest_Bg:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		WeeklyBest_Keylevel:SetPoint("CENTER", WeeklyBest_Bg, "CENTER", 0, 0)
		-- WeeklyBest_Keylevel:SetText("|cffff8000" .. "+" .. WeeklyBest_Key)
		WeeklyBest_Keylevel:SetText("+" .. WeeklyBest_Key)
		WeeklyBest_Keylevel:SetFont(WeeklyBest_Keylevel:GetFont(), 42)
		WeeklyBest_Keylevel:SetTextColor(WeeklyBest_Key_Color.r, WeeklyBest_Key_Color.g, WeeklyBest_Key_Color.b)
	else
		WeeklyBest_Keylevel:SetText("+" .. WeeklyBest_Key)
	end
end

function AMT:WeeklyRaid()
	local seasonID = C_MythicPlus.GetCurrentSeason()
	raids = AMT:Filter_Table(SeasonalRaids, function(SeasonalRaids)
		return SeasonalRaids.seasonID == seasonID
	end)

	table.sort(raids, function(a, b)
		return a.order < b.order
	end)

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

	-- for savedInstanceIndex, savedInstance in ipairs(raids.savedInstances) do
	-- 	if savedInstance.instanceID == 2522 then
	-- 		print("Saved Instance Index:", savedInstanceIndex)
	-- 		print("  Name:", savedInstance.name)
	-- 		print("  Lockout ID:", savedInstance.lockoutId)
	-- 		print("  Reset:", savedInstance.reset)
	-- 		print("  Difficulty ID:", savedInstance.difficultyID)
	-- 		print("  Locked:", savedInstance.locked)
	-- 		print("  Extended:", savedInstance.extended)
	-- 		print("  Instance ID Most Sig:", savedInstance.instanceIDMostSig)
	-- 		print("  Is Raid:", savedInstance.isRaid)
	-- 		print("  Max Players:", savedInstance.maxPlayers)
	-- 		print("  Difficulty Name:", savedInstance.difficultyName)
	-- 		print("  Num Encounters:", savedInstance.numEncounters)
	-- 		print("  Encounter Progress:", savedInstance.encounterProgress)
	-- 		print("  Extend Disabled:", savedInstance.extendDisabled)
	-- 		print("  Instance ID:", savedInstance.instanceID)
	-- 		print("  Link:", savedInstance.link)
	-- 		print("  Expires:", savedInstance.expires)

	-- 		-- Iterate over each encounter in the saved instance
	-- 		for encounterIndex, encounter in ipairs(savedInstance.encounters) do
	-- 			print("    Encounter Index:", encounterIndex)
	-- 			print("      Boss Name:", encounter.bossName)
	-- 			print("      File Data ID:", encounter.fileDataID)
	-- 			print("      Killed:", encounter.killed)
	-- 		end
	-- 	end
	-- end

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

			------ SETS THE COLORING OF EACH BOX DEPENDING ON KILL
			-- for encounterIndex, encounter in ipairs(raid.encounters) do
			-- 	local color = { r = 1, g = 1, b = 1 }
			-- 	local alpha = 0.1
			-- 	local EncounterFrame = _G[DifficultyFrame:GetName() .. "Encounter" .. encounterIndex]
			-- 	if not EncounterFrame then
			-- 		EncounterFrame = CreateFrame("Frame", "$parentEncounter" .. encounterIndex, DifficultyFrame)
			-- 		local size = self.constants.sizes.column
			-- 		size = size - self.constants.sizes.padding -- left/right cell padding
			-- 		size = size - (raid.numEncounters - 1) * 4 -- gaps
			-- 		size = size / raid.numEncounters -- box sizes
			-- 		EncounterFrame:SetPoint(
			-- 			"LEFT",
			-- 			anchorFrame,
			-- 			encounterIndex > 1 and "RIGHT" or "LEFT",
			-- 			self.constants.sizes.padding / 2,
			-- 			0
			-- 		)
			-- 		EncounterFrame:SetSize(size, self.constants.sizes.row - 12)
			-- 		self:SetBackgroundColor(EncounterFrame, 1, 1, 1, 0.1)
			-- 	end
			-- 	if character.raids.savedInstances then
			-- 		local savedInstance = AE_table_find(character.raids.savedInstances, function(savedInstance)
			-- 			return savedInstance.difficultyID == difficulty.id
			-- 				and savedInstance.instanceID == raid.instanceID
			-- 				and savedInstance.expires > time()
			-- 		end)
			-- 		if savedInstance ~= nil then
			-- 			local savedEncounter = AE_table_find(savedInstance.encounters, function(enc)
			-- 				return enc.instanceEncounterID == encounter.instanceEncounterID and enc.killed == true
			-- 			end)
			-- 			if savedEncounter ~= nil then
			-- 				color = UNCOMMON_GREEN_COLOR
			-- 				if self.db.global.raids.colors then
			-- 					color = difficulty.color
			-- 				end
			-- 				alpha = 0.5
			-- 			end
			-- 		end
			-- 	end
			-- 	self:SetBackgroundColor(EncounterFrame, color.r, color.g, color.b, alpha)
			-- 	anchorFrame = EncounterFrame
			-- end
		end
	end
end

function AMT:WeeklyMplus()
	local RequiredKeys_MaxVault = 8
	if not _G["Mplus_Box" .. RequiredKeys_MaxVault] then
		for i = 1, RequiredKeys_MaxVault do
			local box_size = 15

			Mplus_Box = CreateFrame("Frame", "Mplus_Box" .. i, MplusDifficulty_Goals, "BackdropTemplate")
			Mplus_Box:SetSize(box_size, box_size)

			Mplus_Box:SetBackdrop(BackdropInfo)
			Mplus_Box:SetBackdropBorderColor(0.000, 0.000, 1.000, 0)
			Mplus_Box:SetBackdropColor(1.000, 1.000, 1.000, 0.500)

			if i == 1 then
				Mplus_Box:SetPoint("RIGHT", MplusDifficulty_Goals, "RIGHT", -3, 0)
			else
				local previousBox = _G["Mplus_Box" .. (i - 1)]
				Mplus_Box:SetPoint("RIGHT", previousBox, "LEFT", -3, 0)
			end
		end
	end

	WeeklyKeysHistory = {}

	for i = 1, RequiredKeys_MaxVault do
		if KeysDone[i] == nil then
			tinsert(WeeklyKeysHistory, 0)
		else
			tinsert(WeeklyKeysHistory, KeysDone[i])
		end
	end

	for i = 1, RequiredKeys_MaxVault do
		local reverse_ordering = RequiredKeys_MaxVault + 1 - i
		if WeeklyKeysHistory[i] ~= nil and WeeklyKeysHistory[i] > 0 then
			if i == 1 or i == 4 or i == 8 then
				_G["Mplus_Box" .. reverse_ordering]:SetBackdropBorderColor(1.000, 0.824, 0.000, 0.000)
				_G["Mplus_Box" .. reverse_ordering]:SetBackdropColor(1.000, 0.824, 0.000, 1.000)
			else
				_G["Mplus_Box" .. reverse_ordering]:SetBackdropBorderColor(0.000, 1.000, 1.000, 0)
				_G["Mplus_Box" .. reverse_ordering]:SetBackdropColor(0.000, 1.000, 1.000, 1.000)
			end
		end
	end
end

function AMT:WeeklyPVP()
	WeeklyPVP_HonorBox = CreateFrame("Frame", "HonorBox", PVPHonor_Goals, "BackdropTemplate")
	WeeklyPVP_HonorBox:SetSize(134, 15)

	WeeklyPVP_HonorBox:SetBackdrop(BackdropInfo)
	WeeklyPVP_HonorBox:SetBackdropBorderColor(0.000, 0.800, 1.000, 0)
	WeeklyPVP_HonorBox:SetBackdropColor(0.000, 0.800, 1.000, 1.000)
	WeeklyPVP_HonorBox:SetPoint("RIGHT", PVPHonor_Goals, "RIGHT", -3, 0)
end

function AMT:AMT_KeystoneItem()
	if not KeystoneItem_Icon then
		KeystoneItem_Icon = CreateFrame("Frame", "KeystoneItem_Icon", RuneArt)
		KeystoneItem_Icon:SetPoint("CENTER")
		KeystoneItem_Icon:SetSize(40, 40)
	end
	if not KeystoneItem_Glow then
		KeystoneItem_Glow = CreateFrame("Frame", "KeystoneItem_Glow", RuneArt)
		KeystoneItem_Glow:SetPoint("CENTER")
		KeystoneItem_Glow:SetSize(66, 66)
		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetSize(54, 54)
		KeystoneItem_Glow.tex:SetAllPoints(KeystoneItem_Glow)
		KeystoneItem_Glow.tex:SetAtlas("BonusChest-ItemBorder-Uncommon")
	end

	local id = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(id)
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		KeystoneItem_Icon.tex = KeystoneItem_Icon:CreateTexture()
		KeystoneItem_Icon.tex:SetAllPoints(KeystoneItem_Icon)
		KeystoneItem_Icon.tex:SetTexture(icon)

		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetVertexColor(1.000, 0.824, 0.000, 0.750)
	else
		KeystoneItem_Icon.tex = KeystoneItem_Icon:CreateTexture()
		KeystoneItem_Icon.tex:SetAllPoints(KeystoneItem_Icon)
		KeystoneItem_Icon.tex:SetTexture(4352494)
		KeystoneItem_Icon.tex:SetDesaturated(true)

		KeystoneItem_Glow.tex = KeystoneItem_Glow:CreateTexture()
		KeystoneItem_Glow.tex:SetVertexColor(1, 1, 1, 0.750)
	end

	-- KeystoneItem_Icon.tex:SetTexture(525134)

	AMT:AMT_KeystoneItem_TT()
end

function AMT:AMT_KeystoneItem_TT()
	local id = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local abbr = GetAbbrFromChallengeModeID(id)
	local name = C_ChallengeMode.GetMapUIInfo(id)

	local level = C_MythicPlus.GetOwnedKeystoneLevel()
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		local Keystone_DungName_Bg = CreateFrame("Frame", "CurrentKey_TopLabel", AMT_Container_Data, "BackdropTemplate")
		Keystone_DungName_Bg:SetSize(68, 20)
		Keystone_DungName_Bg:SetPoint("BOTTOMLEFT", AMT_Container_Data, "BOTTOMLEFT", 76, 110)
		Keystone_DungName_Bg:SetBackdrop(BackdropInfo)

		Keystone_DungName_Bg:SetBackdropBorderColor(0, 0, 0, 0.5)
		Keystone_DungName_Bg:SetBackdropColor(0, 0, 0, 0.5)

		if not Keystone_DungName then
			Keystone_DungName = KeystoneItem_Icon:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
			-- Keystone_DungName:SetPoint("TOP", KeystoneItem_Icon, "TOP", 0, 26)
			Keystone_DungName:SetPoint("CENTER", Keystone_DungName_Bg, "CENTER", 0, 1)
			Keystone_DungName:SetText("+" .. level .. " " .. abbr)
			Keystone_DungName:SetFont(Keystone_DungName:GetFont(), 14)
		else
			Keystone_DungName:SetText("+" .. level .. " " .. abbr)
		end

		--Initiate Modifiers
		local mod = C_ChallengeMode.GetPowerLevelDamageHealthMod(level)

		local modFort = { 30, 15, 0, 0 }

		local affix = C_MythicPlus.GetCurrentAffixes()
		if affix then
			if affix[1].id == 10 then
				modFort = { 0, 0, 20, 30 }
			end
		end

		local modifiers = BOSS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. mod + modFort[1]
			.. "%\n"
			.. BOSS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. mod + modFort[2]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-healer")
			.. " +"
			.. mod + modFort[3]
			.. "%\n"
			.. UNIT_NAME_ENEMY_MINIONS
			.. CreateAtlasMarkup("roleicon-tiny-dps")
			.. " +"
			.. mod + modFort[4]
			.. "%"

		local VaultReward, DungeonReward = C_MythicPlus.GetRewardLevelForDifficultyLevel(level)

		local TT_KeystoneInfo = "|cffffffffKeystone: |cffc845fa" .. name .. " +" .. level .. "\n\n"
		local TT_DungeonModifiers = "|cffffffffDungeon Modifiers:|r\n" .. modifiers .. "\n\n"
		local TT_Rewards = "|cffffffffRewards:|r"
			.. "\n"
			.. "End of Dungeon: "
			.. DungeonReward
			.. "\n"
			.. "Great Vault: "
			.. VaultReward
			.. "\n\n"
		local tab = "          "
		local whitetext = "|cffffffff"
		if RaiderIO then
			local playerprofile = RaiderIO.GetProfile("player")
			if
				playerprofile == nil
				or playerprofile.mythicKeystoneProfile == nil
				or playerprofile.mythicKeystoneProfile.keystoneFivePlus == nil
			then
				TT_RaiderIO = "No timed runs found."
			else
				TT_RaiderIO_Title = "|cffffffffTimed Runs:"
				TT_RaiderIO_Total = "|cff009dd5"
					.. playerprofile.mythicKeystoneProfile.keystoneTwentyPlus + playerprofile.mythicKeystoneProfile.keystoneFifteenPlus + playerprofile.mythicKeystoneProfile.keystoneTenPlus + playerprofile.mythicKeystoneProfile.keystoneFivePlus
					.. "+"
				TT_RaiderIO_20L = "   • For +20 "
				TT_RaiderIO_20R = playerprofile.mythicKeystoneProfile.keystoneTwentyPlus .. "+"
				TT_RaiderIO_15L = "   • For +15 - 19 "
				TT_RaiderIO_15R = playerprofile.mythicKeystoneProfile.keystoneFifteenPlus .. "+"
				TT_RaiderIO_10L = "   • For +10 - 14 "
				TT_RaiderIO_10R = playerprofile.mythicKeystoneProfile.keystoneTenPlus .. "+"
				TT_RaiderIO_5L = "   • For +5 - 9 "
				TT_RaiderIO_5R = playerprofile.mythicKeystoneProfile.keystoneFivePlus .. "+"
				TT_RaiderIO = "Timed Runs|cff009dd5"
					.. tab
					.. playerprofile.mythicKeystoneProfile.keystoneTwentyPlus + playerprofile.mythicKeystoneProfile.keystoneFifteenPlus + playerprofile.mythicKeystoneProfile.keystoneTenPlus + playerprofile.mythicKeystoneProfile.keystoneFivePlus
					.. "+"
					.. "\n \n   • for +20 "
					.. whitetext
					.. tab
					.. playerprofile.mythicKeystoneProfile.keystoneTwentyPlus
					.. "+"
					.. "\n\n   • for +15 "
					.. whitetext
					.. tab
					.. playerprofile.mythicKeystoneProfile.keystoneFifteenPlus
					.. "+"
					.. "\n\n   • for +10 "
					.. whitetext
					.. tab
					.. playerprofile.mythicKeystoneProfile.keystoneTenPlus
					.. "+"
					.. "\n\n   • for +5   "
					.. whitetext
					.. tab
					.. playerprofile.mythicKeystoneProfile.keystoneFivePlus
					.. "+"
			end

			KeystoneItem_Icon:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(TT_KeystoneInfo)
				GameTooltip:AddLine(TT_DungeonModifiers)
				GameTooltip:AddLine(TT_Rewards)
				-- GameTooltip:AddLine(TT_RaiderIO)
				GameTooltip:AddDoubleLine(TT_RaiderIO_Title, TT_RaiderIO_Total)
				GameTooltip:AddDoubleLine(TT_RaiderIO_20L, TT_RaiderIO_20R)
				GameTooltip:AddDoubleLine(TT_RaiderIO_15L, TT_RaiderIO_15R)
				GameTooltip:AddDoubleLine(TT_RaiderIO_10L, TT_RaiderIO_10R)
				GameTooltip:AddDoubleLine(TT_RaiderIO_5L, TT_RaiderIO_5R)
				GameTooltip:Show()
			end)
			KeystoneItem_Icon:SetScript("OnLeave", function()
				GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
			end)
		else
			KeystoneItem_Icon:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(
					"If you'd like detailed breakdown of your keys,\n install & enable the |cffffffffRaider.IO|r addon."
				)
				GameTooltip:Show()
			end)
			KeystoneItem_Icon:SetScript("OnLeave", function()
				GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
			end)
		end
	else
		KeystoneItem_Icon:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine("Get your Keystone by completing any dungeon\non Mythic or Mythic Plus Difficulty")
			GameTooltip:Show()
		end)
		KeystoneItem_Icon:SetScript("OnLeave", function()
			GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
		end)
	end
end

function AMT:AMT_GreatVault_Button()
	if not GreatVault_Button then
		GreatVault_Button = CreateFrame("Button", nil, AMT_Container_Data, "UIPanelButtonTemplate")
		GreatVault_Button:SetPoint("BOTTOMLEFT", AMT_Container_Data, "BOTTOMLEFT", 76, 20)
		GreatVault_Button:SetSize(70, 30)
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

function AMT:Display_Data()
	AMT:WeeklyBest()
	AMT:AMT_GreatVault_Button()
	AMT:WeeklyRaid()
	AMT:WeeklyMplus()
	AMT:WeeklyPVP()
	AMT:AMT_KeystoneItem()
	-- AMT:AMT_KeystoneItem_TT()
end
