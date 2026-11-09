# Shell design: Games Hub 0.4.0

Owner: coordinator. Adopted 2026-11-09. Source: `games/games-hub/src/shell.lua`
(screens) and `index.lua` (hosting, state, orientation).

## Decisions and reasons

| Decision | Reason |
| --- | --- |
| The shell is the next Games Hub version (`gameshub`), not a new app ID. | User choice. Existing Hub progress, the import receipt and the card updater carry over unchanged. |
| The shell is entered once, and the reader's sleep/wake keeps it on screen. | User report: sleep (including a long power press) returns to the open app. A locked unit rules out firmware boot hooks; see [THINK](THINK.md) and [device research](research/device.md). |
| Games run inside the shell. | A separately launched app would be the one resumed after sleep, not the shell. |
| Reopens where it was left (`shell.txt`: screen + orientation, including an open game). | If the firmware ever relaunches the app instead of resuming it, the user still lands where they were. |
| Layout follows the user's CrossPoint X4 Pro preview (`BigCatMellow/crosspoint-reader`, `index.html`, `a93303a`). | User-supplied Home design. |
| Reading is display-only: current book, percent, streak, minutes today, Library list. | `system.open` has no documented targets, so the shell cannot open a book. The card says "Continue in the reader". Rows have no chevron or frame, so they don't look tappable. |
| Portrait or landscape (Settings → Screen), via `ctx.screen:set_orientation` on API 2.18. | The user reads in landscape with the device's base on the left. The setting appears only when the firmware exposes rotation. |
| Games always switch to portrait and back. | All 17 engines are laid out and tested for 480×800. |
| Book titles use the control face (Poppins Medium); curly quotes, dashes and ellipses become ASCII. | The heading bitmap face lacks punctuation, and a title containing `'` would otherwise drop to the native font. Changing the shared font pack would version every game. |
| No clock in the header; battery only. | Apps redraw only on input, so an e-ink clock would show a stale time. |

## Tokens and layout

Monochrome, square corners, 1px rules (rendered as filled rects) and 2px frames
(1px plus the family stroke increment). Margin 18, header 52, bottom bar 76,
status line 34 above the bottom bar, list rows 92 with a 10 gap. Landscape uses
two columns for lists and side-by-side Home cards. Fonts are the canonical
family roles (`small` Inter, `medium` Inter body, `control` Poppins Medium,
`large` Poppins SemiBold for page titles only). Icons are vector strokes; the
Games icon repeats the in-game nine-dot return button.

One `Shell.targets()` list drives both drawing and hit testing. Tests tap the
centre of drawn targets and check that the gaps between rows do nothing.

## Previews

Host renders with packaged glyphs (not device photos) are in
[docs/design/games-hub](../../docs/design/games-hub/): `home`, `library`, `games`,
`settings` and their `-landscape` versions. Regenerate them with
`python3 scripts/render_game_hub.py`.

## Install note

0.4.0 changes the manifest to API 2.18 with the `reader` permission. The
firmware has to approve that, so the card updater skips the Hub and reports
`firmware_install_required`. Install `Apps/games-hub.xtapp` over the existing
Hub once from All Files. Saves stay because the app ID is unchanged. Later
versions with the same permissions update directly again.

## Device checks still needed

- One-time install over 0.3.3: progress kept, and reading access granted.
- Which way `landscape` turns compared with the user's grip (base on the left), and whether taps map correctly.
- Reading data on the Home and Library screens matches the stock reader.
- Sleep/wake from Home, Library and inside a game; switching between landscape and a portrait game.
- Native fallback for titles with accented characters; e-ink refresh of the 1px rules.
