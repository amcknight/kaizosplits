state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}

startup {
    settings.Add("record", false, "Record Events");
    settings.SetToolTip("record", "Record events for SPlit Synthesis");
    settings.Add("levels", true, "Normal Levels");
    settings.SetToolTip("levels", "Split on crossing goal tapes and activating keyholes");
    settings.Add("bosses", true, "Boss Levels");
    settings.SetToolTip("bosses", "Split on boss fanfare");
    settings.Add("checkpoints", true, "Checkpoints");
    settings.SetToolTip("checkpoints", "Split when getting a checkpoint, whether it's the tape or a room transition CP");
    settings.Add("worlds", true, "Overworlds");
    settings.SetToolTip("worlds", "Split when switching overworlds (use with subsplits)");
    settings.Add("rooms", false, "All Room Changes");
    settings.SetToolTip("rooms", "Split when on room transitions even with CPs");
    settings.Add("flags", false, "Flags");
    settings.SetToolTip("flags", "Split when getting special non-CP states. Warning about idempotence!");
    settings.Add("levelStarts", false, "Level Starts");
    settings.SetToolTip("levelStarts", "Split at the start of each level");

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
    } else if (vars.smw.states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
      if (memory.ProcessName.ToLower().Contains("snes9x"))
          memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);

    if (memoryOffset == 0) throw new Exception("Memory not yet initialized.");

    vars.watchers = new MemoryWatcherList();
    foreach (KeyValuePair<int, string> entry in vars.smw.shortMemoryMap) {
        vars.watchers.Add(new MemoryWatcher<short>((IntPtr)memoryOffset + entry.Key)  { Name = entry.Value });
    }
    foreach (KeyValuePair<int, string> entry  in vars.smw.byteMemoryMap) {
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

    // Settings
    var isLevels =      settings["levels"];
    var isLevelStarts = settings["levelStarts"];
    var isBosses =      settings["bosses"];
    var isCheckpoints = settings["checkpoints"];
    var isRooms =       settings["rooms"];
    var isFlags =       settings["flags"];
    var isWorlds =      settings["worlds"];

    smw.update(vars.watchers);

    // Override Default split variables for individual games
    switch ((string) vars.gamename) {
        case "Bunbun World 2": // TODO: Retest
            smw.tape = smw.tape
                && smw.prev(smw.io) != 61 // KLDC Dolphins
                && smw.prevIO != 48 // Mirror Temple
                ;
            smw.room = smw.room && smw.prev(smw.io) != 65; // Using yoshiCoins
            smw.coinFlag = smw.stepped(smw.yoshiCoin) && smw.prev(smw.io) == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
        break;
        case "Climb The Tower": // TODO: Retest
        break;
        case "Cute Kaizo World": // TODO: Retest
            smw.tape = smw.tape && smw.prev(smw.io) != 55;  // Using doors
            smw.credits = smw.shiftTo(smw.io, 21);
        break;
        case "Love Yourself": // TODO: Retest
            // TODO: Double-splitting to fix:
            // tape then room: CS, TT, TFW23
            // room then tape: RTB, W, PO
            // room then tape forced: TFW12
            // All room changes are not CPs in the above 7 double-splits
            // TFW 2nd and 3rd tapes don't work. Will need to fix double-splitting if tape counting is implemented.
        break;
        case "Purgatory": // TODO: Retest
            smw.tape = smw.tape
                && smw.prev(smw.io) != 56  // Cancel for Sea Moon
                && smw.prev(smw.io) != 49  // Cancel for Soft and Wet
                && smw.prev(smw.io) != 63  // Cancel for Summit of Salvation
                ;
        break;
        case "Quickie World": // TODO: Retest
        break;
        case "Quickie World 2": // TODO: Retest
            smw.tape = smw.tape && smw.prev(smw.io) != 65;  // Yoshi's Lair 1 Tape
        break;
    }

    var splitStatus = smw.runDone
        || (isLevelStarts && smw.levelStart)
        || (isLevels && smw.levelExit)
        || (isBosses && smw.bossDefeated)
        || (isCheckpoints && smw.tape)
        || (isRooms && smw.room)
        || (isFlags && smw.flag)
        || (isWorlds && smw.overworld);


    // TEMPORARY DEBUG INFO

    if (splitStatus) smw.dbg("SPLIT: "+smw.splitReasons());

    //smw.monitor(smw.cutScene);

    smw.track(smw.tape, "Tape");
    smw.track(smw.room, "Room");
    smw.track(smw.start, "Start");

    //if (shifted(cutScene) && cutScene.Current != 0 && cutScene.Current != 6 && cutScene.Current != 9) dbg(cutScene.Name + ": " + cutScene.Old + "->" + cutScene.Current);
    //if (shifted(roomNum)) dbg("NEW ROOM | "+place);
    //if (stepped(eventsTriggered)) dbg("EXIT");

    if (smw.debugInfo.Count > 0) print(string.Join("\n", smw.debugInfo));
    vars.smw = smw;
    return splitStatus;
}

onStart {
    vars.runNum = vars.runNum + 1;
}

onReset {
    if (settings["record"]) {
        vars.smw.writeRun("C:\\Users\\thedo\\git\\kaizosplits\\runs", vars.runNum);
    }
    vars.smw.reset();
}
