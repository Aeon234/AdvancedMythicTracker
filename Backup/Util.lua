local addonName, AMT = ...

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

function AMT:GetNextAffixRotation(CurrentWeek_AffixTable, AffixRotation)
	if #self.CurrentWeek_AffixTable == 0 then
		return nil -- No affixes in CurrentWeek_AffixTable
	end

	local currentRotation = CurrentWeek_AffixTable[1]
	local nextRotationIndex = nil

	-- Find the index of the current rotation in AffixRotation
	for i, rotationInfo in ipairs(AffixRotation) do
		if AMT:CompareArrays(rotationInfo.rotation, currentRotation) then
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

function AMT:AMT_Update_PlayerMplus_Score()
	AMT.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	AMT.Player_Mplus_ScoreColor =
		C_ChallengeMode.GetDungeonScoreRarityColor(AMT.Player_Mplus_Summary.currentSeasonScore)
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

function AMT:Update_PlayerDungeonInfo()
	--Reset the state of the tables - need to check if it's actually resetting the values
	self.KeysDone = {}
	self.BestKeys_per_Dungeon = {}
	self.Current_SeasonalDung_Info = {}
	self.RunHistory = {}
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
		for _, dungeon in ipairs(self.DungeonAbbr) do
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

function AMT:AMT_UpdateMythicGraph()
	local dungLines = {}
	for i = 1, #self.BestKeys_per_Dungeon do
		local graphlabel = _G["GraphDung_Label" .. i]
		local dungeonLine = _G["Dung_AntTrail" .. i]
		if not dungeonLine then
			dungLines[i] = MythicRunsGraph_Container:CreateFontString("Dung_AntTrail" .. i, "ARTWORK", "GameFontNormal")
		else
			dungLines[i] = dungeonLine
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
end
