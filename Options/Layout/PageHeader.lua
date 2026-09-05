local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options

local TITLE_GAP = 6
local DIVIDER_GAP = 2
local MIN_HEIGHT = 40
local TOGGLE_GROUP_GAP = 16
local TOGGLE_LABEL_GAP = 8
local TOGGLE_ROW_DROP = 4
local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

---@class AMTOptionsPageHeaderConfig
---@field title string?
---@field description string?
---@field divider string? thin|accent
---@field actionText string?
---@field actionIcon string?
---@field onAction fun()?
---@field actionHidden AMTOptionPredicate?
---@field previewToggles boolean?

---@class AMTOptionsPageHeader
---@field frame Frame
---@field title FontString
---@field description FontString
---@field action Button?
---@field previewCheck Button?
---@field previewTick Texture?
---@field animateCheck Button?
---@field animateTick Texture?
---@field config AMTOptionsPageHeaderConfig
---@field onResized fun()?
local PageHeader = {}
PageHeader.__index = PageHeader
Options.PageHeader = PageHeader

function PageHeader:Refresh()
	if self.action then
		local predicate = self.config.actionHidden

		self.action:SetShown(predicate == nil or not predicate())
	end

	if not (self.previewCheck and self.previewTick and self.animateCheck and self.animateTick) then
		return
	end

	local inKey = AMT.State.current.inChallenge

	self.previewTick:SetShown(AMT.Demo.IsActive())
	self.previewCheck:SetEnabled(not inKey)

	self.animateTick:SetShown(Options.IsPreviewAnimated())
	self.animateCheck:SetEnabled(not inKey)
end

---@param header AMTOptionsPageHeader
local function BuildPreviewToggles(header)
	local previewCheck, previewTick = Options.CreateCheckboxControl(header.frame, function()
		AMT.Demo.Toggle(Options.IsPreviewAnimated())
		Options.NotifyValueChanged()
	end)

	local previewLabel = previewCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	previewLabel:SetPoint("LEFT", previewCheck, "RIGHT", TOGGLE_LABEL_GAP, 0)
	previewLabel:SetText(L["Preview"])
	previewLabel:SetTextColor(1, 1, 1)

	local animateCheck, animateTick = Options.CreateCheckboxControl(header.frame, function()
		local animated = not Options.IsPreviewAnimated()

		Options.SetPreviewAnimated(animated)

		if AMT.Demo.IsActive() then
			AMT.Demo.Toggle(animated)
		end

		Options.NotifyValueChanged()
	end)

	local animateLabel = animateCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	animateLabel:SetPoint("LEFT", animateCheck, "RIGHT", TOGGLE_LABEL_GAP, 0)
	animateLabel:SetText(L["Animate preview"])
	animateLabel:SetTextColor(1, 1, 1)

	local animateInset = TOGGLE_GROUP_GAP + animateLabel:GetStringWidth() + TOGGLE_LABEL_GAP

	animateCheck:SetPoint("TOPRIGHT", header.frame, "TOPRIGHT", -animateInset, -TOGGLE_ROW_DROP)

	previewCheck:SetPoint(
		"RIGHT",
		animateCheck,
		"LEFT",
		-(TOGGLE_GROUP_GAP + previewLabel:GetStringWidth() + TOGGLE_LABEL_GAP),
		0
	)

	header.previewCheck = previewCheck
	header.previewTick = previewTick
	header.animateCheck = animateCheck
	header.animateTick = animateTick
end

---@param parent Frame
---@param config AMTOptionsPageHeaderConfig
---@return AMTOptionsPageHeader
function Options.NewPageHeader(parent, config)
	local header = setmetatable({ config = config }, PageHeader)

	header.frame = CreateFrame("Frame", nil, parent)

	header.title = header.frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	header.title:SetPoint("TOPLEFT", header.frame, "TOPLEFT", 0, 0)
	header.title:SetJustifyH("LEFT")
	header.title:SetText((config.title or ""):upper())
	header.title:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

	header.description = header.frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	header.description:SetPoint("TOPLEFT", header.title, "BOTTOMLEFT", 0, -TITLE_GAP)
	header.description:SetJustifyH("LEFT")
	header.description:SetText(config.description or "")
	header.description:SetTextColor(0.7, 0.7, 0.7)

	local height = header.title:GetStringHeight() + TITLE_GAP + header.description:GetStringHeight()

	if config.divider then
		local divider = Options.NewDivider(header.frame, config.divider)

		divider:SetPoint("TOPLEFT", header.description, "BOTTOMLEFT", 0, -DIVIDER_GAP)
		divider:SetPoint("RIGHT", header.frame, "RIGHT", 0, 0)

		height = height + DIVIDER_GAP + divider:GetHeight()
	end

	header.frame:SetHeight(math.max(height, MIN_HEIGHT))

	if config.actionText then
		local action, label, icon = Options.CreateActionButton(header.frame, function()
			if config.onAction then
				config.onAction()
			end

			Options.NotifyValueChanged()
		end)

		action:SetPoint("TOPRIGHT", header.frame, "TOPRIGHT", 0, 0)

		label:SetPoint("CENTER", action, "CENTER", config.actionIcon and 10 or 0, 0)
		label:SetText(config.actionText)

		if config.actionIcon then
			icon:SetTexture(config.actionIcon)
			icon:Show()
		end

		header.action = action
	end

	if config.previewToggles then
		BuildPreviewToggles(header)
	end

	header:Refresh()

	return header
end
