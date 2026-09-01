local AMT = select(2, ...)

local State = AMT.State

local CHALLENGERS_PERIL_AFFIX_ID = 152
local CHALLENGERS_PERIL_BONUS = 90

-- Tick mark positions for +1,+2,+3 upgrades
local UPGRADE_FRACTIONS = { 1.0, 0.8, 0.6 }

---@class AMTChallenge
local Challenge = {}
AMT.Challenge = Challenge

Challenge.PERIL_AFFIX_ID = CHALLENGERS_PERIL_AFFIX_ID

---@return boolean
function Challenge.IsInChallengeInstance()
	local _, instanceType, difficultyID = GetInstanceInfo()

	return instanceType == "party" and difficultyID == DifficultyUtil.ID.DungeonChallenge
end

---@param timeLimit number seconds as reported by GetMapUIInfo
function Challenge.SetTimeLimit(timeLimit)
	local state = State.current
	local bonus = state.hasChallengersPeril and CHALLENGERS_PERIL_BONUS or 0
	local base = timeLimit - bonus

	state.timeLimit = timeLimit

	local limits = state.timeLimits
	wipe(limits)

	for index = 1, #UPGRADE_FRACTIONS do
		limits[index] = base * UPGRADE_FRACTIONS[index] + bonus
	end

	State.MarkDirty("timer")
end

---@return boolean loaded
function Challenge.Load()
	local mapID = C_ChallengeMode.GetActiveChallengeMapID()

	if not mapID then
		return false
	end

	local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()

	if not level or level <= 0 then
		return false
	end

	local state = State.current

	state.mapID = mapID
	state.level = level
	state.hasChallengersPeril = false

	wipe(state.affixIDs)

	for index, affixID in ipairs(affixIDs) do
		state.affixIDs[index] = affixID

		if affixID == CHALLENGERS_PERIL_AFFIX_ID then
			state.hasChallengersPeril = true
		end
	end

	State.MarkDirty("keyInfo")

	---@type number?
	local timeLimit = select(3, C_ChallengeMode.GetMapUIInfo(mapID))

	if not timeLimit then
		-- In case map data is not cached yet
		C_MythicPlus.RequestMapInfo()
		return false
	end

	Challenge.SetTimeLimit(timeLimit)

	return true
end

function Challenge.Complete()
	local info = C_ChallengeMode.GetChallengeCompletionInfo()
	local state = State.current

	state.challengeCompleted = true
	state.completedOnTime = info.onTime
	state.completionMS = info.time
	state.upgradeLevels = info.keystoneUpgradeLevels

	State.MarkDirty("timer")
end

function Challenge.UpdateElapsed()
	State.current.elapsed = select(2, GetWorldElapsedTime(1))
	State.MarkDirty("timer")
end

---@return integer
function Challenge.GetUpgradeTier()
	local state = State.current

	if state.challengeCompleted and state.upgradeLevels then
		return state.upgradeLevels
	end

	local limits = state.timeLimits

	for tier = #limits, 1, -1 do
		if state.elapsed <= limits[tier] then
			return tier
		end
	end

	return 0
end
