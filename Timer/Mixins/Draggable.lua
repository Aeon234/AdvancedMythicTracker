local AMT = select(2, ...)

---@alias AMTAnchorPoint
---| "TOPLEFT" | "TOP" | "TOPRIGHT"
---| "LEFT" | "CENTER" | "RIGHT"
---| "BOTTOMLEFT" | "BOTTOM" | "BOTTOMRIGHT"

---@class AMTFramePosition
---@field anchor FramePoint
---@field x number
---@field y number

---@class AMTDraggableMixin : Frame
---@field OnPositionChanged fun(self: AMTDraggableMixin, position: AMTFramePosition)?
local Draggable = {}
AMT.Mixins.Draggable = Draggable

---@param frame Frame
---@return number
local function ScaleRatio(frame)
	return frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
end

function Draggable:OnLoad()
	self:SetClampedToScreen(true)
	self:RegisterForDrag("LeftButton")

	self:SetScript("OnDragStart", self.StartMoving)

	self:SetScript("OnDragStop", function()
		self:StopMovingOrSizing()
		self:SavePosition()
	end)
end

---@param unlocked boolean
function Draggable:SetUnlocked(unlocked)
	self:SetMovable(unlocked)
	self:EnableMouse(unlocked)
end

function Draggable:SavePosition()
	local anchor, _, _, x, y = self:GetPoint(1)
	local ratio = ScaleRatio(self)

	if self.OnPositionChanged then
		self:OnPositionChanged({
			anchor = anchor,
			x = Round(x * ratio),
			y = Round(y * ratio),
		})
	end
end

---@param position AMTFramePosition
function Draggable:ApplyPosition(position)
	local ratio = ScaleRatio(self)

	self:ClearAllPoints()
	self:SetPoint(position.anchor, UIParent, position.anchor, position.x / ratio, position.y / ratio)
end

---@param frame Frame
---@return AMTDraggableMixin
function AMT.Mixins.MakeDraggable(frame)
	Mixin(frame, Draggable)
	frame:OnLoad()

	return frame
end
