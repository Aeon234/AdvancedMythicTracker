local AMT = select(2, ...)

-- Things that change or may change with the seasons.
---@class AMTSeason
---@field teleportUnlockLevel integer the key level a dungeon must be timed at to learn its teleport
---@field affixLevels integer[] the key level each GetCurrentAffixes() position activates at
AMT.Season = {
	teleportUnlockLevel = 10,
	affixLevels = { 2, 5, 7, 10, 12 },
}
