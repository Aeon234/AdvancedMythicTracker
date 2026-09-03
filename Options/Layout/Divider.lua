local AMT = select(2, ...)

local Options = AMT.Options

---@class AMTDividerStyle
---@field texture string
---@field height number
---@field lineHeight number
---@field color number[]

---@type table<string, AMTDividerStyle>
local STYLES = {
	thin = { texture = "DividerThin", height = 14, lineHeight = 14, color = { 1, 1, 1, 0.22 } },
	accent = { texture = "DividerAccent", height = 18, lineHeight = 6, color = { 1, 0.8235, 0, 1 } },
}

---@param parent Frame
---@param style string? thin|accent
---@return Frame
function Options.NewDivider(parent, style)
	local config = STYLES[style or "thin"] or STYLES.thin
	local divider = CreateFrame("Frame", nil, parent)

	divider:SetHeight(config.height)

	local line = divider:CreateTexture(nil, "ARTWORK")
	local color = config.color

	line:SetHeight(config.lineHeight)
	line:SetPoint("LEFT", divider, "LEFT", 0, 0)
	line:SetPoint("RIGHT", divider, "RIGHT", 0, 0)
	line:SetTexture(AMT.NineSlice.Path(config.texture))
	line:SetVertexColor(color[1], color[2], color[3], color[4])

	return divider
end
