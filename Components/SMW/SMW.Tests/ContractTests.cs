using System;
using System.IO;
using System.Linq;
using System.Reflection;
using Xunit;

namespace SMW.Tests {

    // Pins the reflection contract that Kaizo.asl consumes from the built
    // SNES.dll + SMW.dll pair. The DLLs are loaded exactly the way the .asl
    // loads them (byte-load + shared AppDomain slot + AssemblyResolve hook),
    // so a failure here is a break the .asl would hit inside LiveSplit.
    //
    // Discipline: when you edit an .asl call site, update the matching assertion
    // here (and vice versa). The lists are hand-maintained, derived from the
    // member accesses actually present in Kaizo.asl.
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
            // (t.ToString() is also called; Object.ToString always satisfies it.)
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
            // Dormant run-recording experiment: the Synth.asl shell was deleted;
            // SMW.Recorder and this pin are kept so a regenerated shell binds
            // unchanged.
            Type r = SmwType("SMW.Recorder");
            AssertMethod(r, "Init", "Void", "String");
            AssertMethod(r, "StartReasons", "Void", "String");
            AssertMethod(r, "ResetReasons", "Void", "String");
            AssertMethod(r, "WriteRun", "Void");
        }
    }
}
