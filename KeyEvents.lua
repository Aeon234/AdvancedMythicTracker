local addonName, AMT = ...

local WorldChange_EventListenerFrame = CreateFrame("Frame")
local PartyKeystone_EventListenerFrame = CreateFrame("Frame")

-- Create a font string to display the message
local GroupKeysFrame = CreateFrame("Frame", nil, UIParent)
GroupKeysFrame:SetSize(360, 100)
GroupKeysFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 400)
GroupKeysFrame.tex = GroupKeysFrame:CreateTexture()
GroupKeysFrame.tex:SetAllPoints(GroupKeysFrame)
-- GroupKeysFrame.tex:SetColorTexture(unpack(AMT.BackgroundHover))
GroupKeysFrame.tex:SetColorTexture(unpack(AMT.BackgroundClear))
GroupKeysFrame:Hide()

local Initiated_Text = GroupKeysFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
Initiated_Text:SetPoint("CENTER", GroupKeysFrame, "CENTER")
Initiated_Text:SetText(
	"Ready Check Initiated"
	-- .. "\n\n"
	-- .. "WWWWWWWWWWWW"
	-- .. "\n\n"
	-- .. CreateAtlasMarkup("GM-icon-role-healer")
	-- .. CreateAtlasMarkup("GM-icon-role-tank")
	-- .. CreateAtlasMarkup("GM-icon-role-dps")
)
Initiated_Text:SetFont(AMT.AMT_Font, 36)

--Create the label for Keystone's Dungeon Name Background
local Initiated_Text_Divider = CreateFrame("Frame", "AMT_Initiated_Text_Divider", GroupKeysFrame)
Initiated_Text_Divider:SetPoint("TOP", Initiated_Text, "BOTTOM", 0, 4)
Initiated_Text_Divider:SetSize(420, 19)
Initiated_Text_Divider.tex = Initiated_Text_Divider:CreateTexture(nil, "ARTWORK")
Initiated_Text_Divider.tex:SetAtlas("Adventure-MissionEnd-Line")
Initiated_Text_Divider.tex:SetSize(1, 1)
Initiated_Text_Divider.tex:SetAllPoints(Initiated_Text_Divider)

local PartyKeystones_NameFrame = {}
local PartyKeystones_KeyLevelFrame = {}

-- Create the Frames which will store the player name on the left and key level on the right
for i = 1, 5 do
	PartyKeystones_NameFrame[i] = CreateFrame("Frame", nil, GroupKeysFrame)
	PartyKeystones_NameFrame[i]:SetSize(
		Initiated_Text:GetUnboundedStringWidth() / 6 * 5,
		Initiated_Text:GetStringHeight()
	)
	PartyKeystones_NameFrame[i].tex = PartyKeystones_NameFrame[i]:CreateTexture()
	PartyKeystones_NameFrame[i].tex:SetAllPoints(PartyKeystones_NameFrame[i])
	PartyKeystones_NameFrame[i].tex:SetColorTexture(unpack(AMT.BackgroundClear))
	if i == 1 then
		PartyKeystones_NameFrame[i]:SetPoint("TOPLEFT", GroupKeysFrame, "BOTTOMLEFT", 0, 10)
	else
		PartyKeystones_NameFrame[i]:SetPoint("TOPLEFT", PartyKeystones_NameFrame[i - 1], "BOTTOMLEFT")
	end

	PartyKeystones_KeyLevelFrame[i] = CreateFrame("Frame", nil, GroupKeysFrame)
	PartyKeystones_KeyLevelFrame[i]:SetSize(
		Initiated_Text:GetUnboundedStringWidth() / 6,
		Initiated_Text:GetStringHeight()
	)
	PartyKeystones_KeyLevelFrame[i].tex = PartyKeystones_KeyLevelFrame[i]:CreateTexture()
	PartyKeystones_KeyLevelFrame[i].tex:SetAllPoints(PartyKeystones_KeyLevelFrame[i])
	PartyKeystones_KeyLevelFrame[i].tex:SetColorTexture(unpack(AMT.BackgroundClear))
	if i == 1 then
		PartyKeystones_KeyLevelFrame[i]:SetPoint("TOPRIGHT", GroupKeysFrame, "BOTTOMRIGHT", 0, 10)
	else
		PartyKeystones_KeyLevelFrame[i]:SetPoint("TOPRIGHT", PartyKeystones_KeyLevelFrame[i - 1], "BOTTOMRIGHT")
	end

	local PlayerName = PartyKeystones_NameFrame[i]:CreateFontString(
		"AMT_PartyKeystone_NameText" .. i,
		"ARTWORK",
		"GameFontNormalLarge"
	)
	PlayerName:SetPoint("LEFT", PartyKeystones_NameFrame[i], "LEFT")
	PlayerName:SetText("Temp Name")
	PlayerName:SetFont(AMT.AMT_Font, 28)

	local KeyLevel = PartyKeystones_KeyLevelFrame[i]:CreateFontString(
		"AMT_PartyKeystone_KeyLevelText" .. i,
		"ARTWORK",
		"GameFontNormalLarge"
	)
	KeyLevel:SetPoint("RIGHT", PartyKeystones_KeyLevelFrame[i], "RIGHT")
	KeyLevel:SetText("+ 32")
	KeyLevel:SetFont(AMT.AMT_Font, 28)
