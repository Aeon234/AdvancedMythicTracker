local AMT = select(2, ...)

local Dashboard = AMT.Dashboard

local SAMPLE_KEYSTONE = { mapID = 78, abbrev = "SM", level = 21 }
local SAMPLE_RATING = 3285
local SAMPLE_WEEKLY_BEST = { mapID = 78, abbrev = "SM", level = 22, seconds = 1868, chests = 2 }
local SAMPLE_SEASON_BEST = { mapID = 78, abbrev = "SM", level = 23, seconds = 1694, chests = 3 }
local SAMPLE_AFFIXES = { 148, 9, 152, 147 }

---@class AMTDashboardKeystone
---@field name string
---@field abbrev string
---@field texture number?
---@field level integer

---@class AMTDashboardAffix
---@field name string
---@field description string
---@field texture number

---@class AMTDashboardHeader
---@field keystone AMTDashboardKeystone? nil when the character holds no key
---@field rating number
---@field weeklyBest AMTDashboardRunSummary? nil before a run this week
---@field seasonBest AMTDashboardRunSummary? nil before a run this season
---@field affixes AMTDashboardAffix[]

---@class AMTDashboardSource
local Source = {}
Dashboard.Source = Source

---@param sample { mapID: number, abbrev: string, level: integer, seconds: number, chests: integer }
---@return AMTDashboardRunSummary
local function SampleRun(sample)
	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(sample.mapID)

	return {
		name = name,
		abbrev = sample.abbrev,
		texture = texture,
		level = sample.level,
		seconds = sample.seconds,
		chests = sample.chests,
	}
end

---@return AMTDashboardAffix[]
local function SampleAffixes()
	local affixes = {}

	for index, affixID in ipairs(SAMPLE_AFFIXES) do
		local name, description, texture = C_ChallengeMode.GetAffixInfo(affixID)

		affixes[index] = { name = name, description = description, texture = texture }
	end

	return affixes
end

---@return AMTDashboardHeader
function Source:GetHeader()
	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(SAMPLE_KEYSTONE.mapID)

	return {
		keystone = {
			name = name,
			abbrev = SAMPLE_KEYSTONE.abbrev,
			texture = texture,
			level = SAMPLE_KEYSTONE.level,
		},
		rating = SAMPLE_RATING,
		weeklyBest = SampleRun(SAMPLE_WEEKLY_BEST),
		seasonBest = SampleRun(SAMPLE_SEASON_BEST),
		affixes = SampleAffixes(),
	}
end
