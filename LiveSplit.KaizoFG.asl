state("snes9x") {}
state("snes9x-x64") {}
state("bsnes") {}
state("higan") {}
state("emuhawk") {}
state("retroarch") {
    long offset : "snes9x_libretro.dll", 0x380660;  // 1.17.0 snes9x-1.62.3 (x64)
}

startup {
    print("STARTUP");
    settings.Add("recording", false, "Record Events");
    settings.SetToolTip("recording", "Record events for Split Synthesis");
    settings.Add("autoskipOnLag", false, "Autoskip laggy splits");
    settings.SetToolTip("autoskipOnLag", "Autoskip splits that might have had more than 100ms of lag");
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
    vars.settingNames = new List<string>() {"recording", "autoskipOnLag", "worlds", "levelExits", "introExits", "levelStarts", "levelFinishes", "firstTapes", "rooms"};
    vars.settingsDict = new Dictionary<string, bool>();

    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    vars.rec = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.ws = Activator.CreateInstance(asm.GetType("SMW.Watchers"));
    vars.settings = Activator.CreateInstance(asm.GetType("SMW.Settings"));

}

init {
    print("INIT");
    vars.gamename = timer.Run.GameName;
    vars.livesplitGameName = vars.gamename;
    vars.runNum = 0;
    vars.maxLag = 100L;
    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    vars.prevIn = false;
    vars.prevFinished = false;
    vars.ycs = 0;
    vars.yc1 = false;

    // Branching on module size
    var memoryOffsets = new Dictionary<int, long>
    {
        {   9646080, 0x97EE04 },      // Snes9x-rr 1.60
        {  13565952, 0x140925118 },   // Snes9x-rr 1.60 (x64)
        {   9027584, 0x94DB54 },      // Snes9x 1.60
        {  12836864, 0x1408D8BE8 },   // Snes9x 1.60 (x64)
        {  12955648, 0x59A1430 },     // Snes9x 1.61 (x64)    "snes9x-x64.exe"+0x00883158
        {  10399744, 0x987494 },      // Snes9x 1.62.3        "snes9x.exe"+0x00012698
        {  15474688, 0x140A32314 },   // Snes9x 1.62.3 (x64)  "snes9x-x64.exe"+0xA62390
        {  16019456, 0x94D144 },      // higan v106
        {  15360000, 0x8AB144 },      // higan v106.112
		{  22388736, 0xB0ECC8 },      // higan v107
		{  23142400, 0xBC7CC8 },      // higan v108
		{  23166976, 0xBCECC8 },      // higan v109
		{  23224320, 0xBDBCC8 },      // higan v110
        {  10096640, 0x72BECC },      // bsnes v107
        {  10338304, 0x762F2C },      // bsnes v107.1
        {  47230976, 0x765F2C },      // bsnes v107.2/107.3
        { 131543040, 0xA9BD5C },      // bsnes v110
        {  51924992, 0xA9DD5C },      // bsnes v111
        {  52056064, 0xAAED7C },      // bsnes v112
		{  52477952, 0xB16D7C },      // bsnes v115
        {   7061504, 0x36F11500240 }, // BizHawk 2.3
        {   7249920, 0x36F11500240 }, // BizHawk 2.3.1
        {   6938624, 0x36F11500240 }, // BizHawk 2.3.2
    };
    
    long memoryOffset = 0; 
    try {
        memoryOffset = current.offset;
    } catch(Microsoft.CSharp.RuntimeBinder.RuntimeBinderException) {
        int modSize = modules.First().ModuleMemorySize;
        memoryOffsets.TryGetValue(modSize, out memoryOffset);
    }
    
    if (memoryOffset == 0) throw new Exception("Memory not yet initialized.");
    vars.ws.SetMemoryOffset(memoryOffset, new Dictionary<int, int>() {{0x7E13CA,0x7E1B91},});
    vars.reInitialise = (Action)(() => {
        vars.gamename = timer.Run.GameName;
        vars.livesplitGameName = vars.gamename;
        print("Game:   '"+vars.gamename+"'\nSplits: '"+vars.livesplitGameName+"'");
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
    var marioLives = vars.ws["marioLives"];
    return fileSelect.Old == 0 && fileSelect.Current != 0 || marioLives.Old == 0 && marioLives.Current != 0;
}

reset {
    var fileSelect = vars.ws["fileSelect"];
    var marioLives = vars.ws["marioLives"];
    return fileSelect.Old != 0 && fileSelect.Current == 0 || marioLives.Old == 0 && marioLives.Current != 0;
}

split {
    var r = vars.rec;
    var w = vars.ws;
    var s = vars.settings;
    var startMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    // Currently can't put these into UpdateAll due to troubles importing Process from System.Diagnostics.Process
    // The order here matters for Spawn recording
    foreach (string sn in vars.settingNames) {
        vars.settingsDict[sn] = settings[sn];
    }
    s.Update(vars.settingsDict, w);
    r.Update(s.recording, w);
    w.UpdateState();

    // Override Default split variables for individual games
    switch ((string) vars.gamename) {
        case "Bunbun World":
            // TODO: Put a split on rooms function that uses levelNum and first roomNum
            s.other =
                w.RoomShiftsInLevel(80) || // Six-Screen Suites
                w.RoomShiftInLevel(45, 9, 11) || // Mt. Ninji Secret. TODO: This should split on 1-up triggering the pipe instead
                w.RoomShiftInLevel(45, 9, 10) || // Mt. Ninji Ending
                w.RoomShiftInLevel(48, 12, 254) || // Slippery Spirits to Boss
                w.RoomShiftsInLevel(37) || // Cotton Candy Castle
                w.RoomShiftInLevel(78, 42, 74) || // Dizzy Drifting Secret pipe
                w.RoomShiftInLevel(51, 15, 198) || // Dolphin Dreams
                w.RoomShiftsInLevel(68) || // Breathtaking
                w.RoomShiftsInLevel(61) || // Night Sky Scamper
                w.RoomShiftInLevel(52, 16, 225) || // Bunbun Bastion
                (w.Shift(w.io, 3, 20) && w.Curr(w.levelNum) == 52) || // Bunbun Bastion any%
                w.RoomShiftsInLevel(62) || // Culmination Castle
                w.RoomShiftInLevel(53, 17, 198) // Bowser's Tower
                ;
            s.credits = w.ShiftTo(w.io, 33) && w.Curr(w.levelNum) == 53; // Final Bowser hit (little late)
        break;
        case "Bunbun World 2": // TODO: Retest
            s.Tape = w.Prev(w.io) != 61 // KLDC Dolphins
                && w.prevIO != 48 // Mirror Temple
                ;
            w.Room = w.Room && w.Prev(w.io) != 65; // Using yoshiCoins
            w.CoinFlag = w.Stepped(w.yoshiCoin) && w.Prev(w.io) == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
        break;
        case "Cute Kaizo World": // TODO: Retest
            w.Tape = w.Tape && w.Prev(w.io) != 55;  // Using doors
            s.credits = w.ShiftTo(w.io, 21);
        break;
        case "Dancer to a Discordant System":
            s.other =
                w.RoomShiftInLevel(5, 6, 7) ||
                w.RoomShiftInLevel(51, 14, 13) ||
                w.RoomShiftInLevel(11, 10, 21) ||
                w.RoomShiftInLevel(11, 21, 22) ||
                w.RoomShiftInLevel(11, 22, 12) ||
                w.RoomShiftInLevel(11, 12, 23) ||
              false;
        break;
        case "Janked Up Mario Party":
            // s.other =
                // w.RoomShiftsInLevel(38) || // Mushroom Ledge
                // w.RoomShiftsInLevel(37) || // Bastion Blue
                // w.RoomShiftsInLevel(93) || // Tides, Ok?
                // w.RoomShiftsInLevel(84) || // Roy
                // w.RoomShiftsInLevel(19) || // Peek a Boo
                // w.RoomShiftsInLevel(31) || // Glacier Soup
                // w.RoomShiftsInLevel(62) || // Yellow
                // w.RoomShiftsInLevel(36) || // Warehouse
               // w.RoomShiftInLevel(45, 9, 11) || // Mt. Ninji Secret. TODO: This should split on 1-up triggering the pipe instead
              //  false;
            s.credits = false;
        break;
        case "Love Yourself":
            s.other =
                (w.Shift(w.roomNum, 39, 40) && w.Curr(w.levelNum) == 74) || // 3rd Castle room
                (w.Shift(w.roomNum, 40, 42) && w.Curr(w.levelNum) == 74) || // 4th castle room
                (w.Stepped(w.roomNum) && w.Curr(w.roomNum) > 50 && w.Curr(w.roomNum) < 67 && w.Curr(w.levelNum) == 85) // All room other than credits door
                ;
            s.credits = w.EnterDoor && w.Curr(w.roomNum) == 66 && w.Curr(w.levelNum) == 85;
        break;
        case "Nonsense":
            s.credits = false; // Peach release doesn't work here
        break;
        case "Purgatory": // TODO: Retest
            w.Tape = w.Tape
                && w.Prev(w.io) != 56  // Cancel for Sea Moon
                && w.Prev(w.io) != 49  // Cancel for Soft and Wet
                && w.Prev(w.io) != 63  // Cancel for Summit of Salvation
                ;
        break;
        case "Quickie World 2":
          s.other =
            w.RoomShiftInLevel(10, 10, 41) ||
            w.RoomShiftInLevel(2, 2, 48) ||
            w.RoomShiftInLevel(9, 9, 36) ||
            w.RoomShiftInLevel(17, 17, 23) || // CP shifting to Secret room
            w.RoomShiftInLevel(17, 23, 42) ||
            w.RoomShiftInLevel(4, 4, 44) ||
            w.RoomShiftInLevel(6, 6, 33) ||
            w.RoomShiftInLevel(6, 6, 207) || // CP shifting to Boss room
            w.RoomShiftInLevel(5, 5, 49) ||
            w.RoomShiftInLevel(20, 20, 34) ||
            w.RoomShiftInLevel(3, 3, 32) ||
            w.RoomShiftInLevel(14, 14, 15) || // CP Shifting to Secret room
            w.RoomShiftInLevel(14, 15, 47) ||
            w.RoomShiftInLevel(24, 24, 30) ||
            w.RoomShiftInLevel(19, 19, 28) ||
            w.RoomShiftInLevel(21, 21, 29) ||
            w.RoomShiftInLevel(12, 12, 35) ||
            w.RoomShiftInLevel(7, 7, 40) ||
            w.RoomShiftInLevel(1, 1, 43) ||
            w.RoomShiftInLevel(11, 11, 38) ||
            w.RoomShiftInLevel(18, 18, 27) ||
            w.RoomShiftInLevel(18, 18, 25) || // Castle Door instead of Tape
            w.RoomShiftInLevel(8, 8, 46) ||
            w.RoomShiftInLevel(16, 16, 26) ||
            w.RoomShiftInLevel(22, 22, 37) ||
            w.RoomShiftInLevel(13, 13, 31) ||
            w.RoomShiftInLevel(13, 13, 45) ||
            w.RoomShiftInLevel(13, 13, 235) // Yoshi pipe
            ;
        break;
        case "Truc Bidule":
        break;
    }

    List<string> reasons = new List<string>();
    if (s.SplitStatus()) {
        if (w.Palace) reasons.Add("Palace");
        if (w.Tape) reasons.Add("Tape");
        if (w.Submap) reasons.Add("Submap");
        if (w.Portal) reasons.Add("Portal");
        if (w.Boss) reasons.Add("Boss");
        if (w.Orb) reasons.Add("Orb");
        if (w.Key) reasons.Add("Key");
        if (w.Goal) reasons.Add("Goal");
        r.Dbg("Split: " + string.Join(" ", reasons));
    }

    r.Monitor(w.levelNum, w);
    r.Monitor(w.roomNum, w);
    //r.Monitor(w.Submap, w);

    var newEndMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();
    var lag = newEndMs - vars.endMs;
    if (r.debugInfo.Count > 0) print(string.Join("\n", r.debugInfo));
    vars.endMs = newEndMs;

    if (s.UndoStatus()) new TimerModel { CurrentState = timer }.UndoSplit();

    if (s.credits) return true;

    if (s.SplitStatus() && s.autoskipOnLag && lag > vars.maxLag) {
        new TimerModel { CurrentState = timer }.SkipSplit();
        print("LAG: "+lag);
        return false;
    } else {
        return s.SplitStatus();
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
