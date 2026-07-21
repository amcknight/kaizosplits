# SNES.dll merge gate

Run this before merging any branch that bumps the consumed SNES.dll (or
changes this repo's contract with it). It takes ~15 minutes, most of it
launching emulators.

## 0. Fresh pair deployed

- Rebuild: `dotnet build Components/SMW/SMW.sln`
- **Restart LiveSplit** — byte-loaded DLLs refresh only on script reload.
- Confirm Kaizo.asl's startup log line shows today's timestamps for both
  DLLs.

## 1. Test suites green (both repos)

- `dotnet test Components/SMW/SMW.sln` (includes ContractTests — the
  executable form of the .asl reflection contract)
- `dotnet test ../snes_offsets/src/SNES.Tests/SNES.Tests.csproj`

## 2. Live matrix (semi-automated)

Build the probe once: `dotnet build ../snes_offsets/src/SNES.LiveProbe/SNES.LiveProbe.csproj`

Combos: {snes9x-x64, bsnes, retroarch + snes9x_libretro core} x ~5 hacks
from the local library (e.g. JUMP, Jono Hack, Ninji Story, Bunbun World,
Yoshi's Revenge). Dropping a failing combo is a reviewed decision recorded
in the merge commit — not a shrug.

For each combo:
1. Launch the emulator, load the ROM, get in-game (past the title screen).
2. Run:
   `../snes_offsets/src/SNES.LiveProbe/bin/Debug/net481/SNES.LiveProbe.exe <process> 30`
3. PASS = exit code 0 and a `WRAM base = 0x…` line. Record the result.

Poke at anything you're suspicious of while the emulator is up (savestates,
resets, ROM swaps) and re-run the probe after.

## 3. One real LiveSplit session

On one combo, verify the known-good sequence in LiveSplit's debug output
(DebugView or VS attach):

    Connected to game -> SMC: <rom>.smc -> WRAM discovery in progress ->
    WRAM found at 0x… -> cpEntrance/levelNum watcher lines ->
    Start -> Split -> Reset

(Reference capture: JUMP.smc on retroarch, 2026-07-14.)

## 4. Verdict

All green -> merge. Any FAIL -> fix, or explicitly drop the combo from the
list above with a note in the merge commit explaining why.

## Run record — SNES.dll 1.2.0+c3470e48 (2026-07-18)

Suites green (145+124). Live: mesen PASS; retroarch+snes9x (no run-ahead)
fully green incl. Start/Split/Reset and the R2 SMC-swap check;
**retroarch+bsnes FAIL** (run-ahead burst decoy defeats arbitration) —
dropped pending snes_offsets 1.2.1; run-ahead configs generally are the
known gap. Full evidence: docs/snes-dll-consumer-notes.md (local).

Merge-commit sentence to carry per §4: "Gate: bsnes and run-ahead combos
dropped this round — arbitration mispicks run-ahead WRAM copies (R3/R8 in
consumer notes, upstream fix targeted for 1.2.1); verified matrix is
no-run-ahead RetroArch+snes9x and Mesen (snes9x-x64 standalone untested
this round)."

## Run record — SNES.dll 1.3.0+0e2363fe (2026-07-20/21, partial)

Suites green (147+138). Live: bsnes-core matrix fully green — no-run-ahead,
run-ahead in-level (**R3 closed**, committed base provenance-verified),
title-screen fresh discovery ×2, mid-session reconnect (after the consumer
Watchers rebind fix); uncovered standalones both discovered and split
(bsnes nightly 2026-05-23, snes9x-x64 1.63) — first-ever uncovered-build
passes; mesen green incl. the Agnosthesia witness-margin test (gfx 61/64
in-level). Dropped this round, run next session: retroarch+snes9x baseline
and +run-ahead title screen (R8 remains upstream-open), SMC-flip poke,
bsnes 115 standalone. Correctness unblemished; discovery latency (7–20 s,
region-serialized scan) is the v1.4 priority — full evidence and timing
tables: docs/snes-dll-consumer-notes.md.
