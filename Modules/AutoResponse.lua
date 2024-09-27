local addonName, AMT = ...
local API = AMT.API

local Mplus_AutoResponse = CreateFrame("Frame")
Mplus_AutoResponse.isLoaded = false

function Mplus_AutoResponse:Init()
	if Mplus_AutoResponse.isLoaded then
		AMT:PrintDebug("Mplus_AutoResponse already initialized")
		return
	else
		AMT:PrintDebug("Mplus_AutoResponse initialized")
		Mplus_AutoResponse.prefix = "<M+ Auto Response>"
		Mplus_AutoResponse.spamBase = {
			"^" .. Mplus_AutoResponse.prefix,
			"^<Deadly Boss Mods>",
			"^<DBM>",
			"^%[BigWigs%]",
		}
		Mplus_AutoResponse.whoToReplyTo = {
			[1] = "Friends Only",
			[2] = "Friends and Guild Mates",
			[3] = "All",
		}
		Mplus_AutoResponse.DungeonNameType = {
			[1] = "My Language",
			[2] = "English Full Name",
			[3] = "English Abbreviation",
		}
		Mplus_AutoResponse.responseTarget = {
			["friend"] = 1,
			["guild"] = 2,
			["unknown"] = 3,
		}
		Mplus_AutoResponse.replyInfoType = {
			[1] = "Time",
			[2] = "Trash",
			[3] = "Boss",
			[4] = "Deaths",
		}
		Mplus_AutoResponse.started = false
		Mplus_AutoResponse.isActive = false

		Mplus_AutoResponse.throttle = {}
		Mplus_AutoResponse.throttleBN = {}
		Mplus_AutoResponse.toReply = {}

		Mplus_AutoResponse.runInfo = {
			["challengeMapId"] = nil,
			["keyLevel"] = nil,
			["startTime"] = nil,
			["progressTrash"] = nil,
			["progressEncounter"] = nil,
			["numEncounters"] = nil,
			["deaths"] = nil,
		}
		Mplus_AutoResponse.isLoaded = true
	end
end

-- =======================
-- MARK: === Utilities ===
-- =======================

function Mplus_AutoResponse.UpdateProgress()
	local elapsedTime = select(2, GetWorldElapsedTime(1))
	if not Mplus_AutoResponse.started or not Mplus_AutoResponse.isActive or elapsedTime <= 0 then
		AMT:PrintDebug("not in mplus")
		return false
	end

	Mplus_AutoResponse.runInfo.keyLevel = C_ChallengeMode.GetActiveKeystoneInfo()
	Mplus_AutoResponse.runInfo.startTime = GetTime() - elapsedTime
	Mplus_AutoResponse.runInfo.numEncounters = select(3, C_Scenario.GetStepInfo()) - 1

	local stepID = select(3, C_Scenario.GetStepInfo())
	local scenarioCriteriaInfo = C_ScenarioInfo.GetCriteriaInfo(stepID)
	local totalQuantity = scenarioCriteriaInfo.totalQuantity
	local quantityString = scenarioCriteriaInfo.quantityString

	if quantityString then
		local currentQuantity = tonumber(string.sub(quantityString, 1, string.len(quantityString) - 1)) or 0
		Mplus_AutoResponse.runInfo.progressTrash = ((currentQuantity / totalQuantity) * 100) or 0
	end

	local killed = 0
	for i = 1, Mplus_AutoResponse.runInfo.numEncounters do
		local encounterInfo = C_ScenarioInfo.GetCriteriaInfo(i)
		if encounterInfo.completed then
			killed = killed + 1
		end
	end
	Mplus_AutoResponse.runInfo.progressEncounter = killed
	Mplus_AutoResponse.runInfo.deaths = select(1, C_ChallengeMode.GetDeathCount())
	return true
end

