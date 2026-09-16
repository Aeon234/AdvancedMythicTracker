local AMT = select(2, ...)

---@class AMTTeleport
---@field spell integer|integer[]|nil accounting for some dungeons having multiple teleports
---@field factionSpell { Alliance: integer, Horde: integer }|nil where the two factions teleport differently
---@field item integer? a toy or cloak rather than a spell
---@field challengeMapID integer? Mythic+ map ID
---@field abbr string?

---@class AMTTeleportGroup
---@field expansionLevel integer
---@field dungeons AMTTeleport[]
---@field raids AMTTeleport[]

---@class AMTTeleports
---@field groups AMTTeleportGroup[] newest expansion first
local Teleports = {}
AMT.Teleports = Teleports

Teleports.groups = {
	{
		expansionLevel = LE_EXPANSION_MIDNIGHT,
		dungeons = {
			{ spell = 1254572, challengeMapID = 558, abbr = "MT" }, -- Magisters' Terrace
			{ spell = 1254559, challengeMapID = 560, abbr = "MC" }, -- Maisara Caverns
			{ spell = 1254563, challengeMapID = 559, abbr = "NPX" }, -- Nexus-Point Xenas
			{ spell = 1254400, challengeMapID = 557, abbr = "WS" }, -- Windrunner Spire
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_DRAGONFLIGHT,
		dungeons = {
			{ spell = 393273, challengeMapID = 402, abbr = "AA" }, -- Algeth'ar Academy
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_LEGION,
		dungeons = {
			{ spell = 1254551, challengeMapID = 239, abbr = "SOTT" }, -- Seat of the Triumvirate
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WARLORDS_OF_DRAENOR,
		dungeons = {
			{ spell = 159898, challengeMapID = 161, abbr = "SR" }, -- Skyreach
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
		dungeons = {
			{ spell = 1254555, challengeMapID = 556, abbr = "POS" }, -- Pit of Saron
		},
		raids = {},
	},
}

---@type table<integer, AMTTeleport>
local byChallengeMap = {}

for _, group in ipairs(Teleports.groups) do
	for _, teleport in ipairs(group.dungeons) do
		if teleport.challengeMapID then
			byChallengeMap[teleport.challengeMapID] = teleport
		end
	end
end

---@class AMTTeleportAction
---@field kind "spell"|"item"
---@field id integer
---@field known boolean

---@param teleport AMTTeleport
---@return AMTTeleportAction? action nil for an entry this addon cannot cast yet
local function Resolve(teleport)
	local spell = teleport.factionSpell and teleport.factionSpell[UnitFactionGroup("player")] or teleport.spell

	if type(spell) == "number" then
		return { kind = "spell", id = spell, known = C_SpellBook.IsSpellKnown(spell) }
	end

	if type(spell) == "table" then
		for _, spellID in ipairs(spell) do
			if C_SpellBook.IsSpellKnown(spellID) then
				return { kind = "spell", id = spellID, known = true }
			end
		end

		return { kind = "spell", id = spell[1], known = false }
	end

	-- Item teleports are catalogued for the map-frame hub, which decides how to test and cast them.
	return nil
end

---@param challengeMapID integer
---@return string? abbr nil when the dungeon is not catalogued or has no abbreviation yet
function Teleports.AbbreviationFor(challengeMapID)
	local teleport = byChallengeMap[challengeMapID]

	return teleport and teleport.abbr
end

---@param challengeMapID integer
---@return AMTTeleportAction?
function Teleports.ForChallengeMap(challengeMapID)
	local teleport = byChallengeMap[challengeMapID]

	if not teleport then
		return nil
	end

	return Resolve(teleport)
end
