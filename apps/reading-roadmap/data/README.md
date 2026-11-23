# Reading Roadmap planning data

These are **reference datasets**, not yet the runtime catalogue for the X4 Pro. The current Lua InkApp and HTML preview still embed the earlier **33-book** recommendation set. Do not claim that the 211-book route is installed on the device.

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

## Integrating later into Lua + HTML

**Do not paste the 211 entries into the runtime list without a save migration.** The current app saves progress against positional IDs for its original 33 titles. Reordering those IDs would misassign progress.

A later integration should use stable, title-and-edition aware identifiers, migrate existing statuses by original entry, preserve the linked reader ID where verified, update both the Lua app and `preview.html` in the same change, and extend the parity tests. The JSON relative paths are identifiers from a directory listing, **not confirmed readable files or public download URLs**. Any direct-reader launch still requires a physical-device verification.

Nothing here alters ebook files, removes duplicates, changes the installed application or purchases books.
