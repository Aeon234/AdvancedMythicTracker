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
