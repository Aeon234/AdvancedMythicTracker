local AMT = select(2, ...)

local Options = AMT.Options

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

	self.note = self.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")

	self.note:SetPoint("TOPLEFT", self.frame, "TOPLEFT", self:GetControlOffset(), 0)
	self.note:SetPoint("RIGHT", self.frame, "RIGHT", 0, 0)
	self.note:SetJustifyH("LEFT")
	self.note:SetWordWrap(true)
	self.note:SetTextColor(MUTED_ORANGE[1], MUTED_ORANGE[2], MUTED_ORANGE[3])
end

function Note:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	self.note:SetText(info.text or info.label or "")
	self.frame:SetHeight(math.max(self.note:GetStringHeight(), MIN_HEIGHT))

	-- The label column stays empty: a note is the row, not an annotation on one.
	self.label:SetText("")
end
