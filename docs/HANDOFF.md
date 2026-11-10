# Project handoff — 2026-11-10

## Closing this chat / resume here

- Handoff ID: `XT-HO-20261110-session-close`; status: **OPEN / ready for the next session**.
- Repository: `/home/mellow/xteink`, `BigCatMellow/xteink`, branch `main`.
- Reviewed source state: `d2c3e82` (shell 0.4.0), `2f18e80` (expanded next steps).
- No uncommitted work was present at this closing check. The previously local
  locked-unit THINK note was saved by `2c71db3`; do not treat it as lost or pending.
- Receiving session: read `AGENTS.md`, this handoff, then
  [shell design](../shell/docs/DESIGN.md) and [current state](../shell/docs/STATE.md).
  Older roadmap/probe/review records preserve historical evidence; the 0.4.0
  disposition below supersedes the separate-shell proposal for production.
- Next real work: stage the archived 0.4.0 candidate when the card is available,
  perform its one-time permission/API installation, then record the device checks.
  This closeout establishes no installation, rendering or sleep success.
- Next session should acknowledge this handoff here, change status to CONTINUED
  with a durable work/evidence link when work resumes, and close it when the
  follow-up is completed or superseded. No hidden chat is needed.

### User intent and operating method

The user wants autonomous coordination with helpers, consistent games and an
SD-card shell using stock Licorice services, without repeated per-game decisions
or manual updates. Default coordinator/research/PLAN: Sol high; architecture and
independent challenge: Astra high; bounded implementation: Terra medium, higher
effort for save/recovery complexity; clerical indexing: Luna medium/low. Use
available capabilities, record substitutions and retain independent review.
The probe review records the Astra usage-limit interruption and Sol completion.

[Model routing and roadmap](../shell/docs/ROADMAP.md),
[MAPS_Lean protocol index](../shell/docs/protocols/INDEX.md),
[method application](../shell/docs/protocols/APPLICATION.md) and
[pinned method research](../shell/docs/research/maps-method.md) preserve THINK,
PLAN, HPOM, spiderweb, emergence/insight and indexing/lifecycle decisions.
These are applied methods, not a claim that the full MAPS runtime was installed.

Game work retains canonical Poppins/Inter typography, deliberate spacing and
strong semantic boundaries. [Design reasons](GAME_DESIGN.md),
[complete rollout](GAME_ROLLOUT_PLAN.md), [visual comparisons](design/full-rollout-2026-11-08/README.md)
and [update procedure](GAME_UPDATES.md) own those details. Preserve stable IDs,
generated puzzle seeds, unfinished boards, undo and valid saves. Paper Golf is
shelved; stock Sudoku/Dictionary and wallpaper remain separate.

## Repository organization

Closing verification, 2026-11-10: `python3 scripts/check_games.py` passed all
17 games. All 18 entries in `game-family-latest.json` match both their archived
package SHA-256 and current app source fingerprints. Closing navigation links
and whitespace checks passed. No SD write or physical test occurred in this
closeout; the usual card mount was unavailable at the check.

Exact Hub candidate: [0.4.0 installer](../releases/games-hub-0.4.0.xtapp),
401,312 bytes, SHA-256
`4cf571f84b737a8abea416b786c32dc845b1dfe77a7573b7a0bf5fe559aef867`.
Its [metadata](../releases/games-hub-0.4.0.json) records `device_tested: false`.

Games and Games Hub now live under `games/`; the shell project owns its docs,
tools and tests under `shell/`. Start at the root README or
[layout guide](REPOSITORY_LAYOUT.md). This source-layout change preserves app
payloads and release identities and requires no SD updates.

## Shell 0.4.0 (Games Hub) — latest, 2026-11-10

**Status:** built, tested and pushed (`d2c3e82`); all CI green. **Not on the
reader yet** — the SD card was not mounted.

### Constraints (do not revisit)

- The unit is locked: no firmware dump, flashing, esptool, web flasher or lock
  bypass. The shell is a stock-installed app.
- User reports that sleep, including a long power press, returns to the open app. So the shell is
  opened once and stays on screen; games run inside it.
