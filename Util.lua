local addonName, AMT = ...

--Debugging Prints
function AMT:PrintDebug(str)
	if not self.db.DebugMode then
		return
	end
	print("|cff18a8ffAMT|r Debug: " .. str)
end

-- Function to update the highest key for a dungeon
function AMT:UpdateHighestKey(dungeonAbbr, keylevel)
	for _, dungeon in ipairs(self.BestKeys_per_Dungeon) do
		AMT:PrintDebug("Checking dungeon: " .. dungeon.dungAbbr) -- Debug print
		if dungeon.dungAbbr == dungeonAbbr then
			dungeon.HighestKey = tonumber(keylevel)
			local KeyBullets = ""
			local BulletTemplate = "• "
			for i = 1, keylevel do
				KeyBullets = KeyBullets .. BulletTemplate
			end
			dungeon.DungBullets = KeyBullets
			AMT:PrintDebug("Updated " .. dungeon.dungAbbr .. " with key level " .. keylevel)
			AMT:AMT_UpdateMythicGraph()
			return
		end
	end
	AMT:PrintDebug("Dungeon abbreviation not found: " .. dungeonAbbr)
end

--Check Number of Tabs displayed on PVEFrame
function AMT:Check_PVEFrame_TabNums()
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
-- =========================
-- === Utility Functions ===
-- =========================
function AMT:Update_PVEFrame_Panels()
	if UnitLevel("player") >= GetMaxLevelForPlayerExpansion() and not PlayerGetTimerunningSeasonID() then
		for i = 1, #self.PVEFrame_Panels do
			if
				self.PVEFrame_Panels[i].text == "Mythic+ Dungeons"
				or self.PVEFrame_Panels[i].text == "Advanced Mythic Tracker"
			then
				self.PVEFrame_Panels[i].isVisible = true
			end
		end
	end
end

--Get Dungeon Abbreviations from MapIDs
function AMT:GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		if dungeon.mapID == id then
			return dungeon.abbr
		end
	end
	return nil -- Return nil if no matching dungeon is found
end

--Get End of Dungeon reward for key level
function AMT:AMT_GetKeystoneRewards(keylevel)
	local key
	if keylevel > 10 then
		key = 10
	else
		key = keylevel
	end
	local vaultReward = ""
	local dungeonReward = ""
	for _, level in ipairs(self.RewardsTable) do
		if level.Key == key then
			vaultReward = level.GreatVault .. " (" .. level.VaultUpgradeTrack .. ")"
			dungeonReward = level.EndofDungeon .. " (" .. level.DungeonUpgradeTrack .. ")"
			break
		end
	end
	return vaultReward, dungeonReward
end

