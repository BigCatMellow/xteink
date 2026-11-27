# Reading Roadmap — visual and interaction contract

Status: adopted for the standalone X4 Pro InkApp v0.5.0 and its matching 480×800 HTML canvas preview. Host rendering is not physical X4 Pro evidence. Owner: Reading Roadmap app. This document does **not** change the games' design contract.

## Source of authority

1. The user's request: a reading-order tracker whose **HTML and installed native app are 1:1** in labels, layouts, interactions, and eventually device-rendered typography.
2. `../../docs/GAME_DESIGN.md`: the X4 Pro's existing monochrome, space-efficient visual contract, shared Inter type roles, 9px rounded controls, 3px strokes, and direct correspondence between visual and touch target boundaries.
3. `BigCatMellow/Pilot_Projects/ai-design-bible/rules/VISUAL.md`: hierarchy, explicit typography roles, semantic spacing, coordinated corners and deliberate density.
4. `BigCatMellow/Pilot_Projects/ai-design-bible/rules/INTERACTION.md`: truthful affordances, concrete action labels, recovery after interruption, and reliable state transitions.

The game-specific puzzle board requirements do **not** apply to a reading tracker. The standalone app uses the firmware's native fonts today, not the bitmap Inter pack used by the game collection. That is a known **font parity gap**, not an approved exception; native Inter glyphs and a browser measurement fixture are needed before claiming pixel-identical typography.

## User tasks and hierarchy

1. Orient: what am I reading, what comes next, what have I completed, and which books can the reader identify?
2. Open: tap the title area of an available book to request the stock EPUB reader immediately; if it is not linked, offer linking only where possible.
3. Manage (secondary): tap the separate INFO target to see the recommendation, mark started/finished, or change the reader link.
4. Explore: move through Path, All and Finished lists; tap Check to rescan available reader metadata and see complications.

Do not add a dashboard, clock, streak, animation, or decorative cover images merely to fill space. Favor one clear state, legible words and direct controls.

## Native visual tokens

| Item | Contract |
| --- | --- |
| Canvas | 480 × 800 portrait, strictly monochrome |
| Title | large native role (browser approximates at 30px) |
| Body / buttons | medium native role (browser approximates at 24px) |
| Metadata | small native role (browser approximates at 20px) |
| Controls | 9px corner radius, 3px outline and subtle lower 1px line |
| Selected tab/state | inset outline, never color alone |
| Rows | 84px high, 91px pitch, six per page; full 462×84 touch rect |
| Selected/next row | 3px frame, 8px radius; primary open target is x9–408, secondary INFO target x408–471 |
| Other rows | quiet 1px bottom divider; checkbox (x9–67) = mark read, title (x67–407) = open, divided INFO (x408–471) = manage |
| Screen | 76px title/progress header; controls below the scroll-free rows |

Text and padding should be bounded based on measured glyphs, not character counts. Reserve two title lines if needed; keep the metadata distinct. Long descriptions and visual references should wrap instead of clipping. The fixed six-row screen deliberately uses its whole useful vertical band while leaving touch gutters between high-frequency footer controls.

## Changes made for v0.4.1

| Problem in v0.1.0 | Improvement | Why |
| --- | --- | --- |
| Six equally strong square outlines obscure hierarchy | Only current/next book is framed; other entries have dividers, numeric order and chevrons | Task hierarchy VISUAL-001 and legible grouping SPACE-001 |
| `[ ]` does not communicate why the book matters or position | Stable 01…33 numbers and explicit READ NEXT, READING, FINISHED, TO READ text | Readable state without mental mapping |
| Long titles were ellipsized on list rows | Up to two wrapped title lines, then metadata in the same 84px target | Prevent information loss at 480px width |
| Button corners were square, 2px frames; active tabs not visible | Shared-family rounded 9px / 3px style, selected inset on active tab and status | SHAPE-001, meaningful selection and consistent affordances |
| Detail screen reserved a fixed empty 100px band | Dynamic title/note/reference layout, followed by Previous/Next Book controls | DENSITY-001 and next-action continuity |
| Empty Finished view contained a blank page | Meaningful empty-state explanation and Back to Path control | Recoverable state, no unexplained whitespace |
| Disabled Prev/Next pages still looked like functional buttons | Omit unavailable page arrows | INT-001: visible actions should actually work |
| Unlinked books offered OPEN BOOK despite no valid link | Show a single full-width LINK AN EPUB action until a book is linked; show Link/Open only after linking | INT-002, honest action availability and clearer priority |

**Constrained non-goals:** do not invent EPUB file paths, pretend a direct-open API is verified, auto-finish a book solely from reader statistics, or change saved book IDs. Keep per-book status and link data in the app sandbox. Changing API permissions requires device confirmation.

## v0.4.1: remove the mandatory detail-page detour

User feedback: “when you click on the book it should just take you to it.” The primary object must perform the primary task. This overrides the earlier detail-first design without weakening the visual or safety constraints.

