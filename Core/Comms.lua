local AMT = select(2, ...)

local PARTY_UNITS = { "party1", "party2", "party3", "party4" }
local GROUP_CHANNELS = { PARTY = true, RAID = true, INSTANCE_CHAT = true }

-- Detailsand EnhanceQoL
local PLAYER_INFO_PREFIX = "PITB"
local OPEN_KEYSTONE_PREFIX = "EQKS"

-- Sends fail with AddOnMessageLockdown under these rather than queueing, so a request waits them out.
local RESTRICTIONS = {
	Enum.AddOnRestrictionType.Combat,
	Enum.AddOnRestrictionType.ChallengeMode,
	Enum.AddOnRestrictionType.Chat,
}

local REQUEST_DELAY_SECONDS = 1

---@class AMTCommsKeystone
---@field challengeMapID integer
---@field level integer

---@class AMTComms : CallbackRegistryMixin
---@field Event { KeystoneUpdated: string }
local Comms = CreateFromMixins(CallbackRegistryMixin)
AMT.Comms = Comms

Comms:OnLoad()
Comms:GenerateCallbackEvents({ "KeystoneUpdated" })

---@type table<string, string>
local guidByName = {}

---@type table<string, AMTCommsKeystone>
local keystoneByGUID = {}

---@type table<string, true>
local roster = {}

local requestPending = false

---@type FunctionContainer?
local requestTimer

---@return boolean
local function IsRestricted()
	for _, restriction in ipairs(RESTRICTIONS) do
		if C_RestrictedActions.IsAddOnRestrictionActive(restriction) then
			return true
		end
	end

	return false
end

---@param sender unknown a name as the chat system or a library hands it over
---@return string? guid nil for anyone outside the party, or when the name cannot be read
local function ResolveSender(sender)
	if type(sender) ~= "string" or issecretvalue(sender) then
		return nil
	end

	return guidByName[Ambiguate(sender, "none")]
end

---@param guid string
---@param challengeMapID integer
---@param level integer zero, as the libraries send it, when the member holds no key
local function StoreKeystone(guid, challengeMapID, level)
	local current = keystoneByGUID[guid]

	if challengeMapID <= 0 or level <= 0 then
		if not current then
			return
		end

		keystoneByGUID[guid] = nil
	elseif current and current.challengeMapID == challengeMapID and current.level == level then
		return
	else
		keystoneByGUID[guid] = { challengeMapID = challengeMapID, level = level }
	end

	Comms:TriggerEvent(Comms.Event.KeystoneUpdated, guid)
end

---@param guid string
---@param specID integer?
local function StoreSpec(guid, specID)
	if specID and specID > 0 then
		AMT.Inspect:SetSpecID(guid, specID)
	end
end

---@class AMTCommsKeystoneLibrary
---@field library table? LibKeystone, nil when it failed to load
local KeystoneLibrary = {}

function KeystoneLibrary:Attach()
	self.library = LibStub("LibKeystone", true)

	if not self.library then
		return
	end

	self.library.Register(self, function(level, challengeMapID, _, sender, channel)
		if channel ~= "PARTY" then
			return
		end

		local guid = ResolveSender(sender)

		if guid then
			StoreKeystone(guid, tonumber(challengeMapID) or 0, tonumber(level) or 0)
		end
	end)
end

function KeystoneLibrary:Request()
	if self.library then
		self.library.Request("PARTY")
	end
end

---@class AMTCommsSpecializationLibrary
local SpecializationLibrary = {}

function SpecializationLibrary:Attach()
	local library = LibStub("LibSpecialization", true)

	if not library then
		return
	end

	library.RegisterGroup(self, function(specID, _, _, sender)
		local guid = ResolveSender(sender)

		if guid then
			StoreSpec(guid, tonumber(specID))
		end
	end)
end

---@class AMTCommsPlayerInfo
local PlayerInfo = {}

function PlayerInfo:Attach()
	LibStub("AceComm-3.0"):Embed(self)
	self:RegisterComm(PLAYER_INFO_PREFIX, "OnMessage")
end

---@param message string
---@return string?
local function Inflate(message)
	local decoded, compressed = pcall(C_EncodingUtil.DecodeBase64, message)

	if not decoded or not compressed then
		return nil
	end

	local inflated, data = pcall(C_EncodingUtil.DecompressString, compressed, Enum.CompressionMethod.Deflate)

	if not inflated or type(data) ~= "string" then
		return nil
	end

	return data
end

