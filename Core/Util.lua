local AMT = select(2, ...)

---@class AMTUtil
local Util = {}
AMT.Util = Util

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

---@generic T: table
---@param target table
---@param defaults T
---@return T
function Util.MergeDefaults(target, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if target and type(target[key]) ~= "table" then
				target[key] = {}
			end

			Util.MergeDefaults(target[key], value)
		elseif target[key] == nil then
			target[key] = value
		end
	end

	return target
end
