local AMT = select(2, ...)

local State = AMT.State

local CRITERIA_TYPE_DUNGEON_ENCOUNTER = 165

-- Table addressing inconsistencies in some dungeons.
-- e.g. Pit of Saron's Quarry Camps reporting 1/6 instead of 6/6
local UNRELIABLE_ELAPSED = {
	[556] = { [3] = true },
}

---@class AMTObjectives
local Objectives = {}
AMT.Objectives = Objectives

---@param mapID integer?
---@param index integer
---@param info ScenarioCriteriaInfo
---@return integer
local function ResolveCompletion(mapID, index, info)
	local now = select(2, GetWorldElapsedTime(1))
	local quirks = mapID and UNRELIABLE_ELAPSED[mapID]

	if quirks and quirks[index] then
		return math.floor(now * 1000)
	end

	return math.floor((now - (info.elapsed or 0)) * 1000)
end

function Objectives.Update()
	---@type ScenarioStepInfo?
	local step = C_ScenarioInfo.GetScenarioStepInfo()

	if not step or step.numCriteria <= 0 then
		return
	end

	local state = State.current
	local objectives = state.objectives
	local changed = false
	local slot = 0

	for index = 1, step.numCriteria do
		---@type ScenarioCriteriaInfo?
		local info = C_ScenarioInfo.GetCriteriaInfo(index)

		if info and not info.isWeightedProgress then
			slot = slot + 1

			local objective = objectives[slot]

			if not objective or objective.description ~= info.description then
				---@type AMTObjective
				objective = {
					description = info.description,
					dungeonEncounterID = info.criteriaType == CRITERIA_TYPE_DUNGEON_ENCOUNTER and info.assetID or nil,
				}

				objectives[slot] = objective
				changed = true
			end

			if info.completed and not objective.completedAtMS then
				objective.completedAtMS = ResolveCompletion(state.mapID, index, info)
				changed = true
			end
		end
	end

	-- Tazavesh reports every boss from both wings. Removes wrong wing bosses once timer starts.
	for extra = #objectives, slot + 1, -1 do
		objectives[extra] = nil
		changed = true
	end

	if changed then
		State.MarkDirty("objectives")
	end
end
