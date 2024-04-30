using Codaxy.Xlio;
using LiveSplit.ComponentUtil;
using SpeedrunComSharp;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;

namespace SNES {
    public class Emu {
        Dictionary<int, string> versions = new Dictionary<int, string> {
            { 15675392, "1.9.4"  }, // retroarch
            { 16793600, "1.16.0" }, // retroarch
            { 17264640, "1.17.0" }, // retroarch
            {  6991872, "1.57"   }, // snes9x
            {  9027584, "1.60"   }, // snes9x
            {  9158656, "1.61"   }, // snes9x
            { 10399744, "1.62.3" }, // snes9x
            { 12537856, "1.59.2" }, // snes9x x64
            { 12836864, "1.60"   }, // snes9x x64
            { 12955648, "1.61"   }, // snes9x x64
            { 29069312, "1.62"   }, // snes9x x64
            { 15474688, "1.62.3" }, // snes9x x64 (also 1.62.2)
            {  9646080, "1.60"   }, // snes9x-rr
            { 13565952, "1.60"   }, // snes9x-rr x64
            { 10096640, "107"    }, // bsnes
            { 10338304, "107.1"  }, // bsnes
            { 47230976, "107.2"  }, // bsnes (also 107.3)
            {131543040, "110"    }, // bsnes
            { 51924992, "111"    }, // bsnes
            { 52056064, "112"    }, // bsnes
		    { 52477952, "115"    }, // bsnes
            { 16019456, "106"    }, // higan
            { 15360000, "106.112"}, // higan
		    { 22388736, "107"    }, // higan
		    { 23142400, "108"    }, // higan
		    { 23166976, "109"    }, // higan
		    { 23224320, "110"    }, // higan
            {  7061504, "2.3"    }, // BizHawk
            {  7249920, "2.3.1"  }, // BizHawk
            {  6938624, "2.3.2"  }, // BizHawk
        };
        // x comments means I didnt test the offset. picked up from prior splitters
        Dictionary<string, long> offsets = new Dictionary<string, long> {
            { "higan 106",    0x94D144 }, // x
            { "higan 106.112",0x8AB144 }, // x
		    { "higan 107",    0xB0ECC8 }, // x
		    { "higan 108",    0xBC7CC8 }, // x
		    { "higan 109",    0xBCECC8 }, // x
		    { "higan 110",    0xBDBCC8 }, // x
            { "bsnes 107",    0x72BECC }, // x
            { "bsnes 107.1",  0x762F2C }, // x
            { "bsnes 107.2",  0x765F2C }, // x
            { "bsnes 107.3",  0x765F2C }, // x
            { "bsnes 110",    0xA9BD5C }, // x
            { "bsnes 111",    0xA9DD5C }, // x
            { "bsnes 112",    0xAAED7C }, // x
		    { "bsnes 115",    0xB16D7C },
            { "emuhawk 2.3",  0x36F11500240 }, // x
            { "emuhawk 2.3.1",0x36F11500240 }, // x
            { "emuhawk 2.3.2",0x36F11500240 }, // x
        };
        Dictionary<string, DeepPointer> offsetPtrs = new Dictionary<string, DeepPointer> {
            { "snes9x 1.60",   new DeepPointer("snes9x.exe", 0x54DB54) },
            { "snes9x 1.61",   new DeepPointer("snes9x.exe",0x507BC4) },
            { "snes9x 1.62.3", new DeepPointer("snes9x.exe", 0x12698) },
            { "snes9x-x64 1.59.2", new DeepPointer("snes9x-x64.exe", 0x8D86F8) },
            { "snes9x-x64 1.60",   new DeepPointer("snes9x-x64.exe", 0x8D86F8) },
            { "snes9x-x64 1.61",   new DeepPointer("snes9x-x64.exe", 0x883158) },
            { "snes9x-x64 1.62",   new DeepPointer("snes9x-x64.exe", 0x1758D40) },
            { "snes9x-x64 1.62.2", new DeepPointer("snes9x-x64.exe", 0xA62390) },
            { "snes9x-x64 1.62.3", new DeepPointer("snes9x-x64.exe", 0xA62390) },
        };
        Dictionary<string, DeepPointer> smcPathPtrs = new Dictionary<string, DeepPointer> {
            { "snes9x 1.60",   new DeepPointer("snes9x.exe", 0x557B7D) },
            { "snes9x 1.61",   new DeepPointer("snes9x.exe", 0xE162C, 0x1) },
            { "snes9x 1.62.3", new DeepPointer("snes9x.exe", 0x5C14D4, 0x0) },
            { "snes9x-x64 1.59.2", new DeepPointer("snes9x-x64.exe", 0x8EA749) },
            { "snes9x-x64 1.60",   new DeepPointer("snes9x-x64.exe", 0x8EAC39) },
            { "snes9x-x64 1.61",   new DeepPointer("snes9x-x64.exe", 0x8951CF) },
            { "snes9x-x64 1.62",   new DeepPointer("snes9x-x64.exe", 0x176AD48, 0x0) },
            { "snes9x-x64 1.62.2", new DeepPointer("snes9x-x64.exe", 0xA74398, 0x0) },
            { "snes9x-x64 1.62.3", new DeepPointer("snes9x-x64.exe", 0xA74398, 0x0) },
            { "bsnes 115", new DeepPointer("bsnes.exe", 0x31FC528, 0x0, 0xE8) },
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD69926) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8E80F) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEFF8A9) },
        };
        Dictionary<string, DeepPointer> corePathPtrs = new Dictionary<string, DeepPointer> {
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD6A900) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8F7E9) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEEB59A) },
        };
        Dictionary<string, DeepPointer> coreVersionPtrs = new Dictionary<string, DeepPointer> {
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD67600) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8C4E9) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEFD5A9) },
        };
        Dictionary<string, int> coreOffsetPtrs = new Dictionary<string, int> {
            { "snes9x_libretro.dll 1.62.3 ec4ebfc", 0x3BA164 },
            { "bsnes_libretro.dll 115",             0x7D39DC },
        };

        private Process emu;
        private string name;
        private string version;
        private string emuKey;
        private string smc = "";
        private string prevSmc;

        private string core;
        private string coreVersion;

        public Emu() { }

        public void Init(Process emu) {
            this.emu = emu;
            var size = emu.MainModuleWow64Safe().ModuleMemorySize;
            versions.TryGetValue(size, out version);
            if (string.IsNullOrWhiteSpace(version)) {
                throw new EmuException("Can't find emulator version from it's size (" + size + ")");
            }
            name = emu.ProcessName.ToLower();
            emuKey = Key(name, version);
        }

        public void Ready() {
            if (name == "retroarch") {
                core = Core();
                coreVersion = CoreVersion();
                if (string.IsNullOrWhiteSpace(core)) {
                    throw new CoreException("No " + name + " Core found");
                }
                if (string.IsNullOrWhiteSpace(coreVersion)) {
                    throw new CoreException("No " + name + " Core Version found for " + core);
                }
            }

            UpdateSmc();

            if (string.IsNullOrWhiteSpace(smc) || smc.StartsWith(name)) {
                throw new EmuException("No " + name + " ROM found");
            }
        }

        public long GetOffset() {
            long memOffset;
            IntPtr offset;
            if (name == "retroarch") {
                string coreKey = Key(core, coreVersion);
                int coreOffset = 0;
                coreOffsetPtrs.TryGetValue(coreKey, out coreOffset);
                if (coreOffset == 0) {
                    throw new CoreException("No core offset found for '" + coreKey + "'");
                }

                new DeepPointer(core, coreOffset).DerefOffsets(emu, out offset);
                memOffset = (long)offset;

                if (memOffset == 0) {
                    throw new CoreException("No memory offset found for '" + core + "' at '" + coreOffset.ToString("X4") + "'");
                }
                return memOffset;
            }

            string emuKey = Key(name, version);
            DeepPointer offsetPtr;
            offsetPtrs.TryGetValue(emuKey, out offsetPtr);
            if (offsetPtr != null) {
                offsetPtr.DerefOffsets(emu, out offset);
                memOffset = (long)offset;
                if (memOffset == 0) {
                    throw new EmuException("No memory offset found for '" + emuKey + "' at '" + offset.ToString("X4") + "'");
                }
                return memOffset;
            }

            offsets.TryGetValue(emuKey, out memOffset);
            if (memOffset == 0) {
                throw new EmuException("No memory offset found for '" + emuKey + "'");
            }
            return memOffset;
        }

        private string Core() {
            if (!corePathPtrs.ContainsKey(emuKey)) {
                throw new EmuException("No Core Path pointer exists for '" + emuKey + "'");
            }
            var corePath = corePathPtrs[emuKey].DerefString(emu, 512);
            return Path.GetFileName(corePath);
        }

        private string CoreVersion() {
            if (!coreVersionPtrs.ContainsKey(emuKey)) {
                throw new EmuException("No Core Version pointer exists for '" + emuKey + "'");
            }
            return coreVersionPtrs[emuKey].DerefString(emu, 32);
        }

        private string Key(string k1, string k2) {
            return string.Join(" ", k1, k2);
        }

        // Only call once per update
        private void UpdateSmc() {
            prevSmc = smc;
            if (!smcPathPtrs.ContainsKey(emuKey)) {
                throw new EmuException("No SMC path pointer exists for '"+emuKey+"'");
            }
            var smcPath = smcPathPtrs[emuKey].DerefString(emu, 512);
            smc = Path.GetFileName(smcPath);
        }

        public bool SmcChanged() {
            return smc != prevSmc;
        }

        public string Smc() {
            return smc;
        }
    }
}
