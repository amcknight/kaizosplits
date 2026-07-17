# SNES.dll Trust & Adoption Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make SNES.dll changes trustworthy (pair-deployment, contract tests, merge-gate runbook), repair three latent contract breaks the investigation surfaced, and merge `spike3-snes-dll` into `main`.

**Architecture:** kaizosplits consumes SNES.dll from the sibling `snes_offsets` repo via ProjectReference. Trust comes from (a) deploying SMW.dll+SNES.dll as an inseparable pair, (b) a reflection contract test that loads the built DLLs exactly the way the .asl files do, and (c) a human-in-the-loop merge-gate checklist using upstream's LiveProbe. Spec: `docs/superpowers/specs/2026-07-14-snes-dll-trust-and-adoption-design.md`.

**Tech Stack:** C# (netstandard2.0 lib, net481 xunit tests), MSBuild, LiveSplit ASL scripts, PowerShell/Git Bash on Windows.

## Global Constraints

- Windows 11 host. Never use `cd /d` or `cd /s`. Repo root: `c:\Users\thedo\git\kaizosplits`. Sibling repos assumed at `c:\Users\thedo\git\snes_offsets` and `c:\Users\thedo\git\LiveSplit`.
- **Do not change split-logic behavior or statement ordering** in `Kaizo.asl` / `Synth.asl` beyond the exact edits shown in Tasks 4–5. Suspicious ordering is load-bearing (see repo memory: delicate split logic).
- The `.asl` reflection contract is: `SNES.Emu` parameterless ctor, `Init(Process)`, `Ready() → bool` (throws = "not ready"), `GetOffset() → long`, `Smc() → string`, `SmcChanged() → bool`. Additive-only evolution.
- All test commands run from repo root unless stated. Test framework is xunit 2.9 via `dotnet test`.
- Commit after each task; commit messages end with `Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>`.

## Pre-existing breaks this plan repairs (context for reviewers)

Found during planning, all pre-dating this branch:

1. `Kaizo.asl:217` calls `s.UndoReasons()` but `Settings.UndoReasons()` was lost in commit `f29f43c` (only stale built DLLs still contain it). Every triggered undo (death after level finish) throws instead of undoing. Task 2 pins it (red), Task 3 restores it (green).
2. `Synth.asl:45` calls `ss.Init(maxLagMs, minStartDurationMs)` but `Settings.Init` has required 3 params since commit `c20facf`. Synth.asl fails at script load. Task 4 fixes.
3. `Synth.asl:152` reads `vars.rec`, which is never assigned (`vars.r` is) — `onReset` throws, `WriteRun()` never runs. Task 4 fixes.

These are behavior-*restoring* fixes (the current behavior is a crash), but flag them to Andrew at review.

---

### Task 1: Pair-copy SNES.dll in CopyToLiveSplit

**Files:**
- Modify: `Components/SMW/SMW/SMW.csproj:21-37` (the `CopyToLiveSplit` target)

**Interfaces:**
- Consumes: build output at `$(TargetDir)` containing `SMW.dll` and `SNES.dll` (already true via ProjectReference).
- Produces: on build with `LiveSplitComponentsDir` set, both DLLs land there as a pair. Later tasks rely on nothing from this task.

- [ ] **Step 1: Replace the single-file copy with a pair copy**

