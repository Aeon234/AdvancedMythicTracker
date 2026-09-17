local AMT = select(2, ...)
local L = AMT.L

local Options = AMT.Options
local CONST = Options.CONST

local CHILD_ROW_HEIGHT = 34
local ROW_INSET = 12

local GRIP_WIDTH = 12
local GRIP_HEIGHT = 18
local GRIP_DOT = 3
local GRIP_STEP = GRIP_DOT * 2 + 1
local GRIP_GAP = 10

local HEADER_INSET = 14
local GRIP_IDLE = 0.55
local GRIP_HOVER = 1

local INDICATOR_HEIGHT = 2
local DRAG_SOURCE_ALPHA = 0.35
local DISABLED_ALPHA = 0.4

local DRAG_THRESHOLD = 4

local GOLD_R, GOLD_G, GOLD_B = 1, 0.8235, 0

local SLOT_VALUES = {
	{ "LEFT", L["Left"] },
	{ "CENTER", L["Center"] },
	{ "RIGHT", L["Right"] },
}

---@class AMTReorderRow : Frame
---@field grip Frame
---@field dots Texture[]
---@field title FontString
---@field slot AMTSegmentedWidget?
---@field hover AMTBorder?

---An armed press, before it is known to be a drag.
---@class AMTReorderPress
---@field surface Frame
---@field kind "group"|"member"
---@field key string
---@field groupKey string?
---@field x number
---@field y number

---@class AMTReorderDrag
---@field kind "group"|"member"
---@field key string
---@field groupKey string?
---@field keys string[] the sibling order this drag reorders
---@field fromIndex integer
---@field dropIndex integer
---@field offX number
---@field offY number

---@class AMTReorderEntry
---@field groupKey string
---@field grip Frame
---@field group AMTOptionsGroup
---@field rows table<string, AMTReorderRow>
---@field note AMTOptionWidget?

---@class AMTReorderWidget : AMTOptionWidget
---@field entries table<string, AMTReorderEntry>
---@field built boolean?
---@field pressUpdater function
---@field press AMTReorderPress?
---@field drag AMTReorderDrag?
---@field onResized fun()?
local Reorder = Options.NewWidgetPrototype("reorder")

local ghost, indicator

---@param parent Frame
---@param brightness number
---@return Frame
local function CreateGrip(parent, brightness)
	local grip = CreateFrame("Frame", nil, parent)

	grip:SetSize(GRIP_WIDTH, GRIP_HEIGHT)
	grip:EnableMouse(false)

	local dots = {}

	for column = 0, 1 do
		for row = 0, 2 do
			local dot = grip:CreateTexture(nil, "ARTWORK")

			dot:SetSize(GRIP_DOT, GRIP_DOT)
			dot:SetPoint("TOPLEFT", grip, "TOPLEFT", column * GRIP_STEP, -row * GRIP_STEP)
			dot:SetColorTexture(brightness, brightness, brightness, 1)

			dots[#dots + 1] = dot
		end
	end

	grip.dots = dots

	return grip
end

---@param grip Frame
---@param brightness number
local function SetGripBrightness(grip, brightness)
	for _, dot in ipairs(grip.dots) do
		dot:SetColorTexture(brightness, brightness, brightness, 1)
	end
end

---@return Frame
local function EnsureGhost()
	if ghost then
		return ghost
	end

	ghost = CreateFrame("Frame", nil, UIParent)

	ghost:SetFrameStrata("TOOLTIP")
	ghost:EnableMouse(false)
	ghost:SetAlpha(0.9)

	AMT.NineSlice.Apply(ghost, "Control", CONST.CORNER_SIZE)

	ghost.grip = CreateGrip(ghost, GRIP_HOVER)
	ghost.grip:SetPoint("LEFT", ghost, "LEFT", ROW_INSET, 0)

	ghost.title = ghost:CreateFontString(nil, "OVERLAY", CONST.FONT_GROUP_TITLE)
	ghost.title:SetPoint("LEFT", ghost.grip, "RIGHT", GRIP_GAP, 0)
	ghost.title:SetTextColor(1, 1, 1)

	ghost:Hide()

	return ghost
end

---@return Frame
local function EnsureIndicator()
	if indicator then
		return indicator
	end

	indicator = CreateFrame("Frame", nil, UIParent)

	indicator:SetHeight(INDICATOR_HEIGHT)
	indicator:EnableMouse(false)

	local line = indicator:CreateTexture(nil, "OVERLAY")

	line:SetAllPoints(indicator)
	line:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, 1)

	indicator:Hide()

	return indicator
