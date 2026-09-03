local AMT = select(2, ...)

local Options = AMT.Options
local CONST = Options.CONST

local ICON_ROOT = [[Interface\AddOns\AdvancedMythicTracker\Media\Icons\]]

local INSET = 10
local ROW_HEIGHT = 28
local ROW_INDENT = 4
local HEADER_HEIGHT = 26
local HEADER_DROP = 8
local SECTION_GAP = 8
local ICON_SIZE = 16
local ICON_GAP = 8
local SCROLL_STEP = 40
local SCROLL_DURATION = 0.12

-- ffd200, applied to the selected row's label and icon alike.
local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

---@class AMTSidebarRow
---@field id string page id
---@field button Button
---@field background Texture
---@field icon Texture
---@field label FontString

---@class AMTOptionsSidebar
---@field frame Frame
---@field scroll ScrollFrame
---@field content Frame
---@field rows AMTSidebarRow[]
---@field selectedID string?
---@field scrollTo number?
local Sidebar = {}
Sidebar.__index = Sidebar
Options.Sidebar = Sidebar

---@param page AMTOptionsPage
function Options.OnPageSelected(page) end

---@param row AMTSidebarRow
function Sidebar:UpdateRow(row)
	if self.selectedID == row.id then
		row.label:SetTextColor(GOLD_R, GOLD_G, GOLD_B)
		row.icon:SetVertexColor(GOLD_R, GOLD_G, GOLD_B)
		row.background:SetAtlas("Options_List_Active")

		return
	end

	row.label:SetTextColor(1, 1, 1)
	row.icon:SetVertexColor(1, 1, 1)

	if row.button:IsMouseMotionFocus() then
		row.background:SetAtlas("Options_List_Hover")
	else
		row.background:SetTexture(nil)
	end
end

---@param id string
function Sidebar:Select(id)
	local page = Options.GetPage(id)

	if not page or self.selectedID == id then
		return
	end

	self.selectedID = id

	for _, row in ipairs(self.rows) do
		self:UpdateRow(row)
	end

	Options.OnPageSelected(page)
end

---@param page AMTOptionsPage
---@param offsetY number
---@return AMTSidebarRow
function Sidebar:CreateRow(page, offsetY)
	local button = CreateFrame("Button", nil, self.content)

	button:SetHeight(ROW_HEIGHT)
	button:SetPoint("TOPLEFT", self.content, "TOPLEFT", ROW_INDENT, -offsetY)
	button:SetPoint("TOPRIGHT", self.content, "TOPRIGHT", 0, -offsetY)
	button:RegisterForClicks("LeftButtonUp")

	local background = button:CreateTexture(nil, "BACKGROUND")

	background:SetAllPoints(button)

	local icon = button:CreateTexture(nil, "ARTWORK")

	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("LEFT", button, "LEFT", ICON_GAP, 0)

	local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")

	label:SetJustifyH("LEFT")
	label:SetPoint("RIGHT", button, "RIGHT", -ICON_GAP, 0)
	label:SetWordWrap(false)
	label:SetText(page.name)

	if page.icon then
		icon:SetTexture(ICON_ROOT .. page.icon)
		icon:Show()
		label:SetPoint("LEFT", icon, "RIGHT", ICON_GAP, 0)
	else
		icon:Hide()
		label:SetPoint("LEFT", button, "LEFT", ICON_GAP, 0)
	end

	---@type AMTSidebarRow
	local row = { id = page.id, button = button, background = background, icon = icon, label = label }

	button:SetScript("OnEnter", function()
		self:UpdateRow(row)
	end)

	button:SetScript("OnLeave", function()
		self:UpdateRow(row)
	end)

	button:SetScript("OnClick", function()
		self:Select(row.id)
	end)

	self:UpdateRow(row)

	return row
end

function Sidebar:Build()
	local offsetY = 0

	for index, category in ipairs(Options.GetCategories()) do
		local pages = Options.GetPages(category.id)

		if #pages > 0 then
			if index > 1 then
				offsetY = offsetY + SECTION_GAP
			end

			local header = self.content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")

			header:SetJustifyH("LEFT")
			header:SetPoint("TOPLEFT", self.content, "TOPLEFT", ICON_GAP, -offsetY - HEADER_DROP)
			header:SetText(category.name:upper())
			header:SetTextColor(GOLD_R, GOLD_G, GOLD_B)

			offsetY = offsetY + HEADER_HEIGHT

			for _, page in ipairs(pages) do
				self.rows[#self.rows + 1] = self:CreateRow(page, offsetY)
				offsetY = offsetY + ROW_HEIGHT
			end
		end
	end

	self.content:SetHeight(math.max(offsetY, 1))
end

---@param parent Frame
---@return AMTOptionsSidebar
function Options.NewSidebar(parent)
	local sidebar = setmetatable({ rows = {} }, Sidebar)

	sidebar.frame = CreateFrame("Frame", nil, parent)
	sidebar.frame:SetAllPoints(parent)

	AMT.NineSlice.Apply(sidebar.frame, "Inset", CONST.CORNER_SIZE)

	local scroll = CreateFrame("ScrollFrame", nil, sidebar.frame)

	scroll:SetPoint("TOPLEFT", sidebar.frame, "TOPLEFT", INSET, -INSET)
	scroll:SetPoint("BOTTOMRIGHT", sidebar.frame, "BOTTOMRIGHT", -INSET, INSET)
	scroll:EnableMouseWheel(true)

	local content = CreateFrame("Frame", nil, scroll)

	content:SetHeight(1)
	scroll:SetScrollChild(content)

	sidebar.scroll = scroll
	sidebar.content = content

	local function UpdateContentWidth()
		content:SetWidth(scroll:GetWidth())
	end

	scroll:SetScript("OnSizeChanged", UpdateContentWidth)
	UpdateContentWidth()

	scroll:SetScript("OnMouseWheel", function(_, delta)
		local range = scroll:GetVerticalScrollRange()

		if range <= 0 then
			return
		end

		local from = sidebar.scrollTo or scroll:GetVerticalScroll()
		local target = math.max(0, math.min(range, from - delta * SCROLL_STEP))
		local start = scroll:GetVerticalScroll()

		if target == start then
			return
		end

		sidebar.scrollTo = target

		AMT.Animation.Run(scroll, SCROLL_DURATION, function(eased)
			scroll:SetVerticalScroll(start + (target - start) * eased)
		end)
	end)

	sidebar:Build()

	return sidebar
end

---@param host Frame
function Options.BuildSidebar(host)
	local sidebar = Options.NewSidebar(host)
	local first = Options.GetFirstPage()

	Options.sidebar = sidebar

	if first then
		sidebar:Select(first.id)
	end
end
