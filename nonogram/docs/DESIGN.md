# Nonogram v0.3 — first design pass

**Current design owner:** [shared game design contract](../../docs/GAME_DESIGN.md).
The study below records the v0.3/v0.4 decisions and measurements. v0.5 now
centers the complete measured clue + board composition and uses the shared
3px grid / 4px frame and mark tokens. The font pack was promoted and expanded
for all active games; its current metrics live in `shared/font-metrics.json`.
Use the shared contract for future changes rather than treating the historical
right-edge anchoring and v0.4 cache counts below as current constraints.

The surface helps a reader solve a nonogram by comparing the row/column clues
with a grid they can mark reliably with a finger. This pass is scoped to
Nonogram. Its existing levels, generated seeds, app ID and save format remain
the product contract.

## Design Bible applied

The user's direction is stronger strokes, rounded corners and better use of
the 480×800 screen. The Bible supplies the method and design principles:

- [Agent Start](https://github.com/BigCatMellow/Pilot_Projects/blob/main/ai-design-bible/AGENT-START.md): recover the actual task and runtime, establish hierarchy before decoration, inspect rendered states, separate host checks from judgment and device evidence.
- [Visual rules](https://github.com/BigCatMellow/Pilot_Projects/blob/main/ai-design-bible/rules/VISUAL.md): `VISUAL-001` task hierarchy; `TYPE-001` deliberate type roles; `SPACE-001` grouping through spacing; `SHAPE-001/002` a coherent radius family; `DENSITY-001` deliberate touch density.
- [Interaction rules](https://github.com/BigCatMellow/Pilot_Projects/blob/main/ai-design-bible/rules/INTERACTION.md): `INT-001` visible objects and hit areas agree; `INT-002` outcome labels; `INT-003` proportionate feedback. `CONTEXT-001` supports keeping the current board and progress recognizable after re-entry.

Chosen priority: legible clues and a generous touch board, then clear controls
and feedback, then ornament. The existing shared measured UI helper remains
the component owner. A small opt-in button style adds radius and stroke weight;
other apps retain the default rectangular treatment until individually reviewed.

## What the original layout spent space on

The 8×8 grid occupied 312×312 pixels: about 25% of the screen. Its clue rows
floated far from the grid, while a persistent rule line, row/column counts,
tap instructions and the hidden-picture explanation created competing text
bands. All four footer controls looked equally important. A 35px-wide help
target was considerably narrower than the play controls.

## New space allocation

| Region | Contract |
| --- | --- |
| Header | Small tile mark, 30px title, 48×48 Help target; 20px puzzle number and size below |
| Clues + board | Clues sit immediately above/left of the board; every grid ends at x=456 |
| Progress | One row at y=608: row and column matches, aligned with the 24px margins |
| Feedback | One line at y=660: input guidance, CHECK result, revealed name or save failure |
| Controls | y=708–776; 68px tall, 12px gaps; a 108px primary Check/Next action |

| Grid | Before: cell / side | After: cell / side | Board area gain |
| --- | --- | --- | --- |
| 5×5 | 58 / 290px | 68 / 340px | 37.5% |
| 7×7 | 44 / 308px | 48 / 336px | 19.0% |
| 8×8 | 39 / 312px | 44 / 352px | 27.3% |

The largest board now occupies about 32% of the full screen. Its remaining
space pays for clues, header and comfortable controls. Clue gutters reserve
room for three runs, including generated patterns. Board sizes stay stable
within a grid size rather than changing whenever a clue gets longer.

## Visual language and behavior

- Board frame: 3px stroke, 8px corners. Internal grid lines: 2px; each fifth
  boundary: 3px to aid counting.
- Filled cells: inset 5px with 3px corners. X marks: 3px strokes, proportionate
  to the cell size. The grid remains easy to distinguish from the marks.
- Buttons: 12px corners, 2px normal outline, 3px primary outline, 1px unavailable
  outline. No black button with white lettering: the community's
  [firmware evidence](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/3d7e6225efc9b18d2b4aeed324a32b2e352d1f0d/docs/firmware-notes.md)
  reports ignored text color on filled surfaces. Existing community apps use
  the native rect `radius` option; its exact rendering still needs this device check.
- Clues: right-aligned against their rows, bottom-aligned above their columns;
  24px on 5×5 and 20px on denser boards. A small tick means the current line's
  runs match its clues, not that every cell is globally confirmed correct.
- Feedback: one contextual line replaces the repeated hidden-picture message.
  Names remain hidden until CHECK succeeds.
- Solved primary action: Check becomes Next. The secondary header Next is
  hidden when solved, leaving one clear continuation. Reset remains explicit.
- The rounded button's rectangular bounding box remains the full touch target;
  there is no tiny corner exclusion. Both drawing and hit testing use `BUTTONS`.
- Static frames only; no motion, gradients, textures or periodic refresh.

## Proof and judgment

[Before/after](design/before-after.png) and [state sheet](design/states.png)
come from the real Lua `on_draw` commands, replayed using Pillow and DejaVu
Sans at 20/24/30px. They are **host previews, not firmware screenshots**.
Regenerate current states with:

```bash
python3 scripts/render_nonogram.py
```

The visual review inspected 5×5, 7×7, 8×8, a generated board, help, incomplete
CHECK and solved states. The board now owns the frame, row clues have an
unambiguous visual connection, and the control family is coherent without
wrapping every region in a card. White space above short clue lists is
intentional; the reserved clue area prevents crowded generated boards.

Automated proof covers every authored board and generated samples at distinct
font heights and enlarged variable glyph widths, help/solved/error messages,
large puzzle counters, cell-edge hit testing, the new solved Next action,
legacy saves, generated archives, per-board undo and correct-but-unsubmitted
boards. The shared helper checks that rounded styling preserves padded text
and coherent nested corner radii.

The user reports the previous game builds seem to work. v0.3 still requires
physical checks for native font metrics, radius support, stroke appearance,
finger accuracy, inactive-control clarity and e-ink ghosting. Host previews
cannot settle those questions.

## Typeface study and v0.4 implementation

The user selected the Poppins/Inter direction after reviewing the
[font comparison](design/font-comparison.png). v0.4 implements that choice as
packaged **1-bit PNG glyphs**. It does not need a TTF loader or a change to the
reader's system font. The [packaged-font preview](design/bitmap/native-vs-bitmap.png)
and [bitmap state sheet](design/bitmap/states.png) draw the actual shipped glyph
pixels through the real Lua renderer. Graphics and image-decoding behavior
still need physical confirmation.

| Role | Typeface | Pixel size / line height |
| --- | --- | --- |
| Title and help heading | Poppins SemiBold | 30 / 30 |
| Controls | Poppins Medium | 24 / 26 |
| Metadata and status | Inter Medium | 20 / 25 |
| Help paragraphs | Inter Medium | 24 / 30 |
| Dense clues | Inter Medium, tabular numbers | 20 / 20 |
| 5×5 clues | Inter Medium, tabular numbers | 24 / 24 |

Each glyph has an integer advance and tight ink bounds. Line heights include
ascenders and descenders; glyphs are not aligned by the top of each individual
letter. UI measurement, wrapping, button fitting and drawing all use the same
metrics. Larger 5×5 clues have an explicit Inter role instead of borrowing the
control font.

The runtime evidence reports no verified per-app TTF loader, but supports
small PNG decoding and drawing whole runtime pictures. It rejects cropping
those pictures, so this implementation uses separate glyph images rather than
an atlas that needs source rectangles. No image is scaled while drawing text.
The TTF sources stay outside the app folder; only generated PNG data, metrics,
renderer code and license notices go into the installer.

The pack contains 254 glyph records sharing 227 unique images, with 36,655
pixels total. The raw RGB pixel payload would be 109,965 bytes; native handle,
allocator and Lua overhead are additional and are not measured on this device.
PNG bytes total 22,156; the generated Lua data is 53,640 bytes. The cache is
created on the first frame, reused across taps and level visits, and released
on leave/relaunch. A failed mid-frame draw keeps queued images alive until
leave rather than freeing objects the canvas may still reference.

Decode failure, invalid image dimensions, or an unsupported drawing backend
switch the app to system fonts. A drawing/decoding failure with an image
backend displays “System fonts active”; puzzle state and saves remain intact.
Unsupported text falls back as a whole label using native measurements,
avoiding a mixture of incompatible glyph metrics within that label.

Independent tests compare the PNGs against source-font masks, validate glyph
bounds and tabular digits, exercise the cache lifecycle and failure paths, and
measure every authored board plus generated samples, help, solved and long
counter states using the actual bitmap metrics. The busiest tested frame uses
323 drawing commands, including 314 glyph images. These checks establish
bounds and command counts, not first-frame latency or native heap usage.

Source font files and licenses:
[Inter](https://github.com/google/fonts/tree/main/ofl/inter),
[Poppins](https://github.com/google/fonts/tree/main/ofl/poppins).
The package includes both complete SIL Open Font License notices in
`font_license.lua`. Unmodified source files, export hashes and reproduction
instructions are in `assets/fonts/game-ui/` and `font-metrics.json`.

Rebuild or inspect:

```bash
python3 scripts/make_game_fonts.py --check
python3 nonogram/tests/validate_fonts.py
(cd nonogram && lua tests/test_fonts.lua)
python3 scripts/render_nonogram.py --bitmap --out nonogram/docs/design/bitmap
```

The reference renderer uses Python 3.12, Pillow 10.2.0 and FreeType 2.13.2.
CI pins the matching Python/Pillow wheel; that wheel was checked locally
against the exported glyph masks. Physical acceptance still needs the real
reader's PNG appearance, first-frame generation time, repeated taps,
sleep/resume and native memory behavior.
