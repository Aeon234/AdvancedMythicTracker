local AMT = select(2, ...)

---@class AMTMixins
---@field Bar AMTBarMixin
---@field NewBar fun(parent: Frame): AMTBar
local Mixins = {}
AMT.Mixins = Mixins
