local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options
local CONST = Options.CONST

local SIDEBAR_GAP = 12
local SCROLLBAR_RESERVE = 20
local SCROLLBAR_OFFSET = 8
local CLOSE_RESERVE = 30
local TITLE_ITEM_GAP = 12
local TITLE_TEXT_DROP = 12
local TOGGLE_ROW_GAP = 6
local CHECKBOX_LABEL_GAP = 8

local RESET_POINT, RESET_X, RESET_Y = "CENTER", 0, 200

---@class AMTOptionsChrome
---@field frame Frame
---@field sidebarHost Frame
---@field scroll ScrollFrame
---@field scrollBar EventFrame
---@field content AMTOptionsContainer
---@field previewCheck Button
---@field previewTick Texture
---@field animateCheck Button
---@field animateTick Texture
---@field animate boolean
local chrome

---@param host Frame
function Options.BuildSidebar(host) end

---@return AMTOptionsChrome
function Options.GetChrome()
	if chrome then
		return chrome
	end

	chrome = {}

	local frame = CreateFrame("Frame", "AdvancedMythicTrackerOptions", UIParent, "DefaultPanelTemplate")

	frame:SetSize(CONST.FRAME_WIDTH, CONST.FRAME_HEIGHT)
	frame:SetFrameStrata("HIGH")
	frame:SetTitle(AMT.name)
	frame:Hide()

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	CreateFrame("Button", nil, frame, "UIPanelCloseButtonDefaultAnchors")

	frame.onCloseCallback = function()
		Options.Hide()

		return false
	end

	chrome.animate = false

	local version = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")

	version:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CLOSE_RESERVE, -TITLE_TEXT_DROP)
	version:SetText(("v%s"):format(AMT.version))
	version:SetTextColor(0.7, 0.7, 0.7)

	local previewCheck, previewTick = Options.CreateCheckboxControl(frame, function()
		AMT.Demo.Toggle(chrome.animate)
		Options.RefreshToggles()
	end)

	local previewLabel = previewCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	previewLabel:SetPoint("LEFT", previewCheck, "RIGHT", CHECKBOX_LABEL_GAP, 0)
	previewLabel:SetText(L["Preview"])
	previewLabel:SetTextColor(1, 1, 1)

	previewCheck:SetPoint(
		"RIGHT",
		version,
		"LEFT",
		-(TITLE_ITEM_GAP + previewLabel:GetStringWidth() + CHECKBOX_LABEL_GAP),
		0
	)

	local animateCheck, animateTick = Options.CreateCheckboxControl(frame, function()
		chrome.animate = not chrome.animate

		if AMT.Demo.IsActive() then
			AMT.Demo.Toggle(chrome.animate)
		end

		Options.RefreshToggles()
	end)

	local animateLabel = animateCheck:CreateFontString(nil, "ARTWORK", "GameFontNormal")

	animateLabel:SetPoint("LEFT", animateCheck, "RIGHT", CHECKBOX_LABEL_GAP, 0)
	animateLabel:SetText(L["Animate preview"])
	animateLabel:SetTextColor(0.7, 0.7, 0.7)

	animateCheck:SetPoint("TOPLEFT", previewCheck, "BOTTOMLEFT", 0, -TOGGLE_ROW_GAP)

	chrome.previewCheck = previewCheck
	chrome.previewTick = previewTick
	chrome.animateCheck = animateCheck
	chrome.animateTick = animateTick

	chrome.frame = frame

	local sidebarHost = CreateFrame("Frame", nil, frame)

	sidebarHost:SetWidth(CONST.SIDEBAR_WIDTH)
	sidebarHost:SetPoint("TOPLEFT", frame, "TOPLEFT", CONST.PANEL_PADDING, -CONST.TITLE_HEIGHT)
	sidebarHost:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONST.PANEL_PADDING, CONST.PANEL_PADDING)

	chrome.sidebarHost = sidebarHost

	local scroll = CreateFrame("ScrollFrame", nil, frame)

	scroll:SetPoint("TOPLEFT", sidebarHost, "TOPRIGHT", SIDEBAR_GAP, 0)
	scroll:SetPoint(
		"BOTTOMRIGHT",
		frame,
		"BOTTOMRIGHT",
		-(CONST.PANEL_PADDING + SCROLLBAR_RESERVE),
		CONST.PANEL_PADDING
	)
	scroll:EnableMouseWheel(true)

	local scrollBar = CreateFrame("EventFrame", nil, frame, "MinimalScrollBar")

	scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", SCROLLBAR_OFFSET, 0)
	scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", SCROLLBAR_OFFSET, 0)

	ScrollUtil.InitScrollFrameWithScrollBar(scroll, scrollBar)

	scrollBar:SetInterpolateScroll(true)

	scroll:SetPanExtent(CONST.SCROLL_PAN_EXTENT) ---@diagnostic disable-line: undefined-field

	chrome.scroll = scroll
	chrome.scrollBar = scrollBar

	local content = Options.NewContainer(frame)

	scroll:SetScrollChild(content.frame)

	chrome.content = content

	local function UpdateContentWidth()
		content.frame:SetWidth(scroll:GetWidth())
	end

	scroll:SetScript("OnSizeChanged", UpdateContentWidth)
	UpdateContentWidth()

	frame:RegisterEvent("PLAYER_REGEN_DISABLED")
	frame:RegisterEvent("CHALLENGE_MODE_START")
	frame:SetScript("OnEvent", function(_, event)
		-- A key starting forces the toggle off and disabled rather than closing the window: the real
		-- HUD is live and is a better preview than fake data.
		if event == "CHALLENGE_MODE_START" then
			Options.RefreshToggles()

			return
		end

		Options.Hide()
	end)

	Options.BuildSidebar(sidebarHost)

	return chrome
end

function Options.RefreshToggles()
	if not chrome then
		return
	end

	local inKey = AMT.State.current.inChallenge

	chrome.previewTick:SetShown(AMT.Demo.IsActive())
	chrome.previewCheck:SetEnabled(not inKey)

	chrome.animateTick:SetShown(chrome.animate)
	chrome.animateCheck:SetEnabled(not inKey)
end

---@return boolean opened
function Options.Show()
	if InCombatLockdown() then
		AMT.Util.Warn("the options window cannot be opened in combat.")

		return false
	end

	local window = Options.GetChrome().frame

	window:ClearAllPoints()
	window:SetPoint(RESET_POINT, UIParent, RESET_POINT, RESET_X, RESET_Y)
	window:Show()
	Options.RefreshToggles()

	return true
end

function Options.Hide()
	if not chrome then
		return
	end

	chrome.frame:Hide()
end

function Options.Toggle()
	if chrome and chrome.frame:IsShown() then
		Options.Hide()

		return
	end

	Options.Show()
end

---@return boolean
function Options.IsShown()
	return chrome ~= nil and chrome.frame:IsShown()
end
