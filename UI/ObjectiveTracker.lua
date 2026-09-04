local AMT = select(2, ...)

---@class AMTObjectiveTracker
local Tracker = {}
AMT.ObjectiveTracker = Tracker

local hidden = false
local hooked = false

local function EnsureHook()
	if hooked or not ScenarioObjectiveTracker then
		return
	end

	hooked = true

	hooksecurefunc(ScenarioObjectiveTracker, "Show", function()
		if hidden then
			ScenarioObjectiveTracker:Hide()
		end
	end)
end

---@param value boolean
function Tracker.SetHidden(value)
	if not ScenarioObjectiveTracker then
		return
	end

	EnsureHook()

	if hidden == value then
		return
	end

	hidden = value

	if hidden then
		ScenarioObjectiveTracker:Hide()

		return
	end

	ScenarioObjectiveTracker:Show()

	if ObjectiveTrackerFrame then
		ObjectiveTrackerFrame:Update()
	end
end

---@return boolean
function Tracker.IsHidden()
	return hidden
end
