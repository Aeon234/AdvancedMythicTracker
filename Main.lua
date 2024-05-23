local addonName, AMT = ...
-- local E, S
AMT.ElvUIEnabled = false
AMT.DetailsLoaded = false
AMT.DebugMode = false

if ElvUI then
	AMT.E = unpack(ElvUI)
	AMT.S = ElvUI[1]:GetModule("Skins")
	AMT.ElvUIEnabled = true
end

if Details then
	AMT.OpenRaidLib = LibStub("LibOpenRaid-1.0", true)
	AMT.DetailsLoaded = true
end
-- ====================================
-- === Setup Shortcuts and Keybinds ===
-- ====================================
_G["BINDING_NAME_AMT"] = "Show/Hide the window" -- Keybind option name

-- Function to update the highest key for a dungeon
function AMT:UpdateHighestKey(dungeonAbbr, keylevel)
	for _, dungeon in ipairs(self.BestKeys_per_Dungeon) do
		print("Checking dungeon:", dungeon.dungAbbr) -- Debug print
		if dungeon.dungAbbr == dungeonAbbr then
			dungeon.HighestKey = tonumber(keylevel)
			local KeyBullets = ""
			local BulletTemplate = "• "
			for i = 1, keylevel do
				KeyBullets = KeyBullets .. BulletTemplate
			end
			dungeon.DungBullets = KeyBullets
			print("Updated " .. dungeon.dungAbbr .. " with key level " .. keylevel)
			AMT:AMT_UpdateMythicGraph()
			return
		end
	end
	print("Dungeon abbreviation not found: " .. dungeonAbbr)
end

local function handler(msg, editBox)
	if msg == "debug" then
		AMT.DebugMode = not AMT.DebugMode
		print("DebugMode: " .. tostring(AMT.DebugMode))
	elseif msg:match("^add") then
		local command, dungeon, keylevel = msg:match("^(%S*)%s*(%S*)%s*(%S*)$")
		if command == "add" then
			if dungeon and keylevel then
				print("running updatehighestkey")
				-- Update the highest key for the specified dungeon
				AMT:UpdateHighestKey(dungeon, keylevel)
			else
				print("Usage: /amt add <dungeon_abbr> <key_level>")
			end
		end
	elseif msg == "print AMT" then
		if AMT and AMT.BestKeys_per_Dungeon then
			print("Contents of BestKeys_per_Dungeon:")
			for index, dungeon in ipairs(AMT.BestKeys_per_Dungeon) do
				print("Dungeon #" .. index .. ":")
				for key, value in pairs(dungeon) do
					print("\t", key, value)
				end
			end
		else
			print("AMT or BestKeys_per_Dungeon is nil.")
		end
	end
end
SLASH_AMT1 = "/amt"
SlashCmdList["AMT"] = handler

-- ======================================
-- === Create AMT_Window ===
-- ======================================

local AMT_Window
if AMT.ElvUIEnabled then
	AMT_Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_ElvUITemplate")
	AMT.S:HandleFrame(AMT_Window)
else
	AMT_Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_RetailTemplate")
end

AMT_Window:SetSize(1000, PVEFrame:GetHeight())
-- AMT_Window:SetFrameStrata("HIGH")
AMT_Window:Raise()
AMT_Window:SetFrameLevel(500)
AMT_Window:SetPoint("CENTER", UIParent)
AMT_Window:SetToplevel(true)
AMT_Window:SetFlattensRenderLayers(true)
-- AMT_Window.title = AMT_Window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- AMT_Window.title:SetPoint("TOP", AMT_Window.TitleContainer, "TOP", 0, -5)
-- AMT_Window.title:SetText("Advanced Mythic Keystone")
AMT_WindowTitleText:SetText("Advanced Mythic Keystone")
--Make Sure the AMT Window is hidden after creation
AMT_Window:Show()
--Create Button Tabs for AMT Window to mimic PVEFrame
AMT.Check_PVEFrame_TabNums()
--Clamp Window to the screen
AMT_Window:SetClampedToScreen(true)
-- Make Window Movable
AMT_Window:SetMovable(true)
--Let the mouse interact with the Window
AMT_Window:EnableMouse(true)
-- Left Mouse Button will be used to initiate Dragging
AMT_Window:RegisterForDrag("LeftButton")
-- Set the Window to be moveable
AMT_Window:SetScript("OnMouseDown", function(self, button)
	self:StartMoving()
end)
AMT_Window:SetScript("OnMouseUp", function(self, button)
	self:StopMovingOrSizing()
end)

-- ======================================
-- === On addon load pull player data ===
-- ======================================

-- ======================================
-- === Create AMT Tab for PVEFrame ===
-- ======================================

--Create the tab button that will open up the AMT Tab in PVEFrame.
local AMT_TabButton = CreateFrame("Button", "AMT_Tab", PVEFrame, "PanelTabButtonTemplate", (PVEFrame.numTabs + 1))
if AMT.ElvUIEnabled then
	AMT.S:HandleTab(AMT_TabButton)
	AMT_TabButton:SetText("Keystone Tracker")
else
	AMT_TabButton:SetText("Advanced Keystone Tracker")
