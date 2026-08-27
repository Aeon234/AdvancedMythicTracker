local AMT = select(2, ...)

---@param _ table
---@param key string
---@return string
local function FallBackToKey(_, key)
	return key
end

---@class AMTLocale: table
local L = setmetatable({}, { __index = FallBackToKey })

AMT.L = L
