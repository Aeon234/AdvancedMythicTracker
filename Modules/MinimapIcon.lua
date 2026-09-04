local AMT = select(2, ...)
local L = AMT.L

local ICON = 4352494

---@class AMTMinimapIconModule : AMTModule
---@field icon table? LibDBIcon-1.0
local module = AMT.Modules.New("MinimapIcon")

function module:OnInitialize()
	local broker = LibStub("LibDataBroker-1.1", true)
	local icon = LibStub("LibDBIcon-1.0", true)

	if not broker or not icon then
		AMT.Util.Warn("the minimap icon needs LibDataBroker-1.1 and LibDBIcon-1.0.")

		return
	end

	local launcher = broker:NewDataObject(AMT.name, {
		type = "launcher",
		icon = ICON,
		OnClick = function(_, button)
			if button == "RightButton" then
				AMT.Demo.Toggle(false)

				return
			end

			AMT.Options.Toggle()
		end,
		OnTooltipShow = function(tooltip)
			tooltip:AddLine(AMT.name)
			tooltip:AddLine(L["Left click: open configuration"], 1, 1, 1)
			tooltip:AddLine(L["Right click: toggle preview"], 1, 1, 1)
		end,
	})

	icon:Register(AMT.name, launcher, AMT.DB.settings.minimapIcon)

	self.icon = icon
end

---@return boolean
function module:IsShown()
	return not AMT.DB.settings.minimapIcon.hide
end

---@param shown boolean
function module:SetShown(shown)
	AMT.DB.settings.minimapIcon.hide = not shown

	if not self.icon then
		return
	end

	if shown then
		self.icon:Show(AMT.name)
	else
		self.icon:Hide(AMT.name)
	end
end
