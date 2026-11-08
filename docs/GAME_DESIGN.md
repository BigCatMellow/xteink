# Game design contract and change record

This is the design owner for the **17 active games** in
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

| Role | Typeface | Use |
| --- | --- | --- |
| Game/help heading | Poppins SemiBold, 30px | Clear family identity; game headings use title case |
| Normal controls | Poppins Medium, 24px | Round, welcoming action labels |
| Compact controls | Inter Medium, 20px | Preserve full labels inside compact targets |
| Body/game data | Inter Medium, 24px | Rules, counters, word cards and readable game data |
| Metadata/status | Inter Medium, 20px | Secondary information without competing with the board |
| Numeric clues | Inter Medium, 20/24px, tabular digits | Stable clue alignment and distinct numbers |
| Emphasized numbers (`strong`) | Existing Poppins SemiBold, 30px | Sudoku fixed clues and large number keys; aliases the shipped heading face without extra glyph images |

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

- Controls: 12px radius, 3px ordinary outline, 4px Check/Next/continuation outline.
- Large square play-area frames: 10px radius, generally 4px emphasis.
- Connected grid interiors: straight shared edges. `UI.grid` uses 1px cell
  edges and a 4px frame; semantic regions/box boundaries stay visibly stronger.
  Nonogram retains its approved 3px grid and 4px frame.
- Filled marks: 3px corner radius. Nonogram's X marks use 4px strokes.
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
| Nonogram | Center measured clues and board together; 3px grid, 4px frame/marks; preserve correct-but-unsubmitted boards and the solved Next action |
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
| Sudoku | v0.3 uses a 468px board, solid 4px box separators against 1px cell edges, bold givens and a three-column keypad. Remove per-given boxes and passive legends; retain note dots, active Notes/key outlines, explicit Check and saved undo |
| Crown Fields | Large board, corner region letters and solid 5px region boundaries; keep crown/X marks independent of color |
| Ten Pairs | Full-width 8-column sheet; rectangular row heights adapt to 4–11 rows while preserving reading order and usable digits |
| Quiet Mines | Large field, clear open/closed/flag states, outlined active Flag mode and persistent mode/count feedback |
| Sum Cross | Larger clue grid, filled inactive cells and a backslash separator between down/top-right and across/bottom-left clues; retain the 10-key number/Clear pad |

These are scoped exceptions, not permission to create a different theme.
Pocket Golf remains shelved and off the card. Wallpaper Randomizer is a utility
and does not receive this game-theme rollout.

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
and records source fingerprints. `games-hub/src/ui.lua` only adapts header
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