--Pick random keystone from the group and print out to group
function AMT:AMT_RandomKeystonePicker()
	local i = math.random(#self.GroupKeystone_Info)
	local playername = AMT_StripColorText(self.GroupKeystone_Info[i].player)
	local keyabbr = self.GroupKeystone_Info[i].name
	local keyname
	for _, dungeon in ipairs(self.SeasonalDungeons) do
		if dungeon.abbr == keyabbr then
			keyname = dungeon.name
			break
		end
	end
	local keylevel = self.GroupKeystone_Info[i].level
	local msg = "Next Key: " .. playername .. "'s " .. keyname .. " (" .. keylevel .. ")"
	if IsInGroup() and not IsInRaid() then
		SendChatMessage(msg, "PARTY")
	end
end

--Get Next Affix Rotation
function AMT:AMT_UpdateAffixInformation()
	wipe(self.CurrentWeek_AffixTable or {})
	local currentRotation
	self.GetCurrentAffixesTable = C_MythicPlus.GetCurrentAffixes() or {} --Current Affix Raw Table
	-- Amtesttable = C_MythicPlus.GetCurrentAffixes() or {} --Current Affix Raw Table
	if #self.CurrentWeek_AffixTable == 0 and #self.GetCurrentAffixesTable ~= 0 then
		table.insert(self.CurrentWeek_AffixTable, {
			self.GetCurrentAffixesTable[1].id,
			self.GetCurrentAffixesTable[2].id,
			self.GetCurrentAffixesTable[3].id,
			self.GetCurrentAffixesTable[4].id,
			self.GetCurrentAffixesTable[5].id,
		})
		currentRotation = self.CurrentWeek_AffixTable[1]
	end
	local nextRotationIndex = nil

	-- Find the index of the current rotation in AffixRotation
	if currentRotation then
		for i, rotationInfo in ipairs(self.AffixRotation) do
			if AMT:CompareArrays(rotationInfo.rotation, currentRotation) then
				nextRotationIndex = i + 1
				break
			end
		end
	end

	if nextRotationIndex then
		-- Wrap around if reached the end of AffixRotation
		nextRotationIndex = nextRotationIndex > #self.AffixRotation and 1 or nextRotationIndex
		local nextRotation = self.AffixRotation[nextRotationIndex].rotation

		-- Return the next rotation
		NextWeek_AffixTable = { nextRotation }
		return
	end

	return nil -- Current rotation not found in AffixRotation
end

-- Process Party Keystone Refresh Request
function AMT:AMT_PartyKeystoneRefreshRequest()
	if IsInGroup() and not IsInRaid() then
		self.OpenRaidLib.RequestKeystoneDataFromParty()
		C_Timer.After(0.5, function()
			AMT:AMT_PartyKeystoneRefresh()
		end)
		C_Timer.After(2, function()
			AMT:AMT_PartyKeystoneRefresh()
		end)
	else
		print("|cff18a8ffAMT|r: Must be in a group with multiple keystones to refresh")
	end
end

--Update Party Keystones for Ready Check/Pull Timer
function AMT:AMT_KeystoneRefresh()
	wipe(self.GroupKeystone_Info or {})
	if self.DetailsEnabled and not UnitInRaid("player") then
		for i = 1, 5 do
			local unitID = i == 1 and "player" or "party" .. i - 1
			local data = self.OpenRaidLib.GetKeystoneInfo(unitID)
			local mapID = data and data.challengeMapID
			for _, dungeon in ipairs(self.SeasonalDungeons) do
				if dungeon.mapID == mapID then
					Keyname_abbr = dungeon.abbr
					if mapID and Keyname_abbr then
						local level = data.level
						local playerClass = UnitClassBase(unitID)
						local playerName = UnitName(unitID)
						local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))
						local name = dungeon.name
						local instanceID = dungeon.instanceID

						tinsert(self.GroupKeystone_Info, {
							level = level,
							mapID = tonumber(mapID),
							instanceID = instanceID,
							abbr = Keyname_abbr,
							name = name,
							player = AMT_ClassColorString(playerName, playerClass),
							playerName = tostring(playerName),
							playerClass = playerClass,
							icon = texture,
						})
					end
				end
			end
		end

		--Sort the keys found from highest to lowest
		if #self.GroupKeystone_Info > 1 then
			table.sort(self.GroupKeystone_Info, function(a, b)
				return b.level < a.level
			end)
		end
	end
end

-- Update Party Keystones
function AMT:AMT_PartyKeystoneRefresh()
	wipe(self.GroupKeystone_Info or {})
	if self.DetailsEnabled and not UnitInRaid("player") then
		for i = 1, 5 do
			local unitID = i == 1 and "player" or "party" .. i - 1
			local data = self.OpenRaidLib.GetKeystoneInfo(unitID)
			local mapID = data and data.challengeMapID
			for _, dungeon in ipairs(self.SeasonalDungeons) do
				if dungeon.mapID == mapID then
					Keyname_abbr = dungeon.abbr
					if mapID and Keyname_abbr then
						local level = data.level
						local playerClass = UnitClassBase(unitID)
						local playerName = UnitName(unitID)
						local texture = select(4, C_ChallengeMode.GetMapUIInfo(tonumber(mapID)))

						tinsert(self.GroupKeystone_Info, {
							level = level,
							name = Keyname_abbr,
							player = AMT_ClassColorString(playerName, playerClass),
							icon = texture,
						})
					end
				end
			end
		end

		--Sort the keys found from highest to lowest
		if #self.GroupKeystone_Info > 1 then
			table.sort(self.GroupKeystone_Info, function(a, b)
				return b.level < a.level
			end)
		end
		for i = 1, 5 do
			local left_text = _G["AMT_PartyKeystyone_Left" .. i]
			local right_text = _G["AMT_PartyKeystyone_Right" .. i]
			if self.GroupKeystone_Info[i] then
				right_text:SetText(self.GroupKeystone_Info[i].player)
				left_text:SetText(
					format(
						"|T%s:16:16:0:0:64:64:4:60:7:57:255:255:255|t |c%s%s - %s|r",
						self.GroupKeystone_Info[i].icon,
						AMT_getKeystoneLevelColor(self.GroupKeystone_Info[i].level),
						self.GroupKeystone_Info[i].level,
						self.GroupKeystone_Info[i].name
					)
				)
			else
				right_text:SetText("")
				left_text:SetText("")
			end
		end
	end
