local AMT = select(2, ...)

local ELVUI_CALLBACK = "AdvancedMythicTracker_Dashboard"

---@alias AMTDashboardSkinPack "ElvUI"|"Aurora"

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

---@class AMTDashboardSkinTabAnchor
---@field gap number x from the previous shown tab's TOPRIGHT
---@field point FramePoint the tab's point on PVEFrame's BOTTOMLEFT when no Blizzard tab is shown
---@field x number
---@field y number

---@type table<AMTDashboardSkinPack|"Blizzard", AMTDashboardSkinTabAnchor>
local TAB_ANCHORS = {
	Blizzard = { gap = 3, point = "BOTTOMLEFT", x = 19, y = -30 },
	ElvUI = { gap = -5, point = "BOTTOMLEFT", x = -3, y = -32 },
	Aurora = { gap = 1, point = "TOPLEFT", x = 20, y = -1 },
}

---@alias AMTDashboardSkinHandler fun(region: Region)

---@type table<AMTDashboardSkinPack, table<AMTDashboardSkinRole, AMTDashboardSkinHandler>>
local HANDLERS = {
	ElvUI = {},
	Aurora = {},
}

---@class AMTDashboardSkinEntry
---@field region Region
---@field role AMTDashboardSkinRole

---@class AMTDashboardSkin
---@field entries AMTDashboardSkinEntry[]
---@field resolved boolean
---@field pack AMTDashboardSkinPack? nil for Blizzard's look
---@field shadows boolean WindTools shadows on top of ElvUI
local Skin = {}
AMT.Dashboard.Skin = Skin

Skin.entries = {}
Skin.resolved = false
Skin.shadows = false

---@param E table ElvUI's engine
---@return boolean
local function ElvUISkinsGroupFinder(E)
	local blizzard = E.private.skins.blizzard

	return blizzard.enable and blizzard.lfg or false
end

---@return boolean
local function WindToolsShadowsGroupFinder()
	local windTools = _G.WindTools

	if not windTools then
		return false
	end

	return windTools[1].Modules.Skins:CheckDB("lfg", "lookingForGroup")
end

---@param entry AMTDashboardSkinEntry
function Skin:Apply(entry)
	local handler = self.pack and HANDLERS[self.pack][entry.role]

	if handler then
		handler(entry.region)
	end
end

---@param pack AMTDashboardSkinPack?
---@param shadows boolean
function Skin:Resolve(pack, shadows)
	if self.resolved then
		return
	end

	self.pack = pack
	self.shadows = shadows
	self.resolved = true

	for _, entry in ipairs(self.entries) do
		self:Apply(entry)
	end
end

---@param E table ElvUI's engine
function Skin:ResolveElvUI(E)
	if ElvUISkinsGroupFinder(E) then
		self:Resolve("ElvUI", WindToolsShadowsGroupFinder())
	else
		self:Resolve(nil, false)
	end
end

function Skin:Start()
	local elvui = _G.ElvUI

	if not elvui then
		self:Resolve(_G.Aurora and "Aurora" or nil, false)

		return
	end

	local E = elvui[1]

	if E.Initialized then
		self:ResolveElvUI(E)
	else
		E:GetModule("Skins"):AddCallback(ELVUI_CALLBACK, function()
			self:ResolveElvUI(E)
		end)
	end
end

---@param region Region
---@param role AMTDashboardSkinRole
function Skin:Register(region, role)
	if not ROLES[role] then
		AMT.Util.Warn("unknown dashboard skin role %q.", tostring(role))

		return
	end

	local entries = self.entries
	local entry = { region = region, role = role }

	entries[#entries + 1] = entry

	if self.resolved then
		self:Apply(entry)
	end
end

---@return AMTDashboardSkinTabAnchor
function Skin:GetTabAnchor()
	return TAB_ANCHORS[self.pack or "Blizzard"]
end
