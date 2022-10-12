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
    settings.Add("switchPalaces", true, "Switch Palaces");
    settings.SetToolTip("switchPalaces", "Split on completing a switch palace");
    settings.Add("checkpointTape", true, "Checkpoint Tape");
    settings.SetToolTip("checkpointTape", "Split when running into the Checkpoint Tape");
    settings.Add("levelDoorPipe", false, "Level Room Transitions");
    settings.SetToolTip("levelDoorPipe", "Split on door and pipe transitions within standard levels and switch palaces");
    settings.Add("castleDoorPipe", false, "Castle/GH Room Transitions");
    settings.SetToolTip("castleDoorPipe", "Split on door and pipe transitions within ghost houses and castles");
    settings.Add("bowserPhase", false, "Bowser Phase Transition");
    settings.SetToolTip("bowserPhase", "Split when transitioning between Bowser's phases (not tested on Cloud runs)");
    settings.Add("enterPipe", false, "Enter a Pipe");
    settings.SetToolTip("enterPipe", "Split when entering any pipe");
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
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x1434) { Name = "keyholeTimer" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1ED2)  { Name = "fileSelect" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0xDB4)   { Name = "fileSelect_Baby" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x906)   { Name = "fanfare" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1B99)  { Name = "victory" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1DFB)  { Name = "orb" },  // Calling this "orbs" is a misnomer. Seems to be more about music.
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x18390) { Name = "orb_climb" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1493)  { Name = "endtimer" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f28)  { Name = "yellowSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f27)  { Name = "greenSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f29)  { Name = "blueSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f2a)  { Name = "redSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x141A)  { Name = "roomCounter" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1B9B)  { Name = "yoshiBanned" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x13C6)  { Name = "bossDefeat" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1429)  { Name = "bowserPalette" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x190D)  { Name = "peach" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x13CE)  { Name = "checkpointTape" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0089)  { Name = "enterOrExitPipe" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x0071)  { Name = "cutScene" },
    };

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
    var isLevels =         settings["levels"];
    var isSwitchPalaces =  settings["switchPalaces"];
    var isLevelDoorPipe =  settings["levelDoorPipe"];
    var isCastleDoorPipe = settings["castleDoorPipe"];
    var isBosses =         settings["bosses"];
    var isCheckpointTape = settings["checkpointTape"];
    var isEnterPipe =      settings["enterPipe"];

    // Vars
    var fanfare =         vars.watchers["fanfare"];
    var victory =         vars.watchers["victory"];
    var bossDefeat =      vars.watchers["bossDefeat"];
    var keyholeTimer =    vars.watchers["keyholeTimer"];
    var orb =             vars.watchers["orb"];
    var orb_climb =       vars.watchers["orb_climb"];
    var yellowSwitch =    vars.watchers["yellowSwitch"];
    var greenSwitch =     vars.watchers["greenSwitch"];
    var blueSwitch =      vars.watchers["blueSwitch"];
    var redSwitch =       vars.watchers["redSwitch"];
    var roomCounter =     vars.watchers["roomCounter"];
    var peach =           vars.watchers["peach"];
    var checkpointTape =  vars.watchers["checkpointTape"];
    var enterOrExitPipe = vars.watchers["enterOrExitPipe"];
    var cutScene =        vars.watchers["cutScene"];
    var endtimer =        vars.watchers["endtimer"]; // Only used by "Of Jumps and Platforms". TODO: Try to remove it.

    Func<int, bool> afterSeconds = s => vars.stopwatch.ElapsedMilliseconds > s*1000;

    // Convenience function for testing whether a watcher var shifted from an Old value to a Current one
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, int, bool> shift = (watcher, o, c) => watcher.Old == o && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> shiftTo = (watcher, c) => watcher.Old != c && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> anyShift = watcher => watcher.Old != watcher.Current;

    // Composite Vars
    var yellowPalace = isSwitchPalaces && shift(yellowSwitch, 0, 1);
    var greenPalace = isSwitchPalaces && shift(greenSwitch, 0, 1);
    var bluePalace = isSwitchPalaces && shift(blueSwitch, 0, 1);
    var redPalace = isSwitchPalaces && shift(redSwitch, 0, 1);

    // Split Conditions
    var goalExit = isLevels && shift(fanfare, 0, 1) && bossDefeat.Current == 0;  // TODO: Mix "victory" into this condition
    var keyExit = isLevels && keyholeTimer.Old == 0 && keyholeTimer.Current == 48; // Doesn't use shift because it's a short
    var orbExit = shiftTo(orb, 3) && bossDefeat.Current == 0;
    var bossExit = isBosses && shift(fanfare, 0, 1) && (bossDefeat.Current == 1 || bossDefeat.Current == 255);  // TODO: Find better bossDefeat default (and hopefully remove it from goalExit?)
    var switchPalaceExit = yellowPalace || greenPalace || bluePalace || redPalace;
    var bowserDefeated = isBosses && shift(peach, 0, 1);
    var checkpoint = isCheckpointTape && shift(checkpointTape, 0, 1);
	var enteredPipe = isEnterPipe && anyShift(enterOrExitPipe) && enterOrExitPipe.Current < 4 && cutScene.Old == 0 && (cutScene.Current == 5 || cutScene.Current == 6);
    var credits = false;  // Not used by default. TODO: Try to make it default.

    // Override Default split variables for individual games
	switch ((string) vars.gamename) {
		case "The Joy of Kaizo": //orb 67, 49
			goalExit = isLevels && shift(victory, 0, 1) && bossDefeat.Current == 0;
			bossExit = isBosses && shift(bossDefeat, 0, 1);
		break;
		case "Climb The Tower":
			orbExit = isLevels && (orb_climb.Old == 57 || orb_climb.Old == 3) && orb_climb.Current == 56 && fanfare.Current != 1 && afterSeconds(25);
			bossExit = isBosses && shift(fanfare, 0, 1) && bossDefeat.Current == 1 && afterSeconds(25);
		break;
		case "Peachy Moat World": //orb 67, 49
			bossExit = isBosses && shift(bossDefeat, 0, 1) && afterSeconds(25);
		break;
		case "Little Mario World": //orb 66
    		bossExit = isBosses && shift(fanfare, 0, 1) && bossDefeat.Current == 1;
		break;
		case "Super Swunsh World 2": // orb 38, 32
			goalExit = isLevels && shift(victory, 0, 1) && bossDefeat.Current == 0 && afterSeconds(20);
			orbExit = isLevels && (shiftTo(orb, 3) || shift(orb, 45, 4));
			bossExit = isBosses && shift(fanfare, 0, 1) && bossDefeat.Current == 255 && afterSeconds(20);
            credits = isLevels && shift(orb, 255, 56);
		break;
		case "Shell's Retriever": // orb 67, 49
			goalExit = isLevels && shift(victory, 0, 1) && bossDefeat.Current == 0 && afterSeconds(20);
			bossExit = isBosses && bossDefeat.Current == 1 && afterSeconds(20);
		break;
		case "Invictus": // orb 67, 49
			credits = isLevels && shift(orb, 255, 107);
		break;
		case "El Dorado":
			orbExit = isLevels && (shift(orb, 56, 64) || shift(orb, 51, 0)) && bossDefeat.Current == 0;
		break;
		case "Quickie World": // orb 6, 10
		break;
		case "Quickie World 2": // orb 68, 67, 61
			/*
             orbExit = isLevels && (
                (  orb.Old == 68  // Soaring Saguaro
                || orb.Old == 67  // RB's Clock Tower
                || orb.Old == 61  // The ChrisG Spot
                ) && orb.Current == 3);
            */
		    checkpoint = isCheckpointTape && ((shift(checkpointTape, 0, 1)
                && orb.Current != 3   // Roll the Bones Boss
                && orb.Current != 65  // Yoshi's Lair 1 Tape
                )
                || shift(orb, 60, 49)  // Roll the Bones Door
                || shift(orb, 65, 42)  // Yoshi's Lair 1 Door
                || shift(orb, 42, 17)  // Yoshi's Lair 2 Pipe
                || shift(orb, 17, 49)  // Final Boss Door
            );
        break;
        case "Purgatory":
    /* TODO:
     * 2nd CPs don't seem to work. (Sea Moon, Summit of Salvation, maybe Paradise) 
     * Missing important transitions in Summit of Salvation 1 and 4 (no easy orb diff)
     * Missing almost all Paradise transitions (2,3,4,5,6,7,8,9,final) (no easy orb diff)
     */
            checkpoint = isCheckpointTape && (shift(checkpointTape, 0, 1)
                || shift(orb, 31, 56)  // Sea Moon 1 Pipe
                || shift(orb, 41, 40)  // Drifting Den 1 Pipe
                || shift(orb, 40, 41)  // Drifting Den 3 Pipe
                || shift(orb, 31, 40)  // Soft and Wet 1 Pipe
                || shift(orb, 31, 55)  // Chocolate Disco 1 Pipe
                || shift(orb, 68, 54)  // Paradise 1 Vine
                || shift(orb, 54, 68)  // Paradise 10 Vine
                || shift(orb, 68, 70)  // Paradise 11 Vine
            );
        break;
		case "Grand Poo World 2":
			orbExit = isLevels && (shift(orb, 44, 3) || shift(orb, 83, 3) || shift(orb, 84, 3) || shift(orb, 90, 3) || shift(orb, 86, 92) || shift(orb, 88, 91)) && afterSeconds(20);
		break;
		case "Mahogen": // orb 0, 71
		break;
		case "Shellax":
			orbExit = isLevels && shift(orb, 255, 53) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Akogare 2":
			orbExit = isLevels && (shift(orb, 152, 3) || shift(orb, 255, 56)) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Casio Mario World":
			orbExit = isLevels && shift(orb, 128, 26) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Orcus":
			orbExit = isLevels && shift(orb, 63, 68) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Dreams":
			orbExit = isLevels && (shift(orb, 57, 4) || shift(orb, 255, 54)) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Boogie Wonderland":
			orbExit = isLevels && shift(orb, 83, 79) && bossDefeat.Current == 0 && afterSeconds(25);
			bossExit = isBosses && (shift(bossDefeat, 0, 1) || shift(bossDefeat, 0, 255)) && afterSeconds(20);
		break;
		case "Silencio":
			goalExit = isLevels && shift(victory, 0, 1) && bossDefeat.Current == 0 && afterSeconds(20);
			orbExit = isLevels && shift(orb, 255, 88) && bossDefeat.Current == 0 && afterSeconds(25);
			bossExit = isBosses && (shift(bossDefeat, 0, 1) || shift(bossDefeat, 0, 255)) && afterSeconds(20);
		break;
		case "Polyphony":
			orbExit = isLevels && (shift(orb, 52, 3) || shift(orb, 87, 74)) && bossDefeat.Current == 0 && afterSeconds(25);
		break;
		case "Super Joe Bros. 2":
			orbExit = isLevels && (shift(orb, 64, 3) || shift(orb, 19, 49)) && bossDefeat.Current == 0 && afterSeconds(25);
			bossExit = isBosses && (shift(bossDefeat, 0, 1) || shift(bossDefeat, 0, 255)) && afterSeconds(20);
		break;
		case "Of Jumps and Platforms":
			goalExit = isLevels && shift(endtimer, 0, 255) && afterSeconds(20);
		break;
	}
    
	if (goalExit || bossExit || orbExit || keyExit || switchPalaceExit) vars.stopwatch.Restart();
    /*
	if (cutScene.Old != cutScene.Current) {
		switch ((int) cutScene.Current) {
			case 0: print("PLAYING"); break;
			case 5: print("WARPING HORIZONTAL"); break;
			case 6: print("WARPING VERTICAL"); break;
			case 9: print("DEAD"); break;
            case 16: print("DOOR"); break;
		}
	}
	if (enterOrExitPipe.Old != enterOrExitPipe.Current) print("Pipes " + enterOrExitPipe.Old + "->" + enterOrExitPipe.Current);
    */
    if (roomCounter.Old != roomCounter.Current) print("Rooms " + roomCounter.Old + "->" + roomCounter.Current);
    if (orb.Old != orb.Current) {
        if (orb.Current == 3) {
            print("OOOOOOOOORRRRRRBBBB");
        }
        print("Orbs " + orb.Old + "->" + orb.Current);
    }
/*
    if (goalExit || keyExit || switchPalaceExit || bossExit || bowserDefeated || checkpoint || enteredPipe || credits) {
        print("goalExit "+goalExit+", keyExit "+keyExit+", switchPalaceExit "+switchPalaceExit+", bossExit "+bossExit+", bowserDefeated "+bowserDefeated+", checkpoint "+checkpoint+", enteredPipe"+enteredPipe+", credits "+credits);
        print("CP: "+checkpointTape.Old + ", " + checkpointTape.Current);
    }
    */
	return goalExit || keyExit || orbExit || switchPalaceExit || bossExit || bowserDefeated || checkpoint || enteredPipe || credits;
}
