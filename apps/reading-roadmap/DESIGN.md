# Reading Roadmap — visual and interaction contract

Status: adopted for the standalone X4 Pro InkApp v0.2.1 and its matching 480×800 HTML canvas preview. Host rendering is not physical X4 Pro evidence. Owner: Reading Roadmap app. This document does **not** change the games' design contract.

## Source of authority

1. The user's request: a reading-order tracker whose **HTML and installed native app are 1:1** in labels, layouts, interactions, and eventually device-rendered typography.
2. `../../docs/GAME_DESIGN.md`: the X4 Pro's existing monochrome, space-efficient visual contract, shared Inter type roles, 9px rounded controls, 3px strokes, and direct correspondence between visual and touch target boundaries.
3. `BigCatMellow/Pilot_Projects/ai-design-bible/rules/VISUAL.md`: hierarchy, explicit typography roles, semantic spacing, coordinated corners and deliberate density.
4. `BigCatMellow/Pilot_Projects/ai-design-bible/rules/INTERACTION.md`: truthful affordances, concrete action labels, recovery after interruption, and reliable state transitions.

The game-specific puzzle board requirements do **not** apply to a reading tracker. The standalone app uses the firmware's native fonts today, not the bitmap Inter pack used by the game collection. That is a known **font parity gap**, not an approved exception; native Inter glyphs and a browser measurement fixture are needed before claiming pixel-identical typography.

## User tasks and hierarchy

1. Orient: what am I reading, what comes next, what have I completed?
2. Choose: tap a title to see author, recommendation, visual-reference suggestion and reader link.
3. Act: mark started/finished, link an already-opened EPUB, request an open in Bookshelf when supported.
4. Explore: move through the recommended sequence, with optional All and Finished filters.

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
| Selected/next row | 3px frame, 8px radius, full matching touch rect |
| Other rows | quiet 1px bottom divider; vector chevron cues tap |
| Screen | 76px title/progress header; controls below the scroll-free rows |

Text and padding should be bounded based on measured glyphs, not character counts. Reserve two title lines if needed; keep the metadata distinct. Long descriptions and visual references should wrap instead of clipping. The fixed six-row screen deliberately uses its whole useful vertical band while leaving touch gutters between high-frequency footer controls.

## Changes made for v0.2.1

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

## HTML and Lua parity

- The HTML canvas is the **preview**, not an alternate product. Editor sliders outside the 480×800 screen are preview-only experiments.
- Native and browser code have matching book IDs/order, row geometry, tap areas, tab labels, buttons, and display states. `tests/test_preview_parity.py` enforces major invariants and must be updated when the approved design changes.
- Any mockup change must be reproduced in Lua and the package version bumped **in the same PR**. A passing HTML screenshot alone is not a native-app delivery.
- For layout changes, inspect 480×800 captures of Path (initial, active, done), All (longest title), Done (empty and populated), Detail (with/without visual reference, longest title), and Link (empty and populated). Check no text/touch overlap under both normal and enlarged glyph metrics.
- Hardware acceptance is separate: installed-app screenshot alongside HTML, readable font weight, tap on each target (including corner and edge points), screen refresh/ghosting, state persistence and actual EPUB-open action where supported.

## Outstanding risks, verification and next steps

- **Unverified physical device:** real font width, contrast, rounded corner support, native text raster, tap coordinates and EPUB handoff.
- The firmware's system font and the browser's fallback font are not byte- or pixel-identical. We must measure a physical test or package the already-approved Inter bitmap system, then regenerate both renderers from the same font metrics.
- The 33 book entries are stable numeric IDs used in saved progress: append new entries, do not reorder without migration.
- Every update must retain status/linked-reader data after a device reinstall-over, and should not require uninstalling the prior app.

## Review outcome

The v0.2.0 source and preview use the same screen design as verified by the catalog/geometry regression, host Lua tests and browser interaction rendering. Hardware fidelity is **not** yet verified. Existing 11-game UI rules remain authoritative for games; this is the specific app's design owner.
