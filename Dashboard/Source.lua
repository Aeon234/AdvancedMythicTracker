local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard

local GCD_SECONDS = 2
local MILLISECONDS_PER_SECOND = 1000
local DURATION_MATCH_SECONDS = 1
local RECORD_MATCH_SECONDS = 900

local PARTY_UNITS = { "player", "party1", "party2", "party3", "party4" }
local TYRANNICAL_ID, FORTIFIED_ID = 9, 10
local TYRANNICAL_BOSS_HEALTH, TYRANNICAL_BOSS_DAMAGE = 0.25, 0.15
local FORTIFIED_MINION_HEALTH, FORTIFIED_MINION_DAMAGE = 0.20, 0.20

local RAIDER_IO_URL = "https://raider.io/characters/%s/%s/%s"
local RAIDER_IO_REGIONS = { [1] = "us", [2] = "kr", [3] = "eu", [4] = "tw" }

---@class AMTDashboardKeystoneModifiers
---@field bossHealth integer percent
---@field bossDamage integer percent
---@field minionHealth integer percent
---@field minionDamage integer percent

---@class AMTDashboardKeystone
---@field name string
---@field abbrev string
---@field texture number?
---@field level integer
---@field modifiers AMTDashboardKeystoneModifiers
---@field lootItemLevel number? nil for no info
---@field vaultItemLevel number? nil for no info

---@class AMTDashboardAffix
---@field name string
---@field description string
---@field texture number

---@class AMTDashboardHeader
---@field raiderIOURL string? nil where no Raider.IO page can be linked with confidence
---@field keystone AMTDashboardKeystone? nil when the character holds no key
---@field rating number
---@field weeklyBest AMTDashboardRunSummary? nil before a run this week
---@field seasonBest AMTDashboardRunSummary? nil before a run this season
---@field affixes AMTDashboardAffix[]
---@class AMTDashboardVaultMilestone
---@field index integer the slot, 1-3
---@field threshold integer runs that unlock this reward
---@field level integer the key level the slot is set at
---@field heroic boolean the slot is set by a Heroic run
---@field itemLevel number? nil until the reward item has loaded
---@field upgradeItemLevel number? nil when the slot is already at its highest item level
---@field nextLevel integer the key level that would raise the slot
---@field lowestLevel integer? the lowest of the top `threshold` runs; WeeklyRewardsUtil.HeroicLevel for Heroic

---@class AMTDashboardVaultRun
---@field level integer
---@field name string

---@class AMTDashboardVaultTrack
---@field progress integer runs the vault counts this week, Heroic and Mythic 0 included
---@field canClaim boolean last week's rewards can be claimed, which hides the reward preview
---@field milestones AMTDashboardVaultMilestone[] in threshold order
---@field topRuns AMTDashboardVaultRun[] this week's Mythic+ runs, highest first
---@field mythicRuns integer Mythic 0 runs counted by the vault
---@field heroicRuns integer Heroic and Timewalking runs counted by the vault
---@field rewardsWaiting boolean last week's rewards are unclaimed

---@class AMTDashboardPartyKey
---@field name string dungeon name
---@field abbrev string
---@field texture number?
---@field level integer

---@class AMTDashboardPartyDungeon
---@field name string
---@field level integer 0 when not run this season
---@field timed boolean
---@field upgrades integer 0-3

---@class AMTDashboardPartyMember
---@field name string a plain string, never secret: the panel sorts by it
---@field classFile string
---@field specIcon number? nil until the spec is known
---@field key AMTDashboardPartyKey? nil until the key is known
---@field rating number? nil when the client returned no rating summary
---@field dungeons AMTDashboardPartyDungeon[] every season dungeon, in no particular order

---@class AMTDashboardPartyRoster
---@field inGroup boolean
---@field members AMTDashboardPartyMember[] the player included, in no particular order

---@class AMTDashboardFastestRun
---@field level integer
---@field seconds number
---@field overTime boolean

