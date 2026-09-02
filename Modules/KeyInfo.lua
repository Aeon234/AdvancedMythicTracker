local AMT = select(2, ...)

---@class AMTKeyInfoModule : AMTModule
---@field element Frame
---@field name AMTTextMixin
---@field level AMTTextMixin
local module = AMT.Modules.New("KeyInfo")

function module:OnInitialize()
	self.element = CreateFrame("Frame", nil, AMT.Layout.GetGroup("keyInfo"))

	self.name = AMT.Mixins.NewText(self.element)
	self.name:SetPoint("LEFT", self.element, "LEFT", 0, 0)

	self.level = AMT.Mixins.NewText(self.element)
	self.level:SetPoint("RIGHT", self.element, "RIGHT", 0, 0)

	AMT.Layout.RegisterElement("keyInfo", "keyInfoTitle", self.element)

	AMT.Render.Register("keyInfo", function()
		self:Render()
	end)

	self:ApplyStyle()
end

function module:ApplyStyle()
	local profile = AMT.Profiles.active.timer.keyInfo

	self.element:SetHeight(profile.height)
	self.name:ApplyStyle(profile.text)
	self.level:ApplyStyle(profile.level)

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
end
