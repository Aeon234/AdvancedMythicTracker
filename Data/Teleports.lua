local AMT = select(2, ...)

---@class AMTTeleport
---@field spell integer|integer[]|nil accounting for some dungeons having multiple teleports
---@field factionSpell { Alliance: integer, Horde: integer }|nil where the two factions teleport differently
---@field item integer? a toy or cloak rather than a spell
---@field maps table<integer, string>?

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
			{ spell = 1254572, maps = { [558] = "MT" } }, -- Magisters' Terrace
			{ spell = 1254559, maps = { [560] = "MC" } }, -- Maisara Caverns
			{ spell = 1254563, maps = { [559] = "NPX" } }, -- Nexus-Point Xenas
			{ spell = 1254400, maps = { [557] = "WS" } }, -- Windrunner Spire
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WAR_WITHIN,
		dungeons = {
			{ spell = 445444, maps = { [499] = "PSF" } }, -- Priory of the Sacred Flame
			{ spell = 445443, maps = { [500] = "ROOK" } }, -- The Rookery
			{ spell = 445269, maps = { [501] = "SV" } }, -- The Stonevault
			{ spell = 445416, maps = { [502] = "COT" } }, -- City of Threads
			{ spell = 445417, maps = { [503] = "ARAK" } }, -- Ara-Kara, City of Echoes
			{ spell = 445441, maps = { [504] = "DFC" } }, -- Darkflame Cleft
			{ spell = 445414, maps = { [505] = "DAWN" } }, -- The Dawnbreaker
			{ spell = 445440, maps = { [506] = "BREW" } }, -- Cinderbrew Meadery
			{ spell = 1216786, maps = { [525] = "FLOOD" } }, -- Operation: Floodgate
			{ spell = 1237215, maps = { [542] = "EDA" } }, -- Eco-Dome Al'dani
		},
		raids = {
			{ spell = 1239155 }, -- Manaforge Omega
			{ spell = 1226482 }, -- Liberation of Undermine
		},
	},
	{
		expansionLevel = LE_EXPANSION_DRAGONFLIGHT,
		dungeons = {
			{ spell = 393256, maps = { [399] = "RLP" } }, -- Ruby Life Pools
			{ spell = 393262, maps = { [400] = "NO" } }, -- The Nokhud Offensive
			{ spell = 393279, maps = { [401] = "AV" } }, -- The Azure Vault
			{ spell = 393273, maps = { [402] = "AA" } }, -- Algeth'ar Academy
			{ spell = 393222, maps = { [403] = "ULD" } }, -- Uldaman: Legacy of Tyr
			{ spell = 393276, maps = { [404] = "NELT" } }, -- Neltharus
			{ spell = 393267, maps = { [405] = "BH" } }, -- Brackenhide Hollow
			{ spell = 393283, maps = { [406] = "HOI" } }, -- Halls of Infusion
			{ spell = 424197, maps = { [463] = "FALL", [464] = "RISE" } }, -- Dawn of the Infinite
		},
		raids = {
			{ spell = 432258 }, -- Amirdrassil, the Dream's Hope
			{ spell = 432257 }, -- Aberrus, the Shadowed Crucible
			{ spell = 432254 }, -- Vault of the Incarnates
		},
	},
	{
		expansionLevel = LE_EXPANSION_SHADOWLANDS,
		dungeons = {
			{ spell = 354464, maps = { [375] = "MISTS" } }, -- Mists of Tirna Scithe
			{ spell = 354462, maps = { [376] = "NW" } }, -- The Necrotic Wake
			{ spell = 354468, maps = { [377] = "DOS" } }, -- De Other Side
			{ spell = 354465, maps = { [378] = "HOA" } }, -- Halls of Atonement
			{ spell = 354463, maps = { [379] = "PF" } }, -- Plaguefall
			{ spell = 354469, maps = { [380] = "SD" } }, -- Sanguine Depths
			{ spell = 354466, maps = { [381] = "SOA" } }, -- Spires of Ascension
			{ spell = 354467, maps = { [382] = "TOP" } }, -- Theater of Pain
			{ spell = 367416, maps = { [391] = "WNDR", [392] = "GMBT" } }, -- Tazavesh, the Veiled Market
		},
		raids = {
			{ spell = 373192 }, -- Sepulcher of the First Ones
			{ spell = 373191 }, -- Sanctum of Domination
			{ spell = 373190 }, -- Castle Nathria
		},
	},
	{
		expansionLevel = LE_EXPANSION_BATTLE_FOR_AZEROTH,
		dungeons = {
			{ spell = 424187, maps = { [244] = "AD" } }, -- Atal'Dazar
			{ spell = 410071, maps = { [245] = "FH" } }, -- Freehold
			{ factionSpell = { Alliance = 467553, Horde = 467555 }, maps = { [247] = "ML" } }, -- The MOTHERLODE!!
			{ spell = 424167, maps = { [248] = "WM" } }, -- Waycrest Manor
			{ spell = 410074, maps = { [251] = "UNDR" } }, -- The Underrot
			{ factionSpell = { Alliance = 445418, Horde = 464256 }, maps = { [353] = "SIEGE" } }, -- Siege of Boralus
			{ spell = 373274, maps = { [369] = "JY", [370] = "WORK" } }, -- Operation: Mechagon
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_LEGION,
		dungeons = {
			{ spell = 1254551, maps = { [239] = "SEAT" } }, -- Seat of the Triumvirate
			{ spell = 424163, maps = { [198] = "DHT" } }, -- Darkheart Thicket
			{ spell = 424153, maps = { [199] = "BRH" } }, -- Black Rook Hold
			{ spell = 393764, maps = { [200] = "HOV" } }, -- Halls of Valor
			{ spell = 410078, maps = { [206] = "NL" } }, -- Neltharion's Lair
			{ spell = 393766, maps = { [210] = "COS" } }, -- Court of Stars
			{ spell = 373262, maps = { [277] = "LOWER", [234] = "UPPER" } }, -- Return to Karazhan
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WARLORDS_OF_DRAENOR,
		dungeons = {
			{ spell = { 159898, 1254557 }, maps = { [161] = "SR" } }, -- Skyreach
			{ spell = 159895, maps = { [163] = "BSM" } }, -- Bloodmaul Slag Mines
			{ spell = 159897, maps = { [164] = "AUC" } }, -- Auchindoun
			{ spell = 159899, maps = { [165] = "SBG" } }, -- Shadowmoon Burial Grounds
			{ spell = 159900, maps = { [166] = "GD" } }, -- Grimrail Depot
			{ spell = 159902, maps = { [167] = "UBRS" } }, -- Upper Blackrock Spire
			{ spell = 159901, maps = { [168] = "EB" } }, -- The Everbloom
			{ spell = 159896, maps = { [169] = "ID" } }, -- Iron Docks
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_MISTS_OF_PANDARIA,
		dungeons = {
			{ spell = 131225, maps = { [57] = "GOTSS" } }, -- Gate of the Setting Sun
			{ spell = 131222, maps = { [60] = "MSP" } }, -- Mogu'shan Palace
			{ spell = 131232, maps = { [76] = "SCHOLO" } }, -- Scholomance
			{ spell = 131231, maps = { [77] = "SH" } }, -- Scarlet Halls
			{ spell = 131229, maps = { [78] = "SM" } }, -- Scarlet Monastery
			{ spell = 131228, maps = { [59] = "SNT" } }, -- Siege of Niuzao Temple
			{ spell = 131206, maps = { [58] = "SPM" } }, -- Shado-Pan Monastery
			{ spell = 131205, maps = { [56] = "SSB" } }, -- Stormstout Brewery
			{ spell = 131204, maps = { [2] = "TJS" } }, -- Temple of the Jade Serpent
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_CATACLYSM,
		dungeons = {
			{ spell = 410080, maps = { [438] = "VP" } }, -- The Vortex Pinnacle
			{ spell = 424142, maps = { [456] = "TOTT" } }, -- Throne of the Tides
			{ spell = 445424, maps = { [507] = "GB" } }, -- Grim Batol
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
		dungeons = {
			{ spell = 1254555, maps = { [556] = "POS" } }, -- Pit of Saron
		},
		raids = {},
	},
}

---@type table<integer, AMTTeleport>
local byChallengeMap = {}

---@type table<integer, string>
local abbreviations = {}

for _, group in ipairs(Teleports.groups) do
	for _, teleport in ipairs(group.dungeons) do
		for challengeMapID, abbr in pairs(teleport.maps) do
			byChallengeMap[challengeMapID] = teleport
			abbreviations[challengeMapID] = abbr
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
---@return string? abbr nil when the dungeon is not catalogued
function Teleports.AbbreviationFor(challengeMapID)
	return abbreviations[challengeMapID]
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
