local AMT = select(2, ...)

local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local TIMEOUT_SECONDS = 5
local INTERVAL_SECONDS = 1.5
local RETRY_SECONDS = 20
local MIN_RETRY_DELAY = 0.1

---@class AMTInspectRequest
---@field unit string
---@field guid string
---@field timer FunctionContainer

---@class AMTInspect : CallbackRegistryMixin
---@field Event { SpecUpdated: string }
local Inspect = CreateFromMixins(CallbackRegistryMixin)
AMT.Inspect = Inspect

Inspect:OnLoad()
Inspect:GenerateCallbackEvents({ "SpecUpdated" })

---@type table<string, integer>
local specByGUID = {}

---@type table<string, number>
local retryAt = {}

---@type table<string, true>
local roster = {}

---@type string[]
local queue = {}

---@type AMTInspectRequest?
local pending

---@type FunctionContainer?
local nextStep

---@type FunctionContainer?
local retryTimer

---@param unit string
---@return string? guid nil when the unit is absent or its identity is restricted
local function ReadableGUID(unit)
	local guid = UnitGUID(unit)

	if not guid or issecretvalue(guid) then
		return nil
	end

	return guid
end

---@return boolean
local function IsPlayerInspecting()
	return (InspectFrame ~= nil and InspectFrame:IsShown())
		or (PlayerSpellsFrame ~= nil and PlayerSpellsFrame:IsInspecting())
end

local Step, Rebuild

---@param delay number
local function ScheduleStep(delay)
	if nextStep then
		nextStep:Cancel()
	end

	nextStep = C_Timer.NewTimer(delay, Step)
end

local function ScheduleRetry()
	if retryTimer then
		retryTimer:Cancel()
		retryTimer = nil
	end

	local soonest

	for _, at in pairs(retryAt) do
		if not soonest or at < soonest then
			soonest = at
		end
	end

	if not soonest then
		return
	end

	retryTimer = C_Timer.NewTimer(math.max(soonest - GetTime(), MIN_RETRY_DELAY), function()
		retryTimer = nil
		Rebuild()
	end)
end

---@param guid string
local function Defer(guid)
	retryAt[guid] = GetTime() + RETRY_SECONDS
	ScheduleRetry()
end

local function Finish()
	if pending then
		pending.timer:Cancel()
		pending = nil
	end

	if not IsPlayerInspecting() then
		ClearInspectPlayer()
	end

	ScheduleStep(INTERVAL_SECONDS)
end

local function OnTimeout()
	if pending then
		Defer(pending.guid)
	end

	Finish()
end

function Step()
	nextStep = nil

	if pending or InCombatLockdown() then
		return
	end

	if IsPlayerInspecting() then
		ScheduleStep(INTERVAL_SECONDS)

		return
	end

	while #queue > 0 do
		local unit = table.remove(queue, 1)
		local guid = ReadableGUID(unit)

		if guid and not specByGUID[guid] then
			if UnitIsConnected(unit) and CanInspect(unit) then
				NotifyInspect(unit)
				pending = { unit = unit, guid = guid, timer = C_Timer.NewTimer(TIMEOUT_SECONDS, OnTimeout) }

				return
			end

			Defer(guid)
		end
	end
end

function Rebuild()
	if InCombatLockdown() then
		return
	end

	local now = GetTime()
	---@type table<string, true>
	local present = {}

	wipe(queue)

	for _, unit in ipairs(PARTY_UNITS) do
		local guid = ReadableGUID(unit)

		if guid then
			present[guid] = true

			if not roster[guid] then
				specByGUID[guid] = nil
				retryAt[guid] = nil
			end

			local deferred = retryAt[guid] and retryAt[guid] > now

			if not specByGUID[guid] and not deferred then
				queue[#queue + 1] = unit
			end
		end
	end

	for guid, at in pairs(retryAt) do
		if not present[guid] or at <= now then
			retryAt[guid] = nil
		end
	end

	roster = present
	ScheduleRetry()

	if not pending and not nextStep then
		ScheduleStep(0)
	end
end

---@param guid string
local function OnInspectReady(guid)
	if not pending or issecretvalue(guid) or guid ~= pending.guid then
		return
	end

	if not InCombatLockdown() and ReadableGUID(pending.unit) == guid then
		local specID = C_SpecializationInfo.GetInspectSpecialization(pending.unit)

		if issecretvalue(specID) then
			Defer(guid)
		elseif specID > 0 then
			Inspect:SetSpecID(guid, specID)
		else
			Defer(guid)
		end
	end

	Finish()
end

---@param unit string
local function OnSpecializationChanged(unit)
	local guid = ReadableGUID(unit)

	if guid then
		specByGUID[guid] = nil
		retryAt[guid] = nil
	end

	Rebuild()
end

---@param guid string
---@param specID integer
function Inspect:SetSpecID(guid, specID)
	retryAt[guid] = nil

	if specByGUID[guid] == specID then
		return
	end

	specByGUID[guid] = specID
	self:TriggerEvent(self.Event.SpecUpdated, guid)
end

---@param guid string
---@return integer? specID nil until an inspect or comms has supplied it
function Inspect:GetSpecID(guid)
	if guid == ReadableGUID("player") then
		local index = C_SpecializationInfo.GetSpecialization()

		return index and C_SpecializationInfo.GetSpecializationInfo(index) or nil
	end

	return specByGUID[guid]
end

---@param guid string
---@return number? icon
function Inspect:GetSpecIcon(guid)
	local specID = self:GetSpecID(guid)

	if not specID or specID == 0 then
		return nil
	end

	return (select(4, GetSpecializationInfoByID(specID)))
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("INSPECT_READY")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "INSPECT_READY" then
		OnInspectReady(...)
	elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
		OnSpecializationChanged(...)
	else
		Rebuild()
	end
end)
