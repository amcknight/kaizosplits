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
    vars.ticksUntilShowHist = 500;
    vars.ticksUntilRecheckGame = 20;
    vars.tick = 0;
    int maxLagMs = 100;
    int minStartDurationMs = 1000;

    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    vars.e =  Activator.CreateInstance(asm.GetType("SNES.Emu"));
    vars.t =  Activator.CreateInstance(asm.GetType("SMW.Timer"));
    vars.d =  Activator.CreateInstance(asm.GetType("SMW.Debugger"));
    vars.ss = Activator.CreateInstance(asm.GetType("SMW.Settings"));
    vars.ws = Activator.CreateInstance(asm.GetType("SMW.Watchers"));

    vars.ss.Init(maxLagMs, minStartDurationMs);
    vars.ws.Init(vars.ss.UsedMemory());

    vars.ranges = new Dictionary<int, int>() {};
    vars.settingsDict = new Dictionary<string, bool>();
    
    foreach (var entry in vars.ss.entries) {
        string k = entry.Key;
        var v = entry.Value;
        bool on =        v.Item1;
        string name =    v.Item2;
        string tooltip = v.Item3;
        string parent =  v.Item4;
        settings.Add(k, on, name, parent);
        settings.SetToolTip(k, tooltip);
    }
}

init {
    vars.e.Init(game);
}

update {
    var t = vars.t; var d = vars.d; var e = vars.e; var w = vars.ws; var s = vars.ss;

    // Stuff that should happen after split or start or reset but before real update
    t.HistEnd();
    // if (vars.tick % vars.ticksUntilShowHist == 0) print(t.ToString());
    if (d.HasLines()) print(d.ClearLines());
    vars.startMs = vars.endMs;
    vars.tick++;

    bool recheck = vars.tick % vars.ticksUntilRecheckGame == 0;
    if (!vars.ready || recheck) {
        try {
            e.Ready();
        } catch (Exception ex) {
            d.DbgOnce(ex);
            vars.ready = false;
            return vars.running; // Return vars.running for opposite behaviour in Start vs Reset
        }
    }
    
    d.DbgOnce("SMC: " + e.Smc(), "smc");
    if (vars.ready) {
        // The order here matters (for Spawn recording)
        w.UpdateAll(game);
        var sd = vars.settingsDict;
        sd.Clear();
        foreach (string k in s.keys) {
            sd[k] = settings[k];
        }
        s.Update(sd, w);
        d.Update(w);
        w.UpdateState();
        
        // MONITOR HERE for monitoring even while not in a run
        
        //d.Monitor(w.roomNum, w);
        //d.Monitor(w.levelNum, w);
        //d.Monitor(w.io, w);
        //d.Monitor(w.overworldTile, w);
    } else {
        try {
            var offset = e.GetOffset();
            w.SetMemoryOffset(offset, vars.ranges);
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            vars.ready = true;
        } catch (Exception ex) {
            d.DbgOnce(ex);
            return false;
        }
    }
    t.HistMid();
}

start {
    var d = vars.d; var s = vars.ss;
    var startDuration = DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime;
    if (s.StartStatus(startDuration)) {
        d.Dbg("Start: " + s.StartReasons());
        return true;
    }
}

reset {
    var d = vars.d; var s = vars.ss; var e = vars.e;
    bool smcChanged = e.SmcChanged();
    if (s.ResetStatus(vars.ready, smcChanged)) {
        var reasons = s.ResetReasons(vars.ready, smcChanged);
        d.Dbg("Reset: " + reasons);
        vars.ready = false;
        return true;
    }
}

split {
    var d = vars.d; var w = vars.ws; var s = vars.ss;

    string runName = string.Join(" - ", timer.Run.GameName, timer.Run.CategoryName);
    d.DbgOnce("Run: '"+runName+"'", "run");

    // Override Default split variables for individual runs. Customize Splits Tutorial: https://github.com/amcknight/kaizosplits?tab=readme-ov-file#custom-splits
    switch (runName) {
        case "Bunbun World - 100%":
            s.other = w.ShiftIn(w.levelNum, 52, w.io, 3, 20); // any% ending
            s.credits = w.ShiftToIn(w.levelNum, 53, w.io, 33) && w.Curr(w.levelNum) == 53;
        break;
        case "Cute Kaizo World - 100%":
            s.credits = w.ShiftTo(w.io, 21);
        break;
        case "Easyland - Beat the Game":
            s.credits = w.Curr(w.submap) == 6 && w.Curr(w.overworldTile) == 97 && w.GmFadeToLevel;
        break;
        case "Love Yourself - Welcome Home%":
            s.credits = w.Curr(w.levelNum) == 85 && w.Curr(w.roomNum) == 66 && w.EnterDoor;
        break;
        case "Nonsense - 16 Exit":
        case "Nonsense - 24 Exit":
            s.block = w.CPEntrance && w.Curr(w.roomNum) == 101; // Extra CP at beginning of Angry Parachutes when icy
            s.credits = w.ShiftIn(w.levelNum, 94, w.io, 255, 37); // Peach drop
        break;
    }

    if (s.UndoStatus()) {
        d.Dbg("Undo: " + s.UndoReasons());
        new TimerModel { CurrentState = timer }.UndoSplit();
    }

    vars.endMs = DateTimeOffset.Now.ToUnixTimeMilliseconds();

    if (s.SplitStatus()) {
        d.Dbg("Split: " + s.SplitReasons());
        long lag = vars.endMs - vars.startMs;
        if (!s.SkipStatus(lag)) {
            return true;
        }
        d.Dbg("Skip: " + s.SkipReasons(lag));
        new TimerModel { CurrentState = timer }.SkipSplit();
    }
}

onStart {
    vars.running = true;
}

onReset {
    vars.running = false;
}