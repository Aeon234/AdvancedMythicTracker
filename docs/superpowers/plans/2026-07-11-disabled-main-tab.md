# Disabled-State Main Tab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The PVEFrame Main Tab shows Blizzard's stock disabled-tab treatment (grey font, inactive textures, clicks blocked, lock-reason tooltip) whenever the player is not max level, no Mythic+ season is active, or the character is a Timerunner — and cleans up the duplicated eligibility logic while doing it.

**Architecture:** Eligibility becomes one pure function in `Util.lua` returning `(eligible, reasonKey)`. Visual application becomes `AMT.UpdateMainTabState()` in `Dashboard.lua`, using `PanelTemplates_SetDisabledTabState(tab)` / `PanelTemplates_DeselectTab(tab)`. All three previous copies of the condition logic (toggle guard, Util check, tab text hack) route through the single pair.

**Tech Stack:** WoW retail 12.x (Interface 120007), Lua 5.1, FrameXML PanelTemplates.

## Global Constraints

- Lua 5.1 only; `luac -p` after every file edit.
- Every user-facing string is a locale key `L["KEY"]` defined in `Locales\enUS.lua` before use.
- No new globals except intentional frame names (`AdvancedMythicTracker*`). The existing global function `AdvancedMythicTracker_ToggleDashboard` is REMOVED and replaced by `AMT.ToggleDashboard`.
- No automated test harness exists (WoW addon) — each task's test cycle is `luac -p` + the in-game checklist at the end; in-game verification is Alex's.
- Verified APIs (wow-ui-source `live`, Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.lua unless noted):
  - `PanelTemplates_SetDisabledTabState(tab)` — line 547: shows inactive textures, `tab:Disable()`, grey `GameFontDisableSmall`.
  - `PanelTemplates_DeselectTab(tab)` — line 505: shows inactive textures, `tab:Enable()`.
  - `Button:SetMotionScriptsWhileDisabled(bool)` — widget method, used throughout Blizzard code (e.g. Blizzard_Menu/MenuTemplates.lua:126).
  - `C_MythicPlus.IsMythicPlusActive()` — Blizzard gates ChallengesFrame with it (Blizzard_GroupFinder/Mainline/PVEFrame.lua:420).
  - `UnitLevel("player") >= GetMaxLevelForPlayerExpansion()` — Blizzard's own ChallengesFrame level gate (PVEFrame.lua:10).
  - `PlayerGetTimerunningSeasonID()` — PlayerScriptDocumentation.lua:1351; returns seasonID or nil.
  - `C_MythicPlus.GetCurrentUIDisplaySeason()` — **nilable** (MythicPlusInfoDocumentation.lua:41-48); Blizzard nil-guards it in ChallengesFrameMixin:UpdateTitle (Blizzard_ChallengesUI.lua:269-280).

---

### Task 1: Locale keys

**Files:**
- Modify: `Locales\enUS.lua` (whole file, currently 6 lines)

**Interfaces:**
- Produces: keys `TAB_NAME`, `DASHBOARD_TITLE`, `DASHBOARD_TITLE_NO_SEASON`, `TAB_LOCKED_TIMERUNNER`, `TAB_LOCKED_NOT_MAX_LEVEL`, `TAB_LOCKED_NO_SEASON` — consumed by Tasks 2 and 3.

- [ ] **Step 1: Replace file content**

```lua
local AMT = select(2, ...) ---@class AMT
---@class L
local L = AMT.L

-- --- Main Tab ---------------------------------------------------------------
L["TAB_NAME"] = "Mythic+ Tracker"
L["TAB_LOCKED_TIMERUNNER"] = "Not available on Timerunning characters."
L["TAB_LOCKED_NOT_MAX_LEVEL"] = "Available at maximum level."
L["TAB_LOCKED_NO_SEASON"] = "No Mythic+ season is currently active."

-- --- Dashboard --------------------------------------------------------------
L["DASHBOARD_TITLE"] = "Advanced Mythic+ Tracker (%s Season %d)"
L["DASHBOARD_TITLE_NO_SEASON"] = "Advanced Mythic+ Tracker"
```

