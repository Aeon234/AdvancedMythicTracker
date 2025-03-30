local addonName, AMT = ...

local ElvUI = ElvUI
local Details = Details
local RaiderIO = RaiderIO

-- =========================
-- === Set Slash Command ===
-- =========================
function AMT_DebugCommands(msg)
	if msg == "debug" then
		AMT.db.DebugMode = not AMT.db.DebugMode
		if AMT.db.DebugMode then
			AMT:PrintDebug("|cff19ff19Activated|r")
		else
			print("|cff18a8ffAMT|r Debug Mode: |c3fff2114Disabled|r")
		end
	elseif msg == "wm" and not InCombatLockdown() then
		AMT:WorldMarkerCycler_ToggleConfig()
	elseif AMT.db.DebugMode and msg:match("^add") then
		local command, dungeon, keylevel = msg:match("^(%S*)%s*(%S*)%s*(%S*)$")
		if command == "add" then
			if dungeon and keylevel then
				-- Update the highest key for the specified dungeon
				AMT:UpdateHighestKey(dungeon, keylevel)
			else
				print("Usage: /amt add <dungeon_abbr> <key_level>")
			end
		end
	else
		-- Settings.OpenToCategory(AMT_SettingsID)
	end
end
SLASH_AMT1 = "/amt"
SlashCmdList["AMT"] = AMT_DebugCommands

-- ======================
-- === Window Refresh ===
-- ======================

function AMT:LoadAPITables()
	--Current Season Info
	if not self.Info.CurrentSeason then
		self.Info.CurrentSeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	end
	--Vault Requirements
	if not self.DungeonReq or not self.RaidReq then
		self:GET_VaultRequirements()
	end
	--Mythic+ Rating Summary
	if not self.Info.MplusSummary then
		self.Info.MplusSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
		if self.Info.MplusSummary then
			self:Score_Update()
		end
	end
	--Weekly M+ Runs
	if not self.Info.SeasonDungeons or #self.Info.SeasonDungeons < 1 then
		self:GET_SeasonalDungeonInfo()
	end
	--Affixes
	if not self.Info.Affix or not self.Info.Affix.Current or #self.Info.Affix.Current < 1 then
		self:GET_AffixInformation()
	end
	--Raid
	if not self.Info.savedInstances then
		self:GET_RaidInfo()
	end
	--Crests
	if not self.Crests[4].CurrentAmount then
		self:GET_Crests()
	end

	if
		self.Info.CurrentSeason
		and self.DungeonReq
		and self.RaidReq
		and self.Info.MplusSummary
		and self.Info.SeasonDungeons
		and #self.Info.SeasonDungeons > 0
		and self.Info.Affix
		and #self.Info.Affix.Current > 0
		and self.Info.savedInstances
		and self.Crests[4].CurrentAmount
	then
		self:PrintDebug("API Tables Loaded.")
		self:Initialize()
	else
		self:PrintDebug("Restarting attempt to load API Tables.")
		C_Timer.After(2, function()
			self:LoadAPITables()
		end)
	end
end

function AMT:RefreshData()
	self.Info.CurrentSeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	self.Info.MplusSummary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
	self:GET_VaultRequirements()
	self:Score_Update()

	--Manually refresh Party Keystones
	if not IsInRaid() then
		self.OpenRaidLib.RequestKeystoneDataFromParty()
		C_Timer.After(0.5, function()
			AMT:PartyKeystone_Refresh()
		end)
		C_Timer.After(2, function()
			AMT:PartyKeystone_Refresh()
		end)
	end
	--

	self:GET_AffixInformation()
	self:Keystone_Update()
	self:GET_SeasonalDungeonInfo()
	self:GET_RaidInfo()
	self:GET_Crests()
	self:Graph_Update()
end

-- ================================
-- === Refresh Individual Items ===
-- ================================
function AMT:GET_VaultRequirements()
	local Mplus_VaultReqs = C_WeeklyRewards.GetActivities(1)
	local Raid_VaultReqs = C_WeeklyRewards.GetActivities(3)

	self.MplusUnlocks, self.RaidUnlocks = {}, {}
	for i = 1, #Mplus_VaultReqs do
		tinsert(self.MplusUnlocks, Mplus_VaultReqs[i].threshold)
	end
	for i = 1, #Raid_VaultReqs do
		tinsert(self.RaidUnlocks, Raid_VaultReqs[i].threshold)
	end
	if #self.MplusUnlocks == 0 or #self.RaidUnlocks == 0 then
		return
	end

	self.DungeonReq = math.max(unpack(self.MplusUnlocks))
	self.RaidReq = math.max(unpack(self.RaidUnlocks))
end

function AMT:Score_Update()
	local color = C_ChallengeMode.GetDungeonScoreRarityColor(self.Info.MplusSummary.currentSeasonScore or 1)
	if self.Initialized then
		self.Window.MplusScore.score:SetText(self.Info.MplusSummary.currentSeasonScore)
		self.Window.MplusScore.score:SetTextColor(color.r or 1, color.g or 1, color.b or 1, 1.0)
	end
end

