local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local ITEM_GAP = 12

---@class AMTRowItem
---@field widget AMTOptionWidget
---@field info AMTOptionInfo

---@class AMTRowWidget : AMTOptionWidget
---@field items AMTOptionWidget[]
local Row = Options.NewWidgetPrototype("row")

---@param parent Frame
function Row:Create(parent)
	Options.Widget.Create(self, parent)

	self.items = {}
end

---@param index integer
---@param info AMTOptionInfo
---@return AMTOptionWidget?
function Row:AcquireItem(index, info)
	local widget = self.items[index]

	if widget then
		return widget
	end

	widget = Options.NewWidget(info.type, self.frame, info.labelWidth or 0)

	if widget then
		self.items[index] = widget
	end

	return widget
end

---@param visible AMTRowItem[]
function Row:AnchorItems(visible)
	local left = self:GetControlOffset()
	local right = 0

	for _, entry in ipairs(visible) do
		local frame = entry.widget.frame

		frame:ClearAllPoints()

		if entry.info.align == "RIGHT" then
			frame:SetPoint("RIGHT", self.frame, "RIGHT", -right, 0)

			right = right + frame:GetWidth() + ITEM_GAP
		else
			frame:SetPoint("LEFT", self.frame, "LEFT", left, 0)

			left = left + frame:GetWidth() + ITEM_GAP
		end
	end
end

function Row:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	---@type AMTRowItem[]
	local visible = {}
	local height = 0

	for index, item in ipairs(info.items or {}) do
		if item.type == "row" then
			AMT.Util.Warn("row item %d is itself a row; rows do not nest.", index)
		else
			local widget = self:AcquireItem(index, item)

			if widget then
				if widget.info ~= item then
					widget:Bind(item)
				else
					widget:Update()
				end

				height = math.max(height, widget:GetControlHeight())

				if widget.frame:IsShown() then
					widget.frame:SetWidth(item.width or CONST.LABEL_WIDTH)

					visible[#visible + 1] = { widget = widget, info = item }
				end
			end
		end
	end

	if #visible == 0 then
		self.frame:Hide()

		return
	end

	self:AnchorItems(visible)
	self.frame:SetHeight(height + CONST.CORNER_SIZE)
end
