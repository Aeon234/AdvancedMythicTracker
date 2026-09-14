local AMT = select(2, ...)

---@alias AMTDashboardSkinRole
---| "tab"
---| "Ring"
---| "Inset"
---| "Hover"
---| "Control"
---| "Solid"
---| "background"
---| "scrollbar"
---| "hairline"
---| "rule"
---| "shadowRule"
---| "text"

---@type table<AMTDashboardSkinRole, true>
local ROLES = {
	tab = true,
	Ring = true,
	Inset = true,
	Hover = true,
	Control = true,
	Solid = true,
	background = true,
	scrollbar = true,
	hairline = true,
	rule = true,
	shadowRule = true,
	text = true,
}

---@class AMTDashboardSkinEntry
---@field region Region
---@field role AMTDashboardSkinRole

---@class AMTDashboardSkin
---@field entries AMTDashboardSkinEntry[]
local Skin = {}
AMT.Dashboard.Skin = Skin

Skin.entries = {}

---@param region Region
---@param role AMTDashboardSkinRole
function Skin:Register(region, role)
	if not ROLES[role] then
		AMT.Util.Warn("unknown dashboard skin role %q.", tostring(role))

		return
	end

	local entries = self.entries

	entries[#entries + 1] = { region = region, role = role }
end
