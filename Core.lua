-- ================================
-- === Namespace & Localization ===
-- ================================

local addonName, addon = ...
local AMT = addon ---@class AMT
AMT.addonName = addonName
AMT.addonVersion = C_AddOns.GetAddOnMetadata(AMT.addonName, "Version")

---@class L
AMT.L = setmetatable({}, {
    __index = function(_, key)
        return key
    end,
})

local CreateFrame = CreateFrame
local SlashCmdList = SlashCmdList
local type = type
local pairs = pairs
local ipairs = ipairs
local lower = string.lower
local _G = _G

-- ===================
-- === Diagnostics ===
-- ===================

local PRINT_PREFIX = "|cffffd200[" .. AMT.addonName .. "]|r"

function AMT:Print(...)
    print(PRINT_PREFIX, ...)
end

-- =======================
-- === Slash Commands ===
-- =======================
function AMT:RegisterSlashCommand(name, aliases, func)
    if type(aliases) == "string" then
        aliases = { aliases }
    elseif type(aliases) ~= "table" then
        return
    end

    name = name:upper()
    for i, alias in ipairs(aliases) do
        _G["SLASH_" .. name .. i] = "/" .. lower(alias)
    end
    SlashCmdList[name] = func
end

local function SlashHandler()
    if AMT.Dashboard then
        AMT:OpenDashboard()
    else
        AMT:Print("Options UI failed to load. Try /reload.")
    end
end

AMT:RegisterSlashCommand("ADVANCEDMYTHICTRACKER", { "amt" }, SlashHandler)

-- ==========================
-- === Master Event Frame ===
-- ==========================

local EventFrame = CreateFrame("Frame")
AMT.EventFrame = EventFrame

-- Module-facing WoW-event dispatcher. Instead of every module spawning its own
-- frame, modules subscribe through AMT.RegisterEvent and this single frame fans the
-- event out. The underlying WoW event is registered on the first subscriber and
-- unregistered when the last one leaves (Core's own bootstrap events excepted).
local eventListeners = {} -- event -> { {func, owner}, ... }
local PERMANENT_EVENTS = { ADDON_LOADED = true }

function EventFrame:OnEvent(event, ...)
    -- Core bootstrap stays internal so its registration is never ref-counted away.
    if event == "ADDON_LOADED" then
        self:ADDON_LOADED(...)
    end

    local list = eventListeners[event]
    if not list then
        return
    end
    -- Snapshot: a handler may (un)subscribe mid-dispatch (e.g. combat deferral).
    local n = #list
    local snapshot = {}
    for i = 1, n do
        snapshot[i] = list[i]
    end
    for i = 1, n do
        local cb = snapshot[i]
        if cb[2] ~= nil then
            cb[1](cb[2], event, ...)
        else
            cb[1](event, ...)
        end
    end
end

EventFrame:SetScript("OnEvent", EventFrame.OnEvent)

---Subscribe to a WoW event. The callback receives (event, ...), or (owner, event,
---...) when an owner is given. Idempotent for the same (func, owner) pair.
---@param event string
---@param func function
---@param owner? table passed as the first arg to func
---@return boolean registered false when the event doesn't exist on this client
function AMT.RegisterEvent(event, func, owner)
    if C_EventUtils and C_EventUtils.IsEventValid and not C_EventUtils.IsEventValid(event) then
        return false -- event doesn't exist on this client flavor; skip silently
    end
    local list = eventListeners[event]
    if not list then
        list = {}
        eventListeners[event] = list
        EventFrame:RegisterEvent(event)
    else
        for i = 1, #list do
            if list[i][1] == func and list[i][2] == owner then
                return true -- already subscribed
            end
        end
    end
    list[#list + 1] = { func, owner }
    return true
end

---Unsubscribe. Removes entries matching func (and owner, when given). When the
---last subscriber leaves, the WoW event is unregistered (unless permanent).
---@param event string
---@param func function
---@param owner? table
function AMT.UnregisterEvent(event, func, owner)
    local list = eventListeners[event]
    if not list then
        return
    end
    for i = #list, 1, -1 do
        if list[i][1] == func and (owner == nil or list[i][2] == owner) then
            table.remove(list, i)
        end
    end
    if #list == 0 then
        eventListeners[event] = nil
        if not PERMANENT_EVENTS[event] then
            EventFrame:UnregisterEvent(event)
        end
    end
end

function EventFrame:ADDON_LOADED(name)
    if name ~= AMT.addonName then
        return
    end
    self:UnregisterEvent("ADDON_LOADED")
    AMT:Print(AMT.addonVersion .. " loaded.")

    AMT:CreateDashboard()
end

EventFrame:RegisterEvent("ADDON_LOADED")
