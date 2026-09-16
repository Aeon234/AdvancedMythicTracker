local AMT = select(2, ...)
local L = AMT.L

local SKULL = [[Interface\TargetingFrame\UI-RaidTargetingIcon_8]]

---@class AMTDeathsModule : AMTModule
---@field element Frame
---@field row Frame
---@field text AMTTextMixin
---@field width number
local module = AMT.Modules.New("Deaths")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))

	-- The element spans the frame; the row is only as wide as the count and its icon.
	self.row = CreateFrame("Frame", nil, self.element)
	self.row:SetMouseMotionEnabled(true)

	self.row:SetScript("OnEnter", function()
		if AMT.Profiles.active.timer.deaths.tooltip then
			AMT.Tooltip.ShowDeaths(self.row)
		end
	end)

	self.row:SetScript("OnLeave", function()
		AMT.Tooltip.Hide()
	end)

	self.text = AMT.Mixins.NewText(self.row)
	self.width = 0

	self.element.GetContentWidth = function()
		return self.width
	end

	AMT.Layout.RegisterElement("keyInfo", "deaths", self.element, "RIGHT", L["Deaths"])

	AMT.Render.Register("deaths", function()
		self:Render()
	end)

	self:ApplyStyle()
end

local function UpdateDeaths()
	AMT.Providers.active.UpdateDeaths()
end

---@param guid string
local function OnUnitDied(_, _, guid)
	AMT.Deaths.RecordDeath(guid)
end

function module:OnChallengeStart()
	AMT.Deaths.SnapshotParty()

	AMT.Events.RegisterChallenge("CHALLENGE_MODE_DEATH_COUNT_UPDATED", self, UpdateDeaths)
	AMT.Events.RegisterChallenge("UNIT_DIED", self, OnUnitDied)

	UpdateDeaths()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer.deaths

	self.element:SetHeight(profile.height)
	self.text:ApplyStyle(profile.text)

	AMT.State.MarkDirty("deaths")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

---@param width number
function module:SetContentWidth(width)
	if self.width == width then
		return
	end

	self.width = width

	AMT.State.MarkDirty("layout")
end

---@return string
function module:FormatText()
	local profile = AMT.Profiles.active.timer.deaths
	local state = AMT.State.current
	local text = ""

	if profile.label == "TEXT" then
		text = ("%d %s"):format(state.deathCount, DEATHS)
	elseif profile.label == "SKULL" then
		text = tostring(state.deathCount)
	end

	if profile.penalty and state.deathTimeLost > 0 then
		local open = profile.brackets == "SQUARE" and "[" or "("
		local close = profile.brackets == "SQUARE" and "]" or ")"
		local sign = AMT.Profiles.active.timer.direction == "UP" and "+" or "-"
		local penalty = ("%s%s%ds%s"):format(open, sign, state.deathTimeLost, close)

		text = text ~= "" and (text .. " " .. penalty) or penalty
	end

	if text ~= "" and profile.label == "SKULL" then
		text = ("%s |T%s:0:0:0:%d|t"):format(text, SKULL, profile.iconOffset)
	end

	return text
end

function module:Render()
	local profile = AMT.Profiles.active.timer.deaths
	local text = self:FormatText()

	if text == "" then
		self.row:Hide()
		self:SetContentWidth(0)
		AMT.Layout.SetCollapsed("deaths", true)

		return
	end

	AMT.Layout.SetCollapsed("deaths", false)

	self.text:SetText(text)

	self.text:ClearAllPoints()
	self.text:SetPoint("LEFT", self.row, "LEFT", 0, 0)

	local width = self.text:GetStringWidth()

	self:SetContentWidth(width)
	self.row:SetSize(width, profile.height)
	self.row:ClearAllPoints()
	local justify = AMT.Layout.GetJustify("deaths")

	self.row:SetPoint(justify, self.element, justify, 0, 0)
	self.row:Show()
end
