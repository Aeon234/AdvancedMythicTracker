local AMT = select(2, ...)

local TITLE_GAP = 4

---@class AMTKeyInfoModule : AMTModule
---@field element Frame
---@field titleRow Frame
---@field name AMTTextMixin
---@field level AMTTextMixin
---@field affixElement Frame
---@field affixRow Frame
---@field affixIcons Texture[]
---@field affixText AMTTextMixin
---@field widths table<string, number>
local module = AMT.Modules.New("KeyInfo")

module.widths = {}

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))
	self.titleRow = CreateFrame("Frame", nil, self.element)

	self.name = AMT.Mixins.NewText(self.titleRow)
	self.level = AMT.Mixins.NewText(self.titleRow)

	self.element.GetContentWidth = function()
		return self.widths.keyInfoTitle or 0
	end

	AMT.Layout.RegisterElement("keyInfo", "keyInfoTitle", self.element, "LEFT")

	self.affixElement = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))
	self.affixRow = CreateFrame("Frame", nil, self.affixElement)
	self.affixIcons = {}
	self.affixText = AMT.Mixins.NewText(self.affixElement)

	self.affixElement.GetContentWidth = function()
		return self.widths.keyInfoAffixes or 0
	end

	AMT.Layout.RegisterElement("keyInfo", "keyInfoAffixes", self.affixElement, "CENTER")

	AMT.Render.Register("keyInfo", function()
		self:Render()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local timer = AMT.Profiles.active.timer
	local profile = timer.keyInfo
	local affixes = timer.affixes

	self.element:SetHeight(profile.height)
	self.name:ApplyStyle(profile.text)
	self.level:ApplyStyle(profile.level)

	self.affixElement:SetHeight(affixes.height)
	self.affixText:ApplyStyle(affixes.text)
	self.affixText:ClearAllPoints()
	self.affixText:SetPoint(affixes.justify, self.affixElement, affixes.justify, 0, 0)

	self:RenderAffixes()

	AMT.State.MarkDirty("layout")
end

function module:OnProfileChanged()
	self:ApplyStyle()
end

---@return string
function module:FormatLevel()
	local level = AMT.State.current.level

	if level <= 0 then
		return ""
	end

	return "+" .. level
end

---@param key string
---@param width number
function module:SetContentWidth(key, width)
	if self.widths[key] == width then
		return
	end

	self.widths[key] = width

	AMT.State.MarkDirty("layout")
end

---@param index integer
---@return Texture
function module:AcquireAffixIcon(index)
	local icon = self.affixIcons[index]

	if not icon then
		icon = self.affixRow:CreateTexture(nil, "ARTWORK")
		self.affixIcons[index] = icon
	end

	return icon
end

function module:RenderAffixes()
	local profile = AMT.Profiles.active.timer.affixes
	local ids = AMT.State.current.affixIDs

	if profile.widget == "TEXT" then
		local parts = {}

		for _, affixID in ipairs(ids) do
			---@type string?
			local name = C_ChallengeMode.GetAffixInfo(affixID)

			if name then
				parts[#parts + 1] = AMT.Locale.FormatAffixName(name)
			end
		end

		self.affixText:SetText(table.concat(parts, profile.separator))
		self.affixText:SetShown(#parts > 0)
		self.affixRow:Hide()

		self:SetContentWidth("keyInfoAffixes", #parts > 0 and self.affixText:GetStringWidth() or 0)

		return
	end

	self.affixText:Hide()

	local size = profile.iconSize
	local shown = 0
	local previous

	for _, affixID in ipairs(ids) do
		---@type integer?
		local fileID = select(3, C_ChallengeMode.GetAffixInfo(affixID))

		if fileID then
			shown = shown + 1

			local icon = self:AcquireAffixIcon(shown)

			icon:SetTexture(fileID)
			icon:SetSize(size, size)
			icon:ClearAllPoints()

			if previous then
				icon:SetPoint("LEFT", previous, "RIGHT", profile.spacing, 0)
			else
				icon:SetPoint("LEFT", self.affixRow, "LEFT", 0, 0)
			end

			icon:Show()

			previous = icon
		end
	end

	for index = shown + 1, #self.affixIcons do
		self.affixIcons[index]:Hide()
	end

	if shown == 0 then
		self.affixRow:Hide()
		self:SetContentWidth("keyInfoAffixes", 0)

		return
	end

	local width = shown * size + (shown - 1) * profile.spacing

	self:SetContentWidth("keyInfoAffixes", width)
	self.affixRow:SetSize(width, size)
	self.affixRow:ClearAllPoints()
	self.affixRow:SetPoint(profile.justify, self.affixElement, profile.justify, 0, 0)
	self.affixRow:Show()
end

function module:LayoutTitle()
	local profile = AMT.Profiles.active.timer.keyInfo
	local parts = {}

	if profile.order == "LEVEL_FIRST" then
		parts[1] = self.level:IsShown() and self.level or nil
		parts[#parts + 1] = self.name:IsShown() and self.name or nil
	else
		parts[1] = self.name:IsShown() and self.name or nil
		parts[#parts + 1] = self.level:IsShown() and self.level or nil
	end

	local width = 0
	local previous

	for _, part in ipairs(parts) do
		part:ClearAllPoints()

		if previous then
			part:SetPoint("LEFT", previous, "RIGHT", TITLE_GAP, 0)

			width = width + TITLE_GAP
		else
			part:SetPoint("LEFT", self.titleRow, "LEFT", 0, 0)
		end

		width = width + part:GetStringWidth()
		previous = part
	end

	self:SetContentWidth("keyInfoTitle", width)

	self.titleRow:SetSize(math.max(width, 1), profile.height)
	self.titleRow:ClearAllPoints()
	self.titleRow:SetPoint("LEFT", self.element, "LEFT", 0, 0)
	self.titleRow:SetShown(#parts > 0)

	AMT.Layout.SetCollapsed("keyInfoTitle", #parts == 0)
end

function module:Render()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer.keyInfo

	---@type string?
	local mapName = state.mapID and C_ChallengeMode.GetMapUIInfo(state.mapID)
	local levelText = self:FormatLevel()

	mapName = mapName or UNKNOWN

	self.name:SetText(mapName)
	self.name:SetShown(profile.show ~= "LEVEL")

	self.level:SetText(levelText)
	self.level:SetShown(profile.show ~= "NAME" and levelText ~= "")

	self:LayoutTitle()
	self:RenderAffixes()
end