function Mplus_AutoResponse.CreateResponse(target, completed)
	if not Mplus_AutoResponse.started or not Mplus_AutoResponse.runInfo.challengeMapId then
		-- If we're not in a key, return nil
		return nil
	end

	local replyInfo
	if target == Mplus_AutoResponse.responseTarget.friend then
		replyInfo = AMT_DB.replyInfoFriend
	elseif target == Mplus_AutoResponse.responseTarget.guild then
		replyInfo = AMT_DB.replyInfoGuild
	elseif target == Mplus_AutoResponse.responseTarget.unknown then
		replyInfo = AMT_DB.replyInfoUnknown
	else
		do
			return nil
		end
	end

	local _, _, maxTime = C_ChallengeMode.GetMapUIInfo(Mplus_AutoResponse.runInfo.challengeMapId)
	local response = "+"
		.. Mplus_AutoResponse.runInfo.keyLevel
		.. " - "
		.. Mplus_AutoResponse.GetKeystoneName(AMT_DB.replyKeystoneNameType)
	local elapsedTime = GetTime() - Mplus_AutoResponse.runInfo.startTime
	local deaths = Mplus_AutoResponse.runInfo.deaths or 0

	if completed then
		if AMT_DB.replyInfoFriend["Time"] then
			local time, onTime, keystoneUpgradeLevels = select(3, C_ChallengeMode.GetCompletionInfo())
			response = response
				.. " - "
				.. Mplus_AutoResponse.FormatSecond(time / 1000)
				.. "/"
				.. Mplus_AutoResponse.FormatSecond(maxTime)
			if onTime then
				response = response .. " (+" .. keystoneUpgradeLevels .. ")"
			else
				response = response .. " (ruined)"
			end
			if AMT_DB.replyInfoFriend["Deaths"] then
				response = response .. " - " .. deaths .. " deaths"
			end
		end
		do
			return Mplus_AutoResponse.prefix .. " I've finished Mythic Keystone: " .. response
		end
	else
		if AMT_DB.replyInfoFriend["Time"] then
			response = response
				.. " - "
				.. Mplus_AutoResponse.FormatSecond(elapsedTime)
				.. "/"
				.. Mplus_AutoResponse.FormatSecond(maxTime)
		end
		if AMT_DB.replyInfoFriend["Trash"] then
			response = response .. " - " .. math.floor(Mplus_AutoResponse.runInfo.progressTrash) .. "% of trash"
		end
		if AMT_DB.replyInfoFriend["Boss"] then
			response = response
				.. " - "
				.. Mplus_AutoResponse.runInfo.progressEncounter
				.. "/"
				.. Mplus_AutoResponse.runInfo.numEncounters
				.. " bosses complete"
		end
		if AMT_DB.replyInfoFriend["Deaths"] then
			response = response .. " - " .. deaths .. " deaths"
		end
		do
			return Mplus_AutoResponse.prefix .. " I'm busy in Mythic Keystone: " .. response
		end
	end
end

--- Starts to track whispers and initializes variables
function Mplus_AutoResponse.Start()
	Mplus_AutoResponse.started, Mplus_AutoResponse.isActive = true, true

	Mplus_AutoResponse.runInfo.challengeMapId = C_ChallengeMode.GetActiveChallengeMapID()
	Mplus_AutoResponse.runInfo.keyLevel = C_ChallengeMode.GetActiveKeystoneInfo()

	local num = select(3, C_Scenario.GetStepInfo())
	local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(num)
	if criteriaInfo ~= 0 and num > 1 then
		Mplus_AutoResponse.runInfo.numEncounters = num - 1
	else
		Mplus_AutoResponse.runInfo.numEncounters = num
	end
end

--- Sends a messages about the completion of the Keystone
function Mplus_AutoResponse.Complete()
	local msg = { nil, nil, nil }
	if AMT_DB.replyAfterComplete == 1 then
		for key in next, Mplus_AutoResponse.throttleBN do
			if not msg[Mplus_AutoResponse.responseTarget.friend] then
				msg[Mplus_AutoResponse.responseTarget.friend] =
					Mplus_AutoResponse.CreateResponse(Mplus_AutoResponse.responseTarget.friend, true)
				if not msg[Mplus_AutoResponse.responseTarget.friend] then
					break
				end
			end
			BNSendWhisper(key, msg[Mplus_AutoResponse.responseTarget.friend])
		end
	end
	if AMT_DB.replyAfterComplete > 1 then
		for key, value in next, Mplus_AutoResponse.toReply do
			if not msg[value] then
				msg[value] = Mplus_AutoResponse.CreateResponse(value, true)
			end
			if msg[value] then
				SendChatMessage(msg[value], "WHISPER", nil, key)
			end
		end
	end
