local AMT = select(2, ...)

---@class AMTEvents
local Events = {}
AMT.Events = Events

---@class AMTEventListener
---@field module AMTModule
---@field handler fun(module:AMTModule,event: string,...:any)
---@field challenge boolean

---@type table<string,AMTEventListener[]>
local listeners = {}

local frame = CreateFrame("Frame")

frame:SetScript("OnEvent", function(_, event, ...)
	local entries = listeners[event]
	if not entries then
		return
	end

	for index = 1, #entries do
		local entry = entries[index]
		entry.handler(entry.module, event, ...)
	end
end)

---@param entries AMTEventListener[]
---@param module AMTModule
---@return integer?
local function IndexOf(entries, module)
	for index = 1, #entries do
		if entries[index].module == module then
			return index
		end
	end
end

---@param event string
---@param module AMTModule
---@param handler fun(module: AMTModule, event: string, ...: any)
---@param challenge boolean
local function Add(event, module, handler, challenge)
	local entries = listeners[event]

	if not entries then
		entries = {}
		listeners[event] = entries
		frame:RegisterEvent(event)
	end

	if IndexOf(entries, module) then
		AMT.Util.Warn("module %q already listens for %s; ignoring the duplicate.", module.name, event)
		return
	end

	entries[#entries + 1] = { module = module, handler = handler, challenge = challenge }
end

---Registering for whole play session
---@param event string
---@param module AMTModule
---@param handler fun(module: AMTModule, event: string, ...: any)
function Events.Register(event, module, handler)
	Add(event, module, handler, false)
end

---Registering only for the duration of the key
---@param event string
---@param module AMTModule
---@param handler fun(module: AMTModule, event: string, ...: any)
function Events.RegisterChallenge(event, module, handler)
	Add(event, module, handler, true)
end

---@param event string
---@param module AMTModule
function Events.Unregister(event, module)
	local entries = listeners[event]

	if not entries then
		return
	end

	local index = IndexOf(entries, module)

	if not index then
		return
	end

	table.remove(entries, index)

	if #entries == 0 then
		listeners[event] = nil
		frame:UnregisterEvent(event)
	end
end

---@param module AMTModule
function Events.UnregisterAll(module)
	for event in pairs(listeners) do
		Events.Unregister(event, module)
	end
end

---Removes all challenge-scoped listeners.
function Events.UnregisterChallenge()
	for event, entries in pairs(listeners) do
		for index = #entries, 1, -1 do
			if entries[index].challenge then
				table.remove(entries, index)
			end
		end

		if #entries == 0 then
			listeners[event] = nil
			frame:UnregisterEvent(event)
		end
	end
end
