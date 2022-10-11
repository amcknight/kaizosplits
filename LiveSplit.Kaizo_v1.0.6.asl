state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {}
startup
{
	vars.stopwatch = new Stopwatch();
    settings.Add("levels", true, "Normal Levels");
    settings.SetToolTip("levels", "Split on crossing goal tapes and activating keyholes");
    settings.Add("bosses", true, "Boss Levels");
    settings.SetToolTip("bosses", "Split on boss fanfare");
    settings.Add("switchPalaces", false, "Switch Palaces");
    settings.SetToolTip("switchPalaces", "Split on completing a switch palace");
    settings.Add("levelDoorPipe", false, "Level Room Transitions");
    settings.SetToolTip("levelDoorPipe", "Split on door and pipe transitions within standard levels and switch palaces");
    settings.Add("castleDoorPipe", false, "Castle/GH Room Transitions");
    settings.SetToolTip("castleDoorPipe", "Split on door and pipe transitions within ghost houses and castles");
    settings.Add("bowserPhase", false, "Bowser Phase Transition");
    settings.SetToolTip("bowserPhase", "Split on the transition between Bowser's phases (not tested on Cloud runs)");
}

init
{
	vars.gamename = timer.Run.GameName;
	vars.livesplitGameName = vars.gamename;
	print(vars.gamename);

    var states = new Dictionary<int, long>
    {
        { 9646080, 0x97EE04 },      // Snes9x-rr 1.60
        { 13565952, 0x140925118 },  // Snes9x-rr 1.60 (x64)
        { 9027584, 0x94DB54 },      // Snes9x 1.60
        { 12836864, 0x1408D8BE8 },  // Snes9x 1.60 (x64)
        { 16019456, 0x94D144 },     // higan v106
        { 15360000, 0x8AB144 },     // higan v106.112
		{ 22388736, 0xB0ECC8 },     // higan v107
		{ 23142400, 0xBC7CC8 },     // higan v108
		{ 23166976, 0xBCECC8 },     // higan v109
		{ 23224320, 0xBDBCC8 },     // higan v110
        { 10096640, 0x72BECC },     // bsnes v107
        { 10338304, 0x762F2C },     // bsnes v107.1
        { 47230976, 0x765F2C },     // bsnes v107.2/107.3
        { 131543040, 0xA9BD5C },    // bsnes v110
        { 51924992, 0xA9DD5C },     // bsnes v111
        { 52056064, 0xAAED7C },     // bsnes v112
		{ 52477952, 0xB16D7C },     // bsnes v115
        { 7061504, 0x36F11500240 }, // BizHawk 2.3
        { 7249920, 0x36F11500240 }, // BizHawk 2.3.1
        { 6938624, 0x36F11500240 }, // BizHawk 2.3.2
    };

    long memoryOffset = 0;
	if ( game.ProcessName.ToLower() == "retroarch" ) {
		ProcessModuleWow64Safe libretromodule = modules.Where(m => m.ModuleName == "snes9x_libretro.dll").First();
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
	} else {
		if (states.TryGetValue(modules.First().ModuleMemorySize, out memoryOffset))
			if (memory.ProcessName.ToLower().Contains("snes9x"))
				memoryOffset = memory.ReadValue<int>((IntPtr)memoryOffset);
	}
	if (memoryOffset == 0)
		throw new Exception("Memory not yet initialized.");

    vars.watchers = new MemoryWatcherList
    {
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1ED2) { Name = "fileSelect" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0xDB4) { Name = "fileSelect_Baby"},

        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x906) { Name = "fanfare" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1B99) { Name = "victory" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1DFB) { Name = "orb" },
		new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x18390) { Name = "orb_climb" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1493) { Name = "endtimer" },

        new MemoryWatcher<short>((IntPtr)memoryOffset + 0x1434) { Name = "keyholeTimer" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f28) { Name = "yellowSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f27) { Name = "greenSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f29) { Name = "blueSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1f2a) { Name = "redSwitch" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x141A) { Name = "roomCounter" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1B9B) { Name = "yoshiBanned" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x13C6) { Name = "bossDefeat" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x1429) { Name = "bowserPalette" },
        new MemoryWatcher<byte>((IntPtr)memoryOffset + 0x190D) { Name = "peach" },
    };

	vars.reInitialise = (Action)(() => {
		vars.gamename = timer.Run.GameName;
		vars.livesplitGameName = vars.gamename;
		print(vars.gamename);
	});

	vars.reInitialise();
}