end

--- Reset all variables
function Mplus_AutoResponse.Reset()
	Mplus_AutoResponse.started, Mplus_AutoResponse.isActive = false, false
	Mplus_AutoResponse.throttle, Mplus_AutoResponse.throttleBN, Mplus_AutoResponse.toReply = {}, {}, {}
	for key in pairs(Mplus_AutoResponse.runInfo) do
		Mplus_AutoResponse.runInfo[key] = nil
	end
end

--- Format seconds to *XX:XX
function Mplus_AutoResponse.FormatSecond(seconds)
	if type(seconds) ~= "number" then
		return "--:--"
	end

	local m = math.floor(seconds / 60)
	local s = math.floor(seconds - (m * 60))

	if m < 10 then
		m = "0" .. m
	end
	if s < 10 then
		s = "0" .. s
	end

	return m .. ":" .. s
end

---Return name of keystone based on config
function Mplus_AutoResponse.GetKeystoneName(type)
	local abbr, name = AMT:Find_Dungeon(Mplus_AutoResponse.runInfo.challengeMapId)

	if type == 1 or not name then
		-- my language full
		name = select(1, C_ChallengeMode.GetMapUIInfo(Mplus_AutoResponse.runInfo.challengeMapId))
	elseif type == 2 then
		-- english full
		name = name
	elseif type == 3 then
		-- english abbreviations
		name = abbr
	end

	return name
end

---Check if message sent by this aura, DBM, BW or something else from base
function Mplus_AutoResponse.IsSpam(str)
	for _, value in ipairs(Mplus_AutoResponse.spamBase) do
		if str:match(value) then
			return true
		end
	end
	return false
end

-- ========================
-- MARK: === Main Event ===
-- ========================