Replace the existing `<Copy …>` / `<Message …>` / `<Warning …>` block inside the `CopyToLiveSplit` target (keep the target's `Name`, `AfterTargets`, `Condition` attributes and the surrounding comments) with:

```xml
    <ItemGroup>
      <!-- SMW.dll and the SNES.dll it was just built against: deploy as a pair
           so LiveSplit can never see a mismatched set. -->
      <_DeployPair Include="$(TargetPath);$(TargetDir)SNES.dll" />
    </ItemGroup>
    <Copy SourceFiles="@(_DeployPair)"
          DestinationFolder="$(LiveSplitComponentsDir)"
          OverwriteReadOnlyFiles="true"
          SkipUnchangedFiles="false"
          Retries="2" RetryDelayMilliseconds="200"
          ContinueOnError="true">
      <Output TaskParameter="CopiedFiles" ItemName="_DeployedDll" />
    </Copy>
    <Message Condition="'@(_DeployedDll->Count())' == '2'" Importance="high"
             Text="Deployed @(_DeployedDll->'%(Filename)%(Extension)', ', ') -> $(LiveSplitComponentsDir)" />
    <Warning Condition="'@(_DeployedDll->Count())' != '2'"
             Text="Deployed only [@(_DeployedDll->'%(Filename)%(Extension)', ', ')] of the SMW.dll+SNES.dll pair: LiveSplit likely has the rest locked. Close LiveSplit and rebuild to deploy the pair." />
```

- [ ] **Step 2: Verify both DLLs deploy to a scratch folder**

Run (Git Bash):
```bash
SCRATCH="$LOCALAPPDATA/Temp/claude/lsdeploy-test" && mkdir -p "$SCRATCH" && rm -f "$SCRATCH"/*.dll
dotnet build Components/SMW/SMW/SMW.csproj -p:LiveSplitComponentsDir="$(cygpath -w "$SCRATCH")"
ls "$SCRATCH"
```
Expected: build succeeds; output contains `Deployed SMW.dll, SNES.dll ->` and `ls` shows `SMW.dll SNES.dll`.

- [ ] **Step 3: Verify the locked-file warning degrades gracefully (no build failure)**

Not automatable cheaply; instead confirm `ContinueOnError="true"` is present on the `<Copy>` and the `<Warning>` fires on `!= '2'`. Visual check only.

- [ ] **Step 4: Commit**

```bash
git add Components/SMW/SMW/SMW.csproj
git commit -m "build: deploy SMW.dll+SNES.dll as a pair to LiveSplit

Root cause of stale-DLL incidents: only SMW.dll was auto-deployed; the
SNES.dll beside it in LiveSplit Components was whatever was copied by
hand last. Deploy the pair from the same build output so they cannot skew.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 2: ContractTests.cs — pin the .asl reflection contract (expect RED)

**Files:**
- Create: `Components/SMW/SMW.Tests/ContractTests.cs`
- Test: same file (`dotnet test --filter ContractTests`)

**Interfaces:**
- Consumes: built `SNES.dll` + `SMW.dll` in the test bin dir (arrive automatically via the SMW.Tests → SMW → SNES ProjectReference chain).
- Produces: the executable statement of the .asl contract. Task 3 makes it green. `AssertMethod(Type, string name, string returnTypeName, params string[] paramTypeNames)` matches on `Type.Name` strings (e.g. `"Int64"`, `"Dictionary`2"`, `"MemoryWatcher"`); `returnTypeName: null` skips the return check.

- [ ] **Step 1: Write the contract test**

Create `Components/SMW/SMW.Tests/ContractTests.cs` with exactly:

```csharp
using System;
using System.IO;
using System.Linq;
using System.Reflection;
using Xunit;

namespace SMW.Tests {

    // Pins the reflection contract that Kaizo.asl and Synth.asl consume from the
    // built SNES.dll + SMW.dll pair. The DLLs are loaded exactly the way the .asl
    // files load them (byte-load + shared AppDomain slot + AssemblyResolve hook),
    // so a failure here is a break the .asl would hit inside LiveSplit.
    //
    // Discipline: when you edit an .asl call site, update the matching assertion
    // here (and vice versa). The lists are hand-maintained, derived from the
    // member accesses actually present in Kaizo.asl / Synth.asl.
    public class ContractTests {

        static readonly Assembly SnesAsm;
        static readonly Assembly SmwAsm;

        static ContractTests() {
            string dir = AppDomain.CurrentDomain.BaseDirectory;
            byte[] snesBytes = File.ReadAllBytes(Path.Combine(dir, "SNES.dll"));
            SnesAsm = Assembly.Load(snesBytes);
            AppDomain.CurrentDomain.SetData("SNES.LatestAssembly", SnesAsm);
            AppDomain.CurrentDomain.AssemblyResolve += (s, a) => {
                if (new AssemblyName(a.Name).Name != "SNES") return null;
                return (Assembly)AppDomain.CurrentDomain.GetData("SNES.LatestAssembly");
            };
            byte[] smwBytes = File.ReadAllBytes(Path.Combine(dir, "SMW.dll"));
            SmwAsm = Assembly.Load(smwBytes);
        }

        static Type SnesType(string name) {
            Type t = SnesAsm.GetType(name);
            Assert.True(t != null, name + " missing from SNES.dll — Activator.CreateInstance in the .asl will break");
            return t;
        }

        static Type SmwType(string name) {
            Type t = SmwAsm.GetType(name);
            Assert.True(t != null, name + " missing from SMW.dll — Activator.CreateInstance in the .asl will break");
            return t;
        }

        // Matches on Type.Name (short) strings so byte-loaded assemblies never
        // need type-identity with the test's compile-time references.
        static void AssertMethod(Type t, string name, string returnTypeName, params string[] paramTypeNames) {
            MethodInfo m = t.GetMethods(BindingFlags.Public | BindingFlags.Instance)
                .FirstOrDefault(x => x.Name == name && x.GetParameters()
                    .Select(p => p.ParameterType.Name).SequenceEqual(paramTypeNames));
            Assert.True(m != null, t.FullName + "." + name + "(" + string.Join(", ", paramTypeNames)
                + ") is missing — an .asl call site will break");
            if (returnTypeName != null) {
                Assert.True(m.ReturnType.Name == returnTypeName, t.FullName + "." + name
                    + " returns " + m.ReturnType.Name + "; the .asl expects " + returnTypeName);
            }
        }

        static void AssertReadable(Type t, string name) {
            bool ok = t.GetField(name) != null
                || (t.GetProperty(name) != null && t.GetProperty(name).CanRead);
            Assert.True(ok, t.FullName + "." + name + " (read by an .asl) is missing");
        }

        static void AssertWritable(Type t, string name) {
            bool ok = t.GetField(name) != null
                || (t.GetProperty(name) != null && t.GetProperty(name).CanWrite);
            Assert.True(ok, t.FullName + "." + name + " (written by an .asl) is missing or read-only");
        }

        [Fact]
        public void AllAslTypesConstruct() {
            // startup{} does Activator.CreateInstance on each of these.
            Assert.NotNull(Activator.CreateInstance(SnesType("SNES.Emu")));
            Assert.NotNull(Activator.CreateInstance(SmwType("SMW.Timer")));
            Assert.NotNull(Activator.CreateInstance(SmwType("SMW.Debugger")));
            Assert.NotNull(Activator.CreateInstance(SmwType("SMW.Settings")));
            Assert.NotNull(Activator.CreateInstance(SmwType("SMW.Watchers")));
            Assert.NotNull(Activator.CreateInstance(SmwType("SMW.Recorder")));
        }

        [Fact]
        public void Emu_AslContract() {
            Type e = SnesType("SNES.Emu");
            AssertMethod(e, "Init", "Void", "Process");
            AssertMethod(e, "Ready", "Boolean");
            AssertMethod(e, "GetOffset", "Int64");
            AssertMethod(e, "Smc", "String");
            AssertMethod(e, "SmcChanged", "Boolean");
        }

        [Fact]
        public void Emu_ReadyThrowsWhenUnattached() {
            // The .asl's readiness signal is "Ready() threw", not its return value.
            Type t = SnesType("SNES.Emu");
            object e = Activator.CreateInstance(t);
            MethodInfo ready = t.GetMethod("Ready", Type.EmptyTypes);
            var ex = Assert.Throws<TargetInvocationException>(() => ready.Invoke(e, null));
            Assert.NotNull(ex.InnerException);
        }

        [Fact]
        public void Timer_AslContract() {
            Type t = SmwType("SMW.Timer");
            AssertMethod(t, "HistEnd", "Void");
            AssertMethod(t, "HistMid", "Void");
            AssertMethod(t, "ToString", "String");
        }

        [Fact]
        public void Debugger_AslContract() {
            Type d = SmwType("SMW.Debugger");
            AssertMethod(d, "Update", "Void", "Watchers");
            AssertMethod(d, "HasLines", "Boolean");
            AssertMethod(d, "ClearLines", "String");
            AssertMethod(d, "Dbg", "Void", "String");
            AssertMethod(d, "DbgOnce", null, "Exception");
            AssertMethod(d, "DbgOnce", null, "String", "Object");
            AssertMethod(d, "Monitor", "Void", "MemoryWatcher", "Watchers");
        }

        [Fact]
        public void Settings_AslContract() {
            Type s = SmwType("SMW.Settings");
            AssertMethod(s, "Init", "Void", "Int64", "Int64", "Int64");
            AssertMethod(s, "UsedMemory", "String[]");
            AssertMethod(s, "Update", "Void", "Dictionary`2", "Watchers");
            AssertMethod(s, "StartStatus", "Boolean", "Int64");
            AssertMethod(s, "StartReasons", "String");
            AssertMethod(s, "ResetStatus", "Boolean", "Boolean", "Boolean");
            AssertMethod(s, "ResetReasons", "String", "Boolean", "Boolean");
            AssertMethod(s, "UndoStatus", "Boolean");
            AssertMethod(s, "UndoReasons", "String");
            AssertMethod(s, "SplitStatus", "Boolean");
            AssertMethod(s, "SplitReasons", "String");
            AssertMethod(s, "SkipStatus", "Boolean", "Int64");
            AssertMethod(s, "SkipReasons", "String", "Int64");
            AssertMethod(s, "BlockedReasons", "String");
            AssertReadable(s, "entries");
            AssertReadable(s, "keys");
            AssertWritable(s, "credits");
            AssertWritable(s, "block");
            AssertWritable(s, "other");
            AssertWritable(s, "lastSplitTime");
        }

        [Fact]
        public void Watchers_AslContract() {
            Type w = SmwType("SMW.Watchers");
            AssertMethod(w, "Init", "Void", "String[]");
            AssertMethod(w, "SetMemoryOffset", "Void", "Int64", "Dictionary`2");
            // UpdateAll is inherited from LiveSplit's MemoryWatcherList; return
            // type not pinned (owned upstream in LiveSplit, not by us).
            AssertMethod(w, "UpdateAll", null, "Process");
            AssertMethod(w, "UpdateState", "Void");
            AssertMethod(w, "Curr", "UInt32", "MemoryWatcher");
            AssertMethod(w, "Prev", "UInt32", "MemoryWatcher");
            AssertMethod(w, "Stepped", "Boolean", "MemoryWatcher");
            AssertMethod(w, "ShiftTo", "Boolean", "MemoryWatcher", "UInt32");
            AssertMethod(w, "ShiftIn", "Boolean", "MemoryWatcher", "UInt32", "MemoryWatcher", "UInt32", "UInt32");
            AssertMethod(w, "ShiftToIn", "Boolean", "MemoryWatcher", "UInt32", "MemoryWatcher", "UInt32");
            foreach (string name in new[] {
                "levelNum", "roomNum", "exitMode", "cpEntrance", "midway", "io",
                "submap", "overworldTile", "yoshiCoin", "moonCounter", "gameMode",
                "CPEntrance", "Room", "EnterDoor", "GmFadeToLevel", "GotGoal",
            }) {
                AssertReadable(w, name);
            }
        }

        [Fact]
        public void Recorder_AslContract() {
            Type r = SmwType("SMW.Recorder");
            AssertMethod(r, "Init", "Void", "String");
            AssertMethod(r, "StartReasons", "Void", "String");
            AssertMethod(r, "ResetReasons", "Void", "String");
            AssertMethod(r, "WriteRun", "Void");
        }
    }
}
```

- [ ] **Step 2: Run and verify the expected RED**

Run: `dotnet test Components/SMW/SMW.Tests/SMW.Tests.csproj --filter ContractTests`
Expected: **`Settings_AslContract` FAILS** with `SMW.Settings.UndoReasons() is missing — an .asl call site will break` (pre-existing break #1). All other ContractTests facts PASS. If anything else fails, stop and investigate before proceeding — the lists above were derived from source on 2026-07-14.

- [ ] **Step 3: Sanity-check the harness detects drift**

Temporarily change `"GetOffset"` to `"GetOffzet"` in `Emu_AslContract`, rerun the filter, confirm `Emu_AslContract` FAILS with the "is missing" message, then revert the edit. Expected after revert: only `Settings_AslContract` red.

- [ ] **Step 4: Commit (red is intentional and documented)**

```bash
git add Components/SMW/SMW.Tests/ContractTests.cs
git commit -m "test: pin the .asl reflection contract against the built DLL pair

Loads SNES.dll+SMW.dll exactly the way the .asl files do (byte-load,
AppDomain slot, resolve hook) and asserts every member the .asl touches.
Settings_AslContract is intentionally red: it exposes the pre-existing
loss of Settings.UndoReasons() (f29f43c); restored in the next commit.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 3: Restore Settings.UndoReasons() (contract test goes GREEN)

**Files:**
- Modify: `Components/SMW/SMW/Settings.cs` (immediately after the `UndoStatus()` method, which starts at line 210)

**Interfaces:**
- Consumes: `Settings_AslContract` red assertion from Task 2.
- Produces: `public string UndoReasons()` on `SMW.Settings`, called by `Kaizo.asl:217` as `d.Dbg("Undo: " + s.UndoReasons())`.

- [ ] **Step 1: Add the method**

In `Components/SMW/SMW/Settings.cs`, directly after the closing brace of `UndoStatus()`, add:

```csharp
        public string UndoReasons() {
            // UndoStatus() has exactly one trigger: a death after the level was
            // already finished (goal/orb/key/boss/palace).
            return "DiedAfterFinish";
        }
```

- [ ] **Step 2: Run the contract tests to verify GREEN**

Run: `dotnet test Components/SMW/SMW.Tests/SMW.Tests.csproj --filter ContractTests`
Expected: all ContractTests facts PASS.

- [ ] **Step 3: Run the full suite to verify no collateral damage**

Run: `dotnet test Components/SMW/SMW.Tests/SMW.Tests.csproj`
Expected: PASS (same pass count as on `main` plus the new ContractTests facts).

- [ ] **Step 4: Commit**

```bash
git add Components/SMW/SMW/Settings.cs
git commit -m "fix: restore Settings.UndoReasons() lost in f29f43c

Kaizo.asl's undo path calls s.UndoReasons(); since f29f43c the method
existed only in stale built DLLs, so every triggered undo threw a
binder exception instead of undoing the split.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 4: Repair Synth.asl latent breakage

**Files:**
- Modify: `Synth.asl:15-16` (startup constants), `Synth.asl:45` (`ss.Init` call), `Synth.asl:152` (`vars.rec`)

**Interfaces:**
- Consumes: `Settings.Init(long, long, long)` (existing, pinned by Task 2).
- Produces: a Synth.asl whose startup and onReset can actually execute. No other .asl lines change.

- [ ] **Step 1: Fix the `ss.Init` arity**

In `Synth.asl`, after the line `int minStartDurationMs = 1000;` add:

```csharp
    int minSplitCooldownMs = 500; // matches Kaizo.asl; inert here (Synth's split{} is empty)
```

and change:

```csharp
    vars.ss.Init(maxLagMs, minStartDurationMs);
```
to:
```csharp
    vars.ss.Init(maxLagMs, minStartDurationMs, minSplitCooldownMs);
```

- [ ] **Step 2: Fix the `vars.rec` typo in onReset**

Change (in `onReset`):
```csharp
    var r = vars.rec;
```
to:
```csharp
    var r = vars.r;
```

- [ ] **Step 3: Verify no other `vars.rec` references remain**

Run: `grep -n "vars.rec" Synth.asl`
Expected: no output.

- [ ] **Step 4: Commit**

```bash
git add Synth.asl
git commit -m "fix: Synth.asl startup and onReset never worked post-c20facf

ss.Init has required three params since c20facf (Synth passed two:
binder error at script load), and onReset read vars.rec which was never
assigned (vars.r is), so WriteRun() could never fire. Behavior-restoring:
the previous behavior was a crash.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 5: DLL identity log lines in both .asl startup blocks

**Files:**
- Modify: `Kaizo.asl` (startup, after `Assembly asm = Assembly.Load(bytes);`, line 38)
- Modify: `Synth.asl` (startup, after `Assembly asm = Assembly.Load(bytes);`, line 37 pre-Task-4 numbering)

**Interfaces:**
- Consumes: `snesAsm` / `asm` locals already in scope in both startup blocks.
- Produces: log lines in LiveSplit's debug output answering "is this an old dll?" at a glance. Additive only — no control-flow changes.

- [ ] **Step 1: Add the two print lines to Kaizo.asl**

Immediately after `Assembly asm = Assembly.Load(bytes);` in `Kaizo.asl`, add:

```csharp
    // Staleness check: byte-loads refresh only on script reload — restart
    // LiveSplit after a rebuild, then confirm these timestamps moved.
    print("Kaizo.asl: loaded SNES.dll v" + snesAsm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SNES.dll"));
    print("Kaizo.asl: loaded SMW.dll v" + asm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SMW.dll"));
```

- [ ] **Step 2: Add the same lines to Synth.asl**

Immediately after `Assembly asm = Assembly.Load(bytes);` in `Synth.asl`, add the same block with `Synth.asl:` prefixes:

```csharp
    // Staleness check: byte-loads refresh only on script reload — restart
    // LiveSplit after a rebuild, then confirm these timestamps moved.
    print("Synth.asl: loaded SNES.dll v" + snesAsm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SNES.dll"));
    print("Synth.asl: loaded SMW.dll v" + asm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SMW.dll"));
```

- [ ] **Step 3: Verify the diff is additive-only**

Run: `git diff --stat Kaizo.asl Synth.asl && git diff Kaizo.asl Synth.asl | grep -c "^-[^-]"`
Expected: the grep count of removed lines is `0` for this task's diff (Task 4's Synth edits were already committed).

