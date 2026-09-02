local AMT = select(2, ...)

---@class AMTRunRecord
---@field mapID integer
---@field level integer
---@field completed boolean
---@field durationSec integer
---@field runScore number
---@field thisWeek boolean

---@class AMTHistoryEntry
---@field runs AMTRunRecord[]
---@field abandoned table<integer, table<integer, integer>> mapID > level > count

---@class AMTAnalyticsModule : AMTModule
local module = AMT.Modules.New("Analytics")

-- Following MPlusTimer's 10s delay. Reloe says immediate read will result in nil data or inaccurate data.
local LOGIN_DELAY = 10
local COMPLETION_DELAY = 2

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
		AMT.Util.Warn("finished a key with incomplete identity; personal best was not stored.")

		return false
	end

	local map = EnsureMap(seasonID, mapID)
	local existing = map[level]

	if existing and existing.finishMS <= record.finishMS then
		return false
	end

	map[level] = record

	AMT.Util.Print("%s %s", AMT.L["New personal best:"], AMT.Util.FormatTime(record.finishMS / 1000, 1))

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
		entry = { runs = {}, abandoned = {} }
		bucket[guid] = entry
	end

	return entry
end

---@return table<integer, true>?
local function SeasonMapSet()
	local maps = C_ChallengeMode.GetMapTable()

	if not maps or #maps == 0 then
		return nil
	end

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

function module:OnEnable()
	AMT.Events.Register("PLAYER_ENTERING_WORLD", self, function(this)
		C_Timer.After(LOGIN_DELAY, function()
			this:RefreshHistory()
		end)
	end)
end

function module:OnChallengeStart()
	AMT.Events.RegisterChallenge("INSTANCE_ABANDON_VOTE_FINISHED", self, self.OnAbandonVote)
end

function module:OnChallengeComplete()
	self:RecordBest()

	C_Timer.After(COMPLETION_DELAY, function()
		self:RefreshHistory()
	end)
end