local function AMT_AutoResponseEventHandler(self, event, ...)
	Mplus_AutoResponse.isActive = select(2, GetWorldElapsedTime(1)) > 0
	if event == "CHALLENGE_MODE_START" then
		-- If a new key has started, but Mplus_AutoResponse.started is already true from a pprevious key, reset it.
		AMT:PrintDebug(event .. " event triggered")
		if Mplus_AutoResponse.started then
			Mplus_AutoResponse.Reset()
		end
		Mplus_AutoResponse.Start()
	elseif event == "CHALLENGE_MODE_DEATH_COUNT_UPDATED" then
		-- When someone dies in the dungeon, update the deaths counter.
		AMT:PrintDebug(event .. " event triggered")
		Mplus_AutoResponse.runInfo.deaths = C_ChallengeMode.GetDeathCount()
	elseif event == "CHALLENGE_MODE_COMPLETED" then
		-- When completing the dungeon update counters, send out final messages if needed and reset.
		AMT:PrintDebug(event .. " event triggered")
		Mplus_AutoResponse.UpdateProgress()
		Mplus_AutoResponse.Complete()
		Mplus_AutoResponse.Reset()
	elseif event == "CHALLENGE_MODE_RESET" then
		-- If dungeons are reset then reset the auto response variables.
		AMT:PrintDebug(event .. " event triggered")
		Mplus_AutoResponse.Reset()
	elseif event == "CHAT_MSG_WHISPER" and Mplus_AutoResponse.isActive then
		AMT:PrintDebug(event .. " event triggered")
		local _, sender, _, _, _, flag, _, _, _, _, _, guid = ...
		if flag ~= "GM" and flag ~= "DEV" then
			-- If the whisperer is not a GM or a Dev
			local trimmedPlayer = Ambiguate(sender, "none") -- grab the player name and realm if needed.
			local time = GetTime()
			if
				-- If the person whispering is not in our group and a reply to said pperson is not on cooldown yet.
				not UnitInRaid(trimmedPlayer)
				and not UnitInParty(trimmedPlayer)
				and (
					not Mplus_AutoResponse.throttle[sender]
					or time - Mplus_AutoResponse.throttle[sender] > (AMT_DB.replyCooldown * 60 + 5)
				)
			then
				AMT:PrintDebug("Not throttled")
				if AMT_DB.antiSpam then
					AMT:PrintDebug("AMT_DB.antiSpam is true")
					if Mplus_AutoResponse.IsSpam(select(1, ...)) then
						return false
					end
				end
				if not Mplus_AutoResponse.UpdateProgress() then
					AMT:PrintDebug("Returning false because not Mplus_AutoResponse.UpdateProgress()")
					return false
				end
				Mplus_AutoResponse.throttle[sender] = time
				local msg
				if select(2, C_BattleNet.GetGameAccountInfoByGUID(guid)) or C_FriendList.IsFriend(guid) then
					AMT:PrintDebug("Whisperer is a friend")
					if AMT_DB.replyAfterComplete == 1 then
						Mplus_AutoResponse.toReply[sender] = Mplus_AutoResponse.responseTarget.friend
					end
					msg = Mplus_AutoResponse.CreateResponse(Mplus_AutoResponse.responseTarget.friend, false)
				elseif IsGuildMember(guid) then
					AMT:PrintDebug("Whisperer is a guildie")
					if AMT_DB.replyAfterComplete == 2 then
						Mplus_AutoResponse.toReply[sender] = Mplus_AutoResponse.responseTarget.guild
					end
					msg = Mplus_AutoResponse.CreateResponse(Mplus_AutoResponse.responseTarget.guild, false)
				else
					AMT:PrintDebug("Whisperer is an unknown")
					if AMT_DB.replyAfterComplete == 3 then
						Mplus_AutoResponse.toReply[sender] = Mplus_AutoResponse.responseTarget.unknown
					end
					msg = Mplus_AutoResponse.CreateResponse(Mplus_AutoResponse.responseTarget.unknown, false)
				end
				if msg then
					AMT:PrintDebug("Sending message")
					SendChatMessage(msg, "WHISPER", nil, sender)
				end
			end
		end
	elseif event == "CHAT_MSG_BN_WHISPER" and Mplus_AutoResponse.isActive then
		AMT:PrintDebug(event .. " event triggered")
		local bnSenderID = select(13, ...)
		-- if not BNIsSelf(bnSenderID) and AMT_DB.replyInfoFriend[Mplus_AutoResponse.replyInfoType.key] then
		if not BNIsSelf(bnSenderID) then
			local time = GetTime()
			if
				not Mplus_AutoResponse.throttleBN[bnSenderID]
				or time - Mplus_AutoResponse.throttleBN[bnSenderID] > (AMT_DB.replyCooldown * 60 + 5)
			then
				AMT:PrintDebug("Not throttled")
				if AMT_DB.antiSpam then
					AMT:PrintDebug("AMT_DB.antiSpam is true")
					if Mplus_AutoResponse.IsSpam(select(1, ...)) then
						return false
					end
				end
				if not Mplus_AutoResponse.UpdateProgress() then
					AMT:PrintDebug("Returning false becausee not Mplus_AutoResponse.UpdateProgress()")
					return false
				end
				local index = BNGetFriendIndex(bnSenderID)
				local gameAccs = C_BattleNet.GetFriendNumGameAccounts(index)
				for i = 1, gameAccs do
					local friendInfo = C_BattleNet.GetFriendGameAccountInfo(index, i)
					if friendInfo and friendInfo.clientProgram == BNET_CLIENT_WOW then
						local player = friendInfo.characterName
						if friendInfo.realmName ~= GetRealmName() then
							player = player .. "-" .. friendInfo.realmName
						end
						if UnitInRaid(player) or UnitInParty(player) then
							return false
						end
					end
				end
				local msg = Mplus_AutoResponse.CreateResponse(Mplus_AutoResponse.responseTarget.friend, false)
				if msg then
					AMT:PrintDebug("Sending message")
					Mplus_AutoResponse.throttleBN[bnSenderID] = time
					BNSendWhisper(bnSenderID, msg)
				end
			end
		end
	end