- [ ] **Step 4: Commit**

```bash
git add Kaizo.asl Synth.asl
git commit -m "feat: log loaded DLL versions and file times at .asl startup

Makes 'is this an old dll?' a one-glance check in the debug log instead
of a guess. Additive log lines only; no control-flow changes.

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

**Runtime verification** happens in Task 8's LiveSplit session (the .asl cannot be executed outside LiveSplit).

---

### Task 6: Merge-gate runbook + live-matrix combo list

**Files:**
- Create: `docs/merge-gate.md`
- Create: `docs/merge-gate-combos.yaml`

**Interfaces:**
- Consumes: LiveProbe CLI from snes_offsets: `SNES.LiveProbe.exe <process-name-without-exe | pid:N> [timeout-seconds] [watch]`, exit code 0 = resolved (prints `WRAM base = 0x…`), 1 = failed to resolve, 2 = usage error.
- Produces: the checklist Task 8 executes; the standing gate for all future SNES.dll bumps.

- [ ] **Step 1: Write `docs/merge-gate-combos.yaml`**

```yaml
# Live matrix for the SNES.dll merge gate (see docs/merge-gate.md).
# Edit to match the local library. Dropping a failing combo is a reviewed
# decision recorded in the merge commit/PR — not a shrug.
emulators:
  - name: snes9x
    process: snes9x-x64
  - name: retroarch
    process: retroarch
    core: snes9x_libretro 1.63 (185488c)
  - name: bsnes
    process: bsnes
