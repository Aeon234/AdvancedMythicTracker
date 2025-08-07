local addonName, AMT = ...

local ElvUI = ElvUI

local CellHeight = 19
local X_OFFSET = 7
local Y_OFFSET_TOP = -23
local Y_OFFSET_BOTTOM = 4
local CatalystID = 3269
local HalfSparkID = 231757
local FullSparkID = 231756

function AMT:SeasonalInfo_Setup()
	-- self.Window.Info.WIP = self.Window.Info:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	-- self.Window.Info.WIP:SetPoint("CENTER", self.Window.Info, "CENTER", 0, 0)
	-- self.Window.Info.WIP:SetText("Work in Progress")
	-- self.Window.Info.WIP:SetFont(self.AMT_Font, 36)

	-- Calayst Charges Tracker
	self.Window.Info.Catalyst = CreateFrame("Frame", "AMT_Catalyst", self.Window.Info)
	self.Window.Info.Catalyst:SetSize(200, 60)
	self.Window.Info.Catalyst:SetPoint("TOPLEFT", self.Window.Info, "TOPLEFT", X_OFFSET, Y_OFFSET_TOP)

	-- if ElvUI then
	-- 	self.Window.Info.Catalyst:SetTemplate("Transparent")
	-- else
	-- 	self.Window.Info.Catalyst.tex = self.Window.Info.Catalyst:CreateTexture()
	-- 	self.Window.Info.Catalyst.tex:SetAllPoints(self.Window.Info.Catalyst)
	-- 	self.Window.Info.Catalyst.tex:SetColorTexture(unpack(self.BackgroundDark))
	-- end

	self.Window.Info.Catalyst.header = self.Window.Info.Catalyst:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	self.Window.Info.Catalyst.header:SetPoint("TOP", self.Window.Info.Catalyst, "TOP", 0, -2)
	self.Window.Info.Catalyst.header:SetFont(self.AMT_Font, 14)
	self.Window.Info.Catalyst.header:SetText("Catalyst Charges")

	self.Window.Info.Catalyst.ChargesBar =
		AMT.CreateMetalProgressBar(self.Window.Info.Catalyst, "large", "AMT_CatalystChargesBar")
	self.Window.Info.Catalyst.ChargesBar:SetBarWidth(160)
	self.Window.Info.Catalyst.ChargesBar:SetBarColor(0.9, 0.9, 0.9, 1.0)
	self.Window.Info.Catalyst.ChargesBar:SetPoint("TOP", self.Window.Info.Catalyst.header, "BOTTOM", 0, -5)
	self.Window.Info.Catalyst.ChargesBar:SetSmoothFill(true)
	self.Window.Info.Catalyst.ChargesBar:SetNumThreshold(5)
	self.Window.Info.Catalyst.ChargesBar:SetValue(2, 6)

	self.Window.Info.Catalyst.ChargesBar:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self.Window.Info.Catalyst.ChargesBar, "ANCHOR_RIGHT")
		GameTooltip:SetText(
			CreateTextureMarkup(AMT.Window.Info.Catalyst.Icon, 64, 64, 16, 16, 0.07, 0.93, 0.07, 0.93)
				.. " "
				.. AMT.Window.Info.Catalyst.Name,
			0.118,
			0.900,
			0.000,
			1.000,
			true
		)
		GameTooltip:AddLine(AMT.Window.Info.Catalyst.CurrencyDescription, 1.000, 0.824, 0.000, true)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(
			"Current: "
				.. AMT.WhiteText
				.. AMT.Window.Info.Catalyst.CurrentCharges
				.. "/"
				.. AMT.Window.Info.Catalyst.MaxCharges
		)
		GameTooltip:Show()
	end)
	self.Window.Info.Catalyst.ChargesBar:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	--Spark Tracker
	self.Window.Info.Spark = CreateFrame("Frame", "AMT_Spark", self.Window.Info)
	self.Window.Info.Spark:SetSize(200, 60)
	self.Window.Info.Spark:SetPoint("TOP", self.Window.Info.Catalyst, "BOTTOM", 0, 0)

	-- if ElvUI then
	-- 	self.Window.Info.Spark:SetTemplate("Transparent")
	-- else
	-- 	self.Window.Info.Spark.tex = self.Window.Info.Spark:CreateTexture()
	-- 	self.Window.Info.Spark.tex:SetAllPoints(self.Window.Info.Spark)
	-- 	self.Window.Info.Spark.tex:SetColorTexture(unpack(self.BackgroundDark))
	-- end

	self.Window.Info.Spark.header = self.Window.Info.Spark:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
	self.Window.Info.Spark.header:SetPoint("TOP", self.Window.Info.Spark, "TOP", 0, -2)
	self.Window.Info.Spark.header:SetFont(self.AMT_Font, 14)
	self.Window.Info.Spark.header:SetText("Sparks Tracker")

	self.Window.Info.Spark.ChargesBar =
		AMT.CreateMetalProgressBar(self.Window.Info.Spark, "large", "AMT_SparkChargesBar")
	self.Window.Info.Spark.ChargesBar:SetBarWidth(160)
	self.Window.Info.Spark.ChargesBar:SetBarColor(0.992, 0.906, 0.678, 1.0)
	self.Window.Info.Spark.ChargesBar:SetPoint("TOP", self.Window.Info.Spark.header, "BOTTOM", 0, -5)
	self.Window.Info.Spark.ChargesBar:SetSmoothFill(true)
	self.Window.Info.Spark.ChargesBar:SetNumThreshold(5)
	self.Window.Info.Spark.ChargesBar:SetValue(2, 6)

	self.Window.Info.Spark.ChargesBar:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self.Window.Info.Spark.ChargesBar, "ANCHOR_RIGHT")
		GameTooltip:SetText(
			CreateTextureMarkup(AMT.Window.Info.Spark.db.SparkTex, 64, 64, 16, 16, 0.07, 0.93, 0.07, 0.93)
				.. " "
				.. AMT.Window.Info.Spark.db.SparkName
				.. " Tracker",
			-- 0.118,
			-- 0.900,
			-- 0.000,
			-- 1.000,
			true
		)
		GameTooltip:AddLine(
			"Accumulate 1 Fractured Spark every week, combining 2 for a single Spark. Required for crafting Armor and Weapon Pieces.",
			1.000,
			0.824,
			0.000,
			true
		)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(
			"Maximum Sparks Available: " .. AMT.WhiteText .. AMT.Window.Info.Spark.db.TotalAvailableSparks
		)
		GameTooltip:AddLine("Sparks in Inventory: " .. AMT.WhiteText .. AMT.Window.Info.Spark.db.SparksInHand)
		-- GameTooltip:AddLine("Fragments in Inventory: " .. AMT.WhiteText .. AMT.Window.Info.Spark.db.HalvesInHand)
		GameTooltip:AddLine("Sparks Used: " .. AMT.WhiteText .. AMT.Window.Info.Spark.db.SparksUsed)
		GameTooltip:AddLine(
			"Left to Gain: "
				.. AMT.WhiteText
				.. (
					AMT.Window.Info.Spark.db.TotalAvailableSparks
					- AMT.Window.Info.Spark.db.SparksInHand
					- AMT.Window.Info.Spark.db.SparksUsed
				)
		)

		GameTooltip:Show()
	end)
	self.Window.Info.Spark.ChargesBar:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- Dungeon Drops Table
	-- self.Window.Info.DungeonTable = CreateFrame("Frame", "AMT_DungeonTable", self.Window.Info)
	-- local DungeonTableWidth = 0
	-- local DungeonTableHeight = ((#self.SeasonalInfo.DungeonTable.content[1] + 1) * CellHeight) or 1
	-- for i = 1, #self.SeasonalInfo.DungeonTable.headers do
	-- 	DungeonTableWidth = DungeonTableWidth + self.SeasonalInfo.DungeonTable.headers[i].width
	-- end
	-- self.Window.Info.DungeonTable:SetSize(DungeonTableWidth, DungeonTableHeight)
	-- self.Window.Info.DungeonTable:SetPoint("BOTTOMLEFT", self.Window.Info, "BOTTOMLEFT", X_OFFSET, Y_OFFSET_BOTTOM)

	-- for row = 1, #self.SeasonalInfo.DungeonTable.content[1] + 1 do
	-- 	local TotalCellWidth = 0
	-- 	for col = 1, #self.SeasonalInfo.DungeonTable.headers do
	-- 		local cell = CreateFrame("Frame", nil, self.Window.Info.DungeonTable)
	-- 		cell:SetSize(self.SeasonalInfo.DungeonTable.headers[col].width, CellHeight)
	-- 		if col == 1 then
	-- 			TotalCellWidth = TotalCellWidth + self.SeasonalInfo.DungeonTable.headers[col].width
	-- 			cell:SetPoint("TOPLEFT", self.Window.Info.DungeonTable, "TOPLEFT", 0, -(row - 1) * CellHeight)
	-- 		else
	-- 			cell:SetPoint(
	-- 				"TOPLEFT",
	-- 				self.Window.Info.DungeonTable,
	-- 				"TOPLEFT",
	-- 				TotalCellWidth,
	-- 				-(row - 1) * CellHeight
	-- 			)
	-- 			TotalCellWidth = TotalCellWidth + self.SeasonalInfo.DungeonTable.headers[col].width
	-- 		end

	-- 		-- Background Color
	-- 		cell.bg = cell:CreateTexture(nil, "BACKGROUND")
	-- 		cell.bg:SetAllPoints(cell)
	-- 		cell.bg:SetColorTexture(0.5, 0.5, 0.5, 0.2)

	-- 		local borderColor = { 0.2, 0.2, 0.2, 1 }
	-- 		cell.borderTop = cell:CreateTexture(nil, "OVERLAY")
	-- 		cell.borderTop:SetHeight(1)
	-- 		cell.borderTop:SetColorTexture(unpack(borderColor))
	-- 		cell.borderTop:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
	-- 		cell.borderTop:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)

	-- 		cell.borderBottom = cell:CreateTexture(nil, "OVERLAY")
	-- 		cell.borderBottom:SetHeight(1)
	-- 		cell.borderBottom:SetColorTexture(unpack(borderColor))
	-- 		cell.borderBottom:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)
	-- 		cell.borderBottom:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)

	-- 		cell.borderLeft = cell:CreateTexture(nil, "OVERLAY")
	-- 		cell.borderLeft:SetWidth(1)
	-- 		cell.borderLeft:SetColorTexture(unpack(borderColor))
	-- 		cell.borderLeft:SetPoint("TOPLEFT", cell, "TOPLEFT", 0, 0)
	-- 		cell.borderLeft:SetPoint("BOTTOMLEFT", cell, "BOTTOMLEFT", 0, 0)

	-- 		cell.borderRight = cell:CreateTexture(nil, "OVERLAY")
	-- 		cell.borderRight:SetWidth(1)
	-- 		cell.borderRight:SetColorTexture(unpack(borderColor))
	-- 		cell.borderRight:SetPoint("TOPRIGHT", cell, "TOPRIGHT", 0, 0)
	-- 		cell.borderRight:SetPoint("BOTTOMRIGHT", cell, "BOTTOMRIGHT", 0, 0)

	-- 		-- Cell Text
	-- 		local cellText = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	-- 		cellText:SetPoint("CENTER", cell, "CENTER", 0, 0)
	-- 		if row == 1 then
	-- 			cellText:SetText(self.SeasonalInfo.DungeonTable.headers[col].label)
	-- 		elseif col == 1 then
	-- 			cellText:SetText(self.SeasonalInfo.DungeonTable.content[col][row - 1].text)
	-- 		else
	-- 			cellText:SetText(self.SeasonalInfo.DungeonTable.content[col][row - 1].text)
	-- 			local color = self.SeasonalInfo.DungeonTable.content[col][row - 1].color
	-- 			cell.bg:SetColorTexture(color[1], color[2], color[3], 0.3)
	-- 		end
	-- 	end
	-- end
	local DungeonTable_Options = {
		name = "AMT_DungeonTable",
		cellHeight = CellHeight,
		xOffset = X_OFFSET + 204,
		yOffset = Y_OFFSET_TOP,
		position = "TOPLEFT",
		relativePoint = "TOPLEFT",
		borderColor = { 0.2, 0.2, 0.2, 1 },
		defaultBgColor = { 0.5, 0.5, 0.5, 0.2 },
	}
	self.Window.Info.DungeonTable =
		AMT_CreateDataTable(self.Window.Info, self.SeasonalInfo.DungeonTable, DungeonTable_Options)

	local RaidTable_Options = {
		name = "AMT_RaidTable",
		cellHeight = CellHeight,
		xOffset = X_OFFSET,
		yOffset = Y_OFFSET_BOTTOM,
		position = "BOTTOMLEFT",
		relativePoint = "BOTTOMLEFT",
		borderColor = { 0.2, 0.2, 0.2, 1 },
		defaultBgColor = { 0.5, 0.5, 0.5, 0.2 },
	}
	self.Window.Info.RaidTable =
		AMT_CreateDataTable(self.Window.Info, self.SeasonalInfo.RaidDropsTable, RaidTable_Options)
	-- self.Window.Info.RaidTable:SetPoint("TOPLEFT", self.Window.Info.DungeonTable, "TOPRIGHT", 10, 0)

	local UpgradeTrack_Options = {
		name = "AMT_UpgradeTrackTable",
		cellHeight = CellHeight,
		xOffset = -X_OFFSET + 4,
		yOffset = Y_OFFSET_TOP,
		position = "TOPRIGHT",
		relativePoint = "TOPRIGHT",
		borderColor = { 0.2, 0.2, 0.2, 1 },
		defaultBgColor = { 0.5, 0.5, 0.5, 0.2 },
	}
	self.Window.Info.UpgradeTrackTable =
		AMT_CreateDataTable(self.Window.Info, self.SeasonalInfo.UpgradeTrackTable, UpgradeTrack_Options)

	self.SeasonalInfo_Initialized = true
