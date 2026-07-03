using LiveSplit.ComponentUtil;
using System.Collections.Generic;

namespace SNES {
    // Memory offset tables, keyed for lookup by Emu.cs.
    //
    // The public dictionaries below preserve the long-standing surface used by
    // Emu.cs and any external readers. They are POPULATED from the colocated
    // _profiles and _cores arrays so that adding a new emulator build means
    // writing one EmuProfile literal in one place, instead of touching 3-5
    // parallel dictionaries.
    //
    // Comment "x" on an entry below means: "I didn't test this offset; it was
    // carried over from a prior splitter".
    public class Offset {
        // These dictionaries are the public lookup surface. They are filled by
        // the static constructor from _profiles / _cores below.
        public static readonly Dictionary<int, string> version = new Dictionary<int, string>();
        public static readonly Dictionary<string, long> mem = new Dictionary<string, long>();
        public static readonly Dictionary<string, DeepPointer> memPtr = new Dictionary<string, DeepPointer>();
        public static readonly Dictionary<string, DeepPointer> smcPathPtr = new Dictionary<string, DeepPointer>();
        public static readonly Dictionary<string, DeepPointer> corePathPtr = new Dictionary<string, DeepPointer>();
        public static readonly Dictionary<string, DeepPointer> coreVersionPtr = new Dictionary<string, DeepPointer>();
        public static readonly Dictionary<string, int> coreMem = new Dictionary<string, int>();
        public static readonly Dictionary<string, DeepPointer> coreMemPtr = new Dictionary<string, DeepPointer>();

        private static readonly EmuProfile[] _profiles = new[] {
            // --- RetroArch ---
            new EmuProfile {
                Name = "retroarch", Version = "1.9.4", ModuleSize = 15675392,
                SmcPath     = new DeepPointer("retroarch.exe", 0xD69926),
                CorePath    = new DeepPointer("retroarch.exe", 0xD6A900),
                CoreVersion = new DeepPointer("retroarch.exe", 0xD67600),
            },
            new EmuProfile {
                Name = "retroarch", Version = "1.16.0", ModuleSize = 16793600,
                SmcPath     = new DeepPointer("retroarch.exe", 0xE8E80F),
                CorePath    = new DeepPointer("retroarch.exe", 0xE8F7E9),
                CoreVersion = new DeepPointer("retroarch.exe", 0xE8C4E9),
            },
            new EmuProfile {
                Name = "retroarch", Version = "1.17.0", ModuleSize = 17264640,
                SmcPath     = new DeepPointer("retroarch.exe", 0xEFF8A9),
                CorePath    = new DeepPointer("retroarch.exe", 0xEEB59A),
                CoreVersion = new DeepPointer("retroarch.exe", 0xEFD5A9),
            },
            new EmuProfile {
                Name = "retroarch", Version = "1.21.0", ModuleSize = 18350080,
                SmcPath     = new DeepPointer("retroarch.exe", 0xFB5BD1),
                CorePath    = new DeepPointer("retroarch.exe", 0xFB157C),
                CoreVersion = new DeepPointer("retroarch.exe", 0xFBE399),
            },
            new EmuProfile {
                Name = "retroarch", Version = "1.22.2", ModuleSize = 20008960,
                SmcPath     = new DeepPointer("retroarch.exe", 0x114F0B9),
                CorePath    = new DeepPointer("retroarch.exe", 0x114F8B9),
                CoreVersion = new DeepPointer("retroarch.exe", 0x1150BB9),
            },

            // --- snes9x (32-bit) ---
            new EmuProfile { Name = "snes9x", Version = "1.57", ModuleSize = 6991872 }, // version-only
            new EmuProfile {
                Name = "snes9x", Version = "1.60", ModuleSize = 9027584,
                MemPtr  = new DeepPointer("snes9x.exe", 0x54DB54, 0x0),
                SmcPath = new DeepPointer("snes9x.exe", 0x557B7D),
            },
            new EmuProfile {
                Name = "snes9x", Version = "1.61", ModuleSize = 9158656,
                MemPtr  = new DeepPointer("snes9x.exe", 0x507BC4, 0x0),
                SmcPath = new DeepPointer("snes9x.exe", 0xE162C, 0x1),
            },
            new EmuProfile {
                Name = "snes9x", Version = "1.62.3", ModuleSize = 10399744,
                MemPtr  = new DeepPointer("snes9x.exe", 0x12698, 0x0),
                SmcPath = new DeepPointer("snes9x.exe", 0x5C14D4, 0x0),
            },

            // --- snes9x-x64 ---
            new EmuProfile {
                Name = "snes9x-x64", Version = "1.59.2", ModuleSize = 12537856,
                MemPtr  = new DeepPointer("snes9x-x64.exe", 0x8D86F8, 0x0),
                SmcPath = new DeepPointer("snes9x-x64.exe", 0x8EA749),
            },
            new EmuProfile {
                Name = "snes9x-x64", Version = "1.60", ModuleSize = 12836864,
                MemPtr  = new DeepPointer("snes9x-x64.exe", 0x8D86F8, 0x0),
                SmcPath = new DeepPointer("snes9x-x64.exe", 0x8EAC39),
            },
            new EmuProfile {
                Name = "snes9x-x64", Version = "1.61", ModuleSize = 12955648,
                MemPtr  = new DeepPointer("snes9x-x64.exe", 0x883158, 0x0),
                SmcPath = new DeepPointer("snes9x-x64.exe", 0x8951CF),
            },
            new EmuProfile {
                Name = "snes9x-x64", Version = "1.62", ModuleSize = 29069312,
                MemPtr  = new DeepPointer("snes9x-x64.exe", 0x1758D40, 0x0),
                SmcPath = new DeepPointer("snes9x-x64.exe", 0x176AD48, 0x0),
            },
            new EmuProfile {
                Name = "snes9x-x64", Version = "1.62.3", ModuleSize = 15474688,
                Aliases = new[] { "1.62.2" },
                MemPtr  = new DeepPointer("snes9x-x64.exe", 0xA62390, 0x0),
                SmcPath = new DeepPointer("snes9x-x64.exe", 0xA74398, 0x0),
            },

            // --- snes9x-rr (version-only; no memory offset yet) ---
            new EmuProfile { Name = "snes9x-rr", Version = "1.60", ModuleSize = 9646080 },
            new EmuProfile { Name = "snes9x-rr", Version = "1.60", ModuleSize = 13565952 }, // x64

            // --- bsnes ---
            new EmuProfile { Name = "bsnes", Version = "107",   ModuleSize =  10096640, DirectMem = 0x72BECC }, // x
            new EmuProfile { Name = "bsnes", Version = "107.1", ModuleSize =  10338304, DirectMem = 0x762F2C }, // x
            new EmuProfile {
                Name = "bsnes", Version = "107.2", ModuleSize = 47230976,
                Aliases = new[] { "107.3" },
                DirectMem = 0x765F2C, // x
            },
            new EmuProfile { Name = "bsnes", Version = "110", ModuleSize = 131543040, DirectMem = 0xA9BD5C }, // x
            new EmuProfile { Name = "bsnes", Version = "111", ModuleSize =  51924992, DirectMem = 0xA9DD5C }, // x
            new EmuProfile { Name = "bsnes", Version = "112", ModuleSize =  52056064, DirectMem = 0xAAED7C }, // x
            new EmuProfile {
                Name = "bsnes", Version = "115", ModuleSize = 52477952,
                DirectMem = 0xB16D7C,
                SmcPath   = new DeepPointer("bsnes.exe", 0x31FC528, 0x0, 0xE8),
            },

            // --- higan (all x, carried from prior splitters) ---
            new EmuProfile { Name = "higan", Version = "106",     ModuleSize = 16019456, DirectMem = 0x94D144 },
            new EmuProfile { Name = "higan", Version = "106.112", ModuleSize = 15360000, DirectMem = 0x8AB144 },
            new EmuProfile { Name = "higan", Version = "107",     ModuleSize = 22388736, DirectMem = 0xB0ECC8 },
            new EmuProfile { Name = "higan", Version = "108",     ModuleSize = 23142400, DirectMem = 0xBC7CC8 },
            new EmuProfile { Name = "higan", Version = "109",     ModuleSize = 23166976, DirectMem = 0xBCECC8 },
            new EmuProfile { Name = "higan", Version = "110",     ModuleSize = 23224320, DirectMem = 0xBDBCC8 },

            // --- BizHawk (emuhawk process name; all x) ---
            new EmuProfile { Name = "emuhawk", Version = "2.3",   ModuleSize = 7061504, DirectMem = 0x36F11500240 },
            new EmuProfile { Name = "emuhawk", Version = "2.3.1", ModuleSize = 7249920, DirectMem = 0x36F11500240 },
            new EmuProfile { Name = "emuhawk", Version = "2.3.2", ModuleSize = 6938624, DirectMem = 0x36F11500240 },
        };

