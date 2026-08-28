---@type string
local addonName = ...

---@class AMT
---@field name string
---@field version string
---@field DB AMTDB
---@field Util AMTUtil
---@field L AMTLocale
---@field Modules AMTModules
---@field Events AMTEvents
---@field Profiles AMTProfiles
---@field State AMTState
local AMT = select(2, ...)

AMT.name = addonName
AMT.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ERROR_CAPS

-- AMT API exposed to other addons. Here just in case in future I want to expose anything.
-- ---@class AMTAPI
-- ---@field version integer
-- AMTAPI = { version = 1 }

SLASH_ADVANCEDMYTHICTRACKER1 = "/amt"

SlashCmdList.ADVANCEDMYTHICTRACKER = function()
	print(("%s v%s"):format(AMT.name, AMT.version))
end
