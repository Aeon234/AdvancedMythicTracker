local AMT = select(2, ...)
local L = AMT.L

local Util = AMT.Util
local Modules = AMT.Modules

-- Incase I need to force Profile Upgrades
local PROFILE_VERSION = 1
local EXPORT_FORMAT = 1

---@class AMTLayoutElementSettings
---@field enabled boolean
---@field nudge number[] {x, y}
---@field slot "LEFT"|"CENTER"|"RIGHT"

---@class AMTLayoutOrder
---@field groups AMTLayoutGroupKey[]
---@field keyInfo string[]
---@field timer string[]
---@field objectives string[]
---@field forces string[]

---@class AMTThresholdSettings
---@field enabled boolean
---@field marks "TICK"|"TEXT"|"BOTH"
---@field tickColor number[]
---@field aheadColor number[]
---@field behindColor number[]
---@field text AMTTextStyle

-- Timer Key Info
---@class AMTKeyInfoProfile
---@field height number
---@field inline boolean
---@field show "LEVEL"|"NAME"|"BOTH"
---@field order "LEVEL_FIRST"|"NAME_FIRST"
---@field text AMTTextStyle
---@field level AMTTextStyle

-- Timer Affixes
---@class AMTAffixesProfile
---@field height number
---@field widget "ICON"|"TEXT"
---@field justify "LEFT"|"CENTER"|"RIGHT"
---@field iconSize number
---@field spacing number
---@field separator string
---@field text AMTTextStyle

-- Timer Background
---@class AMTBackgroundProfile
---@field enabled boolean
---@field color number[]
---@field padding number
---@field nineslice boolean

-- Timer Forces
---@class AMTOverlayTextSettings
---@field enabled boolean
---@field slot "LEFT"|"CENTER"|"RIGHT"
---@field text AMTTextStyle

---@class AMTForcesProfile
---@field bar AMTBarStyle
---@field count AMTOverlayTextSettings
---@field percent AMTOverlayTextSettings
---@field decimals integer
---@field spacedSlash boolean
---@field completedColor number[]
---@field showRemaining boolean

-- Timer Objectives
---@class AMTObjectivesProfile
---@field rowHeight number
---@field spacing number
---@field icon boolean
---@field iconSize number
---@field showTime boolean
---@field text AMTTextStyle
---@field time AMTTextStyle
---@field completedColor number[]
---@field pendingColor number[]

-- Timer Boss Splits
---@class AMTElementTextSettings
---@field enabled boolean
---@field text AMTTextStyle

-- Timer Splits
---@class AMTSplitsProfile
---@field overall "ALWAYS"|"COUNTDOWN_AND_AFTER"|"NEVER"
---@field boss "ALWAYS"|"AFTER"
---@field decimals integer
---@field aheadColor number[]
---@field equalColor number[]
---@field behindColor number[]
---@field pbCompare AMTOverlayTextSettings
---@field forcesSplit AMTOverlayTextSettings
---@field bossSplit AMTElementTextSettings

-- Timer Deaths
---@class AMTDeathsProfile
---@field height number
---@field label "SKULL"|"TEXT"|"NONE"
---@field iconSize number
---@field penalty boolean
---@field brackets "PAREN"|"SQUARE"
---@field justify "LEFT"|"CENTER"|"RIGHT"
---@field text AMTTextStyle
---@field tooltip boolean

---@class AMTTimerProfile
---@field style "MINIMAL"|"PANEL"|"AEON"
---@field scale number
---@field width number
---@field geometry "SPAN"|"SIZED"
---@field contentWidth number
---@field justify "LEFT"|"CENTER"|"RIGHT"
---@field position AMTFramePosition
---@field order AMTLayoutOrder
---@field elements table<string, AMTLayoutElementSettings>
---@field direction "UP"|"DOWN"
---@field decimals integer
---@field successColor number[]
---@field failColor number[]
---@field bar AMTBarStyle
---@field text AMTTextStyle
---@field spacedSlash boolean
---@field thresholds AMTThresholdSettings[]
---@field keyInfo AMTKeyInfoProfile
---@field affixes AMTAffixesProfile
---@field deaths AMTDeathsProfile
---@field forces AMTForcesProfile
---@field objectives AMTObjectivesProfile
---@field splits AMTSplitsProfile
---@field background AMTBackgroundProfile
---@field __preTimerStyleBackup AMTTimerProfile?

---@class AMTProfile
---@field version integer
---@field timer AMTTimerProfile

