local AMT = select(2, ...)

local Dashboard = AMT.Dashboard
local Parts = Dashboard.Parts

local BACKGROUND_SUBLEVEL = -5
local BACKGROUND_LEFT, BACKGROUND_TOP = 6, -21
local BACKGROUND_RIGHT, BACKGROUND_BOTTOM = -2, 2

local BAND_LEFT, BAND_TOP = 8, -26
local BAND_RIGHT, BAND_BOTTOM = -3, 339
local SECTION_SHARES = { 0.185, 0.221, 0.175, 0.174, 0.245 }

local SHADOW_RULE_HEIGHT = 32
local SHADOW_RULE_DROP = 4
local SHADOW_RULE_R, SHADOW_RULE_G, SHADOW_RULE_B = 95 / 255, 86 / 255, 81 / 255

local COLUMN_WIDTH = 290
-- Below the band, clear of the shadow rule's fade.
local COLUMN_GAP = 12
local COLUMN_BOTTOM = 4
local DUNGEONS_LEFT = 8
local PARTY_RIGHT = -3
local PARTY_GAP = 6
local RUNS_GAP = 8

---@class AMTDashboardShowTicker
---@field interval number
---@field callback fun()
---@field handle FunctionContainer?

---@class AMTDashboardPanel
local Panel = {}
Dashboard.Panel = Panel

---@class AMTDashboardPanelRoot : Frame
---@field band Frame
---@field sections Frame[]
---@field dungeons Frame
---@field runs Frame
---@field vault Frame
---@field party Frame
---@field showEvents table<string, fun(event: string, ...: any)[]>
---@field showTickers AMTDashboardShowTicker[]
local Root = {}
Panel.RootMixin = Root

---@param ticker AMTDashboardShowTicker
local function StartTicker(ticker)
	if ticker.handle then
		return
	end

	ticker.callback()
	ticker.handle = C_Timer.NewTicker(ticker.interval, ticker.callback)
end

---@param ticker AMTDashboardShowTicker
local function StopTicker(ticker)
	if not ticker.handle then
		return
	end

	ticker.handle:Cancel()
	ticker.handle = nil
end

function Root:OnLoad()
	self.showEvents = {}
	self.showTickers = {}

	self:SetUsingParentLevel(true)
	self:SetAllPoints()
	self:Hide()

	self:CreateBackground()
	self:CreateBand()
	self:CreateColumns()
	Dashboard.Band:Build(self.sections)

	self:SetScript("OnShow", self.OnShow)
	self:SetScript("OnHide", self.OnHide)
	self:SetScript("OnEvent", self.OnEvent)
end

function Root:CreateBackground()
	local background = self:CreateTexture(nil, "BACKGROUND", nil, BACKGROUND_SUBLEVEL)

	background:SetAtlas("UI-Journeys-BG")
	background:SetPoint("TOPLEFT", BACKGROUND_LEFT, BACKGROUND_TOP)
	background:SetPoint("BOTTOMRIGHT", BACKGROUND_RIGHT, BACKGROUND_BOTTOM)

	Dashboard.Skin:Register(background, "background")
end

function Root:CreateBand()
	local band = CreateFrame("Frame", nil, self)

	band:SetPoint("TOPLEFT", BAND_LEFT, BAND_TOP)
	band:SetPoint("BOTTOMRIGHT", BAND_RIGHT, BAND_BOTTOM)

	self.band = band
	self.sections = {}

	for index = 1, #SECTION_SHARES do
		local section = CreateFrame("Frame", nil, band)
		local previous = self.sections[index - 1]

		if previous then
			section:SetPoint("TOPLEFT", previous, "TOPRIGHT")
			section:SetPoint("BOTTOMLEFT", previous, "BOTTOMRIGHT")
		else
			section:SetPoint("TOPLEFT")
			section:SetPoint("BOTTOMLEFT")
		end

		if index < #SECTION_SHARES then
			local hairline = Parts.NewHairline(section)

			hairline:SetPoint("TOPRIGHT")
			hairline:SetPoint("BOTTOMRIGHT")
		end

		self.sections[index] = section
	end

	band:SetScript("OnSizeChanged", function(_, width)
		self:LayoutSections(width)
	end)
	self:LayoutSections(band:GetWidth())

	local shadowRule = band:CreateTexture(nil, "ARTWORK")

	shadowRule:SetTexture(AMT.NineSlice.Path("DividerShadow"))
	shadowRule:SetHeight(SHADOW_RULE_HEIGHT)
	shadowRule:SetPoint("LEFT", band, "BOTTOMLEFT", 0, -SHADOW_RULE_DROP)
	shadowRule:SetPoint("RIGHT", band, "BOTTOMRIGHT", 0, -SHADOW_RULE_DROP)
	shadowRule:SetVertexColor(SHADOW_RULE_R, SHADOW_RULE_G, SHADOW_RULE_B)

	Dashboard.Skin:Register(shadowRule, "shadowRule")
