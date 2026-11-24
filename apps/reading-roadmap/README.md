# Reading Roadmap — XTEINK X4 Pro

A standalone, offline Lua InkApp for the X4 Pro on XTOS Licorice (480 × 800 pixels).
The book order is the **211-book quality-first path** of books already on the card ([data/quality-first-211.md](data/quality-first-211.md)), 20 of them optional rereads.

## Reading list data

See **[data/README.md](data/README.md)** for the user-curated path, its **62 optional series continuations** (not in the app), the **65-group duplicate audit**, and the wishlist. The app's copy of the list is generated from the JSON; never edit it by hand:

    python3 apps/reading-roadmap/tools/build_catalog.py --write     # after changing data/quality-first-211.json

CI fails if the app copy is stale. Each entry carries its card path, so the app knows every listed file is on the card and where. `data/reader-titles.json` holds each file's own metadata title (what the stock reader shows); when that is junk (`Microsoft Word - …`, author in the title field) and unique on the card, it is baked in as a match alias.

## Interactive HTML mockup (native layout review)

The authoritative app-specific decisions are in [DESIGN.md](DESIGN.md). They adapt the existing design rules from `docs/GAME_DESIGN.md` and the Design Bible's hierarchy, typography, spacing, and interaction guidance.

Open `preview.html` in any browser. It uses a fixed **480 × 800 canvas** with the same 211-book catalogue, fixed screen coordinates, button areas, labels, navigation and reading-status transitions as the native Lua InkApp.

The preview simulates direct opening when you tap a book row; a separate INFO area opens book details. Native book launch is still subject to firmware support. The outside-of-device panel supports selecting screens, simulating already-opened books, and experimenting with text sizes / line weight. Experiments are explicitly marked **unsynced**: use **Copy changes for native app**, then apply those parameters to Lua before building another .xtapp. Browser text rasterization is not proof of exact XTOS native font metrics: compare a physical device photo before claiming pixel-perfect typography.

Run `python apps/reading-roadmap/tests/test_preview_parity.py` to catch catalogue and critical layout drift. The package CI also runs this check. Do not change one surface without updating and verifying the other.

## Features

