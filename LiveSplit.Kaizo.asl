state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}

startup {
	vars.stopwatch = new Stopwatch();
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
				IntPtr result = IntPtr.Zero;
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
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x1434)  { Name = "keyholeTimer" }, // TODO: Can this be made an byte without breaking stuff?
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1ED2)  { Name = "fileSelect" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0xDB4)   { Name = "fileSelect_Baby" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x906)   { Name = "fanfare" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1B99)  { Name = "victory" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1DFB)  { Name = "io" },  // SPC700 I/0 Ports. Related to music. Important for many transitions.
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f28)  { Name = "yellowSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f27)  { Name = "greenSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f29)  { Name = "blueSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f2a)  { Name = "redSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x141A)  { Name = "roomCounter" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13C6)  { Name = "bossDefeat" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x190D)  { Name = "peach" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13CE)  { Name = "checkpointTape" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0089)  { Name = "pipe" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0071)  { Name = "cutScene" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1420)  { Name = "yoshiCoin" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0109)  { Name = "weirdLevVal" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1F2E)  { Name = "eventsTriggered" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x010B)  { Name = "roomNum" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13BF)  { Name = "levelNum" },
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x00D1)  { Name = "playerX" },
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x00D3)  { Name = "playerY" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1F11)  { Name = "submap" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1B9C)  { Name = "overworldPortal" },
        // Screen Width 005E
        // Screen height 005F
        // In Water 0075
        // 0100 Game Mode
        // 0109 weird level value
        // 010B 245 bytes stack, but first two bytes are usually level num
        // 0D9B IRQ or whatever for game modes
        // 0DB3 Player in play
        // 13C1 Overworld tile number
        // 13C5 Moon counter
        // 141C Goal flag type
        // 1925 Level mode
        // 1935 Used by Mario start
        // 19B8 32byte exit table
        // 19D8 32byte exit table flags
        // 1B95 Yoshi wings to the sky flag
        // 1B96 Side exits enabled
        // 1B99 Mario peace sign
        // 1B9C Overworld Pipe or Star
        // 1DEA Overworld event to run at level end
        // 1EA2 First 12 beaten level, next 12 midway, then a bunch more
        // 1F2E Events triggered / Levels beaten
        // 007E Player X (2 byte) within borders
        // 0080 Player Y (2 byte) within borders
        // 00D1 Player X (2 byte) within level
        // 00D3 Player Y (2 byte) within level
        // 0DD5 How a level was exited
        // 13BF Status of level (beaten, midway, directions enabled)
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0100)  { Name = "gameMode" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0DB3)  { Name = "player" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1925)  { Name = "levelMode" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1935)  { Name = "levelStart" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1DEA)  { Name = "overworldExitEvent" },
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
	vars.stopwatch.Restart();
    
    var fileSelect = vars.watchers["fileSelect"];
    var fileSelect_Baby = vars.watchers["fileSelect_Baby"];

	switch ((string) vars.gamename) {
	case "Baby Kaizo World":
		return fileSelect_Baby.Old == 0 && fileSelect_Baby.Current == 4;
	case "Super ShyGuy's Epic Journey":
		return fileSelect_Baby.Old == 0 && fileSelect_Baby.Current == 98;
	case "Of Jumps and Platforms":
		return fileSelect_Baby.Old == 0 && fileSelect_Baby.Current > 0;
	default:
		return fileSelect.Old == 0 && fileSelect.Current > 0;
	};
}

reset {
    var fileSelect = vars.watchers["fileSelect"];
    var fileSelect_Baby = vars.watchers["fileSelect_Baby"];

   	switch ((string) vars.gamename){
	case "Baby Kaizo World":
		return fileSelect_Baby.Old != 0 && fileSelect_Baby.Current == 0;
	case "Super ShyGuy's Epic Journey":
		return fileSelect_Baby.Old != 0 && fileSelect_Baby.Current == 0;
	case "Of Jumps and Platforms":
		return fileSelect_Baby.Old != 0 && fileSelect_Baby.Current == 0;
	default:
		return fileSelect.Old != 0 && fileSelect.Current == 0;
	};
}

