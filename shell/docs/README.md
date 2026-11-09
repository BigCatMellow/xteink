# Xteink shell research and planning

Status: initial research and planning. Owner: project coordinator. Updated 2026-11-08.

The objective is a custom primary interface stored on the X4 Pro SD card,
copied and updated through USB, while XTOS Licorice supplies hardware services.
The interface need not resemble PocketOS. Automatic startup entry is part of
that desired experience and needs evidence before it can be promised.

## Read in order

1. [Current state and next work](STATE.md).
2. [Device evidence](research/device.md) and [source identities](research/sources.json).
3. [THINK: alternatives and challenge](THINK.md).
4. [PLAN: tasks, dependencies, acceptance and model routing](ROADMAP.md).
5. [Applied MAPS_Lean protocols](protocols/INDEX.md) and [method research](research/maps-method.md).
6. [Independent planning review](REVIEW.md), including corrected findings and input identities.
7. [Probe preparation and capture tools](probes/README.md), the executable next research wave.

Device claims belong in research; decisions/task eligibility belong in the
roadmap; captured alternatives belong in THINK. STATE routes to these owners.
Source refreshes retain superseded evidence as historical when behavior changes.

## Meaning of loaded from USB

The working interpretation is SD-card code transferred through USB storage
mode. A USB thumb drive plugged into the reader needs a separate host-mode
capability investigation. Neither file transfer nor app launch proves external
OS boot. Distinguish firmware startup, Lua launch, sleep/wake and reset resume.

A polished menu alone does not complete the startup objective. The research
starts with a stock-hosted shell candidate; firmware changes are contingent
on a later decision. Public records contain no books, saves, credentials or
personal firmware dumps.

Related: [Xteink rules](../../AGENTS.md), [game design](../../docs/GAME_DESIGN.md),
[direct updates](../../docs/GAME_UPDATES.md), [Games Hub](../../games/games-hub/README.md).
