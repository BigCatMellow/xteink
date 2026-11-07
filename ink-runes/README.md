# Ink Runes — original cryptic word puzzles for XTEINK X4 Pro

A standalone, offline, monochrome puzzle inspired by the **rule-discovery** idea of LOK by Blaž Urban Gracar, but not a port. The three rune words, powers, boards, implementation and graphics are original. No original LOK levels, vocabulary, writing or assets are copied.

**Version 0.1:** Twenty frozen, solver-checked puzzles. Needs physical testing on the X4 Pro running XTOS Licorice.

## Gameplay

Tap three **orthogonally adjacent** letters in order. Every successful invented word covers its three letters and applies its power:

- **MIR — TRACE:** Cover only the selected three letters.
- **VAS — RIPPLE:** Also cover all orthogonally neighboring tiles of the **last** letter.
- **DOK — COLUMN:** Also cover the entire column of the **last** letter.

The goal is to cover every active letter tile. Covered letters cannot form another word; sometimes a valid word is the *wrong* choice because it destroys another needed word. The first two levels teach tracing. Levels 3–20 offer traps and later mix all three abilities.

Puzzles 1–6 are 4×4; 7–13 are 5×5; 14–20 are 6×6. The **?** notebook reveals powers only after you have cast them. Tapping the final selected tile cancels a partial trace; an invalid word leaves the board unchanged.

## Controls

- Tap letter cells to trace, one static redraw per tap.
- **UNDO** cancels the current partial word or restores the board before the last valid rune.
- **RESET** starts the current level again.
- **PREV/NEXT** move between unlocked levels; NEXT unlocks on completion.
- Physical page buttons navigate levels where permitted, not individual letters.

All completed tiles are drawn black, with no animation, sound, timer, fades, or network. Current progress, unlocked levels, discovered runes, and undo history are saved locally in the app's private storage.

## How to install

1. Open the [Ink Runes build workflow](https://github.com/BigCatMellow/xteink/actions/workflows/ink-runes.yml).
2. Download the latest successful **ink-runes-xtapp** artifact.
3. Unzip it and copy the enclosed `ink-runes.xtapp` to the reader's microSD root.
4. Install via **All Files**, then launch via **Ink App**.

If Ink App is hidden, open Settings → About and tap Model ten times quickly. Do not uninstall an existing app if you wish to preserve its private save data.

## Verification

An independent Python exact-state solver checks all 20 puzzles. It ensures they are solvable and that the final 18 have at least one tempting first word leading to a dead end. A Lua host simulator replays complete solutions and verifies selection, undo, persistence, input, and bounded static rendering. Those tests cannot replace real-device verification.

Files: `app/index.lua`, `app/manifest.json`, `tests/test_game.lua`, `tests/check_levels.py`, and `docs/DEVICE_TESTING.md`. The build is in `.github/workflows/ink-runes.yml`.

For the original game, see [LOK by Letibus](https://www.letibus.com/lok) and [LOK Digital](https://store.steampowered.com/app/2207440/).
