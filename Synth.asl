state("snes9x"){}
state("snes9x-x64"){}
state("bsnes"){}
state("retroarch"){}
state("higan"){} 
state("snes9x-rr"){}
state("emuhawk"){} 

startup {
    print("STARTUP");

    byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
    Assembly snesAsm = Assembly.Load(snesBytes);
    vars.e = Activator.CreateInstance(snesAsm.GetType("SNES.Emu"));

    byte[] smwBytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly smwAsm = Assembly.Load(smwBytes);
    vars.t =  Activator.CreateInstance(smwAsm.GetType("SMW.Tracker"));
    vars.ws = Activator.CreateInstance(smwAsm.GetType("SMW.Watchers"));
    vars.ss = Activator.CreateInstance(smwAsm.GetType("SMW.Settings"));
    vars.ss.Init(100L, 1000L); // Max Lag, Min start duration, TODO: shouldn't need these for Synth
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
    vars.ready = false;
    vars.running = false;
}

shutdown {
    print("SHUTDOWN");
}

init {
    print("INIT");
    // TODO: Can get size from game?
    int modSize = modules.First().ModuleMemorySize;
    vars.e.Init(modSize, game)
}

exit {
    print("EXIT");
}

update {
    // TODO: Move as much of this as possible that never changes into init
    var t = vars.t; var e = vars.e;
    
    if (t.HasLines()) print(t.ClearLines());

    //if (string.IsNullOrWhiteSpace(version)) return false;
    
    try {
        e.Ready();
        t.DbgOnce("SMC: " + e.Smc());
    } catch (Exception ex) { // CoreException
        t.DbgOnce(ex.Message);
        vars.ready = false;
        return vars.running;
    }
    
    // TODO: Could be done prior to loading SMC?
    // Do this only the update after the vars above change
    if (!vars.ready) {
        var w = vars.ws;
        var ranges = new Dictionary<int, int>() {};
        try {
            var offset = e.GetOffset();
            w.SetMemoryOffset(offset, ranges);
            vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            vars.ready = true;
        } catch (Exception ex) {
            t.DbgOnce(ex);
            return false;
        }
    }

    if (vars.ready) {
        //t.DbgOnce("READY");
        var w = vars.ws; var s = vars.ss;
        var r = vars.rec;
        w.UpdateAll(game);

        // TODO: Currently can't put these into UpdateAll due to troubles importing Process from System.Diagnostics.Process
        // The order here matters (for Spawn recording)
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
        t.Dbg("Reset: " + reasons);
        r.ResetReasons(reasons);
        return true;
    }
}

split {

}

onStart {
    print("STARTING");
    vars.running = true;
}

onReset {
    print("RESETING");
    var r = vars.rec;
    r.WriteRun();
    vars.running = false;
}