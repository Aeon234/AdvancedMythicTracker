local AMT = select(2, ...)

---@class AMTKeyInfoModule : AMTModule
---@field element Frame
---@field name AMTTextMixin
---@field level AMTTextMixin
---@field affixElement Frame
---@field affixRow Frame
---@field affixIcons Texture[]
---@field affixText AMTTextMixin
local module = AMT.Modules.New("KeyInfo")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))

	self.name = AMT.Mixins.NewText(self.element)
	self.name:SetPoint("LEFT", self.element, "LEFT", 0, 0)

	self.level = AMT.Mixins.NewText(self.element)
	self.level:SetPoint("RIGHT", self.element, "RIGHT", 0, 0)

	AMT.Layout.RegisterElement("keyInfo", "keyInfoTitle", self.element)

	self.affixElement = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))
	self.affixRow = CreateFrame("Frame", nil, self.affixElement)
	self.affixIcons = {}
	self.affixText = AMT.Mixins.NewText(self.affixElement)

	AMT.Layout.RegisterElement("keyInfo", "keyInfoAffixes", self.affixElement)

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

	local text = "+" .. level

	if AMT.Profiles.active.timer.keyInfo.colorLevel then
		return C_ChallengeMode.GetKeystoneLevelRarityColor(level):WrapTextInColorCode(text)
	end

	return text
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

		return
	end

	self.affixRow:SetSize(shown * size + (shown - 1) * profile.spacing, size)
	self.affixRow:ClearAllPoints()
	self.affixRow:SetPoint(profile.justify, self.affixElement, profile.justify, 0, 0)
	self.affixRow:Show()
end

function module:Render()
	local state = AMT.State.current
	local profile = AMT.Profiles.active.timer.keyInfo

	---@type string?
	local mapName = state.mapID and C_ChallengeMode.GetMapUIInfo(state.mapID)
	local levelText = profile.showLevel and self:FormatLevel() or ""

	mapName = mapName or UNKNOWN

	if profile.combineLevel then
		self.name:SetText(levelText ~= "" and (mapName .. " " .. levelText) or mapName)
		self.level:Hide()
	else
		self.name:SetText(mapName)
		self.level:SetText(levelText)
		self.level:SetShown(levelText ~= "")
	end

	self:RenderAffixes()
end
