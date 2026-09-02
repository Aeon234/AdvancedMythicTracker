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

---@param text string
---@return string
function Util.Trim(text)
	return (text:gsub("^%s*(.-)%s*$", "%1"))
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

---@param seconds number
---@param decimals integer? 0-3, default 0
---@param signed boolean? prefix the sign, for diffs
---@return string
function Util.FormatTime(seconds, decimals, signed)
	local precision = decimals or 0
	local factor = 10 ^ precision
	local absolute = Round(math.abs(seconds) * factor) / factor

	local hours = math.floor(absolute / 3600)
	local minutes = math.floor((absolute % 3600) / 60)
	local wholeSeconds = math.floor(absolute % 60)

	local formatted

	if hours > 0 then
		formatted = ("%d:%02d:%02d"):format(hours, minutes, wholeSeconds)
	else
		formatted = ("%d:%02d"):format(minutes, wholeSeconds)
	end

	if precision > 0 then
		formatted = formatted .. ("%." .. precision .. "f"):format(absolute % 1):sub(2)
	end

	if not signed then
		return formatted
	end

	if seconds > 0 then
		return "+" .. formatted
	elseif seconds < 0 then
		return "-" .. formatted
	end

	return "±" .. formatted
end

---Instead of MergeDefaults, overwrites existing table completely.
---@param target table
---@param source table
function Util.Overlay(target, source)
	for key, value in pairs(source) do
		if type(value) == "table" then
			local current = target[key]

			if type(current) ~= "table" then
				current = {}
				target[key] = current
			end

			Util.Overlay(current, value)
		else
			target[key] = value
		end
	end
end

---@param settings AMTSplitsProfile
---@param verdict AMTSplitVerdict
---@return number[]
function Util.SplitColor(settings, verdict)
	if verdict == "AHEAD" then
		return settings.aheadColor
	elseif verdict == "BEHIND" then
		return settings.behindColor
	end

	return settings.equalColor
end