- Never publish `dist/games-hub-personal.xtapp`. Paper Golf stays shelved.
  Installers go in `SD:/Apps/`. Preserve saves.

### What 0.4.0 is

- Home in the user's CrossPoint layout (`BigCatMellow/crosspoint-reader`
  `index.html`): current book card (title, author, % read, streak, minutes
  today, "Continue in the reader") and a resume-last-game card.
- Bottom tabs: Library (books with progress, display-only), Games (all 17),
  Settings (Screen portrait/landscape, About).
- Games force portrait and restore the shell orientation on return.
- Reopens where left (`shell.txt`: screen + orientation, including an open game).
- Reading is display-only because `ctx.system.open` has no documented targets.
- Code: `games/games-hub/src/shell.lua` (screens), `index.lua` (hosting, state,
  rotation). Decisions: [shell design](../shell/docs/DESIGN.md). Previews:
  [docs/design/games-hub](design/games-hub/) (host renders, not photos;
  regenerate with `python3 scripts/render_game_hub.py`).
- Manifest: version 0.4.0, API 2.18, permission `reader`. 31/32 code files,
  399,213/524,288 bytes. Hub suite: 292 frames, Lua 5.4 and 5.1.
- Release: `releases/games-hub-0.4.0.xtapp`,
  `releases/game-family-20261109-111321.*`. The 17 games are unchanged.
- Updater change: a changed API/permission/lockscreen now skips that app as
  `firmware_install_required` instead of aborting the whole update.

### Next steps

1. Mount the card (usually `/media/mellow/4A21-0000`) and run
   `python3 scripts/release_games.py --card <mount>` (or `--apply-only`). It
   will skip the Hub as `firmware_install_required`; check that
   `Apps/games-hub.xtapp` is the 0.4.0 package.
2. On the reader: All Files → `Apps/games-hub.xtapp` → install over the existing
   Games Hub (one time, to approve API 2.18 + reading access). Saves are kept.
3. Device checks:
   - progress kept after the install, and reading access granted;
   - which way `landscape` turns versus the user's grip (base of the device on
     the left) — only `portrait`/`landscape` are known values; if it is upside
     down, research a flip option;
   - taps land correctly in landscape;
   - Home/Library reading data matches the stock reader;
   - sleep/wake on Home, Library and inside a game; landscape shell ↔ portrait game;
   - accented titles (fall back to the native font); e-ink refresh of 1px rules.
4. Record results in `shell/docs/DESIGN.md` (Device checks) and
   `shell/docs/STATE.md` (I1).

### Open ideas, not started

- Open a book from the shell, if a `system.open` target is ever found.
- A header clock is deliberately absent (no timed redraw on e-ink).

## Shell research and planning

The separate [shell project index](../shell/docs/README.md) owns the new research and
OS planning work. Follow [current state](../shell/docs/STATE.md) and its canonical
roadmap for startup, native navigation, return paths and USB updates. MAPS_Lean
methods and helper model/effort assignments are recorded there. The subsequent
[probe wave](../shell/docs/probes/README.md) supplies a frozen contract, separate host
diagnostic, package builder and capture harness. No shell installation or new
physical result is implied; see its host receipt and independent review.

## Complete 17-game rollout — historical delivery, 2026-11-08

The user requested a complete pass without per-game review/install back-and-forth.
Fetched and merged upstream `2a6af10`, preserving prior local work in a checkpoint
and full host backup. Crown Fields, Ten Pairs, Quiet Mines and Sum Cross are now
part of the canonical family, Games Hub, icon export, render fixtures and checks.
Paper Golf remains shelved; stock Sudoku, Dictionary and unrelated apps stay intact.

Every game has a documented layout/icon review and a versioned release. Larger
boards and clearer boundaries replace wasted space where appropriate; already
sound Nonogram clue centering and Oddity shelf hitboxes are preserved. Fixed
pixel strokes, responsive number-sheet rows and stronger glyphs are owned by
the shared UI. Final review corrected Kakuro clue diagonal orientation and
recentered Ray Vault marks. Target-name chips now preserve the full UMBRELLA label, with a regression. [Rollout plan](GAME_ROLLOUT_PLAN.md),
[design decisions](GAME_DESIGN.md), [visual review](design/full-rollout-2026-11-08/README.md).

