# Quiet Mines — physical-device checks
1. Install from SD:/Apps/; confirm the 6×6, 7×7 and 8×8 field sizes fit the screen.
2. First attempt OPEN on a cell other than S; the game should direct you to S. Opening S must safely reveal a zero region, with one redraw and no animation.
3. Verify numbers correspond to mines in eight surrounding cells.
4. Toggle FLAG/OPEN; flags should never accidentally reveal mines.
5. Exit and reopen while partially revealing a field; flags and opened cells persist. UNDO restores a safe action.
6. Open a mine in a later field; lose, display the mines, and require RESET before retry.
7. Reveal all safe squares; NEXT unlocks. Returning to an incomplete earlier field should not reset it.
8. Check help, tiny numbers in 8×8 cells, physical buttons and sleep/wake.
9. No timer or periodic refresh.
