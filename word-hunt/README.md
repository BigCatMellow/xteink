# Word Hunt — word search and Find the Fox for XTEINK X4 Pro

Presentation follows the [shared game design contract](../docs/GAME_DESIGN.md): Poppins/Inter, rounded controls and stronger monochrome lines. That document owns design changes, reasons and per-game exceptions.

A completely static, offline, black-and-white word-search game. It has **two independent modes**. The crowded F/O/X mode is based on the *kind* of puzzle shown in the supplied image, not copied from that image; every 13×13 grid is an original composition.

## Two modes

**WORDS** — Eight themed **8×8** classic word searches, with four listed words per board. Words may be horizontal, vertical, diagonal, backward, or overlap other words. Themes include woodland, cosmos, reef, grove, kitchen, kingdom, garden and sky.

**FOX** — Eight denser **13×13** grids made entirely from the letters F, O and X. Each contains **exactly one straight FOX**, with the eight levels covering all eight compass directions. The visual challenge is spotting the one three-letter target among the repeating letters.

**Endless continuation (v0.2.0):** after puzzle 8, NEXT generates more boards in either mode, entirely offline. WORDS combines four themed words with fresh placements and filler; FOX keeps exactly one target in a fresh grid. Every listed word is checked in all eight directions. Generated boards can repeat eventually; this is a procedural supply, not a promise of infinitely many distinct finite grids. Puzzle numbers support up to 999,999,999 per mode.

The original boards, app ID, hints and saved progress are preserved on upgrade. A puzzle number determines its grid, so revisiting it restores the same search and your finds. Generated records use 64 save files per mode to stay below Licorice's 512-file quota. History still uses storage and remains subject to the device's byte quota; a failed save keeps the current puzzle open and reports the failure.

**Controls:** Tap the *first* letter and then the *last* letter, rather than dragging across the e-ink display. Either endpoint order works. A correct find is outlined on the grid and checked off beneath it; an incorrect pair does not remove any letters. Tap a selected start again to cancel.

- Toggle WORDS or FOX at the top; the modes save progress separately.
- HINT circles the start of one missing word; two hints per puzzle.
- RESET clears only the current puzzle, not your other finds or unlocked stages.
- PREV/NEXT navigate previously unlocked puzzles.
- Physical page buttons navigate levels where permitted; they never select letters.
- Completed words are circled, not shaded over, to preserve the ability to read overlapping letters.

The renderer performs **one static update per accepted tap**. There are no swipes, timers, moving letters, network connections, grayscale fades or animated search effects.

## Puzzle validation

An independent Python verifier scans **every authored board and a generated sample in all eight directions**, including forced generator fallbacks, and confirms exactly one occurrence of each listed word. Lua host tests complete the authored games and generated continuations, exercise v1 save migration, hints, mode switching, saves, revisits, large puzzle numbers and scaled-font layout.

## Install

1. Open [Word Hunt's Actions workflow](https://github.com/BigCatMellow/xteink/actions/workflows/word-hunt.yml) and choose its latest **successful** build.
2. Download the `word-hunt-xtapp` artifact and extract `word-hunt.xtapp`.
3. Copy it into **`SD:/Apps/`** on the X4 Pro microSD card.
4. Install from Licorice **All Files**, and launch through **Ink App → Word Hunt**.

Do not delete the firmware's `XTApps/` folder; that location contains installed-app data. Install a newer version over the previous version to preserve saves.

## Project

- `app/index.lua`: app, touch input, display, saving and two search modes.
- `app/puzzles.lua`: 16 frozen original search boards and authored paths.
- `app/ui.lua`: synchronized copy of the repository's measured UI helper.
- `app/icon.png` and `assets/icons/word-hunt.svg`: native launcher icon.
- `tests/validate_levels.py`: independent 8-direction uniqueness checker.
- `tests/test_game.lua`: simulated input, persistence, and layout testing.
- `docs/DEVICE_TESTING.md`: on-hardware acceptance checklist.

**Hardware status:** Build and simulation checks do not establish touch accuracy or letter legibility on a physical X4 Pro. These still require device testing.
