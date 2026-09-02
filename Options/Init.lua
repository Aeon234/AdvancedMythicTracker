local AMT = select(2, ...)

---@class AMTOptionsConstants
---@field FRAME_WIDTH number
---@field FRAME_HEIGHT number
---@field TITLE_HEIGHT number
---@field SIDEBAR_WIDTH number
---@field PANEL_PADDING number
---@field LABEL_WIDTH number
---@field LABEL_WIDTH_NESTED number
---@field LABEL_GAP number
---@field ROW_SPACING number
---@field CORNER_SIZE number
---@field SCROLL_PAN_EXTENT number

---@class AMTOptions
---@field Styles AMTStyles
---@field CONST AMTOptionsConstants
local Options = {}
AMT.Options = Options

Options.CONST = {
	FRAME_WIDTH = 880,
	FRAME_HEIGHT = 640,
	TITLE_HEIGHT = 34,
	SIDEBAR_WIDTH = 190,
	PANEL_PADDING = 16,
	LABEL_WIDTH = 150,
	LABEL_WIDTH_NESTED = 110,
	LABEL_GAP = 12,
	ROW_SPACING = 12,
	CORNER_SIZE = 16,
	SCROLL_PAN_EXTENT = 60,
}
