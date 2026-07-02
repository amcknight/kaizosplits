using LiveSplit.ComponentUtil;

namespace SNES {
    // One EmuProfile captures everything needed for a single emulator build:
    // its module size (so the emulator can be detected by Offset.version),
    // and any pointers/addresses that depend on this exact build.
    //
    // Fields:
    //   Name         Process name ("snes9x", "snes9x-x64", "bsnes", "retroarch",
    //                "higan", "snes9x-rr", "emuhawk")
    //   Version      Version string used as the second half of an emuKey
    //   ModuleSize   MainModule memory size used for detection
    //   SmcPath      Pointer to the loaded ROM path string
    //   CorePath     RetroArch only: pointer to the active core dll path string
    //   CoreVersion  RetroArch only: pointer to the core version+hash string
    //   DirectMem    Direct address (no pointer chain) for emulators that
    //                expose memory at a stable offset. 0 means "n/a"
    //   MemPtr       Pointer chain to the emulator's SNES memory base
    //   Aliases      Additional version strings that share this build's data;
    //                emit duplicate entries for these in the generated dicts
    //                BUT not in the version-by-size map.
    internal class EmuProfile {
        public string Name;
        public string Version;
        public int ModuleSize;
        public DeepPointer SmcPath;
        public DeepPointer CorePath;
        public DeepPointer CoreVersion;
        public long DirectMem;
        public DeepPointer MemPtr;
        public string[] Aliases = new string[0];

        public string Key => Name + " " + Version;
        public string KeyFor(string version) => Name + " " + version;
    }

    // CoreProfile captures retroarch-core-specific data. The Key is
    // "<dllName> <coreVersionString>" where coreVersionString already
    // contains the version + commit-hash suffix as it appears at runtime.
    internal class CoreProfile {
        public string Dll;
        public string Version;
        public long DirectMem;
        public DeepPointer MemPtr;

        public string Key => Dll + " " + Version;
    }
}