update
{
    vars.watchers.UpdateAll(game);
	if (vars.livesplitGameName != timer.Run.GameName) {
		vars.gamename = timer.Run.GameName;
        vars.reInitialise();
	}
}

start
{
	vars.stopwatch.Restart();
	switch ((string) vars.gamename){
	case "Baby Kaizo World":
		return vars.watchers["fileSelect_Baby"].Old == 0 && vars.watchers["fileSelect_Baby"].Current == 4;
		break;
	case "Super ShyGuy's Epic Journey":
		return vars.watchers["fileSelect_Baby"].Old == 0 && vars.watchers["fileSelect_Baby"].Current == 98;
		break;
	case "Of Jumps and Platforms":
		return vars.watchers["fileSelect_Baby"].Old == 0 && vars.watchers["fileSelect_Baby"].Current >= 1;
		break;
	default:
		return vars.watchers["fileSelect"].Old == 0 && vars.watchers["fileSelect"].Current >= 1;
	};
}

reset
{
   	switch ((string) vars.gamename){
	case "Baby Kaizo World":
		return vars.watchers["fileSelect_Baby"].Old != 0 && vars.watchers["fileSelect_Baby"].Current == 0;
		break;
	case "Super ShyGuy's Epic Journey":
		return vars.watchers["fileSelect_Baby"].Old != 0 && vars.watchers["fileSelect_Baby"].Current == 0;
		break;
	case "Of Jumps and Platforms":
		return vars.watchers["fileSelect_Baby"].Old != 0 && vars.watchers["fileSelect_Baby"].Current == 0;
		break;
	default:
		return vars.watchers["fileSelect"].Old != 0 && vars.watchers["fileSelect"].Current == 0;
	};
}

