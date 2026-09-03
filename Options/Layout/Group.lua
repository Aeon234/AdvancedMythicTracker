local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local HEADER_HEIGHT = 42
local HEADER_INSET = 14
local BODY_INSET = 16
local BODY_PADDING = 14
local CHEVRON_SIZE = 14
local ENABLED_GAP = 14
local CHECKBOX_LABEL_GAP = 8
local ANIM_DURATION = 0.3

local BODY_OVERLAP = 12

---@class AMTOptionsGroupConfig
---@field title string
---@field expanded boolean? starts open; defaults to false
---@field enabledPath string? omit for a header with no checkbox
---@field enabledScope AMTBindingScope?
---@field labelWidth number? label column for rows built in the body

---@class AMTOptionsGroup
---@field frame Frame
---@field header Button
---@field body Frame
---@field content AMTOptionsContainer
---@field chevron Texture
---@field checkbox Button?
---@field checkTick Texture?
---@field config AMTOptionsGroupConfig
---@field expanded boolean
---@field progress number 0 collapsed, 1 expanded; drives the chevron mid-slide
---@field animTo number?
---@field animToProgress number?
---@field onResized fun()?
local Group = {}
Group.__index = Group
Options.Group = Group

---@return number
function Group:GetExpandedHeight()
	return HEADER_HEIGHT + BODY_PADDING + math.max(self.content.frame:GetHeight(), 1) + BODY_PADDING
end

---@param height number
---@param progress number
function Group:ApplyHeight(height, progress)
	self.progress = progress
	self.frame:SetHeight(height)

	self.chevron:SetRotation(-progress * math.pi / 2)

	self.body:SetShown(height > HEADER_HEIGHT + 1)

	if self.onResized then
		self.onResized()
	end
end

function Group:UpdateHeight()
	local target = self.expanded and self:GetExpandedHeight() or HEADER_HEIGHT

	if self.frame:GetScript("OnUpdate") then
		self.animTo = target

		return
	end

	self:ApplyHeight(target, self.expanded and 1 or 0)
end

---@return boolean
function Group:IsExpanded()
	return self.expanded
end

---@param expanded boolean
---@param instant boolean?
function Group:SetExpanded(expanded, instant)
	self.expanded = expanded and true or false

	local target = self.expanded and self:GetExpandedHeight() or HEADER_HEIGHT

	if instant then
		AMT.Animation.Stop(self.frame)
		self:ApplyHeight(target, self.expanded and 1 or 0)

		return
	end

	self.body:Show()

	local fromHeight = self.frame:GetHeight()
	local fromProgress = self.progress

	self.animTo = target
	self.animToProgress = self.expanded and 1 or 0

	AMT.Animation.Run(self.frame, ANIM_DURATION, function(eased)
		self:ApplyHeight(
			fromHeight + ((self.animTo or target) - fromHeight) * eased,
			fromProgress + ((self.animToProgress or 0) - fromProgress) * eased
		)
	end)
end

function Group:Toggle()
	self:SetExpanded(not self.expanded)
end

---@return boolean
function Group:IsEnabled()
	local path = self.config.enabledPath

	return path == nil or Options.Get(path, self.config.enabledScope) == true
end

function Group:Refresh()
	if self.checkTick then
		self.checkTick:SetShown(self:IsEnabled())
	end

	self.content:Refresh()
	self:UpdateHeight()
end

---@param parent Frame
---@param config AMTOptionsGroupConfig
---@return AMTOptionsGroup
function Options.NewGroup(parent, config)
	local group = setmetatable({ config = config, expanded = false, progress = 0 }, Group)

	group.frame = CreateFrame("Frame", nil, parent)

	local header = CreateFrame("Button", nil, group.frame)

	header:SetHeight(HEADER_HEIGHT)
	header:SetPoint("TOPLEFT", group.frame, "TOPLEFT", 0, 0)
	header:SetPoint("TOPRIGHT", group.frame, "TOPRIGHT", 0, 0)
	header:RegisterForClicks("LeftButtonUp")

	AMT.NineSlice.Apply(header, "Control", CONST.CORNER_SIZE)

	local hover = AMT.NineSlice.Apply(header, "Hover", CONST.CORNER_SIZE, "OVERLAY")

	if hover then
		hover:SetShown(false)
	end

	local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	title:SetPoint("LEFT", header, "LEFT", HEADER_INSET, 0)
	title:SetText(config.title)
	title:SetTextColor(1, 1, 1)

	group.chevron = header:CreateTexture(nil, "ARTWORK")
	group.chevron:SetSize(CHEVRON_SIZE, CHEVRON_SIZE)
	group.chevron:SetPoint("RIGHT", header, "RIGHT", -HEADER_INSET, 0)
	group.chevron:SetTexture(AMT.NineSlice.Path("Chevron"))
	group.chevron:SetVertexColor(0.8, 0.8, 0.8)

	group.header = header

	if config.enabledPath then
		local control, tick = Options.CreateCheckboxControl(group.frame, function()
			Options.Set(config.enabledPath, not group:IsEnabled(), config.enabledScope)
			Options.NotifyValueChanged()
		end)

		local label = control:CreateFontString(nil, "ARTWORK", "GameFontNormal")

		label:SetPoint("LEFT", control, "RIGHT", CHECKBOX_LABEL_GAP, 0)
		label:SetText(AMT.L["Enabled"])
		label:SetTextColor(1, 1, 1)

		local reserve = label:GetStringWidth() + CHECKBOX_LABEL_GAP

		control:SetPoint("RIGHT", group.chevron, "LEFT", -(ENABLED_GAP + reserve), 0)

		group.checkbox = control
		group.checkTick = tick
	end

	local body = CreateFrame("Frame", nil, group.frame)

	body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, BODY_OVERLAP)
	body:SetPoint("BOTTOMRIGHT", group.frame, "BOTTOMRIGHT", 0, 0)
	body:SetClipsChildren(true)
	body:Hide()

	AMT.NineSlice.Apply(body, "Inset", CONST.CORNER_SIZE)

	group.body = body

	header:SetFrameLevel(body:GetFrameLevel() + 5)

	if group.checkbox then
		group.checkbox:SetFrameLevel(body:GetFrameLevel() + 6)
	end

	local content = Options.NewContainer(body, config.labelWidth)

	content.frame:SetPoint("TOPLEFT", body, "TOPLEFT", BODY_INSET, -(BODY_PADDING + BODY_OVERLAP))
	content.frame:SetPoint("TOPRIGHT", body, "TOPRIGHT", -BODY_INSET, -(BODY_PADDING + BODY_OVERLAP))
	content.onResized = function()
		group:UpdateHeight()
	end

	group.content = content

	header:SetScript("OnEnter", function()
		if hover then
			hover:SetShown(true)
		end
	end)

	header:SetScript("OnLeave", function()
		if hover then
			hover:SetShown(false)
		end
	end)

	header:SetScript("OnClick", function()
		group:Toggle()
	end)

	group:SetExpanded(config.expanded == true, true)

	if group.checkTick then
		group.checkTick:SetShown(group:IsEnabled())
	end

	return group
end
