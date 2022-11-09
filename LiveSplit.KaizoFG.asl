state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}

startup {
    settings.Add("recording", false, "Record Events");
    settings.SetToolTip("recording", "Record events for Split Synthesis");
    settings.Add("worlds", true, "Overworlds");
    settings.SetToolTip("worlds", "Split when switching overworlds (use with subsplits)");
    settings.Add("levelExits", true, "Level Exits");
    settings.SetToolTip("levelExits", "Split when leaving a level without start/select");
    settings.Add("introExits", true, "Intro Exits");
    settings.SetToolTip("introExits", "Split and end of the intro");
    settings.Add("levelStarts", false, "Level Starts");
    settings.SetToolTip("levelStarts", "Split at the start of each level");
    settings.Add("levelFinishes", false, "Goals, Orbs, Keys, and Bosses");
    settings.SetToolTip("levelFinishes", "Split on crossing goal tapes, getting orbs, and activating keyholes");
    settings.Add("firstTapes", true, "First checkpoint tape");
    settings.SetToolTip("firstTapes", "Split when getting the first checkpoint tape in the level");
    settings.Add("rooms", false, "All Room Changes");
    settings.SetToolTip("rooms", "Split when on room transitions even with CPs");

    // Load libs
    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    vars.rec = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.ws = Activator.CreateInstance(asm.GetType("SMW.Watchers"));
}

init {
    vars.gamename = timer.Run.GameName;
    vars.livesplitGameName = vars.gamename;
    vars.runNum = 0;
    vars.maxLag = 50L;
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    vars.prevIn = false;

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

    vars.ws.SetMemoryOffset(memoryOffset);

    vars.reInitialise = (Action)(() => {
        vars.gamename = timer.Run.GameName;
        vars.livesplitGameName = vars.gamename;
        print("Game: "+vars.gamename+", Splits: "+vars.livesplitGameName);
    });

    vars.reInitialise();
}

update {
    vars.ws.UpdateAll(game);
    if (vars.livesplitGameName != timer.Run.GameName) {
        vars.gamename = timer.Run.GameName;
        vars.reInitialise();
    }
}

start {
    var fileSelect = vars.ws["fileSelect"];
    return fileSelect.Old == 0 && fileSelect.Current != 0;
}

reset {
    var fileSelect = vars.ws["fileSelect"];
    return fileSelect.Old != 0 && fileSelect.Current == 0;
}

split {
    var r = vars.rec;
    var w = vars.ws;
    var startMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    // Settings: TODO Move to a lib
    var isRecording = settings["recording"];
    var isWorlds = settings["worlds"];
    var isLevelExits = settings["levelExits"];
    var isIntroExits = settings["introExits"];
    var isLevelStarts = settings["levelStarts"];
    var isLevelFinishes = settings["levelFinishes"];
    var isFirstTapes = settings["firstTapes"];
    var isRooms = settings["rooms"];
    var other = false;

    // Currently can't put these into UpdateAll due to troubles importing Process from System.Diagnostics.Process
    // The order here matters for Spawn recording
    r.Update(isRecording, w);
    w.UpdateState();

    // Override Default split variables for individual games
    switch ((string) vars.gamename) {
        case "Bunbun World 2": // TODO: Retest
            other = w.Prev(w.io) != 61 // KLDC Dolphins
                && w.prevIO != 48 // Mirror Temple
                ;
            w.Room = w.Room && w.Prev(w.io) != 65; // Using yoshiCoins
            w.CoinFlag = w.Stepped(w.yoshiCoin) && w.Prev(w.io) == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
        break;
        case "Cute Kaizo World": // TODO: Retest
            w.Tape = w.Tape && w.Prev(w.io) != 55;  // Using doors
            w.Credits = w.ShiftTo(w.io, 21);
        break;
        case "Love Yourself":
            other =
                (w.Shift(w.roomNum, 39, 40) && w.Curr(w.levelNum) == 74) || // 3rd Castle room
                (w.Shift(w.roomNum, 40, 42) && w.Curr(w.levelNum) == 74) || // 4th castle room
                (w.Stepped(w.roomNum) && w.Curr(w.roomNum) > 50 && w.Curr(w.roomNum) < 67 && w.Curr(w.levelNum) == 85) || // All room other than credits door
                (w.EnterDoor && w.Curr(w.roomNum) == 66 && w.Curr(w.levelNum) == 85) // Credits door
                ;
        break;
        case "Purgatory": // TODO: Retest
            w.Tape = w.Tape
                && w.Prev(w.io) != 56  // Cancel for Sea Moon
                && w.Prev(w.io) != 49  // Cancel for Soft and Wet
                && w.Prev(w.io) != 63  // Cancel for Summit of Salvation
                ;
        break;
        case "Quickie World 2": // TODO: Retest
            w.Tape = w.Tape && w.Prev(w.io) != 65;  // Yoshi's Lair 1 Tape
        break;
    }

    var splitStatus = !isRecording && (w.RunDone
        || (isWorlds && w.Overworld)
        || (isLevelExits && w.LevelExit)
        || (isIntroExits && w.Intro)
        || (isLevelStarts && w.LevelStart)
        || (isLevelFinishes && w.LevelFinish)
        || (isFirstTapes && w.Tape)
        || (isRooms && w.Room)
        || other
        );

    // r.Track(w.LevelExit, "Exit", w);
    // r.Track(w.Intro, "Intro", w);
    // r.Track(w.LevelStart, "Start", w);
    // r.Track(w.Goal, "Goal", w);
    // r.Track(w.Key, "Key", w);
    // r.Track(w.Orb, "Orb", w);
    // r.Track(w.Palace, "Palace", w);
    // r.Track(w.Boss, "Boss", w);
    // r.Track(w.Tape, "Tape", w);
    // r.Track(w.Room, "Room", w);
    // r.Track(w.Portal, "Portal", w);
    // r.Track(w.Submap, "Map", w);
    //r.Monitor(w.gameMode, w);

    // TODO: Separate timing to a lib
    var newEndMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    var lag = newEndMs - vars.endMs;
    if (r.debugInfo.Count > 0) print(string.Join("\n", r.debugInfo));
    vars.endMs = newEndMs;

    if (splitStatus && lag > vars.maxLag) {
        new TimerModel { CurrentState = timer }.SkipSplit();
        print("LAG: "+lag);
        return false;
    } else {
        return splitStatus;
    }
}

onStart {
    print("START");
    vars.runNum = vars.runNum + 1;
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds(); // This first endMs doesn't really make sense..
}

onReset {
    print("RESET");
    if (settings["recording"]) {
        vars.rec.WriteRun("C:\\Users\\thedo\\git\\kaizosplits\\runs", vars.runNum); // TODO: Remove hardcoded location
    }
    vars.rec.Reset();
}