end

-- =======================
-- MARK: ===  SETTINGS ===
-- =======================

local ADDON_LOADED = CreateFrame("Frame")
ADDON_LOADED:RegisterEvent("ADDON_LOADED")

ADDON_LOADED:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if name == addonName then
		Mplus_AutoResponse:SetScript("OnEvent", AMT_AutoResponseEventHandler)
		if C_ChallengeMode.IsChallengeModeActive() then
			Mplus_AutoResponse:Init()
			Mplus_AutoResponse.Start()
		end
		self:UnregisterEvent(event)
		AMT:PrintDebug("Unregistering " .. event .. " for M+ Auto Response")
	end
end)

function Mplus_AutoResponse:EnableShowKeys()
	if self.enabled then
		return
	end
	Mplus_AutoResponse:RegisterEvent("CHALLENGE_MODE_START")
	Mplus_AutoResponse:RegisterEvent("CHALLENGE_MODE_COMPLETED")
	Mplus_AutoResponse:RegisterEvent("CHAT_MSG_WHISPER")
	Mplus_AutoResponse:RegisterEvent("CHAT_MSG_BN_WHISPER")
	Mplus_AutoResponse:RegisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
	AMT:PrintDebug("Mplus_AutoResponse - Registering all events")
	Mplus_AutoResponse:Init()
	self.enabled = true
end

function Mplus_AutoResponse:DisableShowKeys()
	if self.enabled then
		Mplus_AutoResponse:UnregisterEvent("CHALLENGE_MODE_START")
		Mplus_AutoResponse:UnregisterEvent("CHALLENGE_MODE_COMPLETED")
		Mplus_AutoResponse:UnregisterEvent("CHAT_MSG_WHISPER")
		Mplus_AutoResponse:UnregisterEvent("CHAT_MSG_BN_WHISPER")
		Mplus_AutoResponse:UnregisterEvent("CHALLENGE_MODE_DEATH_COUNT_UPDATED")
		AMT:PrintDebug("Mplus_AutoResponse - Unregistering all events ")
	end
	self.enabled = false
end

