local addonName, AMT = ...

local X_OFFSET = 16
local Y_OFFSET_TOP = -23
local Y_OFFSET_BOTTOM = 4

function AMT:Portals_Setup()
	local Portals = AMT.Window.Portals
	Portals.WIP = Portals:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	Portals.WIP:SetPoint("CENTER", Portals, "CENTER", 0, 0)
	Portals.WIP:SetText("Work in Progress")
	Portals.WIP:SetFont(self.AMT_Font, 36)
	-- Portals Tracker
	-- Portals.ExpansionsTable = {}

	-- for _, dungeon in ipairs(self.SeasonalDungeons) do
	-- 	local exp = dungeon.exp
	-- 	if exp and not self:TableFind(Portals.ExpansionsTable, function(val)
	-- 		return val == exp
	-- 	end) then
	-- 		table.insert(Portals.ExpansionsTable, exp)
	-- 	end
	-- end

	-- Portals.Expansions = {}
	-- for i, exp in ipairs(Portals.ExpansionsTable) do
	-- 	local expName = _G["EXPANSION_NAME" .. exp]

	-- 	if not Portals.Expansions[exp] then
	-- 		Portals.Expansions[exp] = {}
	-- 	end

	-- 	Portals.Expansions[exp].Divider = self:SpellbookDivider(Portals, expName)
	-- 	Portals.Expansions[exp].Divider:SetPoint(
	-- 		"TOPLEFT",
	-- 		Portals,
	-- 		"TOPLEFT",
	-- 		X_OFFSET,
	-- 		Y_OFFSET_TOP - 23 - (i - 1) * 85
	-- 	)
	-- 	Portals.Expansions[exp].Spells = {}
	-- 	local processedInstanceIDs = {}

	-- 	local SpellIndex = 0
	-- 	for _, dungeon in ipairs(self.SeasonalDungeons) do
	-- 		if dungeon.exp == exp and not processedInstanceIDs[dungeon.instanceID] then
	-- 			processedInstanceIDs[dungeon.instanceID] = true
	-- 			local abbr = dungeon.megaDung or dungeon.abbr
	-- 			SpellIndex = SpellIndex + 1
	-- 			Portals.Expansions[exp].Spells[dungeon.abbr] = self:SpellbookSpellIcon(Portals, dungeon.spellID, abbr)
	-- 			Portals.Expansions[exp].Spells[dungeon.abbr]:SetPoint(
	-- 				"TOPLEFT",
	-- 				Portals.Expansions[exp].Divider,
	-- 				"BOTTOMLEFT",
	-- 				40 + 50 * (SpellIndex - 1),
	-- 				0
	-- 			)
	-- 		end
	-- 	end
	-- end

	self.Portals_Initialized = true

	Portals.ScrollFrame = CreateFrame("Frame", nil, Portals, "WowScrollBoxList")
	Portals.ScrollFrame:SetPoint("CENTER")
	Portals.ScrollFrame:SetSize(Portals:GetWidth() - 34, Portals:GetHeight() + Y_OFFSET_TOP)

	Portals.ScrollFrame.ScrollBar = CreateFrame("EventFrame", nil, Portals, "MinimalScrollBar")
	Portals.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", Portals.ScrollFrame, "TOPRIGHT")
	Portals.ScrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", Portals.ScrollFrame, "BOTTOMRIGHT")

	local DataProvider = CreateDataProvider()
	Portals.ScrollFrame.ScrollView = CreateScrollBoxListLinearView()
	Portals.ScrollFrame.ScrollView:SetDataProvider(DataProvider)

	ScrollUtil.InitScrollBoxListWithScrollBar(
		Portals.ScrollFrame,
		Portals.ScrollFrame.ScrollBar,
		Portals.ScrollFrame.ScrollView
	)

	-- local function HeaderInitializer(frame, data)
	-- 	frame:ClearAllPoints()
	-- 	for _, child in ipairs({ frame:GetChildren() }) do
	-- 		child:Hide()
	-- 	end

	-- 	local title = _G["EXPANSION_NAME" .. data.exp]
	-- 	local divider = AMT:SpellbookDivider(frame, title)
	-- 	divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)

	-- 	local h = divider:GetHeight() + (divider.Text:GetHeight() or 0)
	-- 	frame:SetHeight(h)
	-- end

	-- local function SpellInitializer(frame, data)
	-- 	local dungeon = data.dungeon

	-- 	-- clear old contents
	-- 	frame:ClearAllPoints()
	-- 	for _, child in ipairs({ frame:GetChildren() }) do
	-- 		child:Hide()
	-- 	end

	-- 	-- call your existing AMT:SpellbookSpellIcon, parented to this row‐frame
	-- 	local iconBtn = AMT:SpellbookSpellIcon(frame, dungeon.spellID, dungeon.abbr or dungeon.megaDung)
	-- 	iconBtn:SetPoint("LEFT", frame, "LEFT", 40, 0)

	-- 	-- size the row to match the icon + its label
	-- 	local h = iconBtn:GetHeight() + (iconBtn.Text and iconBtn.Text:GetHeight() or 0) + 8
	-- 	frame:SetHeight(h)
	-- 	frame:SetScript("OnClick", iconBtn:GetScript("OnClick"))
	-- end

	-- Portals.ScrollFrame.ScrollView:SetElementInitializer("Frame", function(f, d)
	-- 	if d.type == "header" then
	-- 		HeaderInitializer(f, d)
	-- 	end
	-- end)
	-- Portals.ScrollFrame.ScrollView:SetElementInitializer("Frame", function(f, d)
	-- 	if d.type == "spell" then
	-- 		SpellInitializer(f, d)
	-- 	end
	-- end)
