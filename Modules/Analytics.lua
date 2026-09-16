local AMT = select(2, ...)
local L = AMT.L

---@class AMTRunRecord
---@field mapID integer
---@field level integer
---@field completed boolean
---@field durationSec integer
---@field runScore number
---@field thisWeek boolean

---@class AMTRecordedMember
---@field classFile string
---@field specIcon number? nil until an inspect has seen the member

---@class AMTRecordedRun
---@field mapID integer
---@field level integer
---@field durationSec integer
---@field completedAt integer epoch seconds
---@field completedOnTime boolean
---@field deaths integer
---@field affixIDs integer[]
---@field bosses AMTBossSplit[]
---@field forcesMS integer?
---@field party AMTRecordedMember[] in party order, the player first

---@class AMTHistoryEntry
---@field runs AMTRunRecord[]
---@field abandoned table<integer, table<integer, integer>> mapID > level > count
---@field recorded AMTRecordedRun[] since the last weekly reset

---@class AMTAnalyticsModule : AMTModule
local module = AMT.Modules.New("Analytics")

-- Following MPlusTimer's 10s delay; Reloe says an
-- immediate read returns nil or inaccurate data.
local LOGIN_DELAY = 10
local COMPLETION_DELAY = 2
local MILLISECONDS_PER_SECOND = 1000
local SECONDS_PER_WEEK = 7 * SECONDS_PER_DAY
local UNIT_ORDER = { player = 1, party1 = 2, party2 = 3, party3 = 4, party4 = 5 }

---@param seasonID integer
---@param mapID integer
---@return table<integer, AMTSplitRecord>
local function EnsureMap(seasonID, mapID)
	local best = AMT.DB.records.best
	local season = best[seasonID]

	if not season then
		season = {}
		best[seasonID] = season
	end

	local map = season[mapID]

	if not map then
		map = {}
		season[mapID] = map
	end

	return map
end

---@return boolean stored
function module:RecordBest()
	if AMT.Demo.IsActive() then
		return false
	end

	local record = AMT.Splits.BuildRecord()

	if not record then
		return false
	end

	local state = AMT.State.current
	local seasonID, mapID, level = state.seasonID, state.mapID, state.level

	if not seasonID or not mapID or level <= 0 then
		AMT.Util.Warn(L["finished a key with incomplete identity; personal best was not stored."])

		return false
	end

	local map = EnsureMap(seasonID, mapID)
	local existing = map[level]

	if existing and existing.finishMS <= record.finishMS then
		return false
	end

	map[level] = record

	AMT.Util.Print("%s %s", L["New personal best:"], AMT.Util.FormatTime(record.finishMS / 1000, 1))

	return true
end

---@return string? guid nil when the player GUID is unreadable
local function PlayerGUID()
	local guid = UnitGUID("player")

	if not guid or issecretvalue(guid) then
		return nil
	end

	return guid
end

---@param seasonID integer
---@param guid string
---@return AMTHistoryEntry
local function EnsureEntry(seasonID, guid)
	local history = AMT.DB.records.history
	local bucket = history[seasonID]

	if not bucket then
		bucket = {}
		history[seasonID] = bucket
	end

	local entry = bucket[guid]

	if not entry then
		entry = { runs = {}, abandoned = {}, recorded = {} }
		bucket[guid] = entry
	end

	if not entry.recorded then
		entry.recorded = {}
	end

	return entry
end

---@return table<integer, true>?
local function SeasonMapSet()
	local maps = C_ChallengeMode.GetMapTable()

	if not maps or #maps == 0 then
		return nil
	end

	---@type table<integer, true>
	local set = {}

	for _, mapID in ipairs(maps) do
		set[mapID] = true
	end

	return set
end

function module:RefreshHistory()
	local guid = PlayerGUID()

	if not guid then
		return
	end

	---@type MythicPlusRunInfo[]
	local runs = C_MythicPlus.GetRunHistory(true, true)
	local currentSeason = C_MythicPlus.GetCurrentSeason()
	local allowed = SeasonMapSet()

	for _, bucket in pairs(AMT.DB.records.history) do
		if bucket[guid] then
			bucket[guid].runs = {}
		end
	end

	for _, run in ipairs(runs) do
		local keep = not allowed or run.season ~= currentSeason or allowed[run.mapChallengeModeID]

		if keep then
			local entry = EnsureEntry(run.season, guid)

			entry.runs[#entry.runs + 1] = {
				mapID = run.mapChallengeModeID,
				level = run.level,
				completed = run.completed,
				durationSec = run.durationSec,
				runScore = run.runScore,
				thisWeek = run.thisWeek,
			}
		end
	end