---@class AMTDashboardSeasonDungeon
---@field mapID integer
---@field name string
---@field abbrev string
---@field texture number?
---@field score number 0 when not run this season
---@field level integer 0 when not run this season
---@field seconds number
---@field timed boolean
---@field fastest AMTDashboardFastestRun? the fastest season-best run, nil when not run
---@field teleportSpellID integer? nil when no teleport entry a given dungeon
---@field teleportName string the spell's name, or TELEPORT_TO_DUNGEON
---@field teleportKnown boolean
---@field teleportUnlockLevel integer

---@class AMTDashboardRunMember
---@field classFile string
---@field specIcon number?

---@class AMTDashboardRunSplit
---@field name string
---@field timeMS integer
---@field diffMS integer? nil without a personal best to compare against

---@class AMTDashboardRun
---@field mapID integer
---@field name string
---@field abbrev string
---@field texture number?
---@field level integer
---@field seconds number
---@field completed boolean false for a key the player left
---@field chests integer 0 = depleted
---@field score number score the run provided
---@field completedAt number
---@field party AMTDashboardRunMember[]? nil if AMT didn't record the run
---@field splits AMTDashboardRunSplit[]? boss splits, only for a run AMT recorded

---@class AMTDashboardSource
local Source = {}
Dashboard.Source = Source

---@param challengeMapID integer
---@param name string? the dungeon's name from GetMapUIInfo
---@return string
local function GetAbbreviation(challengeMapID, name)
	local abbr = AMT.Teleports.AbbreviationFor(challengeMapID)

	return abbr and L[abbr] or name or UNKNOWN
end

---@return AMTDashboardAffix[] affixes
---@return integer[] affixIDs in activation order
local function GetAffixes()
	local affixes, affixIDs = {}, {}
	local current = C_MythicPlus.GetCurrentAffixes()

	if not current then
		return affixes, affixIDs
	end

	for index, affix in ipairs(current) do
		local name, description, texture = C_ChallengeMode.GetAffixInfo(affix.id)

		affixes[index] = { name = name, description = description, texture = texture }
		affixIDs[index] = affix.id
	end

	return affixes, affixIDs
end

-- 0 is returned when no info available.
---@param itemLevel number
---@return number?
local function KnownItemLevel(itemLevel)
	if itemLevel > 0 then
		return itemLevel
	end
end

---@param base number percent, as GetPowerLevelDamageHealthMod returns it
---@param affix number fraction, 0 when the affix is not active on the key
---@return integer percent
local function CombineScaling(base, affix)
	return Round(((1 + base / 100) * (1 + affix) - 1) * 100)
end

