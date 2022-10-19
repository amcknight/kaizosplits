state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}

startup {
    settings.Add("levels", true, "Normal Levels");
    settings.SetToolTip("levels", "Split on crossing goal tapes and activating keyholes");
    settings.Add("checkpoints", false, "First H");
    settings.SetToolTip("checkpoints", "Split when getting the first H");
    settings.Add("worlds", false, "Overworlds");
    settings.SetToolTip("worlds", "Split when switching overworlds (use with subsplits)");
    settings.Add("intro", false, "End of Intro");
    settings.SetToolTip("intro", "Split when intro ends");
}

init {
    vars.gamename = timer.Run.GameName;
    vars.livesplitGameName = vars.gamename;
    print(vars.gamename);

    var states = new Dictionary<int, long>
    {
        { 9646080,   0x97EE04 },      // Snes9x-rr 1.60
        { 13565952,  0x140925118 },   // Snes9x-rr (x64) 1.61
        { 9027584,   0x94DB54 },      // Snes9x 1.60
        { 12836864,  0x1408D8BE8 },   // Snes9x (x64) 1.60
        { 16019456,  0x94D144 },      // higan v106
        { 15360000,  0x8AB144 },      // higan v106.112
        { 22388736,  0xB0ECC8 },      // higan v107
        { 23142400,  0xBC7CC8 },      // higan v108
        { 23166976,  0xBCECC8 },      // higan v109
        { 23224320,  0xBDBCC8 },      // higan v110
        { 10096640,  0x72BECC },      // bsnes v107
        { 10338304,  0x762F2C },      // bsnes v107.1
        { 47230976,  0x765F2C },      // bsnes v107.2/107.3
        { 131543040, 0xA9BD5C },      // bsnes v110
        { 51924992,  0xA9DD5C },      // bsnes v111
        { 52056064,  0xAAED7C },      // bsnes v112
        { 52477952,  0xB16D7C },      // bsnes v115
        { 7061504,   0x36F11500240 }, // BizHawk 2.3
        { 7249920,   0x36F11500240 }, // BizHawk 2.3.1
        { 6938624,   0x36F11500240 }, // BizHawk 2.3.2
    };

    long memoryOffset = 0;
    if ( game.ProcessName.ToLower() == "retroarch" ) {
        var snes9xModules = modules.Where(m => m.ModuleName == "snes9x_libretro.dll");
        if ( snes9xModules.Any() ) {
            ProcessModuleWow64Safe libretromodule = snes9xModules.First();
            IntPtr baseAddress = libretromodule.BaseAddress;
            if ( game.Is64Bit() ) {
                SigScanTarget target = new SigScanTarget(13, "83 F9 01 74 10 83 F9 02 75 2C 48 8B 05 ?? ?? ?? ?? 48 8B 40 ??");
                SignatureScanner scanner = new SignatureScanner(game, baseAddress, (int)libretromodule.ModuleMemorySize);
                IntPtr codeOffset = scanner.Scan(target);
                int memoryReference = (int) ((long) memory.ReadValue<int>(codeOffset) + (long) codeOffset + 0x04 +  - (long) libretromodule.BaseAddress);
                byte memoryReferenceoffset = memory.ReadValue<byte>(codeOffset + 7);
                IntPtr outOffset;
                new DeepPointer( "snes9x_libretro.dll", memoryReference, memoryReferenceoffset, 0x0).DerefOffsets(game, out outOffset);
                memoryOffset = (long) outOffset;
            }
        }
    } else {
        if (states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
            if (memory.ProcessName.ToLower().Contains("snes9x"))
                memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);
    }

    // TODO: This gets thrown repeatedly in retroarch until a game is loaded. It works but is very loud when debugging
    if (memoryOffset == 0)
        throw new Exception("Memory not yet initialized.");

    vars.watchers = new MemoryWatcherList {
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1ED2)  { Name = "fileSelect" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x906)   { Name = "fanfare" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1DFB)  { Name = "io" },  // SPC700 I/0 Ports. Related to music. Important for many transitions.
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f28)  { Name = "yellowSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f27)  { Name = "greenSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f29)  { Name = "blueSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f2a)  { Name = "redSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13C6)  { Name = "bossDefeat" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x190D)  { Name = "peach" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13CE)  { Name = "checkpointTape" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0109)  { Name = "weirdLevVal" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1F11)  { Name = "submap" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1B9C)  { Name = "overworldPortal" },
    };

    vars.prevIO = -1;
    vars.died = false;

    vars.reInitialise = (Action)(() => {
        vars.gamename = timer.Run.GameName;
        vars.livesplitGameName = vars.gamename;
        print(vars.gamename);
    });

    vars.reInitialise();
}

