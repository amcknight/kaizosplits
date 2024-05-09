state("snes9x"){}
state("snes9x-x64"){}
state("bsnes"){}
state("retroarch"){}
state("higan"){}
state("snes9x-rr"){}
state("emuhawk"){}

startup {
    vars.ticksUntilShowHist = 500;
    vars.tick = 0;

    byte[] smwBytes = File.ReadAllBytes("Components/SMW.dll");
    Assembly smwAsm = Assembly.Load(smwBytes);
    vars.t =  Activator.CreateInstance(smwAsm.GetType("SMW.Timer"));
}

update {
    var t = vars.t;
    t.Update();
    if (vars.tick % vars.ticksUntilShowHist == 0) print(t.ToString());
    vars.tick++;
    t.HistNow();
}