---@param level integer
---@param affixIDs number[] this week's affixes, in activation order
---@param affixLevels integer[] the key level each position activates at
---@return AMTDashboardKeystoneModifiers
local function GetModifiers(level, affixIDs, affixLevels)
	local tyrannical, fortified = false, false

	for index = 1, math.min(#affixIDs, #affixLevels) do
		if affixLevels[index] <= level then
			tyrannical = tyrannical or affixIDs[index] == TYRANNICAL_ID
			fortified = fortified or affixIDs[index] == FORTIFIED_ID
		end
	end

	local damage, health = C_ChallengeMode.GetPowerLevelDamageHealthMod(level)

	return {
		bossHealth = CombineScaling(health, tyrannical and TYRANNICAL_BOSS_HEALTH or 0),
		bossDamage = CombineScaling(damage, tyrannical and TYRANNICAL_BOSS_DAMAGE or 0),
		minionHealth = CombineScaling(health, fortified and FORTIFIED_MINION_HEALTH or 0),
		minionDamage = CombineScaling(damage, fortified and FORTIFIED_MINION_DAMAGE or 0),
	}
end

---@param affixIDs integer[] this week's affixes, in activation order
---@return AMTDashboardKeystone?
local function GetKeystone(affixIDs)
	local challengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local level = C_MythicPlus.GetOwnedKeystoneLevel()

	if not challengeMapID or not level then
		return nil
	end

	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(challengeMapID)
	local vaultItemLevel, lootItemLevel = C_MythicPlus.GetRewardLevelForDifficultyLevel(level)

	return {
		name = name or UNKNOWN,
		abbrev = GetAbbreviation(challengeMapID, name),
		texture = texture,
		level = level,
		modifiers = GetModifiers(level, affixIDs, AMT.Season.affixLevels),
		lootItemLevel = KnownItemLevel(lootItemLevel),
		vaultItemLevel = KnownItemLevel(vaultItemLevel),
	}
end

---@return number seconds to add to a UTC date read by time()
local function LocalReadOffset()
	local now = time()
	local utc = date("!*t", now) --[[@as osdate]]

	return now
		- time({ year = utc.year, month = utc.month, day = utc.day, hour = utc.hour, min = utc.min, sec = utc.sec })
end

-- Run dates are UTC, not the machine's zone and not realm time.
---@param completionDate CalendarTime
---@return number epoch seconds
local function CompletedAt(completionDate)
	return time({
		year = completionDate.year,
		month = completionDate.month,
		day = completionDate.monthDay,
		hour = completionDate.hour,
		min = completionDate.minute,
	}) + LocalReadOffset()
end

---@param left AMTDashboardRun
---@param right AMTDashboardRun
---@return boolean
local function ByRecency(left, right)
	if left.completedAt ~= right.completedAt then
		return left.completedAt > right.completedAt
	end

	return left.level > right.level
end

---@return AMTDashboardRun[] newest first
local function GetHistoryRuns()
	local runs = {}

	for index, info in ipairs(C_MythicPlus.GetRunHistory(false, true, true)) do
		local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID)
		local chests = info.completed and timeLimit and AMT.Util.CountUpgrades(info.durationSec, timeLimit)

		runs[index] = {
			mapID = info.mapChallengeModeID,
			name = name or UNKNOWN,
			abbrev = GetAbbreviation(info.mapChallengeModeID, name),
			texture = texture,
			level = info.level,
			seconds = info.durationSec,
			completed = info.completed,
			chests = chests or 0,
			score = info.runScore,
			completedAt = CompletedAt(info.completionDate --[[@as CalendarTime]]),
		}
	end

	table.sort(runs, ByRecency)

	return runs
end

---@param run AMTDashboardRun
---@return AMTDashboardRunSummary
local function Summarise(run)
	return {
		name = run.name,
		abbrev = run.abbrev,
		texture = run.texture,
		level = run.level,
		seconds = run.seconds,
		chests = run.chests,
	}
end

-- Highest>Fastest>Timed>Untimed
---@param runs AMTDashboardRun[]
---@return AMTDashboardRunSummary? nil before a run this week
local function GetWeeklyBest(runs)
	local best

	for _, run in ipairs(runs) do
		local better = not best or run.level > best.level or (run.level == best.level and run.seconds < best.seconds)

		if run.completed and better then
			best = run
		end
	end

	return best and Summarise(best)
end

---@param intime MapSeasonBestInfo?
---@param overtime MapSeasonBestInfo?
---@return MapSeasonBestInfo?
local function BetterSeasonRun(intime, overtime)
	if intime and overtime then
		return intime.dungeonScore > overtime.dungeonScore and intime or overtime
	end

	return intime or overtime
end

---@return AMTDashboardRunSummary? nil before a run this season
local function GetSeasonBest()
	local best, bestMapID

	for _, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local info = BetterSeasonRun(C_MythicPlus.GetSeasonBestForMap(mapID))

		if info then
			local better = not best
				or info.level > best.level
				or (info.level == best.level and info.durationSec < best.durationSec)

			if better then
				best, bestMapID = info, mapID
			end
		end
	end

	if not best or not bestMapID then
		return nil
	end

	local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(bestMapID)

	return {
		name = name or UNKNOWN,
		abbrev = GetAbbreviation(bestMapID, name),
		texture = texture,
		level = best.level,
		seconds = best.durationSec,
		chests = timeLimit and AMT.Util.CountUpgrades(best.durationSec, timeLimit) or 0,
	}
end

