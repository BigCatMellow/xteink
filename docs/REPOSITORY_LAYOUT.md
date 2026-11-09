# Repository layout

Reorganized on 2026-11-08 to keep projects together and reduce root clutter.

| Folder | Owner / contents |
| --- | --- |
| `games/` | 17 active games, Games Hub and shelved Paper Golf; start at its README |
| `shell/` | Shell research/protocols/roadmap in docs, diagnostic in probe, host tools and focused tests |
| `wallpaper-randomizer/` | Wallpaper utility |
| `shared/`, `assets/` | Shared UI, fonts, licenses and icon sources |
| `scripts/`, `tests/` | Collection-wide build, update, render and quality infrastructure |
| `docs/`, `research/` | Repository-wide game conventions, handoff and scouting |
| `releases/` | Immutable historical packages/catalogues; stable game keys and installer filenames |
| `dist/` | Ignored build output |

Games moved from `<game>/` to `games/<game>/`. Shell docs moved from
`docs/shell/` to `shell/docs/`; its host tools and tests now live under `shell/`.
Run documented commands from the repository root. The canonical game-source
resolver is `project_path(name, root=ROOT)` in `scripts/sync_game_ui.py`.
Logical game keys, app IDs, release filenames and SD paths stay stable.

App payload bytes are unchanged by the moves, so no installer version bump or
SD update is needed. Workflow filters, runtime test-helper paths, source
discovery, renderers, release tools and document links use the new locations.
The before/after renderer can still read older flat-layout Git revisions.

Historical review hash tables and source receipts retain the paths/revisions
they inspected. Relocating a document does not renew a prior substantive review
or turn host evidence into a physical reader result. See the referenced Git
revision when validating a historical path. Keep any unrelated local edits
separate from this directory-only change.
