local addonName, AMT = ...
local API = AMT.API

-- change order to be a saved variable and make settings to change which markers to go through, plus if you can re-arrange the order.
local TEXT_WIDTH = 200
local WorldMarkerCycler = CreateFrame("Frame")
WorldMarkerCycler:RegisterEvent("ADDON_LOADED")

local order = { 5, 6, 3, 2, 7, 1, 4, 8 }
-- local order = { 5, 6, 3, 2 } --Brppdtwoster
function WorldMarkerCycler:Placer_Init()
	local Placer_Button
	if not _G["WorldMarker_Placer"] then
		Placer_Button = CreateFrame("Button", "WorldMarker_Placer", nil, "SecureActionButtonTemplate")
		Placer_Button:SetAttribute("pressAndHoldAction", true)
		Placer_Button:SetAttribute("typerelease", "macro")
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
	end
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
		WorldMarkerCycler:Init()
	end
end)

function WorldMarkerCycler:IsFocused()
	return (self:IsShown() and self:IsMouseOver())
		or (self.OptionFrame and self.OptionFrame:IsShown() and self.OptionFrame:IsMouseOver())
end

---- Edit Mode
function WorldMarkerCycler:EnterEditMode()
	if not self.enabled then
		return
	end

	if not self.Selection then
		local uiName = "Relevant Mythic+ Keystones"
		local hideLabel = true
		self.Selection = AMT.CreateEditModeSelection(self, uiName, hideLabel)
	end

	self.isEditing = true
	self:SetScript("OnUpdate", nil)
	-- FadeFrame(self, 0, 1)
end

function WorldMarkerCycler:ExitEditMode()
	if self.Selection then
		self.Selection:Hide()
	end
	self:ShowOptions(false)
	self.isEditing = false
	self:CloseImmediately()
end

function WorldMarkerCycler:ShowOptions(state)
	if state then
		self:CreateOptions()
		self.OptionFrame:Show()
		if self.OptionFrame.requireResetPosition then
			self.OptionFrame.requireResetPosition = false
			self.OptionFrame:ClearAllPoints()
			self.OptionFrame:SetPoint("LEFT", UIParent, "CENTER", TEXT_WIDTH * 0.5, 0)
		end
	else
		if self.OptionFrame then
			self.OptionFrame:Hide()
		end
		if not API.IsInEditMode() then
			self:CloseImmediately()
		end
	end
end

local function testoutput()
	print("star toggled")
end
local OPTIONS_SCHEMATIC = {
	title = "World Marker Cycler Options",
	widgets = {
		{ type = "Divider" },
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker8", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker7", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker6", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker5", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker4", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker3", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker2", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
		{
			type = "Checkbox",
			label = CreateAtlasMarkup("GM-raidMarker1", 32, 32),
			onClickFunc = testoutput,
			dbKey = "Cycler_Star",
		},
	},
}

function WorldMarkerCycler:CreateOptions()
	-- self.OptionFrame = AMT.SetupSettingsDialog(self, OPTIONS_SCHEMATIC)
	local f
	if not _G["AMT_Cycler_OptionsPane"] then
		f = CreateFrame("Frame", "AMT_Cycler_OptionsPane", UIParent)
		f:Hide()
		f:SetSize(300, 350)
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		f:SetMovable(true)
		f:SetClampedToScreen(true)
		f:RegisterForDrag("LeftButton")
		f:SetDontSavePosition(true)
		f:SetFrameStrata("DIALOG")
		f:SetFrameLevel(200)
		f:EnableMouse(true)
		f:SetScript("OnDragStart", function(self, button)
			self:StartMoving()
		end)
		f:SetScript("OnDragStop", function(self, button)
			self:StopMovingOrSizing()
		end)

		f.Border = CreateFrame("Frame", nil, f, "DialogBorderTranslucentTemplate")
		f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
		f.CloseButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
		f.CloseButton:SetScript("OnClick", function()
			f:Hide()
			f:ClearAllPoints()
			f.requireResetPosition = true
			if f.parent then
				if f.parent.Selection then
					f.parent.Selection:ShowHighlighted()
				end
				if f.parent.ExitEditMode and not API.IsInEditMode() then
					f.parent:ExitEditMode()
				end
				f.parent = nil
			end
		end)
		f.Title = f:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
		f.Title:SetPoint("TOP", f, "TOP", 0, -16)
		f.Title:SetText("World Marker Cycler Options")

		-- local b1 = AMT:CreateCheckbox()
	end
	self.OptionFrame = _G["AMT_Cycler_OptionsPane"]
end

function WorldMarkerCycler:CloseImmediately()
	if self.voHandle then
		StopSound(self.voHandle)
	end
	self.lastName = nil
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
			WorldMarkerCycler:ExitEditMode()
		else
			WorldMarkerCycler:EnterEditMode()
			WorldMarkerCycler:ShowOptions(true)
		end
	end

	local moduleData = {
		name = "World Marker Cycler",
		dbKey = "WorldMarkerCycler",
		description = "Assign a keybind and cycle through all available world markers wih each click. Placing each marker at your mouse location. By default all world markers are enabled, but you can configure which world markers it should cycle through.",
		toggleFunc = EnableModule,
		categoryID = 1,
		uiOrder = 1,
		optionToggleFunc = OptionToggle_OnClick,
	}

	-- AMT.Config:AddModule(moduleData)
end