- Primary 399×84 book-row target (x9–408): try to open the associated book in the stock reader. Existing reader IDs are matched by exact normalized title when possible.
- Secondary 63×84 INFO target (x408–471): opens optional book description, completion controls and link management. Draw the vertical separator at x407; title lines must stay within 314px to avoid that target.
- If the selected EPUB has not been linked and the reader reports books, go straight to the existing link picker. A selection stores that link and attempts to open it, then returns to the list. If the reader does not report any books, keep the user on the list and show “Not on device: open this EPUB from Bookshelf first.”
- Never silently open another book, claim launch success from a missing response, or fabricate a file path. Direct reader-launch API behavior is **not physically verified**. Preserve the secondary INFO and manual status editing as fallbacks.
- Hardware Back returns from linking to the originating screen and restores its page. All changes are mirrored in the HTML preview and tested.

## v0.4.1: automatic matching and complications

User requested that the app **search for the books** and **list any complications**.

- The firmware-supported source is `ctx.reader:all_books()` plus `ctx.reader:books()`. The former includes books opened at least once, **not all EPUB files physically present on SD**. The app has no documented general SD-card directory enumeration API. Therefore `NOT INDEXED` explicitly means the title is not in the reader's history, **not** that it is absent from storage.
- On startup, on opening the Check tab, and when returning from book management, scan the available reader index. Coalesce by reader ID and use **unique exact normalized titles** to auto-link. Trim filename .epub/.txt suffixes and punctuation. Do not automatically select multiple exact matches or merely similar titles.
- The **Check** tab lists issues in reading order: `NOT INDEXED` (open once in Bookshelf), `MULTIPLE` (several editions), `CHECK TITLE` (similar title requiring manual review), `LINK CHANGED` (saved link missing), and `NO ACCESS` (reader API unavailable).
- Show a concise resolution per issue on the same screen. An issue row opens its book-management screen for manual linking; returning from that screen restores Check and its previous page.
- A successful unique match counts as identified; never silently claim every EPUB is found on the SD card. Previously saved progress and explicit manual links have priority, and no file content is altered.
- Direct opening remains dependent on firmware behavior, which still needs physical confirmation. An absent or ambiguous match must not trigger a guessed EPUB launch.

## v0.5.0: card-aware matching and link persistence

Reviewed against the card's `Books/directory-tree.md` (693 files, verified identical to the card) and each book's metadata title.

| Problem in v0.4.1 | Change | Evidence |
| --- | --- | --- |
| `safe_text` returned gsub's count too; `save()` wrote `id\tstatus\trid\t0`, so after a relaunch every link read back as `rid\t0` and became LINK CHANGED | `safe_text`/`norm` return one value; test relaunches the app and reopens a linked book | regression fails on v0.4.1 code |
| Exact match only on the whole normalized title: `The Martian: A Novel`, `The Hobbit: Or There and Back Again`, `The Princess Bride: S. Morgenstern's…` stayed CHECK TITLE | Match the title without subtitle / series tag / edition note / file-name author tail | real card: 5 of the 7 present books auto-link if opened (was 3) |
| Substring suggestions: *In the Woods* offered for *A Walk in the Woods*; *The Martian Chronicles* for *The Martian* | Suggestions need shared leading words; a known different author vetoes | cross-language case table |
| NOT INDEXED said "open it in Bookshelf" for 26 books that are not on the card at all | Generated card list: NOT OPENED YET (with folder) vs NOT ON CARD; path rows say NOT ON CARD | `tools/card_from_tree.py` report |
| Missing books (most of the list) buried the fixable issues | CHECK sorts LINK CHANGED, MULTIPLE, CHECK TITLE, NOT OPENED YET, then NOT ON CARD | test asserts order |
| Tapping an unlinked book only toasted, though this design said it should go to the picker | MULTIPLE / CHECK TITLE / LINK CHANGED open the picker with candidates first (MATCH, newest last-read first); others toast the specific reason | host tests |
| Same-title records sorted nondeterministically (LuaJIT order differed) | Tie-break by last read date, then ID | repeated LuaJIT runs |

Known limits: the card list is a snapshot (date shown in CHECK footer and detail); a book added later is still found once opened in Bookshelf. `LINK AN EPUB` wording is kept for parity although some books are MOBI.

## v0.5.0: simpler rows, one-tap tracking

User goal: "simple and clean, but also allow you to track what you have read". Reviewed against VISUAL-001 (hierarchy), INT-001/002 (targets match grouping, concrete labels), STATE-002 (truthful state) and the screen-space rules in `docs/GAME_DESIGN.md`.