Versions at that delivery (Games Hub 0.4.0 above is the current package):

| Game | Version |
| --- | --- |
| Line Lift | 0.6.0 |
| Summit Putt | 0.6.0 |
| Link Grid | 0.4.0 |
| Ink Runes | 0.4.0 |
| Lantern Logic | 0.4.0 |
| Ray Vault | 0.4.1 |
| Island Links | 0.4.0 |
| Oddity Hunt | 0.3.1 |
| Word Hunt | 0.4.0 |
| Nonogram | 0.6.0 |
| Word Bridge | 0.3.0 |
| Rectangle Rooms | 0.3.0 |
| Sudoku | 0.3.2 |
| Crown Fields | 0.2.0 |
| Ten Pairs | 0.2.0 |
| Quiet Mines | 0.2.0 |
| Sum Cross | 0.2.1 |
| Games Hub | 0.3.3 |

The full gate passed all 17 standalone and bundled suites, independent solvers,
Lua compatibility and native icons. Bitmap suites audit 3,904 frames total,
peak 589 commands, all images released. Hub navigation/import/error checks audit
165 frames and release all 26,307 decoded font images. Code container is 383,525
bytes, 30/32 code files. Five menu rows per page and stable-ID resumes preserve
older numeric resumes. Builder coverage asserts prevent missing new games.

`python3 scripts/release_games.py --card <mount>` now exports/syncs shared assets,
verifies/builds every game, archives immutable packages and the latest catalogue,
backs up the card, directly updates existing apps/Hub and verifies all app data.
`--apply-only` deploys the verified current sources. A changed source fingerprint
requires a version bump; a change during verification stops the release.

**Applied to the live card:** all 13 existing standalone games and Games Hub
were updated directly. All 326 app-data files remain byte-identical, including
existing progress and unrelated apps. All 346 installed files were verified;
all 18 recovery installers in Apps/ were refreshed. New games are playable
inside the updated Hub without separate standalone registration. Do not tell
the user to install all packages individually.

Backups: `/home/mellow/Backups/xteink-family-update-20261108-112417/` (main
rollout) and `/home/mellow/Backups/xteink-family-update-20261108-113525/`
(Ray/Hub correction); target-label and pencil-note corrections are also recorded
in dated SD receipts. The final backup is
`/home/mellow/Backups/xteink-family-update-20261108-120133/`.
Dated deployment receipts and the latest 17-game
release catalogue are in releases/. Public packages have no personal save data.

**Next physical check:** safely eject, open existing icons and the Hub, confirm
new versions/layouts and preserved progress. Check all four new games inside
Hub, repeated switching, sleep/resume and real e-ink/font behavior. Filesystem
replacement is verified; no physical launch/refresh success is claimed yet.
The older wallpaper sleep test remains separate and outstanding.

The full rollout is published on main after merging the upstream new games.
CI exposed a Lua 5.4/5.5 pencil-note serialization difference: numeric masks
could be written as `511.0` and rejected on reload. Sudoku 0.3.2 / Hub 0.3.3
write canonical integers and recover old exact-integral decimal note/history
records. Regressions preserve notes, selection, mode and undo across migration;
the fix passes both Lua 5.1 and 5.4. The complete release also runs on Lua 5.4
with the Lua 5.5 compatibility linter. Earlier sections below record historical
deliveries and their limitations.

## Sudoku v0.3 / Games Hub v0.2 — latest change

User supplied photos comparing stock Sudoku with ours. Their preference is
the stock game's use of space, clear 3×3 box boundaries and more legible icon,
while retaining our existing Poppins/Inter and rounded-control style. v0.2
rendered physically, but its separators were inadequate; that photo is not
evidence the new version works on-device.

