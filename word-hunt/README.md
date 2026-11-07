# Word Hunt — word search and Find the Fox for XTEINK X4 Pro

A completely static, offline, black-and-white word-search game. It has **two independent modes**. The crowded F/O/X mode is based on the *kind* of puzzle shown in the supplied image, not copied from that image; every 13×13 grid is an original composition.

## Two modes

**WORDS** — Eight themed **8×8** classic word searches, with four listed words per board. Words may be horizontal, vertical, diagonal, backward, or overlap other words. Themes include woodland, cosmos, reef, grove, kitchen, kingdom, garden and sky.

**FOX** — Eight denser **13×13** grids made entirely from the letters F, O and X. Each contains **exactly one straight FOX**, with the eight levels covering all eight compass directions. The visual challenge is spotting the one three-letter target among the repeating letters.

**Controls:** Tap the *first* letter and then the *last* letter, rather than dragging across the e-ink display. Either endpoint order works. A correct find is outlined on the grid and checked off beneath it; an incorrect pair does not remove any letters. Tap a selected start again to cancel.

- Toggle WORDS or FOX at the top; the modes save progress separately.
- HINT circles the start of one missing word; two hints per puzzle.
- RESET clears only the current puzzle, not your other finds or unlocked stages.
- PREV/NEXT navigate previously unlocked puzzles.
- Physical page buttons navigate levels where permitted; they never select letters.
- Completed words are circled, not shaded over, to preserve the ability to read overlapping letters.

The renderer performs **one static update per accepted tap**. There are no swipes, timers, moving letters, network connections, grayscale fades or animated search effects.

## Puzzle validation

An independent Python verifier scans **every board in all eight directions** and confirms exactly one occurrence of each listed word, that the stated selection endpoints are correct, and that the eight FOX boards collectively cover every compass direction. Lua host tests complete all 16 games, exercise hints, mode switching, saves, revisits and scaled-font layout.

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
