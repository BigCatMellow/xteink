# Margin Codex — original pocket puzzle book (prototype)

A new, original open-ended word/phrase puzzle collection influenced by the **format** of *The Master Theorem* (M): unusual one-page clues, one answer, optional hints, and explanations. No published puzzle, prose, illustration, answer sequence, or other protected content is reproduced.

## Current state (2026-11-11)

- [Interactive standalone HTML prototype](prototype/index.html): sixteen authored puzzle pages, 3 progressive hints per page, answer input/checking, explanation, browser-local progress, and a five-entry paginated book index.
- Browser interaction test completed for all sixteen answers, all 48 hint reveals, paginated navigation, and local progress restoration. Every clue page was checked for content clipping at 480x800; representative screenshots reviewed. Existing v1 saved progress and unfinished answers remain loadable.
- **Not yet a native XTOS Licorice XTApp, Games Hub game, or device-tested package.** The HTML is a temporary design/playtest artifact. Do not stage it in `SD:/Apps/` or present it as firmware-compatible.
- Active game roster, current installers and saved game data remain unchanged.

## Device-first requirements for native implementation

- XTEINK X4 Pro: **480 x 800** monochrome e-ink; never assume a larger viewport.
- One page per puzzle. Keep clue text within a real measured region (no tiny dense illustrations, long scrolling pages, or pinch-to-zoom).
- Puzzle, three hints, answer-entry, and solution are **separate static screens**. The keyboard must never shrink the clue text.
- No animation, timed prompts, sound, network requirements, or use of color/gray as the only meaning.
- Large touch targets (about 48px minimum); hardware page keys should navigate pages with proper debounce.
- Explicit save/resume for puzzle selection, solved states, hints and unfinished answer; retain existing saves during upgrades.
- Use the repository shared Poppins/Inter typography, game UI helpers and theme. Verify font metrics, rectangles, tap targets and bitmap rendering in both normal and enlarged test profiles.
- Add native app to all central registries, hub, app icon system, solver/layout tests, release pipeline. Do not weaken existing quality checks or alter shelved Paper Golf.
- Re-run `python3 scripts/check_games.py`, compatibility and package/icon checks. Host previews are not hardware validation.
- Enforce 32-code-file and 524288-byte Games Hub container limits. At last documented build, the hub was already 31/32 files.

## Puzzle content

The first six authored training puzzles use number-letter substitution, word indexing, acrostics, alphabet shifting, chronological sorting and Morse signals. Ten additional pages use compass-path tracing, missing letters, constrained truth statements, prime-date indexing, transitive ordering, central/outer letters, shared-letter intersections, paired-word indexing and row-column coordinates. All fit one reader-sized clue page. Future content should prioritize surprising rule discovery and puzzle originality over quantity or repetitive decoding.

## Status and next acceptance criteria

The *format trial* is complete; native gameplay remains open. A native release is accepted only after an XTApp package is generated, an original icon is verified, all repository checks pass, progress survives relaunch/level switching, and real-device font/refresh/physical buttons are reviewed. The SD card must be mounted before deployment.