split
{
	//TimeSpan ts = vars.stopwatch.Elapsed;
	//print(ts.ToString(@"m\:ss\.ff"));
	switch ((string) vars.gamename){

		case "The Joy of Kaizo":

			var goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0;
			var keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030;

			var orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 67 && vars.watchers["orb"].Current == 3) || (vars.watchers["orb"].Old == 49 && vars.watchers["orb"].Current == 3)) && vars.watchers["bossDefeat"].Current == 0;
			var yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			var greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			var bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			var redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			var switchPalaceExit = yellowPalace || greenPalace || bluePalace || redPalace;

			var levelDoorPipe = settings["levelDoorPipe"] && (vars.watchers["roomCounter"].Old + 1) == vars.watchers["roomCounter"].Current && vars.watchers["yoshiBanned"].Current == 0;
			var castleDoorPipe = settings["castleDoorPipe"] && (vars.watchers["roomCounter"].Old + 1) == vars.watchers["roomCounter"].Current && vars.watchers["yoshiBanned"].Current == 1;

			var bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Old == 0 && vars.watchers["bossDefeat"].Current == 1;
			var bowserPhase = settings["bowserPhase"] && vars.watchers["bowserPalette"].Old == 4 && vars.watchers["bowserPalette"].Current == 7;
			var bowserDefeated = settings["bosses"] && vars.watchers["peach"].Old == 0 && vars.watchers["peach"].Current == 1;

			return goalExit || keyExit || orbExit || switchPalaceExit || levelDoorPipe || castleDoorPipe || bossExit || bowserPhase || bowserDefeated;
		break;

		case "Climb The Tower":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;
			orbExit = settings["levels"] && (vars.watchers["orb_climb"].Old == 57 || vars.watchers["orb_climb"].Old == 3) && vars.watchers["orb_climb"].Current == 56 && vars.watchers["fanfare"].Current != 1 && vars.stopwatch.ElapsedMilliseconds > 25000;

			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 1 && vars.stopwatch.ElapsedMilliseconds > 25000;

			if (goalExit == true || orbExit == true || bossExit == true) {
				vars.stopwatch.Restart();
			}
			return goalExit || orbExit || bossExit;
		break;

		case "Peachy Moat World":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 25000;

			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 67 && vars.watchers["orb"].Current == 3) || (vars.watchers["orb"].Old == 49 && vars.watchers["orb"].Current == 3)) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;
			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 25000;

			bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Old == 0 && vars.watchers["bossDefeat"].Current == 1 && vars.stopwatch.ElapsedMilliseconds > 25000;
			bowserPhase = settings["bowserPhase"] && vars.watchers["bowserPalette"].Old == 4 && vars.watchers["bowserPalette"].Current == 7;
			bowserDefeated = settings["bosses"] && vars.watchers["peach"].Old == 0 && vars.watchers["peach"].Current == 1;
			if (goalExit == true || orbExit == true || bossExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
			}
			return goalExit || keyExit || orbExit || switchPalaceExit || bossExit || bowserPhase || bowserDefeated;
		break;

		case "Little Mario World":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030;

			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 66 && vars.watchers["orb"].Current == 3) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;
			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 25000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 1;
			bowserPhase = settings["bowserPhase"] && vars.watchers["bowserPalette"].Old == 4 && vars.watchers["bowserPalette"].Current == 7;
			bowserDefeated = settings["bosses"] && vars.watchers["peach"].Old == 0 && vars.watchers["peach"].Current == 1;
			if (goalExit == true || orbExit == true) {
				vars.stopwatch.Restart();
			}
			return goalExit || keyExit || orbExit || switchPalaceExit ||  bossExit || bowserPhase || bowserDefeated;
		break;

		case "Super Swunsh World 2":

			goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 38 && vars.watchers["orb"].Current == 3) || (vars.watchers["orb"].Old == 45 && vars.watchers["orb"].Current == 4) || (vars.watchers["orb"].Old == 32 && vars.watchers["orb"].Current == 3));
			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 255 && vars.stopwatch.ElapsedMilliseconds > 20000;
			var credits = settings["levels"] && vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 56;
			if (goalExit == true || bossExit == true || keyExit==true || switchPalaceExit==true) {
			vars.stopwatch.Restart();
			}
		return goalExit || keyExit || orbExit || switchPalaceExit || bossExit || credits;
		break;

		case "Shell's Retriever":

			goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Current == 1 && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || bossExit == true) {
			vars.stopwatch.Restart();
			}

		return goalExit || bossExit;
		break;

		case "Invictus":
			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (greenPalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;
			credits = settings["levels"] && vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 107;
			if (goalExit == true || bossExit == true || keyExit==true || switchPalaceExit==true) {
			vars.stopwatch.Restart();
			}
		return goalExit || keyExit || switchPalaceExit ||  bossExit || credits;
		break;

		case "El Dorado":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 56 && vars.watchers["orb"].Current == 64) || (vars.watchers["orb"].Old == 51 && vars.watchers["orb"].Current == 0)) && vars.watchers["bossDefeat"].Current == 0;

			if (goalExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit;
		break;

		case "Quickie World":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 6 || vars.watchers["orb"].Old == 10) && vars.watchers["orb"].Current == 3) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || bossExit == true || orbExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit || bossExit;
		break;

		case "Quickie World 2":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 68 || vars.watchers["orb"].Old == 67 || vars.watchers["orb"].Old == 61) && vars.watchers["orb"].Current == 3) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || bluePalace) && vars.stopwatch.ElapsedMilliseconds > 20000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || bossExit == true || orbExit==true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit ||  bossExit;
		break;

		case "Grand Poo World 2":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && (((vars.watchers["orb"].Old == 44 || vars.watchers["orb"].Old == 83 || vars.watchers["orb"].Old == 84 || vars.watchers["orb"].Old == 90) && vars.watchers["orb"].Current == 3) || (vars.watchers["orb"].Old == 86 && vars.watchers["orb"].Current == 92) || (vars.watchers["orb"].Old == 88 && vars.watchers["orb"].Current == 91)) && vars.stopwatch.ElapsedMilliseconds > 20000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;
			if (goalExit == true || bossExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || switchPalaceExit ||  bossExit || orbExit;
		break;

		case "Mahogen":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 0 || vars.watchers["orb"].Old == 71) && vars.watchers["orb"].Current == 3 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || switchPalaceExit==true || orbExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit || switchPalaceExit;
		break;

		case "Shellax":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 53 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = redPalace && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || orbExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit;
		break;

		case "Akogare 2":

			goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;
			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 152 && vars.watchers["orb"].Current == 3)||(vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 56)) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || orbExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit;
		break;

		case "Casio Mario World":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 128 && vars.watchers["orb"].Current == 26) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || switchPalaceExit==true || orbExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit || switchPalaceExit;
		break;

		case "Orcus":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 63 && vars.watchers["orb"].Current == 68) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit;
		break;

		case "Dreams":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 57 && vars.watchers["orb"].Current == 4)||(vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 54)) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			if (goalExit == true || orbExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit;
		break;

		case "Boogie Wonderland":

			goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 83 && vars.watchers["orb"].Current == 79) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Old == 0 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || switchPalaceExit==true || bossExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || orbExit || switchPalaceExit || bossExit;
		break;

		case "Silencio":

			goalExit = settings["levels"] && vars.watchers["victory"].Old == 0 && vars.watchers["victory"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && (vars.watchers["orb"].Old == 255 && vars.watchers["orb"].Current == 88) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Old == 0 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || keyExit==true || switchPalaceExit==true || bossExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit || bossExit;
		break;

		case "Polyphony":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 52 && vars.watchers["orb"].Current == 3)||(vars.watchers["orb"].Old == 87 && vars.watchers["orb"].Current == 74)) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit;
		break;

		case "Super Joe Bros. 2":

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;

			orbExit = settings["levels"] && ((vars.watchers["orb"].Old == 64 && vars.watchers["orb"].Current == 3)||(vars.watchers["orb"].Old == 19 && vars.watchers["orb"].Current == 49)) && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 25000;

			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;

			bossExit = settings["bosses"] && vars.watchers["bossDefeat"].Old == 0 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;

			if (goalExit == true || keyExit==true || switchPalaceExit==true || bossExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || orbExit || switchPalaceExit || bossExit;
		break;

		case "Of Jumps and Platforms":
			goalExit = settings["levels"] && vars.watchers["endtimer"].Old == 0 && vars.watchers["endtimer"].Current == 255 && vars.stopwatch.ElapsedMilliseconds > 20000;
			if (goalExit == true) {
				vars.stopwatch.Restart();
				}
		return goalExit;
		break;

		default:

			goalExit = settings["levels"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && vars.watchers["bossDefeat"].Current == 0 && vars.stopwatch.ElapsedMilliseconds > 20000;
			keyExit = settings["levels"] && vars.watchers["keyholeTimer"].Old == 0 && vars.watchers["keyholeTimer"].Current == 0x0030 && vars.stopwatch.ElapsedMilliseconds > 20000;


			yellowPalace = settings["switchPalaces"] && vars.watchers["yellowSwitch"].Old == 0 && vars.watchers["yellowSwitch"].Current == 1;
			greenPalace = settings["switchPalaces"] && vars.watchers["greenSwitch"].Old == 0 && vars.watchers["greenSwitch"].Current == 1;
			bluePalace = settings["switchPalaces"] && vars.watchers["blueSwitch"].Old == 0 && vars.watchers["blueSwitch"].Current == 1;
			redPalace = settings["switchPalaces"] && vars.watchers["redSwitch"].Old == 0 && vars.watchers["redSwitch"].Current == 1;
			switchPalaceExit = (yellowPalace || greenPalace || bluePalace || redPalace) && vars.stopwatch.ElapsedMilliseconds > 20000;


			bossExit = settings["bosses"] && vars.watchers["fanfare"].Old == 0 && vars.watchers["fanfare"].Current == 1 && (vars.watchers["bossDefeat"].Current == 1 || vars.watchers["bossDefeat"].Current == 255) && vars.stopwatch.ElapsedMilliseconds > 20000;
			bowserPhase = settings["bowserPhase"] && vars.watchers["bowserPalette"].Old == 4 && vars.watchers["bowserPalette"].Current == 7;
			bowserDefeated = settings["bosses"] && vars.watchers["peach"].Old == 0 && vars.watchers["peach"].Current == 1;
			if (goalExit == true || bossExit == true || keyExit==true || switchPalaceExit==true) {
				vars.stopwatch.Restart();
				}
		return goalExit || keyExit || switchPalaceExit ||  bossExit || bowserPhase || bowserDefeated;
		break;
		};
}