Implemented a 468×468 board at (6,108), up from 414px (about 28% more area).
Four-pixel solid box/outer bars contrast with one-pixel cell edges independently
of line-width support. Bold Poppins fixed clues replace per-given boxes.
Numbers use a 3×3 keypad beside Notes/Undo/Erase; every digit target is 98×52px.
New and explicit Check move into the header, with puzzle/difficulty metadata
and bounded live status. Rules stay in Help. Number keys/givens use the new
canonical `strong` role, an alias for the existing heading face: no new font
images or font data. UI.button has an optional font role; all copies are synced.
Other games' default typography/behavior are unchanged by the additive API.

The Sudoku icon now uses rounded grid artwork and actual Poppins numerals,
including an emphasized center cell. Icon SVG text uses the shipped fonts,
rendered by `make_icons.py`; packaged native icon pixels are verified. The
small white numeral is baked into the icon PNG, not runtime reversed text.

Versions: standalone Sudoku 0.3.0 and Games Hub 0.2.0 (generated with Sudoku
0.3.0). Generators, seed numbering, app IDs and save formats are unchanged.
Public packages/metadata are archived in `releases/`; `game-family-latest.json`
now references Sudoku 0.3.0 and is the direct updater's default catalogue.
The previous dated release manifests and artifacts remain historical.

Validation: full 13-game quality gate passed with native/enlarged and bitmap
gameplay suites, Lua compatibility, packaging and icon verification. Sudoku
audits 35 bitmap frames with max 325 draw commands and no image leaks, both
standalone and bundled. Regressions cover solid separator geometry, all 81 cell
targets and all nine digit targets. `render_sudoku.py` also checks the actual
raster output has continuous 4px box bars. Notes/cleanup/undo, saved puzzle
visits, unsubmitted answers, help/menu/solved states and large counters pass.

See [before/after](design/sudoku-2026-11-08/before-after.png),
[eight-state sheet](design/sudoku-2026-11-08/states.png), and the updated
[design decisions](GAME_DESIGN.md). Source is still local/uncommitted/unpushed.

**Deployed directly on 2026-11-08:** after the user remounted the SD card,
replaced installed `sudoku/app.xtapp` (0.2.0 → 0.3.0) and `gameshub/app.xtapp`
(0.1.0 → 0.2.0). The other 12 standalone games were already current. Hub import
was complete before replacement. All 346 installed files were checksum-checked:
only those two packages changed; all 326 app-data files and all unrelated apps,
including stock Sudoku, are byte-identical. The two Apps/ recovery installers
were also refreshed. Writes were flushed and readback-verified.

Host backup: `/home/mellow/Backups/xteink-sudoku-hub-direct-20261108-104456/`.
It contains both complete previous installed-app directories, previous recovery
installers, before-inventory, plans and receipt. Public deployment receipt:
`releases/sudoku-hub-sd-update-2026-11-08.json`.

**Next physical check:** safely eject, open the existing Sudoku icon without
installing a package, and verify the larger board, solid box boundaries, bold
givens, new keypad/icon and saved progress. Also check Sudoku inside Games Hub
and sleep/resume. Direct replacement is confirmed on the SD filesystem; reader
launch/metadata refresh is still unverified. Paper Golf remains shelved.

## Update workflow correction — latest request

User clarified that when we place game updates on the SD card, the installed
games should be updated too, without per-game Install actions. The original
Games Hub delivery did not meet that requirement; its earlier description
below is historical, not the user's accepted automatic-update workflow.

Added [direct USB updater and procedure](GAME_UPDATES.md):
`scripts/update_installed_games.py`. It validates a release catalogue, backs up
existing apps, replaces only their app.xtapp packages, verifies other files and
attempts rollback on failure. It supports standalone-game catalogues and a
Games Hub release catalogue; it does not register absent apps. Six regressions
passed, plus an actual-backup/fake-card run updating 10 packages with all 18
save files identical. The full quality gate includes updater regressions.

The first direct SD deployment is now recorded above. The reader still needs
to launch the replaced packages to confirm firmware behavior. Do not silently
fall back to staging installers and claim a direct update is complete.

## Games Hub — latest delivery

