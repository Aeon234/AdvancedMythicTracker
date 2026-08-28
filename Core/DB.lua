local AMT = select(2, ...)

local Util = AMT.Util

-- Incase I need to force DB Upgrades
local SCHEMA_VERSION = 1

---@class AMTDatabase
---@field version integer
---@field settings AMTSettings
---@field records AMTRecords

---@class AMTSettings
---@field profiles table<string,AMTProfile>
---@field profileKeys table<string,string>
---@field defaultProfile string

---@class AMTRecords
---@field version integer
---@field best table<integer,table>
---@field history table<integer,table>

local defaults = {
	version = SCHEMA_VERSION,
	settings = {
		profiles = {},
		profileKeys = {},
		defaultProfile = "Default",
	},
	records = {
		version = SCHEMA_VERSION,
		best = {},
		history = {},
	},
}

---@class AMTDB
---@field settings AMTSettings!
---@field records AMTRecords!
local DB = {}
AMT.DB = DB

function DB.Initialize()
	---@type AMTDatabase
	AdvancedMythicTrackerDB = AdvancedMythicTrackerDB or {}

	local stored = AdvancedMythicTrackerDB.version

	if stored and stored > SCHEMA_VERSION then
		print("%s: settings were upgraded to a newer version and you may cause changes."):format(AMT.name)
	end

	Util.MergeDefaults(AdvancedMythicTrackerDB, defaults)

	DB.settings = AdvancedMythicTrackerDB.settings
	DB.records = AdvancedMythicTrackerDB.records
end
