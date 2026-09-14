local AMT = select(2, ...)

local Dashboard = AMT.Dashboard

local CROP_MIN, CROP_MAX = 0.07, 0.93
local FALLBACK_TEXTURE = 134400

---@alias AMTDashboardIconKind "Frame"|"Button"|"Action"

---@class AMTDashboardIconMixin : Frame
---@field kind AMTDashboardIconKind
---@field iconTexture Texture
---@field border AMTBorder?
local Icon = {}
Dashboard.IconMixin = Icon

---@param kind AMTDashboardIconKind
---@param size number
---@param corner number
function Icon:OnLoad(kind, size, corner)
	self.kind = kind

	self:SetSize(size, size)

	self.iconTexture = self:CreateTexture(nil, "ARTWORK")
	self.iconTexture:SetAllPoints()
	self.iconTexture:SetTexCoord(CROP_MIN, CROP_MAX, CROP_MIN, CROP_MAX)
	self.iconTexture:SetTexture(FALLBACK_TEXTURE)

	self.border = AMT.NineSlice.Apply(self, "Ring", corner, "OVERLAY")

	Dashboard.Skin:Register(self, "Ring")
end

---@param texture number|string|nil
function Icon:SetIcon(texture)
	self.iconTexture:SetTexture(texture or FALLBACK_TEXTURE)
end

---@param desaturated boolean
function Icon:SetIconDesaturated(desaturated)
	self.iconTexture:SetDesaturated(desaturated)
end

---@param shown boolean
function Icon:SetBorderShown(shown)
	if self.border then
		self.border:SetShown(shown)
	end
end

---@param spellID number
function Icon:SetSpell(spellID)
	if self.kind ~= "Action" then
		AMT.Util.Warn("icon of kind %q cannot cast; construct it as Action.", self.kind)

		return
	end

	self:SetAttribute("type", "spell")
	self:SetAttribute("spell", spellID)
end

---@param parent Frame
---@param kind AMTDashboardIconKind
---@param size number
---@param corner number
---@return AMTDashboardIconMixin
function Dashboard.NewIcon(parent, kind, size, corner)
	---@type Frame
	local frame

	if kind == "Action" then
		local button = CreateFrame("Button", nil, parent, "InsecureActionButtonTemplate")

		button:RegisterForClicks("AnyUp", "AnyDown")
		frame = button
	elseif kind == "Button" then
		frame = CreateFrame("Button", nil, parent)
	else
		frame = CreateFrame("Frame", nil, parent)
	end

	Mixin(frame, Icon)
	frame:OnLoad(kind, size, corner)

	return frame
end