| Problem | Change | Why |
| --- | --- | --- |
| Marking a book read took INFO → FINISHED → BACK | 40px checkbox on every row (9px radius, 3px ink, check mark / filled square for reading); its own 58×84 target | Tracking is the primary repeat task; one tap, reversible |
| No way back from Finished or Reading | TO READ / READING / FINISHED segmented choice on INFO, selected inset | Every state choice can be undone (STATE-002) |
| Header `0 / 33 finished | Main path` repeated the tab name | `N / 33 read` plus a 452×14 progress bar | Progress at a glance; tab state is already shown by the selected tab |
| Rows carried number, chevron, divider, INFO and a `Genre | STATE | %` line | Title plus one quiet line: state when it matters (`Finished`, `43% read`, `Not on card`, `Up next | author`), otherwise author. Numbers kept in Check and on INFO (`Book 12 of 33`); genre moved to INFO | Less ink per row; the order is the list order |
| Two-line titles silently lost words ("…Small, / Angry") | Last line carries the remainder, shortened with `...` | Never hide information without a cue |
| Previous / Next Book row on INFO | Removed; list is one tap away | Fewer controls; frees room for long notes |
| Reader progress ignored by status | Unticked books with reader progress show as reading (display only) | Tracks what the reader already knows without auto-finishing |

**Documented gap exception:** on INFO the controls stay bottom-anchored (y=584–782) so they never move between books. Short notes leave up to ~90px above them; the longest entries (two-line title, three-line note, visual reference, card line) use that band.

Fonts: still the firmware's native roles (not the games' Inter bitmaps; this is a utility like Wallpaper Randomizer). Physical legibility of the 20px meta line and checkbox hit accuracy remain device checks.

## v0.6.0: the 211-book owned-library path

The catalogue is now `data/quality-first-211.json` (generated into both surfaces by `tools/build_catalog.py`).

| Problem at 211 books | Change | Why |
| --- | --- | --- |
| Positional save IDs would misassign progress when the list changed | Save by title key (`#roadmap2`); `#roadmap1` migrates via `V1_KEYS`; unknown rows kept | data/README.md migration requirement; no lost progress |
| PATH (9) / ALL (33) split no longer meaningful; 36 pages of ALL | Tabs PATH / DONE / CHECK (3 × 148px). PATH is the whole order and opens on the page with the book up next | One list, always landing where you are |
| 20 optional rereads in the order | Row meta `Optional reread`; "Up next" skips them | Favourites stay without becoming obligations |
| Detail content varies (143 books have no note; 42 have warnings) | Sections in priority order (WHY THIS BOOK 3 lines, HEADS-UP 2, VISUAL REFERENCE 2) shortened or dropped to keep ON YOUR XTEINK and controls fixed | CONTEXT-001 stable controls; no overlap |
| 54 listed books are MOBI | `LINK AN EPUB` became `LINK BOOK`; card line shows the format | Concrete, accurate labels (INT-002) |
| Junk metadata titles on the card (`Microsoft Word - …`, swapped title/author) | Per-file reader-title alias (unique only) and swapped-field rule; whole-title match wins among exact matches | Predicted auto-links: 168/211 now, 198/211 after duplicate cleanup |
| 211 × N title comparisons on an ESP32 | Book forms computed once; reader records memoised and bucketed by key and first two words | Host: 250 ms → 57 ms first scan, ~21 ms after; results identical to brute force |

## HTML and Lua parity

- The HTML canvas is the **preview**, not an alternate product. Editor sliders outside the 480×800 screen are preview-only experiments.
- Native and browser code have matching book IDs/order, row geometry, tap areas, tab labels, buttons, and display states. `tests/test_preview_parity.py` enforces major invariants and must be updated when the approved design changes.
- Any mockup change must be reproduced in Lua and the package version bumped **in the same PR**. A passing HTML screenshot alone is not a native-app delivery.
- For layout changes, inspect 480×800 captures of Path (initial, active, done, longest title), Done (empty and populated), Detail (with/without visual reference, longest title), and Link (empty and populated). Check no text/touch overlap under both normal and enlarged glyph metrics.
- Hardware acceptance is separate: installed-app screenshot alongside HTML, readable font weight, tap on each target (including corner and edge points), screen refresh/ghosting, state persistence and actual EPUB-open action where supported.

## Outstanding risks, verification and next steps

- **Unverified physical device:** real font width, contrast, rounded corner support, native text raster, tap coordinates and EPUB handoff.
- The firmware's system font and the browser's fallback font are not byte- or pixel-identical. We must measure a physical test or package the already-approved Inter bitmap system, then regenerate both renderers from the same font metrics.
- Saved progress is keyed by title; changing a title in the JSON orphans that book's row (kept, but unmatched). Rename only with a migration entry.
- Every update must retain status/linked-reader data after a device reinstall-over, and should not require uninstalling the prior app.

## Review outcome

The v0.6.0 source and preview use the same screen design as verified by the catalog/geometry regression, host Lua tests and browser interaction rendering. Hardware fidelity is **not** yet verified. Existing 11-game UI rules remain authoritative for games; this is the specific app's design owner.
