# SNES.dll from the consumer side — handoff notes for snes_offsets

**Audience:** snes_offsets docs and the Claude Code instances working there.

## Open requests from kaizosplits

Both were prototyped against snes_offsets HEAD on 2026-07-16 (full suite
green, 93/93, including a new test) and then reverted — kaizosplits doesn't
edit snes_offsets; it asks. The diffs below are known-good.

### R1: `ResolveFromTable` zero-deref message prints a type name

`src/SNES/Emu.cs` (~line 577, retroarch path) interpolates the `DeepPointer`
object itself, producing
`No memory offset found for 'snes9x_libretro.dll' at 'LiveSplit.ComponentUtil.DeepPointer'`
(observed live). Suggested wording:
`"No memory offset found for '" + _core + "': core pointer for '" + coreKey + "' dereferenced to 0"`.
Note the method's header comment says it mirrors the retired kaizosplits
messages *exactly* — this needs a deliberate, commented exception.

### R2: lift the retry cooldown when the SMC changes

Observed live (RetroArch, close content → open new ROM): discovery failures
while no content was loaded arm `RetryCooldownMs`; the log then shows the
`SMC:` name flip to the new ROM — so SNES.dll *knew* new content arrived —
yet the next attempt still sat out a cooldown armed during the no-ROM era.
Suggested change: when `_smc` changes in `UpdateSmcFromTable`, clear
`_lastFailure` (under `_gate`; same idea as the vanish path already clearing
it). Test sketch, in `EmuTests` house style: `DiscoverOverride` throws →
cooldown armed → simulate the SMC change → assert the next `GetOffset()`
scans immediately instead of throwing "retrying" (uses the `NowMs` seam and
`PollGetOffset`).
**Source:** lessons from kaizosplits' `spike3-snes-dll` branch (first real
consumer of the two-assembly load), 2026-07. Andrew plans a suite of LiveSplit
plugins all consuming SNES.dll, so these constraints will apply to every
future consumer, not just kaizosplits.

## 1. The hosting environment every plugin consumer shares

LiveSplit ASL scripts impose constraints the DLL's design should assume:

- **Byte-loading is the norm.** Scripts load DLLs via `File.ReadAllBytes` +
  `Assembly.Load(bytes)` so the files stay unlocked and can be redeployed
  while LiveSplit runs. Consequence: byte-loaded assemblies are invisible to
  normal CLR probing, so any assembly that *references* SNES.dll needs an
  `AssemblyResolve` hook to hand back the already-loaded instance.
- **One AppDomain, many scripts, stacking handlers.** All ASL scripts in a
  LiveSplit process share one AppDomain. Each script reload re-runs `startup`
  and registers another `AssemblyResolve` handler; old lambdas can't be
  unsubscribed. First non-null handler wins, so handlers must not capture
  their own assembly reference in a closure.
- **Reflection only.** ASL scripts hold instances as `dynamic` via
  `Activator.CreateInstance(asm.GetType("SNES.Emu"))`. There is no
  compile-time check anywhere in a consumer script.

## 2. The canonical consumer load pattern (treat as public contract)

Every consumer uses this boilerplate (see `Kaizo.asl` / `Synth.asl`
`startup`):

```csharp
byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
Assembly snesAsm = Assembly.Load(snesBytes);
AppDomain.CurrentDomain.SetData("SNES.LatestAssembly", snesAsm);
AppDomain.CurrentDomain.AssemblyResolve += (s, a) => {
    if (new AssemblyName(a.Name).Name != "SNES") return null;
    return (Assembly)AppDomain.CurrentDomain.GetData("SNES.LatestAssembly");
};
```

All handlers — stale ones from reloads, and ones from other scripts — read
the same `"SNES.LatestAssembly"` slot, which each `startup` overwrites, so
the newest load deterministically wins regardless of handler order.

Contract implications for snes_offsets:

- The assembly's **simple name `SNES`** and the slot key
  **`"SNES.LatestAssembly"`** are effectively public API. Renaming either
  breaks every deployed consumer's boilerplate.
- **Last-startup-wins means one process = one SNES.dll.** All plugins in a
  LiveSplit install must byte-load the *identical* deployed file. Two plugins
  shipping different SNES.dll builds would silently impose one build on the
  other (type mismatch / behavior skew). Until pinning exists (§5), the
  invariant is "one deployed `Components/SNES.dll` per LiveSplit install."

## 3. The reflection contract surface

Because consumers bind by reflection at runtime, an upstream signature change
fails in LiveSplit at run time, not at build time. kaizosplits pins the
surface it uses in `Components/SMW.Tests/ContractTests.cs`, which loads the
DLLs exactly the way the .asl does (byte-load + slot + resolve hook) and
asserts member shapes via reflection.

What upstream should treat as compatibility surface:

- `SNES.Emu`: parameterless ctor, `Init(Process)`, `Ready()`,
  `GetOffset() → long`, `Smc() → string`, `SmcChanged() → bool`.
- **Exceptions are the "not ready" signal**: `Ready()` throws rather than
  returns false when unattached. Consumers wrap calls in try/catch as
  liveness detection. This is contract semantics until Phase 0
  (`State`/`Generation`/`Status()`) ships and consumers migrate.
- Additive changes are safe; renames/removals/signature changes need a
  coordinated bump through the consumer's merge gate
  (kaizosplits: `docs/merge-gate.md`).

Recommendation for a plugin *suite*: each consumer repo should carry its own
ContractTests-style pin of the members it actually calls, so `dotnet test`
goes red before LiveSplit goes mysterious.

## 4. Deployment & staleness

- Byte-loads refresh **only on script reload** (in practice: restart
  LiveSplit). Redeploying the file while running succeeds but changes
  nothing until reload.
- Consumers should log assembly version + file last-write time at `startup`
  (Kaizo.asl does). Upstream can help by keeping `AssemblyVersion`
  meaningful (bump on every published change) so the log line actually
  discriminates builds.
- SNES.dll and any assembly referencing it (e.g. SMW.dll) must be deployed
  as a **coherent pair from the same build output** — a skewed pair was the
  root cause of a real "old dll" incident.

## 5. Versioning: fluid now, one mechanism later

Consumption is via sibling-checkout ProjectReference, deliberately unpinned
while both repos are Andrew's and userless. Written-down revisit trigger: a
third consumer repo appears, or the repos need to move independently. Then
pick **one** mechanism (likely a pinned built artifact — local NuGet feed or
committed DLL with recorded upstream commit), not layered safety.
(Decision record: `docs/superpowers/specs/2026-07-14-snes-dll-trust-and-adoption-design.md` §6.)
The planned plugin suite makes this trigger likely to fire — a suite is
"multiple consumers" the moment two plugins can't rebuild in lockstep.

## 6. Known SMW-specificity (already tracked upstream)

The liveness witness cells (`$13/$14/$0100`) are the one SMW-specific part of
an otherwise game-agnostic assembly; generalizing them is tracked upstream
(SA-1 / ROM-anchor B4). The assembly name stays `SNES` — don't bake the
temporary limitation into the identity.
