local AMT = select(2, ...)

local PLACEHOLDER_HEIGHT = 120

---@class AMTFrames
---@field root AMTDraggableMixin!
---@field background Texture!
local Frames = {}
AMT.Frames = Frames

---@return AMTTimerProfile
local function TimerProfile()
	return AMT.Profiles.active.timer
end

function Frames.ApplyProfile()
	local profile = TimerProfile()
	local background = profile.background

	Frames.root:SetWidth(profile.width)
	Frames.root:SetScale(profile.scale)
	Frames.root:ApplyPosition(profile.position)

	if background.enabled then
		local color = background.color

		Frames.background:SetColorTexture(color[1], color[2], color[3], color[4])
		Frames.background:Show()
	else
		Frames.background:Hide()
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
	Frames.root:SetUnlocked(unlocked)
	Frames.root:SetShown(unlocked or Frames.shouldShow == true)
end

---@param shown boolean
function Frames.SetShown(shown)
	Frames.shouldShow = shown
	Frames.root:SetShown(shown)
end
