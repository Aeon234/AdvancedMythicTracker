local addonName, AMT = ...

-- Static table containing font names
AMT_FontTable = {
	"GameFontNormal",
	"GameFontNormal_NoShadow",
	"GameFontNormalCenter",
	"GameFontDisable",
	"GameFontHighlight",
	"GameFontHighlight_NoShadow",
	"GameFontHighlightLeft",
	"GameFontHighlightCenter",
	"GameFontHighlightRight",
	"GameFontNormalHuge",
	"GameFontHighlightHuge",
	"GameFontDisableHuge",
	"GameFontNormalSmall",
	"GameFontNormalTiny",
	"GameFontWhiteTiny",
	"GameFontDisableTiny",
	"GameFontBlackTiny",
	"GameFontNormalTiny2",
	"GameFontWhiteTiny2",
	"GameFontDisableTiny2",
	"GameFontBlackTiny2",
	"GameFontNormalMed1",
	"GameFontNormalMed2",
	"GameFontNormalLarge",
	"GameFontNormalMed2Outline",
	"GameFontNormalLargeOutline",
	"GameFontDisableSmall",
	"GameFontDisableSmall2",
	"GameFontNormalShadowOutline22",
	"GameFontHighlightShadowOutline22",
	"GameFontNormalOutline",
	"GameFontHighlightOutline",
	"QuestFontNormalLarge",
	"QuestFontNormalHuge",
	"QuestFontHighlightHuge",
	"GameFontHighlightMedium",
	"GameFontBlackMedium",
	"GameFontBlackSmall",
	"GameFontRed",
	"GameFontRedLarge",
	"GameFontGreen",
	"GameFontBlack",
	"GameFontWhite",
	"GameFontHighlightMed2",
	"GameFontHighlightLarge",
	"GameFontNormalMed3",
	"GameFontNormalMed3Outline",
	"GameFontDisableMed3",
	"GameFontDisableLarge",
	"GameFontDisableMed2",
	"GameFontHighlightSmall",
	"GameFontNormalSmallLeft",
	"GameFontHighlightSmallLeft",
	"GameFontDisableSmallLeft",
	"GameFontHighlightSmall2",
	"GameFontBlackSmall2",
	"GameFontNormalSmall2",
	"GameFontNormalLarge2",
	"GameFontHighlightLarge2",
	"GameFontNormalWTF2",
	"GameFontNormalWTF2Outline",
	"GameFontNormalHuge2",
	"GameFontHighlightHuge2",
	"GameFontNormalShadowHuge2",
	"GameFontHighlightShadowHuge2",
	"GameFontNormalOutline22",
	"GameFontHighlightOutline22",
	"GameFontDisableOutline22",
	"GameFontNormalHugeOutline",
	"GameFontNormalHuge3",
	"GameFontNormalHuge3Outline",
	"GameFontNormalHuge4",
	"GameFontNormalHuge4Outline",
	"GameFont72Normal",
	"GameFont72Highlight",
	"GameFont72NormalShadow",
	"GameFont72HighlightShadow",
	"GameTooltipHeaderText",
	"GameTooltipText",
	"GameTooltipTextSmall",
	"IMENormal",
	"IMEHighlight",
	"MovieSubtitleFont",
}

local frame = CreateFrame("Frame", "MyFullScreenFrame", UIParent)
frame:SetAllPoints(UIParent)
frame:Raise()

frame.texture = frame:CreateTexture()
frame.texture:SetAllPoints(frame)
frame.texture:SetColorTexture(0.4, 0.4, 0.4, 1)

-- frame:SetBackdrop(BackdropInfo)
-- frame:SetBackdropBorderColor(1, 0, 1, 0.0)
-- frame:SetBackdropColor(1, 1, 1, 1.0)

local function generateFontStrings(fonts)
	for i, fontName in ipairs(fonts) do
		local fontString = CreateFrame("Frame", nil, frame)
		fontString:SetSize(250, 30)

		-- Calculate column and row positions
		local col = math.floor((i - 1) / 21) -- Calculate column index
		local row = (i - 1) % 21 -- Calculate row index

		-- Set position based on column and row
		if i == 1 then
			fontString:SetPoint("TOPLEFT", 100 + 600 * col, -10)
		else
			fontString:SetPoint("TOPLEFT", 100 + 600 * col, -10 - 60 * row - 1)
		end

		local text = fontString:CreateFontString(nil, "OVERLAY", fontName)
		text:SetPoint("CENTER")
		text:SetText(fontName)
		text:SetTextColor(1, 1, 1)
	end
end

-- Generate font strings using the static table of font names
generateFontStrings(AMT_FontTable)
