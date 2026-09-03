local AMT = select(2, ...)
local L = AMT.L

---@class AMTTooltip
local Tooltip = {}
AMT.Tooltip = Tooltip

---@param owner Frame
function Tooltip.ShowDeaths(owner)
	local state = AMT.State.current

	if state.deathCount <= 0 then
		return
	end

	GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
	GameTooltip:AddLine(DEATHS)

	for _, death in ipairs(state.deaths) do
		local color = death.class and C_ClassColor.GetClassColor(death.class)
		local when = AMT.Util.FormatTime(death.atMS / 1000)

		if color then
			GameTooltip:AddDoubleLine(death.name or UNKNOWN, when, color.r, color.g, color.b, 1, 1, 1)
		else
			GameTooltip:AddDoubleLine(death.name or UNKNOWN, when, 1, 1, 1, 1, 1, 1)
		end
	end

	local unnamed = state.deathCount - #state.deaths

	if unnamed > 0 then
		GameTooltip:AddLine(("%s: %d"):format(L["Unnamed deaths"], unnamed), 0.7, 0.7, 0.7)
	end

	GameTooltip:Show()
end

function Tooltip.Hide()
	GameTooltip:Hide()
end
