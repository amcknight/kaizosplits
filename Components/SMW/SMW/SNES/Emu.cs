using LiveSplit.ComponentUtil;
using System;
using System.Diagnostics;
using System.IO;

namespace SNES {
    public class Emu {
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
            Offset.version.TryGetValue(size, out version);
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
                DeepPointer coreOffsetPtr;
                if (Offset.coreMem.ContainsKey(coreKey)) {
                    coreOffsetPtr = new DeepPointer(core, Offset.coreMem[coreKey]);
                } else if (Offset.coreMemPtr.ContainsKey(coreKey)) {
                    coreOffsetPtr = Offset.coreMemPtr[coreKey];
                } else {
                    throw new CoreException("No core offset found for '" + coreKey + "'");
                }

                coreOffsetPtr.DerefOffsets(emu, out offset);
                memOffset = (long)offset;

                if (memOffset == 0) {
                    throw new CoreException("No memory offset found for '" + core + "' at '" + coreOffsetPtr + "'");
                }
                return memOffset;
            }

            string emuKey = Key(name, version);
            DeepPointer offsetPtr;
            Offset.memPtr.TryGetValue(emuKey, out offsetPtr);
            if (offsetPtr != null) {
                offsetPtr.DerefOffsets(emu, out offset);
                memOffset = (long)offset;
                if (memOffset == 0) {
                    throw new EmuException("No memory offset found for '" + emuKey + "' at '" + offset.ToString("X4") + "'");
                }
                return memOffset;
            }

            Offset.mem.TryGetValue(emuKey, out memOffset);
            if (memOffset == 0) {
                throw new EmuException("No memory offset found for '" + emuKey + "'");
            }
            return memOffset;
        }

        private string Core() {
            if (!Offset.corePathPtr.ContainsKey(emuKey)) {
                throw new EmuException("No Core Path pointer exists for '" + emuKey + "'");
            }
            var corePath = Offset.corePathPtr[emuKey].DerefString(emu, 512);
            return Path.GetFileName(corePath);
        }

        private string CoreVersion() {
            if (!Offset.coreVersionPtr.ContainsKey(emuKey)) {
                throw new EmuException("No Core Version pointer exists for '" + emuKey + "'");
            }
            return Offset.coreVersionPtr[emuKey].DerefString(emu, 32);
        }

        private string Key(string k1, string k2) {
            return string.Join(" ", k1, k2);
        }

        // Only call once per update
        private void UpdateSmc() {
            prevSmc = smc;
            if (!Offset.smcPathPtr.ContainsKey(emuKey)) {
                throw new EmuException("No SMC path pointer exists for '"+emuKey+"'");
            }
            var smcPath = Offset.smcPathPtr[emuKey].DerefString(emu, 512);
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
