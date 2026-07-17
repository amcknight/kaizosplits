state("snes9x"){}
state("snes9x-x64"){}
state("bsnes"){}
state("retroarch"){}
state("higan"){}
state("snes9x-rr"){}
state("mesen"){}
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
    int minSplitCooldownMs = 500;

    // Two-assembly load: SNES.dll (shared WRAM resolver, source of truth in
    // snes_offsets) first, then SMW.dll which references it. Byte-loaded
    // assemblies resolve references through normal probing, which cannot see
    // other byte-loaded assemblies — the AssemblyResolve hook hands SMW.dll's
    // SNES reference the already-loaded assembly. Byte-loaded assemblies stack
    // a handler per script reload; each script reload stacks another handler;
    // all of them read the shared AppDomain slot, which each startup overwrites,
    // so the newest SNES.dll always wins.
    byte[] snesBytes = File.ReadAllBytes("Components/SNES.dll");
    Assembly snesAsm = Assembly.Load(snesBytes);
    // Shared process-wide slot: if two scripts (Kaizo + Synth) are live, last startup wins for both
    // — fine while they byte-load the same Components/SNES.dll; don't diverge the deployed file.
    AppDomain.CurrentDomain.SetData("SNES.LatestAssembly", snesAsm);
    AppDomain.CurrentDomain.AssemblyResolve += (rSender, rArgs) => {
        if (new AssemblyName(rArgs.Name).Name != "SNES") return null;
        return (Assembly)AppDomain.CurrentDomain.GetData("SNES.LatestAssembly");
    };
    byte[] bytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly asm = Assembly.Load(bytes);
    // Staleness check: byte-loads refresh only on script reload — restart
    // LiveSplit after a rebuild, then confirm these timestamps moved.
    print("Kaizo.asl: loaded SNES.dll v" + snesAsm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SNES.dll"));
    print("Kaizo.asl: loaded SMW.dll v" + asm.GetName().Version + ", modified " + File.GetLastWriteTime("Components/SMW.dll"));
    vars.e =  Activator.CreateInstance(snesAsm.GetType("SNES.Emu"));
    vars.t =  Activator.CreateInstance(asm.GetType("SMW.Timer"));
    vars.d =  Activator.CreateInstance(asm.GetType("SMW.Debugger"));
    vars.ss = Activator.CreateInstance(asm.GetType("SMW.Settings"));
    vars.ws = Activator.CreateInstance(asm.GetType("SMW.Watchers"));

    vars.ss.Init(maxLagMs, minStartDurationMs, minSplitCooldownMs);
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
    
    try {
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

            // d.Monitor(w.roomNum, w);
            d.Monitor(w.levelNum, w);
            d.Monitor(w.exitMode, w);
            d.Monitor(w.cpEntrance, w);
            d.Monitor(w.midway, w);
            //d.Monitor(w.moonCounter, w);
            //d.Monitor(w.gameMode, w);
            //d.Monitor(w.io, w);
            //d.Monitor(w.overworldTile, w);
        } else {
            try {
                var offset = e.GetOffset();
                w.SetMemoryOffset(offset, vars.ranges);
                vars.memFoundTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                vars.ready = true;
                d.DbgOnce("WRAM found at 0x" + offset.ToString("X"), "wram");
            } catch (Exception ex) {
                d.DbgOnce(ex);
                return false;
            }
        }
    } catch (Exception ex) {
        // The game can die between ticks before Ready() notices (content
        // closed, emulator quit); same handling as the Ready() catch above,
        // instead of letting a raw Win32Exception escape update.
        d.DbgOnce(ex);
        vars.ready = false;
        return vars.running;
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
        if (!vars.running) {
            vars.ready = false;
        }

        return true;
    }
}

split {
    var d = vars.d; var w = vars.ws; var s = vars.ss;

    string runName = string.Join(" - ", timer.Run.GameName, timer.Run.CategoryName);
    d.DbgOnce("Run: '"+runName+"'", "run");

    // Override Default split variables for individual runs. Customize Splits Tutorial: https://github.com/amcknight/kaizosplits?tab=readme-ov-file#custom-splits
    switch (runName) {
        case "Babby Builds Wevels - 100%":
        case "Babby Builds Wevels - SwagMoon%":
            s.credits = w.ShiftTo(w.levelNum, 34);
        break;
        case "Beautiful (Not So) Dangerous - 100%":
            s.block = w.CPEntrance && w.Curr(w.roomNum) == 197; // pre-intro
        break;
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
        case "Jono Hack - Any%":
            //42: 6,20,250
            //39: 3,253H,3,252,251
            //38: 2,H,106,107,255
            //53: 17,18,8,10,16,13
            //5:  5,203,19,7
            s.block = w.Curr(w.levelNum) == 39 && w.Room;
            s.other = w.ShiftToIn(w.levelNum, 39, w.roomNum, 252) || w.ShiftToIn(w.levelNum, 39, w.roomNum, 251);
        break;
        case "Love Yourself - Welcome Home%":
            s.credits = w.Curr(w.levelNum) == 85 && w.Curr(w.roomNum) == 66 && w.EnterDoor;
        break;
        case "Ninji Story - Any%":
            s.other = w.ShiftToIn(w.levelNum, 57, w.roomNum, 2);
        break;
        case "Nonsense - 16 Exit":
        case "Nonsense - 24 Exit":
            s.block = w.CPEntrance && w.Curr(w.roomNum) == 101; // Extra CP at beginning of Angry Parachutes when icy
            s.credits = w.ShiftIn(w.levelNum, 94, w.io, 255, 37); // Peach drop
        break;
        case "Toothpaste World - Any%":
            s.credits = w.ShiftTo(w.levelNum, 54);
        break;
        case "Yoshi's Revenge - 46* Exit":
        case "Yoshi's Revenge - Credits%":
        case "Yoshi's Revenge - Torn Apart IL":
            s.other = 
                w.ShiftIn(w.levelNum, 32, w.roomNum, 46, 47) || // Maze to Bosses
                w.Stepped(w.yoshiCoin) && !(
                    w.Curr(w.levelNum) == 52 ||                           // Last Journey
                    (w.Curr(w.levelNum) == 32 && w.Curr(w.roomNum) != 48) // Torn Apart
                );
            s.block = w.CPEntrance && w.Curr(w.levelNum) == 32 && w.Prev(w.roomNum) == 46 || // Maze midways
                      w.CPEntrance && w.Curr(w.levelNum) == 31 && w.Curr(w.roomNum) == 31 || // Madness 1 midways
                      w.CPEntrance && w.Curr(w.levelNum) == 86 && (                          // Tengoku galoomba skip
                        w.Curr(w.roomNum) == 102 ||
                        w.Curr(w.roomNum) == 103 ||
                        w.Curr(w.roomNum) == 104);
            s.credits = w.Curr(w.levelNum) == 52 && w.GotGoal;
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
            s.lastSplitTime = vars.startMs;
            return true;
        }
        d.Dbg("Skip: " + s.SkipReasons(lag));
        new TimerModel { CurrentState = timer }.SkipSplit();
    } else {
        var blockedReasons = s.BlockedReasons();
        var splitReasons = s.SplitReasons();
        if (blockedReasons != "" && splitReasons != "") {
            d.Dbg("Blocked: " + blockedReasons + " (" + splitReasons + ")");
        }
    }
}

onStart {
    vars.running = true;
}

onReset {
    vars.running = false;
}