split {
    // Settings
    var isLevels =      settings["levels"];
    var isLevelStarts = settings["levelStarts"];
    var isBosses =      settings["bosses"];
    var isCheckpoints = settings["checkpoints"];
    var isRooms =       settings["rooms"];
    var isFlags =       settings["flags"];
    var isWorlds =      settings["worlds"];

    // Vars
    var fanfare =        vars.watchers["fanfare"];
    var victory =        vars.watchers["victory"];
    var bossDefeat =     vars.watchers["bossDefeat"];
    var keyholeTimer =   vars.watchers["keyholeTimer"];
    var io =             vars.watchers["io"];
    var yellowSwitch =   vars.watchers["yellowSwitch"];
    var greenSwitch =    vars.watchers["greenSwitch"];
    var blueSwitch =     vars.watchers["blueSwitch"];
    var redSwitch =      vars.watchers["redSwitch"];
    var roomCounter =    vars.watchers["roomCounter"];
    var peach =          vars.watchers["peach"];
    var checkpointTape = vars.watchers["checkpointTape"];
    var pipe =           vars.watchers["pipe"];
    var cutScene =       vars.watchers["cutScene"];
    var yoshiCoin =      vars.watchers["yoshiCoin"]; // Only for BunBun 2
    var levelStart =     vars.watchers["levelStart"];
    var weirdLevVal =    vars.watchers["weirdLevVal"];
    var eventsTriggered = vars.watchers["eventsTriggered"];
    var overworldPortal = vars.watchers["overworldPortal"];
    var roomNum = vars.watchers["roomNum"]; // Not unique. Use in conjunction with levelNum.
    var levelNum = vars.watchers["levelNum"];
    var playerX = vars.watchers["playerX"];
    var playerY = vars.watchers["playerY"];

    // Temporary Test properties
    var gameMode = vars.watchers["gameMode"];
    var levelMode = vars.watchers["levelMode"];
    var player = vars.watchers["player"];
    var overworldExitEvent = vars.watchers["overworldExitEvent"];
    var submap = vars.watchers["submap"];

    // Convenience functions
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, int, bool> shift = (watcher, o, c) => watcher.Old == o && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> shiftTo = (watcher, c) => watcher.Old != c && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> shifted = watcher => watcher.Old != watcher.Current;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> stepTo = (watcher, c) => watcher.Current == c && watcher.Old + 1 == watcher.Current;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> stepped = watcher => watcher.Old + 1 == watcher.Current;
    Func<int, bool> afterSeconds = s => vars.stopwatch.ElapsedMilliseconds > s*1000;


    // Stateful Vars
    // Only roomStep if didn't just die. Assumes every death sets the roomCount to 1.
    var died = vars.died || shift(cutScene, 9, 6);
    var roomStep = false;
    if (stepped(roomCounter)) {
        roomStep = roomCounter.Current != 1 || !died;
        died = false;
    }
    vars.died = died;
    // PrevIO is basically Current IO except when a P-Switch or Star shifts the io to 0
    var prevIO = vars.prevIO;
    if (io.Current != 0) prevIO = io.Current;
    vars.prevIO = prevIO;

    // Composite Vars
    var enteredPipe = shifted(pipe) && pipe.Current < 4 && ((cutScene.Current == 5) || (cutScene.Current == 6));
    var toOrb = shiftTo(io, 3);
    var toGoal = shiftTo(io, 4);
    var gotOrb = io.Current == 3;
    var gotGoal = io.Current == 4;
    var gotKey = io.Current == 7;
    var gotFadeout = io.Current == 8;
    var bossUndead = bossDefeat.Current == 0;
    var placed = shiftTo(gameMode, 20);
    var exitOverworldPortal = shift(overworldPortal, 1, 0);

    // Default Split Conditions
    var start = stepTo(levelStart, 1);
    var goalExit = stepTo(fanfare, 1) && bossUndead && !gotOrb;  // didn't defeat boss already or get an Orb TODO: Mix "victory" into this condition
    var keyExit = shiftTo(io, 7);
    var orbExit = toOrb && bossUndead;
    var switchPalaceExit = stepTo(yellowSwitch, 1) || stepTo(greenSwitch, 1) || stepTo(blueSwitch, 1) || stepTo(redSwitch, 1);
    var bossExit = stepTo(fanfare, 1) && (bossDefeat.Current == 1 || bossDefeat.Current == 255); // TODO: Test whether non-zero would work here.
    var unknownExit = false;
    var peachReleased = stepTo(peach, 1);
    var tape = stepTo(checkpointTape, 1) && !gotOrb && !gotGoal && !gotKey && !gotFadeout;
    var room = roomStep; // TODO: If relying on this, may want to remove the room, door, pipe CPs above. This also counts place changes within the same room
    var coinFlag = false;
    var credits = false;
    var introExit = shift(weirdLevVal, 233, 0);
    var worlds = exitOverworldPortal || shifted(submap);

    // Override Default split variables for individual games
	switch ((string) vars.gamename) {
        case "Bunbun World 2": // TODO: Retest
            tape = tape
                && io.Current != 61 // KLDC Dolphins
                && prevIO != 48 // Mirror Temple
                ;
            room = room && io.Current != 65; // Using yoshiCoins
            coinFlag = stepped(yoshiCoin) && io.Current == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
		break;
		case "Climb The Tower": // TODO: Retest
		break;
		case "Cute Kaizo World": // TODO: Retest
            tape = tape && io.Current != 55;  // Using doors
            credits = shiftTo(io, 21);
		break;
        case "Love Yourself": // TODO: Retest
            /* TODO: Double-splitting to fix:
             * tape then room: CS, TT, TFW23
             * room then tape: RTB, W, PO
             * room then tape forced: TFW12
             * All room changes are not CPs in the above 7 double-splits
             * 
             * TFW 2nd and 3rd tapes don't work. Will need to fix double-splitting if tape counting is implemented.
             */
        break;
        case "Purgatory": // TODO: Retest
            tape = tape
                && io.Current != 56  // Cancel for Sea Moon
                && io.Current != 49  // Cancel for Soft and Wet
                && io.Current != 63  // Cancel for Summit of Salvation
                ;
        break;
		case "Quickie World": // TODO: Retest
		break;
		case "Quickie World 2": // TODO: Retest
		    tape = tape && io.Current != 65;  // Yoshi's Lair 1 Tape
        break;
	}
    
    // Construct high level split conditions
    var levelExit = goalExit || keyExit || orbExit || switchPalaceExit || bossExit || introExit || unknownExit; // TODO: All unknownExits need to be tested and lumped into existing exit types
    var bossDefeated = false;
    var flag = coinFlag;
    var runDone = peachReleased || credits;
    var overworld = worlds;
    var splitStatus = runDone
        || (isLevelStarts && start)
        || (isLevels && levelExit) 
        || (isBosses && bossDefeated) 
        || (isCheckpoints && tape) 
        || (isRooms && room)
        || (isFlags && flag)
        || (isWorlds && overworld);

	if (levelExit) vars.stopwatch.Restart();

    // TEMPORARY DEBUG INFO
    
    List<string> debugInfo = new List<string>();
    Func<string, bool> dbg = msg => { debugInfo.Add(msg); return true; };
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> monitor = watcher => {
        if (watcher.Old != watcher.Current) dbg(watcher.Name + ": " + watcher.Old + "->" + watcher.Current);
        return true;
    };
    
    if (splitStatus) {
        var reasons = "";
        if (start) reasons += " levelStart";
        if (goalExit) reasons += " goalExit";
        if (keyExit) reasons += " keyExit";
        if (orbExit) reasons += " orbExit";
        if (switchPalaceExit) reasons += " switchPalaceExit";
        if (bossExit) reasons += " bossExit";
        if (introExit) reasons += " introExit";
        if (tape) reasons += " tape";
        if (room) reasons += " room";
        if (coinFlag) reasons += " coinFlag";
        if (peachReleased) reasons += " peachReleased";
        if (credits) reasons += " credits";
        if (worlds) reasons += " worlds";
        dbg("SPLIT: "+reasons);
    }   
    
    //monitor(pipe);
    //monitor(io);
    //monitor(checkpointTape);
    //monitor(cutScene);
    //monitor(roomCounter);
    //monitor(gameMode);
    //monitor(weirdLevVal);
    //monitor(roomNum);
    //monitor(player);
    //monitor(levelNum);
    //monitor(levelMode);
    //monitor(overworldPortal);
    //monitor(overworldExitEvent);
    //monitor(submap);

    //var place = "X "+playerX.Current+", Y "+playerY.Current+"(io: "+prevIO+", room#: "+ roomNum.Current+", lev#: "+ levelNum.Current+")";
    //if (placed) dbg("PLACED | "+place);
    //if (shifted(cutScene) && cutScene.Current != 0 && cutScene.Current != 6 && cutScene.Current != 9) dbg(cutScene.Name + ": " + cutScene.Old + "->" + cutScene.Current);
    //if (shifted(roomNum)) dbg("NEW ROOM | "+place);
    //if (stepped(eventsTriggered)) dbg("EXIT");

    if (debugInfo.Any()) print(string.Join("\n", debugInfo));
	return splitStatus;
}
