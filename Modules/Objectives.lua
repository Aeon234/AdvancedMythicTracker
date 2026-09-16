local AMT = select(2, ...)
local L = AMT.L

local ICON_DONE = [[Interface\RaidFrame\ReadyCheck-Ready]]
local ICON_PENDING = [[Interface\RaidFrame\ReadyCheck-Waiting]]
local ROW_GAP = 4

---@class AMTObjectiveRow : Frame
---@field icon Texture
---@field name AMTTextMixin
---@field time AMTTextMixin
---@field split AMTTextMixin

---@class AMTObjectivesModule : AMTModule
---@field element Frame
---@field rows AMTObjectiveRow[]
local module = AMT.Modules.New("Objectives")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("objectives"))
	self.element:SetHeight(1)
	self.rows = {}

	AMT.Layout.RegisterElement("objectives", "objectiveRows", self.element, nil, L["Boss List"])

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
	row.name = AMT.Mixins.NewText(row)
	row.name:SetWordWrap(false)
	row.time = AMT.Mixins.NewText(row)
	row.split = AMT.Mixins.NewText(row)

	self.rows[index] = row

	self:StyleRow(row)

	return row
end

---@param row AMTObjectiveRow
function module:StyleRow(row)
	local timer = AMT.Profiles.active.timer
	local profile = timer.objectives
	local justify = timer.justify

	row.icon:SetSize(profile.iconSize, profile.iconSize)
	row.name:ApplyStyle(profile.text)
	row.time:ApplyStyle(profile.time)
	row.split:ApplyStyle(timer.splits.bossSplit.text)
end

local function UpdateObjectives()
	AMT.Providers.active.UpdateObjectives()
end

function module:OnChallengeStart()
	AMT.Events.RegisterChallenge("SCENARIO_CRITERIA_UPDATE", self, UpdateObjectives)
	AMT.Events.RegisterChallenge("SCENARIO_POI_UPDATE", self, UpdateObjectives)

	-- A /reload mid-key starts here with bosses already down.
	UpdateObjectives()
end

function module:ApplyStyle()
	for _, row in ipairs(self.rows) do
		self:StyleRow(row)
	end

	AMT.State.MarkDirty("objectives")
end

---@param row AMTObjectiveRow
---@param diffMS integer?
function module:RenderSplit(row, diffMS)
	local profile = AMT.Profiles.active.timer.splits

	if not diffMS then
		row.split:Hide()

		return
	end

	row.split:SetText(AMT.Util.FormatTime(diffMS / 1000, profile.decimals, true))
	row.split:SetColor(AMT.Util.SplitColor(profile, AMT.Splits.Classify(diffMS)))
	row.split:Show()
end

---Panel and Aeon span the frame: the icon leads, the name takes the slack, and the times sit at the
---far edge.
---@param row AMTObjectiveRow
function module:LayoutSpanRow(row)
	local profile = AMT.Profiles.active.timer.objectives
	local available = self.element:GetWidth()
	local reserved = 0

	row.name:SetJustifyH("LEFT")
	row.icon:ClearAllPoints()
	row.icon:SetPoint("LEFT", row, "LEFT", 0, 0)

	row.name:ClearAllPoints()

	if profile.icon then
		row.name:SetPoint("LEFT", row.icon, "RIGHT", ROW_GAP, 0)

		reserved = reserved + profile.iconSize + ROW_GAP
	else
		row.name:SetPoint("LEFT", row, "LEFT", 0, 0)
	end

	row.split:ClearAllPoints()
	row.split:SetPoint("RIGHT", row, "RIGHT", 0, 0)

	row.time:ClearAllPoints()

	if row.split:IsShown() then
		row.time:SetPoint("RIGHT", row.split, "LEFT", -ROW_GAP, 0)

		reserved = reserved + row.split:GetStringWidth() + ROW_GAP
	else
		row.time:SetPoint("RIGHT", row, "RIGHT", 0, 0)
	end

	if row.time:IsShown() then
		reserved = reserved + row.time:GetStringWidth() + ROW_GAP
	end

	row.name:SetWidth(math.max(available - reserved, 1))
end

---Minimal is one packed run flush to the alignment edge, and the order mirrors with it: icon, name,
---split, time going left; split, time, name, icon going right. Only the name gives ground when the
---run does not fit.
---@param row AMTObjectiveRow
function module:LayoutRow(row)
	local timer = AMT.Profiles.active.timer
	local justify = timer.justify

	if timer.style ~= "MINIMAL" then
		self:LayoutSpanRow(row)

		return
	end

	row.name:SetJustifyH(justify)
	local available = self.element:GetWidth()
	local parts = {}

	local function Add(region, width)
		if region:IsShown() then
			parts[#parts + 1] = { region = region, width = width }
		end
	end

	if justify == "RIGHT" then
		Add(row.split, row.split:GetStringWidth())
		Add(row.time, row.time:GetStringWidth())
		Add(row.name, 0)
		Add(row.icon, timer.objectives.iconSize)
	else
		Add(row.icon, timer.objectives.iconSize)
		Add(row.name, 0)
		Add(row.split, row.split:GetStringWidth())
		Add(row.time, row.time:GetStringWidth())
	end

	local spare = available - (#parts - 1) * ROW_GAP

	for _, part in ipairs(parts) do
		spare = spare - part.width
	end

	local nameWidth = math.max(math.min(row.name:GetStringWidth(), spare), 1)

	for _, part in ipairs(parts) do
		if part.region == row.name then
			part.width = nameWidth

			row.name:SetWidth(nameWidth)
		end

		part.region:ClearAllPoints()
	end

	local previous

	if justify == "RIGHT" then
		for index = #parts, 1, -1 do
			local region = parts[index].region

			if previous then
				region:SetPoint("RIGHT", previous, "LEFT", -ROW_GAP, 0)
			else
				region:SetPoint("RIGHT", row, "RIGHT", 0, 0)
			end

			previous = region
		end

		return
	end

	for _, part in ipairs(parts) do
		local region = part.region

		if previous then
			region:SetPoint("LEFT", previous, "RIGHT", ROW_GAP, 0)
		else
			region:SetPoint("LEFT", row, "LEFT", 0, 0)
		end

		previous = region
	end
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

function module:Render()
	local profile = AMT.Profiles.active.timer.objectives
	local objectives = AMT.State.current.objectives
	local spacing = profile.spacing
	local y = 0

	local splits = AMT.Profiles.active.timer.splits
	local showSplits = splits.bossSplit.enabled and (splits.boss == "ALWAYS" or AMT.State.current.challengeCompleted)

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

		self:RenderSplit(row, showSplits and AMT.Splits.BossDiffMS(index) or nil)
		self:LayoutRow(row)

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
