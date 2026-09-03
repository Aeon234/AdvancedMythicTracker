local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local DISABLED_ALPHA = 0.4
local DEFAULT_CONTROL_HEIGHT = 22

---@alias AMTOptionGetter fun(): any
---@alias AMTOptionSetter fun(value: any)
---@alias AMTOptionPredicate fun(): boolean

---@class AMTOptionInfo
---@field mediaType string? LibSharedMedia type for the media dropdown; defaults to "statusbar"
---@field type string registered widget name
---@field label string already localised
---@field path string? dotted, resolved against `scope`
---@field scope AMTBindingScope? defaults to "profile"
---@field get AMTOptionGetter? overrides `path`
---@field set AMTOptionSetter? overrides `path`
---@field disabled AMTOptionPredicate? greyed at ~40%, still visible
---@field hidden AMTOptionPredicate? removed from the flow; the container reflows
---@field dirty AMTDirtyKey? narrows D-52's mark-everything default
---@field values table[]? enum widgets: { storedKey, displayLabel } pairs
---@field min number?
---@field max number?
---@field step number?

---@class AMTOptionWidget
---@field frame Frame
---@field label FontString
---@field labelWidth number
---@field info AMTOptionInfo?
---@field disabled boolean?
local Widget = {}
Widget.__index = Widget
Options.Widget = Widget

---@return number
function Widget:GetControlHeight()
	return DEFAULT_CONTROL_HEIGHT
end

---@return number
function Widget:GetControlOffset()
	return self.labelWidth + CONST.LABEL_GAP
end

---@param parent Frame
function Widget:Create(parent)
	self.frame = CreateFrame("Frame", nil, parent)
	self.frame:SetHeight(self:GetControlHeight() + CONST.CORNER_SIZE)

	self.label = self.frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	self.label:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
	self.label:SetWidth(self.labelWidth)
	self.label:SetJustifyH("LEFT")
	self.label:SetWordWrap(false)
end

---@param info AMTOptionInfo
function Widget:Bind(info)
	self.info = info
	self.label:SetText(info.label or "")

	self:Update()
end

---@return boolean visible
function Widget:Update()
	local info = self.info

	if not info or (info.hidden and info.hidden()) then
		self.frame:Hide()

		return false
	end

	self.frame:Show()

	self.disabled = info.disabled ~= nil and info.disabled()
	self.frame:SetAlpha(self.disabled and DISABLED_ALPHA or 1)

	return true
end

---@return any
function Widget:GetValue()
	local info = self.info

	if not info then
		return nil
	end

	if info.get then
		return info.get()
	end

	return info.path and Options.Get(info.path, info.scope) or nil
end

---@param value any
function Widget:SetValue(value)
	local info = self.info

	if not info then
		return
	end

	if info.set then
		info.set(value)
		AMT.Profiles.Refresh()
	elseif info.path then
		Options.Set(info.path, value, info.scope)
	end

	self:Update()

	Options.NotifyValueChanged()
end

function Options.NotifyValueChanged() end

---@type table<string, AMTOptionWidget>
local prototypes = {}

---@param widgetType string
---@return AMTOptionWidget
function Options.NewWidgetPrototype(widgetType)
	if prototypes[widgetType] then
		AMT.Util.Warn("widget type %q is already registered; the duplicate will not be reachable.", widgetType)
	end

	local prototype = setmetatable({}, { __index = Widget })
	prototype.__index = prototype

	prototypes[widgetType] = prototype

	return prototype
end

---@param widgetType string
---@param parent Frame
---@param labelWidth number? defaults to CONST.LABEL_WIDTH; nested tab pages pass the narrower one
---@return AMTOptionWidget?
function Options.NewWidget(widgetType, parent, labelWidth)
	local prototype = prototypes[widgetType]

	if not prototype then
		AMT.Util.Warn("no widget registered for type %q.", tostring(widgetType))

		return nil
	end

	local widget = setmetatable({ labelWidth = labelWidth or CONST.LABEL_WIDTH }, prototype)

	widget:Create(parent)

	return widget
end