end

-- local testnames = { "Darkdrpepper", "Mysophobia", "Stygiophobia", "Bigdumblock", "Wwwwwwwwwwww" }
-- --Set the Player Name and Key Level Text
-- for i = 1, 5 do
-- 	local PlayerName = _G["AMT_PartyKeystone_NameText" .. i]
-- 	PlayerName:SetText(CreateAtlasMarkup("GM-icon-role-healer") .. testnames[i])

-- 	local KeyLevel = _G["AMT_PartyKeystone_KeyLevelText" .. i]
-- 	KeyLevel:SetText("+32")
-- end

local PartyKeystones_Text = {}

-- Function to show and hide the message
local function ShowRelevantKeysMessage()
	wipe(PartyKeystones_Text or {})
	AMT:AMT_KeystoneRefresh()
	local _, _, _, _, _, _, _, CurrentInstanceID = GetInstanceInfo()
	local RelevantKeystones = {}
	wipe(RelevantKeystones or {})
	--Grab relevant keystones into a separate table
	for _, key in ipairs(AMT.GroupKeystone_Info) do
		if key.instanceID == CurrentInstanceID then
			tinsert(RelevantKeystones, {
				level = key.level,
				mapID = key.mapID,
				instanceID = key.instanceID,
				name = key.name,
				player = key.player,
				playerName = key.playerName,
				playerClass = key.playerClass,
				playerRole = "",
				playerRoleArt = "",
			})
		end
	end
	--Sort the keys found from highest to lowest
	if #RelevantKeystones > 1 then
		table.sort(RelevantKeystones, function(a, b)
			return b.level < a.level
		end)
	end

	local GroupSize = GetNumGroupMembers()
	local SelectedPlayer = {}
	wipe(SelectedPlayer or {})
	if GroupSize > 0 then
		for i = 1, GroupSize do
			if i == 1 then
				SelectedPlayer[i] = "player"
			else
				SelectedPlayer[i] = "party" .. i - 1
			end
		end
	end
	--Grab every players role (TANK, DAMAGER, HEALER)
	if #SelectedPlayer > 0 then
		for _, player in ipairs(RelevantKeystones) do
			for i = 1, #SelectedPlayer do
				local playerName, _ = UnitName(SelectedPlayer[i])
				local playerRole = UnitGroupRolesAssigned(SelectedPlayer[i])
				if playerName == player.playerName then
					-- print(playerName, playerRole)
					player.playerRole = playerRole
				end
			end
		end
	end
	--Assign the atlas art that will be used alongside player names
	for _, player in ipairs(RelevantKeystones) do
		if player.playerRole == "TANK" then
			player.playerRoleArt = "GM-icon-role-tank"
			-- print(player.player .. " assigned " .. player.playerRoleArt .. " as " .. player.playerRole)
		elseif player.playerRole == "HEALER" then
			player.playerRoleArt = "GM-icon-role-healer"
			-- print(player.player .. " assigned " .. player.playerRoleArt .. " as " .. player.playerRole)
		elseif player.playerRole == "DAMAGER" then
			player.playerRoleArt = "GM-icon-role-dps"
			-- print(player.player .. " assigned " .. player.playerRoleArt .. " as " .. player.playerRole)
		end
	end

	-- for i = 1, #RelevantKeystones do
	-- 	PartyKeystones_Text[i] = GroupKeysFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	-- 	PartyKeystones_Text[i]:SetFont(AMT.AMT_Font, 32)
	-- 	PartyKeystones_Text[i]:SetText(
	-- 		CreateAtlasMarkup("Adventure-heal-indicator")
	-- 			.. CreateAtlasMarkup("GM-icon-role-healer")
	-- 			.. CreateAtlasMarkup("GM-icon-role-tank")
	-- 			.. CreateAtlasMarkup("GM-icon-role-dps")
	-- 			.. RelevantKeystones[i].player
	-- 			.. "'s +"
	-- 			.. RelevantKeystones[i].level
	-- 	)
	-- 	if i == 1 then
	-- 		PartyKeystones_Text[i]:SetPoint("CENTER", Initiated_Text, "CENTER", 0, -60)
	-- 	else
	-- 		PartyKeystones_Text[i]:SetPoint("CENTER", Initiated_Text, "CENTER", 0, -100 - 40 * i - 1)
	-- 	end
	-- end

	--Set the Player Name and Key Level Text
	for i = 1, 5 do
		local PlayerName = _G["AMT_PartyKeystone_NameText" .. i]
		local KeyLevel = _G["AMT_PartyKeystone_KeyLevelText" .. i]
		if RelevantKeystones[i] then
			PlayerName:SetText(CreateAtlasMarkup(RelevantKeystones[i].playerRoleArt) .. RelevantKeystones[i].player)
			KeyLevel:SetText("+" .. RelevantKeystones[i].level)
		else
			PlayerName:SetText("")
			KeyLevel:SetText("")
		end
	end

	if #RelevantKeystones > 0 then
		GroupKeysFrame:Show()
		C_Timer.After(20, function()
			GroupKeysFrame:Hide()
			print("Hiding Message")
		end)
	end