- CHECK: automatically match all 211 titles against Bookshelf's **previously opened books** index and the baked-in **card paths**, and list complications with remedies, fixable ones first: LINK CHANGED, MULTIPLE (several editions; picker lists them first, most recently read on top), CHECK TITLE (similar title), NOT OPENED YET (shows its folder), NO ACCESS.
- Matching ignores series tags (`[Murderbot Diaries 01] …`), subtitles (`The Martian: A Novel`), edition notes and file-name style titles (`True Grit - Charles Portis`). A different known author vetoes a match (*The Martian Chronicles* is not Weir's); similar titles must share leading words (*In the Woods* is not *A Walk in the Woods*). Title/author swapped in the metadata still matches; among several exact matches a whole-title match wins (*Dune* over *Dune: House Atreides*).
- PATH: all 211 books in order, opening on the page with the book up next (a book in progress, else the first unread one; optional rereads are labelled and skipped for "Up next").
- DONE: books marked as finished.
- **Tap a book row to read** (when linked to a book the reader knows), or go straight to linking if a book must be matched first.
- Tap **INFO** on the right for the optional recommendation, status and link controls.
- Each book has a short reason to read it and a movie/TV/game visual reference when appropriate.
- Tick the box on any row to mark a book read (tap again to undo); the header shows `N / 211 read` with a progress bar. INFO has an explicit TO READ / READING / FINISHED choice. A book the reader shows progress for displays as reading (`43% read`) without overwriting your choice. Status is saved in the app sandbox (XTApps/readingpath/files/progress.txt).
- LINK BOOK selects a book (EPUB or MOBI) that was already opened in the stock Bookshelf, showing its reading percentage where available.
- OPEN BOOK attempts a supported reader launch on a deliberate tap. It remains unverified on hardware, with a Bookshelf fallback.

## Actual platform and limitations

The X4 Pro runs an ESP32-S3-based XTOS Licorice e-reader firmware, not Android. InkApps use Lua with the native InkApp API, and are packaged as .xtapp. An Android APK or browser-based HTML file is not the correct app format.

The reader API gives book IDs and statistics for books that have already been opened; it does not give EPUB file paths or a directory listing of all SD-card ebooks. **NOT OPENED YET does not mean missing from SD.** Open that book once in Bookshelf, then tap CHECK to rescan. Unique exact title matches link automatically; duplicates and similar titles require human review. Earlier builds could not launch a stock EPUB from a mini app. Firmware 26110501 announced new "open files or books in the reader" API capabilities, but the public signatures have not been confirmed. This app probes the available calls conservatively and explains the fallback when it cannot open a book. The app never claims a book was opened if the host did not confirm the request. Unlinked books show a single **LINK BOOK** action; the **OPEN BOOK** button appears only after the book has been matched to a reader record.

This app ships no copyrighted books, downloads no books, changes no reader positions, and does not alter firmware.

## Why a book may need opening in Bookshelf once

Mini apps cannot list the SD card: their files are sandboxed to `/AppFiles/<app id>` (the card's
`XTApps/<id>/files/`). The reader's API (`ctx.reader:all_books()`) lists only books the reader has
opened. So the app knows where every listed book is (the card list baked from
`directory-tree.md`), but not the reader's ID for a book it has never opened.

From 0.6.1, tapping such a book first asks the reader whether it can open the file by its card
path (`ctx.system:can_open`, a yes/no question, with `{type='file', path='/Books/…'}` and similar
shapes). If the firmware accepts one, the book opens directly. Otherwise the app says which
Bookshelf folder to open it from once. On first launch the app writes `open-probe.txt` (in
`XTApps/readingpath/files/`) with the reader's answer to each request shape, so the working
one can be confirmed from the card.

**Back:** the button at the top left of the main screens closes the app through `ctx:quit()`
where the reader offers it (otherwise it says to use the Back key). The Back key closes details or
the picker, takes DONE and CHECK back to the path, and on the path is left to the reader, which
asks whether to exit.

## Installing

1. Verify your X4 Pro runs XTOS Licorice (not Android or alternate firmware).
2. Obtain the Reading Roadmap CI artifact, or build the package with the pinned community packer.
3. Place the resulting reading-roadmap.xtapp installer into SD:/Apps/ via USB.
4. On the device go to All Files > Apps > reading-roadmap.xtapp > Install.
5. Launch Reading Roadmap from the Ink App area.

Install updates over the existing app; don't uninstall just to update, because that can remove its private progress data.

If tapping a book cannot launch its EPUB, open it once in Bookshelf, then return and tap its row again. Books that have not been matched offer the link picker if the firmware reports existing books. The progress tracker itself works without book launching.

## Card checks and duplicate cleanup

The reader API only reports books that have been opened, so the app relies on the paths in the list. After adding, moving or removing books, confirm every listed file is still there:

    python3 apps/reading-roadmap/tools/card_from_tree.py /media/<card>/Books/directory-tree.md

With the card mounted, `--card /media/<card> --titles-json apps/reading-roadmap/data/reader-titles.json` refreshes the metadata titles (then run `build_catalog.py --write`), and `--predict /tmp/card.lua` plus `lua apps/reading-roadmap/tests/predict.lua /tmp/card.lua` shows the CHECK screen the app would give if every book had been opened once. On the current card (after duplicate cleanup and the metadata fix below): 211 / 211 linked automatically, 0 issues. Before: 168 / 211.

To remove the duplicates in [data/duplicate-audit.md](data/duplicate-audit.md) (keep one EPUB per book, take duplicate MOBIs and extra EPUBs off the card):

    python3 apps/reading-roadmap/tools/dedupe_card.py --card /media/<card>            # dry run: the plan
    python3 apps/reading-roadmap/tools/dedupe_card.py --card /media/<card> --apply    # do it

It never removes a reading-list file, checks that the kept EPUB opens and has no DRM, skips groups without an EPUB and unconfirmed "verify manually" groups, and never touches omnibus files. Removed files are copied to `~/xteink-research/card-dedupe-backup/DATE/` and verified before deletion, with `restore.sh` to undo and a fresh `directory-tree.md`. Planned on the current tree: 62 groups, 65 files; left alone: The Great Gatsby (unconfirmed), *Philosophy: The Classics* (MOBI+PDF) and *House Atreides* (two MOBIs).

Some EPUBs carry placeholder metadata (`<dc:title>none</dc:title>`), so the reader reports them as "none" and the app cannot tell them apart. `tools/fix_metadata.py --card /media/<card>` lists the reading-list files affected (dry run; `--apply` fixes them, `--all` includes the rest of the library). It sets the title from the list (or the file name), the author from the file name, and a per-file identifier when it was a placeholder; nothing else in the file changes. Originals go to `~/xteink-research/metadata-fix-backup/DATE/` with `restore.sh`. Applied 2026-11-23 to the 13 listed books.

## Testing from the repository root

1. lua5.4 apps/reading-roadmap/tests/test_app.lua
1. python apps/reading-roadmap/tools/build_catalog.py (app copy of the list is current)
1. python apps/reading-roadmap/tests/test_match_parity.py (Lua, preview JS and card tool agree on every matching case)
2. python apps/reading-roadmap/make_icon.py
3. python /path/to/touch-licorice-apps/tools/lualint55.py apps/reading-roadmap/app/index.lua
4. python /path/to/touch-licorice-apps/xtpack.py apps/reading-roadmap/app -o dist/reading-roadmap.xtapp

The GitHub workflow packages the installable app with a pinned packer and runs host checks. CI cannot prove e-ink rendering or book opening on a physical X4 Pro.

## Progress format and migrations

Progress is saved by **title key** (`#roadmap2`: `key<TAB>status<TAB>reader id`), never by position, so the list can be reordered or replaced without moving progress onto another book. Rows for books no longer in the list are kept as they are. Saves from 0.4/0.5 (`#roadmap1`, positional) migrate on first launch: the five books that carried over (All Systems Red, True Grit, The Martian, The Princess Bride, The Hobbit) keep their status and link; the other 28 are kept as `v1:N` rows.

For on-device validation, link one book already opened in Bookshelf, tap OPEN BOOK, and check whether the correct book opens. Record the exact firmware build and outcome. No existing books, saves, or unrelated apps should be removed.
