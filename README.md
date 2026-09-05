# Advanced Mythic Tracker

A Mythic+ dungeon timer for retail World of Warcraft.

Replaces Blizzard's scenario tracker with a timer, enemy-forces bar, boss list and death counter,
records your best times per dungeon and key level, and compares each run against them as you play.

**Requires retail World of Warcraft 12.1 (Midnight).** No Classic support is planned.

---

## What it does

**Timer.** Counts up or down, with all three upgrade thresholds shown at once and marked on the bar.
The bar recolours each time a threshold passes. Challenger's Peril is accounted for, so the `+2` and
`+3` times are correct whether or not the affix is up. The final time comes from the game's own
completion data, to a tenth of a second.

**Enemy forces.** Count, percentage, or both, with a completion colour and an optional
count-remaining mode.

**Objectives.** Boss rows with completion times, dimming as they die.

**Splits.** Every boss and the forces completion are compared against your best run for that dungeon
and level, falling back to one level lower when you have no record at the current one. The dungeon's
overall best can show as a target before the key starts and a result after it ends, with nothing in
between.

**Deaths.** A count with the accumulated time penalty, and a tooltip listing who died and when, in
class colours. Party identity is captured out of combat at the start of the key, which keeps it
working under the 12.0 secret-value restrictions. Where a name is unavailable you still get the
count.

**Records.** Personal bests per season, dungeon and key level, plus run history ingested from the
game's own data and abandoned runs recorded manually, since the API does not report them.

**Three styles.** Minimal, Panel and Aeon. Each lays the timer out differently. Selecting one resets
the timer's appearance to that style's defaults, and can be undone until you switch again.

**Profiles.** Per character, with a fallback for characters that have never chosen one, and
import/export as a shareable string.

**Quality of life.** Auto-slots your keystone at the pedestal, and auto-confirms single-option
dungeon dialogue inside a key. Both optional; hold Ctrl to bypass the second.

## What it does not do

- **No current-pull counter.** The APIs it needs became restricted in 12.0. Every comparable addon
  dropped the feature on Midnight.
- **No routing, no interrupt or dispel tracking, no party comms.** Other addons do these well.

---

## Installing

Through the CurseForge app, or by downloading a release and extracting
`AdvancedMythicTracker` into `World of Warcraft\_retail_\Interface\AddOns\`.

The folder must be named exactly `AdvancedMythicTracker`.

## Using it

Configuration opens from the minimap button, from `Escape → Options → AddOns → Advanced Mythic
Tracker`, or with `/amt`.

Turn on **Preview** in the options window's title bar to see the timer populated with sample data
while you set it up. **Animate preview** advances that data, so you can check thresholds
recolouring, split colours changing and forces completing.

| Command | |
|---|---|
| `/amt` | Open or close the options window |
| `/amt demo` | Toggle a static preview |
| `/amt demo live` | Toggle an animated preview |
| `/amt style minimal\|panel\|aeon` | Switch style |
| `/amt undo` | Undo the last style change |
| `/amt version` | Print the installed version |

---

## Building

`Libs/` is not committed. It is fetched at release time by
[BigWigsMods/packager](https://github.com/BigWigsMods/packager) from the `externals` block in
`.pkgmeta`, so a fresh clone will not load until you place local copies of the seven libraries
listed there.

Pushing any tag triggers `.github/workflows/release.yml`, which packages and publishes.

```bash
bash Scripts/check-syntax.sh      # parse every addon Lua file
bash Scripts/extract-locale.sh    # emit the translatable strings as a locale template
```

Translations are welcome: run the second script, paste its output into a file named for your locale
under `Locales/`, and fill in the right-hand sides. Untranslated strings fall back to English, so a
partial translation is useful.
