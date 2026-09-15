local AMT = select(2, ...)

local Dashboard = AMT.Dashboard

local SAMPLE_KEYSTONE = { mapID = 78, abbrev = "SM", level = 21 }
local SAMPLE_RATING = 3285
local SAMPLE_WEEKLY_BEST = { mapID = 78, abbrev = "SM", level = 22, seconds = 1868, chests = 2 }
local SAMPLE_SEASON_BEST = { mapID = 78, abbrev = "SM", level = 23, seconds = 1694, chests = 3 }
local SAMPLE_AFFIXES = { 148, 9, 152, 147 }
local SAMPLE_AFFIX_LEVELS = { 2, 5, 7, 10, 12 }
local SAMPLE_VAULT_PROGRESS = 3
---@type { threshold: integer, level: integer, itemLevel: number?, upgradeItemLevel: number?, nextLevel: integer, lowestLevel: integer? }[]
local SAMPLE_VAULT_MILESTONES = {
	{ threshold = 1, level = 22, itemLevel = 662, upgradeItemLevel = 665, nextLevel = 23, lowestLevel = 22 },
	{ threshold = 4, level = 0, nextLevel = 2, lowestLevel = 21 },
	{ threshold = 8, level = 0, nextLevel = 2, lowestLevel = 21 },
}
local SAMPLE_VAULT_RUNS = {
	{ mapID = 78, level = 20 },
	{ mapID = 78, level = 10 },
	{ mapID = 78, level = 4 },
}

local TYRANNICAL_ID, FORTIFIED_ID = 9, 10
local TYRANNICAL_BOSS_HEALTH, TYRANNICAL_BOSS_DAMAGE = 0.25, 0.15
local FORTIFIED_MINION_HEALTH, FORTIFIED_MINION_DAMAGE = 0.20, 0.20

local RAIDER_IO_URL = "https://raider.io/characters/%s/%s/%s"
local RAIDER_IO_REGIONS = { [1] = "us", [2] = "kr", [3] = "eu", [4] = "tw" }

---@class AMTDashboardKeystoneModifiers
---@field bossHealth integer percent
---@field bossDamage integer percent
---@field minionHealth integer percent
---@field minionDamage integer percent

---@class AMTDashboardKeystone
---@field name string
---@field abbrev string
---@field texture number?
---@field level integer
---@field modifiers AMTDashboardKeystoneModifiers
---@field lootItemLevel number? nil for no info
---@field vaultItemLevel number? nil for no info

---@class AMTDashboardAffix
---@field name string
---@field description string
---@field texture number

---@class AMTDashboardHeader
---@field raiderIOURL string? nil where no Raider.IO page can be linked with confidence
---@field keystone AMTDashboardKeystone? nil when the character holds no key
---@field rating number
---@field weeklyBest AMTDashboardRunSummary? nil before a run this week
---@field seasonBest AMTDashboardRunSummary? nil before a run this season
---@field affixes AMTDashboardAffix[]
---@class AMTDashboardVaultMilestone
---@field index integer the slot, 1-3
---@field threshold integer runs that unlock this reward
---@field level integer the key level the slot is set at
---@field heroic boolean the slot is set by a Heroic run
---@field itemLevel number? nil until the reward item has loaded
---@field upgradeItemLevel number? nil when the slot is already at its highest item level
---@field nextLevel integer the key level that would raise the slot
---@field lowestLevel integer? the lowest of the top `threshold` runs; WeeklyRewardsUtil.HeroicLevel for Heroic

---@class AMTDashboardVaultRun
---@field level integer
---@field name string

---@class AMTDashboardVaultTrack
---@field progress integer runs the vault counts this week, Heroic and Mythic 0 included
---@field canClaim boolean last week's rewards can be claimed, which hides the reward preview
---@field milestones AMTDashboardVaultMilestone[] in threshold order
---@field topRuns AMTDashboardVaultRun[] this week's Mythic+ runs, highest first
---@field mythicRuns integer Mythic 0 runs counted by the vault
---@field heroicRuns integer Heroic and Timewalking runs counted by the vault
---@field rewardsWaiting boolean last week's rewards are unclaimed

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

-- 0 is returned when no info available.
---@param itemLevel number
---@return number?
local function KnownItemLevel(itemLevel)
	if itemLevel > 0 then
		return itemLevel
	end
end

---@param base number percent, as GetPowerLevelDamageHealthMod returns it
---@param affix number fraction, 0 when the affix is not active on the key
---@return integer percent
local function CombineScaling(base, affix)
	return Round(((1 + base / 100) * (1 + affix) - 1) * 100)