end

--Update Player M+ Score
function AMT:AMT_Update_PlayerMplus_Score()
	AMT.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	AMT.Player_Mplus_ScoreColor =
		C_ChallengeMode.GetDungeonScoreRarityColor(AMT.Player_Mplus_Summary.currentSeasonScore)
end

--Load Raid Tracking Data
function AMT:LoadTrackingData()
	for _, raid in pairs(self.SeasonalRaids) do
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

function AMT:Pull_VaultRequirements()
	local Mplus_VaultReqs = C_WeeklyRewards.GetActivities(1)
	local Raid_VaultReqs = C_WeeklyRewards.GetActivities(3)
	local World_VaultReqs = C_WeeklyRewards.GetActivities(6)
	wipe(self.Mplus_VaultUnlocks or {})
	wipe(self.Raid_VaultUnlocks or {})
	wipe(self.World_VaultUnlocks or {})

	for i = 1, #Mplus_VaultReqs do
		tinsert(self.Mplus_VaultUnlocks, Mplus_VaultReqs[i].threshold)
	end
	for i = 1, #Raid_VaultReqs do
		tinsert(self.Raid_VaultUnlocks, Raid_VaultReqs[i].threshold)
	end
	for i = 1, #World_VaultReqs do
		tinsert(self.World_VaultUnlocks, World_VaultReqs[i].threshold)
		if i == #World_VaultReqs then
			self.World_VaultTracker = World_VaultReqs[i].progress
		end
	end

	AMT.Vault_DungeonReq = math.max(unpack(self.Mplus_VaultUnlocks))
	AMT.Vault_RaidReq = math.max(unpack(self.Raid_VaultUnlocks))
	AMT.Vault_WorldReq = math.max(unpack(self.World_VaultUnlocks))
end