---@param realm string the realm name as GetRealmName returns it, spaces intact
---@return string? slug nil when the page cannot be named with confidence
local function GetRaiderIOSlug(realm)
	-- Cyrillic lead bytes in UTF-8
	if realm:find("[\208\209]") then
		local english = AMT.RussianRealms[(realm:gsub("%s+", ""))]

		if not english then
			return nil
		end

		realm = english
	end

	if realm:find("[\128-\255]") then
		return nil
	end

	local slug = realm:gsub("'", "")

	slug = slug:gsub("%s+", "-")

	return slug:lower()
end

---@return string?
local function GetRaiderIOURL()
	local region = RAIDER_IO_REGIONS[GetCurrentRegion()]
	local slug = GetRaiderIOSlug(GetRealmName())
	local name = UnitName("player")

	if not region or not slug or issecretvalue(name) then
		return nil
	end

	return RAIDER_IO_URL:format(region, slug, name)
end

---@return AMTDashboardHeader
function Source:GetHeader()
	local affixes, affixIDs = GetAffixes()

	return {
		keystone = GetKeystone(affixIDs),
		rating = C_ChallengeMode.GetOverallDungeonScore(),
		weeklyBest = GetWeeklyBest(GetHistoryRuns()),
		seasonBest = GetSeasonBest(),
		affixes = affixes,
		raiderIOURL = GetRaiderIOURL(),
	}
end

---@param left WeeklyRewardActivityInfo
---@param right WeeklyRewardActivityInfo
---@return boolean
local function ByActivityIndex(left, right)
	return left.index < right.index
end

---@param activityInfo WeeklyRewardActivityInfo
---@return number? itemLevel nil until the example item has loaded
---@return number? upgradeItemLevel nil when the slot is already at its highest
---@return integer nextLevel
local function GetRewardLevels(activityInfo)
	local itemLink, upgradeItemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(activityInfo.id)
	local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink) or nil
	local upgradeItemLevel = upgradeItemLink and C_Item.GetDetailedItemLevelInfo(upgradeItemLink) or nil
	local hasSeasonData, _, nextLevel, nextItemLevel =
		C_WeeklyRewards.GetNextActivitiesIncrease(activityInfo.activityTierID, activityInfo.level)

	if hasSeasonData then
		upgradeItemLevel = nextItemLevel
	end

	return itemLevel, upgradeItemLevel, nextLevel or WeeklyRewardsUtil.GetNextMythicLevel(activityInfo.level)
end

---@param left MythicPlusRunInfo
---@param right MythicPlusRunInfo
---@return boolean
local function ByRunLevel(left, right)
	if left.level ~= right.level then
		return left.level > right.level
	end

	return left.mapChallengeModeID < right.mapChallengeModeID
end

---@return AMTDashboardVaultRun[] highest first
local function GetTopRuns()
	local history = C_MythicPlus.GetRunHistory(false, true)
	local runs = {}

	table.sort(history, ByRunLevel)

	for index, info in ipairs(history) do
		runs[index] = {
			level = info.level,
			name = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID) or UNKNOWN,
		}
	end

	return runs
end

---@return AMTDashboardVaultTrack
function Source:GetVault()
	local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.Activities)
	local numHeroic, numMythic = C_WeeklyRewards.GetNumCompletedDungeonRuns()
	local milestones = {}
	local progress = 0

	table.sort(activities, ByActivityIndex)

	for index, activityInfo in ipairs(activities) do
		local itemLevel, upgradeItemLevel, nextLevel = GetRewardLevels(activityInfo)
		local difficultyID = C_WeeklyRewards.GetDifficultyIDForActivityTier(activityInfo.activityTierID)

		-- One counter drives all three slots; the thresholds are what differ.
		progress = math.max(progress, activityInfo.progress)

		milestones[index] = {
			index = activityInfo.index,
			threshold = activityInfo.threshold,
			level = activityInfo.level,
			heroic = difficultyID == DifficultyUtil.ID.DungeonHeroic,
			itemLevel = itemLevel,
			upgradeItemLevel = upgradeItemLevel,
			nextLevel = nextLevel,
			lowestLevel = (WeeklyRewardsUtil.GetLowestLevelInTopDungeonRuns(activityInfo.threshold)),
		}
	end

	return {
		progress = progress,
		canClaim = C_WeeklyRewards.CanClaimRewards(),
		milestones = milestones,
		topRuns = GetTopRuns(),
		mythicRuns = numMythic,
		heroicRuns = numHeroic,
		rewardsWaiting = C_WeeklyRewards.HasAvailableRewards(),
	}
