local AMT = select(2, ...)

local State = AMT.State

---@class AMTForces
local Forces = {}
AMT.Forces = Forces

---@param total integer
function Forces.SetTotal(total)
	local state = State.current

	if state.totalCount == total then
		return
	end

	state.totalCount = total
	state.currentPercent = total > 0 and math.min(state.currentCount / total, 1.0) or 0

	State.MarkDirty("forces")
end

---@param current integer
function Forces.SetCurrent(current)
	local state = State.current

	if current <= state.currentCount then
		return
	end

	state.currentCount = current
	state.currentPercent = state.totalCount > 0 and math.min(current / state.totalCount, 1.0) or 0

	State.MarkDirty("forces")
end

function Forces.Update()
	---@type ScenarioStepInfo?
	local step = C_ScenarioInfo.GetScenarioStepInfo()

	if not step or step.numCriteria <= 0 then
		return
	end

	for index = 1, step.numCriteria do
		---@type ScenarioCriteriaInfo?
		local info = C_ScenarioInfo.GetCriteriaInfo(index)

		if info and info.isWeightedProgress then
			local total = info.totalQuantity

			if not total or total <= 0 then
				return
			end

			local current = tonumber(info.quantityString:match("%d+")) or 0

			Forces.SetTotal(total)
			Forces.SetCurrent(current)

			local state = State.current

			if (current >= total or info.completed) and not state.forcesCompleted then
				state.forcesCompleted = true

				local elapsed = select(2, GetWorldElapsedTime(1))
				state.forcesCompletedAtMS = math.floor((elapsed - (info.elapsed or 0)) * 1000)

				State.MarkDirty("forces")
			end

			return
		end
	end
end
