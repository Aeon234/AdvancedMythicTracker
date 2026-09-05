local AMT = select(2, ...)

---@type string[]
local registrationOrder = {}
---@type table<string, boolean>
local collapsed = {}
---@type table<string, FramePoint>
local JUSTIFY_POINTS = { LEFT = "TOPLEFT", CENTER = "TOP", RIGHT = "TOPRIGHT" }
local GROUP_SPACING = 4
local ELEMENT_SPACING = 2

---@alias AMTLayoutGroupKey "keyInfo"|"timer"|"objectives"|"forces"

---@class AMTLayoutElement
---@field group AMTLayoutGroupKey
---@field frame Frame
---@field slot "LEFT"|"CENTER"|"RIGHT"

---@class AMTLayout
local Layout = {}
AMT.Layout = Layout

---@type table<AMTLayoutGroupKey, Frame>
local groups = {}

---@type table<string, AMTLayoutElement>
local elements = {}

---@param key AMTLayoutGroupKey
---@return Frame
function Layout.GetGroup(key)
	local group = groups[key]

	if not group then
		group = CreateFrame("Frame", nil, AMT.Frames.root)
		groups[key] = group
	end

	return group
end

---@param elementKey string
local function SeedElement(elementKey)
	local profile = AMT.Profiles.active.timer
	local order = profile.order[elements[elementKey].group]

	if order and not tContains(order, elementKey) then
		order[#order + 1] = elementKey
	end

	local settings = profile.elements[elementKey]

	if not settings then
		settings = { enabled = true, nudge = { 0, 0 } }
		profile.elements[elementKey] = settings
	end

	if not settings.slot then
		settings.slot = elements[elementKey].slot
	end
end

---@param groupKey AMTLayoutGroupKey
---@param elementKey string
---@param frame Frame
---@param slot ("LEFT"|"CENTER"|"RIGHT")?
function Layout.RegisterElement(groupKey, elementKey, frame, slot)
	local existing = elements[elementKey]

	if existing then
		AMT.Util.Warn(
			"layout element %q is already registered in group %q; ignoring the one in %q.",
			elementKey,
			existing.group,
			groupKey
		)

		return
	end

	elements[elementKey] = { group = groupKey, frame = frame, slot = slot or "LEFT" }
	registrationOrder[#registrationOrder + 1] = elementKey

	SeedElement(elementKey)
end

function Layout.ReseedProfile()
	for _, elementKey in ipairs(registrationOrder) do
		SeedElement(elementKey)
	end
end

---@param elementKey string
---@param isCollapsed boolean
function Layout.SetCollapsed(elementKey, isCollapsed)
	if collapsed[elementKey] == isCollapsed then
		return
	end

	collapsed[elementKey] = isCollapsed

	AMT.State.MarkDirty("layout")
end

---@param groupKey AMTLayoutGroupKey
---@param width number the group's own width
---@return number height
local function ApplyInline(groupKey, width)
	local profile = AMT.Profiles.active.timer
	local group = groups[groupKey]
	local rowHeight = profile.keyInfo.height
	local boxWidth = width
	local origin = 0

	if profile.geometry ~= "SPAN" then
		boxWidth = math.min(profile.contentWidth, width)

		if profile.justify == "RIGHT" then
			origin = width - boxWidth
		elseif profile.justify == "CENTER" then
			origin = (width - boxWidth) / 2
		end
	end

	---@type table<string, string[]>
	local buckets = { LEFT = {}, CENTER = {}, RIGHT = {} }
	local shown = 0

	for _, elementKey in ipairs(profile.order[groupKey]) do
		local element = elements[elementKey]

		if element then
			local settings = profile.elements[elementKey]

			if settings and settings.enabled and not collapsed[elementKey] then
				local bucket = buckets[settings.slot] or buckets.LEFT

				bucket[#bucket + 1] = elementKey
				shown = shown + 1
			else
				element.frame:Hide()
			end
		end
	end

	if shown == 0 then
		return 0
	end

	for slot, bucket in pairs(buckets) do
		local widths = {}
		local total = math.max(#bucket - 1, 0) * ELEMENT_SPACING

		for index, elementKey in ipairs(bucket) do
			local frame = elements[elementKey].frame
			local content = frame.GetContentWidth and frame:GetContentWidth() or frame:GetWidth()

			widths[index] = content
			total = total + content
		end

		local x = origin

		if slot == "CENTER" then
			x = origin + (boxWidth - total) / 2
		elseif slot == "RIGHT" then
			x = origin + boxWidth - total
		end

		for index, elementKey in ipairs(bucket) do
			local settings = profile.elements[elementKey]
			local frame = elements[elementKey].frame

			frame:ClearAllPoints()
			frame:SetSize(math.max(widths[index], 1), rowHeight)
			frame:SetPoint("LEFT", group, "LEFT", x + settings.nudge[1], settings.nudge[2])
			frame:Show()

			x = x + widths[index] + ELEMENT_SPACING
		end
	end

	return rowHeight
end

---@param groupKey AMTLayoutGroupKey
---@param width number
---@return number height
local function ApplyGroup(groupKey, width)
	local profile = AMT.Profiles.active.timer

	if groupKey == "keyInfo" and profile.keyInfo.inline then
		return ApplyInline(groupKey, width)
	end

	local group = groups[groupKey]
	local spanning = profile.geometry == "SPAN"
	local y = 0

	for _, elementKey in ipairs(profile.order[groupKey]) do
		local element = elements[elementKey]

		if element then
			local settings = profile.elements[elementKey]
			local frame = element.frame

			if settings and settings.enabled and not collapsed[elementKey] then
				local nudge = settings.nudge
				local top = -y + nudge[2]

				frame:ClearAllPoints()

				if spanning then
					frame:SetWidth(0)
					frame:SetPoint("TOPLEFT", group, "TOPLEFT", nudge[1], top)
					frame:SetPoint("TOPRIGHT", group, "TOPRIGHT", nudge[1], top)
				else
					local point = JUSTIFY_POINTS[profile.justify] or "TOPRIGHT"

					frame:SetPoint(point, group, point, nudge[1], top)
					frame:SetWidth(profile.contentWidth)
				end

				frame:Show()

				y = y + frame:GetHeight() + ELEMENT_SPACING
			else
				frame:Hide()
			end
		end
	end

	return math.max(y - ELEMENT_SPACING, 0)
end

function Layout.Apply()
	local profile = AMT.Profiles.active.timer
	local root = AMT.Frames.root
	local background = profile.background
	local padding = background.enabled and background.padding or 0
	local y = padding
	local width = profile.width - padding * 2

	for _, groupKey in ipairs(profile.order.groups) do
		if groups[groupKey] then
			local height = ApplyGroup(groupKey, width)
			local group = groups[groupKey]

			if height > 0 then
				group:ClearAllPoints()
				group:SetPoint("TOPLEFT", root, "TOPLEFT", padding, -y)
				group:SetPoint("TOPRIGHT", root, "TOPRIGHT", -padding, -y)
				group:SetHeight(height)
				group:Show()

				y = y + height + GROUP_SPACING
			else
				group:Hide()
			end
		end
	end

	root:SetHeight(math.max(y - GROUP_SPACING + padding, 1))
end

AMT.Render.Register("layout", Layout.Apply)
