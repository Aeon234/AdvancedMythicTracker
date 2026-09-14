local AMT = select(2, ...)

---@class AMTDashboard
---@field Skin AMTDashboardSkin
---@field IconMixin AMTDashboardIconMixin
---@field NewIcon fun(parent: Frame, kind: AMTDashboardIconKind, size: number, corner: number): AMTDashboardIconMixin
---@field Panel AMTDashboardPanel
---@field Host AMTDashboardHost
---@field Parts AMTDashboardParts
---@field Source AMTDashboardSource
---@field Band AMTDashboardBand
local Dashboard = {}
AMT.Dashboard = Dashboard
