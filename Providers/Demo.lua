local AMT = select(2, ...)
local L = AMT.L

local State = AMT.State

local LEVEL = 12
local MAP_ID = 78
local TIME_LIMIT = 1980
local TOTAL_FORCES = 388
local TIME_SCALE = 10

local FORCES_FULL_AT = TIME_LIMIT * 0.9
local FINISH_AT = TIME_LIMIT * 0.95
local SPLIT_SPREAD_SECONDS = 60
local DEATH_PENALTY = 5

local MAX_AFFIXES = 4
local FALLBACK_AFFIX_IDS = { 152 }

local BOSS_NAMES = {
	"Interrogator Vishas",
	"Houndmaster Loksey",
	"Arcanist Doan",
	"Scarlet Commander Mograine",
	"High Inquisitor Whitemane",
}

local BOSS_INTERVAL = TIME_LIMIT / (#BOSS_NAMES + 1)

local FAKE_DEATHS = {
	{ name = "Arthas", class = "DEATHKNIGHT" },
	{ name = "Xal'atath", class = "DEMONHUNTER" },
	{ name = "Malfurion", class = "DRUID" },
	{ name = "Emberthal", class = "EVOKER" },
	{ name = "Vol'jin", class = "HUNTER" },
	{ name = "Jaina", class = "MAGE" },
	{ name = "Chen", class = "MONK" },
	{ name = "Tirion", class = "PALADIN" },
	{ name = "Anduin", class = "PRIEST" },
	{ name = "Valeera", class = "ROGUE" },
	{ name = "Thrall", class = "SHAMAN" },
	{ name = "Gul'dan", class = "WARLOCK" },
	{ name = "Varian", class = "WARRIOR" },
}

local DEATH_INTERVAL = TIME_LIMIT / #FAKE_DEATHS

---@class AMTDemo
local Demo = {}
AMT.Demo = Demo

local active = false
local animating = false
local startedAt = 0

---@return boolean
local function LoadKey()
	local state = State.current

	state.mapID = MAP_ID
	state.level = LEVEL
	state.hasChallengersPeril = false

	wipe(state.affixIDs)

	---@type MythicPlusKeystoneAffix[]?
	local affixes = C_MythicPlus.GetCurrentAffixes()

	if affixes then
		for index, affix in ipairs(affixes) do
			if index > MAX_AFFIXES then
				break
			end

			state.affixIDs[index] = affix.id

			if affix.id == AMT.Challenge.PERIL_AFFIX_ID then
				state.hasChallengersPeril = true
			end
		end
	else
		for index, id in ipairs(FALLBACK_AFFIX_IDS) do
			state.affixIDs[index] = id
		end

		state.hasChallengersPeril = true
	end

	State.MarkDirty("keyInfo")
	AMT.Challenge.SetTimeLimit(TIME_LIMIT)

	return true
end

---@param elapsed number
---@return integer
local function ForcesAt(elapsed)
	return math.floor(TOTAL_FORCES * math.min(elapsed / FORCES_FULL_AT, 1))
end

---Normally forces count is set to only ever go up.
local function UpdateForces()
	local state = State.current
	local current = ForcesAt(state.elapsed)

	AMT.Forces.SetTotal(TOTAL_FORCES)
	AMT.Forces.SetCurrent(current)

	if not state.forcesCompletedAtMS then
		state.forcesCompletedAtMS = math.floor(FORCES_FULL_AT * 1000)

		State.MarkDirty("forces")
	end

	if current >= TOTAL_FORCES and not state.forcesCompleted then
		state.forcesCompleted = true

		State.MarkDirty("forces")
	end
end

local function UpdateObjectives()
	local state = State.current
	local changed = false

	for index, name in ipairs(BOSS_NAMES) do
		local objective = state.objectives[index]

		if not objective then
			objective = { description = name, name = name }
			state.objectives[index] = objective
			changed = true
		end

		local completesAt = index * BOSS_INTERVAL

		if state.elapsed >= completesAt and not objective.completedAtMS then
			objective.completedAtMS = math.floor(completesAt * 1000)
			changed = true
		end
	end

	if changed then
		State.MarkDirty("objectives")
	end
end

local function UpdateDeaths()
	local state = State.current
	local expected = math.min(math.floor(state.elapsed / DEATH_INTERVAL), #FAKE_DEATHS)

	if expected == state.deathCount then
		return
	end

	state.deathCount = expected
	state.deathTimeLost = expected * DEATH_PENALTY

	wipe(state.deaths)

	for index = 1, expected do
		local fake = FAKE_DEATHS[index]

		state.deaths[index] = {
			atMS = math.floor(index * DEATH_INTERVAL * 1000),
			name = fake.name,
			class = fake.class,
		}
	end

	State.MarkDirty("deaths")
end

---@param seconds number
---@return integer ms
local function NearMS(seconds)
	return math.floor((seconds + math.random(-SPLIT_SPREAD_SECONDS, SPLIT_SPREAD_SECONDS)) * 1000)
end

---@return AMTSplitRecord
local function BuildBest()
	local bosses = {}

	for index, name in ipairs(BOSS_NAMES) do
		bosses[index] = { name = name, timeMS = NearMS(index * BOSS_INTERVAL) }
	end

	return { finishMS = NearMS(FINISH_AT), forcesMS = NearMS(FORCES_FULL_AT), bosses = bosses }
end

---The snapshot has to agree with what the ticker would have produced at the same elapsed, or the
---first animated tick rewrites everything it disagrees about.
local function Populate()
	State.current.elapsed = math.random(300, TIME_LIMIT - 300)

	UpdateForces()
	UpdateObjectives()
	UpdateDeaths()

	State.MarkAllDirty()
end

---Fake ticker to emulate changes.
local function Tick()
	State.current.elapsed = (GetTime() - startedAt) * TIME_SCALE
	State.MarkDirty("timer")

	UpdateForces()
	UpdateObjectives()
	UpdateDeaths()
end

AMT.Providers.Register("demo", {
	Tick = Tick,
	LoadKey = LoadKey,
	UpdateForces = UpdateForces,
	UpdateObjectives = UpdateObjectives,
	UpdateDeaths = UpdateDeaths,
})

---@return boolean
function Demo.IsActive()
	return active
end

---@param animated boolean?
function Demo.Enter(animated)
	if State.current.inChallenge then
		AMT.Util.Warn(L["preview is unavailable during a key."])

		return
	end

	if active then
		return
	end

	active = true
	animating = false
	startedAt = GetTime()

	State.Reset()
	AMT.Providers.Use("demo")
	AMT.Providers.active.LoadKey()
	AMT.Splits.SetOverride(BuildBest())
	AMT.Frames.SetShown(true)

	Populate()
	AMT.Render.Flush()

	if animated == true then
		Demo.SetAnimated(true)
	end
end

function Demo.Exit()
	if not active then
		return
	end

	active = false
	animating = false

	AMT.Render.StopTicker()
	AMT.Providers.Use("live")
	AMT.Splits.SetOverride(nil)
	State.Reset()
	State.MarkAllDirty()
	AMT.Frames.SetShown(false)
	AMT.Render.Flush()
end

---@param animated boolean
function Demo.SetAnimated(animated)
	if not active or animating == animated then
		return
	end

	animating = animated

	if not animating then
		AMT.Render.StopTicker()

		return
	end

	-- Resume from the snapshot's elapsed so the HUD carries on instead of restarting at zero.
	startedAt = GetTime() - State.current.elapsed / TIME_SCALE

	Tick()
	AMT.Render.Flush()
	AMT.Render.StartTicker()
end

---@param animated boolean?
function Demo.Toggle(animated)
	if active then
		Demo.Exit()

		return
	end

	Demo.Enter(animated == true)
end
