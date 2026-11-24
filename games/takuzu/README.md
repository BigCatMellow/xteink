# Takuzu

Fill every cell with 0 or 1. Each row and column has equally many zeros and ones. Never place three equal digits in a row. No two rows or columns can be identical. Select 0 or 1, then tap a cell. Tap the same value to clear it.

Native 480×800 monochrome Lua game. Fresh, seeded, validated puzzles (6×6, 8×8, 10×10) from New and on first install. The original 12 boards remain only for legacy saves. Shared Inter/theme/controls, full-width grid, explicit mark modes, undo, help and saved progress. No networking or animation. Level order is a save-format contract.

Run `lua tests/test_procedural.lua` for the generated-session regression and `lua tests/test_game.lua` from this directory and `python3 tests/validate_levels.py` for independent solution counting. Device tests, visual acceptance and human challenge rating remain required before release.
