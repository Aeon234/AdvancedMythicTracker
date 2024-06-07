local addonName, AMT = ...

--Mythic Plus rewards. Key Level : Dungeon Rewards : Vault Rewards
BackdropInfo = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true,
	tileSize = 40,
	edgeSize = 8,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

--Figure out how many tabs are being displayed for the character so that we can assign what number our new custom tab will be.
AMT.PVEFrame_Panels = {
	{
		text = "Dungeons & Raids",
		frameName = "GroupFinderFrame",
		isVisible = true,
	},
	{
		text = "Player vs. Player",
		frameName = "PVPUIFrame",
		isVisible = true,
	},
	{
		text = "Mythic+ Dungeons",
		frameName = "ChallengesFrame",
		isVisible = false,
	},
	{
		text = "Advanced Keystone Tracker",
		frameName = "AMT_Window",
		isVisible = false,
	},
}

function AMT:GetAbbrFromChallengeModeID(id)
	for _, dungeon in ipairs(AMT.SeasonalDungeons) do
		if dungeon.challengeModeID == id then
			return dungeon.abbr
		end
	end
	return nil -- Return nil if no matching dungeon is found
end

AMT.RewardsTable = {
	{ "2", "441", "454" },
	{ "3", "444", "457" },
	{ "4", "444", "460" },
	{ "5", "447", "460" },
	{ "6", "447", "463" },
	{ "7", "450", "463" },
	{ "8", "450", "467" },
	{ "9", "454", "467" },
	{ "10", "454", "470" },
	{ "11", "457", "470" },
	{ "12", "457", "473" },
	{ "13", "460", "473" },
	{ "14", "460", "473" },
	{ "15", "463", "476" },
	{ "16", "463", "476" },
	{ "17", "467", "476" },
	{ "18", "467", "480" },
	{ "19", "470", "480" },
	{ "20", "470", "483" },
}

AMT.Challenges_Teleports = {
	--Dragonflight
	{ spellID = 393256, mapID = 399 }, -- Ruby Life Pools
	{ spellID = 393262, mapID = 400 }, -- The Nokhud Offensive
	{ spellID = 393279, mapID = 401 }, -- The Azure Vault
	{ spellID = 393273, mapID = 402 }, -- Algeth'ar Academy
	{ spellID = 393222, mapID = 403 }, -- Uldaman:Legacy of Tyr
	{ spellID = 393276, mapID = 404 }, -- Neltharus
	{ spellID = 393283, mapID = 406 }, -- Halls of Infusion
	{ spellID = 393267, mapID = 405 }, -- Brakenhide Hollow
	{ spellID = 424197, mapID = 463 }, -- Dawn of the infinite: Galakrond's Fall
	{ spellID = 424197, mapID = 464 }, -- Dawn of the infinite: Murozond's Rise

	--Shadowlands
	{ spellID = 354464, mapID = 375 }, -- Mist of Tirna Scithe
	{ spellID = 354462, mapID = 376 }, -- Necrotic Wake
	{ spellID = 354468, mapID = 377 }, -- De Other Side
	{ spellID = 354465, mapID = 378 }, -- Halls of Atonement
	{ spellID = 354463, mapID = 379 }, -- Plaguefall
	{ spellID = 354469, mapID = 380 }, -- Sanguine Depths
	{ spellID = 354466, mapID = 381 }, -- Spires of Ascension
	{ spellID = 354467, mapID = 382 }, -- Theater of Pain
	{ spellID = 367416, mapID = 391 }, -- Tazavesh, the Veiled Market: Streets of Wonder
	{ spellID = 367416, mapID = 392 }, -- Tazavesh, the Veiled Market: So'leah's Gambit

	--Battle for Azeroth
	{ spellID = 424187, mapID = 244 }, -- Atal'Dazar
	{ spellID = 410071, mapID = 245 }, -- Freehold
	{ spellID = 424167, mapID = 248 }, -- Waycrest Manor
	{ spellID = 410074, mapID = 251 }, -- The Underrot
	{ spellID = 373274, mapID = 369 }, -- Operation: Mechagon: Junkyard
	{ spellID = 373274, mapID = 370 }, -- Operation: Mechagon: Workshop

	--Legion
	{ spellID = 424163, mapID = 198 }, -- Darkheart Thicket
	{ spellID = 424153, mapID = 199 }, -- Black Rook Hold
	{ spellID = 393764, mapID = 200 }, -- Halls of Valor
	{ spellID = 410078, mapID = 206 }, -- Neltharion's Lair
	{ spellID = 393766, mapID = 210 }, -- Court of Stars
	{ spellID = 373262, mapID = 277 }, -- Return to Karazhan: Lower
	{ spellID = 373262, mapID = 234 }, -- Return to Karazhan: Upper

	--Warlords of Draenor
	{ spellID = 159898, mapID = 161 }, -- Skyreach
	{ spellID = 159895, mapID = 163 }, -- Bloodmaul Slag Mines
	{ spellID = 159897, mapID = 164 }, -- Auchindoun
	{ spellID = 159899, mapID = 165 }, -- Shadowmoon Burial Grounds
	{ spellID = 159900, mapID = 166 }, -- Grimrail Depot
	{ spellID = 159902, mapID = 167 }, -- Upper Blackrock Spire
	{ spellID = 159901, mapID = 168 }, -- The Everbloom
	{ spellID = 159896, mapID = 169 }, -- Iron Docks

	--Mist of Pandaria
	{ spellID = 131204, mapID = 2 }, -- Temple of the Jade Serpent

	--Cataclysm
	{ spellID = 410080, mapID = 438 }, -- The Vortex Pinnacle
	{ spellID = 424142, mapID = 456 }, -- Throne of the Tides
}