function AMT:AMT_UpdateRaidProg()
	self.RaidVault_Bosses = C_WeeklyRewards.GetActivityEncounterInfo(3, 1) --Grab current encounters that count towards vault
	--sort the encounters so in case of multiple raids so that first raid appears first.
	if self.RaidVault_Bosses then
		table.sort(self.RaidVault_Bosses, function(left, right)
			if left.instanceID ~= right.instanceID then
				return left.instanceID < right.instanceID
			end
			return left.uiOrder < right.uiOrder
		end)
	end
	wipe(self.SeasonalRaids or {})
	--Reset Weekly_KillCount table
	for i = 1, #self.Weekly_KillCount do
		self.Weekly_KillCount[i].kills = 0
	end
	--Grab the raids journal ID, instance ID, and name.
	for i = 1, #self.RaidVault_Bosses do
		local journalInstanceID = self.RaidVault_Bosses[i].instanceID
		local instanceID = self.RaidVault_Bosses[i].encounterID
		if not AMT:Exists_in_Table(self.SeasonalRaids, journalInstanceID) then
			local name = EJ_GetInstanceInfo(journalInstanceID)
			tinsert(self.SeasonalRaids, {
				name = name,
				journalInstanceID = journalInstanceID,
				instanceID = instanceID,
				reset = 0,
				difficulty = {
					LFR = {
						reset = 0,
						lockout = {},
					},
					N = {
						reset = 0,
						lockout = {},
					},
					H = {
						reset = 0,
						lockout = {},
					},
					M = {
						reset = 0,
						lockout = {},
					},
				},
			})
		end
	end

	SeasonalRaid_Info = {
		LFR = {},
		N = {},
		H = {},
		M = {},
	}

	local resettime = 0
	local numSavedInstances = GetNumSavedInstances()
	if numSavedInstances > 0 then
		for savedInstanceIndex = 1, numSavedInstances do
			local name, lockoutID, reset, difficultyID, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID =
				GetSavedInstanceInfo(savedInstanceIndex)

			for _, raid in ipairs(self.Raids) do
				if instanceID == raid.instanceID then
					instanceID = raid.journalInstanceID
				end
			end

			if encounterProgress > 0 and reset and reset > 0 then
				for _, difficulty in ipairs(self.Weekly_KillCount) do
					if difficulty.name == difficultyName then
						difficulty.kills = difficulty.kills + encounterProgress
					end
				end
			end

			for encounterIndex = 1, numEncounters do
				local bossName, fileDataID, killed = GetSavedInstanceEncounterInfo(savedInstanceIndex, encounterIndex)
				local instanceEncounterID = 0

				if reset and reset > 0 then
					resettime = reset + time()
				else
					resettime = 0
				end
				for _, SeasonalRaid_Info in pairs(self.SeasonalRaids) do
					if instanceID == SeasonalRaid_Info.journalInstanceID then
						if difficultyID == 17 then
							SeasonalRaid_Info.difficulty.LFR.reset = resettime
							tinsert(SeasonalRaid_Info.difficulty.LFR.lockout, {
								index = encounterIndex,
								instanceEncounterID = instanceEncounterID,
								bossName = bossName,
								fileDataID = fileDataID or 0,
								killed = killed,
							})
						elseif difficultyID == 16 then
							SeasonalRaid_Info.difficulty.M.reset = resettime
							tinsert(SeasonalRaid_Info.difficulty.M.lockout, {
								index = encounterIndex,
								instanceEncounterID = instanceEncounterID,
								bossName = bossName,
								fileDataID = fileDataID or 0,
								killed = killed,
							})
						elseif difficultyID == 15 then
							SeasonalRaid_Info.difficulty.H.reset = resettime
							tinsert(SeasonalRaid_Info.difficulty.H.lockout, {
								index = encounterIndex,
								instanceEncounterID = instanceEncounterID,
								bossName = bossName,
								fileDataID = fileDataID or 0,
								killed = killed,
							})
						elseif difficultyID == 14 then
							SeasonalRaid_Info.difficulty.N.reset = resettime
							tinsert(SeasonalRaid_Info.difficulty.N.lockout, {
								index = encounterIndex,
								instanceEncounterID = instanceEncounterID,
								bossName = bossName,
								fileDataID = fileDataID or 0,
								killed = killed,
							})
						end
					end
				end
			end
		end
	end
end

--Grab the Keystone color to be used for the Party Keystone Container
function AMT_getKeystoneLevelColor(level)
	-- Was initially 5,10,15,20.
	-- Changed to 2,5,10 to account for DF S4 changes.
	-- Changed 4,7,10,12 to accccount for TWW S1 changes.
	if level < 4 then
		return "ffffffff"
	elseif level < 7 then
		return "ff1eff00"
	elseif level < 10 then
		return "ff0070dd"
	elseif level < 12 then
		return "ffa335ee"
	else
		return "ffff8000"
	end
end

