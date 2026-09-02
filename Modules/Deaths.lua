local AMT = select(2, ...)

local SKULL = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]]
local ICON_GAP = 4
local RED = { 1, 0.2, 0.2, 1 }

---@class AMTDeathsModule : AMTModule
---@field element Frame
---@field row Frame
---@field icon Texture
---@field text AMTTextMixin
local module = AMT.Modules.New("Deaths")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))
	self.element:SetMouseMotionEnabled(true)

	self.element:SetScript("OnEnter", function()
		AMT.Tooltip.ShowDeaths(self.element)
	end)

	self.element:SetScript("OnLeave", function()
		AMT.Tooltip.Hide()
	end)

	self.row = CreateFrame("Frame", nil, self.element)

	self.icon = self.row:CreateTexture(nil, "ARTWORK")
	self.icon:SetPoint("LEFT", self.row, "LEFT", 0, 0)

	self.text = AMT.Mixins.NewText(self.row)

	AMT.Layout.RegisterElement("keyInfo", "deaths", self.element)

	AMT.Render.Register("deaths", function()
		self:Render()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer.deaths

	self.element:SetHeight(profile.height)
	self.icon:SetSize(profile.iconSize, profile.iconSize)
	self.text:ApplyStyle(profile.text)

	AMT.State.MarkDirty("deaths")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

---@return string
function module:FormatText()
	local profile = AMT.Profiles.active.timer.deaths
	local state = AMT.State.current
	local text = ""

	if profile.label == "TEXT" then
		text = ("%s %d"):format(DEATHS, state.deathCount)
	elseif profile.label == "SKULL" then
		text = tostring(state.deathCount)
	end

	if profile.penalty and state.deathTimeLost > 0 then
		local open = profile.brackets == "SQUARE" and "[" or "("
		local close = profile.brackets == "SQUARE" and "]" or ")"
		local penalty = ("%s-%ds%s"):format(open, state.deathTimeLost, close)

		text = text ~= "" and (text .. " " .. penalty) or penalty
	end

	return text
end

function module:Render()
	local profile = AMT.Profiles.active.timer.deaths
	local text = self:FormatText()

	if text == "" then
		self.row:Hide()
		AMT.Layout.SetCollapsed("deaths", true)

		return
	end

	AMT.Layout.SetCollapsed("deaths", false)

	local showIcon = profile.label == "SKULL"

	self.text:SetText(text)
	self.text:SetColor(profile.red and RED or profile.text.color)

	self.text:ClearAllPoints()

	if showIcon then
		self.text:SetPoint("LEFT", self.icon, "RIGHT", ICON_GAP, 0)
	else
		self.text:SetPoint("LEFT", self.row, "LEFT", 0, 0)
	end

	self.icon:SetTexture(SKULL)
	self.icon:SetShown(showIcon)

	local width = self.text:GetStringWidth() + (showIcon and profile.iconSize + ICON_GAP or 0)

	self.row:SetSize(width, profile.height)
	self.row:ClearAllPoints()
	self.row:SetPoint(profile.justify, self.element, profile.justify, 0, 0)
	self.row:Show()
end