end
--Force the state of the tab to be deselected. Otherwise when you first open up the PVEFrame it will be stuck in both a selected and deselected phase.
PanelTemplates_DeselectTab(AMT_TabButton)

--When we exit the PVEFrame, deselect the AMT Tab.
PVEFrame:HookScript("OnShow", function()
	AMT.Check_PVEFrame_TabNums()
	if UnitLevel("player") >= GetMaxLevelForPlayerExpansion() then
		if AMT.ElvUIEnabled then
			AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", -5, 0)
		else
			--Now that we've checked # of active tabs we'll anchor the AMT button to the last active tab
			AMT_TabButton:SetPoint("LEFT", PVEFrame.Tabs[PVEFrame_TabNums], "RIGHT", 3, 0)
		end
	end
	--Starting at tab 1, whenever each PVEFrame tab is click deselect the AMT Tab Button
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		PVEFrame_Tab:HookScript("OnClick", function(self, button)
			PanelTemplates_DeselectTab(AMT_TabButton)
		end)
	end
	local selected = PanelTemplates_GetSelectedTab(PVEFrame)
	if selected ~= (PVEFrame.numTabs + 1) then
		PanelTemplates_DeselectTab(AMT_TabButton)
	end
	AMT_Window:Hide()
end)

--Set On Click actions for the AMT Button
AMT_TabButton:SetScript("OnClick", function()
	if AMT_Window:IsVisible() then
		AMT_Window:Hide()
	else
		AMT_Window:ClearAllPoints()
		AMT_Window:SetPoint("TOPLEFT", PVEFrame)
		AMT_Window:Show()
		PVEFrame_ToggleFrame()
	end
end)

AMT_Window:SetScript("OnShow", function()
	AMT:LoadTrackingData()
	--Update the Keys info for tables self.Current_SeasonalDung_Info and BestKeys_per_Dungeon
	AMT:Update_PlayerDungeonInfo()
	AMT.Check_PVEFrame_TabNums()
	if UnitLevel("player") >= GetMaxLevelForPlayerExpansion() then
		for i = 1, #PVEFrame_Panels do
			if
				PVEFrame_Panels[i].text == "Mythic+ Dungeons"
				or PVEFrame_Panels[i].text == "Advanced Keystone Tracker"
			then
				PVEFrame_Panels[i].isVisible = true
			end
		end
	end
	VisiblePanels = {}
	-- Filter out visible panels
	for i = 1, #PVEFrame_Panels do
		if PVEFrame_Panels[i].isVisible then
			tinsert(VisiblePanels, {
				text = PVEFrame_Panels[i].text,
				frameName = PVEFrame_Panels[i].frameName,
				isVisible = PVEFrame_Panels[i].isVisible,
			})
		end
	end
	if not _G["AMT_Window_Tab" .. #VisiblePanels] then
		for i = 1, #VisiblePanels do
			if PVEFrame_Panels[i].isVisible then
				AMT_Window_TabButton =
					CreateFrame("Button", "AMT_Window_Tab" .. i, AMT_Window, "PanelTabButtonTemplate")
				AMT_Window_TabButton:SetText(VisiblePanels[i].text)
				AMT_Window_TabButton:SetFrameStrata("HIGH")
				local tabButton = _G["AMT_Window_Tab" .. i]
				local PVEFrameTab_ToClick = "PVEFrameTab" .. i
				tabButton:SetScript("OnClick", function()
					PVEFrame_ToggleFrame(VisiblePanels[i].frameName)
				end)
				if AMT.ElvUIEnabled then
					AMT.S:HandleTab(AMT_Window_TabButton)
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", AMT_Window, "BOTTOMLEFT", -3, 0)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", -5, 0)
					end
				else
					if i == 1 then
						AMT_Window_TabButton:SetPoint("TOPLEFT", AMT_Window, "BOTTOMLEFT", 19, 2)
					else
						AMT_Window_TabButton:SetPoint("LEFT", "AMT_Window_Tab" .. i - 1, "RIGHT", 3, 0)
					end
				end
			end
		end
	end
	for i = 1, #VisiblePanels do
		local AMTtab = _G["AMT_Window_Tab" .. i]
		local sideWidths = AMTtab.Left:GetWidth() + AMTtab.Right:GetWidth()
		minWidth = minWidth or sideWidths

		PanelTemplates_TabResize(AMTtab, 0, nil, minWidth)

		if i == #PVEFrame_Panels then
			PanelTemplates_SelectTab(_G["AMT_Window_Tab" .. #PVEFrame_Panels])
		else
			PanelTemplates_DeselectTab(_G["AMT_Window_Tab" .. i])
		end
	end

	--Find out the current expansion and season information to format the title.
	local currentDisplaySeason = C_MythicPlus.GetCurrentUIDisplaySeason()
	--Format the title of the tab to be "Advanced Mythic Tracker (Expansion Season #)"
	local currExpID = GetExpansionLevel()
	local expName = _G["EXPANSION_NAME" .. currExpID]
	local title = "Advanced Mythic Tracker (" .. expName .. " Season " .. currentDisplaySeason .. ")"
	AMT_WindowTitleText:SetText(title)

	AMT:AMT_Window_Containers()
end)