User approved one app to update the whole game collection. **Games Hub v0.1.0**
contains all 13 active games, a Poppins/Inter selection menu, Resume action and
a nine-dot header button to save/return to the list. It uses app ID `gameshub`.
Install `Apps/games-hub.xtapp` once through All Files, then open Games Hub.
Future collection updates install over this one app. This still uses firmware
installation confirmation; no automatic/background updater was promised.

The mounted card at `/media/mellow/4A21-0000` now has that installer, flushed
and checksum-verified. It is a **private package** containing copies of 18
existing game-save files for first-launch import. Backup and private receipt:
`/home/mellow/Backups/xteink-hub-final-20261107/`. All 18 original save files
were verified unchanged after staging. The importer writes only missing files
inside the hub's own sandbox, verifies them and marks a receipt; existing hub
progress wins. Missing/corrupt import data blocks launch with a Retry action.
Standalone games and hub games have separate progress after importing.

The private installer lives in ignored `dist/games-hub-personal.xtapp`; never
publish it. The public release is `releases/games-hub-0.1.0.xtapp`, containing
no user data. Public metadata/checksums and the SD copy receipt are in
`releases/games-hub-0.1.0.json`, `SHA256SUMS`, and `games-hub-sd-copy.json`.
Source changes are local and remain uncommitted/unpushed.

Maintenance: [hub README](../games/games-hub/README.md),
[design rationale](GAME_DESIGN.md), [host previews](design/games-hub/overview.png).
Edit source games/shared helpers, then run `scripts/build_game_hub.py`.
Generated game modules isolate private level/generator modules and mutable
instances; shared fonts are released when changing screens. `COLLECTIONS`
registers the hub for mandatory tests, packaging and icon verification.
`scripts/install_games_hub.py --card <mount> --packer <xtpack.py>` backs up,
builds a private import package and stages one installer for subsequent USB use.

Validation: full 13-game quality gate passed with Lua compatibility, packages
and native icons. Every original suite also passed through its bundled engine
with native/enlarged and bitmap metrics (1,434 bitmap gameplay frames; highest
engine frame 590 commands). Hub navigation/import/error tests passed 133
additional frames, max 569 commands, all 18,315 font images released. Actual
SD save import and load/save of all 13 engines passed in a host sandbox. Public
and private code/data sections were decrypted and roundtrip-verified at build
time; the private import's digest/count matched the backed-up snapshot.
Code container: 327,082 bytes public, 26/32 files, below 524,288-byte limit.

**Next device check:** install the staged hub; confirm your existing levels,
unfinished puzzles and undo after import; switch repeatedly with the grid menu;
check startup, fonts, touch and sleep/resume. No physical hub test has occurred.
Keep the original apps installed until import is confirmed. Paper Golf remains
shelved and excluded. The older wallpaper sleep test below is still outstanding.

## Shared game design rollout — current state

The user physically confirmed that Nonogram v0.4 looks much better, then
requested a centered Nonogram game area, heavier lines, the same treatment
for all games, and repo notes explaining the changes and reasons.

The design owner is now [GAME_DESIGN.md](GAME_DESIGN.md). It records the
adopted tokens, hierarchy, font roles, per-game exceptions, change rationale,
source owners and verification process. `AGENTS.md` routes future work there.
`shared/game_style.lua`, `game_theme.lua`, `game_ui.lua` and `typefaces.lua`
own implementation; glyph data/notices/metrics are generated in `shared/`.
Source fonts moved to `assets/fonts/game-ui/`; use `make_game_fonts.py` and
`sync_game_theme.py`. The old Nonogram exporter command is only a compatibility
entrypoint. Do not fork per-app fonts or style constants.

Nonogram v0.5 centers the measured clue + board composition horizontally and
vertically in the play band while retaining large cells. Its grid is 3px;
frame and X marks are 4px. The other active games use the shared rounded
control family, Poppins/Inter and stronger vector strokes. Straight internal
grid edges, interrupted rods, double bridges and other rule-bearing geometry
remain distinct. Render review removed redundant double control borders and
fixed Line Lift/Sudoku label truncation.

