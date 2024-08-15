local addonName, AMT = ...

-- ============================
-- === Initialize Variables ===
-- ============================
AMT.AMT_CreationComplete = false
AMT.ElvUIEnabled = false
AMT.DetailsEnabled = false
AMT.RaiderIOEnabled = false
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

if RaiderIO then
	AMT.RaiderIOEnabled = true
end

AMT.Vault_BoxSize = 14
AMT.Vault_RaidReq = 6 -- Number of Raid kills required for max rewards
AMT.Vault_DungeonReq = 8 -- Number of Dungeon completions required for max rewards
AMT.Vault_WorldReq = 12 -- Number of Delves or World Activities required for max rewards
AMT.Mplus_VaultUnlocks = {} -- Breakthrough Numbers for each Vault Reward for M+
AMT.Raid_VaultUnlocks = {} -- Breakthrough Numbers for each Vault Reward for Raid
AMT.GetCurrentAffixesTable = C_MythicPlus.GetCurrentAffixes() or {} --Current Affix Raw Table
AMT.CurrentWeek_AffixTable = {} --Cleaned Affix Table
AMT.NextWeek_AffixTable = {} --Next Week's Affix Table
AMT.RaidVault_Bosses = C_WeeklyRewards.GetActivityEncounterInfo(3, 1)
AMT.Player_Mplus_Summary = C_PlayerInfo.GetPlayerMythicPlusRatingSummary("player") --Raw Player M+ Summary
AMT.Player_Mplus_ScoreColor = nil --M+ Score Color
AMT.RunHistory = {} --M+ runs history
AMT.KeysDone = {} --Cleaned M+ runs history
AMT.Current_SeasonalDung_Info = {} --Current M+ dungeons info
AMT.BestKeys_per_Dungeon = {} --Highest keys done per M+ dungeon
AMT.GroupKeystone_Info = {}
AMT.SeasonalRaids = {}
AMT.Raid_Progress = {}
AMT.AMT_Font = "Interface/AddOns/AdvancedMythicTracker/Media/Fonts/Expressway.TTF"
AMT.AntTrail_Font = "Interface/AddOns/AdvancedMythicTracker/Media/Fonts/AntTrail_Font.TTF"
AMT.Clean_StatusBar = "Interface/AddOns/AdvancedMythicTracker/Media/StatusBar/AMT_Clean"
AMT.Keystone_Icon = "Interface/AddOns/AdvancedMythicTracker/Media/Icons/Keystone_Hourglass"
AMT.Tab = "          "
AMT.Whitetext = "|cffffffff"
AMT.BackgroundClear = { 1, 1, 1, 0.0 } --Clear Background
AMT.BackgroundDark = { 0, 0, 0, 0.25 } --Slightly Dark Background
AMT.BackgroundHover = { 1, 1, 1, 0.25 } --Hovered white color Background
AMT.Uncommon_Color = { 0.118, 0.900, 0.000, 1.000 }
AMT.Rare_Color = { 0.000, 0.569, 0.949, 1.000 }
AMT.Epic_Color = { 0.639, 0.208, 0.933, 1.000 }
AMT.Legendary_Color = { 1.000, 0.502, 0.000, 1.000 }

-- ==============================
-- === Shortcuts and Keybinds ===
-- ==============================
_G["BINDING_NAME_AMT"] = "Toggle AMT Window" -- Keybind option name

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
		text = "Advanced Mythic Tracker",
		frameName = "AMT_Window",
		isVisible = false,
	},
}

