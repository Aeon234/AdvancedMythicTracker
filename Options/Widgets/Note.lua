local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local MIN_HEIGHT = 16
local MUTED_ORANGE = { 1, 0.65, 0.2 }

---@class AMTNoteWidget : AMTOptionWidget
---@field note FontString
local Note = Options.NewWidgetPrototype("note")

---@return number
function Note:GetControlHeight()
	return MIN_HEIGHT
end

---@param parent Frame
function Note:Create(parent)
	Options.Widget.Create(self, parent)

	self.note = self.frame:CreateFontString(nil, "ARTWORK", CONST.FONT_BODY)

	self.note:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self:GetControlOffset(), 0)
	self.note:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
	self.note:SetJustifyH("LEFT")
	self.note:SetWordWrap(true)
end

function Note:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	local text = (info.get or info.path) and self:GetValue() or info.text

	self.note:SetText(text ~= nil and tostring(text) or "")

	local color = info.color or MUTED_ORANGE

	self.note:SetTextColor(color[1], color[2], color[3])
	self.frame:SetHeight(math.max(self.note:GetStringHeight(), MIN_HEIGHT))
	self.label:SetText("")
end