The full 13-game quality gate passed with native and bitmap gameplay suites,
source-font mask validation, shared-copy checks, Lua compatibility and package
icons. Bitmap suites audited 1,434 frames, peaking at 589 drawing commands,
and released every decoded image. The expanded shared pack has 333 images /
64,384 pixels (193,152 RGB payload bytes; native/Lua overhead unmeasured).
New family versions still need physical startup, memory, touch and sleep/wake
checks. The user's v0.4 appearance confirmation is narrower than those checks.

See [first](design/game-family/first-sheet.png),
[dense](design/game-family/dense-sheet.png) and
[help](design/game-family/help-sheet.png) host previews. They replay actual
packaged glyphs and app drawing commands, not physical screen captures.

Exact installers, versions and hashes are indexed in
`releases/game-family-2026-11-07.json`; a complete Apps bundle is
`releases/game-family-2026-11-07.zip`. All 13 installers were copied into
`/media/mellow/4A21-0000/Apps/`, flushed and checksum-verified. Previous
installers and available installed-game data were backed up under
`/home/mellow/Backups/xteink-game-family-before-update-20261107-223614/`.
All 28 inspected installed/save files remained unchanged. Copy receipt:
`releases/game-family-sd-copy.json`. Install the updates through All Files,
over existing apps. Pocket Golf remains shelved; wallpaper utility unchanged.
Source changes and notes are saved in this local checkout, uncommitted/unpushed.

## Nonogram typography — v0.4.0, local workspace

The user approved implementing Poppins/Inter. Nonogram now ships actual 1-bit
PNG glyphs: Poppins SemiBold headings, Poppins Medium controls, Inter Medium
clues, status and help. It uses no TTF runtime loader or global font changes.
The source fonts and licenses are in `assets/fonts/game-ui/`; generated
metrics/PNGs are `games/nonogram/app/font_data.lua`, renderer `typefaces.lua`, and
full packaged notices `font_license.lua`. Rebuild with
`python3 scripts/make_game_fonts.py`.

The pack has 227 unique images / 36,655 pixels. Their raw RGB payload would
be 109,965 bytes; native/Lua allocation overhead remains unmeasured. Images
are decoded on the first frame, reused and released on leave. Native fallback
handles decode/draw failures and unsupported text. Separate Inter clue roles
preserve the chosen typeface on the larger 5×5 grids.

See [updated design rationale](../games/nonogram/docs/DESIGN.md),
[actual packaged-glyph preview](../games/nonogram/docs/design/bitmap/native-vs-bitmap.png),
and [state sheet](../games/nonogram/docs/design/bitmap/states.png). They replay real
shipped glyph pixels through the app, but remain host previews.

The full 13-game quality gate passed, including glyph-source masks, bounds,
native failure paths, repeated-frame image reuse and release, all puzzle
layouts and save compatibility. The busiest font test uses 323 drawing
commands. CI pins Python 3.12/Pillow 10.2.0; the wheel's FreeType 2.13.2 glyph
masks were verified locally. Physical first-frame time, native memory overhead,
PNG appearance and sleep/resume need a reader check. Source changes remain
local and uncommitted.

Exact deliverable: [nonogram-0.4.0.xtapp](../releases/nonogram-0.4.0.xtapp)
(94,688 bytes), checksummed in `releases/SHA256SUMS`. A separate
`releases/nonogram-font-licenses.txt` also accompanies the release. After the
user reconnected the card, v0.4 was copied to
`/media/mellow/4A21-0000/Apps/nonogram.xtapp`, flushed and checksum-verified.
Previous installer and available Nonogram installed-app data were backed up
under `/home/mellow/Backups/xteink-nonogram-before-fonts-20261107-221011/`.
No installed/save files were modified. Install via All Files on the reader;
the v0.4 physical font check remains pending.

## Nonogram design pass — v0.3.0, local workspace

The user reports the earlier game builds seem to work, and requested a Design
Bible review and a more polished Nonogram first. The new design uses bigger
boards, aligned clues, line-match ticks, 2/3px grid strokes, 3px X marks and a
12px rounded control family. Check becomes Next when solved. Save format,
app ID and generated seeds remain compatible.