- [ ] **Step 2: Verify**

Run: `luac -p "Locales\enUS.lua"` — expect silence.

### Task 2: Pure eligibility check in Util.lua

**Files:**
- Modify: `Util.lua` (whole file, currently 33 lines)

**Interfaces:**
- Produces: `AMT.GetTabEligibility() -> boolean eligible, string|nil reasonKey` and `AMT.GetPVEFrameTabNums() -> integer` — consumed by Task 3.
- The old side-effecting `AMT.GetTabEligibility` (Enable/Disable + SetText) is replaced; visuals move to Task 3's `AMT.UpdateMainTabState`.

- [ ] **Step 1: Replace file content**

```lua
local AMT = select(2, ...) ---@class AMT

-- Pure helpers shared across the addon. No UI side effects in this file —
-- anything that touches frames lives with the frame's owner (e.g. Dashboard.lua).

---Loops through PVEFrame's numTabs and counts how many are visible.
---@return integer
function AMT.GetPVEFrameTabNums()
	local tabs = 0
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if PVEFrame_Tab and PVEFrame_Tab:IsVisible() then
			tabs = tabs + 1
		end
	end

	return tabs
end

---Evaluate whether the Main Tab is usable right now. Pure check, no side
---effects; visuals are applied by AMT.UpdateMainTabState (Dashboard.lua).
---Conditions mirror Blizzard's ChallengesFrame gating (Blizzard_GroupFinder/PVEFrame.lua).
---@return boolean eligible
---@return string|nil reasonKey locale key describing why the tab is locked
function AMT.GetTabEligibility()
	if PlayerGetTimerunningSeasonID() then
		return false, "TAB_LOCKED_TIMERUNNER"
	end
	if UnitLevel("player") < GetMaxLevelForPlayerExpansion() then
		return false, "TAB_LOCKED_NOT_MAX_LEVEL"
	end
	if not C_MythicPlus.IsMythicPlusActive() then
		return false, "TAB_LOCKED_NO_SEASON"
	end

	return true, nil
end
```

- [ ] **Step 2: Verify**

Run: `luac -p Util.lua` — expect silence.

### Task 3: Dashboard.lua rework

**Files:**
- Modify: `Dashboard.lua` (whole-file replacement, currently 101 lines)

**Interfaces:**
- Consumes: `AMT.GetTabEligibility()`, `AMT.GetPVEFrameTabNums()` (Task 2); locale keys (Task 1); `AMT.RegisterEvent` (Core.lua).
- Produces: `AMT.ToggleDashboard()` (consumed by Task 4), `AMT.UpdateMainTabState()`, `AMT.Dashboard`, `AMT.MainTab`.

Fixes folded in (each was a live bug or CLAUDE.md violation):
- FIX-A: `PVEFrame:GetHeight()` was evaluated at file-load time (load-order hazard) — moved inside `CreateDashboard`.
- FIX-B: PVEFrame tab `OnClick` hooks were re-added on EVERY PVEFrame OnShow — `HookScript` stacks, so handlers accumulated. Hooks now installed once at creation.
- FIX-C: title concatenated nilable `GetCurrentUIDisplaySeason()` — now guarded like Blizzard does, and refreshed on show since season data can arrive late.
- FIX-D: global `AdvancedMythicTracker_ToggleDashboard` removed → `AMT.ToggleDashboard`.
- FIX-E: hardcoded `"|cff808080Mythic+ Tracker"` (unterminated color code, never reset on re-enable) — replaced by the stock disabled font object.

- [ ] **Step 1: Replace file content**