end

-- Reading the profile

---@return string[]
local function GroupOrder()
	local stored = Options.Get("timer.order.groups")
	local keys = {}

	for _, groupKey in ipairs(stored or {}) do
		keys[#keys + 1] = groupKey
	end

	return keys
end

---@param groupKey string
---@return string[]
local function MemberOrder(groupKey)
	local stored = Options.Get("timer.order." .. groupKey)
	local keys = {}

	for _, elementKey in ipairs(stored or {}) do
		if AMT.Layout.IsElementRegistered(elementKey) then
			keys[#keys + 1] = elementKey
		end
	end

	return keys
end

---@param groupKey string
---@return boolean
local function HasMemberControls(groupKey)
	return groupKey == "keyInfo"
end

---A group earns a chevron when there is something inside worth opening it for.
---@param groupKey string
---@param members string[]
---@return boolean
local function IsExpandable(groupKey, members)
	return #members > 1 or (HasMemberControls(groupKey) and #members > 0)
end

-- Construction

local PressOnUpdate

---@param parent Frame
function Reorder:Create(parent)
	Options.Widget.Create(self, parent)

	self.entries = {}
	self.label:SetText("")

	self.pressUpdater = function()
		PressOnUpdate(self)
	end

	self.frame:SetScript("OnHide", function()
		self:CancelDrag()
	end)
end

---@return number
function Reorder:GetControlHeight()
	return 0
end

---@param entry AMTReorderEntry
---@param elementKey string
---@return AMTReorderRow
function Reorder:CreateRow(entry, elementKey)
	local widget = self
	local row = CreateFrame("Frame", nil, entry.group.content.frame)
	---@cast row AMTReorderRow

	row:SetHeight(CHILD_ROW_HEIGHT)
	row:EnableMouse(true)

	-- Child rows sit on the group body's Inset panel, so an Inset row would vanish into it.
	AMT.NineSlice.Apply(row, "InsetDeep", CONST.CORNER_SIZE)

	row.hover = AMT.NineSlice.Apply(row, "Hover", CONST.CORNER_SIZE, "OVERLAY")

	if row.hover then
		row.hover:SetShown(false)
	end

	row.grip = CreateGrip(row, GRIP_IDLE)
	row.grip:SetPoint("LEFT", row, "LEFT", ROW_INSET, 0)

	row.title = row:CreateFontString(nil, "ARTWORK", CONST.FONT_ROW)
	row.title:SetPoint("LEFT", row.grip, "RIGHT", GRIP_GAP, 0)
	row.title:SetJustifyH("LEFT")
	row.title:SetTextColor(1, 1, 1)
	row.title:SetText(AMT.Layout.GetElementLabel(elementKey))

	if HasMemberControls(entry.groupKey) then
		local slot = Options.NewWidget("segmented", row, 0)

		if slot then
			---@cast slot AMTSegmentedWidget
			slot:Bind({
				type = "segmented",
				path = "timer.elements." .. elementKey .. ".justify",
				values = SLOT_VALUES,
				disabled = function()
					return Options.Get("timer.keyInfo.inline") == true
				end,
			})

			slot.frame:ClearAllPoints()
			slot.frame:SetPoint("RIGHT", row, "RIGHT", -ROW_INSET, 0)

			row.slot = slot
		end
	end

	row:SetScript("OnEnter", function(self)
		if self.hover then
			self.hover:SetShown(true)
		end

		SetGripBrightness(self.grip, GRIP_HOVER)
	end)

	row:SetScript("OnLeave", function(self)
		if self.hover then
			self.hover:SetShown(false)
		end

		SetGripBrightness(self.grip, GRIP_IDLE)
	end)

	row:SetScript("OnMouseDown", function(pressed, button)
		if button == "LeftButton" then
			widget:BeginPress(pressed, "member", elementKey, entry.groupKey)
		end
	end)

	entry.rows[elementKey] = row

	return row
end

function Reorder:Build()
	if self.built then
		return
	end

	self.built = true

	for _, groupKey in ipairs(AMT.Layout.GetGroupKeys()) do
		local members = AMT.Layout.GetRegisteredMembers(groupKey)

		local group = Options.NewGroup(self.frame, {
			title = AMT.Layout.GetGroupLabel(groupKey),
			manualToggle = true,
			labelWidth = 0,
		})

		local header = group.header
		local grip = CreateGrip(header, GRIP_IDLE)

		grip:SetPoint("LEFT", header, "LEFT", HEADER_INSET, 0)

		group.title:ClearAllPoints()
		group.title:SetPoint("LEFT", grip, "RIGHT", GRIP_GAP, 0)

		---@type AMTReorderEntry
		local entry = {
			groupKey = groupKey,
			group = group,
			grip = grip,
			rows = {},
		}

		header:HookScript("OnEnter", function()
			SetGripBrightness(grip, GRIP_HOVER)
		end)

		header:HookScript("OnLeave", function()
			SetGripBrightness(grip, GRIP_IDLE)
		end)

		entry.group.onResized = function()
			self:LayoutGroups()
		end

		entry.group.header:SetScript("OnMouseDown", function(_, button)
			if button == "LeftButton" then
				self:BeginPress(entry.group.header, "group", groupKey)
			end
		end)

		if groupKey == "keyInfo" then
			entry.note = entry.group.content:AddWidget({
				type = "note",
				text = L["Left, Center and Right apply only while Key Info is not combined into a single line."],
				hidden = function()
					return Options.Get("timer.keyInfo.inline") ~= true
				end,
			})
		end

		for _, elementKey in ipairs(members) do
			self:CreateRow(entry, elementKey)
		end

		self.entries[groupKey] = entry
	end
end

-- Layout

function Reorder:LayoutGroups()
	local offsetY = 0

	for _, groupKey in ipairs(GroupOrder()) do
		local entry = self.entries[groupKey]

		if entry then
			local frame = entry.group.frame

			frame:ClearAllPoints()
			frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -offsetY)
			frame:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -offsetY)
			frame:Show()

			offsetY = offsetY + frame:GetHeight() + CONST.ROW_SPACING
		end
	end

	self.frame:SetHeight(math.max(offsetY - CONST.ROW_SPACING, 1))

	if self.onResized then
		self.onResized()
	end