roms:
  # Any ~5 from the local hack library; these match existing split configs.
  - JUMP
  - Jono Hack
  - Ninji Story
  - Bunbun World
  - Yoshi's Revenge
```

- [ ] **Step 2: Write `docs/merge-gate.md`**

```markdown
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
    cpEntrance/levelNum watcher lines -> Start -> Split -> Reset

(Reference capture: JUMP.smc on retroarch, 2026-07-14.)

## 4. Verdict

All green -> merge. Any FAIL -> fix or explicitly drop the combo from the
YAML with a note in the merge commit explaining why.
```

- [ ] **Step 3: Commit**

```bash
git add docs/merge-gate.md docs/merge-gate-combos.yaml
git commit -m "docs: merge-gate runbook + live-matrix combo list for SNES.dll bumps

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 7: CLAUDE.md ownership convention

**Files:**
- Create: `CLAUDE.md` (repo root — none exists today)

**Interfaces:**
- Consumes: nothing.
- Produces: standing instructions for future agent sessions in this repo.

- [ ] **Step 1: Write `CLAUDE.md`**

```markdown
# kaizosplits — project instructions

## SNES.dll is ours

SNES.dll's source of truth is the sibling repo `../snes_offsets` (agents may
push its main directly — see that repo's CLAUDE.md). When work here reveals
friction below the WRAM seam — attach, liveness, ROM identity, raw reads —
improve it upstream instead of working around it here. If upstream can't take
it now, leave a `TODO(snes_offsets):` marker rather than silently absorbing
the workaround.

Boundary: **SNES.dll owns** "where is this game's WRAM right now, across any
emulator/core/version — reliable bytes and liveness/identity signals."
**kaizosplits owns** watcher construction, split semantics, timer policy, and
LiveSplit deployment.

## SNES.dll changes: merge gate

Any change that bumps the consumed SNES.dll (or this repo's contract with it)
goes through `docs/merge-gate.md` before merging to main. The .asl reflection
contract is pinned by `Components/SMW/SMW.Tests/ContractTests.cs` — edit an
.asl call site and that file together.

## Delicate split logic

Preserve behavior exactly when refactoring `Kaizo.asl` and the Settings/
Watchers split path; suspicious ordering is often load-bearing.

## Version pinning: deliberately deferred

kaizosplits consumes SNES.dll via sibling-checkout ProjectReference (fluid,
unpinned) while both repos are ours and userless. Revisit when a consumer
outside these two repos appears, or the repos need to move independently —
then pick ONE mechanism (likely a pinned built artifact), not layered safety.
(Decision record: docs/superpowers/specs/2026-07-14-snes-dll-trust-and-adoption-design.md §6.)
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "docs: ownership convention — SNES.dll is ours, improve it upstream

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
```