AMT.SeasonalDungeons = {
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 206,
		mapID = 1458,
		spellID = 410078,
		abbr = "NL",
		name = "Neltharion's Lair",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 245,
		mapID = 1754,
		spellID = 410071,
		abbr = "FH",
		name = "Freehold",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 251,
		mapID = 1841,
		spellID = 410074,
		abbr = "UNDR",
		name = "The Underrot",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 403,
		mapID = 2451,
		spellID = 393222,
		abbr = "ULD",
		name = "Uldaman: Legacy of Tyr",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 404,
		mapID = 2519,
		spellID = 393276,
		abbr = "NELT",
		name = "Neltharus",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 405,
		mapID = 2520,
		spellID = 393267,
		abbr = "BH",
		name = "Brackenhide Hollow",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 406,
		mapID = 2527,
		spellID = 393283,
		abbr = "HOI",
		name = "Halls of Infusion",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		challengeModeID = 438,
		mapID = 657,
		spellID = 410080,
		abbr = "VP",
		name = "The Vortex Pinnacle",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 168,
		mapID = 1279,
		spellID = 159901,
		abbr = "EB",
		name = "The Everbloom",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 198,
		mapID = 1466,
		spellID = 424163,
		abbr = "DHT",
		name = "Darkheart Thicket",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 199,
		mapID = 1501,
		spellID = 424153,
		abbr = "BRH",
		name = "Black Rook Hold",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 244,
		mapID = 1763,
		spellID = 424187,
		abbr = "AD",
		name = "Atal'Dazar",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 248,
		mapID = 1862,
		spellID = 424167,
		abbr = "WM",
		name = "Waycrest Manor",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 456,
		mapID = 643,
		spellID = 424142,
		abbr = "TOTT",
		name = "Throne of the Tides",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 463,
		mapID = 2579,
		spellID = 424197,
		abbr = "FALL",
		name = "Dawn of the Infinite: Galakrond's Fall",
		short = "DOTI: Galakrond's Fall",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		challengeModeID = 464,
		mapID = 2579,
		spellID = 424197,
		abbr = "RISE",
		name = "Dawn of the Infinite: Murozond's Rise",
		short = "DOTI: Murozond's Rise",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 399,
		mapID = 2521,
		spellID = 393256,
		abbr = "RLP",
		name = "Ruby Life Pools",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 400,
		mapID = 2516,
		spellID = 393262,
		abbr = "NO",
		name = "The Nokhud Offensive",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 401,
		mapID = 2515,
		spellID = 393279,
		abbr = "AV",
		name = "The Azure Vault",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 402,
		mapID = 2526,
		spellID = 393273,
		abbr = "AA",
		name = "Algeth'ar Academy",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 403,
		mapID = 2451,
		spellID = 393222,
		abbr = "ULD",
		name = "Uldaman: Legacy of Tyr",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 404,
		mapID = 2519,
		spellID = 393276,
		abbr = "NELT",
		name = "Neltharus",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 405,
		mapID = 2520,
		spellID = 393267,
		abbr = "BH",
		name = "Brackenhide Hollow",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		challengeModeID = 406,
		mapID = 2527,
		spellID = 393283,
		abbr = "HOI",
		name = "Halls of Infusion",
	},
}

AMT.RaidDifficulty_Levels = {
	{ id = 16, color = LEGENDARY_ORANGE_COLOR, order = 1, label = "M - ", name = "Mythic", abbr = "M" },
	{ id = 15, color = EPIC_PURPLE_COLOR, order = 2, label = "H - ", name = "Heroic", abbr = "H" },
	{ id = 14, color = RARE_BLUE_COLOR, order = 3, label = "N - ", name = "Normal", abbr = "N" },
	{ id = 17, color = UNCOMMON_GREEN_COLOR, order = 4, label = "RF - ", name = "Looking For Raid", abbr = "LFR" },
}