end

---@return number seconds
function Source:GetSecondsUntilWeeklyReset()
	return C_DateAndTime.GetSecondsUntilWeeklyReset()
end

---@param unit UnitToken
---@return table<integer, MythicPlusRatingMapSummary>
---@return number? rating nil when the client has no summary for the unit
local function GetBestRunsByMap(unit)
	local byMap = {}
	local summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary(unit)

	if not summary then
		return byMap, nil
	end

	for _, run in ipairs(summary.runs) do
		byMap[run.challengeModeID] = run
	end

	return byMap, summary.currentSeasonScore
end

---@param challengeMapID integer
---@return AMTDashboardFastestRun? nil when the dungeon has never been run
local function GetFastestRun(challengeMapID)
	local affixScores = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(challengeMapID)

	if not affixScores then
		return nil
	end

	local fastest = TableUtil.FindMin(affixScores, function(affixScore)
		return affixScore.durationSec
	end)

	if not fastest then
		return nil
	end

	return { level = fastest.level, seconds = fastest.durationSec, overTime = fastest.overTime }
end

---@return AMTDashboardSeasonDungeon[] in no particular order
function Source:GetSeasonDungeons()
	local dungeons = {}
	local byMap = GetBestRunsByMap("player")

	for index, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(mapID)
		local best = byMap[mapID]
		local teleport = AMT.Teleports.ForChallengeID(mapID)

		dungeons[index] = {
			mapID = mapID,
			name = name or UNKNOWN,
			abbrev = GetAbbreviation(mapID, name),
			texture = texture,
			score = best and best.mapScore or 0,
			level = best and best.bestRunLevel or 0,
			seconds = best and best.bestRunDurationMS / MILLISECONDS_PER_SECOND or 0,
			timed = best ~= nil and best.finishedSuccess,
			teleportSpellID = teleport and teleport.id,
			teleportName = teleport and C_Spell.GetSpellName(teleport.id) or TELEPORT_TO_DUNGEON,
			teleportKnown = teleport ~= nil and teleport.known,
			teleportUnlockLevel = AMT.Season.teleportUnlockLevel,
			fastest = GetFastestRun(mapID),
		}
	end

	return dungeons
end

---@param unit UnitToken
---@return AMTDashboardPartyDungeon[] dungeons every season dungeon in map-table order
---@return number? rating nil when the client has no summary for the unit
local function GetMemberDungeons(unit)
	local byMap, rating = GetBestRunsByMap(unit)
	local dungeons = {}

	for index, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
		local best = byMap[mapID]
		local seconds = best and best.bestRunDurationMS / MILLISECONDS_PER_SECOND or 0

		dungeons[index] = {
			name = name or UNKNOWN,
			level = best and best.bestRunLevel or 0,
			timed = best ~= nil and best.finishedSuccess,
			upgrades = best and timeLimit and AMT.Util.CountUpgrades(seconds, timeLimit) or 0,
		}
	end

	return dungeons, rating
end

---@param challengeMapID integer
---@param level integer
---@return AMTDashboardPartyKey
local function BuildPartyKey(challengeMapID, level)
	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(challengeMapID)

	return {
		name = name or UNKNOWN,
		abbrev = GetAbbreviation(challengeMapID, name),
		texture = texture,
		level = level,
	}
end

---@return AMTDashboardPartyKey? nil when the character holds no key
local function GetPlayerKey()
	local challengeMapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
	local level = C_MythicPlus.GetOwnedKeystoneLevel()

	if not challengeMapID or not level then
		return nil
	end

	return BuildPartyKey(challengeMapID, level)
end

---@param guid string?
---@return AMTDashboardPartyKey?
local function GetReportedKey(guid)
	local keystone = guid and AMT.Comms:GetKeystone(guid)

	return keystone and BuildPartyKey(keystone.challengeMapID, keystone.level) or nil
