local AMT = select(2, ...)

local PLACEHOLDER_WIDTH = 320
local PLACEHOLDER_HEIGHT = 120

---@class AMTFrames
---@field root AMTDraggableMixin!
local Frames = {}
AMT.Frames = Frames

---@return AMTTimerProfile
local function TimerProfile()
	return AMT.Profiles.active.timer
end

function Frames.ApplyProfile()
	local profile = TimerProfile()

	Frames.root:SetScale(profile.scale)
	Frames.root:ApplyPosition(profile.position)
end

--- Called once from Core/Bootstrap.lua after profiles are resolved.
function Frames.Initialize()
	local root = AMT.Mixins.MakeDraggable(CreateFrame("Frame", "AdvancedMythicTrackerFrame", UIParent))

	root:SetSize(PLACEHOLDER_WIDTH, PLACEHOLDER_HEIGHT)
	root:SetFrameStrata("MEDIUM")
	root:Hide()

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
