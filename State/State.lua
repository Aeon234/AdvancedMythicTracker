local AMT = select(2, ...)

local Util = AMT.Util

---@class AMTObjective
---@field name string?
---@field description string
---@field completedAtMS integer?
---@field dungeonEncounterID integer?

---@class AMTDeath
---@field atMS integer
---@field name string?
---@field class string?

---@class AMTStateData
---@field inChallenge boolean
---@field challengeCompleted boolean
---@field completedOnTime boolean?
---@field completionMS integer?
---@field upgradeLevels integer?
---@field timerStarted boolean
---@field elapsed number
---@field timeLimit number
---@field timeLimits number[]
---@field hasChallengersPeril boolean
---@field deathCount integer
---@field deathTimeLost number
---@field deaths AMTDeath[]
---@field currentCount integer
---@field totalCount integer
---@field currentPercent number
---@field pullCount integer
---@field pullPercent number
---@field forcesCompleted boolean
---@field forcesCompletedAtMS integer?
---@field objectives AMTObjective[]
---@field level integer
---@field affixIDs integer[]
---@field mapID integer?
---@field seasonID integer?

---@type AMTStateData
local defaults = {
	inChallenge = false,
	challengeCompleted = false,
	completedOnTime = nil,
	completionMS = nil,
	upgradeLevels = nil,
	timerStarted = false,
	elapsed = 0,
	timeLimit = 0,
	timeLimits = {},
	hasChallengersPeril = false,
	deathCount = 0,
	deathTimeLost = 0,
	deaths = {},
	currentCount = 0,
	totalCount = 0,
	currentPercent = 0,
	pullCount = 0,
	pullPercent = 0,
	forcesCompleted = false,
	forcesCompletedAtMS = nil,
	objectives = {},
	level = 0,
	affixIDs = {},
	mapID = nil,
	seasonID = nil,
}

---@alias AMTDirtyKey "timer"|"forces"|"objectives"|"deaths"|"keyInfo"|"layout"

---@type AMTDirtyKey[]
local DIRTY_KEYS = { "layout", "keyInfo", "timer", "objectives", "forces", "deaths" }

---@class AMTState
---@field current AMTStateData
local State = {}
AMT.State = State

State.DIRTY_KEYS = DIRTY_KEYS

State.current = Util.Copy(defaults)

---@type table<AMTDirtyKey,boolean>
local dirty = {}

---Reset in place rather than replace the whole table. Note: Module may hold AMT.State.current as an upvalue across a key without it being stale.
function State.Reset()
	wipe(State.current)
	Util.MergeDefaults(State.current, defaults)
end

---@param key AMTDirtyKey
function State.MarkDirty(key)
	dirty[key] = true
end

function State.MarkAllDirty()
	for _, key in ipairs(DIRTY_KEYS) do
		dirty[key] = true
	end
end

---@param key AMTDirtyKey
---@return boolean
function State.IsDirty(key)
	return dirty[key] == true
end

function State.ClearDirty()
	wipe(dirty)
end

---@param key AMTDirtyKey
function State.ClearDirtyKey(key)
	dirty[key] = nil
end