---@type AMTProfile
local profileDefaults = {
	version = PROFILE_VERSION,
	timer = {
		style = "PANEL",
		scale = 1.0,
		width = 320,
		geometry = "SPAN",
		contentWidth = 200,
		justify = "RIGHT",
		position = { anchor = "RIGHT", x = 0, y = -10 },
		order = {
			groups = { "keyInfo", "timer", "objectives", "forces" },
			keyInfo = {},
			timer = {},
			objectives = {},
			forces = {},
		},
		elements = {},
		direction = "UP",
		decimals = 1,
		successColor = { 1, 1, 0, 1 },
		failColor = { 1, 0, 0, 1 },
		bar = {
			texture = "Blizzard",
			height = 24,
			color = { 0.2, 0.6, 1, 1 },
			background = { 0, 0, 0, 0.5 },
			-- Depleted, +1, +2, +3.
			tierColors = {
				{ 89 / 255, 90 / 255, 92 / 255, 1 },
				{ 1, 112 / 255, 0, 1 },
				{ 1, 1, 0, 1 },
				{ 128 / 255, 1, 0, 1 },
			},
		},
		text = {
			font = "Friz Quadrata TT",
			size = 16,
			outline = "OUTLINE",
			color = { 1, 1, 1, 1 },
		},
		spacedSlash = true,
		thresholds = {
			{
				enabled = true,
				marks = "TEXT",
				tickColor = { 1, 1, 1, 0.5 },
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			{
				enabled = true,
				marks = "BOTH",
				tickColor = { 1, 1, 1, 0.5 },
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			{
				enabled = true,
				marks = "BOTH",
				tickColor = { 1, 1, 1, 0.5 },
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
		},
		keyInfo = {
			height = 18,
			inline = false,
			show = "BOTH",
			order = "LEVEL_FIRST",
			text = { font = "Friz Quadrata TT", size = 14, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			level = { font = "Friz Quadrata TT", size = 14, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
		},
		affixes = {
			height = 18,
			widget = "ICON",
			justify = "RIGHT",
			iconSize = 16,
			spacing = 2,
			separator = " - ",
			text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 0.7, 0.7, 0.7, 1 } },
		},
		deaths = {
			height = 16,
			label = "SKULL",
			iconSize = 12,
			penalty = true,
			brackets = "PAREN",
			justify = "RIGHT",
			text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			tooltip = true,
		},
		forces = {
			bar = {
				texture = "Blizzard",
				height = 16,
				color = { 0.55, 0.2, 0.2, 1 },
				background = { 0, 0, 0, 0.5 },
			},
			count = {
				enabled = true,
				slot = "RIGHT",
				text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			percent = {
				enabled = true,
				slot = "CENTER",
				text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			decimals = 2,
			spacedSlash = false,
			showRemaining = false,
			completedColor = { 0.2, 0.8, 0.2, 1 },
		},
		objectives = {
			rowHeight = 14,
			spacing = 2,
			icon = true,
			iconSize = 12,
			showTime = true,
			text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			time = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			completedColor = { 0.6, 0.6, 0.6, 1 },
			pendingColor = { 1, 1, 1, 1 },
		},
		splits = {
			overall = "COUNTDOWN_AND_AFTER",
			boss = "ALWAYS",
			decimals = 0,
			aheadColor = { 0, 1, 0, 1 },
			equalColor = { 1, 0.8, 0, 1 },
			behindColor = { 1, 0, 0, 1 },
			pbCompare = {
				enabled = true,
				slot = "RIGHT",
				text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			forcesSplit = {
				enabled = true,
				slot = "LEFT",
				text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			bossSplit = {
				enabled = true,
				text = { font = "Friz Quadrata TT", size = 12, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
		},
		background = {
			enabled = true,
			color = { 0, 0, 0, 0.6 },
			padding = 6,
			nineslice = false,
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

	Profiles.Refresh()
end

---@param name string
function Profiles.SetDefaultForNewCharacters(name)
	local settings = AMT.DB.settings

	settings.defaultProfile = name
	Profiles.Create(name)

	if not settings.profileKeys[CharacterKey()] then
		Profiles.activeName = name
		Profiles.active = settings.profiles[name]

		Profiles.Refresh()
	end
end

---@return AMTTimerProfile
function Profiles.TimerDefaults()
	return Util.Copy(profileDefaults.timer)
end

function Profiles.Refresh()
	AMT.Frames.ApplyProfile()

	for module in Modules.Iterate() do
		if module.OnProfileChanged then
			module:OnProfileChanged()
		end
	end

	AMT.State.MarkAllDirty()
	AMT.Render.Flush()
end

---@return string[] names sorted, so the picker is stable across sessions
function Profiles.List()
	local names = {}

	for name in pairs(AMT.DB.settings.profiles) do
		names[#names + 1] = name
	end

	table.sort(names)

	return names
end

---@param name string
---@return boolean
function Profiles.Exists(name)
	return AMT.DB.settings.profiles[name] ~= nil
end

---@param name string
---@return boolean valid
local function ValidateNewName(name)
	if not name or name:trim() == "" then
		AMT.Util.Warn(L["a profile needs a name."])

		return false
	end

	if Profiles.Exists(name) then
		AMT.Util.Warn(L["a profile named %q already exists."], name)

		return false
	end

	return true
end

---Create an empty profile at defaults and switch to it.
---@param name string
---@return boolean created
function Profiles.New(name)
	if not ValidateNewName(name) then
		return false
	end

	Profiles.Create(name)
	Profiles.Activate(name)

	return true
end

---@param source string
---@param name string
---@return boolean created
function Profiles.Duplicate(source, name)
	local settings = AMT.DB.settings

	if not settings.profiles[source] or not ValidateNewName(name) then
		return false
	end

	settings.profiles[name] = Util.Copy(settings.profiles[source])

	Profiles.Activate(name)

	return true
end

---@param from string
---@param to string
---@return boolean renamed
function Profiles.Rename(from, to)
	local settings = AMT.DB.settings

	if not settings.profiles[from] or not ValidateNewName(to) then
		return false
	end

	settings.profiles[to] = settings.profiles[from]
	settings.profiles[from] = nil

	for characterKey, name in pairs(settings.profileKeys) do
		if name == from then
			settings.profileKeys[characterKey] = to
		end
	end

	if settings.defaultProfile == from then
		settings.defaultProfile = to
	end

	if Profiles.activeName == from then
		Profiles.activeName = to
	end

	return true
end

---@param name string
---@return boolean deleted
function Profiles.Delete(name)
	local settings = AMT.DB.settings

	if not settings.profiles[name] then
		return false
	end

	local names = Profiles.List()

	if #names <= 1 then
		AMT.Util.Warn(L["the last profile cannot be deleted."])

		return false
	end

	settings.profiles[name] = nil

	for characterKey, assigned in pairs(settings.profileKeys) do
		if assigned == name then
			settings.profileKeys[characterKey] = nil
		end
	end

	local remaining = Profiles.List()

	if settings.defaultProfile == name then
		settings.defaultProfile = remaining[1]
	end

	if Profiles.activeName == name then
		Profiles.Activate(settings.defaultProfile)
	end

	return true
end

---@return table? serializer
---@return table? deflate
local function ExportLibs()
	local serializer = LibStub("LibSerialize", true)
	local deflate = LibStub("LibDeflate", true)

	if not serializer or not deflate then
		AMT.Util.Warn(L["profile import and export need LibSerialize and LibDeflate."])

		return nil, nil
	end

	return serializer, deflate
end

---@param name string
---@return string? encoded
function Profiles.Export(name)
	local profile = AMT.DB.settings.profiles[name]
	local serializer, deflate = ExportLibs()

	if not profile or not serializer or not deflate then
		return nil
	end

	local payload = {
		format = EXPORT_FORMAT,
		addon = AMT.name,
		name = name,
		profile = profile,
	}

	local serialized = serializer:Serialize(payload)
	local compressed = deflate:CompressDeflate(serialized, { level = 9 })

	return deflate:EncodeForPrint(compressed)
end

---@param encoded string
---@return table? payload
function Profiles.Decode(encoded)
	local serializer, deflate = ExportLibs()

	if not serializer or not deflate then
		return nil
	end

	local decoded = deflate:DecodeForPrint(encoded)

	if not decoded then
		AMT.Util.Warn(L["that does not look like an export string."])

		return nil
	end

	local decompressed = deflate:DecompressDeflate(decoded)

	if not decompressed then
		AMT.Util.Warn(L["that export string is corrupt or incomplete."])

		return nil
	end

	local ok, payload = serializer:Deserialize(decompressed)

	if not ok or type(payload) ~= "table" then
		AMT.Util.Warn(L["that export string could not be read."])

		return nil
	end

	if payload.addon ~= AMT.name then
		AMT.Util.Warn(L["that export string is from a different addon."])

		return nil
	end

	if payload.format ~= EXPORT_FORMAT then
		AMT.Util.Warn(L["that export string is from an incompatible version."])

		return nil
	end

	if type(payload.profile) ~= "table" or type(payload.name) ~= "string" then
		AMT.Util.Warn(L["that export string is missing a profile."])

		return nil
	end

	return payload
end

---@param payload table from Profiles.Decode
---@return string name
function Profiles.ApplyImport(payload)
	local imported = Util.Copy(payload.profile)

	Util.MergeDefaults(imported, profileDefaults)

	AMT.DB.settings.profiles[payload.name] = imported

	Profiles.Activate(payload.name)

	return payload.name
end