function AMT:Keystone_Update()
	local weekly_modifier = {}
	local keystone_ID, keystone_name, keystone_icontex, keystone_level, keystone_abbr, keystone_dungname, keystone_mod, vaultReward, dungeonReward
	local keystone_mod_tt, keystone_info_tt, keystone_dungeonmodifiers_tt, keystone_rewards_tt, noKeystone_tt
	local rio_total_tt, rio_1R, rio_2R, rio_3R, rio_4R, rio_5R
	local rio_title_tt = "|cffffffffTimed Runs:"
	local rio_1L = "   • For +12 and up "
	local rio_2L = "   • For +10 - 11 "
	local rio_3L = "   • For +7 - 9 "
	local rio_4L = "   • For +4 - 6 "
	local rio_5L = "   • For +2 - 3 "
	if C_MythicPlus.GetOwnedKeystoneLevel() then
		keystone_ID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
		keystone_name, _, _, keystone_icontex = C_ChallengeMode.GetMapUIInfo(keystone_ID)
		keystone_abbr = AMT:GetAbbrFromChallengeModeID(keystone_ID)
		keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
		vaultReward, dungeonReward = self:AMT_GetKeystoneRewards(keystone_level)

		self.Window.Keystone.name:SetText("+" .. keystone_level .. " " .. keystone_abbr)
		self.Window.Keystone.icon:SetSize(62, 62)
		self.Window.Keystone.icon.tex:SetTexture(keystone_icontex)
		self.Window.Keystone.icon.tex:SetDesaturated(false)
		self.Window.Keystone.icon.glow.tex:SetAtlas("BattleBar-Button-Highlight")
		-- Tooltip
		keystone_mod = C_ChallengeMode.GetPowerLevelDamageHealthMod(keystone_level)
		--Get current affixes and assign the appropriate modifiers for Tyr/Fort.
		local affix = self.Info.Affix.Current
		if affix and keystone_level >= 12 then
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
	else
		--If Great Vault Rewards are uncollected create the
		if C_WeeklyRewards.HasAvailableRewards() then
			self.Window.Keystone.name:SetText("Pending Vault")
			noKeystone_tt = "Visit the Great Vault to collect your reward!"
			self.Window.Keystone.icon:SetSize(64, 64)
			self.Window.Keystone.icon.tex:SetAtlas("CovenantChoice-Celebration-Content-Soulbind")
			self.Window.Keystone.icon.tex:SetDesaturated(false)
		else
			--If a Keystone level is not detected
			self.Window.Keystone.name:SetText("No Key")
			noKeystone_tt = "Get your Keystone by"
				.. "\n|cffffffff"
				.. " • Completing any Dungeon on Mythic or Mythic Plus Difficulty"
				.. "\n"
				.. " • Speaking with Lindormi in Valdrakken"
			self.Window.Keystone.icon.tex:SetTexture(self.Keystone_Icon)
			self.Window.Keystone.icon:SetSize(60, 60)
			self.Window.Keystone.icon.glow.tex:SetAtlas("BattleBar-Button-Highlight")
		end
	end

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
	self.Window.Keystone.icon:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

		if not C_MythicPlus.GetOwnedKeystoneLevel() then
			GameTooltip:AddLine(noKeystone_tt)
		else
			GameTooltip:AddLine(keystone_info_tt)
			GameTooltip:AddLine(keystone_dungeonmodifiers_tt)
			GameTooltip:AddLine("|cffffffffRewards:|r")
			GameTooltip:AddDoubleLine("End of Dungeon:", "|cffffffff" .. dungeonReward .. "|r ")
			GameTooltip:AddDoubleLine("Great Vault:", "|cffffffff" .. vaultReward .. "|r ")
			GameTooltip:AddLine("|r\n\n")
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
	self.Window.Keystone.icon:SetScript("OnLeave", function()
		GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	end)
end

function AMT:GetRaids()
	local seasonID = C_MythicPlus.GetCurrentSeason()
	local raids = AMT:TableFilter(self.Raids, function(dataRaid)
		return dataRaid.seasonID == seasonID
	end)

	table.sort(raids, function(a, b)
		return a.order < b.order
	end)

	return raids
end

