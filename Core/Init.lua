---@type string
local addonName = ...

---@class AMT
---@field name string
---@field version string
local AMT = select(2, ...)

AMT.name = addonName
AMT.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ERROR_CAPS

---@class AMTAPI
---@field version integer
AMTAPI = { version = 1 }

SLASH_ADVANCEDMYTHICTRACKER1 = "/amt"

SlashCmdList.ADVANCEDMYTHICTRACKER = function()
	print(("%s v%s"):format(AMT.name, AMT.version))
end
