# Lights Out

Native XTOS Licorice port of the user's HTML prototype (`research/lights-out.html`, PR #29).

- Tap a tile to flip it and its orthogonal neighbours; turn every tile white.
- Four sizes: Classic 5×5, Tall 5×7, Large 6×9, Huge 7×10. Boards are made from random presses, so
  they are always solvable, and need at least 4 presses.
- **Par** is the exact minimum. The solver tries every first-row press set (at most 2^7) and chases
  the lights down. Every solution is fixed by its first row, so this finds all of them without the
  prototype's GF(2) matrix, which would be slow on the reader.
- Screen-first layout as in Sudoku 0.7: the board owns the top 704px, and the bottom bar holds the
  move counter, Undo (Next when solved) and Menu. The menu has new game sizes, Restart, Show hint,
  Show solution (rings on the presses still needed), par and how to play.
- Progress, undo history (100 steps) and the solution setting are saved to `lights-out.txt`.

Tests: `cd games/lights-out && lua tests/test_game.lua`. They check the solver against brute force
on 3×3, the known 15-press all-on 5×5 board, generated boards for every size, touch geometry,
undo, hints to par, menu, saves and damaged saves.