Read [Nonogram design rationale](../games/nonogram/docs/DESIGN.md) for the applied
Bible rules, space budget, stroke/radius tokens, interaction decisions and
physical checks. The [before/after preview](../games/nonogram/docs/design/before-after.png)
and [state sheet](../games/nonogram/docs/design/states.png) replay real Lua drawing
commands using a desktop font; they are not device screenshots.

The full 13-game quality gate passed again with compatibility checks, builds
and native icons. Regressions enforce the larger board and correct cell-edge
and rounded-control hitboxes, solved Next behavior, help blocking, save
migration, generated archives and undo. Other games keep their default button
style; the shared UI helper's rounded styling is opt-in.

The installer is [nonogram-0.3.0.xtapp](../releases/nonogram-0.3.0.xtapp), with
its checksum in `releases/SHA256SUMS`. The card was disconnected while preparing
the release; copying to SD:/Apps is pending. This v0.3 layout still needs the
reader's actual fonts, radius support, touch accuracy and ghosting checked.
Source changes remain local and uncommitted.

A follow-up [Inter/Poppins typography study](../games/nonogram/docs/design/font-comparison.png)
uses real fonts in the host preview. Proposed direction: Poppins title and
controls, Inter clue numbers. The v0.3 installer uses native font handles;
the v0.4 bitmap implementation above follows that initial study. Native
per-app TTF loading remains unverified.

## Generated puzzle update — local workspace, 2026-11-07

Word Hunt v0.2.0 and Nonogram v0.2.0 now continue past their authored levels with
deterministic offline generation. Word searches are checked for exactly one
occurrence per target. Nonograms are uniquely solvable abstract patterns,
not an endless collection of recognizable pictures. Stable generator v1 seeds
must not change in future updates without migrating saves. Both games read v1
saves and preserve existing progress, unfinished boards, hints and undo.

Sudoku v0.1.0 is a new active app (`sudoku`), adapted from the generator/notes/undo
design in BigCatMellow/meditation. It provides unique puzzles, three clue-count
settings, pencil notes, automatic peer-note cleanup, undo, explicit CHECK and
saved puzzle visits. Difficulty labels are clue-density settings, not solver
technique ratings. A new puzzle preserves the unfinished previous one.

The shared `puzzle_store.lua` uses 64 numbered archive shards per namespace to
avoid Licorice's 512-file quota. Run `python3 scripts/sync_puzzle_store.py` after
editing it. Archives still consume the firmware's byte quota; save failures are
reported and block navigation away from unsaved work. Generators accept puzzle
numbers up to 999,999,999; finite grids can eventually repeat.

Validation: the full 13-game quality gate passed with Lua compatibility, packages
and embedded native icons. Independent Python checks solved 102 generated
nonograms plus 32 forced fallbacks and 75 Sudoku grids, and scanned 204 generated
word searches plus 64 forced fallbacks. Host gameplay tests cover v1 migration,
generated navigation/relaunch, undo, unsubmitted answers and enlarged-font layouts.
The archive regression retains 2,048 records in 64 files. Physical generation
latency, typography, touch and sleep/resume remain unverified.

Installers: `releases/word-hunt-0.2.0.xtapp`, `releases/nonogram-0.2.0.xtapp`,
`releases/sudoku-0.1.0.xtapp`; checksums in `releases/SHA256SUMS`.
Source changes are in this local checkout and have not been committed or pushed.
All three installers were copied to `/media/mellow/4A21-0000/Apps/`, flushed and
verified against their release checksums. Previous installers were backed up in
`/home/mellow/Backups/xteink-endless-before-update-20261107-194002/`.
No installed app or save data in `XTApps/` was changed. The reader still needs
to install the packages through All Files before the physical checks.
Wallpaper v0.5.0's outstanding physical sleep test below remains outstanding.