end

---@param unit UnitToken
---@param isPlayer boolean
---@return AMTDashboardPartyMember? nil where the unit is absent or its identity cannot be read
local function GetMember(unit, isPlayer)
	if not UnitExists(unit) then
		return nil
	end

	local name = UnitName(unit)
	local _, classFile = UnitClass(unit)

	if issecretvalue(name) or issecretvalue(classFile) then
		return nil
	end

	local dungeons, rating = GetMemberDungeons(unit)
	local guid = UnitGUID(unit)

	if issecretvalue(guid) then
		guid = nil
	end

	local key

	if isPlayer then
		key = GetPlayerKey()
	else
		key = GetReportedKey(guid)
	end

	return {
		name = name,
		classFile = classFile,
		specIcon = guid and AMT.Inspect:GetSpecIcon(guid) or nil,
		key = key,
		rating = rating,
		dungeons = dungeons,
	}
end

---@return AMTDashboardPartyRoster
function Source:GetParty()
	local members = {}

	for index, unit in ipairs(PARTY_UNITS) do
		local member = GetMember(unit, index == 1)

		if member then
			members[#members + 1] = member
		end
	end

	return { inGroup = IsInGroup(), members = members }
end

---Since cooldown is shared, first learned entry gives the cooldown.
---@return number? remaining seconds; 0 when ready; nil while it cannot be known
function Source:GetTeleportCooldown()
	if C_Secrets.ShouldCooldownsBeSecret() then
		return nil
	end

	for _, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local teleport = AMT.Teleports.ForChallengeID(mapID)

		if teleport and teleport.known then
			local cooldown = C_Spell.GetSpellCooldown(teleport.id)

			if not cooldown.isActive then
				return 0
			end

			local startTime, duration = cooldown.startTime, cooldown.duration

			if issecretvalue(startTime) or issecretvalue(duration) then
				return nil
			end

			if duration <= GCD_SECONDS then
				return 0
			end

			return math.max(startTime + duration - GetTime(), 0)
		end
	end

	return nil
end

---@param recorded AMTRecordedRun[]
---@param run AMTDashboardRun
---@param claimed table<AMTRecordedRun, true> records already matched to another run
---@return AMTRecordedRun? match nil when AMT did not watch this run
local function FindRecorded(recorded, run, claimed)
	local match, closest

	for _, candidate in ipairs(recorded) do
		if
			not claimed[candidate]
			and candidate.mapID == run.mapID
			and candidate.level == run.level
			and math.abs(candidate.durationSec - run.seconds) <= DURATION_MATCH_SECONDS
		then
			local distance = math.abs(candidate.completedAt - run.completedAt)

			if distance <= RECORD_MATCH_SECONDS and (not closest or distance < closest) then
				match, closest = candidate, distance
			end
		end
	end

	return match
end

---@param record AMTRecordedRun
---@return AMTDashboardRunSplit[]
local function BuildSplits(record)
	local best = AMT.Splits.GetBest(C_MythicPlus.GetCurrentSeason(), record.mapID, record.level)
	local splits = {}

	for index, boss in ipairs(record.bosses) do
		local reference = best and best.bosses[index]

		splits[index] = {
			name = boss.name or UNKNOWN,
			timeMS = boss.timeMS,
			diffMS = reference and boss.timeMS - reference.timeMS or nil,
		}
	end

	return splits
end

---@param runs AMTDashboardRun[]
local function MergeRecordedRuns(runs)
	local recorded = AMT.History.GetRecordedRuns()

	if #recorded == 0 then
		return
	end

	---@type table<AMTRecordedRun, true>
	local claimed = {}

	for _, run in ipairs(runs) do
		local record = run.completed and FindRecorded(recorded, run, claimed) or nil

		if record then
			claimed[record] = true
			run.party = record.party
			run.splits = BuildSplits(record)
		end
	end
end

---@return AMTDashboardRun[] newest first
function Source:GetWeeklyRuns()
	local runs = GetHistoryRuns()

	MergeRecordedRuns(runs)

	return runs
end
