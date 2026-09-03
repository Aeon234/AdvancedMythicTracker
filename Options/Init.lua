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
---@field Widget AMTOptionWidget
---@field Get fun(path: string, scope: AMTBindingScope?): any
---@field Set fun(path: string, value: any, scope: AMTBindingScope?): boolean
---@field RegisterCategory fun(definition: AMTOptionsCategory)
---@field RegisterPage fun(definition: AMTOptionsPage)
---@field GetCategories fun(): AMTOptionsCategory[]
---@field GetPages fun(categoryID: string): AMTOptionsPage[]
---@field GetPage fun(id: string): AMTOptionsPage?
---@field GetFirstPage fun(): AMTOptionsPage?
---@field NewWidgetPrototype fun(widgetType: string): AMTOptionWidget
---@field NewWidget fun(widgetType: string, parent: Frame, labelWidth: number?): AMTOptionWidget?
---@field NotifyValueChanged fun()
---@field CreateCheckboxControl fun(parent: Frame, onClick: fun()): Button, Texture, AMTBorder?
---@field CreateActionButton fun(parent: Frame, onClick: fun()): Button, FontString, Texture, AMTBorder?
---@field Container AMTOptionsContainer
---@field NewContainer fun(parent: Frame, labelWidth: number?, spacing: number?): AMTOptionsContainer
---@field Group AMTOptionsGroup
---@field NewGroup fun(parent: Frame, config: AMTOptionsGroupConfig): AMTOptionsGroup
---@field PageHeader AMTOptionsPageHeader
---@field NewPageHeader fun(parent: Frame, config: AMTOptionsPageHeaderConfig): AMTOptionsPageHeader
---@field NewDivider fun(parent: Frame, style: string?): Frame
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
