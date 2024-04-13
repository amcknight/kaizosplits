state("snes9x-x64") {
    byte room : "snes9x-x64.exe", 0xA62390, 0x10B;
}

startup {
    print("STARTUP");
}

init {
    print("INIT");
}

update {
    //print("UPDATE");
}

start {
    //print("START");
}

reset {
    //print("RESET");
}

split {
    //print("SPLIT");
    //print("ROOM: "+current.room);
}

onStart {
    print("ONSTART");
}

onReset {
    print("ONRESET");
}
