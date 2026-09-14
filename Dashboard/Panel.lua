local AMT = select(2, ...)

---@class AMTDashboardPanel
local Panel = {}
AMT.Dashboard.Panel = Panel

---@param host Frame
---@return Frame
function Panel.Build(host)
	local frame = CreateFrame("Frame", nil, host)

	frame:SetAllPoints(host)
	frame:Hide()

	return frame
end
