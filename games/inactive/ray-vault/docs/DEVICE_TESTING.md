# Ray Vault — physical X4 Pro acceptance checks

1. Install `ray-vault.xtapp` through All Files, launch from Ink App.
2. Verify the complete static 480×800 display: title, 6×6 grid, 24 rim ports and controls.
3. Tap a port once. It must show H, R, or a number **without animation**. A numbered detour should display the same number at the exit port immediately.
4. Tap a previously revealed port. No probe should be counted again or trigger redundant redraws.
5. Tap an interior cell three times: atom guess, X, clear.
6. CHECK with too few guessed atoms must show instruction, not reveal the secret.
7. CHECK a wrong arrangement of exactly 3 or 4 atoms; it must remain editable without revealing the answer.
8. CLEAR should reset atom guesses but **keep all probe results**.
9. Complete a level and confirm NEXT unlocks. PREV should revisit cleared levels.
10. Quit and reopen; marks, prior ray readings and unlocked progress must survive.
11. Verify the ring labels are legible at 480×800 and all four edges are tappable.
12. Press the physical page buttons, which navigate only and never fire rays.
13. Leave idle. There must be no periodic redraw, frame loop, animation, or sound.

A passed CI build does not replace these hardware checks.
