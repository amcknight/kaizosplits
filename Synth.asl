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
    vars.ticksUntilShowHist = 500;
    vars.ticksUntilRecheckGame = 20;
    vars.tick = 0;
    int maxLagMs = 100;
    int minStartDurationMs = 1000;

    byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
    Assembly snesAsm = Assembly.Load(snesBytes);
    vars.e = Activator.CreateInstance(snesAsm.GetType("SNES.Emu"));

    byte[] smwBytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly smwAsm = Assembly.Load(smwBytes);
    vars.t =  Activator.CreateInstance(smwAsm.GetType("SMW.Timer"));
    vars.d =  Activator.CreateInstance(smwAsm.GetType("SMW.Debugger"));
    vars.ws = Activator.CreateInstance(smwAsm.GetType("SMW.Watchers"));
    vars.ss = Activator.CreateInstance(smwAsm.GetType("SMW.Settings"));
    vars.ss.Init(maxLagMs, minStartDurationMs);
    vars.r = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.r.Init("C:/Users/thedo/Git/kaizosplits/runs");  // Folder to write recorded runs to

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
    var t = vars.t; var d = vars.d; var e = vars.e; var w = vars.ws; var s = vars.ss; var r = vars.r;
    
    // Stuff that should happen after split or start or reset but before real update
    t.HistEnd();
    if (vars.tick % vars.ticksUntilShowHist == 0) print(t.ToString());
    if (d.HasLines()) print(d.ClearLines());
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
    var d = vars.d; var s = vars.ss; var r = vars.r;
    var startDuration = DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime;
    if (s.StartStatus(startDuration)) {
        d.Dbg("Start: " + s.StartReasons());
        r.StartReasons(s.StartReasons());
        return true;
    }
}

reset {
    var d = vars.d; var s = vars.ss; var e = vars.e; var r = vars.r;
    bool smcChanged = e.SmcChanged();
    if (s.ResetStatus(vars.ready, smcChanged)) {
        var reasons = s.ResetReasons(vars.ready, smcChanged);
        r.ResetReasons(reasons);
        d.Dbg("Reset: " + reasons);
        vars.ready = false;
        return true;
    }
}

split {

}

onStart {
    vars.running = true;
}

onReset {
    var r = vars.rec;
    r.WriteRun();
    vars.running = false;
}