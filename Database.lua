local addonName, AMT = ...

-- ============================
-- === Default Variables ===
-- ============================
AMT.DefaultValues = {
	ShowRelevantKeys = true, -- Shows relevant M+ keys in the group when ready check is initiated
	GroupKeysFrame_PositionX = nil,
	GroupKeysFrame_PositionY = nil,
	WorldMarkerCycler = true,
	WorldMarkerCycler_Order = { 5, 6, 3, 2, 7, 1, 4, 8 },
	Cycler_Star = true,
	Cycler_Circle = true,
	Cycler_Diamond = true,
	Cycler_Triangle = true,
	Cycler_Moon = true,
	Cycler_Square = true,
	Cycler_X = true,
	Cycler_Skull = true,
}
AMT.API = {} --Custom APIs used by this addon

do
	local tocVersion = select(4, GetBuildInfo())
	tocVersion = tonumber(tocVersion or 0)

	AMT.IsGame_10_2_0 = tocVersion >= 100200
	AMT.IsGame_11_0_0 = tocVersion >= 110000
	AMT.IsGame_11_0_2 = tocVersion >= 110002
end

-- ===============================
-- === Initialize AMT Database ===
-- ===============================
AMT.dbLoaded = false
function AMT:LoadDatabase()
	AMT_DB = AMT_DB or {}
	self.db = AMT_DB

	for dbKey, value in pairs(self.DefaultValues) do
		if self.db[dbKey] == nil then
			self.db[dbKey] = value
		end
	end

	local function GetDBValue(dbKey)
		return self.db[dbKey]
	end
	self.GetDBValue = GetDBValue

	local function SetDBValue(dbKey, value)
		self.db[dbKey] = value
	end
	self.SetDBValue = SetDBValue

	DefaultValues = nil
	self.dbLoaded = true
end

local ADDON_LOADED = CreateFrame("Frame")
ADDON_LOADED:RegisterEvent("ADDON_LOADED")
ADDON_LOADED:RegisterEvent("PLAYER_ENTERING_WORLD")

ADDON_LOADED:SetScript("OnEvent", function(self, event, ...)
	local name = ...
	if name == addonName then
		self:UnregisterEvent(event)
		AMT:LoadDatabase()
		AMT:PrintDebug("Unregistering " .. event)
	end
	if event == "PLAYER_ENTERING_WORLD" then
		if RaiderIO then
			AMT.RaiderIOEnabled = true
			AMT:PrintDebug("RaiderIO found")
		end
		self:UnregisterEvent(event)
		AMT:PrintDebug("Unregistering " .. event)
	end
end)

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