---@param guid string
---@param section string
function PlayerInfo:ReadSection(guid, section)
	local kind = section:sub(1, 1)

	-- Packed lists lead with their own length.
	if kind == "K" then
		local _, level, _, challengeMapID, _, _, _, specID = strsplit(",", section:sub(2))

		StoreKeystone(guid, tonumber(challengeMapID) or 0, tonumber(level) or 0)
		StoreSpec(guid, tonumber(specID))
	elseif kind == "S" then
		local _, specID = strsplit(",", section:sub(2))

		StoreSpec(guid, tonumber(specID))
	end
end

---@param message string
---@param channel string
---@param sender string
function PlayerInfo:OnMessage(_, message, channel, sender)
	if not GROUP_CHANNELS[channel] then
		return
	end

	local guid = ResolveSender(sender)

	if not guid then
		return
	end

	local data = Inflate(message)

	if not data then
		return
	end

	if data:sub(1, 2) ~= "F#" then
		self:ReadSection(guid, data)

		return
	end

	for section in data:sub(3):gmatch("[^#]+") do
		self:ReadSection(guid, section)
	end
end

---@class AMTCommsOpenKeystone
---@field deflate table LibDeflate
local OpenKeystone = {}

function OpenKeystone:Attach()
	self.deflate = LibStub("LibDeflate")
	LibStub("AceComm-3.0"):Embed(self)
	self:RegisterComm(OPEN_KEYSTONE_PREFIX, "OnMessage")
end

---@param message string
---@param channel string
---@param sender string
function OpenKeystone:OnMessage(_, message, channel, sender)
	if not GROUP_CHANNELS[channel] then
		return
	end

	local guid = ResolveSender(sender)

	if not guid then
		return
	end

	local decoded = self.deflate:DecodeForWoWAddonChannel(message)
	local data = decoded and self.deflate:DecompressDeflate(decoded)

	if type(data) ~= "string" then
		return
	end

	local kind, challengeMapID, level, extra = strsplit(",", data)

	if kind == "K" and not extra then
		StoreKeystone(guid, tonumber(challengeMapID) or 0, tonumber(level) or 0)
	end
end

local function FlushRequest()
	requestTimer = nil

	if not requestPending or not IsInGroup() then
		requestPending = false

		return
	end

	if IsRestricted() then
		return
	end

	requestPending = false
	KeystoneLibrary:Request()
end

local function ScheduleRequest()
	requestPending = true

	if not requestTimer then
		requestTimer = C_Timer.NewTimer(REQUEST_DELAY_SECONDS, FlushRequest)
	end
end

---@param unit string
---@return string? name as a sender resolves to it; nil for an NPC or a name that cannot be read
local function RosterName(unit)
	-- Delve and follower companions fill party slots, and none of them runs an addon.
	local isPlayer = UnitIsPlayer(unit)

	if issecretvalue(isPlayer) or not isPlayer then
		return nil
	end

	local name, realm = UnitName(unit)

	if not name or issecretvalue(name) or issecretvalue(realm) then
		return nil
	end

	if realm and realm ~= "" then
		name = name .. "-" .. realm
	end

	return Ambiguate(name, "none")
end

---@return boolean joined
local function RebuildRoster()
	if InCombatLockdown() then
		return false
	end

	local joined = false
	---@type table<string, true>
	local present = {}

	wipe(guidByName)

	for _, unit in ipairs(PARTY_UNITS) do
		local guid = UnitGUID(unit)
		local name = RosterName(unit)

		if guid and name and not issecretvalue(guid) then
			present[guid] = true
			guidByName[name] = guid
		end
	end

	for guid in pairs(present) do
		if not roster[guid] then
			joined = true
		end
	end

	for guid in pairs(keystoneByGUID) do
		if not present[guid] then
			keystoneByGUID[guid] = nil
			Comms:TriggerEvent(Comms.Event.KeystoneUpdated, guid)
		end
	end

	roster = present

	return joined
end

---@param guid string
---@return AMTCommsKeystone? keystone nil until a member's addon has reported one
function Comms:GetKeystone(guid)
	return keystoneByGUID[guid]
end

KeystoneLibrary:Attach()
SpecializationLibrary:Attach()
PlayerInfo:Attach()
OpenKeystone:Attach()

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED")
frame:SetScript("OnEvent", function(_, event, ...)
	if event == "ADDON_RESTRICTION_STATE_CHANGED" then
		local _, state = ...

		if requestPending and state == Enum.AddOnRestrictionState.Inactive then
			C_Timer.After(0, FlushRequest)
		end

		return
	end

	if RebuildRoster() then
		ScheduleRequest()
	elseif event == "PLAYER_REGEN_ENABLED" and requestPending then
		FlushRequest()
	end
end)
