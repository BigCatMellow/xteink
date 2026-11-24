# Lantern Logic — physical X4 Pro test checklist

1. Install the package through All Files and launch it in Ink App on XTOS Licorice.
2. Check the 480×800 portrait board, header, score feedback and bottom controls for clipping.
3. Tap a white cell three times: bulb, X, empty. Each action must redraw **once** with no animation.
4. Tap a black wall or number; nothing should change.
5. Confirm the corner dot shows illumination across open rows and columns, stopping at black walls.
6. Put two bulbs in the same open row. Confirm the conflict message appears and the game does not solve.
7. Verify an adjacent numbered wall becomes satisfied only by its stated bulb count.
8. Test UNDO, RESET, PREV and NEXT. An unsolved new level cannot be skipped.
9. Finish level 1 with a valid configuration; NEXT unlocks level 2.
10. Exit and reopen: the saved bulb positions and unlocked stage survive.
11. Check 7×7 level cells remain readable and tappable. Verify physical page buttons navigate only when allowed.
12. Leave idle: no timer-driven redraws, fades, movement or network dependency.

The app is not hardware-verified until these checks pass.
