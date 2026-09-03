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
---@field Demo AMTDemo
---@field Locale AMTLocaleUtil
---@field Options AMTOptions
---@field Style AMTStyle
---@field NineSlice AMTNineSlice
---@field Splits AMTSplits
---@field Tooltip AMTTooltip
---@field Animation AMTAnimation
local AMT = select(2, ...)

AMT.name = addonName
AMT.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or ERROR_CAPS

-- AMT API exposed to other addons. Here just in case in future I want to expose anything.
-- ---@class AMTAPI
-- ---@field version integer
-- AMTAPI = { version = 1 }

SLASH_ADVANCEDMYTHICTRACKER1 = "/amt"

SlashCmdList.ADVANCEDMYTHICTRACKER = function(msg)
	local command, argument = (msg or ""):lower():match("^%s*(%S*)%s*(%S*)")

	if command == "demo" then
		AMT.Demo.Toggle(argument == "live")
	elseif command == "style" then
		if AMT.Style.Apply(argument:upper()) then
			AMT.Util.Print("style set to %s.", argument:upper())
		end
	elseif command == "undo" then
		AMT.Style.Undo()
	elseif command == "version" then
		AMT.Util.Print("v%s", AMT.version)
	else
		AMT.Options.Toggle()
	end
end
