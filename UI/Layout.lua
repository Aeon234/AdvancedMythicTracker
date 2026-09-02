local AMT = select(2, ...)

local GROUP_SPACING = 4
local ELEMENT_SPACING = 2

---@alias AMTLayoutGroupKey "keyInfo"|"timer"|"objectives"|"forces"

---@class AMTLayoutElement
---@field group AMTLayoutGroupKey
---@field frame Frame

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

---@param groupKey AMTLayoutGroupKey
---@param elementKey string
---@param frame Frame
function Layout.RegisterElement(groupKey, elementKey, frame)
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

	elements[elementKey] = { group = groupKey, frame = frame }

	local profile = AMT.Profiles.active.timer
	local order = profile.order[groupKey]

	if not tContains(order, elementKey) then
		order[#order + 1] = elementKey
	end

	if not profile.elements[elementKey] then
		profile.elements[elementKey] = { enabled = true, nudge = { 0, 0 } }
	end
end

---@param groupKey AMTLayoutGroupKey
---@return number height
local function ApplyGroup(groupKey)
	local profile = AMT.Profiles.active.timer
	local group = groups[groupKey]
	local y = 0

	for _, elementKey in ipairs(profile.order[groupKey]) do
		local element = elements[elementKey]

		if element then
			local settings = profile.elements[elementKey]
			local frame = element.frame

			if settings and settings.enabled then
				local nudge = settings.nudge

				frame:ClearAllPoints()
				frame:SetPoint("TOPLEFT", group, "TOPLEFT", nudge[1], -y + nudge[2])
				frame:SetPoint("TOPRIGHT", group, "TOPRIGHT", nudge[1], -y + nudge[2])
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

	for _, groupKey in ipairs(profile.order.groups) do
		if groups[groupKey] then
			local height = ApplyGroup(groupKey)
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
