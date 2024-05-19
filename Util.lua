local addonName, AMT = ...
--Figure out how many tabs are being displayed for the character so that we can assign what number our new custom tab will be.
PVEFrame_Panels = {
	{
		text = "Dungeons & Raids",
		frameName = "GroupFinderFrame",
		isVisible = true,
	},
	{
		text = "Player vs. Player",
		frameName = "PVPUIFrame",
		isVisible = true,
	},
	{
		text = "Mythic+ Dungeons",
		frameName = "ChallengesFrame",
		isVisible = false,
	},
	{
		text = "Advanced Keystone Tracker",
		frameName = "AMT_Window",
		isVisible = false,
	},
}

function AMT.Check_PVEFrame_TabNums()
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

function GetNextAffixRotation(CurrentWeek_AffixTable, AffixRotation)
	if #CurrentWeek_AffixTable == 0 then
		return nil -- No affixes in CurrentWeek_AffixTable
	end

	local currentRotation = CurrentWeek_AffixTable[1]
	local nextRotationIndex = nil

	-- Find the index of the current rotation in AffixRotation
	for i, rotationInfo in ipairs(AffixRotation) do
		if CompareArrays(rotationInfo.rotation, currentRotation) then
			nextRotationIndex = i + 1
			break
		end
	end

	if nextRotationIndex then
		-- Wrap around if reached the end of AffixRotation
		nextRotationIndex = nextRotationIndex > #AffixRotation and 1 or nextRotationIndex
		local nextRotation = AffixRotation[nextRotationIndex].rotation

		-- Return the next rotation
		NextWeek_AffixTable = { nextRotation }
		return
	end

	return nil -- Current rotation not found in AffixRotation
end

-- Function to compare two arrays
function CompareArrays(arr1, arr2)
	if #arr1 ~= #arr2 then
		return false
	end
	for i = 1, #arr1 do
		if arr1[i] ~= arr2[i] then
			return false
		end
	end
	return true
end

function AMT:AMT_Update_PlayerMplus_Score()
	Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	Player_Mplus_ScoreColor = C_ChallengeMode.GetDungeonScoreRarityColor(Player_Mplus_Summary.currentSeasonScore)
end

function AMT:Find_Table(tbl, callback)
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			return v, i
		end
	end
	return nil, nil
end

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

function AMT_LoadTrackingData()
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

function AMT_RGBtoHexConversion(r, g, b, header, ending)
	r = r <= 1 and r >= 0 and r or 1
	g = g <= 1 and g >= 0 and g or 1
	b = b <= 1 and b >= 0 and b or 1
	return format("%s%02x%02x%02x%s", header or "|cff", r * 255, g * 255, b * 255, ending or "")
end

function AMT_ClassColorString(text, ClassName)
	local r, g, b = GetClassColor(ClassName)
	local hexcolor = r and g and b and AMT_RGBtoHexConversion(r, g, b) or "|cffffffff"
	return hexcolor .. text .. "|r"
end

function AMT_getKeystoneLevelColor(level)
	if level < 5 then
		return "ffffffff"
	elseif level < 10 then
		return "ff1eff00"
	elseif level < 15 then
		return "ff0070dd"
	elseif level < 20 then
		return "ffa335ee"
	else
		return "ffff8000"
	end
end

function AMT_Update_PlayerDungeonInfo()
	--Reset the state of the tables
	KeysDone = {}
	Current_SeasonalDung_Info = {}
	BestKeys_per_Dungeon = {}
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
		for _, dungeon in ipairs(DungeonAbbr) do
			if dungeonID == dungeon.mapID then
				dungAbbr = dungeon.Abbr
				tinsert(BestKeys_per_Dungeon, {
					mapID = dungeon.mapID,
					dungAbbr = dungAbbr,
					HighestKey = 0,
					DungBullets = "",
				})
			end
		end
	end

	--Update BestKeys_per_Dungeon with the Highest Keys done per dungeon
	local KeyBullets = ""
	local BulletTemplate = "• "
	for _, bestKey in ipairs(BestKeys_per_Dungeon) do
		local highestKey = 0
		for _, key in ipairs(KeysDone) do
			if key.keyid == bestKey.mapID and key.level > highestKey then
				highestKey = key.level
			end
		end
		bestKey.HighestKey = highestKey
		for i = 1, bestKey.HighestKey do
			KeyBullets = KeyBullets .. BulletTemplate
		end
		bestKey.DungBullets = KeyBullets
	end
end