end

local function BuildPortalList(self)
	-- collect unique expansions in order
	local expOrder = {}
	local seenExp = {}

	for _, dungeon in ipairs(self.SeasonalDungeons) do
		local exp = dungeon.exp
		if exp and not seenExp[exp] then
			seenExp[exp] = true
			table.insert(expOrder, exp)
		end
	end

	-- build a flat list: { { type="header", exp=exp }, { type="spell", dungeon=d } , … }
	local rows = {}
	for _, exp in ipairs(expOrder) do
		-- header row
		table.insert(rows, { type = "header", exp = exp })

		-- all dungeons of that expansion
		local seenInstance = {}
		for _, dungeon in ipairs(self.SeasonalDungeons) do
			if dungeon.exp == exp and not seenInstance[dungeon.instanceID] then
				seenInstance[dungeon.instanceID] = true
				table.insert(rows, { type = "spell", dungeon = dungeon })
			end
		end
	end

	return rows
end

function AMT:Portals_Refresh()
	if not self.Portals_Initialized then
		self:Portals_Setup()
	end
end

function AMT:SpellbookDivider(parent, title)
	local frame = CreateFrame("Frame", "AMT_Portals_test", parent)
	frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
	frame.tex = frame:CreateTexture()
	frame.tex:SetAllPoints(frame)
	frame.tex:SetTexture("Interface/AddOns/AdvancedMythicTracker/Media/SpellbookElements.blp")
	frame.tex:SetTexCoord(0.2470703125, 0.888671875, 0.4111328125, 0.421875)
	frame:SetSize(657, 11)
	-- frame:SetSize(256, 11)

	frame.Text = frame:CreateFontString(nil, "OVERLAY", "SystemFont_Large")
	frame.Text:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 30, 0)
	frame.Text:SetText(title)
	frame.Text:SetTextColor(1, 1, 1, 1)

	return frame
end

function AMT:SpellbookSpellIcon(parent, spellID, name)
	local IconSetup = {
		iconMask = "spellbook-item-spellicon-mask",
		iconHighlight = "spellbook-item-iconframe-hover",
		activeBorder = "spellbook-item-iconframe",
		activeBorderAnchors = {
			CreateAnchor("TOPLEFT", nil, "TOPLEFT", -11, 1),
			CreateAnchor("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 1, -7),
		},
		inactiveBorder = "spellbook-item-iconframe-inactive",
		inactiveBorderAnchors = {
			CreateAnchor("TOPLEFT", nil, "TOPLEFT", -10, 1),
			CreateAnchor("BOTTOMRIGHT", nil, "BOTTOMRIGHT", 2, -5),
		},
		borderSheenMask = "spellbook-item-iconframe-sheen-mask",
		borderSheenMaskAnchors = {
			CreateAnchor("TOPLEFT"),
			CreateAnchor("BOTTOMRIGHT"),
		},
	}

	local SelectedSpell = nil
	if type(spellID) == "table" then
		for _, id in ipairs(spellID) do
			if IsSpellKnown(id) then
				SelectedSpell = id
				break
			end
		end
		-- Default to the first spellID if none are known
		SelectedSpell = SelectedSpell or spellID[1]
	else
		SelectedSpell = spellID
	end

	local SpellInfo = C_Spell.GetSpellInfo(SelectedSpell)
	local SpellKnown = IsSpellKnown(SelectedSpell)

	local button = CreateFrame("Button", "AMT_testbutton", parent, "InsecureActionButtonTemplate")
	button:SetSize(32, 32)

	button.Icon = button:CreateTexture(nil, "BACKGROUND")
	button.Icon:SetAllPoints(button)
	button.Icon:SetTexture(SpellInfo.iconID)

	button.Mask = button:CreateMaskTexture()
	button.Mask:SetAllPoints(button.Icon)
	button.Mask:SetTexture(
		"interface/spellbook/spellbookelementsiconmask",
		"CLAMPTOBLACKADDITIVE",
		"CLAMPTOBLACKADDITIVE"
	)
	button.Icon:AddMaskTexture(button.Mask)
	-- button.Icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

	button.IconFrame = button:CreateTexture(nil, "BACKGROUND", nil, 2)
	button.IconFrame:SetAllPoints(button)
	if SpellKnown then
		button.IconFrame:SetDesaturated(false)
	else
		button.IconFrame:SetDesaturated(true)
		button.Icon:SetDesaturated(true)
	end
	button.IconFrame:SetAtlas(IconSetup.activeBorder, false)

	local borderAnchors = SpellKnown and IconSetup.activeBorderAnchors or IconSetup.inactiveBorderAnchors
	for _, anchor in ipairs(borderAnchors) do
		local point, relativeTo, relativePoint, x, y = anchor:Get()
		relativeTo = relativeTo or button
		button.IconFrame:SetPoint(point, relativeTo, relativePoint, x, y)
	end

	button.IconHighlight = button:CreateTexture(nil, "HIGHLIGHT")
	button.IconHighlight:SetAllPoints(button)
	button.IconHighlight:SetAtlas(IconSetup.iconHighlight, false)
	button.IconHighlight:SetAlpha(0.35)
	button.IconHighlight:SetBlendMode("ADD")

	button.Text = button:CreateFontString(nil, "OVERLAY", "SystemFont_Med1")
	button.Text:SetPoint("TOP", button, "BOTTOM", 0, -8)
	button.Text:SetText(name)

	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetSpellByID(SelectedSpell)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
	end)

	button:RegisterForClicks("AnyUp", "AnyDown")
	button:SetAttribute("type1", "spell")
	button:SetAttribute("spell", C_Spell.GetSpellName(SelectedSpell))

	return button
end