end

--If Ready Check is detected while in a group and in a dungeon
local function AMT_PartyKeystoneEventHandler(self, event, ...)
	local inInstance, instanceType = IsInInstance()
	if inInstance and IsInGroup() and not IsInRaid() then
		ShowRelevantKeysMessage()
		print("Showing Message")
	end
end

--If loading into new zone
local function AMT_WorldEventHandler(self, event, ...)
	-- ShowRelevantKeysMessage()

	local ReadyCheck_Registered = PartyKeystone_EventListenerFrame:RegisterEvent("READY_CHECK")
	if AMT.DetailsEnabled then
		-- print("|cffffd100----------AMT Debugging----------|r")
		-- print("|cff18a8ffAMT: |rDetails Enabled and registering READY_CHECK")
		-- print("|cffffd100----------------------------------------|r")

		PartyKeystone_EventListenerFrame:RegisterEvent("READY_CHECK")
		PartyKeystone_EventListenerFrame:SetScript("OnEvent", AMT_PartyKeystoneEventHandler)
	else
		WorldChange_EventListenerFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
		-- print("|cffffd100----------AMT Debugging----------|r")
		-- print("|cff18a8ffAMT: |rUnregistering PLAYER_ENTERING_WORLD")
		-- print("|cffffd100----------------------------------------|r")
	end
end

--Register Main Event to listen to loading into another zone/instance
WorldChange_EventListenerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
WorldChange_EventListenerFrame:SetScript("OnEvent", AMT_WorldEventHandler)
