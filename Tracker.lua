local addonName, AMT = ...

local ElvUI = ElvUI
local Details = Details

local AMT_WINDOW_WIDTH = 960
local AMT_WINDOW_HEIGHT
local X_OFFSET = 4
local Y_OFFSET = 22
local BoxSpacing = 3
local BoxSize = 14

function AMT:Initialize()
	if self.Tracker_Initialized then
		return
	end

	self:PrintDebug("Initializing Frames")
	--Tab Button
	self.TabButton = CreateFrame("Button", "AMT_Tab", PVEFrame, "PanelTabButtonTemplate", (PVEFrame.numTabs + 1))
	PanelTemplates_DeselectTab(self.TabButton) --Force newly created button to be deselected
	self.TabButton:SetText("Mythic Tracker")
	self.TabButton:SetScript("OnClick", function()
		AMTWindow_Toggle()
	end)

	--Main Window
	if ElvUI then
		self.Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_ElvUITemplate")
		AMT.S:HandleFrame(self.Window)
		AMT.S:HandleTab(self.TabButton) -- Skin tab with ElvUI
	else
		self.Window = CreateFrame("Frame", "AMT_Window", UIParent, "AMT_Window_RetailTemplate")
	end
	self.Window:SetSize(AMT_WINDOW_WIDTH, PVEFrame:GetHeight())
	AMT_WINDOW_HEIGHT = PVEFrame:GetHeight()
	self.Window:Raise()
	self.Window:SetToplevel(true)
	self.Window:Hide()
	self.Window:SetClampedToScreen(true)
	self.Window:SetMovable(true)
	self.Window:EnableMouse(true)
	self.Window:RegisterForDrag("LeftButton")
	self.Window:SetScript("OnDragStart", function(self, button)
		self:StartMoving()
	end)
	self.Window:SetScript("OnDragStop", function(self, button)
		self:StopMovingOrSizing()
	end)
	self.Window:SetScript("OnShow", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		self:Update_PVEFrame_Panels()
		self:RefreshData()
		self:SetDisplayMode(self.DisplayMode)
	end)

	--Hook PVEFrame
	PVEFrame:HookScript("OnShow", function()
		self:PVEFrameTabNums()
		if ElvUI then
			self.TabButton:SetPoint("LEFT", PVEFrame.Tabs[self.Info.TabNum], "RIGHT", -5, 0)
		else
			self.TabButton:SetPoint("LEFT", PVEFrame.Tabs[self.Info.TabNum], "RIGHT", 3, 0)
		end

		-- Starting at tab 1, whenever each PVEFrame tab is click deselect the AMT Tab Button
		for i = 1, PVEFrame.numTabs do
			local PVEFrame_Tab = _G["PVEFrameTab" .. i]
			PVEFrame_Tab:HookScript("OnClick", function(self, button)
				PanelTemplates_DeselectTab(AMT.TabButton)
			end)
		end
		local selected = PanelTemplates_GetSelectedTab(PVEFrame)
		if selected ~= (PVEFrame.numTabs + 1) then
			PanelTemplates_DeselectTab(self.TabButton)
		end
		self.Window:Hide()
	end)

	--Create AMT Window's Tab Buttons
	self.WindowTab = {}
	for i = 1, #self.AMTFrame_Tabs do
		self.WindowTab[i] = CreateFrame("Button", "AMT_WindowTab" .. i, self.Window, "AMTTabButton")
		if i == 1 then
			self.WindowTab[i]:SetPoint("TOPLEFT", self.Window, "TOPRIGHT", -4, -28)
		else
			self.WindowTab[i]:SetPoint("TOP", self.WindowTab[i - 1], "BOTTOM", 0, -3)
		end
		self.WindowTab[i].name = self.AMTFrame_Tabs[i].name
		self.WindowTab[i].activeAtlas = self.AMTFrame_Tabs[i].activeAtlas
		self.WindowTab[i].inactiveAtlas = self.AMTFrame_Tabs[i].inactiveAtlas
		self.WindowTab[i].DisplayMode = self.AMTFrame_Tabs[i].DisplayMode
		-- self.WindowTab[i].Icon = self.WindowTab[i]:CreateTexture(nil, "ARTWORK")
		self.WindowTab[i].Icon:SetPoint("CENTER", -2, 0)
		self.WindowTab[i].Icon:SetAtlas(self.WindowTab[i].activeAtlas, true)
	end

	self:Framework()
end

