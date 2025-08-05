local addonName, AMT = ...

-- ============================
-- === Default Variables ===
-- ============================
AMT.DefaultValues = {
	DebugMode = false,
}
AMT.API = {} --Custom APIs used by this addon

--Debugging Prints
function AMT:PrintDebug(str)
	if not self.db then
		return
	end
	if self.db.DebugMode then
		print("|cff18a8ffAMT|r Debug: " .. str)
	end
end

-- ===============================
-- === Initialize AMT Database ===
-- ===============================

AMT.dbLoaded = false
function AMT:LoadDatabase()
	AMT_DB = AMT_DB or {}

	-- Check if DB needs to be reset for 2.0 rewrite
	local isOnlyDebugMode = true
	for key, value in pairs(AMT_DB) do
		if key ~= "DebugMode" then
			isOnlyDebugMode = false
			break
		end
	end

	-- Reset DB if needed for rewrite.
	if not isOnlyDebugMode then
		AMT_DB = { DebugMode = false }
		print("|cff18a8ffAMT|r Debug: Database has been reset for the 2.0 rewrite.")
	end

	self.db = AMT_DB

	for dbKey, value in pairs(self.DefaultValues) do
		if self.db[dbKey] == nil then
			self.db[dbKey] = value
		end
	end

	function self.GetDBValue(dbKeyPath)
		local keys = { strsplit(".", dbKeyPath) }
		local value = self.db

		for _, key in ipairs(keys) do
			value = value[key]
			if value == nil then
				return nil
			end
		end

		return value
	end

	function self.SetDBValue(dbKeyPath, newValue)
		local keys = { strsplit(".", dbKeyPath) }
		local dbRef = self.db

		for i = 1, #keys - 1 do
			local key = keys[i]
			dbRef = dbRef[key]
			if dbRef == nil then
				return false
			end
		end

		dbRef[keys[#keys]] = newValue
		return true
	end

	if ElvUI then
		self.E = unpack(ElvUI) -- ElvUI Functions
		self.S = ElvUI[1]:GetModule("Skins") -- ElvUI Skinning
	end

	if Details then
		self.OpenRaidLib = LibStub("LibOpenRaid-1.0", true) -- Call OpenRaidLib functions
	end

	DefaultValues = nil
	self.dbLoaded = true
end

local function OnAddonLoaded(self, event, name)
	if name == addonName then
		AMT:LoadDatabase()
		AMT:PrintDebug("Database Loaded")
		self:UnregisterEvent(event)
		AMT:PrintDebug("Unregistering " .. event)
		AMT:LoadAPITables()
	end
end

local ADDON_LOADED = CreateFrame("Frame")
ADDON_LOADED:RegisterEvent("ADDON_LOADED")

ADDON_LOADED:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		OnAddonLoaded(self, event, ...)
	end
end)

-- ============================
-- === Initialize Variables ===
-- ============================
AMT.AMT_Font = "Interface/AddOns/AdvancedMythicTracker/Media/Fonts/Expressway.TTF"
AMT.AntTrail_Font = "Interface/AddOns/AdvancedMythicTracker/Media/Fonts/AntTrail_Font.TTF"
AMT.Keystone_Icon = "Interface/AddOns/AdvancedMythicTracker/Media/Icons/Keystone_Hourglass"
AMT.Tab = "          "
AMT.WhiteText = "|cffffffff"
AMT.DisplayMode = 1
AMT.BackgroundClear = { 1, 1, 1, 0.0 } --Clear Background
AMT.BackgroundDark = { 0, 0, 0, 0.25 } --Slightly Dark Background
AMT.BackgroundHover = { 1, 1, 1, 0.25 } --Hovered white color Background
AMT.BackgroundClear_Table = { 0.5, 0.5, 0.5, 0.2 } --Clear Background for tables
AMT.Valorstones_Color = { 0.000, 0.800, 1.000, 1.000 }
AMT.Uncommon_Color = { 0.118, 0.900, 0.000, 1.000 }
AMT.Rare_Color = { 0.000, 0.569, 0.949, 1.000 }
AMT.Epic_Color = { 0.639, 0.208, 0.933, 1.000 }
AMT.Legendary_Color = { 1.000, 0.502, 0.000, 1.000 }
AMT.Info = {}
-- AMT.DungeonReq = 8 -- Number of Dungeon completions required for max rewards
-- AMT.RaidReq = 6 -- Number of Raid kills required for max rewards
-- AMT.WorldReq = 8 -- Number of Delves or World Activities required for max rewards

-- ==============================
-- === Shortcuts and Keybinds ===
-- ==============================
_G["BINDING_NAME_AMT"] = "Toggle AMT Window" --Keybind option name

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

--AMT Frame Tabs
AMT.AMTFrame_Tabs = {
	{
		name = "Tracker",
		tooltipText = "Mythic+ Tracker",
		-- activeAtlas = "QuestLog-tab-icon-quest",
		-- inactiveAtlas = "QuestLog-tab-icon-quest-inactive",
		activeAtlas = "keyflameon-32x32",
		inactiveAtlas = "keyflameoff-32x32",
		DisplayMode = 1,
	},
	{
		name = "Seasonal Info",
		tooltipText = "Seasonal Information",
		activeAtlas = "QuestLog-tab-icon-MapLegend",
		inactiveAtlas = "QuestLog-tab-icon-MapLegend-inactive",
		DisplayMode = 2,
	},
	{
		name = "Portals",
		tooltipText = "Dungeon Portals",
		activeAtlas = "delves-bountiful",
		inactiveAtlas = "delves-regular",
		DisplayMode = 3,
	},
}

--Rewards table for each key level
AMT.RewardsTable = {
	{
		Key = 2,
		EndofDungeon = "684",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "694",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 3,
		EndofDungeon = "684",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "694",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 4,
		EndofDungeon = "688",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "697",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 5,
		EndofDungeon = "691",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "697",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 6,
		EndofDungeon = "694",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "701",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = 7,
		EndofDungeon = "694",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "704",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 8,
		EndofDungeon = "697",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "704",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 9,
		EndofDungeon = "697",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "704",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 10,
		EndofDungeon = "701",
		DungeonUpgradeTrack = "Hero 3/6",
		GreatVault = "707",
		VaultUpgradeTrack = "Myth 1/6",
	},
}
--Dungeon info by expansion
AMT.SeasonalDungeons = {
	--The War Within
	{ abbr = "PSF", name = "Priory of the Sacred Flame", spellID = 445444, mapID = 499, instanceID = 2649, exp = 10 },
	{ abbr = "ROOK", name = "The Rookery", spellID = 445443, mapID = 500, instanceID = 2648, exp = 10 },
	{ abbr = "SV", name = "The Stonevault", spellID = 445269, mapID = 501, instanceID = 2652, exp = 10 },
	{ abbr = "COT", name = "City of Threads", spellID = 445416, mapID = 502, instanceID = 2669, exp = 10 },
	{ abbr = "ARAK", name = "Ara-Kara, City of Echoes", spellID = 445417, mapID = 503, instanceID = 2660, exp = 10 },
	{ abbr = "DFC", name = "Darkflame Cleft", spellID = 445441, mapID = 504, instanceID = 2651, exp = 10 },
	{ abbr = "DAWN", name = "The Dawnbreaker", spellID = 445414, mapID = 505, instanceID = 2662, exp = 10 },
	{ abbr = "BREW", name = "Cinderbrew Meadery", spellID = 445440, mapID = 506, instanceID = 2661, exp = 10 },
	{ abbr = "FLOOD", name = "Operation: Floodgate", spellID = 1216786, mapID = 525, instanceID = 2773, exp = 10 },
	{ abbr = "EDA", name = "Eco-Dome Al'dani", spellID = 1237215, mapID = 542, instanceID = 2830, exp = 10 },
	--Dragonflight
	{ abbr = "RLP", name = "Ruby Life Pools", spellID = 393256, mapID = 399, instanceID = 2521, exp = 9 },
	{ abbr = "NO", name = "The Nokhud Offensive", spellID = 393262, mapID = 400, instanceID = 2516, exp = 9 },
	{ abbr = "AV", name = "The Azure Vault", spellID = 393279, mapID = 401, instanceID = 2515, exp = 9 },
	{ abbr = "AA", name = "Algeth'ar Academy", spellID = 393273, mapID = 402, instanceID = 2526, exp = 9 },
	{ abbr = "ULD", name = "Uldaman: Legacy of Tyr", spellID = 393222, mapID = 403, instanceID = 2451, exp = 9 },
	{ abbr = "NELT", name = "Neltharus", spellID = 393276, mapID = 404, instanceID = 2519, exp = 9 },
	{ abbr = "HOI", name = "Halls of Infusion", spellID = 393283, mapID = 406, instanceID = 2527, exp = 9 },
	{ abbr = "BH", name = "Brackenhide Hollow", spellID = 393267, mapID = 405, instanceID = 2520, exp = 9 },
	{
		abbr = "FALL",
		name = "Dawn of the Infinite: Galakrond's Fall",
		spellID = 424197,
		mapID = 463,
		instanceID = 2579,
		megaDung = "DOTI",
		exp = 9,
	},
	{
		abbr = "RISE",
		name = "Dawn of the Infinite: Murozond's Rise",
		spellID = 424197,
		mapID = 464,
		instanceID = 2579,
		megaDung = "DOTI",
		exp = 9,
	},
	--Shadowlands
	{ abbr = "MISTS", name = "Mist of Tirna Scithe", spellID = 354464, mapID = 375, instanceID = 2290, exp = 8 },
	{ abbr = "NW", name = "Necrotic Wake", spellID = 354462, mapID = 376, instanceID = 2286, exp = 8 },
	{ abbr = "DOS", name = "De Other Side", spellID = 354468, mapID = 377, instanceID = 2291, exp = 8 },
	{ abbr = "HOA", name = "Halls of Atonement", spellID = 354465, mapID = 378, instanceID = 2287, exp = 8 },
	{ abbr = "PF", name = "Plaguefall", spellID = 354463, mapID = 379, instanceID = 2289, exp = 8 },
	{ abbr = "SD", name = "Sanguine Depths", spellID = 354469, mapID = 380, instanceID = 2284, exp = 8 },
	{ abbr = "SOA", name = "Spires of Ascension", spellID = 354466, mapID = 381, instanceID = 2285, exp = 8 },
	{ abbr = "TOP", name = "Theater of Pain", spellID = 354467, mapID = 382, instanceID = 2293, exp = 8 },
	{
		abbr = "WNDR",
		name = "Tazavesh, the Veiled Market: Streets of Wonder",
		spellID = 367416,
		mapID = 391,
		instanceID = 2441,
		megaDung = "TAZ",
		exp = 8,
	},
	{
		abbr = "GMBT",
		name = "Tazavesh, the Veiled Market: So'leah's Gambit",
		spellID = 367416,
		mapID = 392,
		instanceID = 2441,
		megaDung = "TAZ",
		exp = 8,
	},
	--Battle for Azeroth
	{ abbr = "AD", name = "Atal'Dazar", spellID = 424187, mapID = 244, instanceID = 1763, exp = 7 },
	{ abbr = "FH", name = "Freehold", spellID = 410071, mapID = 245, instanceID = 1754, exp = 7 },
	--{ abbr = "TD", name = "Tol Dagor", spellID = 445418, mapID = 246, instanceID=1771 },
	{ abbr = "ML", name = "The MOTHERLODE!!", spellID = { 467553, 467555 }, mapID = 247, instanceID = 1594, exp = 7 },
	-- { abbr = "ML", name = "The MOTHERLODE!!", spellID = 467555, mapID = 247, instanceID = 1594 },
	{ abbr = "WM", name = "Waycrest Manor", spellID = 424167, mapID = 248, instanceID = 1862, exp = 7 },
	--{ abbr = "KR", name = "Kings' Rest", spellID = 445418, mapID = 249, instanceID=1762 },
	--{ abbr = "TS", name = "Temple of Sethraliss", spellID = 445418, mapID = 250, instanceID=1877 },
	{ abbr = "UNDR", name = "The Underrot", spellID = 410074, mapID = 251, instanceID = 1841, exp = 7 },
	--{ abbr = "SS", name = "Shrine of the Storm", spellID = 445418, mapID = 252, instanceID=1864 },
	{
		abbr = "SIEGE",
		name = "Siege of Boralus",
		spellID = { 464256, 445418 },
		mapID = 353,
		exp = 7,
		instanceID = 1822,
	},
	{
		abbr = "JY",
		name = "Operation: Mechagon: Junkyard",
		spellID = 373274,
		mapID = 369,
		instanceID = 2097,
		megaDung = "MECHA",
		exp = 7,
	}, --Operation: Mechagon: Junkyard
	{
		abbr = "WORK",
		name = "Operation: Mechagon: Workshop",
		spellID = 373274,
		mapID = 370,
		instanceID = 2097,
		megaDung = "MECHA",
		exp = 7,
	},
	--Legion
	{ abbr = "DHT", name = "Darkheart Thicket", spellID = 424163, mapID = 198, instanceID = 1466, exp = 6 },
	{ abbr = "BRH", name = "Black Rook Hold", spellID = 424153, mapID = 199, instanceID = 1501, exp = 6 },
	{ abbr = "HOV", name = "Halls of Valor", spellID = 393764, mapID = 200, instanceID = 1477, exp = 6 },
	{ abbr = "NL", name = "Neltharion's Lair", spellID = 410078, mapID = 206, instanceID = 1458, exp = 6 },
	{ abbr = "COS", name = "Court of Stars", spellID = 393766, mapID = 210, instanceID = 1571, exp = 6 },
	{
		abbr = "LOWER",
		name = "Return to Karazhan: Lower",
		spellID = 373262,
		mapID = 277,
		instanceID = 1651,
		megaDung = "KARA",
		exp = 6,
	},
	{
		abbr = "UPPER",
		name = "Return to Karazhan: Upper",
		spellID = 373262,
		mapID = 234,
		instanceID = 1651,
		megaDung = "KARA",
		exp = 6,
	},
	--Warlords of Draenor
	{ abbr = "SR", name = "Skyreach", spellID = 159898, mapID = 161, instanceID = 1209, exp = 5 },
	{ abbr = "BSM", name = "Bloodmaul Slag Mines", spellID = 159895, mapID = 163, instanceID = 1175, exp = 5 },
	{ abbr = "AUC", name = "Auchindoun", spellID = 159897, mapID = 164, instanceID = 1182, exp = 5 },
	{ abbr = "SBG", name = "Shadowmoon Burial Grounds", spellID = 159899, mapID = 165, instanceID = 1176, exp = 5 },
	{ abbr = "GD", name = "Grimrail Depot", spellID = 159900, mapID = 166, instanceID = 1208, exp = 5 },
	{ abbr = "UBRS", name = "Upper Blackrock Spire", spellID = 159902, mapID = 167, instanceID = 1358, exp = 5 },
	{ abbr = "EB", name = "The Everbloom", spellID = 159901, mapID = 168, instanceID = 1279, exp = 5 },
	{ abbr = "ID", name = "Iron Docks", spellID = 159896, mapID = 169, instanceID = 1195, exp = 5 },
	--Mist of Pandaria
	{ abbr = "GOTSS", name = "Gate of the Setting Sun", spellID = 131225, mapID = 57, instanceID = 962, exp = 4 },
	{ abbr = "MSP", name = "Mogu'shan Palace", spellID = 131222, mapID = 60, instanceID = 994, exp = 4 },
	{ abbr = "SCHOLO", name = "Scholomance", spellID = 131232, mapID = 76, instanceID = 1007, exp = 4 },
	{ abbr = "SH", name = "Scarlet Halls", spellID = 131231, mapID = 77, instanceID = 1001, exp = 4 },
	{ abbr = "SM", name = "Scarlet Monastery", spellID = 131229, mapID = 78, instanceID = 1004, exp = 4 },
	{ abbr = "SNT", name = "Siege of Niuzao", spellID = 131228, mapID = 59, instanceID = 1011, exp = 4 },
	{ abbr = "SPM", name = "Shado-Pan Monastery", spellID = 131206, mapID = 58, instanceID = 959, exp = 4 },
	{ abbr = "SSB", name = "Stormstout Brewery", spellID = 131205, mapID = 56, instanceID = 961, exp = 4 },
	{ abbr = "TJS", name = "Temple of the Jade Serpent", spellID = 131204, mapID = 2, instanceID = 960, exp = 4 },
	--Cataclysm
	{ abbr = "VP", name = "The Vortex Pinnacle", spellID = 410080, mapID = 438, instanceID = 657, exp = 3 },
	{ abbr = "TOTT", name = "Throne of the Tides", spellID = 424142, mapID = 456, instanceID = 456, exp = 3 },
	{ abbr = "GB", name = "Grim Batol", spellID = 445424, mapID = 507, instanceID = 670, exp = 3 },
}

AMT.Raids = {
	--The War Within
	{
		abbr = "MO",
		name = "Manaforge Omega",
		journalInstanceID = 1302,
		instanceID = 2810,
		numEncounters = 8,
	},
	{
		abbr = "LoU",
		name = "Liberation of Undermine",
		journalInstanceID = 1296,
		instanceID = 2769, --2769 but ingame it shows as 2639
		numEncounters = 8,
	},
	{
		abbr = "NP",
		name = "Nerub'ar Palace",
		journalInstanceID = 1273,
		instanceID = 2657,
		numEncounters = 8,
	},

	--Dragonflight
	{
		abbr = "ATDH",
		name = "Amirdrassil, the Dream's Hope",
		journalInstanceID = 1207,
		instanceID = 2549,
		numEncounters = 9,
	},
	{
		abbr = "ATSC",
		name = "Aberrus, the Shadowed Crucible",
		journalInstanceID = 1208,
		instanceID = 2569,
		numEncounters = 9,
	},
	{
		abbr = "VOTI",
		name = "Vault of the Incarnates",
		journalInstanceID = 1200,
		instanceID = 2522,
		numEncounters = 8,
	},
}

--Raid Difficulties
AMT.RaidDifficulty_Levels = {
	{ id = 16, color = LEGENDARY_ORANGE_COLOR, order = 1, label = "M - ", name = "Mythic", abbr = "M" },
	{ id = 15, color = EPIC_PURPLE_COLOR, order = 2, label = "H - ", name = "Heroic", abbr = "H" },
	{ id = 14, color = RARE_BLUE_COLOR, order = 3, label = "N - ", name = "Normal", abbr = "N" },
	{ id = 17, color = UNCOMMON_GREEN_COLOR, order = 4, label = "LFR - ", name = "Looking For Raid", abbr = "LFR" },
}

--M+ Weekly Modifiers
AMT.Keystone_Modifiers = {
	{ mod = "Tyrannical", id = 9, values = { 30, 15, 0, 0 } },
	{ mod = "Fortified", id = 10, values = { 0, 0, 20, 30 } },
	{ mod = "Both", id = 99, values = { 30, 15, 20, 30 } },
}

--Affix Rotation for the Season
AMT.AffixRotation = {
	{ rotation = { 148, 9, 10, 147 } }, --Ascendant
	{ rotation = { 162, 10, 9, 147 } }, --Pulsar
	{ rotation = { 158, 9, 10, 147 } }, --Voidbound
	{ rotation = { 160, 10, 9, 147 } }, --Devour
	{ rotation = { 162, 9, 10, 147 } }, --Pulsar
	{ rotation = { 148, 10, 9, 147 } }, --Ascendant
	{ rotation = { 160, 9, 10, 147 } }, --Devour
	{ rotation = { 158, 10, 9, 147 } }, --Voidbound
}

AMT.Weekly_KillCount = {
	{ name = "Mythic", abbr = "M", kills = 0 },
	{ name = "Heroic", abbr = "H", kills = 0 },
	{ name = "Normal", abbr = "N", kills = 0 },
	{ name = "Looking For Raid", abbr = "LFR", kills = 0 },
}

AMT.Crests = {
	{
		name = "Gilded",
		color = AMT.Legendary_Color,
		currencyID = 3291,
		displayName = "Gilded Ethereal Crest",
		textureID = 5872057,
	},
	{
		name = "Runed",
		color = AMT.Epic_Color,
		currencyID = 3289,
		displayName = "Runed Ethereal Crest",
		textureID = 5872059,
	},
	{
		name = "Carved",
		color = AMT.Rare_Color,
		currencyID = 3286,
		displayName = "Carved Ethereal Crest",
		textureID = 5872055,
	},
	{
		name = "Weathered",
		color = AMT.Uncommon_Color,
		currencyID = 3284,
		displayName = "Weathered Ethereal Crest",
		textureID = 5872061,
	},
	{
		name = "Valorstones",
		color = AMT.Valorstones_Color,
		currencyID = 3008,
		displayName = "Valorstones",
		textureID = 5868902,
	},
}
AMT.SeasonalInfo = {}
-- AMT.SeasonalInfo.DungeonTable = {
-- 	headers = {
-- 		"Key",
-- 		"Loot",
-- 		"Vault",
-- 		"Drop",
-- 	},
-- 	rows = {
-- 		"H",
-- 		"M",
-- 		"1",
-- 		"2",
-- 		"3",
-- 		"4",
-- 		"5",
-- 		"6",
-- 		"7",
-- 		"8",
-- 		"9",
-- 		"10",
-- 		"11",
-- 		"12",
-- 	},
-- }
AMT.SeasonalInfo.DungeonTable = {
	headers = {
		[1] = {
			label = "Key",
			width = 40,
		},
		[2] = {
			label = "Loot",
			width = 40,
		},
		[3] = {
			label = "Vault",
			width = 40,
		},
		[4] = {
			label = "Drops",
			width = 80,
		},
	},
	content = {
		[1] = {
			{ text = "H", color = AMT.BackgroundClear_Table },
			{ text = "M", color = AMT.BackgroundClear_Table },
			{ text = "2", color = AMT.BackgroundClear_Table },
			{ text = "3", color = AMT.BackgroundClear_Table },
			{ text = "4", color = AMT.BackgroundClear_Table },
			{ text = "5", color = AMT.BackgroundClear_Table },
			{ text = "6", color = AMT.BackgroundClear_Table },
			{ text = "7", color = AMT.BackgroundClear_Table },
			{ text = "8", color = AMT.BackgroundClear_Table },
			{ text = "9", color = AMT.BackgroundClear_Table },
			{ text = "10", color = AMT.BackgroundClear_Table },
			{ text = "11", color = AMT.BackgroundClear_Table },
			{ text = "12", color = AMT.BackgroundClear_Table },
		},
		[2] = {
			{ text = 664, color = { 0.5, 0.5, 0.5, 1 } },
			{ text = 681, color = AMT.Rare_Color },
			{ text = 684, color = AMT.Rare_Color },
			{ text = 684, color = AMT.Rare_Color },
			{ text = 688, color = AMT.Rare_Color },
			{ text = 691, color = AMT.Rare_Color },
			{ text = 694, color = AMT.Epic_Color },
			{ text = 694, color = AMT.Epic_Color },
			{ text = 697, color = AMT.Epic_Color },
			{ text = 697, color = AMT.Epic_Color },
			{ text = 701, color = AMT.Epic_Color },
			{ text = 701, color = AMT.Epic_Color },
			{ text = 701, color = AMT.Epic_Color },
		},
		[3] = {
			{ text = 678, color = AMT.Uncommon_Color },
			{ text = 691, color = AMT.Rare_Color },
			{ text = 694, color = AMT.Epic_Color },
			{ text = 694, color = AMT.Epic_Color },
			{ text = 697, color = AMT.Epic_Color },
			{ text = 697, color = AMT.Epic_Color },
			{ text = 701, color = AMT.Epic_Color },
			{ text = 704, color = AMT.Epic_Color },
			{ text = 704, color = AMT.Epic_Color },
			{ text = 704, color = AMT.Epic_Color },
			{ text = 707, color = AMT.Legendary_Color },
			{ text = 707, color = AMT.Legendary_Color },
			{ text = 707, color = AMT.Legendary_Color },
		},
		[4] = {
			{ text = "Weathered", color = AMT.Uncommon_Color },
			{ text = "15 Carved", color = AMT.Rare_Color },
			{ text = "10 Runed", color = AMT.Epic_Color },
			{ text = "12 Runed", color = AMT.Epic_Color },
			{ text = "14 Runed", color = AMT.Epic_Color },
			{ text = "16 Runed", color = AMT.Epic_Color },
			{ text = "18 Runed", color = AMT.Epic_Color },
			{ text = "10 Gilded", color = AMT.Legendary_Color },
			{ text = "12 Gilded", color = AMT.Legendary_Color },
			{ text = "14 Gilded", color = AMT.Legendary_Color },
			{ text = "16 Gilded", color = AMT.Legendary_Color },
			{ text = "18 Gilded", color = AMT.Legendary_Color },
			{ text = "20 Gilded", color = AMT.Legendary_Color },
		},
	},
}

AMT.SeasonalInfo.RaidDropsTable = {
	headers = {
		[1] = {
			label = "Boss",
			width = 80,
		},
		[2] = {
			label = "LFR",
			width = 80,
		},
		[3] = {
			label = "Normal",
			width = 80,
		},
		[4] = {
			label = "Heroic",
			width = 80,
		},
		[5] = {
			label = "Mythic",
			width = 80,
		},
	},
	content = {
		[1] = {
			{ text = "1, 2, 3", color = AMT.BackgroundClear_Table },
			{ text = "4, 5, 6", color = AMT.BackgroundClear_Table },
			{ text = "7, 8", color = AMT.BackgroundClear_Table },
		},
		[2] = {
			{ text = "671", color = AMT.Uncommon_Color },
			{ text = "675", color = AMT.Uncommon_Color },
			{ text = "678", color = AMT.Uncommon_Color },
		},
		[3] = {
			{ text = "684", color = AMT.Rare_Color },
			{ text = "688", color = AMT.Rare_Color },
			{ text = "691", color = AMT.Rare_Color },
		},
		[4] = {
			{ text = "697", color = AMT.Epic_Color },
			{ text = "701", color = AMT.Epic_Color },
			{ text = "704", color = AMT.Epic_Color },
		},
		[5] = {
			{ text = "710", color = AMT.Legendary_Color },
			{ text = "714", color = AMT.Legendary_Color },
			{ text = "717", color = AMT.Legendary_Color },
		},
	},
}

AMT.SeasonalInfo.UpgradeTrackTable = {
	headers = {
		[1] = {
			label = "ilvl",
			width = 40,
		},
		[2] = {
			label = "Needs",
			width = 80,
		},
		[3] = {
			label = "Veteran",
			width = 80,
		},
		[4] = {
			label = "Champion",
			width = 80,
		},
		[5] = {
			label = "Hero",
			width = 80,
		},
		[6] = {
			label = "Mythic",
			width = 80,
		},
		[7] = {
			label = "Crafting",
			width = 80,
		},
	},
	content = {
		[1] = {
			{ text = "668", color = AMT.BackgroundClear_Table },
			{ text = "671", color = AMT.BackgroundClear_Table },
			{ text = "675", color = AMT.BackgroundClear_Table },
			{ text = "678", color = AMT.BackgroundClear_Table },
			{ text = "681", color = AMT.BackgroundClear_Table },
			{ text = "684", color = AMT.BackgroundClear_Table },
			{ text = "688", color = AMT.BackgroundClear_Table },
			{ text = "691", color = AMT.BackgroundClear_Table },
			{ text = "694", color = AMT.BackgroundClear_Table },
			{ text = "697", color = AMT.BackgroundClear_Table },
			{ text = "701", color = AMT.BackgroundClear_Table },
			{ text = "704", color = AMT.BackgroundClear_Table },
			{ text = "707", color = AMT.BackgroundClear_Table },
			{ text = "710", color = AMT.BackgroundClear_Table },
			{ text = "714", color = AMT.BackgroundClear_Table },
			{ text = "717", color = AMT.BackgroundClear_Table },
			{ text = "720", color = AMT.BackgroundClear_Table },
			{ text = "723", color = AMT.BackgroundClear_Table },
		},
		[2] = {
			{ text = "Weathered", color = AMT.Uncommon_Color },
			{ text = "Weathered", color = AMT.Uncommon_Color },
			{ text = "Weathered", color = AMT.Uncommon_Color },
			{ text = "Weathered", color = AMT.Uncommon_Color },
			{ text = "Carved", color = AMT.Rare_Color },
			{ text = "Carved", color = AMT.Rare_Color },
			{ text = "Carved", color = AMT.Rare_Color },
			{ text = "Carved", color = AMT.Rare_Color },
			{ text = "Runed", color = AMT.Epic_Color },
			{ text = "Runed", color = AMT.Epic_Color },
			{ text = "Runed", color = AMT.Epic_Color },
			{ text = "Runed", color = AMT.Epic_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
			{ text = "Gilded", color = AMT.Legendary_Color },
		},
		[3] = {
			{ text = "1/8", color = AMT.Uncommon_Color },
			{ text = "2/8", color = AMT.Uncommon_Color },
			{ text = "3/8", color = AMT.Uncommon_Color },
			{ text = "4/8", color = AMT.Uncommon_Color },
			{ text = "5/8", color = AMT.Uncommon_Color },
			{ text = "6/8", color = AMT.Uncommon_Color },
			{ text = "7/8", color = AMT.Uncommon_Color },
			{ text = "8/8", color = AMT.Uncommon_Color },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
		},
		[4] = {
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "1/8", color = AMT.Rare_Color },
			{ text = "2/8", color = AMT.Rare_Color },
			{ text = "3/8", color = AMT.Rare_Color },
			{ text = "4/8", color = AMT.Rare_Color },
			{ text = "5/8", color = AMT.Rare_Color },
			{ text = "6/8", color = AMT.Rare_Color },
			{ text = "7/8", color = AMT.Rare_Color },
			{ text = "8/8", color = AMT.Rare_Color },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
		},
		[5] = {
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "1/6", color = AMT.Epic_Color },
			{ text = "2/6", color = AMT.Epic_Color },
			{ text = "3/6", color = AMT.Epic_Color },
			{ text = "4/6", color = AMT.Epic_Color },
			{ text = "5/6", color = AMT.Epic_Color },
			{ text = "6/6", color = AMT.Epic_Color },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
		},
		[6] = {
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "1/6", color = AMT.Legendary_Color },
			{ text = "2/6", color = AMT.Legendary_Color },
			{ text = "3/6", color = AMT.Legendary_Color },
			{ text = "4/6", color = AMT.Legendary_Color },
			{ text = "5/6", color = AMT.Legendary_Color },
			{ text = "6/6", color = AMT.Legendary_Color },
		},
		[7] = {
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "", color = AMT.BackgroundClear_Table },
			{ text = "Q1", color = AMT.Epic_Color },
			{ text = "Q2", color = AMT.Epic_Color },
			{ text = "Q3", color = AMT.Epic_Color },
			{ text = "Q4", color = AMT.Epic_Color },
			{ text = "Q5", color = AMT.Epic_Color },
			{ text = "Q1", color = AMT.Legendary_Color },
			{ text = "Q2", color = AMT.Legendary_Color },
			{ text = "Q3", color = AMT.Legendary_Color },
			{ text = "Q4", color = AMT.Legendary_Color },
			{ text = "Q5", color = AMT.Legendary_Color },
			{ text = "", color = AMT.BackgroundClear_Table },
		},
	},
}
