# Line Lift — static crossing puzzles for XTEINK X4 Pro

**Original minimalist deduction game for XTOS Licorice**, designed for the reader's **480 × 800 black-and-white e-ink screen**. Inspired by the *type of reasoning* in Maciej Targoni's [Hook](https://www.rainbowtrain.eu/hook), but this is **not a port**. All 12 layouts, line groupings, renderer, app code and name are independently authored.

## No animation — by design

There is **no sliding wire, progress tween, transition, delay, flicker, moving ball or timer**. The display only ever shows a complete static state:

- Tap a clear rod's circular pull point → the line **disappears instantly** and the e-ink display redraws once.
- Tap a blocked rod → **the starting state of the level returns instantly**, with "SNAG!" shown.
- Tap NEXT → the next puzzle appears instantly.

Only black strokes on a white background. No gray tones, opacity, bitmaps, or hardware acceleration needed.

## Rules

Each thin black line has a **lettered circle** at its pull end. A line interrupted with a small gap **passes below** a continuous crossing line. You must remove the **upper** line first before you can pull the line beneath it.

1. Study each crossing and find a rod that **never passes underneath any other active rod**.
2. Tap its circular trigger to remove it.
3. Continue until all rods are gone.
4. If a pulled line has even **one** active rod crossing over it, it catches and the **whole level resets**. You can immediately try again. The game tracks snags, with no lives or timer.
5. Levels **11–12** add paired mechanisms: **double-ringed circles with the same letter** trigger two lines at once; **both** must be unblocked. Tap either circle to release the pair.

No guessing is needed: all crossing relationships are visible. The code uses the same geometric crossings to determine legality and to draw the interruptions.

### Controls

- **Tap a lettered circle:** attempt to remove its rod or pair.
- **?**: show the static rules screen; **BACK TO PUZZLE** to close.
- **RESTART:** reset current puzzle (no animation).
- **PREV:** revisit the preceding puzzle; cleared levels remain unlocked.
- **NEXT:** appears only after all current rods are removed.
- Physical **next page** advances only after clearing a level; physical **previous page** revisits the previous puzzle. Neither button can accidentally remove a rod.

Progress, unlocked level, which groups are cleared, and the snag count are stored in the app's private save file.

## Install

1. Open the [Line Lift GitHub Actions build](https://github.com/BigCatMellow/xteink/actions/workflows/line-lift.yml).
2. From the latest **successful** run, download the **line-lift-xtapp** workflow artifact and unzip `line-lift.xtapp`.
3. Copy the `.xtapp` to the root of the reader's microSD card using USB mode.
4. Open **All Files**, tap the package, and approve installation.
5. Open **Ink App → Line Lift**. If the menu is hidden, go to **Settings → About** and quickly tap **Model** ten times.

The app does not replace firmware, has no network permissions, and works offline. The `.xtapp` packaging process follows the same tested community tool as the other projects in this repository.

## Structure

- `app/index.lua`: 12 original levels, crossing model, draw code, touch input, save/restore.
- `app/manifest.json`: Licorice package declaration.
- `tests/test_game.lua`: validates authored geometry, solvability, safe/blocked choices, paired groups, persistence, touch zones, and monochrome static rendering.
- `docs/DEVICE_TESTING.md`: acceptance checks for your physical X4 Pro.
- `.github/workflows/line-lift.yml`: test + compatibility check + package CI.

## Verification status

**Automated validation is not hardware validation.** The Lua logic and `.xtapp` package may pass GitHub CI, but neither display contrast nor the exact Licorice touch handling is proven until the game is launched on the physical X4 Pro. If the mechanics are too easy, revise level structure based on playtesting rather than adding animation.

The reference game's developer describes Hook as a minimalist puzzle about removing linked mechanisms. This version deliberately uses a simpler **over/under layering** rule to make it readable as a static line diagram on e-ink. It does not use any of Hook's proprietary levels or art.
