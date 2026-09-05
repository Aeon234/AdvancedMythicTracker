local AMT = select(2, ...)

---@class AMTObjectiveTracker
local Tracker = {}
AMT.ObjectiveTracker = Tracker

local hidden = false
local hooked = false

local function EnsureHook()
	if hooked or not ObjectiveTrackerFrame then
		return
	end

	hooked = true

	hooksecurefunc(ObjectiveTrackerFrame, "Show", function()
		if hidden then
			ObjectiveTrackerFrame:Hide()
		end
	end)
end

---@param value boolean
function Tracker.SetHidden(value)
	if not ObjectiveTrackerFrame then
		return
	end

	EnsureHook()

	if hidden == value then
		return
	end

	hidden = value

	if hidden then
		ObjectiveTrackerFrame:Hide()

		return
	end

	ObjectiveTrackerFrame:Update()
end

---@return boolean
function Tracker.IsHidden()
	return hidden
end