```lua
local AMT = select(2, ...) ---@class AMT
---@class L
local L = AMT.L

-- Dashboard window and its PVEFrame tab. The tab uses Blizzard's stock
-- disabled-tab treatment when eligibility fails (pure check lives in Util.lua);
-- the lock reason is surfaced as a tooltip on the disabled tab, which requires
-- motion scripts to stay enabled while the button is disabled.

-- ========================
-- === Toggle Dashboard ===
-- ========================

---Toggle the dashboard. No-ops in combat or while the tab is locked.
function AMT.ToggleDashboard()
	if InCombatLockdown() or not AMT.GetTabEligibility() then
		return
	end

	AMT.Dashboard:SetShown(not AMT.Dashboard:IsShown())
end

-- ========================
-- === Main Tab State  ====
-- ========================

---Apply enabled/disabled visuals and click behavior to the Main Tab.
---Safe to call any time after PLAYER_LOGIN; no-ops before the tab exists.
function AMT.UpdateMainTabState()
	local tab = AMT.MainTab
	if not tab then
		return
	end

	local eligible, reasonKey = AMT.GetTabEligibility()
	tab.lockReasonKey = reasonKey

	if eligible then
		PanelTemplates_DeselectTab(tab)
	else
		PanelTemplates_SetDisabledTabState(tab)
		if AMT.Dashboard and AMT.Dashboard:IsShown() then
			AMT.Dashboard:Hide()
		end
	end
end

-- ==========================
-- === Dashboard Creation ===
-- ==========================

local AMT_WINDOW_WIDTH = 960
local AMT_FALLBACK_HEIGHT = 428

---Season data is nil early in a session; Blizzard guards the same way in
---ChallengesFrameMixin:UpdateTitle.
---@return string
local function GetDashboardTitle()
	local season = C_MythicPlus.GetCurrentUIDisplaySeason()
	if not season then
		return L["DASHBOARD_TITLE_NO_SEASON"]
	end

	local expName = _G["EXPANSION_NAME" .. GetExpansionLevel()]
	return string.format(L["DASHBOARD_TITLE"], expName, season)
end

local function CreateDashboard()
	if AMT.Dashboard then
		return
	end

	local f = CreateFrame("Frame", "AdvancedMythicTracker", UIParent, "AdvancedMythicTrackerBlizzard")
	f:SetSize(AMT_WINDOW_WIDTH, PVEFrame:GetHeight() or AMT_FALLBACK_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("HIGH")
	f:SetTitle(GetDashboardTitle())

	-- Movable
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)

	f:SetScript("OnShow", function(self)
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		self:SetTitle(GetDashboardTitle()) -- season data may have arrived since creation
	end)
	f:SetScript("OnHide", function()
		PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
	end)

	-- Escape closes the dashboard
	table.insert(UISpecialFrames, "AdvancedMythicTracker")

	AMT.Dashboard = f

	-- PVEFrame Dashboard Tab Button
	local tabNum = PVEFrame.numTabs + 1
	local tab = CreateFrame("Button", "AdvancedMythicTrackerTab", PVEFrame, "PanelTabButtonTemplate", tabNum)
	tab:SetText(L["TAB_NAME"])
	tab:SetMotionScriptsWhileDisabled(true) -- keep OnEnter alive while disabled for the lock tooltip
	PanelTemplates_DeselectTab(tab)
	AMT.MainTab = tab

	tab:SetScript("OnClick", function()
		AMT.ToggleDashboard()
	end)
	tab:SetScript("OnEnter", function(self)
		if self.lockReasonKey then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["TAB_NAME"], 1, 1, 1)
			GameTooltip:AddLine(L[self.lockReasonKey], nil, nil, nil, true)
			GameTooltip:Show()
		end
	end)
	tab:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- One-time hooks. HookScript STACKS handlers — installing these inside the
	-- OnShow hook (previous code) added a duplicate set on every PVEFrame open.
	PVEFrame:HookScript("OnShow", function()
		AMT.UpdateMainTabState()

		local lastTab = AMT.GetPVEFrameTabNums()
		tab:SetPoint("LEFT", PVEFrame.Tabs[lastTab], "RIGHT", 3, 0)
	end)
	for i = 1, PVEFrame.numTabs do
		local PVEFrame_Tab = _G["PVEFrameTab" .. i]
		if PVEFrame_Tab then
			PVEFrame_Tab:HookScript("OnClick", function()
				AMT.UpdateMainTabState() -- re-assert deselected/disabled visuals
			end)
		end
	end

	AMT.UpdateMainTabState()
end

AMT.RegisterEvent("PLAYER_LOGIN", function()
	CreateDashboard()
end)
AMT.RegisterEvent("PLAYER_LEVEL_UP", function()
	AMT.UpdateMainTabState()
end)
```

