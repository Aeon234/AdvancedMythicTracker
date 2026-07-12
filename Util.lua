local AMT = select(2, ...) ---@class AMT

-- Pure helpers shared across the addon. No UI side effects in this file —
-- anything that touches frames lives with the frame's owner (e.g. Dashboard.lua).

---Loops through PVEFrame's numTabs and counts how many are visible.
---@return integer
function AMT.GetPVEFrameTabNums()
	local tabs = 0
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if PVEFrame_Tab and PVEFrame_Tab:IsVisible() then
			tabs = tabs + 1
		end
	end

	return tabs
end

---Whether the Main Tab is usable right now. Pure predicate, no side effects;
---visuals are applied by AMT.UpdateMainTabState (Dashboard.lua).
---Conditions mirror Blizzard's ChallengesFrame gating (Blizzard_GroupFinder/PVEFrame.lua).
---@return boolean eligible
---@return string|nil reasonKey locale key describing why the tab is locked
function AMT.IsTabEligible()
	if PlayerGetTimerunningSeasonID() then
		return false, "TAB_LOCKED_TIMERUNNER"
	end
	if UnitLevel("player") < GetMaxLevelForPlayerExpansion() then
		return false, "TAB_LOCKED_NOT_MAX_LEVEL"
	end
	if not C_MythicPlus.IsMythicPlusActive() then
		return false, "TAB_LOCKED_NO_SEASON"
	end

	return true, nil
end
