# Source fonts for the game family

Unmodified source files from the Google Fonts repository:

- [Inter variable](https://github.com/google/fonts/blob/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf), kept here as `Inter.ttf`.
- [Poppins Medium](https://github.com/google/fonts/blob/main/ofl/poppins/Poppins-Medium.ttf).
- [Poppins SemiBold](https://github.com/google/fonts/blob/main/ofl/poppins/Poppins-SemiBold.ttf).

The corresponding `Inter-OFL.txt` and `Poppins-OFL.txt` contain the copyright
notices and SIL Open Font License. The package includes the full notices in
each app's generated `font_license.lua`. Source file hashes are recorded in
`shared/font-metrics.json`.

Run `python3 scripts/make_game_fonts.py` to generate the 1-bit glyph images
and metrics, or `--check` to compare with the checked-in output. The reference
export uses Pillow 10.2.0 and FreeType 2.13.2; the Python 3.12/Pillow 10.2.0
wheel is pinned in the relevant CI workflows to keep glyph masks reproducible.

The Lua app contains generated PNGs and integer metrics, not these TTF files.
