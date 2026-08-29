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
---@return boolean
function Providers.Use(name)
	local set = sets[name]

	if not set then
		AMT.Util.Warn("no provider set named %q; keeping the current one.", name)
		return false
	end

	Providers.active = set

	return true
end