end

---@param entry AMTReorderEntry
---@param members string[]
function Reorder:LayoutRows(entry, members)
	local container = entry.group.content
	local children = {}

	if entry.note then
		children[#children + 1] = entry.note.frame
	end

	local placed = {}

	for _, elementKey in ipairs(members) do
		local row = entry.rows[elementKey]

		if row then
			placed[row] = true
			children[#children + 1] = row
		end
	end

	for _, row in pairs(entry.rows) do
		if not placed[row] then
			row:Hide()
		else
			row:Show()
		end
	end

	container.children = children
	container:Layout()
end

--------------------------------------------------------------------------------
-- Refresh
--------------------------------------------------------------------------------

function Reorder:Update()
	local info = Options.Widget.Update(self)

	if not info then
		return
	end

	self:Build()

	for _, groupKey in ipairs(AMT.Layout.GetGroupKeys()) do
		local entry = self.entries[groupKey]
		local members = MemberOrder(groupKey)
		local expandable = IsExpandable(groupKey, members)

		entry.group.chevron:SetShown(expandable)

		if not expandable and entry.group:IsExpanded() then
			entry.group:SetExpanded(false, true)
		end

		for _, elementKey in ipairs(members) do
			local row = entry.rows[elementKey]

			if row then
				local enabled = Options.Get("timer.elements." .. elementKey .. ".enabled") ~= false

				row:SetAlpha(enabled and 1 or DISABLED_ALPHA)

				if row.slot then
					row.slot:Update()
					row.slot.frame:SetWidth(math.max(row.slot.track:GetWidth(), 1))
				end
			end
		end

		if entry.note then
			entry.note:Update()
		end

		self:LayoutRows(entry, members)
	end

	self:LayoutGroups()
end

-- Dragging

---@param frame Frame
---@return number top
---@return number bottom
local function EdgesScreen(frame)
	local scale = frame:GetEffectiveScale()

	return frame:GetTop() * scale, frame:GetBottom() * scale
end

---@param kind "group"|"member"
---@param groupKey string?
---@param key string
---@return Frame?
function Reorder:BlockFrame(kind, groupKey, key)
	if kind == "group" then
		local entry = self.entries[key]

		return entry and entry.group.frame
	end

	if not groupKey then
		return nil
	end

	local entry = self.entries[groupKey]

	return entry and entry.rows[key]
end

---@return number
function Reorder:ComputeDropIndex()
	local drag = self.drag

	if not drag then
		return 1
	end

	local _, cursorY = GetCursorPosition()
	local insertAt = #drag.keys + 1

	for index, key in ipairs(drag.keys) do
		local frame = self:BlockFrame(drag.kind, drag.groupKey, key)

		if frame and frame:GetTop() and frame:GetBottom() then
			local top, bottom = EdgesScreen(frame)

			if cursorY > (top + bottom) / 2 then
				insertAt = index

				break
			end
		end
	end

	if insertAt > drag.fromIndex then
		insertAt = insertAt - 1
	end

	return math.max(1, math.min(#drag.keys, insertAt))
end

---@param dropIndex number
function Reorder:UpdateIndicator(dropIndex)
	local drag = self.drag

	if not drag then
		return
	end

	local anchorKey = drag.keys[dropIndex]
	local anchor = anchorKey and self:BlockFrame(drag.kind, drag.groupKey, anchorKey)

	if not anchor then
		indicator:Hide()

		return
	end

	local point, relative, offset

	if dropIndex <= drag.fromIndex then
		point, relative, offset = "BOTTOM", "TOP", CONST.ROW_SPACING / 2
	else
		point, relative, offset = "TOP", "BOTTOM", -CONST.ROW_SPACING / 2
	end

	indicator:ClearAllPoints()
	indicator:SetParent(anchor:GetParent())
	indicator:SetFrameStrata(anchor:GetFrameStrata())
	indicator:SetFrameLevel(anchor:GetFrameLevel() + 10)
	indicator:SetPoint(point .. "LEFT", anchor, relative .. "LEFT", 0, offset)
	indicator:SetPoint(point .. "RIGHT", anchor, relative .. "RIGHT", 0, offset)
	indicator:Show()
end

---@param enabled boolean
function Reorder:SetRowsInteractive(enabled)
	for _, entry in pairs(self.entries) do
		entry.group.header:EnableMouse(enabled)

		if not enabled then
			SetGripBrightness(entry.grip, GRIP_IDLE)
		end

		for _, row in pairs(entry.rows) do
			row:EnableMouse(enabled)

			if row.slot then
				for _, segment in ipairs(row.slot.segments) do
					segment:EnableMouse(enabled)
				end
			end

			if not enabled and row.hover then
				row.hover:SetShown(false)
				SetGripBrightness(row.grip, GRIP_IDLE)
			end
		end
	end
end

---@param kind "group"|"member"
---@param groupKey string?
---@param key string
---@param alpha number
function Reorder:SetBlockAlpha(kind, groupKey, key, alpha)
	local frame = self:BlockFrame(kind, groupKey, key)

	if frame then
		frame:SetAlpha(alpha)
	end
end

---@param self AMTReorderWidget
function PressOnUpdate(self)
	local press = self.press

	if not press then
		self.frame:SetScript("OnUpdate", nil)

		return
	end

	local scale = UIParent:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()

	if not IsMouseButtonDown("LeftButton") then
		if self.drag then
			self:EndDrag()

			return
		end

		local surface = press.surface

		self.press = nil
		self.frame:SetScript("OnUpdate", nil)

		if press.kind == "group" and surface:IsMouseOver() then
			local entry = self.entries[press.key]

			if entry and entry.group.chevron:IsShown() then
				entry.group:Toggle()
			end
		end

		return
	end

	if not self.drag then
		local dx = cursorX / scale - press.x
		local dy = cursorY / scale - press.y

		if dx * dx + dy * dy < DRAG_THRESHOLD * DRAG_THRESHOLD then
			return
		end

		if not self:BeginDrag(press) then
			self.press = nil
			self.frame:SetScript("OnUpdate", nil)

			return
		end
	end

	local drag = self.drag

	if not drag then
		return
	end

	ghost:ClearAllPoints()
	ghost:SetPoint(
		"TOPLEFT",
		UIParent,
		"BOTTOMLEFT",
		cursorX / scale + drag.offX,
		cursorY / scale + drag.offY
	)

	drag.dropIndex = self:ComputeDropIndex()
	self:UpdateIndicator(drag.dropIndex)
end

---@param surface Frame
---@param kind "group"|"member"
---@param key string
---@param groupKey string?
function Reorder:BeginPress(surface, kind, key, groupKey)
	if self.press or self.disabled then
		return
	end

	local scale = UIParent:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()

	self.press = {
		surface = surface,
		kind = kind,
		key = key,
		groupKey = groupKey,
		x = cursorX / scale,
		y = cursorY / scale,
	}

	self.frame:SetScript("OnUpdate", self.pressUpdater)
end

---@param press AMTReorderPress
---@return boolean started
function Reorder:BeginDrag(press)
	if self.drag then
		return false
	end

	local keys

	if press.kind == "group" then
		keys = GroupOrder()
	elseif press.groupKey then
		keys = MemberOrder(press.groupKey)
	else
		-- A member press with no group is a press the widget did not arm. Refuse rather than guess
		-- which array it belongs to and reorder the wrong one.
		return false
	end

	local fromIndex

	for index, key in ipairs(keys) do
		if key == press.key then
			fromIndex = index

			break
		end
	end

	if not fromIndex or #keys < 2 or not press.surface:GetLeft() then
		return false
	end

	for _, entry in pairs(self.entries) do
		AMT.Animation.Stop(entry.group.frame)
		entry.group:UpdateHeight()
	end

	self:LayoutGroups()

	EnsureGhost()
	EnsureIndicator()

	local surface = press.surface
	local scale = UIParent:GetEffectiveScale()
	local surfaceScale = surface:GetEffectiveScale()
	local cursorX, cursorY = GetCursorPosition()

	self.drag = {
		kind = press.kind,
		key = press.key,
		groupKey = press.groupKey,
		keys = keys,
		fromIndex = fromIndex,
		dropIndex = fromIndex,
		offX = (surface:GetLeft() * surfaceScale - cursorX) / scale,
		offY = (surface:GetTop() * surfaceScale - cursorY) / scale,
	}

	self:SetBlockAlpha(press.kind, press.groupKey, press.key, DRAG_SOURCE_ALPHA)
	self:SetRowsInteractive(false)

	ghost:SetSize(surface:GetWidth(), surface:GetHeight())
	ghost.title:SetText(
		press.kind == "group" and AMT.Layout.GetGroupLabel(press.key) or AMT.Layout.GetElementLabel(press.key)
	)
	ghost:Show()

	self:UpdateIndicator(fromIndex)

	return true
end

function Reorder:EndDrag()
	local drag = self.drag

	if not drag then
		return
	end

	self.drag = nil
	self.press = nil
	self.frame:SetScript("OnUpdate", nil)

	if ghost then
		ghost:Hide()
	end

	if indicator then
		indicator:Hide()
	end

	self:SetRowsInteractive(true)
	self:SetBlockAlpha(drag.kind, drag.groupKey, drag.key, 1)

	if drag.dropIndex == drag.fromIndex then
		return
	end

	table.remove(drag.keys, drag.fromIndex)
	table.insert(drag.keys, drag.dropIndex, drag.key)

	self:SetValue({ groupKey = drag.kind == "member" and drag.groupKey or nil, keys = drag.keys })
end

---Abandon a press or a drag without applying it.
function Reorder:CancelDrag()
	local drag = self.drag

	self.press = nil
	self.frame:SetScript("OnUpdate", nil)

	if not drag then
		return
	end

	self.drag = nil

	if ghost then
		ghost:Hide()
	end

	if indicator then
		indicator:Hide()
	end

	self:SetRowsInteractive(true)
	self:SetBlockAlpha(drag.kind, drag.groupKey, drag.key, 1)
end
