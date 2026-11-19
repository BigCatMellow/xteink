# Reader fonts

Static Bold instances for the reader's `Fonts/` folder on the SD card (the
firmware loads one static TTF per font, like the other fonts there).

| File | Source | Made with |
| --- | --- | --- |
| `Onest-Bold.ttf` | google/fonts `ofl/onest/Onest[wght].ttf` | `fonttools varLib.instancer --update-name-table wght=700` |
| `Manrope-Bold.ttf` | google/fonts `ofl/manrope/Manrope[wght].ttf` | `fonttools varLib.instancer --update-name-table wght=700` |

Both are SIL Open Font License 1.1 (`*-OFL.txt`). Installed on the card
2026-11-18; copy to `<card>/Fonts/` to reinstall.
