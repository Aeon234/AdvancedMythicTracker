local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options
local CONST = Options.CONST

---@alias AMTOptionsNestable AMTOptionsContainer|AMTOptionsGroup|AMTOptionsPageHeader

---@class AMTOptionsContainer
---@field frame Frame
---@field children Frame[]
---@field widgets AMTOptionWidget[]
---@field labelWidth number
---@field spacing number
---@field suspended boolean?
---@field onResized fun()?
---@field nested AMTOptionsNestable[]
local Container = {}
Container.__index = Container
Options.Container = Container

---@param parent Frame
---@param labelWidth number? nested tab pages pass CONST.LABEL_WIDTH_NESTED
---@param spacing number?
---@return AMTOptionsContainer
function Options.NewContainer(parent, labelWidth, spacing)
	local container = setmetatable({
		children = {},
		widgets = {},
		nested = {},
		labelWidth = labelWidth or CONST.LABEL_WIDTH,
		spacing = spacing or CONST.ROW_SPACING,
	}, Container)

	container.frame = CreateFrame("Frame", nil, parent)
	container.frame:SetHeight(1)

	return container
end

function Container:Layout()
	if self.suspended then
		return
	end

	local offsetY = 0
	local shown = 0

	for _, child in ipairs(self.children) do
		if child:IsShown() then
			if shown > 0 then
				offsetY = offsetY + self.spacing
			end

			child:ClearAllPoints()
			child:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -offsetY)
			child:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -offsetY)

			offsetY = offsetY + child:GetHeight()
			shown = shown + 1
		end
	end

	self.frame:SetHeight(math.max(offsetY, 1))

	if self.onResized then
		self.onResized()
	end
end

---@param child Frame
---@return Frame
function Container:AddChild(child)
	self.children[#self.children + 1] = child

	self:Layout()

	return child
end

---@param nested AMTOptionsNestable
---@return AMTOptionsNestable
function Container:AddContainer(nested)
	nested.onResized = function()
		self:Layout()
	end

	self.nested[#self.nested + 1] = nested

	self:AddChild(nested.frame)

	return nested
end

---@param info AMTOptionInfo
---@return AMTOptionWidget?
function Container:AddWidget(info)
	local widget = Options.NewWidget(info.type, self.frame, self.labelWidth)

	if not widget then
		return nil
	end

	widget:Bind(info)

	self.widgets[#self.widgets + 1] = widget

	self:AddChild(widget.frame)

	return widget
end

---@param list AMTOptionInfo[]
---@return AMTOptionWidget[]
function Container:AddWidgets(list)
	local created = {}

	self.suspended = true

	for _, info in ipairs(list) do
		local widget = self:AddWidget(info)

		if widget then
			created[#created + 1] = widget
		end
	end

	self.suspended = false

	self:Layout()

	return created
end

function Container:Refresh()
	self.suspended = true

	for _, widget in ipairs(self.widgets) do
		widget:Update()
	end

	for _, nested in ipairs(self.nested) do
		nested:Refresh()
	end

	self.suspended = false

	self:Layout()
end

function Container:Clear()
	for _, child in ipairs(self.children) do
		child:Hide()
		child:SetParent(nil)
	end

	self.children = {}
	self.widgets = {}
	self.nested = {}

	self:Layout()
end

---@param label string
---@param prefix string dotted path to a table matching AMTTextStyle
---@param hidden AMTOptionPredicate? applied to all three rows
---@return AMTOptionWidget[]
function Container:AddFontGroup(label, prefix, hidden)
	return self:AddWidgets({
		{ type = "media", label = label, path = prefix .. ".font", mediaType = "font", hidden = hidden },
		{ type = "slider", label = L["Size"], path = prefix .. ".size", min = 6, max = 32, step = 1, hidden = hidden },
		{
			type = "dropdown",
			label = L["Outline"],
			path = prefix .. ".outline",
			hidden = hidden,
			values = {
				{ "", L["None"] },
				{ "OUTLINE", L["Outline"] },
				{ "THICKOUTLINE", L["Thick outline"] },
				{ "MONOCHROME", L["Monochrome"] },
				{ "MONOCHROME, OUTLINE", L["Monochrome outline"] },
				{ "MONOCHROME, THICKOUTLINE", L["Monochrome thick outline"] },
				{ "SLUG", L["Slug"] },
				{ "SLUG, OUTLINE", L["Slug outline"] },
				{ "SLUG, THICKOUTLINE", L["Slug thick outline"] },
			},
		},
	})
end