function AMT:GET_RaidInfo()
	self.Info.RaidBosses_Vault = C_WeeklyRewards.GetActivityEncounterInfo(3, 1)
	if self.Info.RaidBosses_Vault then
		table.sort(self.Info.RaidBosses_Vault, function(left, right)
			if left.instanceID ~= right.instanceID then
				return left.instanceID < right.instanceID
			end
			return left.uiOrder < right.uiOrder
		end)
	else
		return
	end
	if not self.Info.SeasonRaids then
		self.Info.SeasonRaids = {}
	else
		wipe(self.Info.SeasonRaids)
	end
	--Reset Weekly_KillCount table
	for i = 1, #self.Weekly_KillCount do
		self.Weekly_KillCount[i].kills = 0
	end

	for i = 1, #self.Info.RaidBosses_Vault do
		local journalInstanceID = self.Info.RaidBosses_Vault[i].instanceID
		local instanceID = self.Info.RaidBosses_Vault[i].encounterID
		if not AMT:Exists_in_Table(self.Info.SeasonRaids, journalInstanceID) then
			local name = EJ_GetInstanceInfo(journalInstanceID)
			tinsert(self.Info.SeasonRaids, {
				name = name,
				journalInstanceID = journalInstanceID,
				instanceID = instanceID,
				numEncounters = 0,
				difficulty = {
					LFR = { index = 0, reset = 0, lockout = {} },
					N = { index = 0, reset = 0, lockout = {} },
					H = { index = 0, reset = 0, lockout = {} },
					M = { index = 0, reset = 0, lockout = {} },
				},
			})
		end
	end

	self.Info.savedInstances = {}

	local numSavedInstances = GetNumSavedInstances()
	if numSavedInstances == 0 then
		return
	end
	for savedInstanceIndex = 1, numSavedInstances do
		local name, lockoutId, reset, difficultyID, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID =
			GetSavedInstanceInfo(savedInstanceIndex)
		if reset and reset > 0 then
			reset = reset + time()
		end
		for _, raid in ipairs(self.Info.SeasonRaids) do
			if string.lower(raid.name) == string.lower(name) then
				raid.numEncounters = numEncounters
				for difficultyKey, difficulty in pairs(raid.difficulty) do
					for _, diffData in ipairs(self.RaidDifficulty_Levels) do
						if diffData.abbr == difficultyKey and diffData.id == difficultyID then
							difficulty.index = savedInstanceIndex
							difficulty.reset = reset
						end
					end
				end
			else
				break
			end
		end
	end
	AMTTEST3 = self.Info.SeasonRaids

	for _, raid in ipairs(self.Info.SeasonRaids) do
		for difficultyKey, difficulty in pairs(raid.difficulty) do
			if difficulty.reset > 0 then
				for _, difficultylevels in ipairs(self.RaidDifficulty_Levels) do
					if difficultylevels.abbr == difficultyKey then
						for i = 1, raid.numEncounters do
							local bossName, fileDataID, isKilled = GetSavedInstanceEncounterInfo(difficulty.index, i)
							local instanceEncounterID = 0
							tinsert(difficulty.lockout, {
								index = i,
								instanceEncounterID = instanceEncounterID,
								bossName = bossName,
								fileDataID = fileDataID or 0,
								killed = isKilled,
							})
							if isKilled then
								for _, category in ipairs(self.Weekly_KillCount) do
									if category.name == difficultylevels.name then
										category.kills = category.kills + 1
									end
								end
							end
						end
					end
				end
			end
		end
	end

	--Color raid boxes
	if self.Initialized then
		local PrevKills = 0
		local VaultUnlock_CurrentMax = 0 --store highest # of bosses killed in all prev. analyzed difficulties
		local LastReward_Unlocked = false
		for i = 1, #self.Weekly_KillCount do
			local RaidBosses_Killed
			if self.Weekly_KillCount[i].kills <= self.RaidReq then
				RaidBosses_Killed = self.Weekly_KillCount[i].kills
			elseif self.Weekly_KillCount[i].kills > self.RaidReq then
				RaidBosses_Killed = self.RaidReq
			end
			local difficulty = self.Weekly_KillCount[i].abbr
			for j = 1, RaidBosses_Killed do
				if
					(j == self.RaidUnlocks[3] and RaidBosses_Killed == self.RaidUnlocks[3]) and not LastReward_Unlocked
				then
					self.Window.Weekly.Raid[i].frame.box[j].tex:SetColorTexture(1, 0.784, 0.047, 1.0) -- Gold
					LastReward_Unlocked = true
				elseif
					(
						(j == self.RaidUnlocks[1] and VaultUnlock_CurrentMax < self.RaidUnlocks[1])
						or (j == self.RaidUnlocks[2] and VaultUnlock_CurrentMax < self.RaidUnlocks[2])
					) and not LastReward_Unlocked
				then
					self.Window.Weekly.Raid[i].frame.box[j].tex:SetColorTexture(1, 0.784, 0.047, 1.0) -- Gold
				else
					self.Window.Weekly.Raid[i].frame.box[j].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0) -- Green
				end
			end
			if RaidBosses_Killed > PrevKills then
				VaultUnlock_CurrentMax = RaidBosses_Killed
			end
			PrevKills = RaidBosses_Killed
		end
	end
end

function AMT:Filter_LockedBosses(seasonalRaids, difficulty)
	local filteredLockouts = {}
	for _, raid in ipairs(seasonalRaids) do
		if raid.difficulty[difficulty].reset > 0 then
			for _, lockout in ipairs(raid.difficulty[difficulty].lockout) do
				if lockout.killed == true then
					tinsert(filteredLockouts, lockout.bossName)
				end
			end
		end
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

