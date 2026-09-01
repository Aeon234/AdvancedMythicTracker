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
---@field Challenge AMTChallenge
---@field Forces AMTForces
---@field Deaths AMTDeaths
---@field Objectives AMTObjectives
---@field Pull AMTPull
---@field Providers AMTProviders
---@field Media AMTMedia
---@field Mixins AMTMixins
---@field Frames AMTFrames
---@field Layout AMTLayout
---@field Render AMTRender
local AMT = select(2, ...)

AMT.name = addonName
AMT.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ERROR_CAPS

-- AMT API exposed to other addons. Here just in case in future I want to expose anything.
-- ---@class AMTAPI
-- ---@field version integer
-- AMTAPI = { version = 1 }

SLASH_ADVANCEDMYTHICTRACKER1 = "/amt"

SlashCmdList.ADVANCEDMYTHICTRACKER = function()
	AMT.Util.Print("v%s", AMT.version)
end
