local AMT = select(2, ...)

---@class AMTModule
---@field name string
---@field enabled boolean
---@field OnInitialize fun(self:AMTModule)?
---@field OnEnable fun(self: AMTModule)?
---@field OnDisable fun(self:AMTModule)?
---@field OnProfileChanged fun(self:AMTModule)?
---@field OnChallengeStart fun(self:AMTModule)?
---@field OnChallengeEnd fun(self:AMTModule,completed:boolean)?

---@class AMTModules
local Modules = {}
AMT.Modules = Modules

---@type table<string,AMTModule>
local byName = {}

---@type AMTModule[]
local inOrder = {}

---@param name string
---@return AMTModule
function Modules.New(name)
	if byName[name] then
		error(("module%q already registered"):format(name), 2)
	end

	---@type AMTModule
	local module = { name = name, enabled = false }

	byName[name] = module
	inOrder[#inOrder + 1] = module

	return module
end

---@param name string
---@return AMTModule?
function Modules.Get(name)
	return byName[name]
end

---@return fun(): AMTModule?
function Modules.Iterate()
	local index = 0

	return function()
		index = index + 1
		return inOrder[index]
	end
end

---@param module AMTModule
function Modules.Enable(module)
	if module.enabled then
		return
	end

	module.enabled = true

	if module.OnEnable then
		module:OnEnable()
	end
end

---@param module AMTModule
function Modules.Disable(module)
	if not module.enabled then
		return
	end

	if module.OnDisable then
		module:OnDisable()
	end

	module.enabled = false
end
