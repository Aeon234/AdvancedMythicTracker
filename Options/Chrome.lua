local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options
local CONST = Options.CONST

local SIDEBAR_GAP = 12
local SCROLLBAR_RESERVE = 20
local SCROLLBAR_OFFSET = 8
local CLOSE_RESERVE = 30
local TITLE_TEXT_DROP = 12

local RESET_POINT, RESET_X, RESET_Y = "CENTER", 0, 200

---@class AMTOptionsChrome
---@field frame Frame
---@field sidebarHost Frame
---@field scroll ScrollFrame
---@field scrollBar EventFrame
---@field content AMTOptionsContainer
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
	frame:SetTitle(AMT.title)
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

	-- Every hide path lands here, so an unlocked frame can never outlive the window that unlocked it.
	frame:SetScript("OnHide", function()
		if AMT.Frames.IsUnlocked() then
			AMT.Frames.SetUnlocked(false)
		end
	end)

	chrome.animate = false

	local version = frame:CreateFontString(nil, "ARTWORK", CONST.FONT_SMALL)

	version:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CLOSE_RESERVE, -TITLE_TEXT_DROP)
	version:SetText(("v%s"):format(AMT.version))
	version:SetTextColor(0.7, 0.7, 0.7)

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
			Options.NotifyValueChanged()

			return
		end

		Options.Hide()
	end)

	Options.BuildSidebar(sidebarHost)

	return chrome
end

---@return boolean
function Options.IsPreviewAnimated()
	return chrome ~= nil and chrome.animate
end

---@param animated boolean
function Options.SetPreviewAnimated(animated)
	if chrome then
		chrome.animate = animated
	end
end

---@return boolean opened
function Options.Show()
	if InCombatLockdown() then
		AMT.Util.Warn(L["the options window cannot be opened in combat."])

		return false
	end

	local window = Options.GetChrome().frame

	window:ClearAllPoints()
	window:SetPoint(RESET_POINT, UIParent, RESET_POINT, RESET_X, RESET_Y)
	window:Show()
	Options.NotifyValueChanged()

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
