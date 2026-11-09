# Line Lift — X4 Pro device acceptance checks

The actual device must be used for these tests; CI alone does not establish on-device operability.

1. Check Settings → About: XTEINK X4 Pro with XTOS Licorice.
2. Install `line-lift.xtapp` from All Files and launch through Ink App.
3. Confirm the complete **480×800 portrait** frame shows a white background, black lines, a level counter and large bottom controls; no colors, ghost shading, or cut-off text.
4. Level 1 starts with a horizontal line **broken at the center** under a continuous vertical line. Tap A (the horizontal's pull circle): the level instantly resets with "SNAG!". **No motion animation** appears.
5. Tap B (the upper vertical's circle): B vanishes in one screen redraw; A becomes a **continuous** line. Tap A and confirm ALL CLEAR.
6. Tap NEXT and verify level 2 appears fully drawn in one refresh.
7. During any level, exit to Ink App and return. The remaining active rods, unlock progress and snag count must be unchanged.
8. Tap the help button; test the static instructions and BACK. The help view must not cause a pull.
9. Use PREV and RESTART; previous progress remains unlocked, and restart restores all rods.
10. Check the tap zones near the left/right/top/bottom board edges. Press each physical page button once; check it does not accidentally remove a rod.
11. Reach level 11. Two rods have **double-ringed** circles with the same letter. Tap either: the pair only disappears when both rods have no active rods above them.
12. Complete level 12, verify the final all-clear text, and check that NEXT does not advance beyond the authored stages.

Record the exact firmware version and a photo of any misplaced label, unreadable crossing gap, missing button press, or crash. Do not call this hardware-verified until the list passes.
