local AMT = select(2, ...)

local LSM = AMT.Media.LSM

local GILROY = [[Interface\AddOns\AdvancedMythicTracker\Media\Fonts\GilroyBold.ttf]]
local EXPRESSWAY = [[Interface\AddOns\AdvancedMythicTracker\Media\Fonts\Expressway.ttf]]

LSM:Register("font", "Gilroy Bold", GILROY, LSM.LOCALE_BIT_western)
LSM:Register("font", "Expressway", EXPRESSWAY, LSM.LOCALE_BIT_western)

---@param name string global font-object name
---@param size number
---@return Font
local function CreateChromeFont(name, size)
	local font = CreateFont(name)

	font:SetFont(GILROY, size, "")
	font:SetTextColor(1, 1, 1, 1)
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(1, -1)

	return font
end

CreateChromeFont("AMTFontTitle", 20)
CreateChromeFont("AMTFontGroupTitle", 14)
CreateChromeFont("AMTFontHeading", 14)
CreateChromeFont("AMTFontRow", 13)
CreateChromeFont("AMTFontBody", 13)
CreateChromeFont("AMTFontSmall", 12)
