local AMT = select(2, ...)

---@class AMTMixins
---@field Bar AMTBarMixin
---@field NewBar fun(parent: Frame): AMTBarMixin
---@field Text AMTTextMixin
---@field NewText fun(parent: Frame, layer: DrawLayer?): AMTTextMixin
---@field Draggable AMTDraggableMixin
---@field MakeDraggable fun(frame: Frame): AMTDraggableMixin
local Mixins = {}
AMT.Mixins = Mixins
