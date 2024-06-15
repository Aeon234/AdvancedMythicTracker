local addonName, AMT = ...

local EventListenerFrame = CreateFrame("Frame")

-- Create a font string to display the message
local GroupKeysFrame = CreateFrame("Frame", nil, UIParent)
GroupKeysFrame:SetSize(300, 100)
GroupKeysFrame:SetPoint("CENTER", UIParent, "CENTER")
GroupKeysFrame:Hide()

local GroupKeysText = GroupKeysFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
GroupKeysText:SetPoint("CENTER", GroupKeysFrame, "CENTER")
GroupKeysText:SetText("Ready Check started")

-- Function to show and hide the message
local function ShowRelevantKeysMessage()
	local _, _, _, _, _, _, _, CurrentInstanceID = GetInstanceInfo()

	GroupKeysFrame:Show()
	C_Timer.After(10, function()
		GroupKeysFrame:Hide()
	end)
end

-- Event handler function
local function AMT_EventHandler(self, event, ...)
	local inInstance, instanceType = IsInInstance()
	if event == "READY_CHECK" and self.DetailsEnabled and inInstance and instanceType == "party" then
		ShowRelevantKeysMessage()
	end
end

-- Register for the READY_CHECK event
EventListenerFrame:RegisterEvent("READY_CHECK")
EventListenerFrame:SetScript("OnEvent", AMT_EventHandler)
