local AMT = select(2, ...)

local Options = AMT.Options

local TITLE_GAP = 6
local DIVIDER_GAP = 2
local MIN_HEIGHT = 40
local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

---@class AMTOptionsPageHeaderConfig
---@field title string
---@field description string?
---@field divider string? thin|accent
---@field actionText string?
---@field actionIcon string?
---@field onAction fun()?
---@field actionDisabled AMTOptionPredicate?

---@class AMTOptionsPageHeader
---@field frame Frame
---@field title FontString
---@field description FontString
---@field action Button?
---@field config AMTOptionsPageHeaderConfig
---@field onResized fun()?
local PageHeader = {}
PageHeader.__index = PageHeader
Options.PageHeader = PageHeader

function PageHeader:Refresh()
	if not self.action then
		return
	end

	local predicate = self.config.actionDisabled

	self.action:SetEnabled(predicate == nil or not predicate())
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
	header.title:SetText(config.title:upper())
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
			if config.onAction and action:IsEnabled() then
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

		header:Refresh()
	end

	return header
end