function Mplus_AutoResponse:CreateOptions()
	-- self.OptionFrame = AMT.SetupSettingsDialog(self, OPTIONS_SCHEMATIC)
	local f
	if not _G["AMT_AutoResponse"] then
		f = AMT:CreateOptionsPane("AMT_AutoResponse")
		f.Title:SetText("M+ Auto Response")
		f:SetHeight(490)

		local Main_Settings = CreateFrame("Frame", "AutoResponse_MainSettings", f)
		Main_Settings:SetSize(f:GetWidth() - (20 * 2), 120)
		Main_Settings:SetPoint("TOP", f, "TOP", 0, -40)
		Main_Settings.tex = Main_Settings:CreateTexture()
		Main_Settings.tex:SetAllPoints(Main_Settings)
		-- Main_Settings.tex:SetColorTexture(unpack(AMT.BackgroundHover))
		Main_Settings.tex:SetColorTexture(unpack(AMT.BackgroundClear))

		-- Setup whoToReplyTo Dropdown
		local whoToReplyTo = CreateFrame("DropdownButton", nil, Main_Settings, "WowStyle1DropdownTemplate")
		whoToReplyTo:SetWidth(180)
		whoToReplyTo:SetDefaultText(Mplus_AutoResponse.whoToReplyTo[AMT_DB.replyAfterComplete])
		whoToReplyTo:SetPoint("TOPLEFT", 10, -30)
		whoToReplyTo:SetupMenu(function(dropdown, rootDescription)
			for i = 1, #Mplus_AutoResponse.whoToReplyTo do
				-- Setup the Dropdown Options and update value of dropdown + DB Value on click
				rootDescription:CreateButton(Mplus_AutoResponse.whoToReplyTo[i], function()
					AMT_DB.replyAfterComplete = i
					whoToReplyTo:SetSelectionText(function()
						return Mplus_AutoResponse.whoToReplyTo[AMT_DB.replyAfterComplete]
					end)
				end)
			end
		end)

		local whoToReplyTo_Title = whoToReplyTo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		whoToReplyTo_Title:SetPoint("BOTTOMLEFT", whoToReplyTo, "TOPLEFT", 0, 4)
		whoToReplyTo_Title:SetText("Reply To:")

		-- Setup the Slider for Reply Cooldown
		local slider = CreateFrame("Slider", "ReplyCooldownSlider", Main_Settings, "OptionsSliderTemplate")
		slider:SetPoint("TOPLEFT", whoToReplyTo, "BOTTOMLEFT", 0, -30)
		slider:SetOrientation("HORIZONTAL")
		slider:SetSize(180, 20)
		slider:SetMinMaxValues(1, 5)
		slider:SetValue(AMT_DB.replyCooldown or 1)
		slider:SetValueStep(1)
		slider:SetObeyStepOnDrag(true)
		slider.Low:SetText("1")
		slider.High:SetText("5")
		slider.Text:SetText("|cffffd100Reply Cooldown: |r" .. slider:GetValue() .. " minute(s)")
		slider.Tooltip = "In minutes"
		slider:SetScript("OnValueChanged", function(self, value)
			AMT_DB.replyCooldown = value
			slider.Text:SetText("|cffffd100Reply Cooldown: |r" .. value .. " minute(s)")
		end)

		-- Setup Dungeon Name Dropdown Mplus_AutoResponse.DungeonNameType
		local DungeonNameType = CreateFrame("DropdownButton", nil, Main_Settings, "WowStyle1DropdownTemplate")
		DungeonNameType:SetWidth(180)
		DungeonNameType:SetDefaultText(Mplus_AutoResponse.DungeonNameType[AMT_DB.replyKeystoneNameType])
		DungeonNameType:SetPoint("TOPRIGHT", -10, -30)
		DungeonNameType:SetupMenu(function(dropdown, rootDescription)
			for i = 1, #Mplus_AutoResponse.DungeonNameType do
				-- Setup the Dropdown Options and update value of dropdown + DB Value on click
				rootDescription:CreateButton(Mplus_AutoResponse.DungeonNameType[i], function()
					AMT_DB.replyKeystoneNameType = i
					DungeonNameType:SetSelectionText(function()
						return Mplus_AutoResponse.DungeonNameType[AMT_DB.replyKeystoneNameType]
					end)
				end)
			end
		end)

		local DungeonNameType_Title = DungeonNameType:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		DungeonNameType_Title:SetPoint("BOTTOMLEFT", DungeonNameType, "TOPLEFT", 0, 4)
		DungeonNameType_Title:SetText("Dungeon Name Format:")

		-- Create Spam Toggle
		local SpamToggle = AMT.CreateCustomCheckbox(Main_Settings, "AMT_AutoResponse_AntiSpam", 26)
		SpamToggle:SetPoint("TOPRIGHT", DungeonNameType, "BOTTOMRIGHT", -40, -30)
		SpamToggle.Text = SpamToggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		SpamToggle.Text:SetPoint("RIGHT", SpamToggle, "LEFT", -10, 0)
		SpamToggle.Text:SetText("Anti-Spam")
		SpamToggle.dbKey = "antiSpam"
		SpamToggle:SetChecked(AMT_DB.antiSpam)
		SpamToggle.Tooltip = "Ignore Messages Generated by DBM or BigWigs"
		SpamToggle:SetScript("OnEnter", function(self)
			GameTooltip:Hide()
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(self.Text:GetText(), 1, 1, 1, true)
			GameTooltip:AddLine(self.Tooltip, 1, 0.82, 0, true)
			GameTooltip:Show()
		end)
		SpamToggle:SetScript("OnLeave", function(self)
			GameTooltip:Hide()
		end)

		-- Create the 3 different Categories: Friends, Guild Members, All
		for i = 1, 3 do
			local categories = {
				[1] = "Friends will receive information on...",
				[2] = "Guild Mates will receive information on...",
				[3] = "Everyone else will receive information on...",
			}
			local Category_Frame = CreateFrame("Frame", "AutoResponse_Category" .. i .. "Info", f)
			Category_Frame:SetSize(Main_Settings:GetWidth(), 100)
			Category_Frame.Border = CreateFrame("Frame", nil, Category_Frame, "DialogBorderNoCenterTemplate")
			Category_Frame.tex = Category_Frame:CreateTexture()
			Category_Frame.tex:SetAllPoints(Category_Frame)
			if i == 1 then
				Category_Frame:SetPoint("TOPLEFT", Main_Settings, "BOTTOMLEFT", 0, -10)
				Category_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))
			else
				local previousFrame = _G["AutoResponse_Category" .. (i - 1) .. "Info"]
				Category_Frame:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT")
				Category_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))
			end
			Category_Frame.text = Category_Frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			Category_Frame.text:SetText(categories[i])
			Category_Frame.text:SetPoint("TOPLEFT", 14, -14)
		end

		-- Create checkboxes for Friends
		local Cat_Friends = _G["AutoResponse_Category" .. 1 .. "Info"]
		for i = 1, 4 do
			local Info_Frame = CreateFrame("Frame", "Cat_Friends_Type" .. i, Cat_Friends)
			if i == 1 then
				Info_Frame:SetPoint("BOTTOMLEFT", Cat_Friends, "BOTTOMLEFT", 0, 0)
			else
				local previousFrame = _G["Cat_Friends_Type" .. (i - 1)]
				Info_Frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 10, 0)
			end
			Info_Frame:SetSize((Cat_Friends:GetWidth() / 4) * 0.9, 76)
			Info_Frame.tex = Info_Frame:CreateTexture()
			Info_Frame.tex:SetAllPoints(Info_Frame)
			Info_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))

			-- Checkbox
			local Info_Checkbox = AMT.CreateCustomCheckbox(Info_Frame, nil, 28)
			Info_Checkbox:SetPoint("CENTER")
			Info_Checkbox.dbKey = "replyInfoFriend." .. Mplus_AutoResponse.replyInfoType[i]
			Info_Checkbox:SetChecked(AMT_DB.replyInfoFriend[Mplus_AutoResponse.replyInfoType[i]])

			-- Label
			Info_Checkbox.Text = Info_Checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			Info_Checkbox.Text:SetPoint("BOTTOM", Info_Checkbox, "TOP", 0, 6)
			Info_Checkbox.Text:SetText(Mplus_AutoResponse.replyInfoType[i])
			Info_Checkbox.Text:SetJustifyH("CENTER")
		end

		-- Create checkboxes for Guild Mates
		local Cat_Guild = _G["AutoResponse_Category" .. 2 .. "Info"]
		for i = 1, 4 do
			local Info_Frame = CreateFrame("Frame", "Cat_Guild_Type" .. i, Cat_Guild)
			if i == 1 then
				Info_Frame:SetPoint("BOTTOMLEFT", Cat_Guild, "BOTTOMLEFT", 0, 0)
			else
				local previousFrame = _G["Cat_Guild_Type" .. (i - 1)]
				Info_Frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 10, 0)
			end
			Info_Frame:SetSize((Cat_Guild:GetWidth() / 4) * 0.9, 76)
			Info_Frame.tex = Info_Frame:CreateTexture()
			Info_Frame.tex:SetAllPoints(Info_Frame)
			Info_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))

			-- Checkbox
			local Info_Checkbox = AMT.CreateCustomCheckbox(Info_Frame, nil, 28)
			Info_Checkbox:SetPoint("CENTER")
			Info_Checkbox.dbKey = "replyInfoGuild." .. Mplus_AutoResponse.replyInfoType[i]
			Info_Checkbox:SetChecked(AMT_DB.replyInfoGuild[Mplus_AutoResponse.replyInfoType[i]])

			-- Label
			Info_Checkbox.Text = Info_Checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			Info_Checkbox.Text:SetPoint("BOTTOM", Info_Checkbox, "TOP", 0, 6)
			Info_Checkbox.Text:SetText(Mplus_AutoResponse.replyInfoType[i])
			Info_Checkbox.Text:SetJustifyH("CENTER")
		end

		-- Create checkboxes for All Others
		local Cat_All = _G["AutoResponse_Category" .. 3 .. "Info"]
		for i = 1, 4 do
			local Info_Frame = CreateFrame("Frame", "Cat_All_Type" .. i, Cat_All)
			if i == 1 then
				Info_Frame:SetPoint("BOTTOMLEFT", Cat_All, "BOTTOMLEFT", 0, 0)
			else
				local previousFrame = _G["Cat_All_Type" .. (i - 1)]
				Info_Frame:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT", 10, 0)
			end
			Info_Frame:SetSize((Cat_All:GetWidth() / 4) * 0.9, 76)
			Info_Frame.tex = Info_Frame:CreateTexture()
			Info_Frame.tex:SetAllPoints(Info_Frame)
			Info_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))

			-- Checkbox
			local Info_Checkbox = AMT.CreateCustomCheckbox(Info_Frame, nil, 28)
			Info_Checkbox:SetPoint("CENTER")
			Info_Checkbox.dbKey = "replyInfoUnknown." .. Mplus_AutoResponse.replyInfoType[i]
			Info_Checkbox:SetChecked(AMT_DB.replyInfoUnknown[Mplus_AutoResponse.replyInfoType[i]])

			-- Label
			Info_Checkbox.Text = Info_Checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			Info_Checkbox.Text:SetPoint("BOTTOM", Info_Checkbox, "TOP", 0, 6)
			Info_Checkbox.Text:SetText(Mplus_AutoResponse.replyInfoType[i])
			Info_Checkbox.Text:SetJustifyH("CENTER")
		end
	end
	self.OptionFrame = _G["AMT_AutoResponse"]
