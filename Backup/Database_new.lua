local addonName, AMT = ...

-- ============================
-- === Initialize Variables ===
-- ============================
AMT.AMT_CreationComplete = false
AMT.ElvUIEnabled = false
AMT.DetailsEnabled = false
AMT.DebugMode = false

if ElvUI then
	AMT.ElvUIEnabled = true -- ElvUI Enabled
	AMT.E = unpack(ElvUI) -- ElvUI Functions
	AMT.S = ElvUI[1]:GetModule("Skins") -- ElvUI Skinning
end

if Details then
	AMT.DetailsEnabled = true -- Details Enabled
	AMT.OpenRaidLib = LibStub("LibOpenRaid-1.0", true) -- Call OpenRaidLib functions
end

AMT.Vault_RaidReq = 6 -- Number of Raid kills required for max rewards
AMT.Vault_DungeonReq = 8 -- Number of Dungeon completions required for max rewards
AMT.GetCurrentAffixesTable = C_MythicPlus.GetCurrentAffixes() or {} --Current Affix Raw Table
AMT.CurrentWeek_AffixTable = {} --Cleaned Affix Table
AMT.NextWeek_AffixTable = {} --Next Week's Affix Table
AMT.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player") --Raw Player M+ Summary
AMT.Player_Mplus_ScoreColor = nil --M+ Score Color
AMT.RunHistory = {} --M+ runs history
AMT.KeysDone = {} --Cleaned M+ runs history
AMT.Current_SeasonalDung_Info = {} --Current M+ dungeons info
AMT.BestKeys_per_Dungeon = {} --Highest keys done per M+ dungeon
AMT.Tab = "          "
AMT.Whitetext = "|cffffffff"
AMT.BackgroundClear = { 0, 0, 0, 0.0 }
AMT.BackgroundClear = { 0, 0, 0, 0.4 }

-- ==============================
-- === Shortcuts and Keybinds ===
-- ==============================
_G["BINDING_NAME_AMT"] = "Show/Hide the window" -- Keybind option name

-- ===================
-- === Data Tables ===
-- ===================

--Custom PVEFrame Tabs
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

-- Rewards table for each key level
AMT.RewardsTable = {
	{
		Key = "2",
		EndofDungeon = "496",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "509",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = "3",
		EndofDungeon = "499",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "509",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = "4",
		EndofDungeon = "499",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "512",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = "5",
		EndofDungeon = "502",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "512",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = "6",
		EndofDungeon = "502",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "515",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = "7",
		EndofDungeon = "506",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "515",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = "8",
		EndofDungeon = "506",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "519",
		VaultUpgradeTrack = "Myth 1/4",
	},
	{
		Key = "9",
		EndofDungeon = "509",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "519",
		VaultUpgradeTrack = "Myth 1/4",
	},
	{
		Key = "10",
		EndofDungeon = "509",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "522",
		VaultUpgradeTrack = "Myth 2/4",
	},
}

