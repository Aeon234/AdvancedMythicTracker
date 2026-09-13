local AMT = select(2, ...)

local DEFAULT_INTERVAL = 0.1

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

local MAX_PASSES = 3

function Render.Flush()
	local keys = AMT.State.DIRTY_KEYS

	for _ = 1, MAX_PASSES do
		local ran = false

		for index = 1, #keys do
			local key = keys[index]

			if AMT.State.IsDirty(key) then
				AMT.State.ClearDirtyKey(key)

				local list = handlers[key]

				if list then
					for _, callback in ipairs(list) do
						callback()
					end
				end

				ran = true
			end
		end

		if not ran then
			return
		end
	end

	AMT.State.ClearDirty()
end

local function OnTick()
	AMT.Providers.active.Tick()
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
