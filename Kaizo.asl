state("snes9x"){}
state("snes9x-x64"){}
state("bsnes"){}
state("retroarch"){}
state("higan"){}
state("snes9x-rr"){}
state("emuhawk"){}

startup {
    vars.ready = false;
    vars.running = false;
    vars.startMs = vars.endMs = -1; // junk value

    byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
    Assembly snesAsm = Assembly.Load(snesBytes);
    vars.e = Activator.CreateInstance(snesAsm.GetType("SNES.Emu"));

    byte[] smwBytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly smwAsm = Assembly.Load(smwBytes);
    vars.t =  Activator.CreateInstance(smwAsm.GetType("SMW.Tracker"));
    vars.ws = Activator.CreateInstance(smwAsm.GetType("SMW.Watchers"));
    vars.ss = Activator.CreateInstance(smwAsm.GetType("SMW.Settings"));
    vars.ss.Init(100L, 1000L); // Max Lag, Min start duration
    
    foreach (var entry in vars.ss.entries) {
        var k = entry.Key;
        var v = entry.Value;
        var on =      v.Item1;
        var name =    v.Item2;
        var tooltip = v.Item3;
        var parent =  v.Item4;
        settings.Add(k, on, name, parent);
        settings.SetToolTip(k, tooltip);
    }
}
shutdown {}

init {
    vars.e.Init(game);
}
exit {}

update {
    var t = vars.t; var e = vars.e; var w = vars.ws; var s = vars.ss;
    
    if (t.HasLines()) print(t.ClearLines());

    vars.startMs = vars.endMs;

    try {
        e.Ready();
    } catch (Exception ex) {
        t.DbgOnce(ex.Message, ex.GetType());
        vars.ready = false;
        return vars.running; // Return running for opposite behaviour in Start vs Reset
    }
    
    // Does this only the update after the vars above change
    if (!vars.ready) {
        t.DbgOnce("SMC: " + e.Smc(), "info");
        var ranges = new Dictionary<int, int>() {};
        try {
            var offset = e.GetOffset();
            w.SetMemoryOffset(offset, ranges);
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            t.DbgOnce("READY", "info");
            vars.ready = true;
        } catch (Exception ex) {
            t.DbgOnce(ex.Message, ex.GetType());
            return false;
        }
    }

    if (vars.ready) {
        // The order here matters (for Spawn recording)
        w.UpdateAll(game);
        var settingsDict = new Dictionary<string, bool>();
        foreach (string k in s.keys) {
            settingsDict[k] = settings[k];
        }
        s.Update(settingsDict, w);
        t.Update(w);
        w.UpdateState();
        
        // MONITOR HERE
        //t.Monitor(w.exitMode, w);
        //t.Monitor(w.gameMode, w);
    }
}

start {
    var t = vars.t; var s = vars.ss;
    var startDuration = DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime;
    if (s.StartStatus(startDuration)) {
        t.Dbg("Start: " + s.StartReasons());
        return true;
    }
}

reset {
    var t = vars.t; var s = vars.ss; var e = vars.e;
    bool smcChanged = e.SmcChanged();
    if (s.ResetStatus(vars.ready, smcChanged)) {
        var reasons = s.ResetReasons(vars.ready, smcChanged);
        t.Dbg("Reset: " + reasons);
        return true;
    }
}

split {
    var t = vars.t; var w = vars.ws; var s = vars.ss;

    string runName = string.Join(" ", timer.Run.GameName, timer.Run.CategoryName);
    // Override Default split variables for individual runs
    switch (runName) {
        case "Bunbun World":
            s.other =
                w.RoomShiftsInLevel(80) || // Six-Screen Suites
                w.RoomShiftInLevel(45, 9, 11) || // Mt. Ninji Secret. This should split on 1-up triggering the pipe instead
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
        case "Bunbun World 2": // Retest and cancel midway on level. CoinFlag was dropped so needs fixing
            s.Midway = w.Prev(w.io) != 61 // KLDC Dolphins
                && w.prevIO != 48 // Mirror Temple
                ;
            w.Room = w.Room && w.Prev(w.io) != 65;
        break;
        case "Cute Kaizo World": // Retest. Can probably use cpEntrance out of the box but if not should cancel on level
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
                // w.RoomShiftInLevel(45, 9, 11) || // Mt. Ninji Secret. This should split on 1-up triggering the pipe instead
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
            s.block = w.CPEntrance && w.Curr(w.roomNum) == 101;
            s.credits = w.ShiftIn(w.levelNum, 94, w.io, 255, 37);
        break;
        case "Purgatory": // Retest. Should cancel based on level
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

    if (s.UndoStatus()) {
        t.Dbg("Undo: " + s.UndoReasons());
        new TimerModel { CurrentState = timer }.UndoSplit();
    }

    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    if (s.SplitStatus()) {
        t.Dbg("Split: " + s.SplitReasons());
        long lag = vars.endMs - vars.startMs;
        if (!s.SkipStatus(lag)) {
            return true;
        }
        t.Dbg("Skip: " + s.SkipReasons(lag));
        new TimerModel { CurrentState = timer }.SkipSplit();
    }
}

onStart {
    vars.running = true;
}

onReset {
    vars.running = false;
}