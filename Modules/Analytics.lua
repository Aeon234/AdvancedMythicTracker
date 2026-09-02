local AMT = select(2, ...)

---@class AMTAnalyticsModule : AMTModule
local module = AMT.Modules.New("Analytics")

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

function module:OnChallengeComplete()
	self:RecordBest()
end
