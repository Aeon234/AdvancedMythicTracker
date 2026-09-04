local AMT = select(2, ...)
local L = AMT.L

local PRESERVED = { "position", "scale" }

---@class AMTStyle
local Style = {}
AMT.Style = Style

---@param source AMTTimerProfile
function Style.Replace(source)
	local timer = AMT.Profiles.active.timer

	wipe(timer)
	AMT.Util.Overlay(timer, source)

	AMT.Layout.ReseedProfile()
	AMT.Profiles.Refresh()
end

---@param key AMTStyleKey
---@return boolean applied
function Style.Apply(key)
	local override = AMT.Options.Styles.GetOverride(key)

	if not override then
		AMT.Util.Warn(L["unknown style %q."], tostring(key))

		return false
	end

	local profile = AMT.Profiles.active
	local timer = profile.timer

	profile.__preTimerStyleBackup = AMT.Util.Copy(timer)

	local preserved = {}

	for _, field in ipairs(PRESERVED) do
		preserved[field] = AMT.Util.Copy(timer[field])
	end

	local stamped = AMT.Profiles.TimerDefaults()

	AMT.Util.Overlay(stamped, override)
	stamped.style = key

	for field, value in pairs(preserved) do
		stamped[field] = value
	end

	Style.Replace(stamped)

	return true
end

---@return boolean
function Style.CanUndo()
	return AMT.Profiles.active.__preTimerStyleBackup ~= nil
end

---@return boolean undone
function Style.Undo()
	local profile = AMT.Profiles.active
	local backup = profile.__preTimerStyleBackup

	if not backup then
		AMT.Util.Warn(L["there is no style change to undo."])

		return false
	end

	profile.__preTimerStyleBackup = nil

	Style.Replace(backup)

	return true
end
