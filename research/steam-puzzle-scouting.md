# Steam puzzle scouting for XTEINK X4 Pro

Reviewed: 2026-11-07. Status: research and prioritization only; no new game implementation claimed.

## Target and authority boundaries

XTEINK X4 Pro on XTOS Licorice, 480x800 portrait, black/white, completely static on each screen. One redraw per intentional touch; no animation, fades, continuous drag, countdown, sound dependency or grayscale-only clues. Tap one item, then its destination. Maintain independently verifiable puzzle solutions, clear undo, unique 96px one-bit launcher icon, host font-layout checks, partial save/resume, and installable XTApps packaged to SD:/Apps/. Device-specific touch and font legibility need physical validation. Preserve AGENTS.md and docs/GAME_QUALITY.md; do not modify the shelved paper-golf game.

These are commercial Steam game references, not asset/code/level sources. Adapt underlying *general puzzle ideas*, author fresh puzzles, characters and art, and avoid reproducing distinctive copyrighted content. Steam links verify the titles and their advertised gameplay; suitability ratings are design judgments.

## High-priority next games

### 1. Seat Shuffle — inspired by Is This Seat Taken? (2025)

Steam: https://store.steampowered.com/app/3035120/

**Fit: 5/5. Novelty: 5/5. Implementation complexity: medium.** Place guests/passengers in 6–10 numbered seats subject to constraints such as: prefer window; adjacent to a friend; avoid a noisy passenger; same row; near entrance; incompatible personalities. Use a *select guest, tap seat* control, never dragging. Each original level includes a small scenario and icon-plus-text preferences. Validate with a constraint-satisfaction solver: no contradictions, clear accepted solutions, ideally a unique arrangement. 12 or more original boards, static status, undo, CHECK, save. Main risk: without humor and personality it becomes a sterile logic table. Do not copy source characters, places, line art or authored preferences.

### 2. Clueboard — inspired by Logic Town (2023)

Steam: https://store.steampowered.com/app/2333240/

**Fit: 5/5. Novelty: 4/5. Complexity: medium.** Small Einstein/zebra grid: match people, objects and locations from short textual clues. 3x3 and 4x4 sizes, tap to mark yes/no/unknown, unique-solution generator, never require guessing. Reuse pure CSP/assignment solver logic from Seat Shuffle but keep the separate game and unique UI. Main risk: text density and checking dozens of clues on 480x800.

### 3. Then & Now — inspired by Instants (2025)

Steam: https://store.steampowered.com/app/2948560/

**Fit: 5/5. Novelty: 5/5. Complexity: low-medium.** Put 4–7 original illustrated memory cards in chronological order. Deduced sequence depends on objects and short captions. Tap two cards to exchange them; CHECK to submit; black-and-white panels with legible clue cues. Author all narrative scenes independently. Main risk: insufficient evidence in an image can turn deduction into arbitrary guessing.

### 4. Word Rooms — inspired by Knotwords (2022)

Steam: https://store.steampowered.com/app/1963900/Knotwords/

**Fit: 5/5. Novelty: 4/5. Complexity: medium-high.** Enter letters drawn from region-specific pools so that all horizontal and vertical runs form valid words. Tap cell, choose from large letter buttons; no keyboard needed. Independent dictionary/unique-solution test. Main risk: wordlist quality and cramped touch typing. A better complement to Word Bridge/Word Hunt than another word search.

### 5. Rule Lines — inspired by Understand (2020)

Steam: https://store.steampowered.com/app/1299400/

**Fit: 5/5. Novelty: 5/5. Complexity: high in level design.** Infer symbolic constraints, select ordered dots, submit a line and receive discrete success/failure indicators. No animated drawing: tapping endpoints makes a static segment. Make new logical rule families and level progression, not an asset/level clone. Main risk: teaching cryptic rules without accidental frustration.

### 6. Cipher Pages — inspired by Prose & Codes (2022)

Steam: https://store.steampowered.com/app/1718910/

**Fit: 5/5. Novelty: 4/5. Complexity: medium.** Short substitution cryptograms using original sentences or safely sourced public-domain texts. Select cipher letter, then replacement letter; update entire text immediately. Large fonts, autosave and accessible history. Don't copy proprietary written passages.

### 7. Pattern Tray — inspired by inbento (2019)

Steam: https://store.steampowered.com/app/1567440/