end

function AMT:SeasonalInfo_Refresh()
	if not self.SeasonalInfo_Initialized then
		self:SeasonalInfo_Setup()
	end
	self:GET_CatalystCharges()
	self:GET_SparksInfo()
end

function AMT:GET_CatalystCharges()
	local CatalystCharges = C_CurrencyInfo.GetCurrencyInfo(CatalystID)
	if not CatalystCharges then
		return
	end
	self.Window.Info.Catalyst.Name = CatalystCharges.name
	self.Window.Info.Catalyst.Icon = CatalystCharges.iconFileID
	self.Window.Info.Catalyst.CurrencyDescription = CatalystCharges.description
	self.Window.Info.Catalyst.CurrentCharges = CatalystCharges.quantity or 0
	self.Window.Info.Catalyst.MaxCharges = CatalystCharges.maxQuantity or 1

	self.Window.Info.Catalyst.ChargesBar:SetNumThreshold(self.Window.Info.Catalyst.MaxCharges - 1)
	self.Window.Info.Catalyst.ChargesBar:SetValue(
		self.Window.Info.Catalyst.CurrentCharges,
		self.Window.Info.Catalyst.MaxCharges
	)
end

function AMT:GET_SparksInfo()
	if not self.Window.Info.Spark.db then
		self.Window.Info.Spark.db = {}
	end
	-- Create Full and Fragment Spark Info
	local Info = self.Window.Info.Spark.db
	local FullSparkItem = Item:CreateFromItemID(FullSparkID)
	FullSparkItem:ContinueOnItemLoad(function()
		Info.SparkName = FullSparkItem:GetItemName()
		Info.SparkTex = FullSparkItem:GetItemIcon()
	end)

	local HalfSparkItem = Item:CreateFromItemID(HalfSparkID)
	HalfSparkItem:ContinueOnItemLoad(function()
		Info.FragName = HalfSparkItem:GetItemName()
		Info.FragTex = HalfSparkItem:GetItemIcon()
	end)

	Info.BaseSparks = 3

	local startDate = time({
		year = 2025,
		month = 3,
		day = 25,
		hour = 10,
		min = 0,
		sec = 0,
	})

	local currentTime = time()

	local dayOfWeek = tonumber(date("%w", startDate))
	local daysToTuesday = (2 - dayOfWeek + 7) % 7
	if daysToTuesday == 0 then
		daysToTuesday = 7
	end

	local firstTuesday = startDate + (daysToTuesday * 86400) -- Still at 10am

	-- Calculate total earned sparks
	local extraHalfSparks = 0

	if currentTime >= firstTuesday then
		local weeksSinceFirstTuesday = math.floor((currentTime - firstTuesday) / 604800)
		local n = weeksSinceFirstTuesday + 1
		extraHalfSparks = 0.5 * n
	end

	Info.TotalAvailableSparks = Info.BaseSparks + extraHalfSparks

	-- Inventory check
	Info.HalvesInHand = C_Item.GetItemCount(HalfSparkID, true)
	Info.FullsInHand = C_Item.GetItemCount(FullSparkID, true)
	Info.SparksInHand = Info.FullsInHand + (Info.HalvesInHand * 0.5)

	Info.SparksUsed = 0

	local twoHandTypes = {
		INVTYPE_2HWEAPON = true,
		INVTYPE_RANGED = true,
	}

	local function checkTooltipLines(lines, itemLink)
		if not lines then
			return
		end

		for _, line in ipairs(lines) do
			if line.leftText and line.leftText:find("Fortune Crafted") then
				local itemName, _, _, _, _, _, _, _, equipSlot = C_Item.GetItemInfo(itemLink)

				if itemName == "Spark of Fortunes" then
					return false
				end

				Info.SparksUsed = Info.SparksUsed + (twoHandTypes[equipSlot] and 2 or 1)
				break
			end
		end
	end

	-- Check equipped items
	for slot = 0, 18 do
		local itemLink = GetInventoryItemLink("player", slot)
		if itemLink then
			local tooltipData = C_TooltipInfo.GetInventoryItem("player", slot)
			checkTooltipLines(tooltipData and tooltipData.lines, itemLink)
		end
	end

	-- Check bag items
	for bag = 0, 6 do
		local numSlots = C_Container.GetContainerNumSlots(bag)
		for slot = 1, numSlots do
			local itemLink = C_Container.GetContainerItemLink(bag, slot)
			if itemLink then
				local tooltipData = C_TooltipInfo.GetBagItem(bag, slot)
				checkTooltipLines(tooltipData and tooltipData.lines, itemLink)
			end
		end
	end

	local BarTotal
	if Info.TotalAvailableSparks % 1 ~= 0 then
		BarTotal = math.floor(Info.TotalAvailableSparks)
	else
		BarTotal = Info.TotalAvailableSparks
	end

	self.Window.Info.Spark.ChargesBar:SetNumThreshold(BarTotal - 1)
	self.Window.Info.Spark.ChargesBar:SetValue(Info.SparksInHand + Info.SparksUsed, BarTotal)
end
