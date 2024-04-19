state("snes9x", "1.62.3") {
    int smc_path_offset : "snes9x.exe", 0x5C14D4;
    int offset :          "snes9x.exe", 0x12698;
}
state("snes9x-x64", "1.60") {
    string512 smc_path : "snes9x-x64.exe", 0x8EAC39;
    long offset :        "snes9x-x64.exe", 0x8D8BE8;
}
state("snes9x-x64", "1.61") {
    string512 smc_path : "snes9x-x64.exe", 0x8951CF;
    long offset :        "snes9x-x64.exe", 0x883158;
}
state("snes9x-x64", "1.62.3") {
    int smc_path_offset : "snes9x-x64.exe", 0xA74398;
    long offset :         "snes9x-x64.exe", 0xA62390;
}
state("retroarch", "1.17.0") {
    string512 core_path :   0xEEB59A;
    string32 core_version : 0xEFD5A9;
    string512 smc_path :    0xEFF8A9;
}
state("retroarch", "1.9.4") {
    string512 core_path :   0xD6A900;
    string32 core_version : 0xD67600;
    string512 smc_path :    0xD69926;
}
state("bsnes"){} 
state("higan"){} 
state("snes9x-rr"){} 
state("emuhawk"){} 

startup {
    print("STARTUP");
    settings.Add("start", true, "Start when");
        settings.Add("playersSelect", true, "# Players Selected", "start");
        settings.SetToolTip("playersSelect", "Start when the number of players is selected");
        settings.Add("livesSet", true, "Luigi >1 Life", "start");
        settings.SetToolTip("livesSet", "Start when Luigi's lives is set to more than 1. Good for one player speedruns when Players Selected is broken");
    settings.Add("reset", true, "Reset when");
        settings.Add("playersUnselect", true, "# Players not Selected", "reset");
        settings.SetToolTip("playersUnselect", "Reset when the number of players is not selected and so probably back in the menu");
        settings.Add("livesUnset", true, "Luigi 1 Life", "reset");
        settings.SetToolTip("livesUnset", "Reset when Luigi has one life. Good for one player speedruns when Players not Selected is broken");
    settings.Add("split", true, "Split when");
        settings.Add("exits", true, "Level Exit", "split");
        settings.SetToolTip("exits", "Split when leaving a level by beating");
        settings.Add("introExit", true, "Intro Exit", "split");
        settings.SetToolTip("introExit", "Split at the end of the intro level");
        settings.Add("worlds", true, "Overworlds", "split");
        settings.SetToolTip("worlds", "Split when switching overworlds. Good to use with subsplits");
        settings.Add("level", true, "Level Events", "split");
            settings.Add("checkpoints", true, "Checkpoints", "level");
                settings.Add("midways", true, "First midway tape", "checkpoints");
                settings.SetToolTip("midways", "Split when getting the first checkpoint tape in the level");
                settings.Add("cpEntrances", true, "Checkpoint Entrance Changes", "checkpoints");
                settings.SetToolTip("cpEntrances", "Split when entrance to appear at on death changes, excluding when entering a level");
            settings.Add("starts", false, "Starts", "level");
            settings.SetToolTip("starts", "Split at the start of each level");
            settings.Add("finishes", false, "Goals, Orbs, Keys, and Bosses", "level");
            settings.SetToolTip("finishes", "Split on crossing goal tapes, getting orbs, and activating keyholes");
                settings.Add("goals", true, "Goal Tape", "finishes");
                settings.SetToolTip("goals", "Split on crossing goal tapes");
                settings.Add("orbs", true, "Orbs", "finishes");
                settings.SetToolTip("orbs", "Split when getting an orb");
                settings.Add("keys", true, "Keys", "finishes");
                settings.SetToolTip("keys", "Split when activating a keyhole");
                settings.Add("bosses", true, "Bosses", "finishes");
                settings.SetToolTip("bosses", "Split when defeating a boss");
                settings.Add("palaces", true, "Palaces", "finishes");
                settings.SetToolTip("palaces", "Split when hitting a switch palace");
            settings.Add("rooms", false, "Room Changes", "level");
            settings.SetToolTip("rooms", "Split whenever your room transitions");
    settings.Add("recording", false, "Record Events");
    settings.SetToolTip("recording", "Record events for Split Synthesis");
    settings.Add("autoskipOnLag", false, "Autoskip laggy splits");
    settings.SetToolTip("autoskipOnLag", "Autoskip splits that might have had more than 100ms of lag");

    vars.settingNames = new List<string>() {
        "playersSelect", "livesSet",
        "playersUnselect", "livesUnset",
        "exits", "introExit", "worlds", "midways", "cpEntrances", "starts", "goals", "orbs", "keys", "bosses", "palaces", "rooms",
        "recording", "autoskipOnLag"
    };
    vars.settingsDict = new Dictionary<string, bool>();

    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    vars.rec = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.ws =  Activator.CreateInstance(asm.GetType("SMW.Watchers"));
    vars.ss =  Activator.CreateInstance(asm.GetType("SMW.Settings"));

    vars.runNum = 0;
    vars.maxLag = 100L;
    vars.ready = false;
}