**Fit: 4/5. Novelty: 4/5. Complexity: medium.** Place and rotate small line-hatched puzzle tiles to match a target arrangement using limited moves. Convert source's color distinctions into distinct silhouettes or patterns. Test monochrome legibility.

### 8. Shape Shelf — inspired by Cats Organized Neatly (2020)

Steam: https://store.steampowered.com/app/1369340/

**Fit: 5/5. Novelty: 4/5. Complexity: medium.** Pack independently drawn silhouettes into a 5x5 or 6x6 tray, selecting and rotating each piece. Potentially a polyomino exact-cover generator. Must make independent shapes/art rather than copying the source's cats and handcrafted boards.

## Additional candidates worth inspecting

| Steam title | Link | Original adaptation angle | Assessment |
|---|---|---|---|
| Hexcells | https://store.steampowered.com/app/265890/ | Hex-grid clue deduction | Excellent fit, overlaps existing number puzzles |
| SquareCells | https://store.steampowered.com/app/416770/ | Numeric pattern elimination | Excellent fit, not a new kind of thinking |
| CrossCells | https://store.steampowered.com/app/632000/ | Remove cells by number clues | Excellent fit, similar numerical family |
| Tametsi | https://store.steampowered.com/app/709920/ | Non-square mine logic and notes | Excellent, but late levels may be cramped |
| Polimines | https://store.steampowered.com/app/1892790/ | Nonogram-plus-minesweeper constraints | Excellent, overlaps Nonogram |
| Logic Bombs (2025) | https://store.steampowered.com/app/3816700/ | Rule-introduction logic tiles | Excellent, design wholly original puzzle rules |
| Taiji | https://store.steampowered.com/app/1141580/ | Binary tile rule discovery | Excellent, strip original exploration context |
| Little Problems (2025) | https://store.steampowered.com/app/2653470/ | Tiny everyday mysteries told through 2–4 documents | Good, writing-intensive |
| The Case of the Golden Idol | https://store.steampowered.com/app/1677770/ | Original freeze-frame deduction via short evidence sheets | Good, requires pagination |
| The Roottrees are Dead | https://store.steampowered.com/app/2754380/ | Small family-tree deduction with letters/records | Good, writing-intensive |
| A Little to the Left | https://store.steampowered.com/app/1629520/ | Orderly Desk: sort visible items using intuitive attributes | Good if graphics remain readable |
| Unpacking | https://store.steampowered.com/app/1135690/ | Static household object placement | Conditional; source benefits from rich visual context |
| Railbound | https://store.steampowered.com/app/1967510/ | Track topology and one-shot static route validation | Conditional: motion is important to the original |
| Wilmot Works It Out | https://store.steampowered.com/app/2060590/ | Minimalist 4–9-piece monochrome jigsaw | Conditional: distinctive illustration is central |
| Hidden Folks | https://store.steampowered.com/app/435400/ | Hidden item layers on static line-art | Good, but better as Oddity Hunt expansion |
| Please, Touch The Artwork 2 | https://store.steampowered.com/app/2600140/ | Seek items in original black-and-white art panels | Good, overlaps Oddity Hunt |
| The Artisan of Glimmith (2026) | https://store.steampowered.com/app/4160210/ | Pattern-based stained-glass rules | Conditional: its color system needs redesign |
| Handshakes | https://store.steampowered.com/app/2171690/ | Two endpoints meet on a static grid | Good with one turn per redraw |
| Sokobond | https://store.steampowered.com/app/290260/ | Adjacent atom bonding logic in static steps | Good, requires readable bond and motion feedback |

## Priority sequence and acceptance checks

Build **Seat Shuffle** first. Its difficulty is in a meaningful constraint mix, not in graphics or movement. Follow with **Clueboard**, reusing a pure solver; then **Then & Now** for narrative variety; **Word Rooms** for word deduction; and **Rule Lines** for abstract inference. Existing catalog already covers word search, word ladders, nonograms, Akari, Bridges, object hunt and other binary grids; favor genuinely different interaction/problem types before similar variants.

For each candidate: author original levels and verify satisfiability plus ambiguity; test all screens with normal/enlarged font metrics and the shared UI helper; preserve saves/undo; enforce single static redraw; register the new game with repository quality checks; create and verify an independent 96px monochrome launcher icon; build its own installer; then conduct physical X4 Pro touch/display/sleep tests.

**No candidate was implemented or hardware-validated as part of this research document.**
