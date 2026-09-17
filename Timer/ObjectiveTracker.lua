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

---@return { Toggle: fun(self: table, show: boolean?) }?
local function GetKalielsTracker()
	local api = _G.KalielsTracker

	return api and api.Toggle and api or nil
end

---@param value boolean
function Tracker.SetHidden(value)
	if hidden == value then
		return
	end

	local kaliels = GetKalielsTracker()

	if kaliels then
		hidden = value
		kaliels:Toggle(not value)

		return
	end

	if not ObjectiveTrackerFrame then
		return
	end

	EnsureHook()

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