--Upldate Player M+ information
function AMT:Update_PlayerDungeonInfo()
	--Reset the state of the tables - need to check if it's actually resetting the values
	wipe(self.KeysDone or {})
	wipe(self.BestKeys_per_Dungeon or {})
	wipe(self.Current_SeasonalDung_Info or {})
	wipe(self.RunHistory or {})
	--Grab Weekly Run history for this season and only timed keys
	self.RunHistory = C_MythicPlus.GetRunHistory(false, true)
	--Grab Vault Rewards Info
	VaultInfo = C_WeeklyRewards.GetActivities() --Not doing anything with this right now
	--For each key done insert them into self.KeysDone table
	for i = 1, #self.RunHistory do
		local KeyLevel = self.RunHistory[i].level
		local KeyID = self.RunHistory[i].mapChallengeModeID
		tinsert(self.KeysDone, { level = KeyLevel, keyid = KeyID, keyname = "" })
	end
	--Sort self.KeysDone so that the highest keys are at the top. This is how we'll grab top key of the week info
	if self.KeysDone[1] == nil then
		self.KeysDone = { 0 }
	else
		table.sort(self.KeysDone, function(a, b)
			return b.level < a.level
		end)
		for _, entry in ipairs(self.KeysDone) do
			for _, dungeon in ipairs(self.SeasonalDungeons) do
				if entry.keyid == dungeon.mapID then
					entry.keyname = dungeon.name
					break -- Once found, no need to continue searching
				end
			end
		end
	end

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
		tinsert(self.Current_SeasonalDung_Info, {
			mapID = dungeonID,
			dungName = name,
			dungIcon = icon,
			dungOverallScore = dungOverallScore,
			dungTyrScore = TyrDungScore,
			dungFortScore = FortDungScore,
			dungTyrLevel = TyrDungLevel,
			dungFortLevel = FortDungLevel,
			intimeInfo = intimeInfo,
			overtimeInfo = overtimeInfo,
		})
		local dungAbbr = ""
		for _, dungeon in ipairs(self.SeasonalDungeons) do
			if dungeonID == dungeon.mapID then
				dungAbbr = dungeon.Abbr
				tinsert(self.BestKeys_per_Dungeon, {
					mapID = dungeon.mapID,
					dungAbbr = dungAbbr,
					HighestKey = 0,
					DungBullets = "",
				})
			end
		end
	end

	--Update BestKeys_per_Dungeon with the Highest Keys done per dungeon
	for _, bestKey in ipairs(self.BestKeys_per_Dungeon) do
		local highestKey = 0
		if #self.KeysDone > 0 and self.KeysDone[1] ~= 0 then
			for _, key in ipairs(self.KeysDone) do
				if key.keyid == bestKey.mapID and key.level > highestKey then
					highestKey = key.level
				end
			end
		end
		local KeyBullets = ""
		local BulletTemplate = "• "
		bestKey.HighestKey = 0
		bestKey.HighestKey = highestKey or 0
		for i = 1, bestKey.HighestKey do
			KeyBullets = KeyBullets .. BulletTemplate
		end
		bestKey.DungBullets = KeyBullets
	end
end

--Updates the M+ Graph
function AMT:AMT_UpdateMythicGraph()
	local dungLines = {}
	for i = 1, #self.BestKeys_per_Dungeon do
		local MythicRunsGraph_Container = _G["AMT_MythicRunsGraph_Container"]
		local graphlabel = _G["GraphDung_Label" .. i]
		local dungeonLine = _G["Dung_AntTrail" .. i]
		if not dungeonLine then
			dungLines[i] = MythicRunsGraph_Container:CreateFontString("Dung_AntTrail" .. i, "ARTWORK", "GameFontNormal")
			dungLines[i]:SetFont(AMT.AntTrail_Font, 14)
		else
			dungLines[i] = dungeonLine
		end

		local dungLine = dungLines[i]

		--If highest key done is same as the current weekly best color the line gold
		if self.BestKeys_per_Dungeon[i].HighestKey == self.KeysDone[1].level then
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
end

function AMT:Update_CrestTracker_Info()
	for i = 1, #self.Crests do
		local CurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(self.Crests[i].currencyID)
		local CurrencyTotalEarned = CurrencyInfo.totalEarned or 0
		local CurrentAmount = CurrencyInfo.quantity
		local CurrencyCapacity
		if CurrencyInfo.maxQuantity ~= 0 then
			CurrencyCapacity = CurrencyInfo.maxQuantity
		else
			CurrencyCapacity = 999
		end
		local ProgBar = _G[self.Crests[i].name .. "_StatusBar"]
		ProgBar:SetMinMaxValues(0, CurrencyCapacity)
		ProgBar:SetValue(CurrencyTotalEarned)
	end
end

-- ==============================
-- === MARK: Helper Functions ===
-- ==============================

-- Convert RGB to Hex
function AMT_RGBtoHexConversion(r, g, b, header, ending)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format("%s%02x%02x%02x%s", header or "|cff", r * 255, g * 255, b * 255, ending or "")
end

-- Color Text to appropriate Color Name
function AMT_ClassColorString(text, ClassName)
	local r, g, b = GetClassColor(ClassName)
	local hexcolor = r and g and b and AMT_RGBtoHexConversion(r, g, b) or "|cffffffff"
	return hexcolor .. text .. "|r"
end

--Strip a string of it's color wrapping
function AMT_StripColorText(coloredString)
	local color, text = coloredString:match("|c(%x%x%x%x%x%x%x%x)(.-)|r")
	return text
end

