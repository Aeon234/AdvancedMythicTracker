local AMT = select(2, ...)

local State = AMT.State

---@class AMTPartyMember
---@field unit string
---@field name string
---@field class string

---@class AMTDeaths
local Deaths = {}
AMT.Deaths = Deaths

---@type table<string,AMTPartyMember>
local partyByGUID = {}

function Deaths.SnapshotParty()
	wipe(partyByGUID)

	for index = 0, 4 do
		local unit = index == 0 and "player" or ("party" .. index)

		if UnitExists(unit) then
			local guid = UnitGUID(unit)

			if guid and not issecretvalue(guid) then
				local name = UnitName(unit)
				local class = select(2, UnitClass(unit))

				if name and class then
					partyByGUID[guid] = { unit = unit, name = name, class = class }
				end
			end
		end
	end
end

---@param guid string
function Deaths.RecordDeath(guid)
	if issecretvalue(guid) then
		return
	end

	local member = partyByGUID[guid]

	if not member then
		return
	end

	if UnitIsFeignDeath(member.unit) then
		return
	end

	local state = State.current

	state.deaths[#state.deaths + 1] = {
		atMS = math.floor(select(2, GetWorldElapsedTime(1)) * 1000),
		name = member.name,
		class = member.class,
	}

	State.MarkDirty("deaths")
end

function Deaths.UpdateCount()
	local count, timeLost = C_ChallengeMode.GetDeathCount()
	---@cast count number?
	---@cast timeLost number?

	if not count then
		return
	end

	local state = State.current

	state.deathCount = count
	state.deathTimeLost = timeLost or 0

	State.MarkDirty("deaths")
end
