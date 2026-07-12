local AMT = select(2, ...) ---@class AMT

---Loops through PVEFrame's numTabs and counts how many are visible.
---@return integer
function AMT.GetPVEFrameTabNums()
	local tabs = 0
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if PVEFrame_Tab:IsVisible() then
			tabs = tabs + 1
		end
	end

	return tabs
end

---Check whether the Main Tab should be enabled or disabled.
function AMT.GetTabEligibility()
	if not AMT.MainTab then
		return
	end

	if
		C_MythicPlus.IsMythicPlusActive()
		and UnitLevel("player") >= GetMaxLevelForPlayerExpansion()
		and not PlayerGetTimerunningSeasonID()
	then
		AMT.MainTab:Enable()
		AMT.MainTab:Disable()
		AMT.MainTab:SetText("|cff808080Mythic+ Tracker")
	else
		AMT.MainTab:Disable()
		AMT.MainTab:SetText("|cff808080Mythic+ Tracker")
	end
end