AMT.Vault_BoxSize = 14
AMT.Vault_RaidReq = 6 -- Number of Raid kills required for max rewards
AMT.Vault_DungeonReq = 8 -- Number of Dungeon completions required for max rewards
AMT.Vault_WorldReq = 8 -- Number of Delves or World Activities required for max rewards
AMT.Mplus_VaultUnlocks = {} -- Breakthrough Numbers for each Vault Reward for M+
AMT.Raid_VaultUnlocks = {} -- Breakthrough Numbers for each Vault Reward for Raid
AMT.World_VaultUnlocks = {} -- Breakthrough Numbers for each Vault Reward for World
AMT.World_VaultTracker = 0
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
_G["BINDING_NAME_CLICK WorldMarker_Placer:LeftButton"] = "World Marker Cycler" -- Keybind for Cycling through World Markers
_G["BINDING_NAME_CLICK WorldMarker_Remover:LeftButton"] = "World Marker Erase" -- Keybind for Cycling through World Markers

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
		text = "Delves",
		frameName = "DelvesDashboardFrame",
		isVisible = true,
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
		EndofDungeon = "597",
		DungeonUpgradeTrack = "Champion 1/8",
		GreatVault = "606",
		VaultUpgradeTrack = "Champion 4/8",
	},
	{
		Key = 3,
		EndofDungeon = "597",
		DungeonUpgradeTrack = "Champion 1/8",
		GreatVault = "610",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 4,
		EndofDungeon = "600",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "610",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 5,
		EndofDungeon = "603",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "613",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 6,
		EndofDungeon = "606",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "613",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 7,
		EndofDungeon = "610",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "616",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = 8,
		EndofDungeon = "610",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "619",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 9,
		EndofDungeon = "613",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "619",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 10,
		EndofDungeon = "613",
		DungeonUpgradeTrack = "Hero 4/6",
		GreatVault = "623",
		VaultUpgradeTrack = "Myth 1/6",
	},
}
-- Dungeon info by expansion
AMT.SeasonalDungeons = {
	--The War Within
	{ abbr = "SF", name = "Priory of the Sacred Flame", spellID = 445444, mapID = 499 }, -- Priory of the Sacred Flame
	{ abbr = "ROOK", name = "The Rookery", spellID = 445443, mapID = 500 }, -- The Rookery
	{ abbr = "SV", name = "The Stonevault", spellID = 445269, mapID = 501 }, -- The Stonevault
	{ abbr = "COT", name = "City of Threads", spellID = 445416, mapID = 502 }, -- City of Threads
	{ abbr = "ARAK", name = "Ara-Kara, City of Echoes", spellID = 445417, mapID = 503 }, -- Ara-Kara, City of Echoes
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
	{ abbr = "MISTS", name = "Mist of Tirna Scithe", spellID = 354464, mapID = 375 }, -- Mist of Tirna Scithe
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
	{
		abbr = "NP",
		name = "Nerub'ar Palace",
		journalInstanceID = 1273,
		instanceID = 2657,
		numEncounters = 8,
	},

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
	{ mod = "Both", id = 99, values = { 30, 15, 20, 30 } },
}

-- Affix Rotation for the Season
AMT.AffixRotation = {
	{ rotation = { 148, 9, 152, 10, 147 } },
	{ rotation = { 148, 10, 152, 9, 147 } },
	{ rotation = { 158, 9, 152, 10, 147 } },
	{ rotation = { 158, 10, 152, 9, 147 } },
	{ rotation = { 159, 9, 152, 10, 147 } },
	{ rotation = { 159, 10, 152, 9, 147 } },
	{ rotation = { 160, 9, 152, 10, 147 } },
	{ rotation = { 160, 10, 152, 9, 147 } },
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
		name = "Weathered",
		color = AMT.Uncommon_Color,
		currencyID = 2914,
		displayName = "Weathered Harbinger Crest",
		textureID = 5872034,
	},
	{
		name = "Carved",
		color = AMT.Rare_Color,
		currencyID = 2915,
		displayName = "Carved Harbinger Crest",
		textureID = 5872028,
	},
	{
		name = "Runed",
		color = AMT.Epic_Color,
		currencyID = 2916,
		displayName = "Runed Harbinger Crest",
		textureID = 5872032,
	},
	{
		name = "Gilded",
		color = AMT.Legendary_Color,
		currencyID = 2917,
		displayName = "Gilded Harbinger Crest",
		textureID = 5872030,
	},
}

AMT.WorldMarkers = {
	{ id = 1, icon = "Star", textAtlas = 8, wmID = 5 },
	{ id = 2, icon = "Circle", textAtlas = 7, wmID = 6 },
	{ id = 3, icon = "Diamond", textAtlas = 6, wmID = 3 },
	{ id = 4, icon = "Triangle", textAtlas = 5, wmID = 2 },
	{ id = 5, icon = "Moon", textAtlas = 4, wmID = 7 },
	{ id = 6, icon = "Square", textAtlas = 3, wmID = 1 },
	{ id = 7, icon = "X", textAtlas = 2, wmID = 4 },
	{ id = 8, icon = "Skull", textAtlas = 1, wmID = 8 },
}