---

### Task 8: Run the merge gate and merge to main (HUMAN-GATED)

**Files:**
- No file changes except the merge itself.

**Interfaces:**
- Consumes: everything above; Andrew at the keyboard for emulator launches and the LiveSplit session.

- [ ] **Step 1: Run both test suites**

```bash
dotnet test Components/SMW/SMW.sln
dotnet test ../snes_offsets/src/SNES.Tests/SNES.Tests.csproj
```
Expected: PASS, PASS.

- [ ] **Step 2: Live matrix with Andrew (cannot be done by an agent alone)**

Follow `docs/merge-gate.md` §0–§3 with Andrew driving emulators. Record each combo's PASS/FAIL. This step also verifies Task 5's startup log lines and (via a Synth layout, if available) Task 4's repairs.

- [ ] **Step 3: Merge via the finishing skill**

On an all-green gate, use **superpowers:finishing-a-development-branch** to merge `spike3-snes-dll` into `main` (present Andrew the standard merge/PR options).

---

## Self-review notes

- Spec coverage: §1 boundary → Tasks 6–7 docs; §2 CLAUDE.md → Task 7; §3 deployment → Tasks 1, 5; §4 contract test → Tasks 2–3; §5 gate → Tasks 6, 8; §6 pinning deferral → Task 7 (recorded in CLAUDE.md + spec); §7 follow-ups → recorded in spec, no tasks (by design). The three latent-break repairs (Tasks 3–4) are additions the spec didn't know about, surfaced while deriving the contract lists; they are prerequisites for an honest green gate.
- Type consistency: contract-test name strings were derived from source greps on 2026-07-14 (`Settings.cs`, `Watchers.cs`, `Debugger.cs`, `Timer.cs`, `Synth/Recorder.cs`, upstream `Emu.cs:324-470`). `UpdateAll` return type deliberately unpinned (owned by LiveSplit).
- Placeholders: none; every step has literal code/commands and expected output.
