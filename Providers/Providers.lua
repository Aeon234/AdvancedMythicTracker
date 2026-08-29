local AMT = select(2, ...)

---@class AMTProviderSet
---@field LoadKey fun(): boolean
---@field UpdateForces fun()
---@field UpdateObjectives fun()
---@field UpdateDeaths fun()

---@class AMTProviders
---@field active AMTProviderSet!
local Providers = {}
AMT.Providers = Providers

---@type table<string, AMTProviderSet>
local sets = {}

---@param name string
---@param set AMTProviderSet
function Providers.Register(name, set)
	sets[name] = set
end

---@param name string
function Providers.Use(name)
	local set = sets[name]

	if not set then
		error(("no provider set named %q"):format(name), 2)
	end

	Providers.active = set
end
