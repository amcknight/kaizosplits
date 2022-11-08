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

    // Load SMW lib
    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    Type type = asm.GetType("SMW.SMW");
    vars.smw = Activator.CreateInstance(type);
}

init {
    vars.gamename = timer.Run.GameName;
    vars.livesplitGameName = vars.gamename;
    vars.runNum = 0;
    vars.maxLag = 50L;
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

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
    } else if (vars.smw.States.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
      if (memory.ProcessName.ToLower().Contains("snes9x"))
          memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);

    if (memoryOffset == 0) throw new Exception("Memory not yet initialized.");

    vars.watchers = new MemoryWatcherList();
    foreach (KeyValuePair<int, string> entry in vars.smw.ShortMemoryMap) {
        vars.watchers.Add(new MemoryWatcher<short>((IntPtr)memoryOffset + entry.Key)  { Name = entry.Value });
    }
    foreach (KeyValuePair<int, string> entry  in vars.smw.ByteMemoryMap) {
        vars.watchers.Add(new MemoryWatcher<byte>((IntPtr)memoryOffset + entry.Key)  { Name = entry.Value });
    }

    vars.reInitialise = (Action)(() => {
        vars.gamename = timer.Run.GameName;
        vars.livesplitGameName = vars.gamename;
        print("Game: "+vars.gamename+", Splits: "+vars.livesplitGameName);
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
    var smw = vars.smw;
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

    smw.Update(isRecording, vars.watchers);

    // Override Default split variables for individual games
    switch ((string) vars.gamename) {
        case "Bunbun World 2": // TODO: Retest
            other = smw.s.mem.Prev(smw.s.mem.io) != 61 // KLDC Dolphins
                && smw.s.prevIO != 48 // Mirror Temple
                ;
            smw.s.mem.Room = smw.s.mem.Room && smw.s.mem.Prev(smw.s.mem.io) != 65; // Using yoshiCoins
            smw.s.mem.CoinFlag = smw.s.Stepped(smw.s.mem.yoshiCoin) && smw.s.mem.Prev(smw.s.mem.io) == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
        break;
        case "Cute Kaizo World": // TODO: Retest
            smw.Tape = smw.Tape && smw.Prev(smw.io) != 55;  // Using doors
            smw.Credits = smw.ShiftTo(smw.io, 21);
        break;
        case "Love Yourself":
            other =
                (smw.s.Shift(smw.s.mem.roomNum, 39, 40) && smw.s.mem.Curr(smw.s.mem.levelNum) == 74) ||
                (smw.s.Shift(smw.s.mem.roomNum, 40, 42) && smw.s.mem.Curr(smw.s.mem.levelNum) == 74) ||
                (smw.s.Stepped(smw.s.mem.roomNum) && smw.s.mem.Curr(smw.s.mem.roomNum) > 50 && smw.s.mem.Curr(smw.s.mem.levelNum) == 85)
                ;
        break;
        case "Purgatory": // TODO: Retest
            smw.Tape = smw.Tape
                && smw.Prev(smw.io) != 56  // Cancel for Sea Moon
                && smw.Prev(smw.io) != 49  // Cancel for Soft and Wet
                && smw.Prev(smw.io) != 63  // Cancel for Summit of Salvation
                ;
        break;
        case "Quickie World 2": // TODO: Retest
            smw.Tape = smw.Tape && smw.Prev(smw.io) != 65;  // Yoshi's Lair 1 Tape
        break;
    }

    var splitStatus = !isRecording && (smw.RunDone
        || (isWorlds && smw.Overworld)
        || (isLevelExits && smw.LevelExit)
        || (isIntroExits && smw.Intro)
        || (isLevelStarts && smw.LevelStart)
        || (isLevelFinishes && smw.LevelFinish)
        || (isFirstTapes && smw.Tape)
        || (isRooms && smw.Room)
        || other
        );

    smw.Track(smw.LevelExit, "Exit");
    smw.Track(smw.Intro, "Intro");
    smw.Track(smw.LevelStart, "Start");
    smw.Track(smw.Goal, "Goal");
    smw.Track(smw.Key, "Key");
    smw.Track(smw.Orb, "Orb");
    smw.Track(smw.Palace, "Palace");
    smw.Track(smw.Boss, "Boss");
    smw.Track(smw.Tape, "Tape");
    smw.Track(smw.Room, "Room");
    smw.Track(smw.Portal, "Portal");
    smw.Track(smw.Submap, "Map");

    // TODO: Separate timing to a lib
    var newEndMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    var lag = newEndMs - vars.endMs;
    if (smw.debugInfo.Count > 0) print(string.Join("\n", smw.debugInfo));
    vars.endMs = newEndMs;
    vars.smw = smw;
    if (splitStatus && lag > vars.maxLag) {
        vars.smw.Skip(timer);
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
        vars.smw.WriteRun("C:\\Users\\thedo\\git\\kaizosplits\\runs", vars.runNum);
    }
    vars.smw.Reset();
}
