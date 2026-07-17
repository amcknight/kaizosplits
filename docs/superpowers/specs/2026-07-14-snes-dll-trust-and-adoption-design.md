# SNES.dll trust & adoption — design

**Date:** 2026-07-14
**Status:** draft for review
**Branch context:** `spike3-snes-dll` (two-assembly load already implemented and working live)

## Goal

Merge `spike3-snes-dll` into `main` once we can trust it, and leave behind small,
permanent infrastructure that makes every *future* SNES.dll change trustworthy too —
without slowing down day-to-day work across the two repos.

Explicitly **out of scope** (named follow-ups, see §7): adopting upstream's Phase 0
state machine in the .asl, the attach-flakiness investigation, any version-pinning
mechanism.

## 1. The boundary (what guards what)

> **SNES.dll owns:** "Where is this game's WRAM right now, across any emulator /
> core / version — reliable bytes, liveness, and identity signals."
> **kaizosplits owns:** everything standing on that — the reflection contract as
> consumed by the .asl files, watcher construction, split semantics, timer policy,
> LiveSplit deployment.

- **snes_offsets** guards "the DLL finds WRAM correctly": its unit suite today,
  its corpus→golden regression (roadmap T1.1) later. Not this effort's job.
- **kaizosplits** guards "our stuff works against the DLL as actually loaded":
  contract test (§4), merge gate (§5), deployment (§3).
- **Naming:** the assembly stays **SNES.dll**. Its SMW-specificity is confined to
  the liveness witness cells (`$13/$14/$0100`), and generalizing those is already
  tracked upstream (SA-1 / ROM-anchor B4). Renaming to `SMW_Offsets` would bake a
  temporary limitation into a permanent identity.

## 2. Ownership convention (durable, goes in CLAUDE.md here)

SNES.dll is ours (sibling repo `snes_offsets`, direct-push-to-main allowed there).
When kaizosplits work reveals friction that belongs below the seam — attach,
liveness, identity, raw reads — prefer improving it upstream over working around it
here. When upstream can't take it immediately, leave a `TODO(snes_offsets):` marker
rather than silently absorbing the workaround.

## 3. Deployment: make the DLL pair unskewable and staleness visible

Root cause of today's "old dll" incident: the `CopyToLiveSplit` target in
`Components/SMW/SMW/SMW.csproj` deploys only `$(TargetPath)` (SMW.dll). SNES.dll
reaches LiveSplit's Components folder by hand / machine-local luck.

1. **Pair copy:** extend `CopyToLiveSplit` to copy `SMW.dll` **and** `SNES.dll`
   from the same build output folder (they are already built there together as a
   coherent pair, via the ProjectReference). Keep the existing warn-don't-fail
   behavior when LiveSplit holds a lock, per file.
2. **Staleness visibility (one mechanism, no double-guarding):** in both
   `Kaizo.asl` and `Synth.asl` `startup`, log one line per loaded DLL with its
   file last-write time (and assembly version). "Is this an old dll?" becomes a
   glance at the log already being watched.
3. **Restart is inherent:** byte-loading happens at script load; picking up a new
   DLL requires reloading the script (in practice: restart LiveSplit). Documented
   in the gate checklist (§5), not fought.

## 4. Contract test (the reusable safety net)

One new test file, `ContractTests.cs`, in the existing `SMW.Tests` project.

- Loads the built `SNES.dll` + `SMW.dll` **exactly the way Kaizo.asl does**:
  `File.ReadAllBytes` → `Assembly.Load`, AppDomain data slot
  (`"SNES.LatestAssembly"`), `AssemblyResolve` hook, `Activator.CreateInstance`.
- Asserts, via reflection, that every member the two .asl files actually call
  still exists with the expected shape:
  - `SNES.Emu`: parameterless ctor, `Init(Process)`, `Ready()`,
    `GetOffset() → long`, `Smc() → string`, `SmcChanged() → bool`.
  - `SMW.Timer`, `SMW.Debugger`, `SMW.Settings`, `SMW.Watchers`: the member set
    used by `Kaizo.asl` / `Synth.asl` (e.g. `Settings.Init/UsedMemory/entries/
    keys/Update`, `Watchers.Init/UpdateAll/SetMemoryOffset/UpdateState` and the
    watcher fields the .asl reads, `Debugger.DbgOnce/HasLines/ClearLines/Update/
    Monitor`, `Timer.HistEnd`, …). The list is hand-maintained; a header comment
    states the discipline: *edit an .asl call site → update this list.*
