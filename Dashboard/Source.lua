local AMT = select(2, ...)
local L = AMT.L

local Dashboard = AMT.Dashboard

local GCD_SECONDS = 2

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

local SAMPLE_PARTY_MAP_ID, SAMPLE_PARTY_ABBREV = 78, "SM"
---@type { name: string, classFile: string, specID: integer?, level: integer?, rating: number? }[]
local SAMPLE_PARTY = {
	{ name = "Tirion", classFile = "PALADIN", specID = 65, level = 21, rating = 3120 },
	{ name = "Malfurion", classFile = "DRUID", level = 22, rating = 3285 },
	{ name = "Jaina", classFile = "MAGE", level = 21, rating = 2950 },
	{ name = "Anduin", classFile = "PRIEST" },
	{ name = "Vol'jin", classFile = "HUNTER", level = 20, rating = 2710 },
}
local SAMPLE_PACE = { 0.55, 0.7, 0.85, 1.0, 1.15 }

local TYRANNICAL_ID, FORTIFIED_ID = 9, 10
local TYRANNICAL_BOSS_HEALTH, TYRANNICAL_BOSS_DAMAGE = 0.25, 0.15
local FORTIFIED_MINION_HEALTH, FORTIFIED_MINION_DAMAGE = 0.20, 0.20

local RAIDER_IO_URL = "https://raider.io/characters/%s/%s/%s"
local RAIDER_IO_REGIONS = { [1] = "us", [2] = "kr", [3] = "eu", [4] = "tw" }

local SAMPLE_RUN_CLASSES = { "PALADIN", "PRIEST", "MAGE", "ROGUE", "SHAMAN" }
local SAMPLE_RUN_SPECS = { 65, 257, 63, 260, 264 }
local DAY_SECONDS = 86400

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

---@class AMTDashboardPartyKey
---@field name string dungeon name
---@field abbrev string
---@field texture number?
---@field level integer

---@class AMTDashboardPartyDungeon
---@field name string
---@field level integer 0 when not run this season
---@field timed boolean
---@field upgrades integer 0-3

---@class AMTDashboardPartyMember
---@field name string a plain string, never secret: the panel sorts by it
---@field classFile string
---@field specIcon number? nil until the spec is known
---@field key AMTDashboardPartyKey? nil until the key is known
---@field rating number? nil when the client returned no rating summary
---@field dungeons AMTDashboardPartyDungeon[] every season dungeon, in no particular order

---@class AMTDashboardPartyRoster
---@field inGroup boolean
---@field members AMTDashboardPartyMember[] the player included, in no particular order

---@class AMTDashboardFastestRun
---@field level integer
---@field seconds number
---@field overTime boolean

---@class AMTDashboardSeasonDungeon
---@field mapID integer
---@field name string
---@field abbrev string
---@field texture number?
---@field score number 0 when not run this season
---@field level integer 0 when not run this season
---@field seconds number
---@field timed boolean
---@field fastest AMTDashboardFastestRun? the fastest season-best run, nil when not run
---@field teleportSpellID integer? nil when no teleport entry a given dungeon
---@field teleportName string the spell's name, or TELEPORT_TO_DUNGEON
---@field teleportKnown boolean
---@field teleportUnlockLevel integer

---@class AMTDashboardRunMember
---@field classFile string
---@field specIcon number?

---@class AMTDashboardRun
---@field name string
---@field abbrev string
---@field texture number?
---@field level integer
---@field seconds number
---@field chests integer 0 = depleted
---@field score number score the run provided
---@field completedAt number
---@field party AMTDashboardRunMember[]? nil if AMT didn't record the run

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