- [ ] **Step 2: Verify**

Run: `luac -p Dashboard.lua` — expect silence.

### Task 4: Core.lua slash handler

**Files:**
- Modify: `Core.lua:53-59` (SlashHandler only)

**Interfaces:**
- Consumes: `AMT.ToggleDashboard` (Task 3). The global `AdvancedMythicTracker_ToggleDashboard` no longer exists after Task 3 — this edit MUST land in the same session.

- [ ] **Step 1: Replace SlashHandler body**

Old:

```lua
local function SlashHandler()
	if AMT.Dashboard then
		AdvancedMythicTracker_ToggleDashboard()
	else
		AMT:Print("Options UI failed to load. Try /reload.")
	end
end
```

New:

```lua
local function SlashHandler()
	if AMT.Dashboard then
		AMT.ToggleDashboard()
	else
		AMT:Print("Options UI failed to load. Try /reload.")
	end
end
```

(The error string stays as-is for now; locale-izing Core.lua's diagnostics is out of scope — flagged separately in review.)

- [ ] **Step 2: Verify**

Run: `luac -p Core.lua` — expect silence.

### Task 5: Final verification (main session)

- [ ] `luac -p Core.lua Util.lua Dashboard.lua Locales\enUS.lua` — expect silence.
- [ ] Grep: `AdvancedMythicTracker_ToggleDashboard` must have zero remaining references.
- [ ] Review full diff against this plan.

## Design choices surfaced (Alex decides, defaults chosen)

1. **InCombatLockdown gate kept** in `ToggleDashboard`. Frame is insecure, so the gate isn't technically required — kept because it was there deliberately.
2. **Tab never shows the "selected" texture.** `PanelTemplates_SelectTab` disables the button (Blizzard selected tabs don't take clicks), which would break click-to-close toggling. Deliberately skipped.
3. **Escape-close added** via `UISpecialFrames` — new behavior, small and standard; drop the `table.insert` line if unwanted.
4. **Close sound added** (`IG_CHARACTER_INFO_CLOSE`) to match the open sound.
5. **Lock reasons are static strings** (no "%d" level formatting) — YAGNI until more dynamic text is needed.
6. **Eligibility re-checks:** PVEFrame OnShow + PLAYER_LEVEL_UP. Season flips mid-session are not evented here; the OnShow re-check covers the practical case.

## In-game checklist (Alex)

1. `/reload` on a max-level, non-Timerunner character with an active season → PVEFrame Group Finder: AMT tab enabled, normal text; click toggles dashboard; Escape closes it; open/close sounds play.
2. Title reads "Advanced Mythic+ Tracker (<Expansion> Season <n>)" — reopen once if it shows the no-season fallback on first login frame.
3. On a sub-max character (or Timerunner): tab greyed with disabled texture, click does nothing, hover shows lock-reason tooltip.
4. `/amt` on ineligible character → nothing opens.
5. Open PVEFrame 5×, then click a Blizzard tab once → no lag/stutter, AMT tab deselects (hook-stacking fix).
6. Paste any Lua error verbatim.

## Execution Status

- Task 1: done (enUS.lua replaced verbatim in main session, luac -p clean)
- Task 2: done (Util.lua replaced verbatim in main session, luac -p clean)
- Task 3: done (Dashboard.lua replaced verbatim by plan-executor, 148 lines, luac -p clean, no deviations)
- Task 4: done (Core.lua SlashHandler now calls AMT.ToggleDashboard, luac -p clean)
- Task 5: done (luac -p all four files silent; zero references to AdvancedMythicTracker_ToggleDashboard remain; Dashboard.lua reviewed against plan — verbatim match)
- Post-plan deviation (Alex-requested): `AMT.GetTabEligibility` renamed to `AMT.IsTabEligible` (pure predicate naming); call sites in Dashboard.lua updated, luac -p clean.
