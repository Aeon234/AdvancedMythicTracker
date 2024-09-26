local addonName, AMT = ...
local API = AMT.API

-- change order to be a saved variable and make settings to change which markers to go through, plus if you can re-arrange the order.
local TEXT_WIDTH = 200
local WorldMarkerCycler = CreateFrame("Frame")
WorldMarkerCycler:RegisterEvent("ADDON_LOADED")

-- local order = { 5, 6, 3, 2, 7, 1, 4, 8 }
-- local order = { 5, 6, 3, 2 } --Brppdtwoster
local order = {}
function WorldMarkerCycler:Placer_Init()
	local Placer_Button
	if not _G["WorldMarker_Placer"] then
		Placer_Button = CreateFrame("Button", "WorldMarker_Placer", nil, "SecureActionButtonTemplate")
		Placer_Button:SetAttribute("pressAndHoldAction", true)
		Placer_Button:SetAttribute("typerelease", "macro")
		Placer_Button:HookScript("PreClick", function(self)
			if not IsInRaid() and not IsInGroup() then
				return
			end
		end)
		Placer_Button:HookScript("PostClick", function(self)
			if not IsInRaid() and not IsInGroup() then
				return
			end
			if not self:GetAttribute("enableMarkers") then
				AMT:PrintDebug("Marker placement disabled")
			else
				local MarkerNum
				for _, marker in ipairs(AMT.WorldMarkers) do
					if marker.wmID == self:GetAttribute("WorldMarker_Previous") then
						MarkerNum = "GM-raidMarker" .. marker.textAtlas
					end
				end
				AMT:PrintDebug(CreateAtlasMarkup(MarkerNum) .. " Marker Placed")
			end
		end)
	else
		Placer_Button = _G["WorldMarker_Placer"]
	end
	Placer_Button:SetAttribute("WorldMarker_Current", order[1])
	Placer_Button:SetAttribute("WorldMarker_Previous", 0)

	local body = "i = 0;order = newtable()"
	for _, index in ipairs(order) do
		body = body .. format("tinsert(order, %s)", index)
	end
	SecureHandlerExecute(Placer_Button, body)

	SecureHandlerWrapScript(
		Placer_Button,
		"PreClick",
		Placer_Button,
		[=[
				if not self:GetAttribute("enableMarkers") then
					self:SetAttribute("macrotext", "")   
					return
				else
					self:SetAttribute("macrotext", "/wm [@cursor]"..self:GetAttribute("WorldMarker_Current"))
					if self:GetAttribute("WorldMarker_Previous") == 0 and self:GetAttribute("WorldMarker_Current") == order[1] then
						i=2
						self:SetAttribute("WorldMarker_Previous", self:GetAttribute("WorldMarker_Current"))
						self:SetAttribute("WorldMarker_Current", order[i])
					else
						i = i%#order + 1
						self:SetAttribute("WorldMarker_Previous", self:GetAttribute("WorldMarker_Current"))
						self:SetAttribute("WorldMarker_Current", order[i])
					end
				end
			]=]
	)
end

function WorldMarkerCycler:Remover_Init()
	local Remover_Button
	local Placer_Button = _G["WorldMarker_Placer"]
	if not _G["WorldMarker_Remover"] then
		Remover_Button = CreateFrame("Button", "WorldMarker_Remover", nil, "SecureActionButtonTemplate")
		Remover_Button:SetAttribute("type", "macro")
		Remover_Button:SetScript("PreClick", function(self)
			if not InCombatLockdown() then
				Placer_Button:SetAttribute("WorldMarker_Current", order[1])
				Placer_Button:SetAttribute("WorldMarker_Previous", 0)
			end
			ClearRaidMarker()
		end)
	end
end

function WorldMarkerCycler:Init()
	WorldMarkerCycler:Placer_Init()
	WorldMarkerCycler:Remover_Init()
end

WorldMarkerCycler:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if name == addonName then
		self:UnregisterEvent(event)
		order = AMT_DB.WorldMarkerCycler_Order
		WorldMarkerCycler:Init()
	end
end)