Start here when resuming this work. Repository: **BigCatMellow/xteink**, branch **main**. Last functional wallpaper change: [`981d182`](https://github.com/BigCatMellow/xteink/commit/981d182224d63b56c867201cee90f21940490a7a).

## Next action

**Wallpaper Randomizer v0.5.0 is implemented, built, tested and staged on the SD card. Its new sleep integration still needs its first physical test.** The user has not yet reported installing/enabling v0.5.0 or seeing a wallpaper during sleep. Do not confuse the successful v0.4.6 quick preview with a completed sleep/wake test.

Follow the [wallpaper handoff](../wallpaper-randomizer/docs/HANDOFF.md). It includes the exact installer, device evidence, install steps, limitations, backups and developer commands. The user wants a new random wallpaper **only when entering sleep**, held unchanged throughout that sleep. They do not want an hourly wallpaper changer.

## Saved deliverables

- [Exact v0.5.0 installer](../releases/wallpaper-randomizer-0.5.0.xtapp), with [SHA-256 checksum](../releases/SHA256SUMS). This is the same package copied to the card, archived here independently of expiring CI artifacts.
- [Wallpaper implementation and usage](../wallpaper-randomizer/README.md), [device checks](../wallpaper-randomizer/docs/DEVICE_TESTING.md), preserved preview logs and the unshipped compact-PNG experiment linked from the handoff.
- Existing source, quality rules, tests, native icons and per-app build workflows are committed. Personal wallpapers, card backups and game save data remain on the local machine/card.

The SD card was mounted at `/media/mellow/4A21-0000` while staging. It was **not accessible at that path when this handoff was written**. Reconnect/remount before inspecting logs or copying anything. Do not infer a new device result from the old backup logs.

## Games and repository conventions

There are 13 active games in `scripts/sync_game_ui.py`. Current manifests at handoff:

| Project | Version |
| --- | --- |
| Line Lift | 0.5.0 |
| Summit Putt | 0.5.0 |
| Link Grid | 0.3.0 |
| Ink Runes | 0.3.0 |
| Lantern Logic | 0.3.0 |
| Ray Vault | 0.3.0 |
| Island Links | 0.3.0 |
| Oddity Hunt | 0.2.0 |
| Word Hunt | 0.3.0 |
| Nonogram | 0.5.0 |
| Word Bridge | 0.2.0 |
| Rectangle Rooms | 0.2.0 |
| Sudoku | 0.2.0 |

Pocket Golf / Paper Golf (`paper-golf`, app ID `pocketgolf`) is **shelved and must stay off the SD card**. Its source is preserved; do not reinstall it with the active games.

All our `.xtapp` installers belong in **SD:/Apps/**. **XTApps/** is firmware-managed installed app/save storage; do not move or replace it to organize installers. Install updates over existing apps and preserve progress, undo history and unfinished boards. Verify the SD inventory before assuming every newer repo game has already been copied/installed; this final work only staged the wallpaper update.

The user expects crisp, premium e-ink presentation. Text overlapping boards/controls was a recurring issue. Read [AGENTS.md](../AGENTS.md) and [GAME_QUALITY.md](GAME_QUALITY.md). Games use `shared/game_ui.lua` for measured text, padded controls and wrapping, with layout regressions using distinct font heights and wider glyph metrics. The wallpaper settings now use the same synchronized helper, listed under `OTHER_APPS` rather than `GAMES`.

Native icons are required for every active app. Editable SVGs are in `assets/icons/`; `scripts/make_icons.py` produces the app PNGs, and `scripts/verify_package_icons.py` checks the native packaged icon section. Host checks do not prove the real reader's typography or touch behavior.

## Last verification

Both checks passed for functional commit `981d182`:

- [Wallpaper build, renderer/cache/rotation tests, Lua compatibility and native icon](https://github.com/BigCatMellow/xteink/actions/runs/42410216245).
- [Game quality gate](https://github.com/BigCatMellow/xteink/actions/runs/42410216255), including all 12 active games.

Locally: `python3 scripts/check_games.py` passed. Wallpaper tests covered 100 new sleeps, fixed timer frames, history transactions, failures, controls and measured layouts; independent JPEG and lossless PNG/cache checks passed. **Only the JPEG preview, not the new v0.5.0 sleep integration, was physically confirmed.**

The repo has received new game commits concurrently. Fetch before publishing and preserve/rebase over unrelated changes rather than overwriting them.
