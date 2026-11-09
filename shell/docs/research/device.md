# X4 Pro Licorice: shell capability research

Research snapshot: **2026-11-08**. This is source research and a proposed probe
sequence. No SD card, serial port, reader, NVS, firmware or app installation was
accessed or changed for this research. No probe was implemented or run. Upstream
hardware reports below belong to their authors; they are not tests of this reader.
The local handoff identifies the reader's last observed firmware as **26110201**.
Record the actual build and API level again before any later device work.

## Decision supported by the evidence

A **manually opened, SD-resident Lua app that presents a complete shell interface**
is the strongest route. It can own a 480×800 canvas, render a launcher, keep its
own settings and run bundled game engines. Licorice still boots and hosts it.
Calling this an SD-loaded interface is accurate; calling it an externally booted
OS is not supported. Automatic startup, arbitrary installed-app launching and
returning to this shell after stock screens are three separate unproven features.

The existing Games Hub already establishes the local implementation pattern for
bundling our games. Its host tests and verified card replacement do not establish
physical launch, memory, wake or rendering behavior. Keep the known working game
packages and their saves outside an experimental shell's scope.

## Evidence vocabulary and pinned sources

**Upstream device report** means an upstream author says they observed hardware.
**Emulator** means the stock image was exercised under x4pro-emu. **Reversed**
means a decompile/disassembly inference. **Local host** means repo code, tests or
handoff evidence. **Unknown** means the sources do not demonstrate the claim.
These categories are not interchangeable.

All GitHub links use immutable revision IDs:

