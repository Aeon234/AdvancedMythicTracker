local AMT = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

---@class AMTMedia
---@field LSM table
local Media = {}
AMT.Media = Media

Media.LSM = LSM

---@param name string
---@return string?
function Media.Statusbar(name)
	return LSM:Fetch("statusbar", name)
end

---@param name string
---@return string?
function Media.Font(name)
	return LSM:Fetch("font", name)
end

---@param name string
---@return string?
function Media.Border(name)
	return LSM:Fetch("border", name)
end

---@param name string
---@return string?
function Media.Background(name)
	return LSM:Fetch("background", name)
end

--- Sorted name list for the options dropdowns (Phase 9).
---@param mediaType string
---@return string[]
function Media.List(mediaType)
	return LSM:List(mediaType)
end
