# SNES.dll merge gate

Run this before merging any branch that bumps the consumed SNES.dll (or
changes this repo's contract with it). It takes ~15 minutes, most of it
launching emulators. Combos live in `merge-gate-combos.yaml`.

## 0. Fresh pair deployed

- Rebuild: `dotnet build Components/SMW/SMW.sln`
- **Restart LiveSplit** — byte-loaded DLLs refresh only on script reload.
- Confirm the startup log shows today's "modified" timestamps for both
  `SNES.dll` and `SMW.dll` (Kaizo.asl prints them).

## 1. Test suites green (both repos)

- `dotnet test Components/SMW/SMW.sln` (includes ContractTests — the
  executable form of the .asl reflection contract)
- `dotnet test ../snes_offsets/src/SNES.Tests/SNES.Tests.csproj`

## 2. Live matrix (semi-automated)

Build the probe once: `dotnet build ../snes_offsets/src/SNES.LiveProbe/SNES.LiveProbe.csproj`

For each emulator x ROM combo in `merge-gate-combos.yaml`:
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

All green -> merge. Any FAIL -> fix or explicitly drop the combo from the
YAML with a note in the merge commit explaining why.