end

---@param level integer
---@param affixIDs number[] this week's affixes, in activation order
---@param affixLevels integer[] the key level each position activates at
---@return AMTDashboardKeystoneModifiers
local function GetModifiers(level, affixIDs, affixLevels)
	local tyrannical, fortified = false, false

	for index = 1, math.min(#affixIDs, #affixLevels) do
		if affixLevels[index] <= level then
			tyrannical = tyrannical or affixIDs[index] == TYRANNICAL_ID
			fortified = fortified or affixIDs[index] == FORTIFIED_ID
		end
	end

	local damage, health = C_ChallengeMode.GetPowerLevelDamageHealthMod(level)

	return {
		bossHealth = CombineScaling(health, tyrannical and TYRANNICAL_BOSS_HEALTH or 0),
		bossDamage = CombineScaling(damage, tyrannical and TYRANNICAL_BOSS_DAMAGE or 0),
		minionHealth = CombineScaling(health, fortified and FORTIFIED_MINION_HEALTH or 0),
		minionDamage = CombineScaling(damage, fortified and FORTIFIED_MINION_DAMAGE or 0),
	}
end

---@param realm string the realm name as GetRealmName returns it, spaces intact
---@return string? slug nil when the page cannot be named with confidence
local function GetRaiderIOSlug(realm)
	-- Cyrillic lead bytes in UTF-8
	if realm:find("[\208\209]") then
		local english = AMT.RussianRealms[(realm:gsub("%s+", ""))]

		if not english then
			return nil
		end

		realm = english
	end

	if realm:find("[\128-\255]") then
		return nil
	end

	local slug = realm:gsub("'", "")

	slug = slug:gsub("%s+", "-")

	return slug:lower()
end

---@return string?
local function GetRaiderIOURL()
	local region = RAIDER_IO_REGIONS[GetCurrentRegion()]
	local slug = GetRaiderIOSlug(GetRealmName())
	local name = UnitName("player")

	if not region or not slug or issecretvalue(name) then
		return nil
	end

	return RAIDER_IO_URL:format(region, slug, name)
end

---@return AMTDashboardHeader
function Source:GetHeader()
	local name, _, _, texture = C_ChallengeMode.GetMapUIInfo(SAMPLE_KEYSTONE.mapID)
	local vaultItemLevel, lootItemLevel = C_MythicPlus.GetRewardLevelForDifficultyLevel(SAMPLE_KEYSTONE.level)

	return {
		keystone = {
			name = name,
			abbrev = SAMPLE_KEYSTONE.abbrev,
			texture = texture,
			level = SAMPLE_KEYSTONE.level,
			modifiers = GetModifiers(SAMPLE_KEYSTONE.level, SAMPLE_AFFIXES, SAMPLE_AFFIX_LEVELS),
			lootItemLevel = KnownItemLevel(lootItemLevel),
			vaultItemLevel = KnownItemLevel(vaultItemLevel),
		},
		rating = SAMPLE_RATING,
		weeklyBest = SampleRun(SAMPLE_WEEKLY_BEST),
		seasonBest = SampleRun(SAMPLE_SEASON_BEST),
		affixes = SampleAffixes(),
		raiderIOURL = GetRaiderIOURL(),
	}
end

---@return AMTDashboardVaultTrack
function Source:GetVault()
	local milestones = {}

	for index, sample in ipairs(SAMPLE_VAULT_MILESTONES) do
		milestones[index] = {
			index = index,
			threshold = sample.threshold,
			level = sample.level,
			heroic = false,
			itemLevel = sample.itemLevel,
			upgradeItemLevel = sample.upgradeItemLevel,
			nextLevel = sample.nextLevel,
			lowestLevel = sample.lowestLevel,
		}
	end

	local topRuns = {}

	for index, sample in ipairs(SAMPLE_VAULT_RUNS) do
		topRuns[index] = { level = sample.level, name = (C_ChallengeMode.GetMapUIInfo(sample.mapID)) }
	end

	return {
		progress = SAMPLE_VAULT_PROGRESS,
		canClaim = false,
		milestones = milestones,
		topRuns = topRuns,
		mythicRuns = 0,
		heroicRuns = 0,
		rewardsWaiting = false,
	}
end

---@return number seconds
function Source:GetSecondsUntilWeeklyReset()
	return C_DateAndTime.GetSecondsUntilWeeklyReset()
end
