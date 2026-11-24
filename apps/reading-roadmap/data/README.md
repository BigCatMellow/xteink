# Reading Roadmap planning data

`quality-first-211.json` is now the **runtime catalogue** (since app 0.6.0): `tools/build_catalog.py --write` bakes it into the Lua app and HTML preview, and CI fails if that copy is stale. The other files are reference data. `duplicate-audit.json` drives `tools/dedupe_card.py`.

## Source and intended meaning

- **Source of ownership evidence:** `directory-tree(6).md`, a user-supplied directory tree with **693 files** (not the ebooks themselves). Last reviewed 2026-11-23.
- **Main path:** `quality-first-211.md` and `quality-first-211.json`. **211** distinct reading choices with real relative paths in the inventory (**157 EPUB / 54 MOBI**). Includes **20 optional reread opportunities**. An additional **62** previously selected series continuations are deliberately not mandatory; they remain documented as optional in the JSON.
- **Duplicates:** `duplicate-audit.md` and `duplicate-audit.json`. **65 candidate groups** representing **68 extra file entries** relative to one per title, including **two uncertain groups**. The JSON also notes **six potential omnibus/collection overlaps**. These are filename-level candidates; do not delete an edition without checking its contents, translation, and DRM.
- **Missing recommendations:** `wishlist-missing-from-original-33.md` and `wishlist-missing-from-original-33.json`. **26 titles** from the *earlier 33-book recommendation list* are not identified by filename; **seven** are identified as owned. This is a **wishlist, not required shopping** and not a list of gaps in the 211-book path.

## Reading philosophy

- Prefer the most promising individual books, **not entire series for their own sake**. Preserve the optional series-continuation notes.
- Include known favorites as **optional rereads**. Do not silently mark them completed or discard them.
- Interleave genres and short/long works; series publication order still matters when a sequel is selected.
- A missing filename is **not proof that an ebook is absent** from the SD card or from the user's other stores.
- MOBI entries are **owned**, not purchases. The device may need EPUB conversion; no conversion has been performed.
- The native reader's opened-books API does **not** scan every file on the SD card; that limitation must remain visible if these datasets become active.

## How the app uses it

- Progress is keyed by title, so reordering or replacing entries keeps it. Saves from the 33-book app migrate automatically (see the app README).
- Each `relative_path` tells the app where the book is on the card. Re-check after card changes with `tools/card_from_tree.py`.
- `reader-titles.json` (generated from the card) supplies match aliases for files with junk metadata titles.
- Optional continuations and the wishlist are not shown in the app.
- Direct reader launch still requires physical-device verification.

Nothing here alters ebook files or purchases books. Duplicate removal only happens when you run `tools/dedupe_card.py --apply`, which backs up every file first.
