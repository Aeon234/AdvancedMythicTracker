local AMT = select(2, ...)

local Util = AMT.Util
local Modules = AMT.Modules

-- Incase I need to force Profile Upgrades
local PROFILE_VERSION = 1

---@class AMTLayoutElementSettings
---@field enabled boolean
---@field nudge number[] {x, y}

---@class AMTLayoutOrder
---@field groups AMTLayoutGroupKey[]
---@field keyInfo string[]
---@field timer string[]
---@field objectives string[]
---@field forces string[]

---@class AMTBarProfile
---@field texture string
---@field height number
---@field color number[]
---@field background number[]

---@class AMTTextProfile
---@field font string
---@field size number
---@field outline AMTFontOutline
---@field color number[]

---@class AMTTimerProfile
---@field scale number
---@field position AMTFramePosition
---@field order AMTLayoutOrder
---@field elements table<string, AMTLayoutElementSettings>
---@field bar AMTBarProfile
---@field text AMTTextProfile

---@class AMTProfile
---@field version integer
---@field timer AMTTimerProfile

---@type AMTProfile
local profileDefaults = {
	version = PROFILE_VERSION,
	timer = {
		scale = 1.0,
		position = { anchor = "RIGHT", x = 0, y = -10 },
		order = {
			groups = { "keyInfo", "timer", "objectives", "forces" },
			keyInfo = {},
			timer = {},
			objectives = {},
			forces = {},
		},
		elements = {},
		bar = {
			texture = "Blizzard",
			height = 24,
			color = { 0.2, 0.6, 1, 1 },
			background = { 0, 0, 0, 0.5 },
		},
		text = {
			font = "Friz Quadrata TT",
			size = 16,
			outline = "OUTLINE",
			color = { 1, 1, 1, 1 },
		},
	},
}

---@class AMTProfiles
---@field active AMTProfile!
---@field activeName string!
local Profiles = {}
AMT.Profiles = Profiles

---@return string
local function CharacterKey()
	local name = UnitName("player") or "Unknown"
	local realm = GetNormalizedRealmName() or GetRealmName() or "Unknown"

	return name .. "-" .. realm
end

---Create profile if nil or return an existing one, making sure it adheres to current profile schema.
---@param name string
---@return AMTProfile
function Profiles.Create(name)
	local settings = AMT.DB.settings
	local profile = settings.profiles[name]

	if not profile then
		profile = Util.Copy(profileDefaults)
		settings.profiles[name] = profile
	else
		Util.MergeDefaults(profile, profileDefaults)
	end

	return profile
end

function Profiles.Initialize()
	local settings = AMT.DB.settings
	local name = settings.profileKeys[CharacterKey()] or settings.defaultProfile

	Profiles.activeName = name
	Profiles.active = Profiles.Create(name)
end

---@param name string
function Profiles.Activate(name)
	AMT.DB.settings.profileKeys[CharacterKey()] = name
	Profiles.activeName = name
	Profiles.active = Profiles.Create(name)

	for module in Modules.Iterate() do
		if module.OnProfileChanged then
			module:OnProfileChanged()
		end
	end
end

---@param name string
function Profiles.SetDefaultForNewCharacters(name)
	local settings = AMT.DB.settings

	settings.defaultProfile = name
	Profiles.Create(name)

	if not settings.profileKeys[CharacterKey()] then
		Profiles.activeName = name
		Profiles.active = settings.profiles[name]

		for module in Modules.Iterate() do
			if module.OnProfileChanged then
				module:OnProfileChanged()
			end
		end
	end
end
