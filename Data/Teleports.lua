local AMT = select(2, ...)

---@class AMTTeleport
---@field spell integer|integer[]|nil accounting for some dungeons having multiple teleports
---@field factionSpell { Alliance: integer, Horde: integer }|nil where the two factions teleport differently
---@field item integer? a toy or cloak rather than a spell

---@class AMTTeleportDungeon : AMTTeleport
---@field challengeIDs table<integer, string>

---@class AMTTeleportGroup
---@field expansionLevel integer
---@field dungeons AMTTeleportDungeon[]
---@field raids AMTTeleport[]

---@class AMTTeleports
---@field groups AMTTeleportGroup[] newest expansion first
local Teleports = {}
AMT.Teleports = Teleports

Teleports.groups = {
	{
		expansionLevel = LE_EXPANSION_MIDNIGHT,
		dungeons = {
			{ spell = 1254559, challengeIDs = { [560] = "MC" } }, -- Maisara Caverns
			{ spell = 1254563, challengeIDs = { [559] = "NPX" } }, -- Nexus-Point Xenas
			{ spell = 1254572, challengeIDs = { [558] = "MT" } }, -- Magisters' Terrace
			{ spell = 1286807, challengeIDs = { [586] = "DON" } }, -- Den of Nalorakk
			{ spell = 1254400, challengeIDs = { [557] = "WS" } }, -- Windrunner Spire
			{ spell = 1286801, challengeIDs = { [584] = "BV" } }, -- The Blinding Vale
			{ spell = 1286804, challengeIDs = { [585] = "VSA" } }, -- Voidscar Arena
			{ spell = 1286809, challengeIDs = { [587] = "MR" } }, -- Murder Row
			{ spell = 1286812, challengeIDs = { [588] = "AOF" } }, -- Altar of Fangs
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WAR_WITHIN,
		dungeons = {
			{ spell = 445444, challengeIDs = { [499] = "PSF" } }, -- Priory of the Sacred Flame
			{ spell = 445443, challengeIDs = { [500] = "ROOK" } }, -- The Rookery
			{ spell = 445269, challengeIDs = { [501] = "SV" } }, -- The Stonevault
			{ spell = 445416, challengeIDs = { [502] = "COT" } }, -- City of Threads
			{ spell = 445417, challengeIDs = { [503] = "ARAK" } }, -- Ara-Kara, City of Echoes
			{ spell = 445441, challengeIDs = { [504] = "DFC" } }, -- Darkflame Cleft
			{ spell = 445414, challengeIDs = { [505] = "DAWN" } }, -- The Dawnbreaker
			{ spell = 445440, challengeIDs = { [506] = "BREW" } }, -- Cinderbrew Meadery
			{ spell = 1216786, challengeIDs = { [525] = "FLOOD" } }, -- Operation: Floodgate
			{ spell = 1237215, challengeIDs = { [542] = "EDA" } }, -- Eco-Dome Al'dani
		},
		raids = {
			{ spell = 1239155 }, -- Manaforge Omega
			{ spell = 1226482 }, -- Liberation of Undermine
		},
	},
	{
		expansionLevel = LE_EXPANSION_DRAGONFLIGHT,
		dungeons = {
			{ spell = 393256, challengeIDs = { [399] = "RLP" } }, -- Ruby Life Pools
			{ spell = 393262, challengeIDs = { [400] = "NO" } }, -- The Nokhud Offensive
			{ spell = 393279, challengeIDs = { [401] = "AV" } }, -- The Azure Vault
			{ spell = 393273, challengeIDs = { [402] = "AA" } }, -- Algeth'ar Academy
			{ spell = 393222, challengeIDs = { [403] = "ULD" } }, -- Uldaman: Legacy of Tyr
			{ spell = 393276, challengeIDs = { [404] = "NELT" } }, -- Neltharus
			{ spell = 393267, challengeIDs = { [405] = "BH" } }, -- Brackenhide Hollow
			{ spell = 393283, challengeIDs = { [406] = "HOI" } }, -- Halls of Infusion
			{ spell = 424197, challengeIDs = { [463] = "FALL", [464] = "RISE" } }, -- Dawn of the Infinite
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
			{ spell = 354464, challengeIDs = { [375] = "MISTS" } }, -- Mists of Tirna Scithe
			{ spell = 354462, challengeIDs = { [376] = "NW" } }, -- The Necrotic Wake
			{ spell = 354468, challengeIDs = { [377] = "DOS" } }, -- De Other Side
			{ spell = 354465, challengeIDs = { [378] = "HOA" } }, -- Halls of Atonement
			{ spell = 354463, challengeIDs = { [379] = "PF" } }, -- Plaguefall
			{ spell = 354469, challengeIDs = { [380] = "SD" } }, -- Sanguine Depths
			{ spell = 354466, challengeIDs = { [381] = "SOA" } }, -- Spires of Ascension
			{ spell = 354467, challengeIDs = { [382] = "TOP" } }, -- Theater of Pain
			{ spell = 367416, challengeIDs = { [391] = "WNDR", [392] = "GMBT" } }, -- Tazavesh, the Veiled Market
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
			{ spell = 424187, challengeIDs = { [244] = "AD" } }, -- Atal'Dazar
			{ spell = 410071, challengeIDs = { [245] = "FH" } }, -- Freehold
			{ factionSpell = { Alliance = 467553, Horde = 467555 }, challengeIDs = { [247] = "ML" } }, -- The MOTHERLODE!!
			{ spell = 424167, challengeIDs = { [248] = "WM" } }, -- Waycrest Manor
			{ spell = 410074, challengeIDs = { [251] = "UNDR" } }, -- The Underrot
			{ factionSpell = { Alliance = 445418, Horde = 464256 }, challengeIDs = { [353] = "SIEGE" } }, -- Siege of Boralus
			{ spell = 373274, challengeIDs = { [369] = "JY", [370] = "WORK" } }, -- Operation: Mechagon
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_LEGION,
		dungeons = {
			{ spell = 1254551, challengeIDs = { [239] = "SEAT" } }, -- Seat of the Triumvirate
			{ spell = 424163, challengeIDs = { [198] = "DHT" } }, -- Darkheart Thicket
			{ spell = 424153, challengeIDs = { [199] = "BRH" } }, -- Black Rook Hold
			{ spell = 393764, challengeIDs = { [200] = "HOV" } }, -- Halls of Valor
			{ spell = 410078, challengeIDs = { [206] = "NL" } }, -- Neltharion's Lair
			{ spell = 393766, challengeIDs = { [210] = "COS" } }, -- Court of Stars
			{ spell = 373262, challengeIDs = { [277] = "LOWER", [234] = "UPPER" } }, -- Return to Karazhan
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WARLORDS_OF_DRAENOR,
		dungeons = {
			{ spell = { 159898, 1254557 }, challengeIDs = { [161] = "SR" } }, -- Skyreach
			{ spell = 159895, challengeIDs = { [163] = "BSM" } }, -- Bloodmaul Slag Mines
			{ spell = 159897, challengeIDs = { [164] = "AUC" } }, -- Auchindoun
			{ spell = 159899, challengeIDs = { [165] = "SBG" } }, -- Shadowmoon Burial Grounds
			{ spell = 159900, challengeIDs = { [166] = "GD" } }, -- Grimrail Depot
			{ spell = 159902, challengeIDs = { [167] = "UBRS" } }, -- Upper Blackrock Spire
			{ spell = 159901, challengeIDs = { [168] = "EB" } }, -- The Everbloom
			{ spell = 159896, challengeIDs = { [169] = "ID" } }, -- Iron Docks
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_MISTS_OF_PANDARIA,
		dungeons = {
			{ spell = 131225, challengeIDs = { [57] = "GOTSS" } }, -- Gate of the Setting Sun
			{ spell = 131222, challengeIDs = { [60] = "MSP" } }, -- Mogu'shan Palace
			{ spell = 131232, challengeIDs = { [76] = "SCHOLO" } }, -- Scholomance
			{ spell = 131231, challengeIDs = { [77] = "SH" } }, -- Scarlet Halls
			{ spell = 131229, challengeIDs = { [78] = "SM" } }, -- Scarlet Monastery
			{ spell = 131228, challengeIDs = { [59] = "SNT" } }, -- Siege of Niuzao Temple
			{ spell = 131206, challengeIDs = { [58] = "SPM" } }, -- Shado-Pan Monastery
			{ spell = 131205, challengeIDs = { [56] = "SSB" } }, -- Stormstout Brewery
			{ spell = 131204, challengeIDs = { [2] = "TJS" } }, -- Temple of the Jade Serpent
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_CATACLYSM,
		dungeons = {
			{ spell = 410080, challengeIDs = { [438] = "VP" } }, -- The Vortex Pinnacle
			{ spell = 424142, challengeIDs = { [456] = "TOTT" } }, -- Throne of the Tides
			{ spell = 445424, challengeIDs = { [507] = "GB" } }, -- Grim Batol
		},
		raids = {},
	},
	{
		expansionLevel = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
		dungeons = {
			{ spell = 1254555, challengeIDs = { [556] = "POS" } }, -- Pit of Saron
		},
		raids = {},
	},
}

---@type table<integer, AMTTeleportDungeon>
local byChallengeID = {}

for _, group in ipairs(Teleports.groups) do
	for _, teleport in ipairs(group.dungeons) do
		for challengeID in pairs(teleport.challengeIDs) do
			if byChallengeID[challengeID] then
				AMT.Util.Warn("challenge ID %d is claimed by two teleports.", challengeID)
			end

			byChallengeID[challengeID] = teleport
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

	return nil
end

---@param challengeID integer
---@return string? abbr nil when the dungeon is not catalogued
function Teleports.AbbreviationFor(challengeID)
	local teleport = byChallengeID[challengeID]

	return teleport and teleport.challengeIDs[challengeID]
end

---@param challengeID integer
---@return AMTTeleportAction?
function Teleports.ForChallengeID(challengeID)
	local teleport = byChallengeID[challengeID]

	if not teleport then
		return nil
	end

	return Resolve(teleport)
end