end
function Mplus_AutoResponse:ShowOptions(state)
	if state then
		self:CreateOptions()
		self.OptionFrame:Show()
		-- self.OptionFrame.requireResetPosition = false
		self.OptionFrame:ClearAllPoints()
		self.OptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	else
		if self.OptionFrame then
			self.OptionFrame:Hide()
		end
	end
end

function AMT:AutoResponse_ToggleConfig()
	if Mplus_AutoResponse.OptionFrame and Mplus_AutoResponse.OptionFrame:IsShown() then
		Mplus_AutoResponse:ShowOptions(false)
	else
		Mplus_AutoResponse:ShowOptions(true)
	end
end

do
	local function EnableModule(state)
		if state then
			Mplus_AutoResponse:EnableShowKeys()
			AMT.DefaultValues["Mplus_AutoResponse"] = not AMT.DefaultValues["Mplus_AutoResponse"]
			AMT:PrintDebug("Mplus_AutoResponse = " .. tostring(AMT.db["Mplus_AutoResponse"]))
		else
			Mplus_AutoResponse:DisableShowKeys()
			AMT:PrintDebug("Mplus_AutoResponse = " .. tostring(AMT.db["Mplus_AutoResponse"]))
		end
	end

	local function OptionToggle_OnClick(self, button)
		if Mplus_AutoResponse.OptionFrame and Mplus_AutoResponse.OptionFrame:IsShown() then
			Mplus_AutoResponse:ShowOptions(false)
		else
			Mplus_AutoResponse:ShowOptions(true)
		end
	end

	local moduleData = {
		name = "M+ Auto Response",
		dbKey = "Mplus_AutoResponse",
		description = "If a whisper is received while in an M+ dungeon, send an automatic reply.",
		toggleFunc = EnableModule,
		categoryID = 2,
		uiOrder = 2,
		optionToggleFunc = OptionToggle_OnClick,
	}

	AMT.Config:AddModule(moduleData)
end