function AMT:GET_SeasonalDungeonInfo()
	self:PrintDebug("Getting Seasonal Dungeon Info.")
	self.Info.SeasonDungeons = {}
	self.Info.SeasonalBest = {}
	self.Info.RunHistory = {}
	self.Info.KeysDone = {}

	--Get Weekly M+ Runs History
	self.Info.RunHistory = C_MythicPlus.GetRunHistory(false, true)
	for i = 1, #self.Info.RunHistory do
		local KeyLevel = self.Info.RunHistory[i].level
		local KeyID = self.Info.RunHistory[i].mapChallengeModeID
		tinsert(self.Info.KeysDone, { level = KeyLevel, keyid = KeyID, keyname = "" })
	end

	--Sort Keys Done
	if self.Info.KeysDone[1] == nil then
		self.Info.KeysDone = { 0 }
	else
		table.sort(self.Info.KeysDone, function(a, b)
			return b.level < a.level
		end)
		for _, entry in ipairs(self.Info.KeysDone) do
			for _, dungeon in ipairs(self.SeasonalDungeons) do
				if entry.keyid == dungeon.mapID then
					entry.keyname = dungeon.name
					break -- Once found, no need to continue searching
				end
			end
		end
	end

	--Get Current Dungeons
	local currentSeasonMap = C_ChallengeMode.GetMapTable()
	for i = 1, #currentSeasonMap do
		local dungeonID = currentSeasonMap[i]
		local name, _, _, icon = C_ChallengeMode.GetMapUIInfo(dungeonID)
		local intimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(dungeonID)
		local dungeonScore
		local dungeonLevel
		local dungeonInfo = (overtimeInfo and (not intimeInfo or overtimeInfo.dungeonScore > intimeInfo.dungeonScore))
				and overtimeInfo
			or intimeInfo

		if dungeonInfo then
			dungeonLevel = dungeonInfo.level
			dungeonScore = dungeonInfo.dungeonScore
		else
			dungeonLevel = 0
			dungeonScore = 0
		end
		tinsert(self.Info.SeasonDungeons, {
			mapID = dungeonID,
			dungName = name,
			dungIcon = icon,
			intimeInfo = intimeInfo,
			overtimeInfo = overtimeInfo,
			dungeonLevel = dungeonLevel,
			dungeonScore = dungeonScore,
		})
		local dungAbbr = ""
		for _, dungeon in ipairs(self.SeasonalDungeons) do
			if dungeonID == dungeon.mapID then
				dungAbbr = dungeon.abbr
				tinsert(self.Info.SeasonalBest, {
					mapID = dungeon.mapID,
					dungAbbr = dungAbbr,
					HighestKey = 0,
					DungBullets = "",
				})
			end
		end
	end
	--Update self.Info.SeasonalBest with the Highest Keys done per dungeon
	for _, bestKey in ipairs(self.Info.SeasonalBest) do
		local highestKey = 0
		if #self.Info.KeysDone > 0 and self.Info.KeysDone[1] ~= 0 then
			for _, key in ipairs(self.Info.KeysDone) do
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

	if self.Initialized then
		--Update Dungeon Icon colors
		for i = 1, #self.Info.SeasonDungeons do
			local Dung_Score = self.Info.SeasonDungeons[i].dungeonScore
			local Dung_Level = self.Info.SeasonDungeons[i].dungeonLevel

			self.Window.Dungeons.Icon[i].level:SetText(Dung_Level)
			self.Window.Dungeons.Icon[i].score:SetText(Dung_Score)

			local DungScore_Color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(Dung_Score)
			self.Window.Dungeons.Icon[i].level:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)
			self.Window.Dungeons.Icon[i].score:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)
		end

		--Update M+ Box colors
		local WeeklyKeysHistory = {}
		for i = 1, self.DungeonReq do
			if i <= #self.Info.KeysDone and #self.Info.RunHistory > 0 then
				tinsert(WeeklyKeysHistory, self.Info.KeysDone[i].level)
			else
				break
			end

			if WeeklyKeysHistory[i] ~= nil and WeeklyKeysHistory[i] > 0 then
				if i == self.MplusUnlocks[1] or i == self.MplusUnlocks[2] or i == self.MplusUnlocks[3] then
					self.Window.Weekly.Mplus.box[i].tex:SetColorTexture(1, 0.784, 0.047, 1.0)
				else
					self.Window.Weekly.Mplus.box[i].tex:SetColorTexture(0.525, 0.69, 0.286, 1.0)
				end
			end
		end
	end
end