function WorldMarkerCycler:IsFocused()
	return (self:IsShown() and self:IsMouseOver())
		or (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

function WorldMarkerCycler:ShowOptions(state)
	if state then
		self:CreateOptions()
		for i = 1, #AMT.WorldMarkers do
			local checkbox = _G["AMT_Cycler_" .. AMT.WorldMarkers[i].icon .. "_Button"]
			for key, value in pairs(AMT_DB) do
				if string.sub(key, 1, 7) == "Cycler_" then
					if key == "Cycler_" .. AMT.WorldMarkers[i].icon then
						checkbox:SetChecked(value)
					end
				end
			end
		end
		self.OptionFrame:Show()
		self.OptionFrame.requireResetPosition = false
		self.OptionFrame:ClearAllPoints()
		self.OptionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	else
		if self.OptionFrame then
			self.OptionFrame:Hide()
		end
	end
end

local function ToggleWorldMarker(self)
	local new_WorldMarkerCycler_Order = {}
	for i = 1, #AMT.WorldMarkers do
		local checkbox = _G["AMT_Cycler_" .. AMT.WorldMarkers[i].icon .. "_Button"]
		for key, value in pairs(AMT_DB) do
			if string.sub(key, 1, 7) == "Cycler_" then
				if key == "Cycler_" .. AMT.WorldMarkers[i].icon and value then
					tinsert(new_WorldMarkerCycler_Order, AMT.WorldMarkers[i].wmID)
				end
			end
		end
	end
	AMT_DB.WorldMarkerCycler_Order = new_WorldMarkerCycler_Order
	order = AMT_DB.WorldMarkerCycler_Order
	WorldMarkerCycler:Init()
end

function WorldMarkerCycler:CreateOptions()
	-- self.OptionFrame = AMT.SetupSettingsDialog(self, OPTIONS_SCHEMATIC)
	local f
	if not _G["AMT_Cycler_OptionsPane"] then
		f = AMT:CreateOptionsPane("AMT_Cycler_OptionsPane")
		f.Title:SetText("World Marker Cycler Options")

		for i = 1, #AMT.WorldMarkers do
			if not _G["WMFrame" .. i] then
				-- Frame
				local WM_Frame = CreateFrame("Frame", "WMFrame" .. i, f)
				if i == 1 then
					WM_Frame:SetPoint("LEFT", f, "LEFT", 28, -16)
				else
					local previous = _G["WMFrame" .. (i - 1)]
					WM_Frame:SetPoint("LEFT", previous, "RIGHT", 0, 0)
				end
				WM_Frame:SetSize(48, 100)
				WM_Frame.tex = WM_Frame:CreateTexture()
				WM_Frame.tex:SetAllPoints(WM_Frame)
				WM_Frame.tex:SetColorTexture(unpack(AMT.BackgroundClear))

				--Icon
				WM_Icon = WM_Frame:CreateFontString("WMIcon_" .. i, "OVERLAY", "GameFontNormalLarge")
				WM_Icon:SetText(CreateAtlasMarkup("GM-raidMarker" .. (#AMT.WorldMarkers + 1 - i), 32, 32))
				WM_Icon:SetPoint("TOP", WM_Frame, "TOP", 0, -8)

				-- Checkbox
				local WM_Button =
					AMT.CreateCustomCheckbox(WM_Frame, "AMT_Cycler_" .. AMT.WorldMarkers[i].icon .. "_Button", 28)
				WM_Button:SetPoint("TOP", WM_Icon, "BOTTOM", 0, -8)
				WM_Button.dbKey = "Cycler_" .. AMT.WorldMarkers[i].icon
				WM_Button.onClickFunc = ToggleWorldMarker
			end
		end
	end
	self.OptionFrame = _G["AMT_Cycler_OptionsPane"]
end

function WorldMarkerCycler:CloseImmediately()
	if self.voHandle then
		StopSound(self.voHandle)
	end
	self.lastName = nil
end

function AMT:WorldMarkerCycler_ToggleConfig()
	if WorldMarkerCycler.OptionFrame and WorldMarkerCycler.OptionFrame:IsShown() then
		WorldMarkerCycler:ShowOptions(false)
	else
		WorldMarkerCycler:ShowOptions(true)
	end
end

do
	local function EnableModule(state)
		local Placer_Button = _G["WorldMarker_Placer"]
		if state then
			AMT.DefaultValues["WorldMarkerCycler"] = not AMT.DefaultValues["WorldMarkerCycler"]
			Placer_Button:SetAttribute("enableMarkers", AMT.db["WorldMarkerCycler"])
			AMT:PrintDebug("WorldMarkerCycler = " .. tostring(AMT.db["WorldMarkerCycler"]))
		else
			AMT:PrintDebug("WorldMarkerCycler = " .. tostring(AMT.db["WorldMarkerCycler"]))
			Placer_Button:SetAttribute("enableMarkers", AMT.db["WorldMarkerCycler"])
		end
	end

	local function OptionToggle_OnClick(self, button)
		if WorldMarkerCycler.OptionFrame and WorldMarkerCycler.OptionFrame:IsShown() then
			WorldMarkerCycler:ShowOptions(false)
		else
			WorldMarkerCycler:ShowOptions(true)
		end
	end

	local moduleData = {
		name = "World Marker Cycler",
		dbKey = "WorldMarkerCycler",
		description = "Assign a keybind and cycle through all available world markers wih each click. Placing each marker at your mouse location. By default all world markers are enabled, but you can configure which world markers it should cycle through.\n\nAlternatively, type '/amt wm' to access the same menu.",
		toggleFunc = EnableModule,
		categoryID = 1,
		uiOrder = 1,
		optionToggleFunc = OptionToggle_OnClick,
	}

	AMT.Config:AddModule(moduleData)
end
