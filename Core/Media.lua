local AMT = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

---@class AMTMedia
---@field LSM table
---@field FontObject fun(name: string): table?
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

---@param mediaType string
---@return string[]
function Media.List(mediaType)
	return LSM:List(mediaType)
end

---@param mediaType string
---@param name string
---@return string?
function Media.Fetch(mediaType, name)
	return LSM:Fetch(mediaType, name)
end

---@type table<string, table>
local fontObjects = {}

local fontObjectCount = 0

---@param name string
---@return table? fontObject
function Media.FontObject(name)
	local existing = fontObjects[name]

	if existing then
		return existing
	end

	local path = LSM:Fetch("font", name)

	if not path then
		return nil
	end

	fontObjectCount = fontObjectCount + 1

	local object = CreateFont("AdvancedMythicTrackerFont" .. fontObjectCount)

	object:CopyFontObject(GameFontHighlight)

	local _, size, flags = object:GetFont()

	object:SetFont(path, size or 12, flags or "")

	fontObjects[name] = object

	return object
end
