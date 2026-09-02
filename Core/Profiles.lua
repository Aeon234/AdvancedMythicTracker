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

-- Timer Bars
---@class AMTBarProfile
---@field texture string
---@field height number
---@field color number[]
---@field background number[]

-- Timer Text
---@class AMTTextProfile
---@field font string
---@field size number
---@field outline AMTFontOutline
---@field color number[]

---@class AMTThresholdSettings
---@field enabled boolean
---@field aheadColor number[]
---@field behindColor number[]
---@field text AMTTextStyle

-- Timer Key Info
---@class AMTKeyInfoProfile
---@field height number
---@field showLevel boolean
---@field combineLevel boolean
---@field colorLevel boolean
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
---@class AMTForcesTextSettings
---@field enabled boolean
---@field slot "LEFT"|"CENTER"|"RIGHT"
---@field text AMTTextStyle

---@class AMTForcesProfile
---@field bar AMTBarStyle
---@field count AMTForcesTextSettings
---@field percent AMTForcesTextSettings
---@field decimals integer
---@field spacedSlash boolean
---@field completedColor number[]

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
---@field forces AMTForcesProfile
---@field objectives AMTObjectivesProfile
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
			-- Indexed tier+1: depleted, +1, +2, +3. MPlusTimer's defaults (D-42).
			tierColors = {
				{ 89 / 255, 90 / 255, 92 / 255, 1 },
				{ 1, 112 / 255, 0, 1 },
				{ 1, 1, 0, 1 },
				{ 128 / 255, 1, 0, 1 },
			},
			showTicks = true,
			tickColor = { 1, 1, 1, 0.5 },
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
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			{
				enabled = true,
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
			{
				enabled = true,
				aheadColor = { 0, 1, 0, 1 },
				behindColor = { 1, 0, 0, 1 },
				text = { font = "Friz Quadrata TT", size = 13, outline = "OUTLINE", color = { 1, 1, 1, 1 } },
			},
		},
		keyInfo = {
			height = 18,
			showLevel = true,
			combineLevel = false,
			colorLevel = true,
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

---@return AMTTimerProfile
function Profiles.TimerDefaults()
	return Util.Copy(profileDefaults.timer)
end
