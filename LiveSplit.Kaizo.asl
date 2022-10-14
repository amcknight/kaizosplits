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
    settings.SetToolTip("checkpoints", "Split when getting a checkpoint, whether it's the tape or a room transition");
    settings.Add("worlds", false, "Overworlds");
    settings.SetToolTip("worlds", "Split when switching overworlds (use with subsplits)");
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
        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x1434)  { Name = "keyholeTimer" }, // TODO: Can this be made an int without breaking stuff?
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1ED2)  { Name = "fileSelect" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0xDB4)   { Name = "fileSelect_Baby" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x906)   { Name = "fanfare" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1B99)  { Name = "victory" },
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1DFB)  { Name = "io" },  // SPC700 I/0 Ports. Related to music? Important for many transitions.
		new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x18390) { Name = "orb_climb" },  // Only used in Climb the Tower. TODO: Would be good to get rid of
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1493)  { Name = "endtimer" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f28)  { Name = "yellowSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f27)  { Name = "greenSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f29)  { Name = "blueSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x1f2a)  { Name = "redSwitch" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x141A)  { Name = "roomCounter" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13C6)  { Name = "bossDefeat" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x190D)  { Name = "peach" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x13CE)  { Name = "checkpointTape" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0089)  { Name = "enterOrExitPipe" },
        new MemoryWatcher<byte>((IntPtr) memoryOffset + 0x0071)  { Name = "cutScene" },
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
    var isLevels =        settings["levels"];
    var isBosses =        settings["bosses"];
    var isCheckpoints =   settings["checkpoints"];
    var isWorlds =        settings["worlds"];

    // Vars
    var fanfare =         vars.watchers["fanfare"];
    var victory =         vars.watchers["victory"];
    var bossDefeat =      vars.watchers["bossDefeat"];
    var keyholeTimer =    vars.watchers["keyholeTimer"];
    var io =              vars.watchers["io"];
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

    // Convenience functions
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, int, bool> shift = (watcher, o, c) => watcher.Old == o && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, int, bool> shiftTo = (watcher, c) => watcher.Old != c && watcher.Current == c;
    Func<LiveSplit.ComponentUtil.MemoryWatcher<byte>, bool> shifted = watcher => watcher.Old != watcher.Current;
    Func<int, bool> afterSeconds = s => vars.stopwatch.ElapsedMilliseconds > s*1000;

    // Composite Vars
    var enteredPipe = shifted(enterOrExitPipe) && enterOrExitPipe.Current < 4 && ((cutScene.Current == 5) || (cutScene.Current == 6));
    var roomUptick = roomCounter.Old > 0 && (roomCounter.Old + 1) == roomCounter.Current;
    var toOrb = shiftTo(io, 3);
    var toGoal = shiftTo(io, 4);
    var gotOrb = io.Current == 3;
    var gotGoal = io.Current == 4;
    var gotFadeout = io.Current == 8;
    var bossUndead = bossDefeat.Current == 0;

    // Default Split Conditions
    var goalExit = shift(fanfare, 0, 1) && bossUndead && !gotOrb;  // didn't defeat boss already and didn't got orb  TODO: Mix "victory" into this condition
    var keyExit = keyholeTimer.Old == 0 && keyholeTimer.Current == 48; // Doesn't use shift because it's a short
    var orbExit = toOrb && bossUndead;
    var switchPalaceExit = shift(yellowSwitch, 0, 1) || shift(greenSwitch, 0, 1) || shift(blueSwitch, 0, 1) || shift(redSwitch, 0, 1);
    var bossExit = shift(fanfare, 0, 1) && (bossDefeat.Current == 1 || bossDefeat.Current == 255);
    var unknownExit = false;
    var peachReleased = shift(peach, 0, 1);
    var tapeCP = shift(checkpointTape, 0, 1) && !gotOrb && !gotGoal && !gotFadeout; // TODO: Must be a way to get tape after the first.
    var roomCP = false;
    var doorCP = false;
    var pipeCP = false;
    var credits = false;

    // Override Default split variables for individual games
	switch ((string) vars.gamename) {
		case "Akogare 2": // orbExit 152
			unknownExit = shift(io, 255, 56);
		break;
		case "Boogie Wonderland":
		    unknownExit = shift(io, 83, 79);
		break;
		case "Casio Mario World":
			unknownExit = shift(io, 128, 26);
		break;
		case "Climb The Tower":
			orbExit = (orb_climb.Old == 57 || orb_climb.Old == 3) && orb_climb.Current == 56 && fanfare.Current != 1;
		break;
		case "Cute Kaizo World": // DONE worlds 48->50->45
            tapeCP = tapeCP && io.Current != 55;  // No tape checks in Zalzion castle. Using doors
            pipeCP = (shiftTo(enterOrExitPipe, 2) && io.Current == 47) // Kimball Secret final Pipe
                || (shiftTo(enterOrExitPipe, 5) && (io.Current == 0 || io.Current == 51)) // Pink Switch (P-Switch on=0 off=51)  
                || (shiftTo(enterOrExitPipe, 5) && io.Current == 40); // Blue Switch
            doorCP = shiftTo(cutScene, 13);
            credits = shiftTo(io, 21);
		break;
		case "Dreams":
			unknownExit = shift(io, 57, 4) || shift(io, 255, 54);
		break;
		case "El Dorado":
			unknownExit = shift(io, 56, 64) || shift(io, 51, 0);
		break;
		case "Grand Poo World 2": // orbExit 44 83 84 90
			unknownExit = shift(io, 86, 92) || shift(io, 88, 91);
		break;
		case "Mahogen": // orbExit 0 71
		break;
		case "Little Mario World": // orbExit 66
    		bossExit = shift(fanfare, 0, 1) && bossDefeat.Current == 1;
		break;
		case "Invictus": // orbExit 67 49
			credits = shift(io, 255, 107);
		break;
		case "Of Jumps and Platforms":
			goalExit = shift(endtimer, 0, 255);
		break;
		case "Orcus":
			unknownExit = shift(io, 63, 68);
		break;	
        case "Peachy Moat World": // orbExit 67 49
		break;
		case "Polyphony": // orbExit 52
			unknownExit = shift(io, 87, 74);
		break;
        case "Purgatory": // DONE worlds 64 -> 65 -> 66 -> 67 -> 47
            tapeCP = tapeCP
                && io.Current != 56   // Cancel for Sea Moon
                && io.Current != 49   // Cancel for Soft and Wet
                && io.Current != 63;  // Cancel for Summit of Salvation
            pipeCP = 
                (  (shift(enterOrExitPipe, 3, 7) && io.Current == 58) // Dionaea 2
                || (shiftTo(cutScene, 7) && io.Current == 43)         // Cetaceans' Call 2
                || (shift(enterOrExitPipe, 2, 6) && io.Current == 50) // Pipeline Blockage 2
                || shift(io, 31, 56)  // Sea Moon 1
                || shift(io, 41, 40)  // Drifting Den 1
                || shift(io, 40, 41)  // Drifting Den 3
                || (shift(enterOrExitPipe, 1, 5) && io.Current == 42) // Road Nowhere 2
                || shift(io, 31, 49)  // Soft and Wet 1
                || (shift(enterOrExitPipe, 1, 5) && io.Current == 52) // Woodland Tango 2
                || (shift(enterOrExitPipe, 2, 6) && io.Current == 45) // Prickly Climb 2
                || (shift(enterOrExitPipe, 2, 6) && io.Current == 57) // Muddied Barbed 2
                || (shift(enterOrExitPipe, 2, 6) && io.Current == 48) // Supercool Fusion Secret 2
                || (shift(enterOrExitPipe, 1, 5) && io.Current == 55) // Chocolate Disco 3
                || (shift(enterOrExitPipe, 1, 6) && io.Current == 46) // Supercool Fusion 2
                || (shift(enterOrExitPipe, 1, 5) && io.Current == 59) // Toxicavity 2
                || (shift(enterOrExitPipe, 0, 6) && io.Current == 60) // Searing Subterrane 2
                || (shift(enterOrExitPipe, 2, 6) && io.Current == 61) // Jump in Altitude 2
                );
            roomCP = 
                (  roomUptick && io.Current == 56  // Sea Moon rooms 2+
                || roomUptick && io.Current == 49  // Soft and Wet
                || roomUptick && io.Current == 63  // Summit of Salvation
                || shift(io, 31, 55)  // Chocolate Disco 1
                || shift(io, 68, 54)  // Paradise 1 Vine
                || roomUptick && io.Current == 54  // Paradise 2-10
                || shift(io, 68, 70)  // Paradise 11 Vine
                || roomUptick && io.Current == 70  // Paradise Final
            );
        break;
		case "Quickie World": // DONE
            pipeCP = shift(io, 46, 52);  // Whitemoth Layer
		break;
		case "Quickie World 2": // DONE orbExit 68 67 61
		    tapeCP = shift(checkpointTape, 0, 1)
                && io.Current != 65;  // Yoshi's Lair 1 Tape
            doorCP = 
                (shift(io, 60, 49)  // Roll the Bones Door
                || shift(io, 65, 42)  // Yoshi's Lair 1 Door
                || shift(io, 17, 49)  // Final Boss Door
                );
            pipeCP = shift(io, 42, 17);  // Yoshi's Lair 2 Pipe
        break;
		case "Shell's Retriever": // orbExit 67 49
			goalExit = shift(victory, 0, 1);
		break;
		case "Shellax":
			unknownExit = shift(io, 255, 53);
		break;
		case "Silencio":
			goalExit = shift(victory, 0, 1);
            unknownExit = shift(io, 255, 88);
		break;
		case "Super Joe Bros. 2": // orbExit 64
			unknownExit = shift(io, 19, 49);
		break;
		case "Super Swunsh World 2": // orbExit 38 32
			goalExit = shift(victory, 0, 1);
            bossExit = shift(fanfare, 0, 1) && bossDefeat.Current == 255;
            unknownExit = shift(io, 45, 4);
            credits = shift(io, 255, 56);
		break;
        case "The Joy of Kaizo": // orbExit 67 49
		    goalExit = shift(victory, 0, 1);
            bossExit = shift(bossDefeat, 0, 1);
		break;
	}
    
    // Construct high level split conditions
    var levelExit = goalExit || keyExit || orbExit || switchPalaceExit || bossExit || unknownExit; // TODO: All unknownExits need to be tested and lumped into existing exit types
    var bossDefeated = false;
    var checkpoint = tapeCP || doorCP || pipeCP || roomCP;
    var runDone = peachReleased || credits;
    var splitStatus = runDone || (isLevels && levelExit) || (isBosses && bossDefeated) || (isCheckpoints && checkpoint);

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
        if (goalExit) reasons += " goalExit";
        if (keyExit) reasons += " keyExit";
        if (orbExit) reasons += " orbExit";
        if (switchPalaceExit) reasons += " switchPalaceExit";
        if (bossExit) reasons += " bossExit";
        if (tapeCP) reasons += " tapeCP";
        if (doorCP) reasons += " doorCP";
        if (pipeCP) reasons += " pipeCP";
        if (roomCP) reasons += " roomCP";
        if (peachReleased) reasons += " peachReleased";
        if (credits) reasons += " credits";
        dbg("Split Reasons:"+reasons);
    }

    
	if (shifted(cutScene)) {
		switch ((int) cutScene.Current) {
			case 0: dbg("PLAYING"); break;
			case 5: dbg("WARPING HORIZONTAL"); break;
			case 6: dbg("WARPING VERTICAL"); break;
			case 9: dbg("DEAD"); break;
            case 16: dbg("DOOR"); break;
		}
	}
    
    monitor(enterOrExitPipe);
    monitor(io);
//if (io.Old != io.Current && io.Old != 8 && io.Current != 8) dbg(io.Name + ": " + io.Old + "->" + io.Current);
monitor(checkpointTape);
    monitor(cutScene);
    //if (cutScene.Old != cutScene.Current && cutScene.Current != 0 && cutScene.Current != 6 && cutScene.Current != 9) dbg(cutScene.Name + ": " + cutScene.Old + "->" + cutScene.Current);

    monitor(enterOrExitPipe);
    monitor(roomCounter);
    //if (roomCounter.Old != roomCounter.Current && roomCounter.Old != 0 && roomCounter.Current != 0) dbg(roomCounter.Name + ": " + roomCounter.Old + "->" + roomCounter.Current);

    if (debugInfo.Any()) print(string.Join("\n", debugInfo));

	return splitStatus;
}
