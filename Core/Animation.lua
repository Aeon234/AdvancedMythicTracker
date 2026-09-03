local AMT = select(2, ...)

---@class AMTAnimation
local Animation = {}
AMT.Animation = Animation

---@param t number normalised 0-1
---@return number
function Animation.EaseOutCubic(t)
	local inverse = 1 - t

	return 1 - inverse * inverse * inverse
end

---@param frame Frame frame whose OnUpdate drives the tween
---@param duration number seconds
---@param apply fun(eased: number)
function Animation.Run(frame, duration, apply)
	local elapsed = 0

	frame:SetScript("OnUpdate", function(_, delta)
		elapsed = elapsed + delta

		local progress = elapsed / duration

		if progress >= 1 then
			progress = 1

			frame:SetScript("OnUpdate", nil)
		end

		apply(Animation.EaseOutCubic(progress))
	end)
end

---@param frame Frame
function Animation.Stop(frame)
	frame:SetScript("OnUpdate", nil)
end