-- Rewards table for each key level
AMT.RewardsTable = {
	{
		Key = 2,
		EndofDungeon = "496",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "509",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 3,
		EndofDungeon = "499",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "509",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 4,
		EndofDungeon = "499",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "512",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = 5,
		EndofDungeon = "502",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "512",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = 6,
		EndofDungeon = "502",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "515",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 7,
		EndofDungeon = "506",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "515",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 8,
		EndofDungeon = "506",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "519",
		VaultUpgradeTrack = "Myth 1/4",
	},
	{
		Key = 9,
		EndofDungeon = "509",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "519",
		VaultUpgradeTrack = "Myth 1/4",
	},
	{
		Key = 10,
		EndofDungeon = "509",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "522",
		VaultUpgradeTrack = "Myth 2/4",
	},
}
-- Dungeon info by expansion
AMT.SeasonalDungeons = {
	--The War Within
	{ abbr = "SF", name = "Priory of the Sacred Flame", spellID = 445444, mapID = 499 }, -- Priory of the Sacred Flame
	{ abbr = "ROOK", name = "The Rookery", spellID = 445443, mapID = 500 }, -- The Rookery
	{ abbr = "SV", name = "The Stonevault", spellID = 445269, mapID = 501 }, -- The Stonevault
	{ abbr = "CoT", name = "City of Threads", spellID = 445416, mapID = 502 }, -- City of Threads
	{ abbr = "CoE", name = "Ara-Kara, City of Echoes", spellID = 445417, mapID = 503 }, -- Ara-Kara, City of Echoes
	{ abbr = "DC", name = "Darkflame Cleft", spellID = 445441, mapID = 504 }, -- Darkflame Cleft
	{ abbr = "DAWN", name = "The Dawnbreaker", spellID = 445414, mapID = 505 }, -- The Dawnbreaker
	{ abbr = "CM", name = "Cinderbrew Meadery", spellID = 445440, mapID = 506 }, -- Cinderbrew Meadery
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
	-- { abbr = "SIEGE", name = "Tol Dagor", spellID = 445418, mapID = 246 }, -- Tol Dagor
	-- { abbr = "SIEGE", name = "The MOTHERLODE!!", spellID = 445418, mapID = 247 }, -- The MOTHERLODE!!
	{ abbr = "WM", name = "Waycrest Manor", spellID = 424167, mapID = 248 }, -- Waycrest Manor
	-- { abbr = "SIEGE", name = "Kings' Rest", spellID = 445418, mapID = 249 }, -- Kings' Rest
	-- { abbr = "SIEGE", name = "Siege of Boralus", spellID = 445418, mapID = 250 }, -- Temple of Sethraliss
	{ abbr = "UNDR", name = "The Underrot", spellID = 410074, mapID = 251 }, -- The Underrot
	-- { abbr = "SIEGE", name = "Shrine of the Storm", spellID = 445418, mapID = 252 }, -- Shrine of the Storm
	{ abbr = "SIEGE", name = "Siege of Boralus", spellID = 445418, mapID = 353 }, -- Siege of Boralus
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
	{ abbr = "GB", name = "Grim Batol", spellID = 445424, mapID = 507 }, -- Grim Batol
}

AMT.Raids = {
	--The War Within

	--Dragonflight
	{
		abbr = "VOTI",
		name = "Vault of the Incarnates",
		journalInstanceID = 1200,
		instanceID = 2522,
		numEncounters = 8,
	},
	{
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
		journalInstanceID = 1208,
		instanceID = 2569,
		numEncounters = 9,
	},
	{
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
		journalInstanceID = 1207,
		instanceID = 2549,
		numEncounters = 9,
	},
}

--Raid Difficulties
AMT.RaidDifficulty_Levels = {
	{ id = 16, color = LEGENDARY_ORANGE_COLOR, order = 1, label = "M - ", name = "Mythic", abbr = "M" },
	{ id = 15, color = EPIC_PURPLE_COLOR, order = 2, label = "H - ", name = "Heroic", abbr = "H" },
	{ id = 14, color = RARE_BLUE_COLOR, order = 3, label = "N - ", name = "Normal", abbr = "N" },
	{ id = 17, color = UNCOMMON_GREEN_COLOR, order = 4, label = "LFR - ", name = "Looking For Raid", abbr = "LFR" },
}

-- M+ Weekly Modifiers
AMT.Keystone_Modifiers = {
	{ mod = "Tyrannical", id = 9, values = { 30, 15, 0, 0 } },
	{ mod = "Fortified", id = 10, values = { 0, 0, 20, 30 } },
}

-- Affix Rotation for the Season
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

AMT.Weekly_KillCount = {
	{ name = "Mythic", abbr = "M", kills = 0 },
	{ name = "Heroic", abbr = "H", kills = 0 },
	{ name = "Normal", abbr = "N", kills = 0 },
	{ name = "Looking For Raid", abbr = "LFR", kills = 0 },
}
-- While the names for the time being are kept as DF names, the ids are for War Within.
-- Might want to update it to TWW names if community doesn't just default to the original names
AMT.CrestNames = {
	{
		name = "Whelpling",
		color = AMT.Uncommon_Color,
		currencyID = 2806,
		displayName = "Whelpling's Awakened Crest",
		textureID = 5646099,
	}, --Weathered Harbinger Crest
	{
		name = "Drake",
		color = AMT.Rare_Color,
		currencyID = 2807,
		displayName = "Drake's Awakened Crest",
		textureID = 5646097,
	}, --Carved Harbinger Crest
	{
		name = "Wyrm",
		color = AMT.Epic_Color,
		currencyID = 2809,
		displayName = "Wyrm's Awakened Crest",
		textureID = 5646101,
	}, --Runed Harbinger Crest
	{
		name = "Aspect",
		color = AMT.Legendary_Color,
		currencyID = 2812,
		displayName = "Aspect's Awakened Crest",
		textureID = 5646095,
	}, --Gilded Harbinger Crest
}