function AMT:GET_AffixInformation()
	self:PrintDebug("Getting Affix Info.")
	self.Info.Affix = self.Info.Affix or {}
	self.Info.Affix.Table = {}
	self.Info.Affix.Current = {}
	self.Info.Affix.Next = {}

	local CurrentRotation, NextRotationIndex
	self.Info.Affix.Table = C_MythicPlus.GetCurrentAffixes() or {}

	--Extract current affix set
	if (not self.Info.Affix.Current or #self.Info.Affix.Current == 0) and #self.Info.Affix.Table ~= 0 then
		-- table.insert(self.Info.Affix.Current, {
		-- self.Info.Affix.Table[1].id,
		-- self.Info.Affix.Table[2].id,
		-- self.Info.Affix.Table[3].id,
		-- self.Info.Affix.Table[4].id,
		-- })
		self.Info.Affix.Current = {
			self.Info.Affix.Table[1].id,
			self.Info.Affix.Table[2].id,
			self.Info.Affix.Table[3].id,
			self.Info.Affix.Table[4].id,
		}
		-- CurrentRotation = self.Info.Affix.Current[1]
	end
	--Find next affix set
	if self.Info.Affix.Current then
		for i, rotationInfo in ipairs(self.AffixRotation) do
			if AMT:CompareArrays(rotationInfo.rotation, self.Info.Affix.Current) then
				NextRotationIndex = i + 1
				break
			end
		end
	end

	if NextRotationIndex then
		NextRotationIndex = NextRotationIndex > #self.AffixRotation and 1 or NextRotationIndex
		self.Info.Affix.Next = { self.AffixRotation[NextRotationIndex].rotation }
		return
	end

	return nil --Current rotation not found
end

function AMT:GET_Crests()
	for i = 1, #self.Crests do
		local name = self.Crests[i].name
		local CurrencyInfo = C_CurrencyInfo.GetCurrencyInfo(self.Crests[i].currencyID)
		if not CurrencyInfo then
			break
		end
		self.Crests[i].CurrencyDescription = CurrencyInfo.description
		self.Crests[i].CurrentAmount = CurrencyInfo.quantity or 0
		self.Crests[i].CurrencyTotalEarned = CurrencyInfo.totalEarned
		if CurrencyInfo.maxQuantity ~= 0 then
			self.Crests[i].CurrencyCapacity = CurrencyInfo.maxQuantity
		else
			self.Crests[i].CurrencyTotalEarned = self.Crests[i].CurrentAmount
			self.Crests[i].CurrencyCapacity = 1000
		end
		self.Crests[i].NumOfRunsNeeded =
			math.max(0, math.ceil((self.Crests[i].CurrencyCapacity - self.Crests[i].CurrencyTotalEarned) / 12))
		if self.Window and self.Window.Crests.bar[i] then
			self.Window.Crests.bar[i]:SetSmoothFill(true)
			self.Window.Crests.bar[i]:SetValue(self.Crests[i].CurrencyTotalEarned, self.Crests[i].CurrencyCapacity)
		end
	end
end

function AMT:Graph_Update()
	for i = 1, #self.Info.SeasonalBest do
		if not self.Window.Graph.dungeons[i].line then
			self.Window.Graph.dungeons[i].line =
				self.Window.Graph:CreateFontString("Dung_AntTrail" .. i, "ARTWORK", "GameFontNormal")
			self.Window.Graph.dungeons[i].line:SetFont(self.AntTrail_Font, 14)
		end

		--If the key actually exists/was done, set the ant trail
		if self.Info.SeasonalBest[i].HighestKey and self.Info.SeasonalBest[i].HighestKey > 0 then
			self.Window.Graph.dungeons[i].line:SetPoint("LEFT", self.Window.Graph.dungeons[i].label, "RIGHT", 6, -1)
			self.Window.Graph.dungeons[i].line:SetText(
				self.Info.SeasonalBest[i].DungBullets .. self.Info.SeasonalBest[i].HighestKey
			)
			--If highest key done is same as the current weekly best color the line gold
			if self.Info.SeasonalBest[i].HighestKey == self.Info.KeysDone[1].level then
				self.Window.Graph.dungeons[i].line:SetTextColor(1.000, 0.824, 0.000, 1.000)
			else
				--Otherwise color it white
				self.Window.Graph.dungeons[i].line:SetTextColor(1, 1, 1, 1.0)
			end
		end
	end
end

-- ======================
-- === PVE Frame Tabs ===
-- ======================

function AMT:PVEFrameTabNums()
	self:PrintDebug("Checking PVEFrame Tab Numbers.")
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]

		if not PVEFrame_Tab:IsVisible() then
			self.Info.TabNum = i - 1
			break
		else
			self.Info.TabNum = PVEFrame.numTabs
		end
	end

	if
		C_MythicPlus.IsMythicPlusActive()
		and UnitLevel("player") >= GetMaxLevelForPlayerExpansion()
		and not PlayerGetTimerunningSeasonID()
	then
		self.TabButton:Enable()
	else
		self.TabButton:Disable()
		self.TabButton:SetText("|cff808080Mythic Tracker")
	end
	self:PrintDebug("PVEFrame Tab Number: " .. self.Info.TabNum)
end