update {
    vars.watchers.UpdateAll(game);
    if (vars.livesplitGameName != timer.Run.GameName) {
        vars.gamename = timer.Run.GameName;
        vars.reInitialise();
    }
}

start {
    var fileSelect = vars.watchers["fileSelect"];
    return fileSelect.Old == 0 && fileSelect.Current != 0;
}

reset {
    var fileSelect = vars.watchers["fileSelect"];
    return fileSelect.Old != 0 && fileSelect.Current == 0;
}

split {
    // Settings
    var isLevels =      settings["levels"];
    var isCheckpoints = settings["checkpoints"];
    var isWorlds =      settings["worlds"];
    var isIntro =       settings["intro"];

    // Vars
    var fanfare =         vars.watchers["fanfare"];
    var bossDefeat =      vars.watchers["bossDefeat"];
    var io =              vars.watchers["io"];
    var yellowSwitch =    vars.watchers["yellowSwitch"];
    var greenSwitch =     vars.watchers["greenSwitch"];
    var blueSwitch =      vars.watchers["blueSwitch"];
    var redSwitch =       vars.watchers["redSwitch"];
    var peach =           vars.watchers["peach"];
    var checkpointTape =  vars.watchers["checkpointTape"];
    var weirdLevVal =     vars.watchers["weirdLevVal"];
    var overworldPortal = vars.watchers["overworldPortal"];
    var submap =          vars.watchers["submap"];

    // Convenience functions
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, int, bool> shift = (watcher, o, c) => watcher.Old == o && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> shiftTo = (watcher, c) => watcher.Old != c && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> shiftFrom = (watcher, c) => watcher.Old == c && watcher.Current != c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> shifted = watcher => watcher.Old != watcher.Current;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> stepTo = (watcher, c) => watcher.Current == c && watcher.Old + 1 == watcher.Current;

    // Composite Vars
    var toOrb = shiftTo(io, 3);
    var toGoal = shiftTo(io, 4);
    var toKey = shiftTo(io, 7);
    var gotOrb = io.Current == 3;
    var gotGoal = io.Current == 4;
    var gotKey = io.Current == 7;
    var gotFanfare = io.Current == 8;
    var bossDead = shiftFrom(bossDefeat, 0);
    var exitOverworldPortal = shift(overworldPortal, 1, 0);

    // Split Conditions
    var bossExit = bossDead;
    var orbExit = toOrb && !bossDead;
    var goalExit = stepTo(fanfare, 1) && !bossDead && !gotOrb; // TODO: Try just using toGoal
    var keyExit = toKey;
    var palaceExit = stepTo(yellowSwitch, 1) || stepTo(greenSwitch, 1) || stepTo(blueSwitch, 1) || stepTo(redSwitch, 1);
    var peachReleased = stepTo(peach, 1);
    var tape = stepTo(checkpointTape, 1) && !gotOrb && !gotGoal && !gotKey && !gotFanfare;
    var credits = false; // TODO: Search for common credits signal
    var worlds = exitOverworldPortal || shifted(submap);
    var intro = shift(weirdLevVal, 233, 0);

    // Composite split conditions
    var levelExit = goalExit || keyExit || orbExit || palaceExit || bossExit;
    var runDone = peachReleased || credits;
    var splitStatus = runDone
        || (isLevels && levelExit)
        || (isCheckpoints && tape)
        || (isWorlds && worlds)
        || (isIntro && intro)
        ;

    // TEMPORARY DEBUG INFO
    
    List<string> debugInfo = new List<string>();
    Func<string, bool> dbg = msg => { debugInfo.Add(msg); return true; };
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> monitor = watcher => {
        if (watcher.Old != watcher.Current) dbg(watcher.Name + ": " + watcher.Old + "->" + watcher.Current);
        return true;
    };

    if (splitStatus) {
        var reasons = "";
        if (goalExit) reasons += " goalExit";
        if (keyExit) reasons += " keyExit";
        if (orbExit) reasons += " orbExit";
        if (palaceExit) reasons += " palaceExit";
        if (bossExit) reasons += " bossExit";
        if (tape) reasons += " tape";
        if (peachReleased) reasons += " peachReleased";
        if (credits) reasons += " credits";
        if (worlds) reasons += " worlds";
        if (intro) reasons += " intro";
        dbg("SPLIT: "+reasons+", IO: "+io.Current);
    }
    
    if (debugInfo.Any()) print(string.Join("\n", debugInfo));
    return splitStatus;
}