shutdown {
    print("SHUTDOWN");
}

init {
    print("INIT");

    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds(); // TODO: WHy this here?

    var versions = new Dictionary<int, string> {
        { 17264640, "1.17.0" }, // Retroarch
        { 15675392, "1.9.4"  }, // Retroarch
        {  9646080, "1.60"   }, // Snes9x-rr
        { 13565952, "1.60"   }, // Snes9x-rr x64
        {  9027584, "1.60"   }, // Snes9x
        { 12836864, "1.60"   }, // Snes9x x64
        { 12955648, "1.61"   }, // Snes9x x64
        { 10399744, "1.62.3" }, // Snes9x
        { 15474688, "1.62.3" }, // Snes9x x64
        { 16019456, "106"    }, // higan
        { 15360000, "106.112"}, // higan
		{ 22388736, "107"    }, // higan
		{ 23142400, "108"    }, // higan
		{ 23166976, "109"    }, // higan
		{ 23224320, "110"    }, // higan
        { 10096640, "107"    }, // bsnes
        { 10338304, "107.1"  }, // bsnes
        { 47230976, "107.2"  }, // bsnes (also 107.3) // Use game hash to prevent collisions like this
        {131543040, "110"    }, // bsnes
        { 51924992, "111"    }, // bsnes 
        { 52056064, "112"    }, // bsnes 
		{ 52477952, "115"    }, // bsnes 
        {  7061504, "2.3"    }, // BizHawk 
        {  7249920, "2.3.1"  }, // BizHawk 
        {  6938624, "2.3.2"  }, // BizHawk 
    };
    
    string emuName = game.ProcessName.ToLower();
    int modSize = modules.First().ModuleMemorySize;

    string v = "";
    versions.TryGetValue(modSize, out v);
    if (!string.IsNullOrWhiteSpace(v)) {
        print("EMU: "+emuName);
        version = v;
    } else {
        throw new Exception("UNKNOWN "+emuName+" MODSIZE '"+modSize+"'");
    }
}

exit {
    print("EXIT");
}

update {
    if (string.IsNullOrWhiteSpace(version)) return false; // Don't start until version
    if (vars.ready) {
        var r = vars.rec; var w = vars.ws; var s = vars.ss;
        w.UpdateAll(game);

        // Currently can't put these into UpdateAll due to troubles importing Process from System.Diagnostics.Process
        // The order here matters for Spawn recording
        foreach (string sn in vars.settingNames) {
            vars.settingsDict[sn] = settings[sn];
        }
        s.Update(vars.settingsDict, w);
        r.Update(s.recording, w);
        w.UpdateState();

        // Hacky attempt to prevent early start from being true right when game starts up
        return DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime > 1000L;
    }
}

start {
    string emuName = game.ProcessName.ToLower();
    if (emuName == "retroarch") {

        string core = Path.GetFileName(current.core_path);
        string coreVersion = current.core_version;
        string smc = Path.GetFileName(current.smc_path);

        if (string.IsNullOrWhiteSpace(core)) {
            print("NO START: No Retroarch Core");
            vars.ready = false;
            return false;
        }
        if (string.IsNullOrWhiteSpace(coreVersion)) {
           print("NO START: No Retroarch Core Version");
           vars.ready = false;
           return false;
        }
        if (string.IsNullOrWhiteSpace(smc)) {
            print("NO START: No Retroarch Game");
            vars.ready = false;
            return false;
        }

        if (!vars.ready) {
            var coreOffsets = new Dictionary<string, int> {
                { "snes9x_libretro.dll 1.62.3 ec4ebfc", 0x3BA164 },
                { "bsnes_libretro.dll 115",             0x7D39DC },
            };

            string coreKey = string.Join(" ", core, coreVersion);
            int coreOffset = 0;
            coreOffsets.TryGetValue(coreKey, out coreOffset);
            if (coreOffset == 0) {
                print("NOT START: No core offset found for '"+coreKey+"'");
                return false;
            }

            IntPtr offset;
            new DeepPointer(core, coreOffset).DerefOffsets(game, out offset);
            long memOffset = (long) offset;

            if (memOffset == 0) throw new Exception("NOT START: No memory offset found for '"+coreKey+"' at '"+coreOffset+"'");
            vars.ws.SetMemoryOffset(memOffset, new Dictionary<int, int>() {{0x7E13CA,0x7E1B91},}); // TODO: What are these nums?
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            vars.ready = true;
        }
    } else {
        string smcPath;
        try {
            smcPath = current.smc_path;
        } catch (Microsoft.CSharp.RuntimeBinder.RuntimeBinderException ex) {
            int smcOffset = current.smc_path_offset;
            ExtensionMethods.ReadString(game, (IntPtr)smcOffset, 512, out smcPath);
        }
        string smc = Path.GetFileName(smcPath);

        if (string.IsNullOrWhiteSpace(smc)) {
            print("NO START: No Game");
            vars.ready = false;
            return false;
        }

        if (!vars.ready) {
            print("SMC: "+smc);
            long memOffset = current.offset;
            print("MEM: "+memOffset.ToString("X8"));

            vars.ws.SetMemoryOffset(memOffset, new Dictionary<int, int>() {{0x7E13CA,0x7E1B91},}); // TODO: What are these nums?
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            vars.ready = true;
        }
    }

    var r = vars.rec; var w = vars.ws; var s = vars.ss;
    if (s.StartStatus()) {
        print("SINCE INIT: "+(DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime));
        r.Dbg("Start: " + s.StartReasons());
        if (r.debugInfo.Count > 0) print(string.Join("\n", r.debugInfo));
        return true;
    }
}

