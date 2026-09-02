local AMT = select(2, ...)

local State = AMT.State

local LEVEL = 12
local MAP_ID = 78
local TIME_LIMIT = 1980
local TOTAL_FORCES = 388
local TIME_SCALE = 10

local FORCES_FULL_AT = 600
local BOSS_INTERVAL = 150
local DEATH_INTERVAL = 90
local DEATH_PENALTY = 5

local FALLBACK_AFFIX_IDS = { 152 }

local BOSS_NAMES = {
	-- "Rhahk'zor",
	-- "Miner Johnson",
	-- "Sneed’s Shredder",
	-- "Gilnid",
	-- "Mr. Smite",
	-- "Captain Greenskin",
	-- "Edwin VanCleef",
	-- "Cookie",
	"Interrogator Vishas",
	"Houndmaster Loksey",
	"Arcanist Doan",
	"Scarlet Commander Mograine",
	"High Inquisitor Whitemane",
}

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

---Normally forces count is set to only ever go up.
local function UpdateForces()
	local state = State.current
	local fraction = math.min(state.elapsed / FORCES_FULL_AT, 1)

	AMT.Forces.SetTotal(TOTAL_FORCES)
	AMT.Forces.SetCurrent(math.floor(TOTAL_FORCES * fraction))

	if fraction >= 1 and not state.forcesCompleted then
		state.forcesCompleted = true
		state.forcesCompletedAtMS = math.floor(state.elapsed * 1000)

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

local function Populate()
	local state = State.current

	state.elapsed = math.random(300, TIME_LIMIT - 300)

	AMT.Forces.SetTotal(TOTAL_FORCES)
	AMT.Forces.SetCurrent(math.floor(TOTAL_FORCES * math.random(25, 95) / 100))

	local defeated = math.random(1, #BOSS_NAMES - 1)

	for index, name in ipairs(BOSS_NAMES) do
		local objective = { description = name, name = name }

		if index <= defeated then
			objective.completedAtMS = math.floor(state.elapsed * 1000 * index / (defeated + 1))
		end

		state.objectives[index] = objective
	end

	local deaths = math.random(0, #FAKE_DEATHS)

	state.deathCount = deaths
	state.deathTimeLost = deaths * DEATH_PENALTY

	for index = 1, deaths do
		local fake = FAKE_DEATHS[index]

		state.deaths[index] = {
			atMS = math.floor(state.elapsed * 1000 * index / (deaths + 1)),
			name = fake.name,
			class = fake.class,
		}
	end

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
		AMT.Util.Warn("preview is unavailable during a key.")

		return
	end

	if active then
		return
	end

	active = true
	animating = animated == true
	startedAt = GetTime()

	State.Reset()
	AMT.Providers.Use("demo")
	AMT.Providers.active.LoadKey()
	AMT.Frames.SetShown(true)

	if animating then
		AMT.Render.StartTicker()
	else
		Populate()
		AMT.Render.Flush()
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
	State.Reset()
	State.MarkAllDirty()
	AMT.Frames.SetShown(false)
	AMT.Render.Flush()
end

---@param animated boolean?
function Demo.Toggle(animated)
	local wantAnimated = animated == true
	local wasActive = active
	local wasAnimating = animating

	if wasActive then
		Demo.Exit()
	end

	if not wasActive or wasAnimating ~= wantAnimated then
		Demo.Enter(wantAnimated)
	end
end