end

---@param width number
function Root:LayoutSections(width)
	for index, section in ipairs(self.sections) do
		section:SetWidth(width * SECTION_SHARES[index])
	end
end

function Root:CreateColumns()
	local band = self.band

	local dungeons = CreateFrame("Frame", nil, self)

	dungeons:SetWidth(COLUMN_WIDTH)
	dungeons:SetPoint("TOPLEFT", band, "BOTTOMLEFT", 0, -COLUMN_GAP)
	dungeons:SetPoint("BOTTOMLEFT", DUNGEONS_LEFT, COLUMN_BOTTOM)

	local dungeonsHairline = Parts.NewHairline(dungeons)

	dungeonsHairline:SetPoint("TOPRIGHT")
	dungeonsHairline:SetPoint("BOTTOMRIGHT")

	-- No height here: the Great Vault panel sizes it to its content.
	local vault = CreateFrame("Frame", nil, self)

	vault:SetWidth(COLUMN_WIDTH)
	vault:SetPoint("TOPRIGHT", band, "BOTTOMRIGHT", 0, -COLUMN_GAP)

	local party = CreateFrame("Frame", nil, self)

	party:SetWidth(COLUMN_WIDTH)
	party:SetPoint("TOPRIGHT", vault, "BOTTOMRIGHT", 0, -PARTY_GAP)
	party:SetPoint("BOTTOMRIGHT", PARTY_RIGHT, COLUMN_BOTTOM)

	local columnHairline = Parts.NewHairline(self)

	columnHairline:SetPoint("TOPRIGHT", vault, "TOPLEFT")
	columnHairline:SetPoint("BOTTOMRIGHT", party, "BOTTOMLEFT")

	local runs = CreateFrame("Frame", nil, self)

	runs:SetPoint("TOPLEFT", dungeons, "TOPRIGHT", RUNS_GAP, 0)
	runs:SetPoint("BOTTOMRIGHT", party, "BOTTOMLEFT", -RUNS_GAP, 0)

	self.dungeons = dungeons
	self.vault = vault
	self.party = party
	self.runs = runs
end

function Root:Refresh()
	Dashboard.Band:Refresh(Dashboard.Source:GetHeader())
end

---@param event string
---@param handler fun(event: string, ...: any)
function Root:RegisterShowEvent(event, handler)
	local handlers = self.showEvents[event]

	if not handlers then
		handlers = {}
		self.showEvents[event] = handlers
	end

	handlers[#handlers + 1] = handler

	if self:IsVisible() then
		self:RegisterEvent(event)
	end
end

---@param interval number seconds, matching the resolution the text shows
---@param callback fun()
function Root:RegisterShowTicker(interval, callback)
	local ticker = { interval = interval, callback = callback }

	self.showTickers[#self.showTickers + 1] = ticker

	if self:IsVisible() then
		StartTicker(ticker)
	end
end

function Root:OnShow()
	self:Refresh()

	for event in pairs(self.showEvents) do
		self:RegisterEvent(event)
	end

	for _, ticker in ipairs(self.showTickers) do
		StartTicker(ticker)
	end
end

function Root:OnHide()
	self:UnregisterAllEvents()

	for _, ticker in ipairs(self.showTickers) do
		StopTicker(ticker)
	end
end

---@param event string
---@param ... any
function Root:OnEvent(event, ...)
	local handlers = self.showEvents[event]

	if not handlers then
		return
	end

	for _, handler in ipairs(handlers) do
		handler(event, ...)
	end
end

---@param host Frame
---@return AMTDashboardPanelRoot
function Panel.Build(host)
	local root = CreateFrame("Frame", "AdvancedMythicTrackerDashboard", host)

	Mixin(root, Root)
	root:OnLoad()

	return root
end