---@param seed integer varies the sample between members
---@return AMTDashboardPartyDungeon[]
local function SampleDungeons(seed)
	local dungeons = {}

	for index, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
		local step = index + seed
		local seconds = timeLimit * SAMPLE_PACE[step % #SAMPLE_PACE + 1]
		local level = step % 6 == 0 and 0 or 16 + step % 6

		dungeons[index] = {
			name = name,
			level = level,
			timed = level > 0 and seconds <= timeLimit,
			upgrades = level > 0 and AMT.Util.CountUpgrades(seconds, timeLimit) or 0,
		}
	end

	return dungeons
end

---@return AMTDashboardPartyRoster
function Source:GetParty()
	local mapName, _, _, texture = C_ChallengeMode.GetMapUIInfo(SAMPLE_PARTY_MAP_ID)
	local members = {}

	for index, sample in ipairs(SAMPLE_PARTY) do
		local key, specIcon

		if sample.level then
			key = { name = mapName, abbrev = SAMPLE_PARTY_ABBREV, texture = texture, level = sample.level }
		end

		if sample.specID then
			specIcon = select(4, GetSpecializationInfoByID(sample.specID))
		end

		members[index] = {
			name = sample.name,
			classFile = sample.classFile,
			specIcon = specIcon,
			key = key,
			rating = sample.rating,
			dungeons = sample.rating and SampleDungeons(index) or {},
		}
	end

	return { inGroup = true, members = members }
end

---@return AMTDashboardSeasonDungeon[] in no particular order
function Source:GetSeasonDungeons()
	local dungeons = {}

	for index, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
		-- The last two stay unplayed, so the sample shows both states.
		local played = index <= 6
		local seconds = timeLimit * SAMPLE_PACE[index % #SAMPLE_PACE + 1]
		local level = played and 18 + index % 5 or 0
		local timed = played and seconds <= timeLimit
		local teleport = AMT.Teleports.ForChallengeID(mapID)
		local abbr = AMT.Teleports.AbbreviationFor(mapID)
		local abbrev = abbr and L[abbr] or name
		local fastest

		if played then
			fastest = { level = level, seconds = seconds, overTime = not timed }
		end

		dungeons[index] = {
			mapID = mapID,
			name = name,
			abbrev = abbrev,
			texture = texture,
			score = played and 400 + (index * 37) % 40 or 0,
			level = level,
			seconds = seconds,
			timed = timed,
			teleportSpellID = teleport and teleport.id,
			teleportName = teleport and C_Spell.GetSpellName(teleport.id) or TELEPORT_TO_DUNGEON,
			teleportKnown = teleport ~= nil and teleport.known,
			teleportUnlockLevel = AMT.Season.teleportUnlockLevel,
			fastest = fastest,
		}
	end

	return dungeons
end

---Since cooldown is shared, first learned entry gives the cooldown.
---@return number? remaining seconds, 0 when ready; nil while it cannot be known
function Source:GetTeleportCooldown()
	if C_Secrets.ShouldCooldownsBeSecret() then
		return nil
	end

	for _, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local teleport = AMT.Teleports.ForChallengeID(mapID)

		if teleport and teleport.known then
			local cooldown = C_Spell.GetSpellCooldown(teleport.id)

			if not cooldown.isActive then
				return 0
			end

			local startTime, duration = cooldown.startTime, cooldown.duration

			if issecretvalue(startTime) or issecretvalue(duration) then
				return nil
			end

			if duration <= GCD_SECONDS then
				return 0
			end

			return math.max(startTime + duration - GetTime(), 0)
		end
	end

	return nil
end

---@return AMTDashboardRun[] newest first
function Source:GetWeeklyRuns()
	local runs = {}
	local now = time()

	for index, mapID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, _, timeLimit, texture = C_ChallengeMode.GetMapUIInfo(mapID)
		local seconds = timeLimit * SAMPLE_PACE[index % #SAMPLE_PACE + 1]
		local party

		-- Every third run stands in for one AMT never saw.
		if index % 3 ~= 0 then
			party = {}

			for member = 1, #SAMPLE_RUN_CLASSES do
				party[member] = {
					classFile = SAMPLE_RUN_CLASSES[member],
					specIcon = index % 2 == 0 and select(4, GetSpecializationInfoByID(SAMPLE_RUN_SPECS[member])) or nil,
				}
			end
		end

		runs[index] = {
			name = name,
			abbrev = AMT.Teleports.AbbreviationFor(mapID) or name,
			texture = texture,
			level = 16 + index % 6,
			seconds = seconds,
			chests = AMT.Util.CountUpgrades(seconds, timeLimit),
			score = 380 + (index * 23) % 50,
			completedAt = now - (index - 1) * DAY_SECONDS,
			party = party,
		}
	end

	return runs
end