- Where feasible without a live emulator, asserts behavioral shape too (e.g.
  `Ready()` throws rather than returns when unattached — exceptions are the
  contract's "not ready" signal).
- Result: an upstream change that would break the .asl turns `dotnet test` red at
  build time, not LiveSplit mysterious at run time.

## 5. Merge gate (a checklist, not a machine)

A short runbook doc in this repo (`docs/merge-gate.md`), used for merging this
branch and for every future SNES.dll bump kaizosplits picks up:

1. `dotnet test` green in **both** repos (SMW.sln here, SNES.Tests upstream).
2. **Live matrix, semi-automated:** ~3 emulators × ~5 ROMs from a small YAML combo
   list committed here. Human launches each emulator+ROM (and pokes at anything
   they're suspicious of); upstream **LiveProbe** attaches and reports
   resolve → read → identity per combo. **No bespoke driver script** — LiveProbe
   is the reused tool (it is also the seed of upstream's planned `doctor`, T1.4).
   Only if LiveProbe genuinely can't cover a check do we consider adding one, and
   then preferably upstream.
3. **One real LiveSplit session** on one combo, verifying the known-good log
   sequence: connect → SMC detected → WRAM discovery → watcher updates → start →
   split → reset. (Today's captured JUMP.smc log is the reference.)
4. Reminder: restart LiveSplit after any DLL rebuild (§3.3).

## 6. Version pinning: deferred, with the trigger written down

Stay **fluid**: sibling-checkout ProjectReference, both repos evolving together,
no pinning ceremony. This is deliberate while both repos are ours and userless.

**Revisit trigger (whichever comes first):** a consumer outside these two repos
appears, or the repos need to move independently (e.g. a kaizosplits release must
not absorb in-flight SNES.dll work). When triggered: pick **one** mechanism —
most likely a pinned built artifact (local NuGet feed or committed DLL with a
recorded upstream commit) — not layered safety.

## 7. Named follow-ups (recorded, not scheduled)

- **Phase 0 adoption:** when upstream ships `State` / `Generation` / `Status()`,
  replace the .asl's try/catch readiness dance and `vars.ready` bookkeeping with
  the honest state machine. Split logic is delicate — this gets its own
  brainstorm/spec when the time comes.
- **Attach flakiness:** long-standing "restart LiveSplit or the emulator until it
  attaches" roulette. May be the ASL plugin's process-hooking, not ours. The
  upstream doctor (T1.4) is the diagnostic that would finally assign blame.
- **Raw-read surface upstream:** SNES.dll still exposes only offset resolution;
  reads happen via `MemoryWatcher` in SMW.dll. Upstream boundary doc already
  flags `ReadByte/ReadWord`-style primitives as the missing surface (needed by
  SMWCounters and friends). Consumer-driven; not needed for this merge.

## 8. Work items (in order)

| # | Item | Where |
|---|------|-------|
| 1 | Pair-copy `SNES.dll` in `CopyToLiveSplit` | SMW.csproj |
| 2 | DLL identity log lines in both .asl `startup` blocks | Kaizo.asl, Synth.asl |
| 3 | `ContractTests.cs` | SMW.Tests |
| 4 | Merge-gate runbook + combo YAML | docs/ |
| 5 | Ownership convention section | CLAUDE.md (new, repo root) |
| 6 | Run the gate on this branch; merge to main on green | — |

Items 1–5 are individually small; the riskiest touch is the two .asl edits, which
are additive log lines only (no control-flow changes — the split logic is not
touched).

## Error handling notes

- Copy target: locked files warn per-file, never fail the build (existing
  semantics, extended to the pair).
- Contract test failures block the gate by definition; they name the missing /
  changed member so the .asl call site is findable by grep.
- LiveProbe combo failures record emulator+core+ROM; a FAIL on any listed combo
  blocks the merge unless the combo is explicitly dropped from the YAML (a
  reviewed decision, not a shrug).

## Testing

- §4 *is* the new automated coverage; it runs in plain `dotnet test` with no
  emulator or LiveSplit present.
- §5 is the human-in-the-loop coverage with assertions delegated to LiveProbe.
- Existing SMW.Tests and upstream SNES.Tests suites are unchanged and remain the
  regression base.
