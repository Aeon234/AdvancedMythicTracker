# Dashboard-as-PVEFrame-Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The dashboard looks and behaves like a fourth PVEFrame panel: it carries a mirrored copy of PVEFrame's tab row (with the addon's tab shown active), swaps in at PVEFrame's exact screen position when opened from the PVEFrame tab, returns to the matching PVEFrame panel when a mirrored Blizzard tab is clicked, and plays the tab-click sound for tab transitions vs. the window-open sound for `/amt`/keybind.

**Architecture:** Everything lands in `Dashboard.lua` (whole-file replacement; no other file changes — no new locale strings, Core.lua untouched). A `PVE_PANELS` list mirrors Blizzard's private `panels` table by index. Four `PanelTabButtonTemplate` buttons live on the dashboard (`f.Tabs`, `f.numTabs`), driven by stock `PanelTemplates_SetTab`/`PanelTemplates_UpdateTabs`. Open-sound selection travels via a one-shot `f.openSoundKit` field consumed in `OnShow`; a one-shot `f.suppressCloseSound` flag silences `OnHide` during tab transitions.

**Tech Stack:** WoW retail 12.x (Interface 120007), Lua 5.1, FrameXML PanelTemplates + PVEFrame globals.

## Global Constraints

- Lua 5.1 only; `luac -p` after the file edit.
- User-facing strings only via `L["KEY"]` — this feature adds none (mirrored tab labels are copied live from Blizzard's buttons, so localization is inherited).
- No new globals except intentional frame names: `AdvancedMythicTrackerDashboardTab1..4`.
- In-game verification is Alex's; the checklist is at the end.
- Verified APIs (wow-ui-source `live`):
  - `PVEFrame_ShowFrame(sidePanelName)` — global, Blizzard_GroupFinder/Mainline/PVEFrame.lua:58; loads the panel's addon on demand, calls `ShowUIPanel(PVEFrame)`, selects the tab.
  - Blizzard's private `panels` list order (PVEFrame.lua:7-11): index 1 `GroupFinderFrame`, 2 `PVPUIFrame`, 3 `ChallengesFrame`; `PVEFrameTab<i>` matches by id.
  - **`PVEFrame.Tabs` does NOT exist** — the XML gives tabs `parentKey` `tab1/2/3` only (PVEFrame.xml:165-183) and nothing assigns a `Tabs` array (grep-verified). The current `PVEFrame.Tabs[lastTab]` in Dashboard.lua:127 is a live nil-index bug this plan fixes via `_G["PVEFrameTab" .. i]` (same fallback PanelTemplates itself uses, SharedUIPanelTemplates.lua:355-356).
  - PVEFrame tab row geometry (PVEFrame.xml:165-186): tab1 at `BOTTOMLEFT` +19/-30 of the frame; each next tab `LEFT` → prev `RIGHT` x -16.
  - `PVEFrameMixin:OnShow` (PVEFrame.lua:414-438): re-shows/hides/disables its tabs, hides ALL tabs for timerunners, and **always plays `SOUNDKIT.IG_CHARACTER_INFO_OPEN`** (:436). `PVEFrameMixin:OnHide` **always plays `IG_CHARACTER_INFO_CLOSE`** (:442). Neither can be suppressed without tainting PVEFrame.
  - `PanelTemplates_SetTab(frame, id)` (SharedUIPanelTemplates.lua:346) + `PanelTemplates_UpdateTabs` (:359) — resolve tabs via `frame.Tabs[i]` (:355), select id, deselect the rest.
  - `PanelTemplates_TabResize(tab, padding)` — SharedUIPanelTemplates.lua:382.
  - `SOUNDKIT.IG_CHARACTER_INFO_TAB` — exactly what `PVEFrame_TabOnClick` plays (PVEFrame.lua:127).
  - `PanelTemplates_SelectTab(tab)` disables the button (SharedUIPanelTemplates.lua:527) — the dashboard's own active tab therefore needs no OnClick.

## Sound design (accepted overlaps — Blizzard side is untouchable)

| Transition | Ours | Blizzard's (unavoidable) |
|---|---|---|
| `/amt` or keybind open (incl. swap-in-place when PVEFrame open) | `IG_CHARACTER_INFO_OPEN` | `..._CLOSE` from PVEFrame OnHide when swapping |
| `/amt` close / Escape | `IG_CHARACTER_INFO_CLOSE` | — |
| PVEFrame tab → dashboard | `IG_CHARACTER_INFO_TAB` | `..._CLOSE` from PVEFrame OnHide |
| dashboard mirrored tab → PVEFrame | none (suppressed) | `..._OPEN` from PVEFrame OnShow |

---

### Task 1: Dashboard.lua whole-file replacement

**Files:**
- Modify: `Dashboard.lua` (whole-file replacement; currently 146 lines)

**Interfaces:**
- Consumes: `AMT.IsTabEligible()`, `AMT.GetPVEFrameTabNums()` (Util.lua); `L["TAB_NAME"]`, `L["DASHBOARD_TITLE"]`, `L["DASHBOARD_TITLE_NO_SEASON"]` (Locales\enUS.lua); `AMT.RegisterEvent` (Core.lua).
- Produces: `AMT.ToggleDashboard()` (Core.lua slash handler calls it — signature unchanged, zero-arg), `AMT.UpdateMainTabState()`, `AMT.Dashboard` (with `.Tabs`, `.numTabs`, `.openSoundKit`, `.suppressCloseSound`), `AMT.MainTab`.

Behavior deltas from current file, all intentional:
- FIX: `PVEFrame.Tabs[lastTab]` → `_G["PVEFrameTab" .. lastTab]` (nil-index bug, see constraints).
- FIX: timerunner guard — Blizzard hides all PVEFrame tabs for timerunners, so `GetPVEFrameTabNums()` returns 0 and `PVEFrameTab0` is nil; the AMT tab now hides itself when no Blizzard tab is visible.
- NEW: mirrored tab row on the dashboard, AMT tab rendered active via `PanelTemplates_SetTab`.
- NEW: PVEFrame-tab click swaps frames in place (position capture → `HideUIPanel(PVEFrame)` → `Show`), plays TAB sound.
- NEW: mirrored Blizzard tab click swaps back via `PVEFrame_ShowFrame`, our close sound suppressed.
- UNCHANGED: eligibility gating, lock tooltip, drag, Escape-close, title refresh, PLAYER_LOGIN/PLAYER_LEVEL_UP wiring.

- [ ] **Step 1: Replace file content**

```lua
local AMT = select(2, ...) ---@class AMT
---@class L
local L = AMT.L

-- Dashboard window styled as an extension of PVEFrame: it carries a mirrored
-- copy of PVEFrame's tab row (plus this addon's own tab, rendered active),
-- swaps in at PVEFrame's screen position when opened from the PVEFrame tab,
-- and returns to the matching PVEFrame panel when a mirrored tab is clicked.
-- Eligibility (pure check in Util.lua) gates the PVEFrame-side tab; the lock
-- reason is a tooltip on the disabled tab (motion scripts stay enabled).

-- Mirrors the private `panels` list in Blizzard_GroupFinder/Mainline/PVEFrame.lua;
-- index i corresponds to PVEFrameTab<i>.
local PVE_PANELS = { "GroupFinderFrame", "PVPUIFrame", "ChallengesFrame" }
local AMT_TAB_INDEX = #PVE_PANELS + 1

-- ==========================
-- === Show / Toggle ========
-- ==========================

---Anchor the dashboard to PVEFrame's current screen position, hide PVEFrame,
---show the dashboard. PVEFrame's own OnHide close sound plays regardless;
---unavoidable without taint.
local function SwapFromPVEFrame()
	local f = AMT.Dashboard
	local left, top = PVEFrame:GetLeft(), PVEFrame:GetTop()
	if left and top then
		f:ClearAllPoints()
		f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
	end

	HideUIPanel(PVEFrame)
	f:Show()
end

---Toggle the dashboard (slash command / future keybind path — standard open
---sound). Swaps in place of PVEFrame when it is open. No-ops in combat and
---on ineligible conditions.
function AMT.ToggleDashboard()
	if InCombatLockdown() or not AMT.IsTabEligible() then
		return
	end

	local f = AMT.Dashboard
	if f:IsShown() then
		f:Hide()
	elseif PVEFrame:IsShown() then
		SwapFromPVEFrame() -- default open sound: this path is not a tab click
	else
		f:Show()
	end
end

---PVEFrame-tab click path: same swap, but sounds like a tab click.
local function SwitchToDashboard()
	if InCombatLockdown() or not AMT.IsTabEligible() then
		return
	end

	AMT.Dashboard.openSoundKit = SOUNDKIT.IG_CHARACTER_INFO_TAB
	SwapFromPVEFrame()
end

-- ==========================
-- === Main Tab State =======
-- ==========================

---Apply enabled/disabled visuals and click behavior to the PVEFrame-side tab.
function AMT.UpdateMainTabState()
	local tab = AMT.MainTab
	if not tab then
		return
	end

	local eligible, reasonKey = AMT.IsTabEligible()
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
-- === Dashboard Tab Row ====
-- ==========================

---Mirror PVEFrame's tab row onto the dashboard: copy label and shown state of
---each Blizzard tab (IsShown, not IsVisible — PVEFrame is hidden during the
---swap), re-anchor the chain across hidden ones, and render this addon's tab
---as the selected one. Selected tabs are disabled by PanelTemplates, so the
---active tab needs no click handler.
local function UpdateDashboardTabs()
	local f = AMT.Dashboard
	local previous
	for i = 1, #PVE_PANELS do
		local source = _G["PVEFrameTab" .. i]
		local tab = f.Tabs[i]
		tab:SetText(source:GetText())
		PanelTemplates_TabResize(tab, 0)
		tab:SetShown(source:IsShown())
		if source:IsShown() then
			tab:ClearAllPoints()
			if previous then
				tab:SetPoint("LEFT", previous, "RIGHT", -16, 0)
			else
				tab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 19, -30)
			end
			previous = tab
		end
	end

	local amtTab = f.Tabs[AMT_TAB_INDEX]
	amtTab:ClearAllPoints()
	if previous then
		amtTab:SetPoint("LEFT", previous, "RIGHT", -16, 0)
	else
		amtTab:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 19, -30)
	end

	PanelTemplates_SetTab(f, AMT_TAB_INDEX)
end

---Click on a mirrored Blizzard tab: swap back to the matching PVEFrame panel.
---PVEFrame plays its own open sound via ShowUIPanel, so we play nothing and
---suppress our close sound to avoid stacking three sounds.
local function OnMirroredTabClick(self)
	local f = AMT.Dashboard
	f.suppressCloseSound = true
	f:Hide()
	PVEFrame_ShowFrame(PVE_PANELS[self:GetID()])
end

local function CreateDashboardTabs(f)
	f.Tabs = {}
	f.numTabs = AMT_TAB_INDEX

	for i = 1, #PVE_PANELS do
		local tab = CreateFrame("Button", "AdvancedMythicTrackerDashboardTab" .. i, f, "PanelTabButtonTemplate", i)
		tab:SetScript("OnClick", OnMirroredTabClick)
		f.Tabs[i] = tab
	end

	local amtTab = CreateFrame("Button", "AdvancedMythicTrackerDashboardTab" .. AMT_TAB_INDEX, f, "PanelTabButtonTemplate", AMT_TAB_INDEX)
	amtTab:SetText(L["TAB_NAME"])
	PanelTemplates_TabResize(amtTab, 0)
	f.Tabs[AMT_TAB_INDEX] = amtTab

	UpdateDashboardTabs()
end

-- ==========================
-- === Dashboard Creation ===
-- ==========================

local AMT_WINDOW_WIDTH = 960
local AMT_FALLBACK_HEIGHT = 428

---Season data is nil early in a session; Blizzard guards the same way in ChallengesFrameMixin:UpdateTitle.
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
		-- openSoundKit is a one-shot override set by SwitchToDashboard (tab
		-- transitions sound like tab clicks; everything else sounds like a window).
		PlaySound(self.openSoundKit or SOUNDKIT.IG_CHARACTER_INFO_OPEN)
		self.openSoundKit = nil
		self:SetTitle(GetDashboardTitle()) -- season data may have arrived since creation
		UpdateDashboardTabs()
	end)
	f:SetScript("OnHide", function(self)
		if self.suppressCloseSound then
			self.suppressCloseSound = nil
		else
			PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE)
		end
	end)

	-- Escape closes the dashboard
	table.insert(UISpecialFrames, "AdvancedMythicTracker")

	AMT.Dashboard = f

	CreateDashboardTabs(f)

	-- PVEFrame Dashboard Tab Button
	local tabNum = PVEFrame.numTabs + 1
	local tab = CreateFrame("Button", "AdvancedMythicTrackerTab", PVEFrame, "PanelTabButtonTemplate", tabNum)
	tab:SetText(L["TAB_NAME"])
	tab:SetMotionScriptsWhileDisabled(true) -- keep OnEnter alive while disabled for the lock tooltip
	PanelTemplates_DeselectTab(tab)
	AMT.MainTab = tab

	tab:SetScript("OnClick", function()
		SwitchToDashboard()
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
	-- OnShow hook would add a duplicate set on every PVEFrame open.
	PVEFrame:HookScript("OnShow", function()
		AMT.UpdateMainTabState()

		-- PVEFrame.Tabs does not exist (XML only sets parentKey tab1..3);
		-- resolve by global name like PanelTemplates itself does. For
		-- timerunners Blizzard hides every PVEFrame tab, so anchor only when
		-- at least one is visible and hide ours alongside theirs.
		local lastTab = AMT.GetPVEFrameTabNums()
		local anchorTab = lastTab > 0 and _G["PVEFrameTab" .. lastTab] or nil
		tab:SetShown(anchorTab ~= nil)
		if anchorTab then
			tab:SetPoint("LEFT", anchorTab, "RIGHT", 3, 0)
		end
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

### Task 2: Final verification (main session)

- [ ] `luac -p Dashboard.lua` — silence.
- [ ] Grep `PVEFrame.Tabs` in *.lua — zero matches (bug eradicated).
- [ ] Grep `AdvancedMythicTracker_ToggleDashboard` — still zero.
- [ ] Confirm `AMT.ToggleDashboard` signature unchanged (Core.lua untouched).
- [ ] Review diff against this plan.

## Design choices surfaced (Alex decides, defaults chosen)

1. **Sound overlaps** (see table above): PVEFrame's own OPEN/CLOSE sounds cannot be suppressed without taint. Tab-into-dashboard = TAB+CLOSE together; tab-back = OPEN only (our TAB suppressed there to avoid a triple). If the TAB+CLOSE mix bothers you in-game, the fallback is dropping our TAB sound and letting CLOSE stand alone — one-line change.
2. **`/amt` while PVEFrame is open swaps in place** (hides PVEFrame, dashboard at its position) — Alex-confirmed 2026-07-11. Sound stays the window-open kit: the tab-click sound is reserved for actual tab clicks per the spec.
3. **Escape (or close button) on the dashboard does NOT reopen PVEFrame** — it just closes, like closing any window.
4. **Dashboard's active tab is click-dead** (stock PanelTemplates behavior for selected tabs) — clicking "Mythic+ Tracker" on the dashboard does nothing, exactly like clicking PVEFrame's own active tab.
5. **Mirrored tab visibility uses `IsShown()`** of the Blizzard tabs (their own flag, valid while PVEFrame is hidden). Disabled-state on PVEFrame's Challenges tab (M+ inactive) is NOT mirrored — dashboard is unreachable in that state anyway (eligibility gate).
6. **Timerunner hardening:** Blizzard hides all PVEFrame tabs for timerunners; our PVEFrame-side tab now hides with them (was a nil-anchor crash before).

## In-game checklist (Alex)

1. Max-level char, active season: open Group Finder → AMT tab enabled at the right of the tab row (no Lua error on open — `PVEFrame.Tabs` fix).
2. Click AMT tab → PVEFrame closes, dashboard appears at the exact same spot; tab-click sound (plus PVEFrame's close sound underneath — accepted); dashboard shows Group Finder / PvP / Mythic+ / Mythic+ Tracker tabs with Mythic+ Tracker active (pressed-in, no click).
3. Click "Group Finder" on the dashboard → dashboard closes silently, PVEFrame opens on Group Finder panel (window-open sound only). Same for PvP and Mythic+ (Challenges panel loads on demand).
4. `/amt` (PVEFrame closed) → dashboard opens at last position with window-open sound; `/amt` again → closes with window-close sound; Escape also closes. `/amt` with PVEFrame OPEN → PVEFrame closes, dashboard appears in its place (window-open sound, not tab sound).
5. Drag dashboard elsewhere, close it, reopen via PVEFrame tab → snaps back to PVEFrame's position.
6. Sub-max char: AMT tab greyed/disabled with tooltip (unchanged behavior).
7. Paste any Lua error verbatim.

## Execution Status

- Task 1: done — Dashboard.lua replaced verbatim with the Step 1 code block (273 lines). `luac -p Dashboard.lua` silent (pass). Starting file was 144 lines, not 146 as the plan noted; immaterial to a whole-file replacement.
- Task 2: pending
