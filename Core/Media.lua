local AMT = select(2, ...)

local LSM = LibStub("LibSharedMedia-3.0")

---@class AMTMedia
---@field LSM table
---@field FontObject fun(name: string): table?
local Media = {}
AMT.Media = Media

Media.LSM = LSM

local STATUSBAR_ATLAS = "statusbar_atlas"
local ATLAS_PREFIX = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-"

---@param key string
---@return string
local function PrettyPowerName(key)
	local words = {}

	for word in key:gmatch("[^_]+") do
		words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2):lower()
	end

	return table.concat(words, " ")
end

if PowerBarColor then
	for power, data in pairs(PowerBarColor) do
		local name, path

		if type(power) == "string" and data.atlas then
			name = PrettyPowerName(power)
			path = data.atlas
		elseif data.atlasElementName then
			name = data.atlasElementName
			path = ATLAS_PREFIX .. data.atlasElementName
		end

		if name and path then
			LSM:Register(STATUSBAR_ATLAS, ("Blizzard %s"):format(name), path)
		end
	end
end

---@param name string
---@return string?
function Media.Statusbar(name)
	return LSM:Fetch(STATUSBAR_ATLAS, name, true) or LSM:Fetch("statusbar", name)
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
	if mediaType ~= "statusbar" then
		return LSM:List(mediaType) or {}
	end

	local merged = {}

	for _, name in ipairs(LSM:List("statusbar") or {}) do
		merged[#merged + 1] = name
	end

	for _, name in ipairs(LSM:List(STATUSBAR_ATLAS) or {}) do
		merged[#merged + 1] = name
	end

	table.sort(merged)

	return merged
end

---@param mediaType string
---@param name string
---@return string?
function Media.Fetch(mediaType, name)
	if mediaType == "statusbar" then
		return Media.Statusbar(name)
	end

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

---@param texture Texture
---@param mediaType string
---@param name string
---@return boolean applied
function Media.Apply(texture, mediaType, name)
	if mediaType == "statusbar" then
		local atlas = LSM:Fetch(STATUSBAR_ATLAS, name, true)

		if atlas then
			texture:SetAtlas(atlas)

			return true
		end
	end

	local path = LSM:Fetch(mediaType, name)

	if not path then
		return false
	end

	texture:SetTexture(path)

	return true
end
