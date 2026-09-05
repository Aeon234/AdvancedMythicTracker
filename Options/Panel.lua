local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options
local CONST = Options.CONST

local TITLE_GAP = 6
local DESCRIPTION_GAP = 12
local BUTTON_GAP = 24

local canvas = CreateFrame("Frame", "AdvancedMythicTrackerSettingsPanel")

canvas.name = AMT.name

local title = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")

title:SetPoint("TOPLEFT", canvas, "TOPLEFT", CONST.PANEL_PADDING, -CONST.PANEL_PADDING)
title:SetJustifyH("LEFT")
title:SetText(AMT.title)

local version = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")

version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -TITLE_GAP)
version:SetJustifyH("LEFT")
version:SetText(("v%s"):format(AMT.version))
version:SetTextColor(0.7, 0.7, 0.7)

local description = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")

description:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -DESCRIPTION_GAP)
description:SetPoint("RIGHT", canvas, "RIGHT", -CONST.PANEL_PADDING, 0)
description:SetJustifyH("LEFT")
description:SetText(L["Advanced Mythic Tracker is configured in its own window."])

local button, label = Options.CreateActionButton(canvas, function()
	if Options.Show() then
		HideUIPanel(SettingsPanel)
	end
end)

button:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -BUTTON_GAP)

label:SetPoint("CENTER")
label:SetText(L["Open Configuration"])

local category = Settings.RegisterCanvasLayoutCategory(canvas, AMT.title)

category.ID = AMT.name

Settings.RegisterAddOnCategory(category)

Options.settingsCategory = category
