local AMT = select(2, ...)

---@class AMTUtil
local Util = {}
AMT.Util = Util

local PREFIX = "|cff33ff99Advanced Mythic Tracker|r: "
local WARN_PREFIX = "|cff33ff99Advanced Mythic Tracker|r |cffff7f3fWarning|r: "

---@param message string
---@param ... any
function Util.Print(message, ...)
	if select("#", ...) > 0 then
		message = message:format(...)
	end

	print(PREFIX .. message)
end

---@param message string
---@param ... any
function Util.Warn(message, ...)
	if select("#", ...) > 0 then
		message = message:format(...)
	end

	print(WARN_PREFIX .. message)
end

---@generic T
---@param source T
---@return T
function Util.Copy(source)
	if type(source) ~= "table" then
		return source
	end

	local result = {}
	for key, value in pairs(source) do
		result[key] = Util.Copy(value)
	end

	return result
end

---@param target table<any, any>?
---@param defaults table<any, any>
function Util.MergeDefaults(target, defaults)
	if not target then
		return
	end

	for key, value in pairs(defaults) do
		local current = target[key]

		if type(value) == "table" then
			if type(current) ~= "table" then
				current = {}
				target[key] = current
			end

			Util.MergeDefaults(current, value)
		elseif current == nil then
			target[key] = value
		end
	end
end
