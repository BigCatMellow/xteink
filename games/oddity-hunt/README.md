# Oddity Hunt — original illustrated seek-and-find for XTEINK X4 Pro

Updates are applied directly from the computer while the SD card is mounted;
see the [family release procedure](../../docs/GAME_UPDATES.md). All active games
are also available inside Games Hub, so new games do not require separate
installation when using the updated hub. Never uninstall to update.


Presentation follows the [shared game design contract](../../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

A **static black-and-white I Spy–style game** made for the 480 × 800 XTEINK X4 Pro running XTOS Licorice. The scenes and 20 miniature line-art object types are original; no I Spy photographs, branded books, or proprietary image assets are included.

**v0.1:** Twelve illustrated shelves, each containing **42 drawn objects** and **five objects to find**. There are 504 object placements across the game and 60 individual searches. Objects are placed with deliberately varied positions rather than being labeled on a grid.

## Playing

Read the five-object checklist below the illustration. Find a matching object in the shelf and **tap its drawing**, not its checklist name. Each requested type appears **exactly once** in that scene; other objects are recognizable distractions but are never duplicate copies of the current requested type.

- Correct tap: a ring appears around the object and a check mark appears next to the target.
- Incorrect object: counts as a miss but does not interrupt the search.
- **HINT:** double-rings a currently missing object. Two hints per scene; a hint is reused until that highlighted target is found.
- **RETRY:** starts this scene from scratch; other scenes and unlocks remain.
- **PREV/NEXT:** navigate previously unlocked scenes.
- Physical page buttons navigate scenes, but never accidentally mark an object.

**No animation:** every tap produces at most one static redraw. No motion, frame loop, countdown, sounds, grayscale, or internet. Five objects can be collected in any order.

## Visual design

Each object is individually drawn using black outlines: key, fish, leaf, boat, star, moon, cup, crown, bell, house, flower, anchor, book, kite, heart, bird, clock, umbrella, apple and lantern.

A crowded shelf is more interesting than a bare number puzzle, but at 480×800 there is a limit to the detail. These are compact **illustrated object shelves**, not photographs or pixel-perfect reproductions of I Spy artwork. The icons are large enough for fingertip tapping, visually separated by at least 48 pixels, and scaled for the monochrome display. Twelve authored sets choose different objects and locations; positions are deterministic on every relaunch.

## How to install

1. Open the [Oddity Hunt GitHub Actions build](https://github.com/BigCatMellow/xteink/actions/workflows/oddity-hunt.yml).
2. Download the **oddity-hunt-xtapp** artifact from the latest *successful* run.
3. Extract `oddity-hunt.xtapp` and copy it to the reader's **SD:/Apps/** folder.
4. Install through **All Files**, then open **Ink App → Oddity Hunt**.

Keep installed app data inside the firmware-managed **XTApps/** folder; do not uninstall the app just to update it. If Ink App is hidden, use Settings → About, then quickly tap Model ten times. No flashing or firmware replacement is required. For existing installations, install over the prior version to preserve app-private progress.

## QA, persistence and limitations

The project uses the repository's canonical `game_ui.lua` helper and `tests/game_canvas.lua` for text collision and scaled font checks. Tests verify every scene, all 60 targets, tap-zone separation, target uniqueness, hint limit, wrong-object handling, single-refresh input, safe save/restore and multi-scene progress.

On a revisit, collected items, remaining hints and mistakes remain **exactly as left**. Only RETRY clears the current scene.

**Physical compatibility is unverified** until touch precision, contrast, sleep/resume and font placement are checked on an actual X4 Pro. See [device tests](docs/DEVICE_TESTING.md).

## Files

- `app/index.lua`: gameplay, persistence, layout and touch interaction.
- `app/art.lua`: 20 original no-animation line-art illustrations.
- `app/scenes.lua`: 12 authored scenes and deterministic object positions.
- `app/ui.lua`: generated copy of `shared/game_ui.lua`.
- `app/icon.png` and `assets/icons/oddity-hunt.svg`: distinct native 96×96 launcher icon and editable vector source.
- `tests/test_game.lua`: state, input, save and measured layout checks.
- `tests/validate_levels.py`: independent layout, decoy and hit-target verifier.
- `.github/workflows/oddity-hunt.yml`: package build.

The inspiration is the general **seek-and-find** game genre. Oddity Hunt is an independent project rather than an adaptation of any specific I Spy book or image.