function AMT:Update_PVEFrame_Panels()
	local VisiblePanels = {}
	for i = 1, #self.PVEFrame_Panels do
		if
			self.PVEFrame_Panels[i].text == "Mythic+ Dungeons"
			or self.PVEFrame_Panels[i].text == "Advanced Mythic Tracker"
		then
			self.PVEFrame_Panels[i].isVisible = true
		end
		if self.PVEFrame_Panels[i].isVisible then
			tinsert(VisiblePanels, {
				text = self.PVEFrame_Panels[i].text,
				frameName = self.PVEFrame_Panels[i].frameName,
				isVisible = self.PVEFrame_Panels[i].isVisible,
			})
		end
	end

	local AMT_Window_TabButton
	if not _G["AMT_Window_Tab" .. #VisiblePanels] then
		for i = 1, #VisiblePanels do
			if self.PVEFrame_Panels[i].isVisible then
				AMT_Window_TabButton =
					CreateFrame("Button", "AMT_Window_Tab" .. i, self.Window, "PanelTabButtonTemplate")
				AMT_Window_TabButton:SetText(VisiblePanels[i].text)
				AMT_Window_TabButton:SetFrameStrata("HIGH")
				local tabButton = _G["AMT_Window_Tab" .. i]
				tabButton:SetScript("OnClick", function()
					PVEFrame_ToggleFrame(VisiblePanels[i].frameName)
				end)
				-- Set placement of the tabs
				if ElvUI then
					self.S:HandleTab(AMT_Window_TabButton)
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", self.Window, "BOTTOMLEFT", -3, 0)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", -5, 0)
					end
				else
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", self.Window, "BOTTOMLEFT", 19, 2)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", 3, 0)
					end
				end
			end
		end
	end
	-- Set the proper sizes for each tab button and make AMT tab active
	for i = 1, #VisiblePanels do
		local AMTTab = _G["AMT_Window_Tab" .. i]
		local sideWidths = AMTTab.Left:GetWidth() + AMTTab.Right:GetWidth()
		local minWidth = minWidth or sideWidths

		PanelTemplates_TabResize(AMTTab, 0, nil, minWidth)

		if i == #self.PVEFrame_Panels then
			PanelTemplates_SelectTab(_G["AMT_Window_Tab" .. #self.PVEFrame_Panels])
		else
			PanelTemplates_DeselectTab(_G["AMT_Window_Tab" .. i])
		end
	end
end

-- =================================
-- === Party Keystones Functions ===
-- =================================
function AMT:PartyKeystone_Refresh()
	local Keyname_abbr

	self.Window.PartyKeys.Group = {}

	if Details and not UnitInRaid("player") then
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
						tinsert(self.Window.PartyKeys.Group, {
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
		if #self.Window.PartyKeys.Group > 1 then
			table.sort(self.Window.PartyKeys.Group, function(a, b)
				return b.level < a.level
			end)
		end

		--Set Text
		for i = 1, 5 do
			local left_text = self.Window.PartyKeys.lines[i].left
			local right_text = self.Window.PartyKeys.lines[i].right
			if self.Window.PartyKeys.Group[i] then
				right_text:SetText(self.Window.PartyKeys.Group[i].player)
				left_text:SetText(
					format(
						"|T%s:16:16:0:0:64:64:4:60:7:57:255:255:255|t |c%s%s - %s|r",
						self.Window.PartyKeys.Group[i].icon,
						AMT_getKeystoneLevelColor(self.Window.PartyKeys.Group[i].level),
						self.Window.PartyKeys.Group[i].level,
						self.Window.PartyKeys.Group[i].name
					)
				)
			else
				right_text:SetText("")
				left_text:SetText("")
			end
		end
	end
end

function AMT:PartyKeystone_RefreshRequest()
	if IsInGroup() and not IsInRaid() then
		self.OpenRaidLib.RequestKeystoneDataFromParty()
		C_Timer.After(0.5, function()
			AMT:PartyKeystone_Refresh()
		end)
		C_Timer.After(2, function()
			AMT:PartyKeystone_Refresh()
		end)
	else
		print("|cff18a8ffAMT|r: Must be in a group with multiple keystones to refresh")
	end
end

--Pick random keystone from the group and print out to group
function AMT:PartyKeystone_RandomPicker()
	local i = math.random(#self.Window.PartyKeys.Group)
	local playername = AMT_StripColorText(self.Window.PartyKeys.Group[i].player)
	local keyabbr = self.Window.PartyKeys.Group[i].name
	local keyname
	for _, dungeon in ipairs(self.SeasonalDungeons) do
		if dungeon.abbr == keyabbr then
			keyname = dungeon.name
			break
		end
	end
	local keylevel = self.Window.PartyKeys.Group[i].level
	local msg = "Next Key: " .. playername .. "'s " .. keyname .. " (" .. keylevel .. ")"
	if IsInGroup() and not IsInRaid() then
		SendChatMessage(msg, "PARTY")
	end
end

-- ================================
-- === Frame Creation Functions ===
-- ================================
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

function AMT_CreateHeader(parentFrame, name, point, relativeTo, relativePoint, x, y, width, height, text)
	local frame = CreateFrame("Frame", name, parentFrame)
	frame:SetSize(width, height)
	frame:SetPoint(point, relativeTo, relativePoint, x, y)

	local frame_label = frame:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	if text == "Mythic+" then
		frame_label:SetPoint("TOP", frame, "TOP", 0, -2)
	else
		frame_label:SetPoint("TOP", frame, "TOP", 0, 0)
	end
	frame_label:SetText(text)
	frame_label:SetFont(AMT.AMT_Font, 14)
	return frame
end

do --Easing
	local EasingFunctions = {}
	AMT.EasingFunctions = EasingFunctions

	local sin = math.sin
	local cos = math.cos
	local pow = math.pow
	local pi = math.pi

	--t: total time elapsed
	--b: beginning position
	--e: ending position
	--d: animation duration

	function EasingFunctions.linear(t, b, e, d)
		return (e - b) * t / d + b
	end

	function EasingFunctions.outSine(t, b, e, d)
		return (e - b) * sin(t / d * (pi / 2)) + b
	end

	function EasingFunctions.inOutSine(t, b, e, d)
		return -(e - b) / 2 * (cos(pi * t / d) - 1) + b
	end

	function EasingFunctions.outQuart(t, b, e, d)
		t = t / d - 1
		return (b - e) * (pow(t, 4) - 1) + b
	end

	function EasingFunctions.outQuint(t, b, e, d)
		t = t / d
		return (b - e) * (pow(1 - t, 5) - 1) + b
	end

	function EasingFunctions.inQuad(t, b, e, d)
		t = t / d
		return (e - b) * pow(t, 2) + b
	end
end

do --Metal Progress Bar
	local ProgressBarMixin = {}

	function ProgressBarMixin:SetBarWidth(width)
		self:SetWidth(width)
		self.maxBarFillWidth = width
	end

	function ProgressBarMixin:SetValueByRatio(ratio)
		self.BarFill:SetWidth(ratio * self.maxBarFillWidth)
		self.BarFill:SetTexCoord(0, ratio, self.barfillTop, self.barfillBottom)
		self.visualRatio = ratio
	end

	local FILL_SIZE_PER_SEC = 100
	local EasingFunc = AMT.EasingFunctions.outQuart

	local function SmoothFill_OnUpdate(self, elapsed)
		self.t = self.t + elapsed
		local ratio = EasingFunc(self.t, self.fromRatio, self.toRatio, self.easeDuration)
		if self.t >= self.easeDuration then
			ratio = self.toRatio
			self.easeDuration = nil
			self:SetScript("OnUpdate", nil)
		end
		self:SetValueByRatio(ratio)
	end

	function ProgressBarMixin:SetValue(barValue, barMax, playPulse)
		if barValue > barMax then
			barValue = barMax
		end
		if self.BarValue then
			self.BarValue:SetText(barValue .. "/" .. barMax)
		end
		if barValue == 0 or barMax == 0 then
			self.BarFill:Hide()
			self:SetScript("OnUpdate", nil)
		else
			self.BarFill:Show()
			local newRatio = barValue / barMax
			if self.smoothFill then
				local deltaRatio, oldRatio

				if self.barMax and self.visualRatio then
					if self.barMax == 0 then
						oldRatio = 0
					else
						oldRatio = self.visualRatio
					end
					deltaRatio = newRatio - oldRatio
				else
					oldRatio = 0
					deltaRatio = newRatio
				end

				if oldRatio < 0 then
					oldRatio = -oldRatio
				end

				if deltaRatio < 0 then
					deltaRatio = -deltaRatio
				end

				local easeDuration = deltaRatio * self.maxBarFillWidth / FILL_SIZE_PER_SEC

				if self.wasHidden then
					--don't animte if the bar was hidden
					self.wasHidden = false
					easeDuration = 0
				end
				if easeDuration > 0.25 then
					self.toRatio = newRatio
					self.fromRatio = oldRatio
					if easeDuration > 1.5 then
						easeDuration = 1.5
					end
					self.easeDuration = easeDuration
					self.t = 0
					self:SetScript("OnUpdate", SmoothFill_OnUpdate)
				else
					self.easeDuration = nil
					self:SetValueByRatio(newRatio)
					self:SetScript("OnUpdate", nil)
				end
			else
				self:SetValueByRatio(newRatio)
			end
		end

		if playPulse and barValue > self.barValue then
			self:Flash()
		end

		self.barValue = barValue
		self.barMax = barMax
	end

	function ProgressBarMixin:OnHide()
		self.wasHidden = true
	end

	function ProgressBarMixin:GetValue()
		return self.barValue
	end

	function ProgressBarMixin:GetBarMax()
		return self.barMax
	end

	function ProgressBarMixin:SetSmoothFill(state)
		state = state or false
		self.smoothFill = state
		if not state then
			self:SetScript("OnUpdate", nil)
			if self.barValue and self.barMax then
				self:SetValue(self.barValue, self.barMax)
			end
			self.easeDuration = nil
		end
	end

	function ProgressBarMixin:Flash()
		self.BarPulse.AnimPulse:Stop()
		self.BarPulse.AnimPulse:Play()
		if self.playShake then
			self.BarShake:Play()
		end
	end

	function ProgressBarMixin:SetBarColor(r, g, b)
		self.BarFill:SetVertexColor(r, g, b)
	end

	function ProgressBarMixin:SetBarColorTint(index)
		if index < 1 or index > 8 then
			index = 2
		end --White

		if index ~= self.colorTint then
			self.colorTint = index
		else
			return
		end

		self.BarFill:SetVertexColor(1, 1, 1)
		self.barfillTop = (index - 1) * 0.125
		self.barfillBottom = index * 0.125

		if self.barValue and self.barMax then
			self:SetValue(self.barValue, self.barMax)
		end
	end

	function ProgressBarMixin:GetBarColorTint()
		return self.colorTint
	end

	local function SetupNotchTexture_Normal(notch)
		notch:SetTexCoord(0.815, 0.875, 0, 0.375)
		notch:SetSize(16, 24)
	end

	local function SetupNotchTexture_Large(notch)
		notch:SetTexCoord(0.5625, 0.59375, 0, 0.25)
		notch:SetSize(16, 64)
	end

	function ProgressBarMixin:SetNumThreshold(numThreshold)
		--Divide the bar evenly
		--"partitionValues", in Blizzard's term
		if numThreshold == self.numThreshold then
			return
		end
		self.numThreshold = numThreshold

		if not self.notches then
			self.notches = {}
		end

		for _, n in ipairs(self.notches) do
			n:Hide()
		end

		if numThreshold == 0 then
			return
		end

		local d = self.maxBarFillWidth / (numThreshold + 1)
		for i = 1, numThreshold do
			if not self.notches[i] then
				self.notches[i] = self.Container:CreateTexture(nil, "OVERLAY", nil, 2)
				self.notches[i]:SetTexture(self.textureFile)
				self.SetupNotchTexture(self.notches[i])
				-- API.DisableSharpening(self.notches[i])
			end
			self.notches[i]:ClearAllPoints()
			self.notches[i]:SetPoint("CENTER", self.Container, "LEFT", i * d, 0)
			self.notches[i]:Show()
		end
	end

	local function CreateMetalProgressBar(parent, sizeType, name)
		sizeType = sizeType or "normal"

		local f = CreateFrame("Frame", name, parent)
		Mixin(f, ProgressBarMixin)

		f:SetScript("OnHide", ProgressBarMixin.OnHide)

		local Container = CreateFrame("Frame", nil, f) --Textures are attached to this frame, so we can setup animations
		f.Container = Container
		Container:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
		Container:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

		f.visualRatio = 0
		f.wasHidden = true

		f.BarFill = Container:CreateTexture(nil, "ARTWORK")
		f.BarFill:SetTexCoord(0, 1, 0, 0.125)
		f.BarFill:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/Frame/ProgressBar-Fill")
		f.BarFill:SetPoint("LEFT", Container, "LEFT", 0, 0)

		f.Background = Container:CreateTexture(nil, "BACKGROUND")
		f.Background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
		f.Background:SetPoint("TOPLEFT", Container, "TOPLEFT", 0, -2)
		f.Background:SetPoint("BOTTOMRIGHT", Container, "BOTTOMRIGHT", 0, 2)

		f.BarLeft = Container:CreateTexture(nil, "OVERLAY")
		f.BarLeft:SetPoint("CENTER", Container, "LEFT", 0, 0)

		f.BarRight = Container:CreateTexture(nil, "OVERLAY")
		f.BarRight:SetPoint("CENTER", Container, "RIGHT", 0, 0)

		f.BarMiddle = Container:CreateTexture(nil, "OVERLAY")
		f.BarMiddle:SetPoint("TOPLEFT", f.BarLeft, "TOPRIGHT", 0, 0)
		f.BarMiddle:SetPoint("BOTTOMRIGHT", f.BarRight, "BOTTOMLEFT", 0, 0)

		local file, barWidth, barHeight
		if sizeType == "normal" then
			file = "ProgressBar-Metal-Normal"
			barWidth, barHeight = 168, 18
			f.BarLeft:SetTexCoord(0, 0.09375, 0, 0.375)
			f.BarRight:SetTexCoord(0.65625, 0.75, 0, 0.375)
			f.BarMiddle:SetTexCoord(0.09375, 0.65625, 0, 0.375)
			f.BarLeft:SetSize(24, 24)
			f.BarRight:SetSize(24, 24)
			f.BarFill:SetSize(barWidth, 12)
			f.SetupNotchTexture = SetupNotchTexture_Normal
		elseif sizeType == "large" then
			file = "ProgressBar-Metal-Large"
			barWidth, barHeight = 248, 28 --32
			f.BarLeft:SetTexCoord(0, 0.0625, 0, 0.25)
			f.BarRight:SetTexCoord(0.46875, 0.53125, 0, 0.25)
			f.BarMiddle:SetTexCoord(0.0625, 0.46875, 0, 0.25)
			f.BarLeft:SetSize(32, 64)
			f.BarRight:SetSize(32, 64)
			f.BarFill:SetSize(barWidth, 20) --24
			f.SetupNotchTexture = SetupNotchTexture_Large
		end

		local barFile = "Interface/AddOns/AdvancedMythicTracker/Media/Frame/" .. file
		f.textureFile = barFile
		f.BarLeft:SetTexture(barFile)
		f.BarRight:SetTexture(barFile)
		f.BarMiddle:SetTexture(barFile)

		-- API.DisableSharpening(f.BarFill)
		-- API.DisableSharpening(f.BarLeft)
		-- API.DisableSharpening(f.BarRight)
		-- API.DisableSharpening(f.BarMiddle)

		f:SetBarWidth(barWidth)
		f:SetHeight(barHeight)
		f:SetBarColorTint(2)
		--f:SetNumThreshold(0);
		f:SetValue(0, 100)

		local BarPulse = CreateFrame("Frame", nil, f, "AMTBarPulseTemplate")
		BarPulse:SetPoint("RIGHT", f.BarFill, "RIGHT", 0, 0)
		f.BarPulse = BarPulse

		local BarShake = Container:CreateAnimationGroup()
		f.BarShake = BarShake
		local a1 = BarShake:CreateAnimation("Translation")
		a1:SetOrder(1)
		a1:SetStartDelay(0.15)
		a1:SetOffset(3, 0)
		a1:SetDuration(0.05)
		local a2 = BarShake:CreateAnimation("Translation")
		a2:SetOrder(2)
		a2:SetOffset(-4, 0)
		a2:SetDuration(0.1)
		local a3 = BarShake:CreateAnimation("Translation")
		a3:SetOrder(3)
		a3:SetOffset(1, 0)
		a3:SetDuration(0.1)

		return f
	end
	AMT.CreateMetalProgressBar = CreateMetalProgressBar
end

-- =========================
-- === Utility Functions ===
-- =========================
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

function AMT:TableFind(tbl, callback)
	assert(type(tbl) == "table", "Must be a table!")
	for i, v in ipairs(tbl) do
		if callback(v, i) then
			return v, i
		end
	end
	return nil, nil
end

function AMT:TableGet(tbl, key, val)
	assert(type(tbl) == "table", "Must be a table!")
	return self:TableFind(tbl, function(elm)
		return elm[key] and elm[key] == val
	end)
end

function AMT:TableFilter(tbl, callback)
	assert(type(tbl) == "table", "Must be a table!")
	local t = {}
	for i, v in pairs(tbl) do
		if callback(v, i) then
			table.insert(t, v)
		end
	end
	return t
end

function AMT:TableForEach(tbl, callback)
	assert(type(tbl) == "table", "Must be a table!")
	for ik, iv in pairs(tbl) do
		callback(iv, ik)
	end
	return tbl
end

function AMT:Exists_in_Table(table, instanceID)
	for _, raid in ipairs(table) do
		if raid.journalInstanceID == instanceID then
			return true
		end
	end
	return false
end

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

--Get Dungeon Abbreviations from MapIDs
function AMT:GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		if dungeon.mapID == id then
			return dungeon.abbr
		end
	end
	local keystone_name, _, _, _ = C_ChallengeMode.GetMapUIInfo(id)
	return keystone_name -- Return full name if no matching dungeon is found
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
			vaultReward = "(" .. level.VaultUpgradeTrack .. ") " .. level.GreatVault
			dungeonReward = "(" .. level.DungeonUpgradeTrack .. ") " .. level.EndofDungeon
			break
		end
	end
	return vaultReward, dungeonReward
end