- **[E1: Licorice app format and launch](https://github.com/kycube/x4pro-emu/blob/51860db361660d69507acbf3c6d2ce930c267533/docs/licorice-apps.md)**,
  x4pro-emu `51860db361660d69507acbf3c6d2ce930c267533`, 2026-10-30.
- **[E2: Stock Licorice behavior](https://github.com/kycube/x4pro-emu/blob/51860db361660d69507acbf3c6d2ce930c267533/docs/stock-licorice.md)**,
  same revision. Covers 261013 and 26102901, not this reader's newer build.
- **[E3: Probed APIs and limitations](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/docs/firmware-notes.md)**,
  touch-licorice-apps `98988cb083bd0c205219575da9783fdaba1148fd`, 2026-11-08.
- **[E4: Current upstream overview](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/README.md)**,
  same revision. Mixes historical API 2.9 guidance and newer API 2.18 requirements.
- **[E5: Official-doc availability note](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/docs/xtapp-api/README.md)**.
  The official docs are invite-only and intentionally absent from the public repo.
- **[E6: ESP32-S3 startup](https://docs.espressif.com/projects/esp-idf/en/v6.0.1/esp32s3/api-guides/startup.html)**,
  **[E7: boot modes](https://docs.espressif.com/projects/esptool/en/latest/esp32s3/advanced-topics/boot-mode-selection.html)**,
  **[E8: sleep modes](https://docs.espressif.com/projects/esp-idf/en/v6.0.1/esp32s3/api-reference/system/sleep_modes.html)**,
  Espressif, retrieved 2026-11-08. E6/E8 are versioned documentation; E7 is a
  mutable upstream documentation URL, not a firmware-specific test.

The machine-readable [source register](sources.json) also records blob IDs,
scope, limitations and supplementary implementation sources.

## Capability table

| Capability | What the evidence establishes | Consequence / confidence boundary |
| --- | --- | --- |
| SD-resident app | Licorice installs an encrypted `.xtapp` from All Files and copies it to `XTApps/<app_id>/app.xtapp`; E1 reports a real 26102901 install/launch and emulator coverage. | Strong basis for a normal shell app. Local installers belong in `SD:/Apps/`, per repo rules. An installer and an installed package are different artifacts. |
| Full-screen custom interface | E1's probe obtains `g:size()` = 480,800. E3's API 2 path supports drawing, pointer movement, fonts and keyboard. | A custom home screen inside an app is feasible. It does not own the boot process or all firmware navigation. |
| Native OS / USB-stick boot | E6 describes ROM → flash bootloader → flash partition. E7 distinguishes normal flash execution from ROM USB/UART download mode. | No source demonstrates booting an OS from an SD filesystem or USB storage without changing firmware. USB disk mode and firmware download mode are different mechanisms. Do not infer a PC-style boot menu. |
| Lua package execution | E1 reverses XTCO Lua source loading and package-local `require`; E3 reports Lua 5.5 and API 2.9. | Bundle controlled modules, use the current Lua compatibility checks. A package loader is not a native executable loader. Bytecode acceptance in E1 is inferred and untried. |
| Cold-boot default app | E2 records an NVS `fw/home_app` value `sys.home`. No reviewed source documents a public API for changing the cold-boot default to an Ink App. | The name is a research lead, not authorization or evidence for editing it. Do not plan an NVS write or autostart promise around this string. |
| Last-app resume | E1 describes an RTC flag selecting `user.lua` or `sys.apps` after a reboot during an app, explicitly unexercised. | At most a reversed lead for resume. It does not establish launch from a cold boot or after loss of RTC state. |
| Wake destination | E2's 261013 deep sleep wakes to the last book; 26102901 wakes to Recent. Both were emulator-walked, with upstream owner comparison. | Wake policy changes by build. Neither behavior proves a shell resumes on this reader's 26110201. |
| Stock screen navigation | E3 observes `ctx.system` with `can_open` and `open` in API 2.9. | Good reason for a bounded capability probe. Reviewed public sources give no target grammar, target list, permission requirement, return contract or successful example. Do not invent URI routes. |
| Arbitrary installed-app launch | E1 shows the native Ink App list scanning `XTApps/<dir>/app.xtapp`, then starting `user.lua`. It does not expose that dispatcher to Lua. | A native launcher exists; a third-party launcher API remains unknown. Presence of `system:open` alone does not prove it launches another app ID. |
| Native navigation and return | E1 demonstrates Home pad → leave confirmation → Ink App list. | Maintain an obvious escape to stock UI. Custom shell return after opening a stock screen, interception of Home and replacing the stock drawer are unproven. |
| Storage sandbox | E3 reports `ctx.files.path = /AppFiles/<app_id>`, backed by `XTApps/<app_id>/files/`; outside paths and `..` are refused. Updates retain this folder; uninstall deletes it. | Shell can store its own catalogue/preferences. It cannot assume cross-app save access, enumerate arbitrary SD content or rewrite other packages. Preserve app IDs and install over existing versions. |
| API selection | E3 later proves `api: 2.0` with permissions from `net`/`reader` (or none); the host returns API 2.9. Newer E4 apps need API 2.18. | The opening no-network conclusion in E3 is historical API 0.8 evidence. Do not copy the old permission vocabulary or assume 2.9/2.18 solely from manifest text. Check runtime surfaces. |
| Network and updates | E3 proves API 2 networking/storage; E4 describes store updates and a browser SD copier. Neither proves an app may update another app's package. | Reuse the authorized host updater for our collection; do not promise an autonomous shell updater. Later API 2.18 improves HTTP verbs; early PATCH failure is not universal current behavior. |
| Lock-screen entry | E3 proves API 2 `lockscreen` manifest plus `ctx.lockscreen:set_default`; E2's older API path could not finish this flow. | Sleep-screen code is a separate entry/lifecycle, not a startup hook or interactive replacement desktop. Keep existing Wallpaper Randomizer integration separate. |
| Sleep timers | [Upstream Notes](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/apps/notes/lockscreen.lua#L134) reports 30–3600 s, reset to manifest interval each lock; 26110201 timing behavior is recorded. | No zero-wake/battery claim. A timer callback is not proof of a new user sleep or a cold boot. Local v0.5 sleep integration remains physically unverified. |
| Installed save compatibility | Local Games Hub imports missing saves into its own sandbox; subsequent hub and standalone progress are separate. [Handoff](../../../docs/HANDOFF.md) records preservation and pending device checks. | A new shell app ID creates another sandbox. Prefer launching existing apps if proven; otherwise explicitly design migration and ownership before bundling more tools. |

## Boot, resume and sleep must be tested independently

For this project, define a **cold boot** as entry from a full shutdown/power-on
without assuming preserved app RTC state. Define **ordinary sleep/wake** by the
user's normal power-button action, and **timer wake** by the lock-screen host's
reported reason. A **warm reset / RTC resume** is a separate case. A screen that
survives on e-ink proves no code has resumed; e-ink can retain an old image.

E6 describes an optional RTC deep-sleep entry before normal startup. E8 says
light sleep preserves normal CPU/RAM state while deep sleep powers most of it
down and retains selected RTC domains. These SoC mechanisms do not establish
which one a particular Licorice UI action selects. E2's observed deep-sleep
path and E1's inferred app RTC flag must not be collapsed into a cold-boot hook.
The feature called **Back to previous spot** in E2 is reader-page navigation,
not a global return-to-shell or autostart facility.

USB mode is also separate: E2 observes a CPU restart into the stock USB mode,
and only partial USB emulation. It provides neither external boot nor evidence
that an interactive shell continues executing while a computer owns the card.

## Resource budgets and architectural effects

The local Hub snapshot in [HANDOFF](../../../docs/HANDOFF.md) is **17 engines,
30/32 code files, 383,525/524,288 XTCO bytes**. That leaves **2 code-file slots
and 140,763 bytes** under the current build gate. XTCO cost includes its 16-byte
header, 104 bytes per code file, and all source bytes. Adding modules consumes
both budgets; merging modules only solves file count, not source/heap cost.

E1 establishes the 1..32 XTCO entry count from reversed parsing. Its 512 KiB
boundary is specifically the **in-memory code path**: it also reverses a larger
streamed path and explicitly says it was not exercised. The
[upstream packer](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/xtpack.py#L202)
rejects larger code, and this repo's [Hub builder](../../../scripts/build_game_hub.py)
does too. Therefore **524,288 bytes is the supported project budget**, not proof
that all possible firmware code packages have an absolute 512 KiB ceiling.
Do not bypass that gate for a shell experiment.

E3's upstream device probe reports **512 files / 134,217,728 bytes per app**,
whole-file storage reads, and no byte-range support. A shell that bundles all
17 games also inherits their save growth in one sandbox: quotas apply to the
aggregate. Preserve archive sharding and account for catalogue, preferences,
imports and bounded diagnostic files before adding more content.

E3 reports truncation around **1,024 draw commands** on 26102401. Keep a measured
margin and design the shell to remain below the current game's measured peaks;
command-count success still does not prove correct fonts, touch or e-ink refresh.
The local handoff's bitmap pass peaks at 589 commands and releases decoded images.
E3's historical 1 MiB Lua heap descriptions and newer
[Text Adventures' roughly 2 MiB claim](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/apps/textadv/README.md#L38)
are not a guaranteed heap allowance for this firmware. Source/package bytes,
Lua heap, native image buffers and peak decoded font allocations are different
budgets. Lazy-load one screen/engine, release its resources, and measure peaks.

The [Sky Tonight account](https://github.com/omer-faruq-xteink/touch-licorice-apps/blob/98988cb083bd0c205219575da9783fdaba1148fd/apps/skytonight/README.md#L56)
also records callback limits and a lock-screen budget it cannot extend. Do not
put parsing, bulk save imports or network work in a lock-screen callback.

## Smallest discriminating probes — specification only

These proposals do **not** authorize installation, SD writes, firmware changes or
physical testing. Work only in a disposable app sandbox when a later stage
explicitly authorizes a device probe. Never change NVS/home_app, boot partitions,
security settings, lock-screen default or existing app/save data to answer these.

| Order | Minimal observation / action | Result needed before depending on it |
| --- | --- | --- |
| DP0: contract inventory | One normal API 2 test app with no permissions: show firmware/model, runtime API, screen size, presence/types of `system.can_open`, `system.open`, storage usage and memory counters. Record bounded allowlisted values only; no device IDs, credentials, full ctx dumps or SD inventories. | Captured contract for the exact reader/build. Member presence establishes existence only. Prefer borrowing an existing verified diagnostic app over creating another package. |
| DP1: resolve route contract | Obtain the authorized official API method page or inspect a public upstream example first. Only then query `system:can_open` for the **documented** stock destination and one documented installed-app target. Do not brute-force strings or invoke `open` on a guessed signature. | Exact signature, target grammar, supported targets and harmless rejection behavior. If no contract is available, this feature remains blocked; manual Ink App entry stays the baseline. |
| DP2: one controlled transition | After DP1, one explicit tap invokes `system:open` for one documented stock destination. Persist a unique small marker before the transition; use the standard Home/back flow; later repeat for one test installed app if the contract supports it. | Visible destination, return path, callback order, whether shell instance survives/reloads, and unchanged target saves. Repeatability matters more than a returned boolean. |
| DP3: lifecycle separation | With an unchanged disposable app, record distinct trials: leave/reopen; normal sleep/wake; timer wake only if already enabled elsewhere; warm reboot; explicit full shutdown/power-on. Keep cold boot separate from retained RTC state. | Per-trial observed startup destination, load/state marker and escape path. No autostart claim unless the exact cold-boot trial reaches it without manual launch. A photo of retained pixels is insufficient. |
| DP4: integrated load | Host-only package budget and drawing/resource tests first. On later authorization, cycle one light game, one worst-case game and shell repeatedly with bounded timing/memory counters and a save/relaunch check. | No growth in retained images or memory, stable saves, complete physical frames/touch, safe return to stock UI. Keep existing app registrations untouched. |

Use a fixed-size report or overwrite a single diagnostic file in the test
sandbox; do not consume quota with one file per event. A return value or emulator
golden alone cannot certify physical destination, power behavior or save safety.

## Ranked open questions

1. **Can API 2 on 26110201 launch a specific installed Ink App, and return to the
   shell?** This decides launcher versus bundled suite. `can_open/open` names
   alone do not answer it; DP1 then DP2 is the smallest discriminator.
2. **Is there a supported user-facing cold-boot default-app setting?** Public
   evidence currently says unknown. Research a documented contract before any
   physical experiment; an NVS key or RTC resume is insufficient.
3. **What happens on normal sleep/wake while the shell or a launched app is
   active?** DP3 must use this exact firmware. Avoid changing the existing sleep
   wallpaper merely to test shell startup.
4. **Does the shell get a reliable supported return route from stock screens?**
   A route out is insufficient for a coherent everyday launcher; DP2 captures it.
5. **How much headroom does the chosen architecture actually retain?** Current
   Hub has 2 file slots and 140,763 code bytes; runtime memory and physical first
   frame latency remain unmeasured. DP4 follows the architecture decision.
6. **Can an app enumerate installed apps without crossing the sandbox?** No
   reviewed public source demonstrates this. A curated host-generated catalogue
   is sufficient for an initial shell if launch itself is proven.
7. **Can future firmware rotate packaging/API behavior or change navigation?**
   E4 warns about key changes; E2 demonstrates wake/UI/API changes. Version the
   compatibility contract and keep stock entry/recovery available.

Onion-style SD interfaces are a useful design analogy, but do not transfer
their boot/startup mechanisms to ESP32-S3 Licorice. No Onion source is needed
to establish this device's technical capabilities; this research makes no
claim that an Onion loader works here.
