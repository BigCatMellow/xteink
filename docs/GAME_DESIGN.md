# Game design contract and change record

This is the design owner for the **11 active games** in
`scripts/sync_game_ui.py`. Use it with [game quality checks](GAME_QUALITY.md).
The user's approved direction is crisp monochrome graphics, rounder controls,
stronger lines, welcoming typography and a generous, clearly centered play area.
The user physically confirmed that Nonogram v0.4's Poppins/Inter treatment looks
better. The current family rollout still needs its own physical review.

## Why this design

The [Design Bible's visual rules](https://github.com/BigCatMellow/Pilot_Projects/blob/main/ai-design-bible/rules/VISUAL.md)
provide the rationale: task hierarchy (`VISUAL-001`), deliberate typography
(`TYPE-001`), meaningful spacing (`SPACE-001`), coherent corners
(`SHAPE-001/002`) and deliberate density (`DENSITY-001`). Its
[interaction rules](https://github.com/BigCatMellow/Pilot_Projects/blob/main/ai-design-bible/rules/INTERACTION.md)
require visible objects and touch targets to agree (`INT-001`) and concrete
action labels (`INT-002`). These are applied to a fixed 480×800 touch/e-ink
surface, rather than copying web component sizes or adding decorative cards.

Priority order: readable puzzle and clues; reliable touch; understandable
state/continuation; coherent finish. No animation, grayscale-only meaning,
textures or large black panels with reversed text. The latter also conflict
with the observed firmware's text-color limitations.

## Single owners in code

| Concern | Owner | Reason |
| --- | --- | --- |
| Shape/stroke tokens | `shared/game_style.lua` | Prevent different games inventing unrelated corner/stroke values |
| Canvas presentation and scoped font context | `shared/game_theme.lua` | Style existing geometry while preserving coordinates and input behavior |
| Measurement, paragraphs and padded buttons | `shared/game_ui.lua` | Drawing and layout use the same glyph metrics |
| Bitmap decoder/cache/fallback | `shared/typefaces.lua` | One lifecycle implementation for all games |
| Original licensed fonts | `assets/fonts/game-ui/` | Preserve provenance and licenses; no TTF loading on device |
| Glyph export | `scripts/make_game_fonts.py` | Reproducible PNGs and integer advances |
| Generated font data/notices/metrics | `shared/font_data.lua`, `font_license.lua`, `font-metrics.json` | One generated source copied into every installer |
| App copies | `scripts/sync_game_ui.py`, `scripts/sync_game_theme.py` | XTApps cannot import outside their own package |

Do not hand-edit app copies. `make_nonogram_fonts.py` is a compatibility
entrypoint for the shared exporter, not a second font-system owner.

## Visual and behavior contract

### Type roles

All bitmap roles are Inter (SIL OFL) since the 2026-11-18 mockup redesign; see
the change record below. `shared/font-metrics.json` is authoritative.

| Role | Face | Use |
| --- | --- | --- |
| `title` | Inter Bold 42px, title letters only | Sudoku, Minesweeper and Nonogram screen titles |
| `large` / `strong` | Inter Bold 30px | Help headings, Minesweeper numbers, emphasized numbers |
| `body` (also `medium` / control) | Inter SemiBold 24px | Button labels, rules, counters, status lines |
| `small` | Inter SemiBold 20px | Metadata and secondary status |
| `clue` / `clue_small` / `clue_large` | Inter SemiBold 24/20/26px, tabular digits | Numeric clues; Nonogram picks the largest that keeps 34px cells |
| `digit` / `digit_light` | Inter SemiBold / Regular 30px digits | Sudoku givens / entered values and keypad digits |

Line heights are **generated ink metrics**, not guessed from pixel size. The
current pack uses 22/26px for small/body text, 31px for the control font and
32px for headings. Numeric clue line boxes remain 20/24px. The authoritative
metrics are the generated JSON. A control falls back to the compact Inter
role when Poppins cannot fit its width or padded height; important control
labels must never become an ellipsis. Gameplay words, codes and numeric labels
keep their meaning and case; visual title casing does not change game data.

The glyph repertoire covers Latin letters, digits and ordinary UI punctuation.
Unsupported strings use native text as a whole label with native measurements.
Do not mix incompatible native/bitmap advances inside one label. Decode or
drawing failures use a native-font frame. This fallback does not reset a game.

### Corners and strokes

The code tokens own exact values. Current roles are:

- Controls: 9px radius, 3px outline for every control, plus a 1px lower edge
  (pressed-paper depth from the mockups). Check/Next are no longer heavier.
- Large square play-area frames: 6px radius where rounded; grids use 3px frames.
- Connected grid interiors: straight shared edges. `UI.grid` uses 1px cell
  edges and a 4px frame; semantic regions/box boundaries stay visibly stronger.
  Nonogram retains its approved 3px grid and 4px frame.
- Filled marks: 2px corner radius. Nonogram's X marks use 2px strokes.
- Selection guides: the selected row and column are shaded grey only, never
  outlined (user feedback after the device photos: the bars were confusing).
  The grey is a fine 25% staggered one-bit screen (`UI.shade`, tiles baked by
  `make_game_fonts.py`), decoded on first use and independent of the glyph set,
  so it still draws when the fonts fall back. The selected cell keeps its 3px
  rounded outline.
- Inactive Nonogram controls: 2px outline. Selected controls may use an inset
  outline; an inner corner follows the outer radius minus the inset.

The common canvas adapter increases an existing outline by one pixel, preserving
its hierarchy and coordinates. Grids explicitly start at the base needed for
the shared 3px result. Filled shapes retain their existing semantics. Tiny square
grid cells are not independently rounded: doing so would break continuous edges.
Parallel bridges and the gaps in crossing rods must remain visibly distinct.

Round shapes keep their full rectangular touch target; there is no tiny corner
exclusion. The adapter must not move or resize a control without a matching
input change. Keep essential rules available, and reserve space for status and
controls before enlarging a board.

### Screen-space efficiency: gameplay first (2026-11-17)

**Design the whole 480×800 surface, not a small app panel surrounded by phone-style
chrome.** The user's XTEINK reference apps devote nearly all useful space to
the puzzle and its interactions. Our visual standard is **zero unexplained
waste**, not 100% ink coverage: white space is justified when it separates
information, supports touch accuracy, or preserves legibility. Do not fill
unused pixels with decorative boxes, redundant labels, or oversized headers.

Required design decisions for **new games and substantial layout revisions**:

1. **Allocate pixels before drawing.** Sketch the actual screen regions
   (game/level/help, playable board **including clues**, feedback, action
   controls, required margins). Identify the largest feasible continuous
   interactive region *after* reserving readable status and reliable controls.
   Maximize playable width first on grids; size cells from available geometry
   instead of copying fixed offsets from another game.
2. **Make the game the visual priority.** Use a compact title/level/status
   area; merge metadata where possible. Remove persistent rule instructions
   and repeated legends after their teaching purpose is served. Put full
   rules in Help, with brief contextual cues only when needed. Keep the
   board, words, scenes, choices, clues, and notes visibly larger than chrome.
3. **Put controls where they serve the play surface.** Position high-frequency
   controls close to the puzzle or in the immediately adjacent available
   band. A single concise status/feedback line should replace stacked
   passive captions where possible. Keep intentional tap targets large,
   measured, distinct and fully inside the viewport.
4. **Account for aspect ratio, not just raw occupancy.** Square games must
   stay square, including their clue gutters. Do **not** stretch tiles,
   shrink readability, or fake visual density. When the board already uses
   almost all 480px of width, assign the remaining height to genuinely
   useful actions, selected-item details, notes, relevant clue lists, or
   progress; if none improves play, justified clear space is preferable to
   ornament. Scroll-free content should remain understandable in one view.
5. **Respond to real content and screen states.** A 5×5 and 8×8 puzzle,
   empty and populated number sheets, menus, solved boards, selected objects,
   errors, and Help may need different bounded geometry. Recompute drawing
   **and hitboxes from the same layout**. Preserve keyboard/page-button
   behavior and game progress; never turn a density improvement into
   overlapping labels or smaller targets.
6. **Treat every large blank band as a design decision.** A contiguous
   approximately **48px or larger** unexplained vertical gap between
   functional areas is a review trigger, **not** an automatic failure
   threshold. Either reclaim it for gameplay/controls or document why it
   improves comprehension or touch safety. Smaller gaps also deserve
   review when they accumulate across multiple fixed rows.

The accepted **Sudoku** improvement is a useful concrete precedent:
414×414 at (33,164) became 468×468 at (6,108), an approximately 28% increase
in play area by removing redundant chrome—not by changing puzzle rules.
It is **not** a universal board-size target: Nonogram must center the full
clue-plus-grid composition; number sheets use responsive row height; narrative
and object-search games need larger readable content rather than forced square
grids. Honor the per-game exceptions below.

**Visual acceptance evidence:** use shipped bitmap fonts to inspect at least
first/empty, typical in-progress, dense or advanced, solved/error, and Help
screens at the actual 480×800 size. Record the board/clue bounding box, action
target bounds, the largest unused bands and any intentional exceptions in
the design review. Compare before/after captures for an existing game. The
review is not complete merely because elements fit without collision.
Hardware legibility, e-ink refresh and touch accuracy still require device
checks.

### Nonogram centering

Center the **complete clue + board composition**, not the board alone while
clues overflow the left edge. The horizontal extent includes the widest row
clue plus its 16px separation from the board. The vertical extent includes the
tallest column-clue stack. Center this object at x=240 and within y=128–584.
The grid consequently sits to the right of the composition's center by half
the clue gutter; this preserves the generous 68/48/44px cells. Both drawing
and taps call the same geometry function. A regression checks both centers
within half a pixel using the active measured fonts.

## Per-game decisions and exceptions

| Game | Decision / why |
| --- | --- |
| Nonogram | Boxed column-clue header and row-clue column sharing the board's 2px rules and 3px frame, centered together in y=76-592 over 472px (cells up to 84px); shaded row/column guides; satisfied clue cells turn grey; header has only New/Next and ?; a Fill/X two-part switch above the action row (active half pressed in) and Hint on the help screen; preserve correct-but-unsubmitted boards and the solved Next action |
| Line Lift | Strong rounded frame and rods; keep interrupted-line gaps and paired rings, which convey puzzle rules. Remove decorative double control outlines and shorten metadata to `Puzzle` so its number stays visible |
| Summit Putt | 424px terrain composition, rounded cards, larger Undo/Restart targets below the hand; retain terrain caps, ramps and flag geometry |
| Link Grid | Full-width 448px board; fine cell grid and solid 5px network lines preserve the network/grid distinction; fixed anchors remain marked |
| Ink Runes | Preserve letter order, selected-cell connections and inked-cell meaning; existing board centering remains |
| Lantern Logic | Strong grid and wall boundaries; preserve clue checks, conflict brackets and light dots without relying on gray shading |
| Ray Vault | Strong grid, rim ports and atom/X markers; preserve port coordinates and paired-ray labels |
| Island Links | Expand the network to a 416px composition; strong island numbers and solid bridge strokes retain double-bridge separation |
| Oddity Hunt | Strong shelf frame and line art; retain object silhouettes and 48px touch neighborhoods, because recognition is the game |
| Word Hunt | Rounded outer grid/list controls; retain letter spacing and readable found/hint rings on the dense 13×13 FOX grid |
| Word Bridge | Rounded word cards and controls; preserve NOW/GOAL word case, dots, route state and word selection targets |
| Rectangle Rooms | Straight connected grid with stronger room/selection outlines; rectangle extents and area clues remain exact |
| Sudoku | Mockup layout: 441px board at (19,114) with 3px box separators/frame and 1px cell edges, SemiBold givens and Regular entries, shaded row/column guides with a box corner mark, 91x50 keys beside Notes/Undo/Erase; retain note digits, active Notes outline, explicit Check and saved undo |
| Crown Fields | Large board, corner region letters and solid 5px region boundaries; keep crown/X marks independent of color |
| Ten Pairs | Full-width 8-column sheet; rectangular row heights adapt to 4–11 rows while preserving reading order and usable digits |
| Quiet Mines | Shown as "Minesweeper". Mockup layout: mine/safe counters with icons, 440px field with 2px rules, Prev/Flag/Hint/Undo/Reset; closed squares are small raised keys (1px rounded outline, 2px lower edge, user request 2026-11-18) and opened squares are flat, with a small dot when empty; messages replace the Safe/Flags line until the next move; difficulty moved to Help |
| Sum Cross | Larger clue grid, filled inactive cells and a backslash separator between down/top-right and across/bottom-left clues; retain the 10-key number/Clear pad |

These are scoped exceptions, not permission to create a different theme.
Pocket Golf remains shelved and off the card. Wallpaper Randomizer is a utility
and does not receive this game-theme rollout.

## Change record — 2026-11-18 / user mockups for Sudoku, Minesweeper, Nonogram

> Current. Merged over PRs #23/#24 ("Playschool portrait cleanup" and "Approved
> portrait mockups" below, an earlier attempt at the same mockups): where they disagree,
> this record and "board size and touches" win. #22's generated-only navigation is kept.

The user supplied target images (`~/Desktop/XTEink/Games/*.png`) and asked for
the three on-card games to look exactly like them. They were measured after
cropping the screens to 480x800 and fitted with Inter: titles ~Bold 42,
labels/buttons ~SemiBold 21-25. Comparisons:
[Sudoku](design/mockup-2026-11-18/sudoku.png),
[Minesweeper](design/mockup-2026-11-18/minesweeper.png),
[Nonogram](design/mockup-2026-11-18/nonogram.png) (mockup left, host bitmap render right).

| Change | Why |
| --- | --- |
| Poppins roles replaced with Inter SemiBold/Bold; new `title`, `digit`, `digit_light`, `clue_large` roles | Every mockup label is a heavy Inter-like sans; 378 images, 245 KB decoded, inside the existing budget |
| Thinner 3px controls with a 1px lower edge, 9px radius | Mockup buttons; Check no longer differs from other controls |
| One-bit dot-screen guide tiles (`UI.shade`) | The mockups' grey row/column highlight; the panel is one-bit and the canvas has no grey fill, so a fixed 11% screen is drawn as baked PNG tiles |
| Sudoku board 468 -> 441px | The mockup keeps ~19px side margins; hub minimum updated |
| Departures kept on purpose | Minesweeper's opened-empty dot (mockup cannot show open vs closed), bottom line shows progress (Safe opened / Flags placed) rather than the mockup's static totals, Nonogram puzzles keep their own clue counts so header/gutter size varies |

The other eight games receive the new fonts and control style through the shared
copies; their layouts and tests are unchanged.

**Device photos of 0.6.0 / 0.5.0 / 0.9.0 (same day):** all three drew in the
system font ("System fonts active" in Nonogram), so the bitmap pack failed on the
reader and Sudoku showed its outline fallback bars. The pack had grown to 378
images / 82k decoded pixels / 101 KB source, past the last confirmed-good 333 /
64k / 80 KB, and every glyph was decoded eagerly in the first draw. The exact
firmware limit is unknown. Fixes in 0.6.1 / 0.5.1 / 0.9.1: glyphs decode lazily
(only what a screen shows), the separate 22px control role is gone (controls
use `body`), shade tiles 34-70 only (290 images, 80 KB source), the last
fallback reason is written to the app's `files/font-status.txt`, Nonogram no
longer covers its mode line with "System fonts active", and the guide outlines
were removed in favour of grey only. Device check still needed.

## Change record — 2026-11-07

| Change | Why / evidence |
| --- | --- |
| v0.4 Nonogram font treatment adopted for all active games | User confirmed it looks substantially better and requested the same treatment everywhere |
| Nonogram centering based on measured composition | Fixed right anchoring left smaller clue/board combinations visually unbalanced; dynamic gutters preserve both centering and clue readability |
| Increase grid/frame/mark weight | Direct user feedback after the physical v0.4 test |
| Promote fonts/theme to shared owners and synchronize copies | User requested consistent future changes and repo notes; copy checks prevent drift |
| Expand shared Latin glyph coverage | All game titles, help and action labels must use the chosen family; preserve whole-string native fallback for unsupported text |
| Remove redundant double borders and fix truncated labels | Render review found unnecessary ornament in Line Lift/Summit Putt, and a truncated Sudoku Notes label |

Original app IDs, save files, generated seeds, unlocked progress, unfinished
boards and undo histories remain the update contract. Install over existing
apps; organizing installers must not alter `XTApps/`.

## Change record — 2026-11-08 / Sudoku reference comparison

The user's physical photographs show that the stock Sudoku uses space and grid
hierarchy more effectively than our v0.2. The user explicitly requested closer
spatial efficiency while preserving the existing family typography/rounding.
Our prior one-pixel difference between minor and box lines was insufficient on
the device. Per-given boxes also competed with the actual puzzle boundaries.

| Change | Why / measurable result |
| --- | --- |
| Board grows from 414×414 at (33,164) to 468×468 at (6,108) | Reclaim passive heading/legend space; 52px cells replace 46px cells, about 28% more board area |
| Draw all grid edges as filled pixel bars | Four-pixel box/outer boundaries remain visible independently of firmware line-width handling; one-pixel minor edges establish clear hierarchy |
| Bold fixed clues replace per-cell boxes | Preserve the givens/entered-value distinction while removing dozens of competing outlines; existing Poppins SemiBold face adds no font image overhead |
| Three rows of digits beside Notes/Undo/Erase | Familiar reference layout; every digit is 98×52px instead of 44×61px, with a clear reading order |
| New and explicit Check remain in the header | Preserve deliberate generation/submission and correct-but-unsubmitted saves; all header targets are at least 48px high |
| Compact puzzle/difficulty row and live counts/status | Preserve progress and feedback without permanent instruction banners; full rules stay behind Help |
| Rounded icon board, readable Poppins digits, one emphasized center cell | Replace the old hand-drawn digital-looking numerals with the same licensed family, improving the silhouette at 96px/64px |

`strong` is an additive alias in the canonical UI; other game roles and the
333-image font pack are unchanged. `UI.button` accepts an optional `font` role
for large numeric keys and retains its measured fallback/padding rules. App
copies are synchronized. The source engines/generators/save formats stay intact;
Games Hub v0.2.0 includes Sudoku v0.3.0 via the normal generated bundle.

General lesson for future games: spend space on the board and usable controls;
make rule-bearing boundaries clearly distinct; move stable explanations into
Help; preserve live feedback. Do not add outlines to every object merely to
make the UI feel polished. Rounded controls and deliberate type remain the
family identity. Sudoku's straight continuous grid is an explicit exception to
rounded outer play-area frames; its solid bar geometry must not be restyled.

See [before/after](design/sudoku-2026-11-08/before-after.png) and
[eight actual bitmap states](design/sudoku-2026-11-08/states.png). Regressions
inspect both separator geometry and raster pixels, all 81 cell hitboxes, all
nine keypad hitboxes, native/enlarged and bitmap layouts, saved boards and undo.
The old v0.2 physical photo is evidence of the problem; the new host previews
do not establish physical-device success. Check the revised grid, icon, clue
weight and keypad on the reader before recording a confirmed result.

## Verification and future work

### Complete 17-game pass — 2026-11-08

User requested one complete review and rollout, including new upstream games,
so they do not need to request each game's layout or install each update.
Upstream `2a6af10` added Crown Fields, Ten Pairs, Quiet Mines and Sum Cross;
these now use the same canonical fonts, theme, icon typography and quality gate.
The [rollout plan](GAME_ROLLOUT_PLAN.md) records every game's review decision.

Shared `UI.grid_geometry` reserves a real play band before computing a cell
size. `UI.grid` uses filled pixel bars, with explicit row height for number
sheets; `UI.stroke` guarantees semantic horizontal/vertical stroke widths.
These avoid relying on one-pixel native stroke differences. Line Lift's
interrupted rods retain their gaps; Island Links' paired bridges retain their
separation. Frame/region tests reject cramped boards and missing filled edges.
Sum Cross's old diagonal crossed its own clue positions: it now separates
their upper-right/lower-left corners correctly, with a regression. Ray Vault's
X marks are centered after enlarging the rim composition.

Sparse authored shapes are not stretched arbitrarily. Nonogram keeps its
approved measured clue composition; Oddity Hunt retains its already full shelf
and object hitboxes. Their semantic strokes, metadata and icons were reviewed
and refined. Oddity target chips adapt to measured name widths so names such
as UMBRELLA remain complete at enlarged and bitmap font metrics. Sudoku retains the new large layout and shares the grid owner.
Every active game has a versioned release; stock Sudoku and shelved Paper Golf
remain outside this rollout.

The icon pass uses readable Poppins numerals/letters where relevant, stronger
silhouettes and clear game metaphors at 96px and 64px. Sudoku's recently refined
icon is retained. The icon sheet now sizes itself to every active app rather
than clipping later rows. All exported and packaged native icon pixels match.

Games Hub includes all 17 engines in 30/32 code files (about 383 KB / 512 KiB
code limit), without increasing the font image pack. Five large list rows per
page reduce navigation; Resume stores a stable game ID and still reads legacy
numeric records. The builder matches descriptions by game key and asserts
complete coverage, avoiding accidental truncation when more games arrive.

The full gate passes 17 standalone and bundled gameplay suites, 3,904 bitmap
layout frames in total, enlarged/native fonts, stable saves/undo, independent
solutions, all menu pages/row taps, cache release and native icon checks.
The peak bitmap frame uses 589 commands, below the 950-command guard. See the
[full before/after review](design/full-rollout-2026-11-08/README.md),
[current first frames](design/game-family/first-sheet.png),
[dense frames](design/game-family/dense-sheet.png) and
[icons](design/game-family/icons.png). These remain host previews.

`scripts/release_games.py` performs the repeatable complete check/build/archive
and optional direct SD deployment. It guards immutable versioned packages with
source fingerprints, updates the latest catalogue, backs up installed apps and
recovery installers, and verifies all app data. New standalone games become
available through the existing updated hub, without extra firmware registration.
Changes during verification or unversioned source changes stop the release.
Physical reader startup, touches and refresh behavior still need device checks.

CI also caught a Lua 5.4/5.5 numeric-string difference in Sudoku pencil notes.
The save writer now emits integer masks explicitly; the reader recovers exact
integral decimal masks from older saves, including undo snapshots. Selection,
Notes mode and unfinished boards survive. Sudoku 0.3.2 and Hub 0.3.3 include
this correction, tested on Lua 5.1 and 5.4 with Lua 5.5 compatibility checks.

### Games Hub — one collection update

User requested an easier way to install all game updates. Games Hub v0.1.0
packages all 13 active engines under one stable `gameshub` app ID, so future
collection updates require one firmware installation. It uses the same bitmap
fonts and tokens; four roomy game cards per page and a Resume action provide
48px-plus touch areas. A 44px nine-dot button in the header returns to the
collection. The header adapter reserves its space without shrinking boards or
moving game controls. The Nonogram brand mark yields that space to navigation.

Do not fork the engines to style the collection. `build_game_hub.py` wraps each
source engine and its private modules, shares the canonical UI/theme/fonts,
and records source fingerprints. `games/games-hub/src/ui.lua` only adapts header
space and delegates measurement/drawing to generated `ui_core.lua`. The
collection has its own required quality checks and a distinct native icon.

Each game's unchanged filenames are prefixed with its original app ID inside
the hub's own save sandbox. A fresh engine instance is created when opening a
game; its fonts are released when closing it. Namespace read errors disable
writes, and save failures keep the game open rather than leaving unsaved work.
`install_games_hub.py` makes a private, backed-up first-launch import of existing
standalone saves. It adds only missing records, verifies writes, retries partial
imports, and never overwrites existing hub progress. Public builds have no
personal data. Original installed apps and saves remain untouched.

Host checks replay all 13 original suites through the bundled engines with
native/enlarged and shipped bitmap metrics. Collection checks cover switching,
unfinished boards and undo, import/retry/malformed data, save/read failures,
blocked import recovery, menu layout, code/file budgets and image cleanup.
Inspect [collection previews](design/games-hub/overview.png). Physical startup,
first import, repeated switching, touch and sleep/resume remain required.

Required process after a design change:

```bash
python3 scripts/make_game_fonts.py --check
python3 scripts/sync_game_ui.py
python3 scripts/sync_game_theme.py
python3 scripts/build_game_hub.py
python3 scripts/check_games.py --packer /path/to/xtpack.py --linter /path/to/lualint55.py
python3 scripts/render_games.py
python3 scripts/render_game_hub.py
python3 scripts/render_sudoku.py
```

The quality gate runs both the existing native/font-margin gameplay suites and
the **same complete suites with bitmap fonts active**. It audits text collisions,
glyph ink bounds, paragraph overflow, full control labels, image-cache cleanup
and drawing limits. The canonical glyph mask/provenance test runs once; every
app copy must match that pack. Package checks verify each native launcher icon.
The first rollout passed 1,434 bitmap-layout frames; the peak was 589 drawing
commands, below the 950-command regression ceiling and documented approximate
1,024-command host limit.

Inspect [first screens](design/game-family/first-sheet.png),
[dense screens](design/game-family/dense-sheet.png) and
[help screens](design/game-family/help-sheet.png). These replay actual shipped
glyphs and Lua drawing commands, but remain host previews. Review visual hierarchy
and symbol separation separately from deterministic checks.

The shared pack currently has 333 images / 64,384 pixels. Its RGB pixel payload
would be 193,152 bytes; native handle and Lua overhead are additional and not
measured on the reader. The wider family pack and each game still need physical
startup, repeated edits, touch, sleep/resume, glyph polarity and ghosting checks.
If a physical observation changes a token or an exception, record the firmware,
affected state, before/after decision and reason here, then add the corresponding
regression or review fixture at the appropriate shared layer.

## Reasoning-depth curation — 2026-11-14

Line Lift, Oddity Hunt and Word Hunt remain archived for limited multi-step reasoning depth.
Ten Pairs was subsequently reinstated at the user's request, retaining its exact original rules and saves. Earlier design notes for them remain historical.
See `games/archive/README.md` for project-specific reasons and reactivation bars.

## Second reasoning-depth audit (2026-11-14)

A deeper authored-level review moved Link Grid, Ink Runes and Word Bridge to
`games/archive/`. The current active collection has eleven games. Solver
uniqueness proves correctness, not human difficulty. See
`games/REASONING_AUDIT.md` for source evidence, retention rationale, and
known challenge limitations. Original content and user saves are preserved.

## Design decision — 2026-11-17 / screen-space feedback

The user compared our game screens with XTEINK community games and identified
unused screen real estate as a material quality gap. Adopted **purposeful
full-screen density** as the standard for future work: minimize fixed chrome,
use adaptive gameplay geometry, position actions adjacent to play, and review
empty bands rather than accepting a fit-only layout. Preserve the established
Poppins/Inter theme, strong rule-bearing lines, measured text/touch targets,
aspect ratios, saves and per-game exceptions. The 2026-11-08 Sudoku expansion
is the documented precedent; this decision does not claim a new family-wide
layout pass or device verification.


## Sudoku pilot — 2026-11-17 / screen-space acceptance

Sudoku already uses 468px of the 480px width with no unexplained 48px
vertical blank band. The pilot therefore keeps its square board unchanged
and reclaims stacked heading/status spacing for 60px-tall keypad and
Notes/Undo/Erase controls instead of 52px (15.4% more numeric touch area).
See [Sudoku pilot evidence](design/sudoku-screen-space-2026-11-17/README.md).
Normal/enlarged UI measurements and host bitmap before/after rendering are
required; physical reader acceptance remains pending.

## Sudoku Meditation parity — 2026-11-17

Strong Sudoku-only grid strokes (2px minor, 5px box and frame) replace thin
rules. The selected row and column receive static outlines, selected 3x3 box
gets brackets, and matching numbers get underlines. Tiny pencil numerals,
note lock, multi selection, five difficulty controls and settings use the
existing 468px board and 60px keypad geometry. Existing saves remain
compatible. See [feature matrix](design/sudoku-meditation-2026-11-17/FEATURE_PARITY.md).


## Nonogram logic-first density pilot — November 2026

The 0.7.0 source changes reserve a measured clue-plus-board region
(y=112..630), use bounded square cells of up to 70/50/45/35px for
5/7/8/10-square puzzles, and provide stronger 4px internal and
5px semantic rules. Selection and forced-move hints appear as static
monochrome outlines. The 10x10 35px target is an explicit on-device
review item; denser grids are not included. See the Nonogram design
record for save compatibility and independent reasoning evidence.

## Quiet Mines board-first density pilot — 2026-11-18

The user's 14×14 mobile HTML reference prioritizes the field, moves settings
off-canvas, and separates Reveal/Flag actions. For the 480×800 Licorice
reader, retain the existing twelve start-anchored boards and add twelve
10×10/12×12 no-guess fields instead of copying a phone-density 14×14 grid
with roughly 32px cells. New 12×12 cells are 38px and require real
touch and ghosting review.

Quiet Mines v0.3.0 centers a 456–460px square field between y=118 and
586; x ranges from 9 to 12. The field occupies more of the playable
screen, up from a maximum 448px square. Row metadata is at y=76,
safe/flag counters at y=600, contextual hint/status at y=650,
and five 66px-high controls at y=710. The controls are distinct,
with active Flag mode visually outlined, and S marks the required first
safe zero cell. Grids use 2px minor, 4px fifth and 5px outer rules.
There are no unexplained 48px vertical bands between functional regions.

A deduction-only Hint highlights a logically forced move (direct-number
or overlapping subset), never automatically opens or flags. Existing
save history and original field indices remain stable. The authoring
quality gate separately verifies old direct-deduction fields and new
subset-deduction boards. Successful host geometry and packaged bitmap
renders do not establish physical acceptance.

## Procedural-puzzle default — 2026-11-18

The user's requirement is new playable puzzles generated at the time of
play for Sudoku, Nonogram and Quiet Mines, rather than fixed starting
campaigns. The Meditation repository contains the Sudoku generator; the
user-provided Minesweeper HTML contains seeded random placement and
deduction-based candidate filtering. Nonogram already had a v2 generator.

New sessions use fresh numeric seeds and preserve those seeds (or the
exact Mines layout) alongside puzzle marks. Historic authored boards
remain available only to protect installed saves. The standard for Mines
and Nonogram is no guessing under the documented deduction engine;
Sudoku requires one exact solution but has not been certified against
the Meditation human-technique difficulty classifier.

New game creation must not silently replace an unfinished saved stage,
and a failed generation attempt must not publish an unverified field.
One 480×800 e-ink frame is drawn per interaction; no animation,
background regeneration, color clues or new permissions are required.
Host-run solver, save, geometry, font and Games Hub checks are necessary
but still do not establish physical latency or touchscreen accuracy.


### Reference generator review: Logic Picross ZIP

The supplied `picross-nonogram-generator(3)(1).zip` is a useful
procedural-generation reference. Its `app.js` creates a hidden pixel
pattern before deriving row and column clues, then checks solution
uniqueness using a bounded search and verifies logic solvability
with legal line-pattern intersection. It applies density, shape and
difficulty filters, and offers blob, symmetric, icon-like and noisy
candidate styles. These are separate tasks; random pixels and
solvable clues by themselves are not enough to establish quality.

The XTEINK Nonogram already implements a bounded line-pattern
constraint propagator on 7×7–10×10 boards, a direct constructive
no-guess proof, and randomized stored seeds for fresh sessions.
It deliberately retains its existing v2 picture generator and
its fallback only when the latter is *also* checked by propagation.
The ZIP's last-resort fallback is **not** a substitute for the
full uniqueness and human-logic checks: it returns a constructed
pattern after the strict generation attempts and does not rerun
the bounded uniqueness counter on that last branch.

The ZIP's 15×15–25×25 profiles, optional speculative contradiction
probing, animation, timer, and browser persistence are not part of
this 480×800 native-device update. Visual shape styles and better
human technique/difficulty scoring are possible follow-ons, but
must be verified against clue gutter size and physical touch
targets, not treated as silently completed in this change.

## Generated-only active campaigns — 2026-11-18

Sudoku already generates every game from a fresh, saved seed. Nonogram v0.9.0 and Quiet Mines v0.5.0 remove the authored campaign from fresh gameplay and from the Nonogram browser preview. Their random/generated board history begins at internal IDs 13 and 25 to avoid collisions with installed saves, but the visible count begins at Puzzle/Field 1. PREV from the first generated puzzle must **not** reveal older authored boards. New and regenerated-puzzle UI must never load an archived original or use an unverified puzzle fallback.

`legacy_pictures.lua` and `legacy_levels.lua` contain original fixed layouts **only** for compatibility with previously saved games. These are not choices for new players and are not authored levels in the active campaign. Removing the compatibility data entirely would corrupt installed saves, violating AGENTS.md. Historical tests verify this data's integrity separately from generated-puzzle gameplay and browser parity.

The acceptance gate now asserts generated-first navigation, only generated preview seeds, original-save recovery, solver acceptance, installed font geometry and refreshed Games Hub source fingerprints. The code remains source-only until device installation and on-reader save/latency/touch review.

## Playschool portrait cleanup — 2026-11-18

The user's photographed physical X4 Pro shows the two main pain points:
Quiet Mines' inset outline in **every** unopened tile looks busy, while
Sudoku's full-row/full-column selection rails muddy the puzzle. The approved
portrait concept uses a very large board, bold single-purpose controls, a
clear selected cell, gentle background contrast and restrained relief; the
requested aesthetic is simple and intuitive, **not** childish. On-device
implementation is 480×800 and static grayscale is not assumed available.

| Game | Play space and UI decision | State preserved |
| --- | --- | --- |
| Sudoku 0.5.1 | Board remains (6,100), 468×468, 52px cells. A staggered 2×2px 1-bit dot every 12px gives the selected row/column a quiet wash *behind* grid and glyphs; remove rails and 3×3 corner brackets. One 4px selected cell border remains. 60px keys and Notes/Undo/Erase unchanged. | Fixed/generated numbers, notes, match underlines, check and menus |
| Quiet Mines 0.5.1 | Normal 10×10 uses 460px board with 46px cells (8×8 and 12×12 recomputed from the same 118–586 band). Remove individual inset boxes and false five-cell boundaries. One 2px shared interior rule, 4px frame, and two 1px right/bottom bevels on unopened cells distinguish tile state. | Safe opening, mines, flags, clue/hint deductions, history, difficulty and save archive |
| Nonogram 0.9.1 | Keep the measured clue + square-board centered; 10×10 cap grows to 37px if fit permits, 2px minor grid / 3px fifth separators / 4px frame. Replace thick crosshair rails with the same sparse focus wash and one selected-cell border; remove decorative header symbol. | Generated puzzle seed/solution, clues, checked rows, X/fill, hint, history and legacy restores |

All three: primary controls gain a *single* outlined rounded body with a
restrained **1px bottom and right shadow offset**. The active Flag/X/Notes
states have a thicker border **instead of** a distracting secondary inset.
This avoids gradients and full gray fills that have unreliable firmware
behavior. No color is essential to identifying state; saved records and touch
hitboxes do not change.

Visual review covers empty/first, selected, in-progress, dense/large, solved,
help and enlarged-glyph frames in CI, including additional assertions on
absence of old guide rails and inset Mines cells. Command use is deliberately
bounded (Sudoku selection approximately 300 extra 2px stipple dots; Mines
maximum 288 1px bevel strokes for a 12×12 field); physical ghosting and actual
refresh latency must still be checked on the X4 Pro. The small additional
padding around control silhouettes is purely painted, not tappable.


## Approved portrait mockups, direct code implementation — 2026-11-18

**Authority:** the three portrait 480×800 device mockups the user approved
(November 18, after rejecting the earlier preview layout). This supersedes
the preceding light-touch "playschool portrait cleanup" where the actual
screen hierarchy differs. "One for one" means match the *screen layout
geometry and visual hierarchy* at device resolution, not that a 1-bit XTOS
canvas can reproduce the photographic case, grayscale bevels, anti-aliasing,
or paper texture from an AI-rendered image.

### Native 480×800 coordinate specification

| Part | Sudoku v0.6.0 | Minesweeper v0.6.0 | Nonogram v1.0.0 |
| --- | --- | --- | --- |
| Header | Sudoku at (22,22); New/Check/? at y18; Puzzle 1/Medium at y78 | Minesweeper (22,21); New/? at y18; mine/safe totals at y96 | Nonogram (22,21); New/? at y18; no second header/tool row |
| Board | 9×9, **441×441** at **(19,126)**; **49px** cells; 5px 3×3 boundaries | n×n, **440px** maximum at **(20,152)** for 10×10; 44px cells; 8×8/12×12 centered in same region | Row and column clues + n×n square board centered within the **488px** region starting y102; cell cap 37px at 10×10 where all clues fit |
| Selection or state | Light 1-bit stipple on selected row + column; **one bold active square** | Connected 2px grid, no double-box tiles; unobtrusive one-pixel cell relief; all random fields retained | 2px grid, subtle staggered stipple selection, one outlined square; row/column numbers have priority over size |
| Progress/status | "Left n / Clashes m", y583 | "Safe n / target" and "Mines flags / total" at y612 | "Rows n / size" and "Cols n / size" at y608; mode text at y658 |
| Primary controls | Notes/Undo/Erase + 3×3 numeric keys, y620/680/740, height53 | Prev/Flag/Hint/Undo/Reset across y701, height62 | Prev/Undo/Reset/Check across y704, height62 |

The mockup intentionally **omits permanent administrative chrome**. In this
native implementation Minesweeper difficulty is changed in the **? / Help**
screen; Nonogram's **Fill/X** and **Hint** actions live in Help (with a
tap on the footer mode text as a shortcut). This preserves all functionality
while matching the approved idle frame. The **New** action always creates a
procedurally generated board in all three games. Save IDs, legacy pictures,
mine layouts, hint logic, no-guess guarantees and undo are unchanged.

Button borders remain rounded, with measured Poppins/Inter bitmap text.
The subtle photographic shadow is approximated by two small offset 1-bit
rectangles (2px bottom/right) rather than a gray alpha shadow; fine one-pixel halftone
approximates the reference's gray selection wash. Do not replace these
with image backgrounds: display geometry, labels and hitboxes must remain
live and responsive to screen state. The device is *actually* 480×800; do
not implement the bezel photograph or photographic optical distortion.

**Verification:** host layout tests assert board size, hit geometry,
selected-cell structure, message bounds, flags and restored histories;
full Games Hub bundling and installer builds still required. The host
raster cannot prove anti-aliasing, ghosting, gray levels or refresh speed on
the physical X4 Pro. A device-photo side-by-side at 480×800 is the final
acceptance evidence for "identical" appearance.

## Change record — 2026-11-18 / board size and touches

User: "negative space is the enemy" — maximize board size without losing function.
Boards now take the full width: Sudoku 468px (52px cells, 6px margins), Minesweeper
468px field from y=114, Nonogram a 472px composition with no 70px cell cap. Headers
start at x=6; the Hub shifts any header text that starts left of x=74 past its HUB key.
Spare height went to taller keys (Sudoku 56px, Minesweeper 82px) and useful lines:
Minesweeper always shows Safe/Flags plus a mode or message line.

Touches: active toggles (Notes, Flag, Hint, the Nonogram Fill/X switch) look pressed
in — grey fill, a shadow along the top edge and no raised lower edge; Sudoku digit keys
show how many of that digit are left (a finished digit turns light); Minesweeper's
hinted square is grey instead of outlined; Nonogram's satisfied clues are grey.
`UI.shade_rect` tiles non-square areas with the 34-84px shade tiles, keeping the dot
phase. Font data is 82 KB (shade tiles 34-84); device check still needed.


## Sudoku HTML port — 2026-11-20

The attached HTML prototype puts the 9×9 board flush to the top of a
480×800 canvas, followed by a calculator-order numeric pad and four stacked
tools. The native 0.7.0 layout follows that hierarchy with a 477px integer
board (53px cells, 1px margin) so all grid lines stay crisp in one-bit ink.
A 24px feedback band is reserved for critical save/error status; keypad
buttons are 108×90px, and tool targets 106×66px. The full-screen menu retains
legacy operations and adds reveal/mistake-assist parity. It does not attempt
to render the HTML/CSS or reproduce web-only anti-aliased shadows and colors.
The source of truth is `games/sudoku/app/index.lua` and its measured UI tests.
Physical appearance, touch accuracy and persistence are still to be checked.

**Games Hub exception:** The Hub's reserved top-left return button must
remain usable and unobstructed. Embedded Sudoku uses a 441px square board at
(19,66); standalone Sudoku uses the 477px board at (1,1). The same hitbox
geometry is used for drawing and taps in each host mode. The Hub provides an
explicit internal host flag; no firmware API detection is assumed.