function AMT:Framework()
	self:PrintDebug("Building Framework")

	--Set Title
	local expName = _G["EXPANSION_NAME" .. GetExpansionLevel()]
	local title = "Advanced Mythic Tracker (" .. expName .. " Season " .. self.Info.CurrentSeason .. ")"
	AMT_WindowTitleText:SetText(title)

	self.Window.Titles = {
		["Tracker"] = title,
		["Seasonal Info"] = "Seasonal Info",
		["Portals"] = "Dungeon & Raid Portals",
	}

	--Create Tracker Frame
	self.Window.Tracker = CreateFrame("Frame", "AMT_Tracker_Frame", self.Window)
	self.Window.Tracker:SetPoint("CENTER")
	self.Window.Tracker:SetSize(AMT_WINDOW_WIDTH, AMT_WINDOW_HEIGHT)

	--Create Seasonal Info Window
	self.Window.Info = CreateFrame("Frame", "AMT_Info_Container", self.Window)
	self.Window.Info:SetPoint("CENTER")
	self.Window.Info:SetSize(AMT_WINDOW_WIDTH, AMT_WINDOW_HEIGHT)

	--Create Portals Window
	self.Window.Portals = CreateFrame("Frame", "AMT_Portals_Container", self.Window)
	self.Window.Portals:SetPoint("CENTER")
	self.Window.Portals:SetSize(AMT_WINDOW_WIDTH, AMT_WINDOW_HEIGHT)

	--Keystone Frame
	self.Window.Tracker.Keystone = CreateFrame("Frame", "AMT_CurrentKeystone_Frame", self.Window.Tracker)
	self.Window.Tracker.Keystone:SetSize(180, 100)
	self.Window.Tracker.Keystone:SetPoint("TOPLEFT", self.Window, "TOPLEFT", X_OFFSET, -Y_OFFSET)

	self.Window.Tracker.Keystone.icon = CreateFrame("Frame", "AMT_KeystoneItem_Icon", self.Window.Tracker.Keystone)
	self.Window.Tracker.Keystone.icon:SetPoint("TOP", 0, -30)
	self.Window.Tracker.Keystone.icon:SetSize(64, 64)
	self.Window.Tracker.Keystone.icon.tex = self.Window.Tracker.Keystone.icon:CreateTexture()
	self.Window.Tracker.Keystone.icon.tex:SetAllPoints(self.Window.Tracker.Keystone.icon)
	self.Window.Tracker.Keystone.icon.tex:SetTexture(self.Keystone_Icon)

	self.Window.Tracker.Keystone.icon.glow = CreateFrame("Frame", "AMT_KeystoneItem_Glow", self.Window.Tracker.Keystone)
	self.Window.Tracker.Keystone.icon.glow:SetPoint("TOP", 0, -12)
	self.Window.Tracker.Keystone.icon.glow:SetSize(96, 96)
	self.Window.Tracker.Keystone.icon.glow:SetFrameLevel(5)
	self.Window.Tracker.Keystone.icon.glow.tex = self.Window.Tracker.Keystone.icon.glow:CreateTexture()
	self.Window.Tracker.Keystone.icon.glow.tex:SetSize(78, 78)
	self.Window.Tracker.Keystone.icon.glow.tex:SetAllPoints(self.Window.Tracker.Keystone.icon.glow)
	self.Window.Tracker.Keystone.icon.glow.tex:SetAtlas("BattleBar-Button-Highlight")

	self.Window.Tracker.Keystone.bg = CreateFrame("Frame", "AMT_Keystone_DungName_Bg", self.Window.Tracker.Keystone)
	self.Window.Tracker.Keystone.bg:SetPoint("BOTTOM", self.Window.Tracker.Keystone.icon, "TOP", 0, 6)
	self.Window.Tracker.Keystone.bg:SetSize(120, 22) --76
	self.Window.Tracker.Keystone.bg.tex = self.Window.Tracker.Keystone.bg:CreateTexture(nil, "ARTWORK")
	self.Window.Tracker.Keystone.bg.tex:SetAtlas("minortalents-descriptionshadow")
	self.Window.Tracker.Keystone.bg.tex:SetSize(1, 1)
	self.Window.Tracker.Keystone.bg.tex:SetAllPoints(self.Window.Tracker.Keystone.bg)

	self.Window.Tracker.Keystone.name =
		self.Window.Tracker.Keystone.bg:CreateFontString("AMT_Keystone_DungName", "OVERLAY", "MovieSubtitleFont")
	self.Window.Tracker.Keystone.name:SetPoint("CENTER", self.Window.Tracker.Keystone.bg, "CENTER", 0, 0)
	self.Window.Tracker.Keystone.name:SetFont(self.AMT_Font, 14)
	self.Window.Tracker.Keystone.name:SetText("Dungeon Name")

	--M+ Score
	self.Window.Tracker.MplusScore = CreateFrame("Button", "AMT_MythicScore_Container", self.Window.Tracker)
	self.Window.Tracker.MplusScore:SetSize(180, 60)
	self.Window.Tracker.MplusScore:SetPoint("TOP", self.Window, "TOP", 0, -Y_OFFSET)

	self.Window.Tracker.MplusScore.left = CreateFrame("Frame", "MythicScore_LeftDragon", self.Window.Tracker.MplusScore)
	self.Window.Tracker.MplusScore.left:SetPoint("RIGHT", self.Window.Tracker.MplusScore, "LEFT", 20, 10)
	self.Window.Tracker.MplusScore.left:SetSize(80, 37)
	self.Window.Tracker.MplusScore.left.tex = self.Window.Tracker.MplusScore.left:CreateTexture()
	self.Window.Tracker.MplusScore.left.tex:SetAllPoints(self.Window.Tracker.MplusScore.left)
	self.Window.Tracker.MplusScore.left.tex:SetAtlas("Dragonflight-DragonHeadLeft", false)

	self.Window.Tracker.MplusScore.right =
		CreateFrame("Frame", "MythicScore_LeftDragon", self.Window.Tracker.MplusScore)
	self.Window.Tracker.MplusScore.right:SetPoint("LEFT", self.Window.Tracker.MplusScore, "RIGHT", -20, 10)
	self.Window.Tracker.MplusScore.right:SetSize(80, 37)
	self.Window.Tracker.MplusScore.right.tex = self.Window.Tracker.MplusScore.right:CreateTexture()
	self.Window.Tracker.MplusScore.right.tex:SetAllPoints(self.Window.Tracker.MplusScore.right)
	self.Window.Tracker.MplusScore.right.tex:SetAtlas("Dragonflight-DragonHeadLeft", false)
	self.Window.Tracker.MplusScore.right.tex:SetTexCoord(1, 0, 0, 1)

	self.Window.Tracker.MplusScore.label =
		self.Window.Tracker.MplusScore:CreateFontString(nil, "OVERLAY", "GameFontWhite")
	self.Window.Tracker.MplusScore.label:SetPoint("TOP", 0, -4)
	self.Window.Tracker.MplusScore.label:SetText("Mythic+ Rating")
	self.Window.Tracker.MplusScore.label:SetFont(self.AMT_Font, 20)
	self.Window.Tracker.MplusScore.label:SetTextColor(1, 1, 1, 1.0)

	self.Window.Tracker.MplusScore.score =
		self.Window.Tracker.MplusScore:CreateFontString("MythicScore_Label", "OVERLAY", "GameFontNormal")
	self.Window.Tracker.MplusScore.score:SetPoint("TOP", self.Window.Tracker.MplusScore.label, "BOTTOM", 0, -4)
	self.Window.Tracker.MplusScore.score:SetText(self.Info.MplusSummary.currentSeasonScore)
	self.Window.Tracker.MplusScore.score:SetFont(self.AMT_Font, 28)

	--Blizzard's hover tooltip
	self.Window.Tracker.MplusScore:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self.Window.Tracker.MplusScore, "ANCHOR_RIGHT", 0, 0)
		GameTooltip_SetTitle(GameTooltip, DUNGEON_SCORE)
		GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_DESC)
		GameTooltip:Show()
	end)
	self.Window.Tracker.MplusScore:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	--Blizzard's Chat Score Link
	self.Window.Tracker.MplusScore:SetScript("OnClick", function()
		if IsModifiedClick("CHATLINK") then
			local dungeonScore = C_ChallengeMode.GetOverallDungeonScore()
			local link = GetDungeonScoreLink(dungeonScore, UnitName("player"))
			if not ChatEdit_InsertLink(link) then
				ChatFrame_OpenChat(link)
			end
		end
	end)

	--Seasonal Dungeons
	self.Window.Tracker.Dungeons = CreateFrame("Frame", "AMT_DungeonIcons_Container", self.Window.Tracker)
	self.Window.Tracker.Dungeons:SetPoint("BOTTOMLEFT", self.Window, "BOTTOMLEFT", X_OFFSET + 2, 4)
	if ElvUI then
		self.Window.Tracker.Dungeons:SetSize(AMT_WINDOW_WIDTH - (X_OFFSET - 2) * 5, 80)
	else
		self.Window.Tracker.Dungeons:SetSize(AMT_WINDOW_WIDTH - (X_OFFSET - 2) * 4, 80)
	end

	self.Window.Tracker.Dungeons.Icon = {}
	self.Window.Tracker.Dungeons.Text = {}

	for i = 1, #self.Info.SeasonDungeons do
		local DungIconWidth = self.Window.Tracker.Dungeons:GetWidth() / 8
		local DungIconHeight = self.Window.Tracker.Dungeons:GetHeight()
		local DungIconAspectRatio = DungIconWidth / DungIconHeight
		local DungIconSize = math.max(DungIconHeight, DungIconWidth)
		local DungIconMargin = (DungIconSize - math.min(DungIconHeight, DungIconWidth)) / 2
		local DungIconCrop = DungIconMargin / DungIconSize

		self.Window.Tracker.Dungeons.Icon[i] =
			CreateFrame("Button", "AMT_DungeonIcon_" .. i, self.Window.Tracker.Dungeons, "InsecureActionButtonTemplate")
		self.Window.Tracker.Dungeons.Icon[i]:SetSize(DungIconWidth, DungIconHeight)
		self.Window.Tracker.Dungeons.Icon[i].tex = self.Window.Tracker.Dungeons.Icon[i]:CreateTexture(nil, "BACKGROUND")
		self.Window.Tracker.Dungeons.Icon[i].tex:SetTexture(self.Info.SeasonDungeons[i].dungIcon)
		if DungIconAspectRatio > 1 then
			self.Window.Tracker.Dungeons.Icon[i].tex:SetTexCoord(0, 1, DungIconCrop, 1 - DungIconCrop)
		elseif DungIconAspectRatio < 1 then
			self.Window.Tracker.Dungeons.Icon[i].tex:SetTexCoord(DungIconCrop, 1 - DungIconCrop, 0, 1)
		end
		self.Window.Tracker.Dungeons.Icon[i].tex:SetSize(DungIconSize, DungIconSize)
		self.Window.Tracker.Dungeons.Icon[i].tex:ClearAllPoints()
		self.Window.Tracker.Dungeons.Icon[i].tex:SetAllPoints(self.Window.Tracker.Dungeons.Icon[i])

		if i == 1 then
			self.Window.Tracker.Dungeons.Icon[i]:SetPoint(
				"BOTTOMLEFT",
				self.Window.Tracker.Dungeons,
				"BOTTOMLEFT",
				0,
				0
			)
		else
			local previousBox = self.Window.Tracker.Dungeons.Icon[i - 1]
			self.Window.Tracker.Dungeons.Icon[i]:SetPoint("LEFT", previousBox, "RIGHT", 0, 0)
		end

		-- Create Labels over the Dungeon Icons
		local CurrentmapID = self.Info.SeasonDungeons[i].mapID
		local DungIcon_Abbr = nil
		local DungName = self.Info.SeasonDungeons[i].dungName
		local Dung_Score = self.Info.SeasonDungeons[i].dungeonScore
		local Dung_Level = self.Info.SeasonDungeons[i].dungeonLevel
		local DungScore_Color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(Dung_Score)
		local affixScores, _ = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(self.Info.SeasonDungeons[i].mapID)
		local dungSpellID
		local dungSpellName

		for _, dungeon in ipairs(self.SeasonalDungeons) do
			if dungeon.mapID == self.Info.SeasonDungeons[i].mapID then
				if type(dungeon.spellID) == "table" then
					for _, id in ipairs(dungeon.spellID) do
						dungSpellID = id
						dungSpellName = C_Spell.GetSpellName(dungSpellID)
						if IsPlayerSpell(dungSpellID) then -- potentially to be used to break when matched
							break
						end
					end
				else
					dungSpellID = dungeon.spellID
					dungSpellName = C_Spell.GetSpellName(dungSpellID)
				end
				break
			end
		end
		for j = 1, #self.SeasonalDungeons do
			if self.SeasonalDungeons[j].mapID == CurrentmapID then
				DungIcon_Abbr = self.SeasonalDungeons[j].abbr
				break
			end
		end

		self.Window.Tracker.Dungeons.Icon[i].label =
			self.Window.Tracker.Dungeons.Icon[i]:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline22")
		self.Window.Tracker.Dungeons.Icon[i].label:SetPoint("TOP", self.Window.Tracker.Dungeons.Icon[i], "TOP", 0, 0)
		self.Window.Tracker.Dungeons.Icon[i].label:SetFont(self.AMT_Font, 20, "OUTLINE")
		self.Window.Tracker.Dungeons.Icon[i].label:SetTextColor(1, 1, 1)
		self.Window.Tracker.Dungeons.Icon[i].label:SetText(DungIcon_Abbr)
		self.Window.Tracker.Dungeons.Icon[i].level = self.Window.Tracker.Dungeons.Icon[i]:CreateFontString(
			"AMT_DungWeekLevel_Label" .. i,
			"OVERLAY",
			"GameFontHighlightOutline22"
		)
		self.Window.Tracker.Dungeons.Icon[i].level:SetPoint(
			"CENTER",
			self.Window.Tracker.Dungeons.Icon[i],
			"CENTER",
			0,
			2
		)
		self.Window.Tracker.Dungeons.Icon[i].level:SetFont(self.AMT_Font, 32, "OUTLINE")
		self.Window.Tracker.Dungeons.Icon[i].level:SetText(Dung_Level)
		self.Window.Tracker.Dungeons.Icon[i].level:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)

		self.Window.Tracker.Dungeons.Icon[i].score = self.Window.Tracker.Dungeons.Icon[i]:CreateFontString(
			"AMT_DungWeekScore_Label" .. i,
			"OVERLAY",
			"GameFontHighlightOutline22"
		)
		self.Window.Tracker.Dungeons.Icon[i].score:SetPoint(
			"BOTTOM",
			self.Window.Tracker.Dungeons.Icon[i],
			"BOTTOM",
			0,
			4
		)
		self.Window.Tracker.Dungeons.Icon[i].score:SetFont(self.AMT_Font, 18, "OUTLINE")
		self.Window.Tracker.Dungeons.Icon[i].score:SetText(Dung_Score)
		self.Window.Tracker.Dungeons.Icon[i].score:SetTextColor(DungScore_Color.r, DungScore_Color.g, DungScore_Color.b)

		self.Window.Tracker.Dungeons.Icon[i]:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(self.Window.Tracker.Dungeons.Icon[i], "ANCHOR_RIGHT")
			GameTooltip:SetText(DungName, 1, 1, 1, 1, true)

			if Dung_Score then
				local color = C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor(Dung_Score)
				if not color then
					color = HIGHLIGHT_FONT_COLOR
				end
				GameTooltip_AddNormalLine(
					GameTooltip,
					DUNGEON_SCORE_TOTAL_SCORE:format(color:WrapTextInColorCode(Dung_Score)),
					GREEN_FONT_COLOR
				)
			end

			if affixScores and #affixScores > 0 then
				for _, affixInfo in ipairs(affixScores) do
					GameTooltip_AddBlankLineToTooltip(GameTooltip)
					GameTooltip_AddNormalLine(GameTooltip, DUNGEON_SCORE_BEST_AFFIX:format(affixInfo.name))
					GameTooltip_AddColoredLine(
						GameTooltip,
						MYTHIC_PLUS_POWER_LEVEL:format(affixInfo.level),
						HIGHLIGHT_FONT_COLOR
					)
					if affixInfo.overTime then
						if affixInfo.durationSec >= SECONDS_PER_HOUR then
							GameTooltip_AddColoredLine(
								GameTooltip,
								DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(affixInfo.durationSec, true)),
								LIGHTGRAY_FONT_COLOR
							)
						else
							GameTooltip_AddColoredLine(
								GameTooltip,
								DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(affixInfo.durationSec, false)),
								LIGHTGRAY_FONT_COLOR
							)
						end
					else
						if affixInfo.durationSec >= SECONDS_PER_HOUR then
							GameTooltip_AddColoredLine(
								GameTooltip,
								SecondsToClock(affixInfo.durationSec, true),
								HIGHLIGHT_FONT_COLOR
							)
						else
							GameTooltip_AddColoredLine(
								GameTooltip,
								SecondsToClock(affixInfo.durationSec, false),
								HIGHLIGHT_FONT_COLOR
							)
						end
					end
				end
			end
			if IsSpellKnown(dungSpellID, false) then
				local spellCooldownInfo = C_Spell.GetSpellCooldown(dungSpellID)

				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)

				if not spellCooldownInfo.startTime or not spellCooldownInfo.duration then
					GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
				elseif spellCooldownInfo.duration == 0 then
					GameTooltip:AddLine(READY, 0, 1, 0)
				else
					GameTooltip:AddLine(
						SecondsToTime(ceil(spellCooldownInfo.startTime + spellCooldownInfo.duration - GetTime())),
						1,
						0,
						0
					)
				end
			else
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(dungSpellName or TELEPORT_TO_DUNGEON)
				GameTooltip:AddLine(SPELL_FAILED_NOT_KNOWN, 1, 0, 0)
			end
			GameTooltip:Show()
		end)
		self.Window.Tracker.Dungeons.Icon[i]:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		self.Window.Tracker.Dungeons.Icon[i]:RegisterForClicks("AnyUp", "AnyDown")
		self.Window.Tracker.Dungeons.Icon[i]:SetAttribute("type1", "spell")
		self.Window.Tracker.Dungeons.Icon[i]:SetAttribute("spell", dungSpellName)
	end

	--Affixes
	local AffixIconSize = 34
	local AffixIconPadding = 14
	self.Window.Tracker.Affix = CreateFrame("Frame", "AMT_Affixes_Compartment", self.Window.Tracker)
	self.Window.Tracker.Affix:SetSize(200, 150)
	self.Window.Tracker.Affix:SetPoint("TOPRIGHT", self.Window, "TOPRIGHT", -X_OFFSET, -Y_OFFSET)

	self.Window.Tracker.Affix.Current = CreateFrame("Frame", "AMT_CurrentAffixes_Container", self.Window.Tracker.Affix)
	self.Window.Tracker.Affix.Current:SetSize(self.Window.Tracker.Affix:GetWidth(), 50)

	self.Window.Tracker.Affix.Current.label =
		self.Window.Tracker.Affix:CreateFontString("AMT_CurrentAffixes_Label", "OVERLAY", "GameFontHighlightOutline22")
	self.Window.Tracker.Affix.Current.label:SetPoint("TOPLEFT", 2, -2)
	self.Window.Tracker.Affix.Current.label:SetText("This Week")
	self.Window.Tracker.Affix.Current.label:SetFont(self.AMT_Font, 20)
	self.Window.Tracker.Affix.Current.label:SetTextColor(1, 1, 1, 1.0)

	self.Window.Tracker.Affix.Current:SetPoint(
		"TOP",
		self.Window.Tracker.Affix,
		"TOP",
		0,
		-self.Window.Tracker.Affix.Current.label:GetHeight()
	)

	self.Window.Tracker.Affix.Next =
		CreateFrame("Frame", "AMT_NextWeekAffixes_Container", self.Window.Tracker.Affix, "BackdropTemplate")
	self.Window.Tracker.Affix.Next:SetSize(
		self.Window.Tracker.Affix:GetWidth(),
		self.Window.Tracker.Affix.Current:GetHeight()
	)

	self.Window.Tracker.Affix.Next.label =
		self.Window.Tracker.Affix:CreateFontString("AMT_NextWeekAffixes_Label", "OVERLAY", "GameFontHighlightOutline22")
	self.Window.Tracker.Affix.Next.label:SetPoint("TOPLEFT", self.Window.Tracker.Affix.Current, "BOTTOMLEFT", 2, -4)
	self.Window.Tracker.Affix.Next.label:SetText("Next Week")
	self.Window.Tracker.Affix.Next.label:SetFont(self.AMT_Font, 20)
	self.Window.Tracker.Affix.Next.label:SetTextColor(1, 1, 1, 1.0)

	local _, _, _, _, NextWeekAffixes_Label_y = self.Window.Tracker.Affix.Next.label:GetPoint()
	self.Window.Tracker.Affix.Next:SetPoint(
		"TOP",
		self.Window.Tracker.Affix.Current,
		"BOTTOM",
		0,
		-NextWeekAffixes_Label_y - self.Window.Tracker.Affix.Next.label:GetHeight() - 6
	)
	for i = 1, #self.Info.Affix.Current do
		-- for _, affixID in ipairs(self.Info.Affix.Current) do
		-- local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])
		local name, description, filedataid = C_ChallengeMode.GetAffixInfo(self.Info.Affix.Current[i])
		local AffixIcon = {}
		AffixIcon[i] = CreateFrame("Frame", "AMT_CurrentAffixIcon" .. i, self.Window.Tracker.Affix.Current)
		AffixIcon[i]:SetSize(AffixIconSize, AffixIconSize)
		AffixIcon[i].tex = AffixIcon[i]:CreateTexture()
		AffixIcon[i].tex:SetAllPoints(AffixIcon[i])
		AffixIcon[i].tex:SetTexture(filedataid)
		AffixIcon[i].tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		if i == 1 then
			AffixIcon[i]:SetPoint(
				"LEFT",
				self.Window.Tracker.Affix.Current,
				"LEFT",
				(
					AffixIcon[i]:GetParent():GetWidth()
					- (AffixIconSize * #self.Info.Affix.Table)
					- (AffixIconPadding * (#self.Info.Affix.Table - 1))
				) / 2,
				0
			)
		else
			AffixIcon[i]:SetPoint("LEFT", _G["AMT_CurrentAffixIcon" .. i - 1], "RIGHT", AffixIconPadding, 0)
		end
		AffixIcon[i]:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(_G["AMT_CurrentAffixIcon" .. i], "ANCHOR_RIGHT")
			GameTooltip:SetText(name, 1, 1, 1, 1, true)
			GameTooltip:AddLine(description, nil, nil, nil, true)
			GameTooltip:Show()
		end)
		AffixIcon[i]:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		-- end
	end

	for i = 1, #self.Info.Affix.Table do
		for _, affixID in ipairs(self.Info.Affix.Next) do
			local name, description, filedataid = C_ChallengeMode.GetAffixInfo(affixID[i])
			local AffixIcon = {}
			AffixIcon[i] = CreateFrame("Frame", "AMT_NexWeek_AffixIcon" .. i, self.Window.Tracker.Affix.Next)
			AffixIcon[i]:SetSize(AffixIconSize, AffixIconSize)
			AffixIcon[i].tex = AffixIcon[i]:CreateTexture()
			AffixIcon[i].tex:SetAllPoints(AffixIcon[i])
			AffixIcon[i].tex:SetTexture(filedataid)
			AffixIcon[i].tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			if i == 1 then
				AffixIcon[i]:SetPoint(
					"LEFT",
					self.Window.Tracker.Affix.Next,
					"LEFT",
					(
						AffixIcon[i]:GetParent():GetWidth()
						- (AffixIconSize * #self.Info.Affix.Table)
						- (AffixIconPadding * (#self.Info.Affix.Table - 1))
					) / 2,
					0
				)
			else
				AffixIcon[i]:SetPoint("LEFT", _G["AMT_NexWeek_AffixIcon" .. i - 1], "RIGHT", AffixIconPadding, 0)
			end
			AffixIcon[i]:SetScript("OnEnter", function()
				GameTooltip:ClearAllPoints()
				GameTooltip:ClearLines()
				GameTooltip:SetOwner(_G["AMT_NexWeek_AffixIcon" .. i], "ANCHOR_RIGHT")
				GameTooltip:SetText(name, 1, 1, 1, 1, true)
				GameTooltip:AddLine(description, nil, nil, nil, true)
				GameTooltip:Show()
			end)
			AffixIcon[i]:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
	end

	--Party Keystones
	self.Window.Tracker.PartyKeys = CreateFrame("Frame", "AMT_PartyKeystone_Container", self.Window.Tracker)
	self.Window.Tracker.PartyKeys:SetSize(
		200,
		PVEFrame:GetHeight()
			- Y_OFFSET
			- self.Window.Tracker.Affix:GetHeight()
			- self.Window.Tracker.Dungeons:GetHeight()
			- 12
	)
	if ElvUI then
		self.Window.Tracker.PartyKeys:SetTemplate("Transparent")
	else
		self.Window.Tracker.PartyKeys.tex = self.Window.Tracker.PartyKeys:CreateTexture()
		self.Window.Tracker.PartyKeys.tex:SetAllPoints(self.Window.Tracker.PartyKeys)
		self.Window.Tracker.PartyKeys.tex:SetColorTexture(unpack(self.BackgroundDark))
	end
	self.Window.Tracker.PartyKeys:SetPoint("TOPRIGHT", self.Window.Tracker.Affix, "BOTTOMRIGHT", 0, 0)

	self.Window.Tracker.PartyKeys.title =
		self.Window.Tracker.PartyKeys:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.Window.Tracker.PartyKeys.title:SetPoint("TOPLEFT", self.Window.Tracker.PartyKeys, "TOPLEFT", 6, -6)
	self.Window.Tracker.PartyKeys.title:SetJustifyH("LEFT")
	self.Window.Tracker.PartyKeys.title:SetFont(self.AMT_Font, 14)
	self.Window.Tracker.PartyKeys.title:SetText("Party Keystones")

	if Details then
		self.Window.Tracker.PartyKeys.details = AMT_CreateBorderButton(
			self.Window.Tracker.PartyKeys,
			"AMT_PartyKeystone_DetailsButton",
			"TOPRIGHT",
			self.Window.Tracker.PartyKeys,
			"TOPRIGHT",
			-4,
			-4,
			16,
			16,
			"!"
		)
		self.Window.Tracker.PartyKeys.details:SetScript("OnClick", function()
			if _G.SlashCmdList["KEYSTONE"] then
				_G.SlashCmdList["KEYSTONE"]("")
			end
		end)

		self.Window.Tracker.PartyKeys.refresh = AMT_CreateBorderButton(
			self.Window.Tracker.PartyKeys,
			"AMT_PartyKeystone_RefreshButton",
			"RIGHT",
			self.Window.Tracker.PartyKeys.details,
			"LEFT",
			-4,
			0,
			50,
			16,
			"Refresh"
		)
		self.Window.Tracker.PartyKeys.refresh:SetScript("OnClick", function()
			self:PartyKeystone_RefreshRequest()
		end)

		self.Window.Tracker.PartyKeys.roll = AMT_CreateBorderButton(
			self.Window.Tracker.PartyKeys,
			"AMT_PartyKeystone_RollButton",
			"BOTTOM",
			self.Window.Tracker.PartyKeys,
			"BOTTOM",
			0,
			3,
			90,
			16,
			"Random Key"
		)

		self.Window.Tracker.PartyKeys.roll:SetScript("OnClick", function()
			if
				IsInGroup()
				and not IsInRaid()
				and self.Window.Tracker.PartyKeys.Group
				and #self.Window.Tracker.PartyKeys.Group > 0
			then
				AMT:PartyKeystone_RandomPicker()
			else
				print("|cff18a8ffAMT|r: Must be in a group with multiple keystones to roll")
			end
		end)

		self.Window.Tracker.PartyKeys.lines = {}
		for i = 1, 5 do
			local Y_OFFSET = -23
			local PartyKeystone_Rightext = self.Window.Tracker.PartyKeys:CreateFontString(
				"AMT_PartyKeystyone_Right" .. i,
				"OVERLAY",
				"GameFontNormalWTF2"
			)
			PartyKeystone_Rightext:SetPoint("TOPRIGHT", self.Window.Tracker.PartyKeys, "TOPRIGHT", -6, Y_OFFSET * i - 2)
			PartyKeystone_Rightext:SetJustifyH("RIGHT")
			PartyKeystone_Rightext:SetWidth(100)
			PartyKeystone_Rightext:SetFont(self.AMT_Font, 14)
			PartyKeystone_Rightext:SetText("")

			PartyKeystone_Lefttext = self.Window.Tracker.PartyKeys:CreateFontString(
				"AMT_PartyKeystyone_Left" .. i,
				"OVERLAY",
				"GameFontNormalWTF2"
			)
			PartyKeystone_Lefttext:SetPoint("TOPLEFT", self.Window.Tracker.PartyKeys, "TOPLEFT", 6, Y_OFFSET * i)
			PartyKeystone_Lefttext:SetJustifyH("LEFT")
			PartyKeystone_Lefttext:SetWidth(100)
			PartyKeystone_Lefttext:SetFont(self.AMT_Font, 14)
			PartyKeystone_Lefttext:SetText("")
			self.Window.Tracker.PartyKeys.lines[i] = {
				left = PartyKeystone_Lefttext,
				right = PartyKeystone_Rightext,
			}
		end
	else
		self.Window.Tracker.PartyKeys.missing =
			CreateFrame("Frame", "AMT_PartyKeystyone_MissingDetails", self.Window.Tracker.PartyKeys)
		self.Window.Tracker.PartyKeys.missing:SetPoint("TOPRIGHT", self.Window.Tracker.PartyKeys, "TOPRIGHT", -4, -4)
		self.Window.Tracker.PartyKeys.missing:SetSize(24, 24)
		self.Window.Tracker.PartyKeys.missing.tex = self.Window.Tracker.PartyKeys.missing:CreateTexture()
		self.Window.Tracker.PartyKeys.missing.tex:SetAllPoints(self.Window.Tracker.PartyKeys.missing)
		self.Window.Tracker.PartyKeys.missing.tex:SetAtlas("Campaign-QuestLog-LoreBook-Back", false)

		self.Window.Tracker.PartyKeys.missing:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(self.Window.Tracker.PartyKeys.missing, "ANCHOR_RIGHT", 0, 0)
			GameTooltip:SetText("Details! Missing", 1, 1, 1, 1)
			GameTooltip:AddLine("To see a list of your group's Keystones,\ninstall/enable Details!.", true)
			GameTooltip:Show()
		end)
		self.Window.Tracker.PartyKeys.missing:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	--Weekly Lockouts

	local Raid_BoxMargin
	self.Window.Tracker.Weekly = CreateFrame("Frame", "AMT_Lockouts_Comparment", self.Window.Tracker)
	self.Window.Tracker.Weekly:SetSize(
		180,
		self.Window:GetHeight()
			- Y_OFFSET
			- self.Window.Tracker.Keystone:GetHeight()
			- self.Window.Tracker.Keystone:GetHeight()
	)
	self.Window.Tracker.Weekly:SetPoint("TOP", self.Window.Tracker.Keystone, "BOTTOM", 0, 0)

	--Raid
	self.Window.Tracker.Weekly.RaidHeader = AMT_CreateHeader(
		self.Window.Tracker.Weekly,
		"AMT_Raid_Goals_Header",
		"TOP",
		self.Window.Tracker.Weekly,
		"TOP",
		0,
		-2,
		180,
		18,
		"Raid"
	)

	self.Window.Tracker.Weekly.Raid = {
		frame = {
			box = {},
		},
	}
	for i, difficulty in ipairs(self.RaidDifficulty_Levels) do
		self.Window.Tracker.Weekly.Raid[i] = CreateFrame("Frame", "AMT_RaidDifficulty" .. i, self.Window.Tracker.Weekly)
		self.Window.Tracker.Weekly.Raid[i]:SetSize(180, 20)
		self.Window.Tracker.Weekly.Raid[i].tex = self.Window.Tracker.Weekly.Raid[i]:CreateTexture()
		self.Window.Tracker.Weekly.Raid[i].tex:SetAllPoints(self.Window.Tracker.Weekly.Raid[i])
		self.Window.Tracker.Weekly.Raid[i].tex:SetColorTexture(unpack(self.BackgroundClear))

		self.Window.Tracker.Weekly.Raid[i].frame =
			CreateFrame("Frame", "AMT_Raid_MainFrame_BoxFrame" .. i, self.Window.Tracker.Weekly.Raid[i])
		self.Window.Tracker.Weekly.Raid[i].frame:SetSize(180, 22)
		self.Window.Tracker.Weekly.Raid[i].frame:SetPoint("CENTER", self.Window.Tracker.Weekly.Raid[i], "CENTER", 0, 0)

		if i == 1 then
			self.Window.Tracker.Weekly.Raid[i]:SetPoint(
				"TOPLEFT",
				self.Window.Tracker.Weekly.RaidHeader,
				"BOTTOMLEFT",
				4,
				4
			)
		else
			local previousFrame = self.Window.Tracker.Weekly.Raid[i - 1]
			self.Window.Tracker.Weekly.Raid[i]:SetPoint("TOP", previousFrame, "BOTTOM", 0, 0)
		end

		Raid_BoxMargin = (
			self.Window.Tracker.Weekly.Raid[1]:GetWidth() - ((BoxSize * self.RaidReq) + (3 * (self.RaidReq - 1)))
		) / 2

		self.Window.Tracker.Weekly.Raid[i].frame.label =
			CreateFrame("Frame", "AMT_Raid_MainFrame_Label" .. i, self.Window.Tracker.Weekly.Raid[i])
		self.Window.Tracker.Weekly.Raid[i].frame.label:SetSize(42, 22)
		self.Window.Tracker.Weekly.Raid[i].frame.label:SetPoint(
			"RIGHT",
			_G["AMT_Raid_MainFrame_BoxFrame" .. i],
			"LEFT",
			Raid_BoxMargin,
			0
		)

		self.Window.Tracker.Weekly.Raid[i].frame.label.text =
			self.Window.Tracker.Weekly.Raid[i].frame.label:CreateFontString(
				"AMT_RaidDifficulty_Label" .. i,
				"OVERLAY",
				"MovieSubtitleFont"
			)
		self.Window.Tracker.Weekly.Raid[i].frame.label.text:SetPoint(
			"RIGHT",
			self.Window.Tracker.Weekly.Raid[i].frame.label,
			"RIGHT",
			-4,
			0
		)
		self.Window.Tracker.Weekly.Raid[i].frame.label.text:SetText("|cffffffff" .. difficulty.abbr)
		self.Window.Tracker.Weekly.Raid[i].frame.label.text:SetFont(self.AMT_Font, 12)
		self.Window.Tracker.Weekly.Raid[i].frame.label.text:SetJustifyH("RIGHT")
		self.Window.Tracker.Weekly.Raid[i].frame.label.text:SetJustifyV("MIDDLE")

		self.Window.Tracker.Weekly.Raid[i]:SetScript("OnEnter", function()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(self.Window.Tracker.Weekly.Raid[i], "ANCHOR_RIGHT")
			GameTooltip:SetText(difficulty.name .. " Progress", 1, 1, 1, 1, true)
			local Raid_LockoutInfo = AMT:Filter_LockedBosses(self.Info.SeasonRaids, difficulty.abbr)
			local lastInstanceID
			for index, encounter in ipairs(self.Info.RaidBosses_Vault) do
				local name, description, encounterID, rootSectionID, link, instanceID =
					EJ_GetEncounterInfo(encounter.encounterID)
				if instanceID ~= lastInstanceID then
					local instanceName = EJ_GetInstanceInfo(instanceID)
					for _, raid in ipairs(self.Info.SeasonRaids) do
						if string.lower(instanceName) == string.lower(raid.name) then
							for difficultyKey, diff in pairs(raid.difficulty) do
								if difficulty.abbr == difficultyKey and diff.reset and diff.reset ~= 0 then
									GameTooltip:AddLine(format("Expires: |cffffffff%s|r", date("%c", diff.reset)))
								end
							end
						end
					end
					GameTooltip_AddBlankLineToTooltip(GameTooltip)
					GameTooltip:AddLine(instanceName)
					lastInstanceID = instanceID
				end
				if name then
					local name_corrected
					if name == "The One-Armed Bandit" then
						name_corrected = "One-Armed Bandit"
					else
						name_corrected = name
					end
					local killed = AMT:Check_BossLockout(Raid_LockoutInfo, name_corrected)
					if killed then
						GameTooltip_AddColoredLine(GameTooltip, string.format(DASH_WITH_TEXT, name), GREEN_FONT_COLOR)
					else
						GameTooltip_AddColoredLine(
							GameTooltip,
							string.format(DASH_WITH_TEXT, name),
							DISABLED_FONT_COLOR
						)
					end
				end
			end

			--
			GameTooltip:Show()
			self.Window.Tracker.Weekly.Raid[i].tex:SetColorTexture(unpack(self.BackgroundHover))
		end)
		self.Window.Tracker.Weekly.Raid[i]:SetScript("OnLeave", function()
			GameTooltip:Hide()
			self.Window.Tracker.Weekly.Raid[i].tex:SetColorTexture(unpack(self.BackgroundClear))
		end)
	end

	for i, difficulty in ipairs(self.RaidDifficulty_Levels) do
		local DifficultyName = difficulty.abbr

		if not self.Window.Tracker.Weekly.Raid[i].frame.box then
			self.Window.Tracker.Weekly.Raid[i].frame.box = {}
		end

		for n = 1, self.RaidReq do
			-- Create the box if it doesn't exist
			if not self.Window.Tracker.Weekly.Raid[i].frame.box[n] then
				self.Window.Tracker.Weekly.Raid[i].frame.box[n] =
					CreateFrame("Frame", "AMT_" .. DifficultyName .. n, self.Window.Tracker.Weekly.Raid[i])
			end

			-- Set the size and texture for the box
			self.Window.Tracker.Weekly.Raid[i].frame.box[n]:SetSize(BoxSize, BoxSize)
			self.Window.Tracker.Weekly.Raid[i].frame.box[n].tex = self.Window.Tracker.Weekly.Raid[i].frame.box[n].tex
				or self.Window.Tracker.Weekly.Raid[i].frame.box[n]:CreateTexture()
			self.Window.Tracker.Weekly.Raid[i].frame.box[n].tex:SetAllPoints(
				self.Window.Tracker.Weekly.Raid[i].frame.box[n]
			)
			self.Window.Tracker.Weekly.Raid[i].frame.box[n].tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

			-- Position the box
			if n == 1 then
				self.Window.Tracker.Weekly.Raid[i].frame.box[n]:SetPoint(
					"LEFT",
					_G["AMT_Raid_MainFrame_BoxFrame" .. i],
					"LEFT",
					Raid_BoxMargin,
					0
				)
			else
				local previousBox = _G["AMT_" .. DifficultyName .. (n - 1)]
				self.Window.Tracker.Weekly.Raid[i].frame.box[n]:SetPoint("LEFT", previousBox, "RIGHT", BoxSpacing, 0)
			end
		end
	end

	--Mythic+
	self.Window.Tracker.Weekly.MplusHeader = AMT_CreateHeader(
		self.Window.Tracker.Weekly,
		"AMT_Mplus_Goals_Header",
		"TOP",
		self.Window.Tracker.Weekly.Raid[4],
		"BOTTOM",
		0,
		0,
		180,
		18,
		"Mythic+"
	)

	self.Window.Tracker.Weekly.Mplus = CreateFrame("Frame", "AMT_Mplus_Mainframe", self.Window.Tracker.Weekly)
	self.Window.Tracker.Weekly.Mplus:SetSize(180, 22)
	self.Window.Tracker.Weekly.Mplus:SetPoint("TOPLEFT", self.Window.Tracker.Weekly.MplusHeader, "BOTTOMLEFT", 0, 0)
	self.Window.Tracker.Weekly.Mplus.tex = self.Window.Tracker.Weekly.Mplus:CreateTexture()
	self.Window.Tracker.Weekly.Mplus.tex:SetAllPoints(self.Window.Tracker.Weekly.Mplus)
	self.Window.Tracker.Weekly.Mplus.tex:SetColorTexture(unpack(self.BackgroundClear))

	self.Window.Tracker.Weekly.Mplus.frame =
		CreateFrame("Frame", "AMT_Mplus_MainFrame_BoxFrame", self.Window.Tracker.Weekly.Mplus)
	self.Window.Tracker.Weekly.Mplus.frame:SetSize(180, 22)
	self.Window.Tracker.Weekly.Mplus.frame:SetPoint("CENTER", self.Window.Tracker.Weekly.Mplus, "CENTER", 0, 0)
	self.Window.Tracker.Weekly.Mplus.frame.tex = self.Window.Tracker.Weekly.Mplus.frame:CreateTexture()
	self.Window.Tracker.Weekly.Mplus.frame.tex:SetAllPoints(self.Window.Tracker.Weekly.Mplus.frame)
	self.Window.Tracker.Weekly.Mplus.frame.tex:SetColorTexture(unpack(self.BackgroundClear))

	self.Window.Tracker.Weekly.Mplus:SetScript("OnEnter", function()
		GameTooltip:ClearAllPoints()
		GameTooltip:ClearLines()
		GameTooltip:SetOwner(self.Window.Tracker.Weekly.Mplus, "ANCHOR_RIGHT")
		GameTooltip:SetText("Mythic Plus Progress", 1, 1, 1, 1, true)
		if self.Info.KeysDone[1] ~= 0 then
			GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", #self.Info.KeysDone))
		else
			GameTooltip:AddLine(format("Number of keys done this week: |cffffffff%s|r", 0))
		end
		if self.Info.KeysDone[1] ~= 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Top 8 Runs This Week")
			for i = 1, 8 do
				if self.Info.KeysDone[i] and (i == 1 or i == 4 or i == 8) then
					GameTooltip:AddLine(
						"|cff00ff12" .. self.Info.KeysDone[i].level .. " - " .. self.Info.KeysDone[i].keyname
					)
				elseif self.Info.KeysDone[i] then
					GameTooltip:AddLine(
						"|cffffffff" .. self.Info.KeysDone[i].level .. " - " .. self.Info.KeysDone[i].keyname
					)
				end
			end
		end
		self.Window.Tracker.Weekly.Mplus.tex:SetColorTexture(unpack(self.BackgroundHover))
		GameTooltip:Show()
	end)
	self.Window.Tracker.Weekly.Mplus:SetScript("OnLeave", function()
		GameTooltip:Hide()
		self.Window.Tracker.Weekly.Mplus.tex:SetColorTexture(unpack(self.BackgroundClear))
	end)

	local Mplus_BoxMargin = (
		self.Window.Tracker.Weekly.Mplus:GetWidth()
		- ((BoxSize * self.DungeonReq) + (BoxSpacing * (self.DungeonReq - 1)))
	) / 2
	self.Window.Tracker.Weekly.Mplus.box = {}
	for i = 1, self.DungeonReq do
		self.Window.Tracker.Weekly.Mplus.box[i] =
			CreateFrame("Frame", "AMT_Mplus_Box" .. i, self.Window.Tracker.Weekly.Mplus)
		self.Window.Tracker.Weekly.Mplus.box[i]:SetSize(BoxSize, BoxSize)
		self.Window.Tracker.Weekly.Mplus.box[i].tex = self.Window.Tracker.Weekly.Mplus.box[i]:CreateTexture()
		self.Window.Tracker.Weekly.Mplus.box[i].tex:SetAllPoints(self.Window.Tracker.Weekly.Mplus.box[i])
		self.Window.Tracker.Weekly.Mplus.box[i].tex:SetColorTexture(1.0, 1.0, 1.0, 0.5)

		if i == 1 then
			self.Window.Tracker.Weekly.Mplus.box[i]:SetPoint(
				"LEFT",
				self.Window.Tracker.Weekly.Mplus,
				"LEFT",
				Mplus_BoxMargin,
				0
			)
		else
			local previousBox = self.Window.Tracker.Weekly.Mplus.box[i - 1]
			self.Window.Tracker.Weekly.Mplus.box[i]:SetPoint("LEFT", previousBox, "RIGHT", BoxSpacing, 0)
		end
	end

	-- --World
	-- self.Window.Tracker.Weekly.WorldHeader = AMT_CreateHeader(
	-- 	self.Window.Tracker.Weekly,
	-- 	"AMT_World_Goals_Header",
	-- 	"TOP",
	-- 	self.Window.Tracker.Weekly.Mplus,
	-- 	"BOTTOM",
	-- 	0,
	-- 	0,
	-- 	180,
	-- 	18,
	-- 	"World"
	-- )

	-- self.Window.Tracker.Weekly.World = CreateFrame("Frame", "AMT_World_Mainframe", self.Window.Tracker.Weekly)
	-- self.Window.Tracker.Weekly.World:SetSize(180, 22)
	-- self.Window.Tracker.Weekly.World:SetPoint("TOPLEFT", self.Window.Tracker.Weekly.WorldHeader, "BOTTOMLEFT", 0, 2)
	-- self.Window.Tracker.Weekly.World.tex = self.Window.Tracker.Weekly.World:CreateTexture()
	-- self.Window.Tracker.Weekly.World.tex:SetAllPoints(self.Window.Tracker.Weekly.World_Mainframe)
	-- self.Window.Tracker.Weekly.World.tex:SetColorTexture(unpack(self.BackgroundClear))

	-- self.Window.Tracker.Weekly.World.frame = CreateFrame("Frame", "AMT_World_Mainframe_BoxFrame", self.Window.Tracker.Weekly.World)
	-- self.Window.Tracker.Weekly.World.frame:SetSize(180, 22)
	-- self.Window.Tracker.Weekly.World.frame:SetPoint("CENTER", self.Window.Tracker.Weekly.World, "CENTER", 0, 0)
	-- self.Window.Tracker.Weekly.World.frame.tex = self.Window.Tracker.Weekly.World.frame:CreateTexture()
	-- self.Window.Tracker.Weekly.World.frame.tex:SetAllPoints(self.Window.Tracker.Weekly.World.frame)
	-- self.Window.Tracker.Weekly.World.frame.tex:SetColorTexture(unpack(self.BackgroundClear))

	-- self.Window.Tracker.Weekly.World:SetScript("OnEnter", function()
	-- 	GameTooltip:ClearAllPoints()
	-- 	GameTooltip:ClearLines()
	-- 	GameTooltip:SetOwner(self.Window.Tracker.Weekly.World, "ANCHOR_RIGHT")
	-- 	GameTooltip:SetText("Delves and World Activities", 1, 1, 1, 1, true)
	-- 	if self.KeysDone[1] ~= 0 then
	-- 		GameTooltip:AddLine(
	-- 			format("Number of Delves and World Activities done this week: |cffffffff%s|r", self.World_VaultTracker)
	-- 		)
	-- 	else
	-- 		GameTooltip:AddLine(format("Number of Delves and World Activities done this week: |cffffffff%s|r", 0))
	-- 	end
	-- 	self.Window.Tracker.Weekly.World.tex:SetColorTexture(unpack(self.BackgroundHover))
	-- 	GameTooltip:Show()
	-- end)
	-- self.Window.Tracker.Weekly.World:SetScript("OnLeave", function()
	-- 	GameTooltip:Hide()
	-- 	self.Window.Tracker.Weekly.World.tex:SetColorTexture(unpack(self.BackgroundClear))
	-- end)

	--M+ Graph
	self.Window.Tracker.Graph = CreateFrame("Frame", "AMT_MythicRunsGraph_Container", self.Window.Tracker)
	self.Window.Tracker.Graph:SetSize(
		AMT_WINDOW_WIDTH
			- X_OFFSET * 2
			- self.Window.Tracker.Weekly:GetWidth()
			- self.Window.Tracker.PartyKeys:GetWidth(),
		PVEFrame:GetHeight()
			- Y_OFFSET
			- self.Window.Tracker.MplusScore:GetHeight()
			- self.Window.Tracker.Dungeons:GetHeight()
			- 12
	)
	self.Window.Tracker.Graph:SetPoint("TOP", self.Window.Tracker.MplusScore, "BOTTOM", -X_OFFSET * 2 - 2, 0)

	self.Window.Tracker.Graph.dividers = {}

	for i = 1, 4 do
		local Starting_XPos = 60
		local YPos_Start = -16
		local YPos_End = 34
		self.Window.Tracker.Graph.dividers[i] = {}
		self.Window.Tracker.Graph.dividers[i] = self.Window.Tracker.Graph:CreateLine("AMT_GraphLine" .. i)
		self.Window.Tracker.Graph.dividers[i]:SetThickness(2)
		self.Window.Tracker.Graph.dividers[i]:SetColorTexture(0.4, 0.4, 0.4, 1.000)
		if i == 1 then
			-- x = 44
			local X_OFFSET = Starting_XPos
			self.Window.Tracker.Graph.dividers[i]:SetColorTexture(1, 1, 1, 0)
			self.Window.Tracker.Graph.dividers[i]:SetStartPoint("TOPLEFT", X_OFFSET, YPos_Start)
			self.Window.Tracker.Graph.dividers[i]:SetEndPoint("BOTTOMLEFT", X_OFFSET, YPos_End)
		elseif i == 2 then
			-- x = 186
			local X_OFFSET = Starting_XPos + 142
			self.Window.Tracker.Graph.dividers[i]:SetStartPoint("TOPLEFT", X_OFFSET, YPos_Start)
			self.Window.Tracker.Graph.dividers[i]:SetEndPoint("BOTTOMLEFT", X_OFFSET, YPos_End)
		elseif i > 2 then
			-- 3 // x = 336
			-- 4 // x = 486
			local X_OFFSET = Starting_XPos + 142 + 150 * (i - 2)
			self.Window.Tracker.Graph.dividers[i]:SetStartPoint("TOPLEFT", X_OFFSET, YPos_Start)
			self.Window.Tracker.Graph.dividers[i]:SetEndPoint("BOTTOMLEFT", X_OFFSET, YPos_End)
		end
	end
	for i = 1, 3 do
		self.Window.Tracker.Graph.dividers[i].label =
			self.Window.Tracker.Graph:CreateFontString("AMT_Graphline_Label" .. i, "BACKGROUND", "GameFontNormal")
		self.Window.Tracker.Graph.dividers[i].label:SetText(tostring(i * 10))
		self.Window.Tracker.Graph.dividers[i].label:SetJustifyH("CENTER")
		self.Window.Tracker.Graph.dividers[i].label:SetPoint(
			"BOTTOM",
			self.Window.Tracker.Graph.dividers[i + 1],
			"TOP",
			0,
			4
		)
	end

	self.Window.Tracker.Graph.dungeons = {}
	for i = 1, #self.Info.SeasonDungeons do
		local graphline = self.Window.Tracker.Graph.dividers[1]
		local dungID = self.Info.SeasonDungeons[i].mapID
		local dungAbbr = ""
		for _, dungeon in ipairs(self.SeasonalDungeons) do
			if dungID == dungeon.mapID then
				dungAbbr = dungeon.abbr
			end
		end
		local yMargin = 12 -- Margin we set at top and bottom
		local Y_OFFSET = 26 -- Margin between each dungeon name
		self.Window.Tracker.Graph.dungeons[i] = {}
		self.Window.Tracker.Graph.dungeons[i].label =
			self.Window.Tracker.Graph:CreateFontString("AMT_GraphDung_Label" .. i, "BACKGROUND", "MovieSubtitleFont")
		self.Window.Tracker.Graph.dungeons[i].label:SetFont(self.AMT_Font, 14)
		self.Window.Tracker.Graph.dungeons[i].label:SetText(dungAbbr)
		self.Window.Tracker.Graph.dungeons[i].label:SetJustifyH("RIGHT")
		if i == 1 then
			self.Window.Tracker.Graph.dungeons[i].label:SetPoint("RIGHT", graphline, "TOPLEFT", -4, -yMargin)
		else
			self.Window.Tracker.Graph.dungeons[i].label:SetPoint(
				"RIGHT",
				graphline,
				"TOPLEFT",
				-4,
				-yMargin - (Y_OFFSET * (i - 1))
			)
		end
	end

	--Crests
	self.Window.Tracker.Crests = CreateFrame("Frame", "AMT_CrestsTracker_Container", self.Window.Tracker)
	self.Window.Tracker.Crests:SetPoint("BOTTOMRIGHT", self.Window.Tracker.Graph, "BOTTOMRIGHT", 0, -1)
	self.Window.Tracker.Crests:SetSize(self.Window.Tracker.Graph:GetWidth() + self.Window.Tracker.Weekly:GetWidth(), 30)
	-- self.Window.Tracker.Crests:SetSize(self.Window.Tracker:GetWidth() - self.Window.Tracker.PartyKeys:GetWidth(), 30)
	-- self.Window.Tracker.Crests.tex = self.Window.Tracker.Crests:CreateTexture()
	-- self.Window.Tracker.Crests.tex:SetAllPoints(self.Window.Tracker.Crests)
	-- self.Window.Tracker.Crests.tex:SetColorTexture(unpack(self.BackgroundDark))
	-- self.Window.Tracker.Crests:SetSize(self.Window.Tracker.Graph:GetWidth(), 30)

	self.Window.Tracker.Crests.bar = {}
	for i = 1, #self.Crests do
		self.Window.Tracker.Crests.bar[i] =
			AMT.CreateMetalProgressBar(self.Window.Tracker.Crests, "normal", self.Crests[i].name .. "_StatusBar")
		self.Window.Tracker.Crests.bar[i]:SetBarWidth(120)
		self.Window.Tracker.Crests.bar[i]:SetBarColor(
			self.Crests[i].color[1],
			self.Crests[i].color[2],
			self.Crests[i].color[3]
		)
		if i == 1 then
			self.Window.Tracker.Crests.bar[i]:SetPoint("BOTTOMRIGHT", self.Window.Tracker.Crests, "BOTTOMRIGHT", -25, 0)
		else
			self.Window.Tracker.Crests.bar[i]:SetPoint(
				"BOTTOMRIGHT",
				self.Window.Tracker.Crests,
				"BOTTOMRIGHT",
				-25 - (self.Window.Tracker.Crests.bar[i]:GetWidth() + 25) * (i - 1),
				0
			)
		end

		self.Window.Tracker.Crests.bar[i].text =
			self.Window.Tracker.Crests.bar[i]:CreateFontString(nil, "OVERLAY", "MovieSubtitleFont")
		self.Window.Tracker.Crests.bar[i].text:SetPoint("BOTTOM", self.Window.Tracker.Crests.bar[i], "TOP", 0, 3)
		self.Window.Tracker.Crests.bar[i].text:SetText(self.Crests[i].name)
		self.Window.Tracker.Crests.bar[i].text:SetFont(self.AMT_Font, 12)

		-- Establish the Hover Properties
		self.Window.Tracker.Crests.bar[i]:SetScript("OnEnter", function()
			AMT:GET_Crests()
			GameTooltip:ClearAllPoints()
			GameTooltip:ClearLines()
			GameTooltip:SetOwner(self.Window.Tracker.Crests.bar[i], "ANCHOR_RIGHT")
			GameTooltip:SetText(
				CreateTextureMarkup(AMT.Crests[i].textureID, 64, 64, 16, 16, 0.07, 0.93, 0.07, 0.93)
					.. " "
					.. AMT.Crests[i].displayName,
				AMT.Crests[i].color[1],
				AMT.Crests[i].color[2],
				AMT.Crests[i].color[3],
				AMT.Crests[i].color[4],
				true
			)
			GameTooltip:AddLine(AMT.Crests[i].CurrencyDescription, 1.000, 0.824, 0.000, true)
			GameTooltip:AddLine(" ")
			if AMT.Crests[i].name == "Valorstones" then
				GameTooltip:AddLine(
					"Current Amount: "
						.. AMT.WhiteText
						.. AMT.Crests[i].CurrentAmount
						.. "/"
						.. AMT.Crests[i].CurrencyCapacity
				)
			else
				GameTooltip:AddLine("Current Amount: " .. AMT.WhiteText .. AMT.Crests[i].CurrentAmount)
				GameTooltip:AddLine(
					"Season Maximum: "
						.. AMT.WhiteText
						.. AMT.Crests[i].CurrencyTotalEarned
						.. "/"
						.. AMT.Crests[i].CurrencyCapacity
				)
				-- GameTooltip:AddLine(
				-- 	"You need to time " .. AMT.WhiteText .. AMT.Crests[i].NumOfRunsNeeded .. "|r M+ keys to cap."
				-- )
			end
			GameTooltip:Show()
		end)
		self.Window.Tracker.Crests.bar[i]:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	--Great Vault
	self.Window.Tracker.VaultButton = AMT_CreateBorderButton(
		self.Window.Tracker,
		"AMT_PartyKeystone_DetailsButton",
		"TOP",
		self.Window.Tracker.Keystone.icon,
		"BOTTOM",
		0,
		-155,
		74,
		22,
		"Open Vault"
	)
	self.Window.Tracker.VaultButton:SetScript("OnClick", function()
		C_AddOns.LoadAddOn("Blizzard_WeeklyRewards")
		if not WeeklyRewardsFrame:IsVisible() then
			WeeklyRewardsFrame:Show()
		else
			WeeklyRewardsFrame:Hide()
		end
	end)

	self.Tracker_Initialized = true
end