AMT.SeasonalDungeons = {
	--Dragonflight
	{ abbr = "RLP", name = "Ruby Life Pools", spellID = 393256, mapID = 399 }, -- Ruby Life Pools
	{ abbr = "NO", name = "The Nokhud Offensive", spellID = 393262, mapID = 400 }, -- The Nokhud Offensive
	{ abbr = "AV", name = "The Azure Vault", spellID = 393279, mapID = 401 }, -- The Azure Vault
	{ abbr = "AA", name = "Algeth'ar Academy", spellID = 393273, mapID = 402 }, -- Algeth'ar Academy
	{ abbr = "ULD", name = "Uldaman: Legacy of Tyr", spellID = 393222, mapID = 403 }, -- Uldaman: Legacy of Tyr
	{ abbr = "NELT", name = "Neltharus", spellID = 393276, mapID = 404 }, -- Neltharus
	{ abbr = "HOI", name = "Halls of Infusion", spellID = 393283, mapID = 406 }, -- Halls of Infusion
	{ abbr = "BH", name = "Brackenhide Hollow", spellID = 393267, mapID = 405 }, -- Brackenhide Hollow
	{ abbr = "FALL", name = "Dawn of the Infinite: Galakrond's Fall", spellID = 424197, mapID = 463 }, -- Dawn of the Infinite: Galakrond's Fall
	{ abbr = "RISE", name = "Dawn of the Infinite: Murozond's Rise", spellID = 424197, mapID = 464 }, -- Dawn of the Infinite: Murozond's Rise

	--Shadowlands
	{ abbr = "MOTS", name = "Mist of Tirna Scithe", spellID = 354464, mapID = 375 }, -- Mist of Tirna Scithe
	{ abbr = "NW", name = "Necrotic Wake", spellID = 354462, mapID = 376 }, -- Necrotic Wake
	{ abbr = "DOS", name = "De Other Side", spellID = 354468, mapID = 377 }, -- De Other Side
	{ abbr = "HOA", name = "Halls of Atonement", spellID = 354465, mapID = 378 }, -- Halls of Atonement
	{ abbr = "PF", name = "Plaguefall", spellID = 354463, mapID = 379 }, -- Plaguefall
	{ abbr = "SD", name = "Sanguine Depths", spellID = 354469, mapID = 380 }, -- Sanguine Depths
	{ abbr = "SOA", name = "Spires of Ascension", spellID = 354466, mapID = 381 }, -- Spires of Ascension
	{ abbr = "TOP", name = "Theater of Pain", spellID = 354467, mapID = 382 }, -- Theater of Pain
	{ abbr = "WNDR", name = "Tazavesh, the Veiled Market: Streets of Wonder", spellID = 367416, mapID = 391 }, -- Tazavesh, the Veiled Market: Streets of Wonder
	{ abbr = "GMBT", name = "Tazavesh, the Veiled Market: So'leah's Gambit", spellID = 367416, mapID = 392 }, -- Tazavesh, the Veiled Market: So'leah's Gambit

	--Battle for Azeroth
	{ abbr = "AD", name = "Atal'Dazar", spellID = 424187, mapID = 244 }, -- Atal'Dazar
	{ abbr = "FH", name = "Freehold", spellID = 410071, mapID = 245 }, -- Freehold
	{ abbr = "WM", name = "Waycrest Manor", spellID = 424167, mapID = 248 }, -- Waycrest Manor
	{ abbr = "UNDR", name = "The Underrot", spellID = 410074, mapID = 251 }, -- The Underrot
	{ abbr = "JY", name = "Operation: Mechagon: Junkyard", spellID = 373274, mapID = 369 }, -- Operation: Mechagon: Junkyard
	{ abbr = "WS", name = "Operation: Mechagon: Workshop", spellID = 373274, mapID = 370 }, -- Operation: Mechagon: Workshop

	--Legion
	{ abbr = "DHT", name = "Darkheart Thicket", spellID = 424163, mapID = 198 }, -- Darkheart Thicket
	{ abbr = "BRH", name = "Black Rook Hold", spellID = 424153, mapID = 199 }, -- Black Rook Hold
	{ abbr = "HOV", name = "Halls of Valor", spellID = 393764, mapID = 200 }, -- Halls of Valor
	{ abbr = "NL", name = "Neltharion's Lair", spellID = 410078, mapID = 206 }, -- Neltharion's Lair
	{ abbr = "COS", name = "Court of Stars", spellID = 393766, mapID = 210 }, -- Court of Stars
	{ abbr = "LOWER", name = "Return to Karazhan: Lower", spellID = 373262, mapID = 277 }, -- Return to Karazhan: Lower
	{ abbr = "UPPER", name = "Return to Karazhan: Upper", spellID = 373262, mapID = 234 }, -- Return to Karazhan: Upper

	--Warlords of Draenor
	{ abbr = "SR", name = "Skyreach", spellID = 159898, mapID = 161 }, -- Skyreach
	{ abbr = "BSM", name = "Bloodmaul Slag Mines", spellID = 159895, mapID = 163 }, -- Bloodmaul Slag Mines
	{ abbr = "AUC", name = "Auchindoun", spellID = 159897, mapID = 164 }, -- Auchindoun
	{ abbr = "SBG", name = "Shadowmoon Burial Grounds", spellID = 159899, mapID = 165 }, -- Shadowmoon Burial Grounds
	{ abbr = "GD", name = "Grimrail Depot", spellID = 159900, mapID = 166 }, -- Grimrail Depot
	{ abbr = "UBRS", name = "Upper Blackrock Spire", spellID = 159902, mapID = 167 }, -- Upper Blackrock Spire
	{ abbr = "EB", name = "The Everbloom", spellID = 159901, mapID = 168 }, -- The Everbloom
	{ abbr = "ID", name = "Iron Docks", spellID = 159896, mapID = 169 }, -- Iron Docks

	--Mist of Pandaria
	{ abbr = "TJS", name = "Temple of the Jade Serpent", spellID = 131204, mapID = 2 }, -- Temple of the Jade Serpent

	--Cataclysm
	{ abbr = "VP", name = "The Vortex Pinnacle", spellID = 410080, mapID = 438 }, -- The Vortex Pinnacle
	{ abbr = "TOTT", name = "Throne of the Tides", spellID = 424142, mapID = 456 }, -- Throne of the Tides
}

AMT.RaidDifficulty_Levels = {
	{ id = 16, color = LEGENDARY_ORANGE_COLOR, order = 1, label = "M - ", name = "Mythic", abbr = "M" },
	{ id = 15, color = EPIC_PURPLE_COLOR, order = 2, label = "H - ", name = "Heroic", abbr = "H" },
	{ id = 14, color = RARE_BLUE_COLOR, order = 3, label = "N - ", name = "Normal", abbr = "N" },
	{ id = 17, color = UNCOMMON_GREEN_COLOR, order = 4, label = "LFR - ", name = "Looking For Raid", abbr = "LFR" },
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

AMT.AffixRotation = {
	{ rotation = { 9, 124, 6 } },
	{ rotation = { 10, 134, 7 } },
	{ rotation = { 9, 136, 123 } },
	{ rotation = { 10, 135, 6 } },
	{ rotation = { 9, 3, 8 } },
	{ rotation = { 10, 124, 11 } },
	{ rotation = { 9, 135, 7 } },
	{ rotation = { 10, 136, 8 } },
	{ rotation = { 9, 134, 11 } },
	{ rotation = { 10, 3, 123 } },
}
