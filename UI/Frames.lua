local AMT = select(2, ...)

local PLACEHOLDER_HEIGHT = 120

---@class AMTFrames
---@field unlocked boolean?
---@field root AMTDraggableMixin!
---@field background Texture!
---@field fill AMTBorder?
---@field ring AMTBorder?
local Frames = {}
AMT.Frames = Frames

---@return AMTTimerProfile
local function TimerProfile()
	return AMT.Profiles.active.timer
end

function Frames.ApplyProfile()
	local profile = TimerProfile()
	local background = profile.background
	local color = background.color
	local nineslice = background.enabled and background.nineslice

	Frames.root:SetWidth(profile.width)
	Frames.root:SetScale(profile.scale)
	Frames.root:ApplyPosition(profile.position)

	Frames.background:SetColorTexture(color[1], color[2], color[3], color[4])
	Frames.background:SetShown(background.enabled and not nineslice)

	if Frames.fill then
		Frames.fill:SetVertexColor(color[1], color[2], color[3], color[4])
		Frames.fill:SetShown(nineslice)
	end

	if Frames.ring then
		Frames.ring:SetShown(nineslice)
	end
end

--- Called once from Core/Bootstrap.lua after profiles are resolved.
function Frames.Initialize()
	local root = AMT.Mixins.MakeDraggable(CreateFrame("Frame", "AdvancedMythicTrackerFrame", UIParent))

	root:SetSize(TimerProfile().width, PLACEHOLDER_HEIGHT)
	root:SetFrameStrata("MEDIUM")
	root:Hide()

	Frames.background = root:CreateTexture(nil, "BACKGROUND")
	Frames.background:SetAllPoints()
	Frames.fill = AMT.NineSlice.Apply(root, "Solid", nil, "BACKGROUND", 0)
	Frames.ring = AMT.NineSlice.Apply(root, "Ring", nil, "BACKGROUND", 1)

	root.OnPositionChanged = function(_, position)
		local stored = TimerProfile().position

		stored.anchor = position.anchor
		stored.x = position.x
		stored.y = position.y
	end

	Frames.root = root

	Frames.ApplyProfile()
end

---@param unlocked boolean
function Frames.SetUnlocked(unlocked)
	Frames.unlocked = unlocked
	Frames.root:SetUnlocked(unlocked)
	Frames.root:SetShown(unlocked or Frames.shouldShow == true)
end

---@return boolean
function Frames.IsUnlocked()
	return Frames.unlocked == true
end

---@param shown boolean
function Frames.SetShown(shown)
	Frames.shouldShow = shown
	Frames.root:SetShown(shown)
end