AMT.SeasonalRaids = {
	{
		seasonID = 9,
		seasonDisplayID = 1,
		journalInstanceID = 1200,
		instanceID = 2522,
		order = 1,
		numEncounters = 8,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "VOTI",
		name = "Vault of the Incarnates",
	},
	{
		seasonID = 10,
		seasonDisplayID = 2,
		journalInstanceID = 1208,
		instanceID = 2569,
		order = 2,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
	},
	{
		seasonID = 11,
		seasonDisplayID = 3,
		journalInstanceID = 1207,
		instanceID = 2549,
		order = 3,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1200,
		instanceID = 2522,
		order = 1,
		numEncounters = 8,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "VOTI",
		name = "Vault of the Incarnates",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1208,
		instanceID = 2569,
		order = 2,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
	},
	{
		seasonID = 12,
		seasonDisplayID = 4,
		journalInstanceID = 1207,
		instanceID = 2549,
		order = 3,
		numEncounters = 9,
		encounters = {},
		modifiedInstanceInfo = nil,
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
	},
}

AMT.Weekly_KillCount = {
	{ name = "M", kills = 0 },
	{ name = "H", kills = 0 },
	{ name = "N", kills = 0 },
	{ name = "LFR", kills = 0 },
}

AMT.DungeonAbbr = {
	-- Cata
	{ mapID = 438, Abbr = "VP" },

	-- MOP
	{ mapID = 2, Abbr = "TJS" },

	-- WoD
	{ mapID = 165, Abbr = "SBG" },
	{ mapID = 166, Abbr = "GD" },
	{ mapID = 169, Abbr = "ID" },

	-- Legion
	{ mapID = 200, Abbr = "HoV" },
	{ mapID = 206, Abbr = "NL" },
	{ mapID = 210, Abbr = "CoS" },
	{ mapID = 227, Abbr = "LOWR" },
	{ mapID = 234, Abbr = "UPPR" },

	-- BFA
	{ mapID = 245, Abbr = "FH" },
	{ mapID = 251, Abbr = "UR" },
	{ mapID = 369, Abbr = "Yard" },
	{ mapID = 370, Abbr = "Work" },

	-- SL
	{ mapID = 375, Abbr = "MotS" },
	{ mapID = 376, Abbr = "NW" },
	{ mapID = 377, Abbr = "DoS" },
	{ mapID = 378, Abbr = "HoA" },
	{ mapID = 379, Abbr = "PF" },
	{ mapID = 380, Abbr = "SD" },
	{ mapID = 381, Abbr = "SoA" },
	{ mapID = 382, Abbr = "ToP" },
	{ mapID = 391, Abbr = "Strt" },
	{ mapID = 392, Abbr = "Gmbt" },

	-- DF
	{ mapID = 399, Abbr = "RLP" },
	{ mapID = 400, Abbr = "NO" },
	{ mapID = 401, Abbr = "AV" },
	{ mapID = 402, Abbr = "AA" },
	{ mapID = 405, Abbr = "BH" },
	{ mapID = 404, Abbr = "NELT" },
	{ mapID = 403, Abbr = "ULD" },
	{ mapID = 406, Abbr = "HOI" },
}

AMT.AffixRotation = {
	{ rotation = { 9, 124, 6 }, rank = "(S)" },
	{ rotation = { 10, 134, 7 }, rank = "(S)" },
	{ rotation = { 9, 136, 123 }, rank = "(S)" },
	{ rotation = { 10, 135, 6 }, rank = "(S)" },
	{ rotation = { 9, 3, 8 }, rank = "(S)" },
	{ rotation = { 10, 124, 11 }, rank = "(S)" },
	{ rotation = { 9, 135, 7 }, rank = "(S)" },
	{ rotation = { 10, 136, 8 }, rank = "(S)" },
	{ rotation = { 9, 134, 11 }, rank = "(S)" },
	{ rotation = { 10, 3, 123 }, rank = "(S)" },
}

AMT.GetCurrentAffixesTable = C_MythicPlus.GetCurrentAffixes() or {}
AMT.CurrentWeek_AffixTable = {}
AMT.NextWeek_AffixTable = {}

AMT.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player")
AMT.Player_Mplus_ScoreColor = nil
--Set up a table that'll store the raw completed run keys from Blizz API
AMT.RunHistory = {}
--Set up a table that'll store all of our weekly keys
AMT.KeysDone = {}
--Set up the table that will hold the Season's dungeon info
AMT.Current_SeasonalDung_Info = {}
--Set up the table that'll store highest keys done per dungeon
AMT.BestKeys_per_Dungeon = {}
