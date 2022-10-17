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
    settings.Add("rooms", false, "All Room Changes");
    settings.SetToolTip("rooms", "Split when on room transitions even with CPs");
    settings.Add("flags", false, "Flags");
    settings.SetToolTip("flags", "Split when getting special non-CP states. Warning about idempotence!");
    settings.Add("worlds", false, "Overworlds");
    settings.SetToolTip("worlds", "Split when switching overworlds (use with subsplits)");
    settings.Add("levelStarts", true, "Level Starts");
    settings.SetToolTip("levelStarts", "Split at the start of each level");
}

init {
	vars.gamename = timer.Run.GameName;
	vars.livesplitGameName = vars.gamename;
	print(vars.gamename);

    var states = new Dictionary<int, long>
    {
        { 9646080,   0x97EE04 },      // Snes9x-rr 1.60
        { 13565952,  0x140925118 },   // Snes9x-rr (x64) 1.60/1.61
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
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1493)  { Name = "endtimer" },
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
        // Screen Width 005E
        // Screen height 005F
        // In Water 0075
        // 00F0 Level number + 1 maybe
        // 0100 Game Mode
        // 0109 weird level value
        // 010B 245 bytes stack, but first two bytes are usually level num
        // 0D9B IRQ or whatever for game modes
        // 0DB3 Player in play
        // 13BF translevel number but complicated
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
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x00F0)  { Name = "levNumPlusOne" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0100)  { Name = "gameMode" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x010B)  { Name = "levNumStack" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0DB3)  { Name = "player" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13BF)  { Name = "translevel" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1925)  { Name = "levelMode" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1935)  { Name = "levelStart" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1B9C)  { Name = "overworldPortal" },
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
    var endtimer =       vars.watchers["endtimer"]; // Only used by "Of Jumps and Platforms". TODO: Try to remove it.
    var yoshiCoin =      vars.watchers["yoshiCoin"]; // Only for BunBun 2
    var levelStart =     vars.watchers["levelStart"];
    var weirdLevVal =    vars.watchers["weirdLevVal"];
    var eventsTriggered = vars.watchers["eventsTriggered"];

    // Temporary Test properties
    var levNumPlusOne = vars.watchers["levNumPlusOne"];
    var gameMode = vars.watchers["gameMode"];
    var levNumStack = vars.watchers["levNumStack"];
    var player = vars.watchers["player"];
    var translevel = vars.watchers["translevel"];
    var levelMode = vars.watchers["levelMode"];
    var overworldPortal = vars.watchers["overworldPortal"];
    var overworldExitEvent = vars.watchers["overworldExitEvent"];

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
    if (io.Current != 0) {prevIO = io.Current;}
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

    // Default Split Conditions
    var start = stepTo(levelStart, 1);
    var goalExit = stepTo(fanfare, 1) && bossUndead && !gotOrb;  // didn't defeat boss already or get an Orb TODO: Mix "victory" into this condition
    var keyExit = shiftTo(io, 7);
    var orbExit = toOrb && bossUndead;
    var switchPalaceExit = stepTo(yellowSwitch, 1) || stepTo(greenSwitch, 1) || stepTo(blueSwitch, 1) || stepTo(redSwitch, 1);
    var bossExit = stepTo(fanfare, 1) && (bossDefeat.Current == 1 || bossDefeat.Current == 255); // TODO: Test whether non-zero would work here.
    var unknownExit = false;
    var peachReleased = stepTo(peach, 1);
    var tapeCP = stepTo(checkpointTape, 1) && !gotOrb && !gotGoal && !gotKey && !gotFadeout; // TODO: Must be a way to get tape after the first.
    var roomCP = false;
    var doorCP = false;
    var pipeCP = false;
    var room = roomStep; // TODO: If relying on this, may want to remove the room, door, pipe CPs above
    var coinFlag = false;
    var credits = false;
    var intro = shift(weirdLevVal, 233, 0);
    var worlds = shift(overworldPortal, 1, 0);

    /* NOTES:
     * A clear CP signal would be super helpful
     * Check that autosplit allows for autoskip and autoback
     * COuld use a checkpointTapeCounter implementation
     * Split cases should work with different %
     * Split cases should work with different split settings
     * Use Exit and other signals to detect and roll back Post-orb and post-goal deaths
     * Need to decide the defaults for retesting. With or without rooms? Seems should be with, but need to redo a bunch and deal with double-splits
     * Try C# Enums for pipes and cutScenes and maybe other nums
     */

    // Override Default split variables for individual games
	switch ((string) vars.gamename) {
        case "Bunbun World 2": // DONE (tested with rooms OFF. need to retest without intro or worlds)
            //intro = shift(io, 0, 69);
            tapeCP = tapeCP
                && io.Current != 61 // KLDC Dolphins
                && prevIO != 48 // Mirror Temple
                ;
            roomCP = shift(io, 64, 59) // Crystal Cove
                || roomStep && (io.Current == 68 || prevIO == 83) // Shifting Stronghold
                || roomStep && prevIO == 48 // Mirror Temple
                || roomStep && (prevIO == 81 || prevIO == 85) // Playtester Palace. TODO: Two Darkanine Splits is awkward. Could maybe solve by removing roomstep when "in" a 6->3->6 pipe in io81(but 0->3->0) is also in io81
                ;
            doorCP = shift(io, 75, 70); // Sumo Summit secret
            pipeCP = shift(pipe, 3, 7) && io.Current == 61  // KLDC Dolphins both CPs
                || roomStep && prevIO == 46 // Hazy Kaizo Cave pipes
                || roomStep && prevIO == 50 // Under Pressure (no tapes to cancel)
                || shift(pipe, 2, 5) && io.Current == 41 // Fire Wall Fortress 1st pipe
                || roomStep && prevIO == 55 // Twilight Thicket (no tapes to cancel)
                ;
            coinFlag = stepped(yoshiCoin) && io.Current == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
            /*
            worlds = shift(io, 69, 66) || shift(io, 66, 69) // World 1 and 2 transitions
                || shift(io, 69, 43)  // World 2 to 3
                || shift(io, 21, 43)  // Mario after Reset
                || shift(io, 43, 77); // Luigi in Starworld
            */
		break;
		case "Climb The Tower": // DONE (Ran with rooms OFF. retest intro.)
            //intro = shift(io, 41, 45);
            doorCP = shift(io, 50, 41);
		break;
		case "Cute Kaizo World": // DONE (retest for worlds and intro. Ran with rooms OFF)
            //worlds = shift(io, 48, 50) || shift(io, 50, 45);
            tapeCP = tapeCP && io.Current != 55;  // No tape checks in Zalzion castle. Using doors
            pipeCP = (shiftTo(pipe, 2) && io.Current == 47) // Kimball Secret final Pipe
                || (shiftTo(pipe, 5) && prevIO == 51) // Pink Switch 
                || (shiftTo(pipe, 5) && io.Current == 40) // Blue Switch
                ;
            doorCP = shiftTo(cutScene, 13);
            credits = shiftTo(io, 21);
		break;
        case "Love Yourself":
            /* TODO: Double-splitting to fix:
             * tape then room: CS, TT, TFW23
             * room then tape: RTB, W, PO
             * room then tape forced: TFW12
             * All room changes are not CPs in the above 7 double-splits
             * 
             * TFW 2nd and 3rd tapes don't work. Will need to fix double-splitting if tape counting is implemented.
             */
            worlds = worlds
                || shift(io, 23, 28) // World 2->3
                || shift(io, 28, 65) // World 3->End
                ;
        break;
        case "Purgatory": // DONE
            tapeCP = tapeCP
                && io.Current != 56  // Cancel for Sea Moon
                && io.Current != 49  // Cancel for Soft and Wet
                && io.Current != 63  // Cancel for Summit of Salvation
                ;
            pipeCP = shift(pipe, 3, 7) && io.Current == 58 // Dionaea 2
                || shiftTo(cutScene, 7) && io.Current == 43 // Cetaceans' Call 2
                || shift(pipe, 2, 6) && io.Current == 50 // Pipeline Blockage 2
                || shift(io, 31, 56)  // Sea Moon 1
                || shift(io, 41, 40)  // Drifting Den 1
                || shift(io, 40, 41)  // Drifting Den 3
                || shift(pipe, 1, 5) && io.Current == 42 // Road Nowhere 2
                || shift(io, 31, 49)  // Soft and Wet 1
                || shift(pipe, 1, 5) && io.Current == 52 // Woodland Tango 2
                || shift(pipe, 2, 6) && io.Current == 45 // Prickly Climb 2
                || shift(pipe, 2, 6) && io.Current == 57 // Muddied Barbed 2
                || shift(pipe, 2, 6) && io.Current == 48 // Supercool Fusion Secret 2
                || shift(pipe, 1, 5) && io.Current == 55 // Chocolate Disco 3
                || shift(pipe, 1, 6) && io.Current == 46 // Supercool Fusion 2
                || shift(pipe, 1, 5) && io.Current == 59 // Toxicavity 2
                || shift(pipe, 0, 6) && io.Current == 60 // Searing Subterrane 2
                || shift(pipe, 2, 6) && io.Current == 61; // Jump in Altitude 2
            roomCP = roomStep && io.Current == 56  // Sea Moon rooms 2+
                || roomStep && io.Current == 49  // Soft and Wet
                || roomStep && io.Current == 63  // Summit of Salvation
                || shift(io, 31, 55)  // Chocolate Disco 1
                || shift(io, 68, 54)  // Paradise 1 Vine
                || roomStep && io.Current == 54  // Paradise 2-10
                || shift(io, 68, 70)  // Paradise 11 Vine
                || roomStep && io.Current == 70;  // Paradise Final
            //worlds = shift(io, 47, 64) || shift(io, 64, 65) || shift(io, 65, 66) || shift(io, 66, 67) || shift(io, 67, 47);
        break;
		case "Quickie World": // DONE (except worlds. Ran with rooms OFF)
            pipeCP = shift(io, 46, 52);  // Whitemoth Layer
		break;
		case "Quickie World 2": // DONE (except worlds. Ran with rooms OFF)
		    tapeCP = tapeCP && io.Current != 65;  // Yoshi's Lair 1 Tape
            doorCP = shift(io, 60, 49)  // Roll the Bones Door
                || shift(io, 65, 42)  // Yoshi's Lair 1 Door
                || shift(io, 17, 49);  // Final Boss Door
            pipeCP = shift(io, 42, 17);  // Yoshi's Lair 2 Pipe
        break;
	}
    
    // Construct high level split conditions
    var levelExit = goalExit || keyExit || orbExit || switchPalaceExit || bossExit || unknownExit; // TODO: All unknownExits need to be tested and lumped into existing exit types
    var bossDefeated = false;
    var checkpoint = tapeCP || doorCP || pipeCP || roomCP;
    var flag = coinFlag;
    var runDone = peachReleased || credits;
    var overworld = intro || worlds;
    var splitStatus = runDone
        || (isLevelStarts && start)
        || (isLevels && levelExit) 
        || (isBosses && bossDefeated) 
        || (isCheckpoints && checkpoint) 
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
        if (tapeCP) reasons += " tapeCP";
        if (doorCP) reasons += " doorCP";
        if (pipeCP) reasons += " pipeCP";
        if (roomCP) reasons += " roomCP";
        if (room) reasons += " room";
        if (coinFlag) reasons += " coinFlag";
        if (peachReleased) reasons += " peachReleased";
        if (credits) reasons += " credits";
        if (intro) reasons += " intro";
        if (worlds) reasons += " worlds";
        dbg("SPLIT: "+reasons);
    }   

    /*
	if (shifted(cutScene)) {
		switch ((int) cutScene.Current) {
			case 0: dbg("PLAYING"); break;
			case 5: dbg("WARPING HORIZONTAL"); break;
			case 6: dbg("WARPING VERTICAL"); break;
			case 9: dbg("DEAD"); break;
            case 16: dbg("DOOR"); break;
		}
	}*/
    
    monitor(pipe);
    monitor(io);
    //monitor(checkpointTape);
    //monitor(cutScene);
    //if (shifted(cutScene) && cutScene.Current != 0 && cutScene.Current != 6 && cutScene.Current != 9) dbg(cutScene.Name + ": " + cutScene.Old + "->" + cutScene.Current);
    monitor(roomCounter);
    monitor(levNumPlusOne);
    //monitor(gameMode);
    monitor(weirdLevVal);
    monitor(levNumStack);
    monitor(player);
    monitor(translevel);
    monitor(levelMode);
    monitor(overworldPortal);
    monitor(overworldExitEvent);
    
    if (shifted(levNumStack)) dbg("NEW ROOM");
    if (shiftTo(io, 8)) dbg("FADE OUT");
    if (stepped(eventsTriggered)) dbg("EXIT");

    if (debugInfo.Any()) print(string.Join("\n", debugInfo));
	return splitStatus;
}
