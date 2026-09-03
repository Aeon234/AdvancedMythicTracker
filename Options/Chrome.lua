local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local SIDEBAR_GAP = 12
local SCROLLBAR_RESERVE = 20
local SCROLLBAR_OFFSET = 8

local RESET_POINT, RESET_X, RESET_Y = "CENTER", 0, 200

---@class AMTOptionsChrome
---@field frame Frame
---@field sidebarHost Frame
---@field scroll ScrollFrame
---@field scrollBar EventFrame
---@field content AMTOptionsContainer
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

	scroll:SetPanExtent(CONST.SCROLL_PAN_EXTENT)

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
	frame:SetScript("OnEvent", function()
		Options.Hide()
	end)

	Options.BuildSidebar(sidebarHost)

	return chrome
end

function Options.Show()
	if InCombatLockdown() then
		AMT.Util.Warn("the options window cannot be opened in combat.")

		return
	end

	local window = Options.GetChrome().frame

	window:ClearAllPoints()
	window:SetPoint(RESET_POINT, UIParent, RESET_POINT, RESET_X, RESET_Y)
	window:Show()
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
