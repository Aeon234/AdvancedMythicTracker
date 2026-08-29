local AMT = select(2, ...)

local State = AMT.State

-- Just setting this up in case Blizz ever decides to let current pull tracking happen...

---@class AMTPull
local Pull = {}
AMT.Pull = Pull

function Pull.Update()
	local state = State.current

	state.pullCount = 0
	state.pullPercent = 0
end