end

---@param event string
---@param votePassed boolean
function module:OnAbandonVote(event, votePassed)
	local state = AMT.State.current

	if not AMT.DB.settings.recordAbandons then
		return
	end

	if not votePassed or not state.inChallenge or state.challengeCompleted then
		return
	end

	local guid = PlayerGUID()

	if not guid or not state.seasonID or not state.mapID or state.level <= 0 then
		return
	end

	local entry = EnsureEntry(state.seasonID, guid)
	local byLevel = entry.abandoned[state.mapID]

	if not byLevel then
		byLevel = {}
		entry.abandoned[state.mapID] = byLevel
	end

	byLevel[state.level] = (byLevel[state.level] or 0) + 1
end

---@return integer epoch seconds of the most recent weekly reset
local function LastWeeklyReset()
	return time() + C_DateAndTime.GetSecondsUntilWeeklyReset() - SECONDS_PER_WEEK
end

-- The dashboard shows this week only, so the store keeps this week only.
---@param entry AMTHistoryEntry
local function PurgeRecorded(entry)
	local since = LastWeeklyReset()
	local kept = {}

	for _, run in ipairs(entry.recorded) do
		if run.completedAt >= since then
			kept[#kept + 1] = run
		end
	end

	entry.recorded = kept
end

---@param left AMTPartyMember
---@param right AMTPartyMember
---@return boolean
local function ByUnitOrder(left, right)
	return (UNIT_ORDER[left.unit] or math.huge) < (UNIT_ORDER[right.unit] or math.huge)
end

---@return AMTRecordedMember[]
local function RecordedParty()
	local snapshot = {}

	for _, member in pairs(AMT.Deaths.GetPartySnapshot()) do
		snapshot[#snapshot + 1] = member
	end

	table.sort(snapshot, ByUnitOrder)

	local party = {}

	for index, member in ipairs(snapshot) do
		party[index] = { classFile = member.class }
	end

	return party
end

---@param affixIDs integer[]
---@return integer[] copy
local function CopyAffixes(affixIDs)
	local copy = {}

	for index, affixID in ipairs(affixIDs) do
		copy[index] = affixID
	end

	return copy
end

---@return boolean stored
function module:RecordRun()
	if AMT.Demo.IsActive() or PlayerIsTimerunning() then
		return false
	end

	local state = AMT.State.current
	local guid = PlayerGUID()

	if not guid or not state.seasonID or not state.mapID or state.level <= 0 or not state.completionMS then
		return false
	end

	local entry = EnsureEntry(state.seasonID, guid)
	local record = AMT.Splits.BuildRecord()

	PurgeRecorded(entry)

	entry.recorded[#entry.recorded + 1] = {
		mapID = state.mapID,
		level = state.level,
		durationSec = math.floor(state.completionMS / MILLISECONDS_PER_SECOND),
		completedAt = time(),
		completedOnTime = state.completedOnTime == true,
		deaths = state.deathCount,
		affixIDs = CopyAffixes(state.affixIDs),
		bosses = record and record.bosses or {},
		forcesMS = record and record.forcesMS or nil,
		party = RecordedParty(),
	}

	return true
end

---@class AMTHistory
local History = {}
AMT.History = History

-- This week's runs AMT watched, in the order they were completed.
---@return AMTRecordedRun[] runs
function History.GetRecordedRuns()
	local guid = PlayerGUID()
	local seasonID = C_MythicPlus.GetCurrentSeason()

	if not guid or not seasonID then
		return {}
	end

	local bucket = AMT.DB.records.history[seasonID]
	local entry = bucket and bucket[guid]

	if not entry or not entry.recorded then
		return {}
	end

	return entry.recorded
end

function module:OnChallengeComplete()
	self:RecordBest()
	self:RecordRun()
end
