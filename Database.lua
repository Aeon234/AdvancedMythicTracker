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
}

--Rewards table for each key level
AMT.RewardsTable = {
	{
		Key = 2,
		EndofDungeon = "639",
		DungeonUpgradeTrack = "Champion 2/8",
		GreatVault = "649",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 3,
		EndofDungeon = "639",
		DungeonUpgradeTrack = "Champion 1/8",
		GreatVault = "649",
		VaultUpgradeTrack = "Hero 1/6",
	},
	{
		Key = 4,
		EndofDungeon = "642",
		DungeonUpgradeTrack = "Champion 3/8",
		GreatVault = "652",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 5,
		EndofDungeon = "645",
		DungeonUpgradeTrack = "Champion 4/8",
		GreatVault = "652",
		VaultUpgradeTrack = "Hero 2/6",
	},
	{
		Key = 6,
		EndofDungeon = "649",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "655",
		VaultUpgradeTrack = "Hero 3/6",
	},
	{
		Key = 7,
		EndofDungeon = "649",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "658",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 8,
		EndofDungeon = "652",
		DungeonUpgradeTrack = "Hero 1/6",
		GreatVault = "658",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 9,
		EndofDungeon = "652",
		DungeonUpgradeTrack = "Hero 2/6",
		GreatVault = "658",
		VaultUpgradeTrack = "Hero 4/6",
	},
	{
		Key = 10,
		EndofDungeon = "655",
		DungeonUpgradeTrack = "Hero 4/6",
		GreatVault = "662",
		VaultUpgradeTrack = "Myth 1/6",
	},
}
--Dungeon info by expansion
AMT.SeasonalDungeons = {
	--The War Within
	{ abbr = "PSF", name = "Priory of the Sacred Flame", spellID = 445444, mapID = 499, instanceID = 2649 }, --Priory of the Sacred Flame
	{ abbr = "ROOK", name = "The Rookery", spellID = 445443, mapID = 500, instanceID = 2648 }, --The Rookery
	{ abbr = "SV", name = "The Stonevault", spellID = 445269, mapID = 501, instanceID = 2652 }, --The Stonevault
	{ abbr = "COT", name = "City of Threads", spellID = 445416, mapID = 502, instanceID = 2669 }, --City of Threads
	{ abbr = "ARAK", name = "Ara-Kara, City of Echoes", spellID = 445417, mapID = 503, instanceID = 2660 }, --Ara-Kara, City of Echoes
	{ abbr = "DFC", name = "Darkflame Cleft", spellID = 445441, mapID = 504, instanceID = 2651 }, --Darkflame Cleft
	{ abbr = "DAWN", name = "The Dawnbreaker", spellID = 445414, mapID = 505, instanceID = 2662 }, --The Dawnbreaker
	{ abbr = "BREW", name = "Cinderbrew Meadery", spellID = 445440, mapID = 506, instanceID = 2661 }, --Cinderbrew Meadery
	{ abbr = "FLOOD", name = "Operation: Floodgate", spellID = 1216786, mapID = 525, instanceID = 2773 }, --Operation: Floodgate
	--Dragonflight
	{ abbr = "RLP", name = "Ruby Life Pools", spellID = 393256, mapID = 399, instanceID = 2521 }, --Ruby Life Pools
	{ abbr = "NO", name = "The Nokhud Offensive", spellID = 393262, mapID = 400, instanceID = 2516 }, --The Nokhud Offensive
	{ abbr = "AV", name = "The Azure Vault", spellID = 393279, mapID = 401, instanceID = 2515 }, --The Azure Vault
	{ abbr = "AA", name = "Algeth'ar Academy", spellID = 393273, mapID = 402, instanceID = 2526 }, --Algeth'ar Academy
	{ abbr = "ULD", name = "Uldaman: Legacy of Tyr", spellID = 393222, mapID = 403, instanceID = 2451 }, --Uldaman: Legacy of Tyr
	{ abbr = "NELT", name = "Neltharus", spellID = 393276, mapID = 404, instanceID = 2519 }, --Neltharus
	{ abbr = "HOI", name = "Halls of Infusion", spellID = 393283, mapID = 406, instanceID = 2527 }, --Halls of Infusion
	{ abbr = "BH", name = "Brackenhide Hollow", spellID = 393267, mapID = 405, instanceID = 2520 }, --Brackenhide Hollow
	{
		abbr = "FALL",
		name = "Dawn of the Infinite: Galakrond's Fall",
		spellID = 424197,
		mapID = 463,
		instanceID = 2579,
	}, --Dawn of the Infinite: Galakrond's Fall
	{ abbr = "RISE", name = "Dawn of the Infinite: Murozond's Rise", spellID = 424197, mapID = 464, instanceID = 2579 }, --Dawn of the Infinite: Murozond's Rise
	--Shadowlands
	{ abbr = "MISTS", name = "Mist of Tirna Scithe", spellID = 354464, mapID = 375, instanceID = 2290 }, --Mist of Tirna Scithe
	{ abbr = "NW", name = "Necrotic Wake", spellID = 354462, mapID = 376, instanceID = 2286 }, --Necrotic Wake
	{ abbr = "DOS", name = "De Other Side", spellID = 354468, mapID = 377, instanceID = 2291 }, --De Other Side
	{ abbr = "HOA", name = "Halls of Atonement", spellID = 354465, mapID = 378, instanceID = 2287 }, --Halls of Atonement
	{ abbr = "PF", name = "Plaguefall", spellID = 354463, mapID = 379, instanceID = 2289 }, --Plaguefall
	{ abbr = "SD", name = "Sanguine Depths", spellID = 354469, mapID = 380, instanceID = 2284 }, --Sanguine Depths
	{ abbr = "SOA", name = "Spires of Ascension", spellID = 354466, mapID = 381, instanceID = 2285 }, --Spires of Ascension
	{ abbr = "TOP", name = "Theater of Pain", spellID = 354467, mapID = 382, instanceID = 2293 }, --Theater of Pain
	{
		abbr = "WNDR",
		name = "Tazavesh, the Veiled Market: Streets of Wonder",
		spellID = 367416,
		mapID = 391,
		instanceID = 2441,
	}, --Tazavesh, the Veiled Market: Streets of Wonder
	{
		abbr = "GMBT",
		name = "Tazavesh, the Veiled Market: So'leah's Gambit",
		spellID = 367416,
		mapID = 392,
		instanceID = 2441,
	}, --Tazavesh, the Veiled Market: So'leah's Gambit
	--Battle for Azeroth
	{ abbr = "AD", name = "Atal'Dazar", spellID = 424187, mapID = 244, instanceID = 1763 }, --Atal'Dazar
	{ abbr = "FH", name = "Freehold", spellID = 410071, mapID = 245, instanceID = 1754 }, --Freehold
	--{ abbr = "TD", name = "Tol Dagor", spellID = 445418, mapID = 246, instanceID=1771 }, --Tol Dagor
	{ abbr = "ML", name = "The MOTHERLODE!!", spellID = { 467553, 467555 }, mapID = 247, instanceID = 1594 }, --The MOTHERLODE!!
	-- { abbr = "ML", name = "The MOTHERLODE!!", spellID = 467555, mapID = 247, instanceID = 1594 }, --The MOTHERLODE!!
	{ abbr = "WM", name = "Waycrest Manor", spellID = 424167, mapID = 248, instanceID = 1862 }, --Waycrest Manor
	--{ abbr = "KR", name = "Kings' Rest", spellID = 445418, mapID = 249, instanceID=1762 }, --Kings' Rest
	--{ abbr = "TS", name = "Temple of Sethraliss", spellID = 445418, mapID = 250, instanceID=1877 }, --Temple of Sethraliss
	{ abbr = "UNDR", name = "The Underrot", spellID = 410074, mapID = 251, instanceID = 1841 }, --The Underrot
	--{ abbr = "SS", name = "Shrine of the Storm", spellID = 445418, mapID = 252, instanceID=1864 }, --Shrine of the Storm
	{ abbr = "SIEGE", name = "Siege of Boralus", spellID = { 464256, 445418 }, mapID = 353, instanceID = 1822 }, --Siege of Boralus Horde
	-- { abbr = "SIEGE", name = "Siege of Boralus", spellID = 445418, mapID = 353, instanceID = 1822 }, --Siege of Boralus Alliance
	{ abbr = "JY", name = "Operation: Mechagon: Junkyard", spellID = 373274, mapID = 369, instanceID = 2097 }, --Operation: Mechagon: Junkyard
	{ abbr = "WORK", name = "Operation: Mechagon: Workshop", spellID = 373274, mapID = 370, instanceID = 2097 }, --Operation: Mechagon: Workshop
	--Legion
	{ abbr = "DHT", name = "Darkheart Thicket", spellID = 424163, mapID = 198, instanceID = 1466 }, --Darkheart Thicket
	{ abbr = "BRH", name = "Black Rook Hold", spellID = 424153, mapID = 199, instanceID = 1501 }, --Black Rook Hold
	{ abbr = "HOV", name = "Halls of Valor", spellID = 393764, mapID = 200, instanceID = 1477 }, --Halls of Valor
	{ abbr = "NL", name = "Neltharion's Lair", spellID = 410078, mapID = 206, instanceID = 1458 }, --Neltharion's Lair
	{ abbr = "COS", name = "Court of Stars", spellID = 393766, mapID = 210, instanceID = 1571 }, --Court of Stars
	{ abbr = "LOWER", name = "Return to Karazhan: Lower", spellID = 373262, mapID = 277, instanceID = 1651 }, --Return to Karazhan: Lower
	{ abbr = "UPPER", name = "Return to Karazhan: Upper", spellID = 373262, mapID = 234, instanceID = 1651 }, --Return to Karazhan: Upper
	--Warlords of Draenor
	{ abbr = "SR", name = "Skyreach", spellID = 159898, mapID = 161, instanceID = 1209 }, --Skyreach
	{ abbr = "BSM", name = "Bloodmaul Slag Mines", spellID = 159895, mapID = 163, instanceID = 1175 }, --Bloodmaul Slag Mines
	{ abbr = "AUC", name = "Auchindoun", spellID = 159897, mapID = 164, instanceID = 1182 }, --Auchindoun
	{ abbr = "SBG", name = "Shadowmoon Burial Grounds", spellID = 159899, mapID = 165, instanceID = 1176 }, --Shadowmoon Burial Grounds
	{ abbr = "GD", name = "Grimrail Depot", spellID = 159900, mapID = 166, instanceID = 1208 }, --Grimrail Depot
	{ abbr = "UBRS", name = "Upper Blackrock Spire", spellID = 159902, mapID = 167, instanceID = 1358 }, --Upper Blackrock Spire
	{ abbr = "EB", name = "The Everbloom", spellID = 159901, mapID = 168, instanceID = 1279 }, --The Everbloom
	{ abbr = "ID", name = "Iron Docks", spellID = 159896, mapID = 169, instanceID = 1195 }, --Iron Docks
	--Mist of Pandaria
	{ abbr = "TJS", name = "Temple of the Jade Serpent", spellID = 131204, mapID = 2, instanceID = 960 }, --Temple of the Jade Serpent
	--Cataclysm
	{ abbr = "VP", name = "The Vortex Pinnacle", spellID = 410080, mapID = 438, instanceID = 657 }, --The Vortex Pinnacle
	{ abbr = "TOTT", name = "Throne of the Tides", spellID = 424142, mapID = 456, instanceID = 456 }, --Throne of the Tides
	{ abbr = "GB", name = "Grim Batol", spellID = 445424, mapID = 507, instanceID = 670 }, --Grim Batol
}

AMT.Raids = {
	--The War Within
	{
		abbr = "LoU",
		name = "Liberation of Undermine",
		journalInstanceID = 1296,
		instanceID = 2769, --2769 but inggame it shows as 2639
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
		currencyID = 3110,
		displayName = "Gilded Undermine Crest",
		textureID = 5872049,
	},
	{
		name = "Runed",
		color = AMT.Epic_Color,
		currencyID = 3109,
		displayName = "Runed Undermine Crest",
		textureID = 5872051,
	},
	{
		name = "Carved",
		color = AMT.Rare_Color,
		currencyID = 3108,
		displayName = "Carved Undermine Crest",
		textureID = 5872047,
	},
	{
		name = "Weathered",
		color = AMT.Uncommon_Color,
		currencyID = 3107,
		displayName = "Weathered Undermine Crest",
		textureID = 5872053,
	},
	{
		name = "Valorstones",
		color = AMT.Valorstones_Color,
		currencyID = 3008,
		displayName = "Valorstones",
		textureID = 5868902,
	},
}
