local AMT = select(2, ...)

local Options = AMT.Options

---@alias AMTBindingScope "profile"|"account"

---@type table<string, (string|integer)[]>
local segmentCache = {}

---@param path string
---@return (string|integer)[]
local function Segments(path)
	local cached = segmentCache[path]

	if cached then
		return cached
	end

	---@type (string|integer)[]
	local segments = {}

	for part in path:gmatch("[^.]+") do
		-- e.g. "timer.thresholds.2.enabled".
		segments[#segments + 1] = tonumber(part) or part
	end

	segmentCache[path] = segments

	return segments
end

---@param scope AMTBindingScope?
---@return table?
local function Root(scope)
	if scope == nil or scope == "profile" then
		return AMT.Profiles.active
	end

	if scope == "account" then
		return AMT.DB.settings
	end

	AMT.Util.Warn("unknown settings scope %q.", tostring(scope))

	return nil
end

---@param path string
---@param scope AMTBindingScope?
---@return any
function Options.Get(path, scope)
	local node = Root(scope)
	local segments = Segments(path)

	for index = 1, #segments do
		if type(node) ~= "table" then
			return nil
		end

		node = node[segments[index]]
	end

	return node
end

---@param path string
---@param value any
---@param scope AMTBindingScope?
---@return boolean written
function Options.Set(path, value, scope)
	local node = Root(scope)
	local segments = Segments(path)

	if not node or #segments == 0 then
		AMT.Util.Warn("cannot write to settings path %q.", tostring(path))

		return false
	end

	for index = 1, #segments - 1 do
		local child = node[segments[index]]

		if type(child) ~= "table" then
			AMT.Util.Warn("settings path %q stops at %q; nothing was written.", path, tostring(segments[index]))

			return false
		end

		node = child
	end

	node[segments[#segments]] = value

	AMT.Profiles.Refresh()

	return true
end
