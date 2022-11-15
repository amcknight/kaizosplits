state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}

startup {
    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    vars.rec = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.ws = Activator.CreateInstance(asm.GetType("SMW.Watchers"));
}

init {
    vars.gamename = timer.Run.GameName;
    vars.maxLag = 50L;
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    vars.inProgress = false;
    vars.skippedStart = false;

    long memoryOffset = 0;
    if (game.ProcessName.ToLower() == "retroarch") {
        var snes9xModules = modules.Where(m => m.ModuleName == "snes9x_libretro.dll");
        if (snes9xModules.Any()) {
            ProcessModuleWow64Safe libretromodule = snes9xModules.First();
            IntPtr baseAddress = libretromodule.BaseAddress;
            if (game.Is64Bit()) {
                IntPtr result = IntPtr.Zero;
                SigScanTarget target = new SigScanTarget(13, "83 F9 01 74 10 83 F9 02 75 2C 48 8B 05 ?? ?? ?? ?? 48 8B 40 ??");
                SignatureScanner scanner = new SignatureScanner(game, baseAddress, (int)libretromodule.ModuleMemorySize);
                IntPtr codeOffset = scanner.Scan(target);
                int memoryReference = (int)((long)memory.ReadValue<int>(codeOffset) + (long)codeOffset + 0x04 + -(long)libretromodule.BaseAddress);
                byte memoryReferenceoffset = memory.ReadValue<byte>(codeOffset + 7);
                IntPtr outOffset;
                new DeepPointer("snes9x_libretro.dll", memoryReference, memoryReferenceoffset, 0x0).DerefOffsets(game, out outOffset);
                memoryOffset = (long)outOffset;
            }
        }
    } else if (vars.ws.states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
      if (memory.ProcessName.ToLower().Contains("snes9x"))
          memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);

    if (memoryOffset == 0) throw new Exception("Memory not yet initialized.");

    vars.ws.SetMemoryOffset(memoryOffset, new Dictionary<int, int>() {});

    vars.reInitialise = (Action)(() => {
        vars.gamename = timer.Run.GameName;
        print("Sciencing: "+vars.gamename);
    });

    vars.reInitialise();
}

update {
    vars.ws.UpdateAll(game);
}

split {
    var r = vars.rec;
    var w = vars.ws;
    var startMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    // Currently can't put these into UpdateAll due to troubles importing Process from System.Diagnostics.Process
    // The order here matters for Spawn recording
    r.Update(true, w);
    w.UpdateState();

    var startCondition = w.Crossed(w.playerX, 100);
    var endCondition = w.Crossed(w.playerX, 200);

    var splitStatus = startCondition || endCondition;

    if (!startCondition) {
      vars.inProgress = true;
    }
    if (endCondition) {
      vars.inProgress = false;
    }

    var newEndMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    var lag = newEndMs - vars.endMs;
    if (r.debugInfo.Count > 0) print(string.Join("\n", r.debugInfo));
    vars.endMs = newEndMs;

    if (splitStatus && (lag > vars.maxLag || vars.skippedStart)) {
        new TimerModel { CurrentState = timer }.SkipSplit();
        print("LAG: "+lag);
        vars.skippedStart = startCondition;
        return false;
    } else {
        return splitStatus;
    }
}

onStart {
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds(); // This first endMs doesn't really make sense..
}

onReset {
    vars.rec.Reset();
}