reset {
    var r = vars.rec; var w = vars.ws; var s = vars.ss;
    if (s.ResetStatus()) {
        r.Dbg("Reset: " + s.ResetReasons());
        if (r.debugInfo.Count > 0) print(string.Join("\n", r.debugInfo));
        return true;
    }
}

split {
    var r = vars.rec; var w = vars.ws; var s = vars.ss;
    var startMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    string runName = string.Join(" ", timer.Run.GameName, timer.Run.CategoryName);
    // Override Default split variables for individual games
    switch (runName) {
        case "Bunbun World":
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
                w.ShiftIn(w.levelNum, 52, w.io, 3, 20) || // Bunbun Bastion any%
                w.RoomShiftsInLevel(62) || // Culmination Castle
                w.RoomShiftInLevel(53, 17, 198) // Bowser's Tower
                ;
            s.credits = w.ShiftTo(w.io, 33) && w.Curr(w.levelNum) == 53; // Final Bowser hit (little late) (create a ShiftsToIn?)
        break;
        case "Bunbun World 2": // TODO: Retest. TODO cancel midway on level. Also maybe use rooms instead of coins or just drop this.
            s.Midway = w.Prev(w.io) != 61 // KLDC Dolphins
                && w.prevIO != 48 // Mirror Temple
                ;
            w.Room = w.Room && w.Prev(w.io) != 65; // Using yoshiCoins
            w.CoinFlag = w.Stepped(w.yoshiCoin) && w.Prev(w.io) == 65; // TODO: Splits on YoshiCoins steps rather than #s 1 thru 4. Not idempotent.
        break;
        case "Cute Kaizo World": // TODO: Retest. Can probably use cpEntrance out of the box but if not should cancel on level
            w.Midway = w.Midway && w.Prev(w.io) != 55;  // Using doors
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
                // false;
            s.credits = false;
        break;
        case "Love Yourself":
            s.other =
                w.RoomShiftInLevel(74, 39, 40) || // 3rd Castle room
                w.RoomShiftInLevel(74, 40, 42) || // 4th castle room
                (w.Stepped(w.roomNum) && w.Curr(w.roomNum) > 50 && w.Curr(w.roomNum) < 67 && w.Curr(w.levelNum) == 85) // All room other than credits door
                ;
            s.credits = w.EnterDoor && w.Curr(w.roomNum) == 66 && w.Curr(w.levelNum) == 85;
        break;
        case "Nonsense 24 Exit":
            s.credits = w.ShiftIn(w.levelNum, 94, w.io, 255, 37);
        break;
        case "Purgatory": // TODO: Retest. Should cancel based on level
            w.Midway = w.Midway
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
            w.RoomShiftInLevel(18, 18, 25) || // Castle Door instead of Midway
            w.RoomShiftInLevel(8, 8, 46) ||
            w.RoomShiftInLevel(16, 16, 26) ||
            w.RoomShiftInLevel(22, 22, 37) ||
            w.RoomShiftInLevel(13, 13, 31) ||
            w.RoomShiftInLevel(13, 13, 45) ||
            w.RoomShiftInLevel(13, 13, 235) // Yoshi pipe
            ;
        break;
    }

    if (s.SplitStatus()) r.Dbg("Split: " + s.SplitReasons());

    r.Monitor(w.levelNum, w);
    r.Monitor(w.roomNum, w);
    r.Monitor(w.fileSelect, w);
    r.Monitor(w.marioLives, w);
    r.Monitor(w.luigiLives, w);

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