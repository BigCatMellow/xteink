# Ray Vault — hidden-atom deduction for XTEINK X4 Pro

An original 6×6 **Black Box-style** logic game for the XTEINK X4 Pro running XTOS Licorice. Completely static, monochrome and offline. Inspired by a traditional deduction mechanic, not a reproduction of any commercial game's art, branding or published level set.

**Version 0.2:** 12 frozen original atom arrangements; 3 atoms on levels 1–6 and 4 on 7–12. Adds illustrated rules, measured layouts and safe resume before submitting an answer.

## Play

The board hides a fixed number of atoms in its 6×6 cells. You do not see them initially. Touch one of 24 circular **edge ports** to fire an invisible ray. Only the result is shown, immediately—there is never a moving beam or animation.

- **H:** the ray hit an atom head-on and was absorbed.
- **R:** the ray reflected and emerged at the same port.
- **Matching numbers:** the ray entered at one numbered port and came out of the other.
- Rays travel straight until atoms one cell diagonally ahead deflect them by 90° away from the atom. A direct hit takes precedence. Two simultaneous diagonal atoms reverse the ray.

Tap an interior cell to cycle **atom guess → X (known empty) → clear**. After marking exactly the stated number of atoms, press **CHECK**. Only an exact correct layout completes a stage. An incorrect attempt leaves all observations visible for further deduction.

**CLEAR** removes guesses but preserves ray observations. **PREV/NEXT** navigate previously unlocked levels. The current probe results and guesses save automatically.

## Difficulty / validation

The Python test independently implements the beam rules. For each authored board, it enumerates **every combination** of 3 or 4 hidden atoms in a 6×6 grid and confirms that the full 24-port signature uniquely identifies the intended layout. Each selected board contains hits, reflections and deflected rays and requires at least three informative probes in a greedy identification analysis.

The Lua tests verify reciprocal ray exits, all 12 winnable stages, input behavior, saving and the static rendering command budget. This is not a guarantee of how difficult the board will feel in real play.

Previous/Next now retain each visited board instead of silently restarting it.
Existing version-1 saves remain readable. Layout and save regressions are checked
by the repository [game quality gate](../docs/GAME_QUALITY.md).

## Installation

1. Open [Ray Vault builds](https://github.com/BigCatMellow/xteink/actions/workflows/ray-vault.yml).
2. Download the latest successful **ray-vault-xtapp** ZIP, extract `ray-vault.xtapp`.
3. Copy it to the microSD card root and install on the reader through **All Files**.
4. Open **Ink App → Ray Vault**.

The app has no network requirements or animation. It does not install new firmware. Physical device testing is still required before declaring compatibility verified.

## Files

- `app/index.lua`: original level set, deterministic beam model, renderer, input and save/restore.
- `app/manifest.json`: Licorice app declaration.
- `tests/test_game.lua`: simulated-device rules and UI acceptance tests.
- `tests/validate_levels.py`: independent all-combinations signature uniqueness verifier.
- `docs/DEVICE_TESTING.md`: on-device acceptance plan.

The ray behavior is documented in [Simon Tatham's Black Box manual](https://www.chiark.greenend.org.uk/~sgtatham/puzzles/doc/blackbox.html). This project uses independently authored layout arrangements and UI.
