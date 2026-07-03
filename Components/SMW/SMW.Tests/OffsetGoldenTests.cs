using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using LiveSplit.ComponentUtil;
using SNES;
using Xunit;

namespace SMW.Tests {
    // Pins down every entry currently in SNES.Offset so the colocation refactor
    // can be verified against an authoritative snapshot. If you intentionally
    // add or remove an emulator build, update both the Offset table AND the
    // expectation here.
    public class OffsetGoldenTests {

        // --- DeepPointer decode helper ---

        private struct Dp {
            public string Module;
            public int Base;
            public int[] Offsets;
        }

        private static Dp Decode(DeepPointer dp) {
            var t = typeof(DeepPointer);
            var module = (string)t.GetField("_module", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(dp);
            var base_ = (int)t.GetField("_base", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(dp);
            var offsetsObj = t.GetField("_offsets", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(dp);
            int[] offsets;
            if (offsetsObj is List<int> list) {
                offsets = list.ToArray();
            } else if (offsetsObj is int[] arr) {
                offsets = arr;
            } else {
                // Fallback: enumerate as IEnumerable<int>
                offsets = ((System.Collections.IEnumerable)offsetsObj).Cast<int>().ToArray();
            }
            return new Dp { Module = module, Base = base_, Offsets = offsets };
        }

        private static Dp Dpt(string module, int base_, params int[] offsets) {
            // DeepPointer prepends a leading 0 in InitializeOffsets, so the
            // expected _offsets is [0, ...declared offsets].
            var actualOffsets = new int[offsets.Length + 1];
            actualOffsets[0] = 0;
            offsets.CopyTo(actualOffsets, 1);
            return new Dp { Module = module, Base = base_, Offsets = actualOffsets };
        }

        private static void AssertDp(string key, Dp expected, Dp actual) {
            Assert.True(expected.Module == actual.Module,
                $"[{key}] module: expected '{expected.Module}', got '{actual.Module}'");
            Assert.True(expected.Base == actual.Base,
                $"[{key}] base: expected 0x{expected.Base:X}, got 0x{actual.Base:X}");
            Assert.True(expected.Offsets.SequenceEqual(actual.Offsets),
                $"[{key}] offsets: expected [{string.Join(",", expected.Offsets.Select(o => $"0x{o:X}"))}], " +
                $"got [{string.Join(",", actual.Offsets.Select(o => $"0x{o:X}"))}]");
        }

        // --- version: module size -> version string ---

        private static readonly Dictionary<int, string> ExpectedVersion = new Dictionary<int, string> {
            { 15675392, "1.9.4"   },
            { 16793600, "1.16.0"  },
            { 17264640, "1.17.0"  },
            { 18350080, "1.21.0"  },
            { 20008960, "1.22.2"  },
            {  6991872, "1.57"    },
            {  9027584, "1.60"    },
            {  9158656, "1.61"    },
            { 10399744, "1.62.3"  },
            { 12537856, "1.59.2"  },
            { 12836864, "1.60"    },
            { 12955648, "1.61"    },
            { 29069312, "1.62"    },
            { 15474688, "1.62.3"  },
            {  9646080, "1.60"    },
            { 13565952, "1.60"    },
            { 10096640, "107"     },
            { 10338304, "107.1"   },
            { 47230976, "107.2"   },
            {131543040, "110"     },
            { 51924992, "111"     },
            { 52056064, "112"     },
            { 52477952, "115"     },
            { 16019456, "106"     },
            { 15360000, "106.112" },
            { 22388736, "107"     },
            { 23142400, "108"     },
            { 23166976, "109"     },
            { 23224320, "110"     },
            {  7061504, "2.3"     },
            {  7249920, "2.3.1"   },
            {  6938624, "2.3.2"   },
        };

        [Fact]
        public void Version_MatchesExpectedExactly() {
            Assert.Equal(ExpectedVersion.Count, Offset.version.Count);
            foreach (var kv in ExpectedVersion) {
                Assert.True(Offset.version.ContainsKey(kv.Key),
                    $"missing version key {kv.Key}");
                Assert.Equal(kv.Value, Offset.version[kv.Key]);
            }
        }

        // --- mem: emuKey -> direct address ---

        private static readonly Dictionary<string, long> ExpectedMem = new Dictionary<string, long> {
            { "higan 106",     0x94D144     },
            { "higan 106.112", 0x8AB144     },
            { "higan 107",     0xB0ECC8     },
            { "higan 108",     0xBC7CC8     },
            { "higan 109",     0xBCECC8     },
            { "higan 110",     0xBDBCC8     },
            { "bsnes 107",     0x72BECC     },
            { "bsnes 107.1",   0x762F2C     },
            { "bsnes 107.2",   0x765F2C     },
            { "bsnes 107.3",   0x765F2C     },
            { "bsnes 110",     0xA9BD5C     },
            { "bsnes 111",     0xA9DD5C     },
            { "bsnes 112",     0xAAED7C     },
            { "bsnes 115",     0xB16D7C     },
            { "emuhawk 2.3",   0x36F11500240 },
            { "emuhawk 2.3.1", 0x36F11500240 },
            { "emuhawk 2.3.2", 0x36F11500240 },
        };

        [Fact]
        public void Mem_MatchesExpectedExactly() {
            Assert.Equal(ExpectedMem.Count, Offset.mem.Count);
            foreach (var kv in ExpectedMem) {
                Assert.True(Offset.mem.ContainsKey(kv.Key),
                    $"missing mem key '{kv.Key}'");
                Assert.Equal(kv.Value, Offset.mem[kv.Key]);
            }
        }

        // --- memPtr ---

        private static readonly Dictionary<string, Dp> ExpectedMemPtr = new Dictionary<string, Dp> {
            { "snes9x 1.60",       Dpt("snes9x.exe",     0x54DB54, 0x0) },
            { "snes9x 1.61",       Dpt("snes9x.exe",     0x507BC4, 0x0) },
            { "snes9x 1.62.3",     Dpt("snes9x.exe",      0x12698, 0x0) },
            { "snes9x-x64 1.59.2", Dpt("snes9x-x64.exe",  0x8D86F8, 0x0) },
            { "snes9x-x64 1.60",   Dpt("snes9x-x64.exe",  0x8D86F8, 0x0) },
            { "snes9x-x64 1.61",   Dpt("snes9x-x64.exe",  0x883158, 0x0) },
            { "snes9x-x64 1.62",   Dpt("snes9x-x64.exe", 0x1758D40, 0x0) },
            { "snes9x-x64 1.62.2", Dpt("snes9x-x64.exe",  0xA62390, 0x0) },
            { "snes9x-x64 1.62.3", Dpt("snes9x-x64.exe",  0xA62390, 0x0) },
        };

        [Fact]
        public void MemPtr_MatchesExpectedExactly() {
            Assert.Equal(ExpectedMemPtr.Count, Offset.memPtr.Count);
            foreach (var kv in ExpectedMemPtr) {
                Assert.True(Offset.memPtr.ContainsKey(kv.Key),
                    $"missing memPtr key '{kv.Key}'");
                AssertDp(kv.Key, kv.Value, Decode(Offset.memPtr[kv.Key]));
            }
        }

        // --- smcPathPtr ---

        private static readonly Dictionary<string, Dp> ExpectedSmcPathPtr = new Dictionary<string, Dp> {
            { "snes9x 1.60",       Dpt("snes9x.exe",   0x557B7D)         },
            { "snes9x 1.61",       Dpt("snes9x.exe",    0xE162C, 0x1)    },
            { "snes9x 1.62.3",     Dpt("snes9x.exe",   0x5C14D4, 0x0)    },
            { "snes9x-x64 1.59.2", Dpt("snes9x-x64.exe", 0x8EA749)       },
            { "snes9x-x64 1.60",   Dpt("snes9x-x64.exe", 0x8EAC39)       },
            { "snes9x-x64 1.61",   Dpt("snes9x-x64.exe", 0x8951CF)       },
            { "snes9x-x64 1.62",   Dpt("snes9x-x64.exe", 0x176AD48, 0x0) },
            { "snes9x-x64 1.62.2", Dpt("snes9x-x64.exe",  0xA74398, 0x0) },
            { "snes9x-x64 1.62.3", Dpt("snes9x-x64.exe",  0xA74398, 0x0) },
            { "bsnes 115",         Dpt("bsnes.exe",     0x31FC528, 0x0, 0xE8) },
            { "retroarch 1.9.4",   Dpt("retroarch.exe",  0xD69926)      },
            { "retroarch 1.16.0",  Dpt("retroarch.exe",  0xE8E80F)      },
            { "retroarch 1.17.0",  Dpt("retroarch.exe",  0xEFF8A9)      },
            { "retroarch 1.21.0",  Dpt("retroarch.exe",  0xFB5BD1)      },
            { "retroarch 1.22.2", Dpt("retroarch.exe", 0x114F0B9)       },
        };

        [Fact]
        public void SmcPathPtr_MatchesExpectedExactly() {
            Assert.Equal(ExpectedSmcPathPtr.Count, Offset.smcPathPtr.Count);
            foreach (var kv in ExpectedSmcPathPtr) {
                Assert.True(Offset.smcPathPtr.ContainsKey(kv.Key),
                    $"missing smcPathPtr key '{kv.Key}'");
                AssertDp(kv.Key, kv.Value, Decode(Offset.smcPathPtr[kv.Key]));
            }
        }

        // --- corePathPtr ---

        private static readonly Dictionary<string, Dp> ExpectedCorePathPtr = new Dictionary<string, Dp> {
            { "retroarch 1.9.4",  Dpt("retroarch.exe", 0xD6A900)  },
            { "retroarch 1.16.0", Dpt("retroarch.exe", 0xE8F7E9)  },
            { "retroarch 1.17.0", Dpt("retroarch.exe", 0xEEB59A)  },
            { "retroarch 1.21.0", Dpt("retroarch.exe", 0xFB157C)  },
            { "retroarch 1.22.2", Dpt("retroarch.exe", 0x114F8B9) },
        };

        [Fact]
        public void CorePathPtr_MatchesExpectedExactly() {
            Assert.Equal(ExpectedCorePathPtr.Count, Offset.corePathPtr.Count);
            foreach (var kv in ExpectedCorePathPtr) {
                Assert.True(Offset.corePathPtr.ContainsKey(kv.Key),
                    $"missing corePathPtr key '{kv.Key}'");
                AssertDp(kv.Key, kv.Value, Decode(Offset.corePathPtr[kv.Key]));
            }
        }

        // --- coreVersionPtr ---

        private static readonly Dictionary<string, Dp> ExpectedCoreVersionPtr = new Dictionary<string, Dp> {
            { "retroarch 1.9.4",  Dpt("retroarch.exe", 0xD67600)  },
            { "retroarch 1.16.0", Dpt("retroarch.exe", 0xE8C4E9)  },
            { "retroarch 1.17.0", Dpt("retroarch.exe", 0xEFD5A9)  },
            { "retroarch 1.21.0", Dpt("retroarch.exe", 0xFBE399)  },
            { "retroarch 1.22.2", Dpt("retroarch.exe", 0x1150BB9) },
        };

        [Fact]
        public void CoreVersionPtr_MatchesExpectedExactly() {
            Assert.Equal(ExpectedCoreVersionPtr.Count, Offset.coreVersionPtr.Count);
            foreach (var kv in ExpectedCoreVersionPtr) {
                Assert.True(Offset.coreVersionPtr.ContainsKey(kv.Key),
                    $"missing coreVersionPtr key '{kv.Key}'");
                AssertDp(kv.Key, kv.Value, Decode(Offset.coreVersionPtr[kv.Key]));
            }
        }

        // --- coreMem ---

        private static readonly Dictionary<string, int> ExpectedCoreMem = new Dictionary<string, int> {
            { "snes9x_libretro.dll 1.62.3 ec4ebfc", 0x3BA164 },
            { "snes9x_libretro.dll 1.63 49f4845",   0x3BB164 },
            { "snes9x_libretro.dll 1.63 185488c",   0x3BB164 },
            { "bsnes_libretro.dll 115",             0x7D39DC },
        };

        [Fact]
        public void CoreMem_MatchesExpectedExactly() {
            Assert.Equal(ExpectedCoreMem.Count, Offset.coreMem.Count);
            foreach (var kv in ExpectedCoreMem) {
                Assert.True(Offset.coreMem.ContainsKey(kv.Key),
                    $"missing coreMem key '{kv.Key}'");
                Assert.Equal(kv.Value, Offset.coreMem[kv.Key]);
            }
        }

        // --- coreMemPtr ---

        private static readonly Dictionary<string, Dp> ExpectedCoreMemPtr = new Dictionary<string, Dp> {
            { "snes9x2010_libretro.dll 1.52.4 d8b10c4", Dpt("retroarch.exe", 0xEF9FF8, 0x8, 0x0) },
        };

        [Fact]
        public void CoreMemPtr_MatchesExpectedExactly() {
            Assert.Equal(ExpectedCoreMemPtr.Count, Offset.coreMemPtr.Count);
            foreach (var kv in ExpectedCoreMemPtr) {
                Assert.True(Offset.coreMemPtr.ContainsKey(kv.Key),
                    $"missing coreMemPtr key '{kv.Key}'");
                AssertDp(kv.Key, kv.Value, Decode(Offset.coreMemPtr[kv.Key]));
            }
        }
    }
}
