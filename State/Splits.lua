local AMT = select(2, ...)

local State = AMT.State

local EQUAL_TOLERANCE_MS = 500

---@class AMTBossSplit
---@field name string?
---@field timeMS integer

---@class AMTSplitRecord
---@field finishMS integer
---@field forcesMS integer?
---@field bosses AMTBossSplit[]
---@field date integer? epoch seconds

---@alias AMTSplitVerdict "AHEAD"|"EQUAL"|"BEHIND"

---@class AMTSplits
local Splits = {}
AMT.Splits = Splits

---@param seasonID integer?
---@param mapID integer?
---@param level integer
---@return AMTSplitRecord? record
---@return integer? recordLevel the level the record was actually found at
function Splits.GetBest(seasonID, mapID, level)
	if not seasonID or not mapID or level <= 0 then
		return nil, nil
	end

	local season = AMT.DB.records.best[seasonID]
	local map = season and season[mapID]

	if not map then
		return nil, nil
	end

	if map[level] then
		return map[level], level
	end

	if map[level - 1] then
		return map[level - 1], level - 1
	end

	return nil, nil
end

---@return AMTSplitRecord? record
---@return integer? recordLevel
function Splits.GetCurrentBest()
	local state = State.current

	return Splits.GetBest(state.seasonID, state.mapID, state.level)
end

---@param index integer
---@return integer? diffMS
function Splits.BossDiffMS(index)
	local objective = State.current.objectives[index]

	if not objective or not objective.completedAtMS then
		return nil
	end

	local record = Splits.GetCurrentBest()
	local best = record and record.bosses and record.bosses[index]

	if not best then
		return nil
	end

	local recorded = best.name
	local current = objective.name or objective.description

	if recorded and current and recorded ~= current then
		return nil
	end

	return objective.completedAtMS - best.timeMS
end

---@return integer? diffMS
function Splits.ForcesDiffMS()
	local state = State.current

	if not state.forcesCompletedAtMS then
		return nil
	end

	local record = Splits.GetCurrentBest()

	if not record or not record.forcesMS then
		return nil
	end

	return state.forcesCompletedAtMS - record.forcesMS
end

---@return integer? finishMS
function Splits.TargetMS()
	local record = Splits.GetCurrentBest()

	return record and record.finishMS or nil
end

---@return integer? diffMS
function Splits.FinishDiffMS()
	local state = State.current
	local record = Splits.GetCurrentBest()

	if not state.challengeCompleted or not state.completionMS or not record then
		return nil
	end

	return state.completionMS - record.finishMS
end

---@param diffMS integer
---@return AMTSplitVerdict
function Splits.Classify(diffMS)
	if diffMS < -EQUAL_TOLERANCE_MS then
		return "AHEAD"
	elseif diffMS > EQUAL_TOLERANCE_MS then
		return "BEHIND"
	end

	return "EQUAL"
end

---@return AMTSplitRecord? record
function Splits.BuildRecord()
	local state = State.current

	if not state.challengeCompleted or not state.completionMS then
		return nil
	end

	local bosses = {}

	for index, objective in ipairs(state.objectives) do
		if objective.completedAtMS then
			bosses[index] = {
				name = objective.name or objective.description,
				timeMS = objective.completedAtMS,
			}
		end
	end

	return {
		finishMS = state.completionMS,
		forcesMS = state.forcesCompletedAtMS,
		bosses = bosses,
		date = time(),
	}
end
