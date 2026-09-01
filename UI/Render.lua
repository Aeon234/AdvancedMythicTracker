local AMT = select(2, ...)

local DEFAULT_INTERVAL = 0.1

---@type AMTDirtyKey[]
local DISPATCH_ORDER = { "keyInfo", "timer", "objectives", "forces", "deaths", "layout" }

---@alias AMTRenderCallback fun()

---@class AMTRender
---@field ticker FunctionContainer?
local Render = {}
AMT.Render = Render

---@type table<AMTDirtyKey, AMTRenderCallback[]>
local handlers = {}

local interval = DEFAULT_INTERVAL

---@param key AMTDirtyKey
---@param callback AMTRenderCallback
function Render.Register(key, callback)
	local list = handlers[key]

	if not list then
		list = {}
		handlers[key] = list
	end

	list[#list + 1] = callback
end

function Render.Flush()
	for index = 1, #DISPATCH_ORDER do
		local key = DISPATCH_ORDER[index]

		if AMT.State.IsDirty(key) then
			local list = handlers[key]

			if list then
				for _, callback in ipairs(list) do
					callback()
				end
			end
		end
	end

	AMT.State.ClearDirty()
end

local function OnTick()
	AMT.State.current.elapsed = select(2, GetWorldElapsedTime(1))
	AMT.State.MarkDirty("timer")

	Render.Flush()
end

function Render.StartTicker()
	if Render.ticker then
		return
	end

	Render.ticker = C_Timer.NewTicker(interval, OnTick)
end

function Render.StopTicker()
	if not Render.ticker then
		return
	end

	Render.ticker:Cancel()
	Render.ticker = nil
end

---@param seconds number
function Render.SetInterval(seconds)
	interval = seconds

	if Render.ticker then
		Render.StopTicker()
		Render.StartTicker()
	end
end
