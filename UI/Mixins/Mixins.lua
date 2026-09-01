local AMT = select(2, ...)

---@class AMTMixins
---@field Bar AMTBarMixin
---@field NewBar fun(parent: Frame): AMTBarMixin
---@field Text AMTTextMixin
---@field NewText fun(parent: Frame, layer: DrawLayer?): AMTTextMixin
local Mixins = {}
AMT.Mixins = Mixins
