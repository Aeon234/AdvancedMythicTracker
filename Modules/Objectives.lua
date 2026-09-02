local AMT = select(2, ...)

local ICON_DONE = [[Interface\RaidFrame\ReadyCheck-Ready]]
local ICON_PENDING = [[Interface\RaidFrame\ReadyCheck-Waiting]]

---@class AMTObjectiveRow : Frame
---@field icon Texture
---@field name AMTTextMixin
---@field time AMTTextMixin

---@class AMTObjectivesModule : AMTModule
---@field element Frame
---@field rows AMTObjectiveRow[]
local module = AMT.Modules.New("Objectives")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("objectives"))
	self.element:SetHeight(1)
	self.rows = {}

	AMT.Layout.RegisterElement("objectives", "objectiveRows", self.element)

	AMT.Render.Register("objectives", function()
		self:Render()
	end)
end

---@param index integer
---@return AMTObjectiveRow
function module:AcquireRow(index)
	local row = self.rows[index]

	if row then
		return row
	end

	row = CreateFrame("Frame", nil, self.element) --[[@as AMTObjectiveRow]]
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)
	row.name = AMT.Mixins.NewText(row)
	row.time = AMT.Mixins.NewText(row)
	row.time:SetPoint("RIGHT", row, "RIGHT", 0, 0)

	self.rows[index] = row

	self:StyleRow(row)

	return row
end

---@param row AMTObjectiveRow
function module:StyleRow(row)
	local profile = AMT.Profiles.active.timer.objectives

	row.icon:SetSize(profile.iconSize, profile.iconSize)
	row.name:ApplyStyle(profile.text)
	row.time:ApplyStyle(profile.time)

	row.name:ClearAllPoints()

	if profile.icon then
		row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	else
		row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
	end
end

function module:ApplyStyle()
	for _, row in ipairs(self.rows) do
		self:StyleRow(row)
	end

	AMT.State.MarkDirty("objectives")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local profile = AMT.Profiles.active.timer.objectives
	local objectives = AMT.State.current.objectives
	local spacing = profile.spacing
	local y = 0

	for index, objective in ipairs(objectives) do
		local row = self:AcquireRow(index)
		local done = objective.completedAtMS ~= nil

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", self.element, "TOPLEFT", 0, -y)
		row:SetPoint("TOPRIGHT", self.element, "TOPRIGHT", 0, -y)
		row:SetHeight(profile.rowHeight)

		row.icon:SetTexture(done and ICON_DONE or ICON_PENDING)
		row.icon:SetShown(profile.icon)

		row.name:SetText(objective.name or objective.description)
		row.name:SetColor(done and profile.completedColor or profile.pendingColor)

		if done and profile.showTime then
			row.time:SetText(AMT.Util.FormatTime(objective.completedAtMS / 1000))
			row.time:Show()
		else
			row.time:Hide()
		end

		row:Show()

		y = y + profile.rowHeight + spacing
	end

	for index = #objectives + 1, #self.rows do
		self.rows[index]:Hide()
	end

	local height = math.max(y - spacing, 1)

	if height ~= self.element:GetHeight() then
		self.element:SetHeight(height)
		AMT.State.MarkDirty("layout")
	end
end
