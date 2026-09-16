local AMT = select(2, ...)

-- Basically everything that might change with the seasons, like speciic abbreviations, affix levels, etc.
---@class AMTSeason
---@field teleportUnlockLevel integer the key level a dungeon must be timed at to learn its teleport
AMT.Season = {
	teleportUnlockLevel = 10,
}
