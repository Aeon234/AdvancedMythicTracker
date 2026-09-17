local AMT = select(2, ...)
local L = AMT.L

local ICON = 4352494

---@class AMTAddonCompartmentModule : AMTModule
---@field entry table? the row this module owns in AddonCompartmentFrame.registeredAddons
local module = AMT.Modules.New("AddonCompartment")

---@return table? frame
local function Compartment()
	local frame = AddonCompartmentFrame

	if type(frame) ~= "table" or type(frame.registeredAddons) ~= "table" then
		return nil
	end

	return frame
end

---@param button table
local function ShowTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine(AMT.name)
	GameTooltip:AddLine(L["Left click: open configuration"], 1, 1, 1)
	GameTooltip:AddLine(L["Right click: toggle preview"], 1, 1, 1)
	GameTooltip:Show()
end

function module:Register()
	local frame = Compartment()

	if not frame or self.entry then
		return
	end

	self.entry = {
		text = AMT.title,
		icon = ICON,
		func = function(_, inputData)
			if inputData and inputData.buttonName == "RightButton" then
				AMT.Demo.Toggle(false)

				return
			end

			AMT.Options.Toggle()
		end,
		funcOnEnter = ShowTooltip,
		funcOnLeave = function()
			GameTooltip:Hide()
		end,
	}

	frame:RegisterAddon(self.entry)
end

function module:Unregister()
	local frame = Compartment()

	if not frame or not self.entry then
		return
	end

	for index, data in ipairs(frame.registeredAddons) do
		if data == self.entry then
			table.remove(frame.registeredAddons, index)

			break
		end
	end

	self.entry = nil

	if frame.UpdateDisplay then
		frame:UpdateDisplay()
	end
end

---@return boolean
function module:IsShown()
	return AMT.DB.settings.addonCompartment == true
end

---@param shown boolean
function module:SetShown(shown)
	AMT.DB.settings.addonCompartment = shown

	if shown then
		self:Register()
	else
		self:Unregister()
	end
end

function module:OnEnable()
	if self:IsShown() then
		self:Register()
	end
end
