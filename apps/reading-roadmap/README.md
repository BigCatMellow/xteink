# Reading Roadmap — XTEINK X4 Pro

A standalone, offline Lua InkApp for the X4 Pro on XTOS Licorice (480 × 800 pixels).
The book order comes from the November 2026 reading list: nine primary books and 24 additional titles.

## Interactive HTML mockup (native layout review)

The authoritative app-specific decisions are in [DESIGN.md](DESIGN.md). They adapt the existing design rules from `docs/GAME_DESIGN.md` and the Design Bible's hierarchy, typography, spacing, and interaction guidance.

Open `preview.html` in any browser. It uses a fixed **480 × 800 canvas** with the same 33-book catalogue, fixed screen coordinates, button areas, labels, navigation and reading-status transitions as the native Lua InkApp.

The outside-of-device panel supports selecting screens, simulating already-opened EPUBs, and experimenting with text sizes / line weight. Experiments are explicitly marked **unsynced**: use **Copy changes for native app**, then apply those parameters to Lua before building another .xtapp. Browser text rasterization is not proof of exact XTOS native font metrics: compare a physical device photo before claiming pixel-perfect typography.

Run `python apps/reading-roadmap/tests/test_preview_parity.py` to catch catalogue and critical layout drift. The package CI also runs this check. Do not change one surface without updating and verifying the other.

## Features

- PATH: the nine-book recommended order, starting with A Knight of the Seven Kingdoms, All Systems Red, and The Thin Man.
- ALL: the full 33-title collection across fantasy, science fiction, mystery, classics and nonfiction.
- DONE: books marked as finished.
- Each book has a short reason to read it and a movie/TV/game visual reference when appropriate.
- START and FINISHED save status inside the app sandbox (XTApps/readingpath/files/progress.txt).
- LINK BOOK selects an EPUB that was already opened in the stock Bookshelf, showing its reading percentage where available.
- OPEN BOOK attempts a supported reader launch on a deliberate tap. It remains unverified on hardware, with a Bookshelf fallback.

## Actual platform and limitations

The X4 Pro runs an ESP32-S3-based XTOS Licorice e-reader firmware, not Android. InkApps use Lua with the native InkApp API, and are packaged as .xtapp. An Android APK or browser-based HTML file is not the correct app format.

The reader API gives book IDs and statistics for books that have already been opened; it does not give EPUB file paths. Earlier builds could not launch a stock EPUB from a mini app. Firmware 26110501 announced new "open files or books in the reader" API capabilities, but the public signatures have not been confirmed. This app probes the available calls conservatively and explains the fallback when it cannot open a book. The app never claims a book was opened if the host did not confirm the request.

This app ships no copyrighted books, downloads no books, changes no reader positions, and does not alter firmware.

## Installing

1. Verify your X4 Pro runs XTOS Licorice (not Android or alternate firmware).
2. Obtain the Reading Roadmap CI artifact, or build the package with the pinned community packer.
3. Place the resulting reading-roadmap.xtapp installer into SD:/Apps/ via USB.
4. On the device go to All Files > Apps > reading-roadmap.xtapp > Install.
5. Launch Reading Roadmap from the Ink App area.

Install updates over the existing app; don't uninstall just to update, because that can remove its private progress data.

If the OPEN BOOK button cannot launch an EPUB, open it once in Bookshelf, then return and use LINK BOOK. The progress tracker itself works without book launching.

## Testing from the repository root

1. lua5.4 apps/reading-roadmap/tests/test_app.lua
2. python apps/reading-roadmap/make_icon.py
3. python /path/to/touch-licorice-apps/tools/lualint55.py apps/reading-roadmap/app/index.lua
4. python /path/to/touch-licorice-apps/xtpack.py apps/reading-roadmap/app -o dist/reading-roadmap.xtapp

The GitHub workflow packages the installable app with a pinned packer and runs host checks. CI cannot prove e-ink rendering or book opening on a physical X4 Pro.

## Progress format and migrations

The list uses stable, numbered entries inside app/index.lua. Saved statuses are by book number. Append new books to preserve existing progress. Reordering existing numbers requires a save-file migration; do not silently shuffle them.

For on-device validation, link one EPUB already opened in Bookshelf, tap OPEN BOOK, and check whether the correct book opens. Record the exact firmware build and outcome. No existing books, saves, or unrelated apps should be removed.