function AMT_CreateBackground(frame, backgroundColor)
	local background = frame:CreateTexture()
	background:SetAllPoints(frame)
	background:SetColorTexture(unpack(backgroundColor))
end

function AMT_CreateBorderButton(
	parentFrame,
	name,
	point,
	relativeTo,
	relativePoint,
	xOffset,
	yOffset,
	width,
	height,
	buttonText
)
	-- Create the Button
	local button = CreateFrame("Button", name, parentFrame)
	button:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	button:SetSize(width, height)
	button:SetText(buttonText)

	-- Create button background texture
	local button_bg = button:CreateTexture(nil, "ARTWORK")
	button_bg:SetAllPoints(button)
	button_bg:SetColorTexture(0, 0, 0, 1)

	-- Create the font string and attach it to the button
	local buttonLabel = button:CreateFontString(name .. "Label", "OVERLAY", "GameFontNormal")
	buttonLabel:SetPoint("CENTER", button, "CENTER", 2, 0)
	buttonLabel:SetFont(AMT.AMT_Font, 12, "OUTLINE")
	buttonLabel:SetJustifyH("CENTER")
	buttonLabel:SetJustifyV("MIDDLE")
	buttonLabel:SetText(buttonText)

	-- Create border textures
	local borderColor = { 0, 0.624, 0.863, 1 }

	local borderTop = button:CreateTexture(nil, "OVERLAY")
	borderTop:SetHeight(1)
	borderTop:SetColorTexture(unpack(borderColor))
	borderTop:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	borderTop:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 1)

	local borderBottom = button:CreateTexture(nil, "OVERLAY")
	borderBottom:SetHeight(1)
	borderBottom:SetColorTexture(unpack(borderColor))
	borderBottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -1, -1)
	borderBottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)

	local borderLeft = button:CreateTexture(nil, "OVERLAY")
	borderLeft:SetWidth(1)
	borderLeft:SetColorTexture(unpack(borderColor))
	borderLeft:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
	borderLeft:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", -1, -1)

	local borderRight = button:CreateTexture(nil, "OVERLAY")
	borderRight:SetWidth(1)
	borderRight:SetColorTexture(unpack(borderColor))
	borderRight:SetPoint("TOPRIGHT", button, "TOPRIGHT", 1, 1)
	borderRight:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)

	-- Hide the border by default
	borderTop:Hide()
	borderBottom:Hide()
	borderLeft:Hide()
	borderRight:Hide()

	-- Show the border on mouse enter
	button:SetScript("OnEnter", function()
		borderTop:Show()
		borderBottom:Show()
		borderLeft:Show()
		borderRight:Show()
	end)

	-- Hide the border on mouse leave
	button:SetScript("OnLeave", function()
		borderTop:Hide()
		borderBottom:Hide()
		borderLeft:Hide()
		borderRight:Hide()
	end)

	return button
end

function AMT:CreateProgressBar(name, texture, color, parent, width, height)
	local StatusBar_Container = CreateFrame("Frame", name .. "_Frame", parent)
	StatusBar_Container:SetSize(width, height)
	StatusBar_Container:SetPoint("CENTER")

	local StatusBar_ProgressBar = CreateFrame("StatusBar", name .. "_StatusBar", StatusBar_Container)
	StatusBar_ProgressBar:SetSize(width, height)
	StatusBar_ProgressBar:SetAllPoints(StatusBar_Container)
	StatusBar_ProgressBar:SetStatusBarTexture(texture)
	StatusBar_ProgressBar:GetStatusBarTexture():SetHorizTile(false)
	StatusBar_ProgressBar:SetMinMaxValues(0, 100)
	StatusBar_ProgressBar:SetStatusBarColor(unpack(color))

	local StatusBar_Bg = StatusBar_ProgressBar:CreateTexture(nil, "BACKGROUND")
	StatusBar_Bg:SetAtlas("widgetstatusbar-bgcenter")
	StatusBar_Bg:SetAllPoints(StatusBar_ProgressBar)
	StatusBar_Bg:SetVertexColor(0.25, 0.25, 0.25, 0.5)

	local StatusBar_Text = StatusBar_ProgressBar:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	StatusBar_Text:SetPoint("BOTTOM", StatusBar_ProgressBar, "TOP", 0, 3)

	-- hooksecurefunc(StatusBar_ProgressBar, "SetValue", function(self, value)
	-- 	text:SetText(text .. "%")
	-- end)

	return StatusBar_Container, StatusBar_ProgressBar, StatusBar_Text, StatusBar_Bg