        private static readonly CoreProfile[] _cores = new[] {
            new CoreProfile { Dll = "snes9x_libretro.dll", Version = "1.62.3 ec4ebfc", DirectMem = 0x3BA164 },
            new CoreProfile { Dll = "snes9x_libretro.dll", Version = "1.63 49f4845",   DirectMem = 0x3BB164 },
            new CoreProfile { Dll = "snes9x_libretro.dll", Version = "1.63 185488c",  DirectMem = 0x3BB164 }, // same 1.63 offset as 49f4845; verify in-game
            new CoreProfile { Dll = "bsnes_libretro.dll",  Version = "115",            DirectMem = 0x7D39DC },
            new CoreProfile {
                Dll = "snes9x2010_libretro.dll", Version = "1.52.4 d8b10c4",
                MemPtr = new DeepPointer("retroarch.exe", 0xEF9FF8, 0x8, 0x0),
            },
        };

        static Offset() {
            foreach (var p in _profiles) {
                version[p.ModuleSize] = p.Version;
                Register(p, p.Version);
                foreach (var alias in p.Aliases) {
                    Register(p, alias);
                }
            }
            foreach (var c in _cores) {
                if (c.DirectMem != 0) coreMem[c.Key] = (int)c.DirectMem;
                if (c.MemPtr != null) coreMemPtr[c.Key] = c.MemPtr;
            }
        }

        // Register a profile's data under the given version label. Used for the
        // canonical version and for any aliases (the version-by-size map only
        // ever gets the canonical version, but mem/memPtr/smcPathPtr/etc. get
        // both canonical and alias entries pointing at the same offsets).
        private static void Register(EmuProfile p, string ver) {
            var key = p.Name + " " + ver;
            if (p.DirectMem != 0) mem[key] = p.DirectMem;
            if (p.MemPtr != null) memPtr[key] = p.MemPtr;
            if (p.SmcPath != null) smcPathPtr[key] = p.SmcPath;
            if (p.CorePath != null) corePathPtr[key] = p.CorePath;
            if (p.CoreVersion != null) coreVersionPtr[key] = p.CoreVersion;
        }
    }
}
