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

    byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
    Assembly snesAsm = Assembly.Load(snesBytes);
    vars.e = Activator.CreateInstance(snesAsm.GetType("SNES.Emu"));

    byte[] smwBytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly smwAsm = Assembly.Load(smwBytes);
    vars.t =  Activator.CreateInstance(smwAsm.GetType("SMW.Tracker"));
    vars.ws = Activator.CreateInstance(smwAsm.GetType("SMW.Watchers"));
    vars.ss = Activator.CreateInstance(smwAsm.GetType("SMW.Settings"));
    vars.ss.Init(100L, 1000L); // Max Lag, Min start duration, (don't need these for Synth)
    vars.rec = Activator.CreateInstance(asm.GetType("SMW.Recorder"));
    vars.rec.Init("C:/Users/thedo/Git/kaizosplits/runs");  // Folder to write recorded runs to
    
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
    var r = vars.rec;
    
    if (t.HasLines()) print(t.ClearLines());
    
    try {
        e.Ready();
    } catch (Exception ex) {
        t.DbgOnce(ex.Message, ex.GetType());
        vars.ready = false;
        return vars.running; // Return running for opposite behaviour in Start vs Reset
    }

    t.DbgOnce("SMC: " + e.Smc(), "smc");
    
    // Does this only the update after the vars above change
    if (!vars.ready) {
        var ranges = new Dictionary<int, int>() {};
        try {
            var offset = e.GetOffset();
            w.SetMemoryOffset(offset, ranges);
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
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
        r.Update(w);
        w.UpdateState();
                
        // MONITOR HERE
        //t.Monitor(w.exitMode, w);
        //t.Monitor(w.gameMode, w);
    }
}

start {
    var t = vars.t; var s = vars.ss;
    var r = vars.rec;
    var startDuration = DateTimeOffset.Now.ToUnixTimeMilliseconds() - vars.memFoundTime;
    if (s.StartStatus(startDuration)) {
        t.Dbg("Start: " + s.StartReasons());
        r.StartReasons(s.StartReasons());
        return true;
    }
}

reset {
    var t = vars.t; var s = vars.ss; var e = vars.e;
    var r = vars.rec;
    bool smcChanged = e.SmcChanged();
    if (s.ResetStatus(vars.ready, smcChanged)) {
        var reasons = s.ResetReasons(vars.ready, smcChanged);
        r.ResetReasons(reasons);
        t.Dbg("Reset: " + reasons);
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