end

-- ========================
-- === Re-evaluate cuz prob won't need for raid stuff ===
-- ========================

function AMT:Exists_in_Table(table, instanceID)
	for _, raid in ipairs(table) do
		if raid.journalInstanceID == instanceID then
			return true
		end
	end
	return false
end

-- Find and return dungeon name and abbreviation from mapID
function AMT:Find_Dungeon(mapID)
	for _, dungeon in ipairs(self.SeasonalDungeons) do
		if dungeon.mapID == mapID then
			return dungeon.abbr, dungeon.name
		end
	end
	return nil, nil
end

-- Compare two arrays
function AMT:CompareArrays(array1, array2)
	if #array1 ~= #array2 then
		return false
	end
	for i = 1, #array1 do
		if array1[i] ~= array2[i] then
			return false
		end
	end
	return true
end

function AMT:Find_Table(tbl, callback)
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			return v, i
		end
	end
	return nil, nil
end

-- Filter input tbl for only when the callback value exists in record
function AMT:Filter_Table(tbl, callback)
	local t = {}
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			table.insert(t, v)
		end
	end
	return t
end

function AMT:Get_Table(tbl, key, val)
	return AMT:Find_Table(tbl, function(elm)
		return elm[key] and elm[key] == val
	end)
end

function AMT:Table_Recall(tbl, callback)
	for ik, iv in pairs(tbl) do
		callback(iv, ik)
	end
	return tbl
end

function AE_table_foreach(tbl, callback)
	for ik, iv in pairs(tbl) do
		callback(iv, ik)
	end
	return tbl
end

function AMT:Filter_SeasonalRaids(seasonalRaids, difficulty)
	local filteredRaids = {}

	for raidIndex, raid in pairs(seasonalRaids) do
		-- Copy the raid's basic information
		local filteredRaid = {
			name = raid.name,
			journalInstanceID = raid.journalInstanceID,
			instanceID = raid.instanceID,
			difficulty = {},
		}

		-- Check if the specified difficulty exists in the raid
		if raid.difficulty[difficulty] then
			filteredRaid.difficulty[difficulty] = raid.difficulty[difficulty]
		end

		-- Only add the filtered raid if it contains the specified difficulty
		if next(filteredRaid.difficulty) ~= nil then
			table.insert(filteredRaids, filteredRaid)
		end
	end
	if filteredRaids then
		table.sort(filteredRaids, function(left, right)
			if left.instanceID ~= right.instanceID then
				return left.instanceID < right.instanceID
			end
		end)
	end

	return filteredRaids
end

function AMT:Filter_LockedBosses(seasonalRaids, difficulty)
	local filteredLockouts = {}
	for _, raid in ipairs(seasonalRaids) do
		-- for i = 1, #seasonalRaids do
		-- Check if the specified difficulty exists in the raid
		if raid.difficulty[difficulty].reset > 0 then
			for _, lockout in ipairs(raid.difficulty[difficulty].lockout) do
				if lockout.killed == true then
					-- print(lockout.bossName)
					-- local bossName = raid.difficulty[difficulty].lockout[1].bossName
					tinsert(filteredLockouts, lockout.bossName)
				end
			end
			-- local lockout = raid.difficulty[difficulty].lockout
			-- Copy the lockout details if it exists
		end
		-- end
	end

	return filteredLockouts
end

function AMT:Check_BossLockout(table, bossName)
	for _, tblBossName in ipairs(table) do
		local tableName = tblBossName or ""
		if string.lower(tableName) == string.lower(bossName) then
			return true
		end
	end
	return false
end

-- Check if we're in a mythic plus key
function AMT:ChallengeModeCheck()
	local _, _, difficulty, _, _, _, _, currentZoneID = GetInstanceInfo()

	self:PrintDebug("Checking for challenge mode, difficulty: " .. difficulty .. ", Zone ID: " .. currentZoneID)

	local inChallenge = difficulty == 8 and C_ChallengeMode.GetActiveChallengeMapID() ~= nil

	if inChallenge then
		return true
	else
		return false
	end
end
