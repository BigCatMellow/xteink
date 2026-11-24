# Hitori

Shade repeated numbers until each row and column contains no repeated unshaded number. Shaded cells cannot share an edge. All unshaded cells must connect through their edges. Select Shade or Keep, then tap cells. Mark every square, then Check.

Native 480×800 monochrome Lua game. 12 fixed original boards (5×5, 6×6, 7×7, 8×8). Shared Inter/theme/controls, full-width grid, explicit mark modes, undo, help and saved progress. No networking or animation. Level order is a save-format contract.

Run `lua tests/test_game.lua` from this directory and `python3 tests/validate_levels.py` for independent solution counting. Device tests, visual acceptance and human challenge rating remain required before release.
