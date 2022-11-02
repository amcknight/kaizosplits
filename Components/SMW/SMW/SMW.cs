using LiveSplit.ComponentUtil;
using LiveSplit.Model;
using System;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class SMW {
        public Dictionary<int, long> states = new Dictionary<int, long> {
            { 9646080,   0x97EE04 },      // Snes9x-rr 1.60
            { 13565952,  0x140925118 },   // Snes9x-rr (x64) 1.61
            { 9027584,   0x94DB54 },      // Snes9x 1.60
            { 12836864,  0x1408D8BE8 },   // Snes9x (x64) 1.60
            { 16019456,  0x94D144 },      // higan v106
            { 15360000,  0x8AB144 },      // higan v106.112
            { 22388736,  0xB0ECC8 },      // higan v107
            { 23142400,  0xBC7CC8 },      // higan v108
            { 23166976,  0xBCECC8 },      // higan v109
            { 23224320,  0xBDBCC8 },      // higan v110
            { 10096640,  0x72BECC },      // bsnes v107
            { 10338304,  0x762F2C },      // bsnes v107.1
            { 47230976,  0x765F2C },      // bsnes v107.2/107.3
            { 131543040, 0xA9BD5C },      // bsnes v110
            { 51924992,  0xA9DD5C },      // bsnes v111
            { 52056064,  0xAAED7C },      // bsnes v112
            { 52477952,  0xB16D7C },      // bsnes v115
            { 7061504,   0x36F11500240 }, // BizHawk 2.3
            { 7249920,   0x36F11500240 }, // BizHawk 2.3.1
            { 6938624,   0x36F11500240 }, // BizHawk 2.3.2
        };

        public Dictionary<int, string> shortMemoryMap = new Dictionary<int, string> {
          {0x00D1, "playerX"},
          {0x00D3, "playerY"},
        };

        public Dictionary<int, string> byteMemoryMap = new Dictionary<int, string> {
          {0x1ED2, "fileSelect"},
          {0x906,  "fanfare"},
          {0x1B99, "victory"},
          {0x1DFB, "io"}, // SPC700 I/0 Ports. Related to music. Important for many transitions.
          {0x1f28, "yellowSwitch"},
          {0x1f27, "greenSwitch"},
          {0x1f29, "blueSwitch"},
          {0x1f2a, "redSwitch"},
          {0x141A, "roomCounter"},
          {0x13C6, "bossDefeat"},
          {0x190D, "peach"},
          {0x13CE, "checkpointTape"},
          {0x0089, "pipe"},
          {0x0071, "playerAnimation"},
          {0x1420, "yoshiCoin"},
          {0x0109, "weirdLevVal"},
          {0x1F2E, "eventsTriggered"},
          {0x010B, "roomNum"},
          {0x13BF, "levelNum"},
          {0x1F11, "submap"},
          {0x1B9C, "overworldPortal"},
          {0x0100, "gameMode"},
          {0x1DEA, "overworldExitEvent"},
          // STILL TESTING
          {0x0DB3, "player"},
          {0x1925, "levelMode"},
          {0x1935, "levelStart"},
          {0x1421, "cp1up"},
          {0x0DD5, "exitMode"},
          
          // OTHER THINGS TO TEST
            // Screen Width 005E
            // Screen height 005F
            // In Water 0075
            // 010B 245 bytes stack, but first two bytes are usually level num
            // 0D9B IRQ or whatever for game modes
            // 0DB3 Player in play
            // 13C1 Overworld tile number
            // 141C Goal flag type
            // 1935 Used by Mario start
            // 1B96 Side exits enabled
            // 1B99 Mario peace sign
            // 1EA2 First 12 beaten level, next 12 midway, then a bunch more
            // 13BF Status of level (beaten, midway, directions enabled)
            // 19B8 (32 bytes) Exit table
            // 19D8 (32 bytes) Exit table flags
            // 0D9B Battle mode
            // 0DD5 Exit mode
            // 13FB Freeze player (yoshi grow, keyhole, yoshi eat berry, some bosses, etc)
            // 1421 1-up checkpoint counter (but maybe includes normal ones?)
          // Useful in rare scenarios?
            // 13C5 Moon counter
            // 1B95 Yoshi wings to the sky flag
            // 18E8 Get yoshi timer (starts at 64 and goes down?)
            // 9AC5 Level names (460 bytes)
            // A0FC How to put level names together (186 bytes, 16 bytes at a time)
        };

        public MemoryWatcher<byte> fileSelect;
        public MemoryWatcher<byte> submap;
        public MemoryWatcher<byte> fanfare;
        public MemoryWatcher<byte> victory;
        public MemoryWatcher<byte> bossDefeat;
        public MemoryWatcher<byte> io;
        public MemoryWatcher<byte> yellowSwitch;
        public MemoryWatcher<byte> greenSwitch;
        public MemoryWatcher<byte> blueSwitch;
        public MemoryWatcher<byte> redSwitch;
        public MemoryWatcher<byte> roomCounter;
        public MemoryWatcher<byte> peach;
        public MemoryWatcher<byte> checkpointTape;
        public MemoryWatcher<byte> pipe;
        public MemoryWatcher<byte> playerAnimation;
        public MemoryWatcher<byte> yoshiCoin;
        public MemoryWatcher<byte> levelStart;
        public MemoryWatcher<byte> weirdLevVal;
        public MemoryWatcher<byte> eventsTriggered;
        public MemoryWatcher<byte> overworldPortal;
        public MemoryWatcher<byte> levelNum;
        public MemoryWatcher<byte> roomNum;
        public MemoryWatcher<byte> overworldExitEvent;
        public MemoryWatcher<byte> exitMode;
        public MemoryWatcher<short> playerX;
        public MemoryWatcher<short> playerY;
        // Temporary Test Watchers
        public MemoryWatcher<byte> gameMode;
        public MemoryWatcher<byte> levelMode;
        public MemoryWatcher<byte> player;
        public MemoryWatcher<byte> cp1up;

        // Stateful Vars
        public bool died;
        public bool roomStep;
        public ushort prevIO;

        public SMW() {
            Init();
        }

        public void Init() {
            died = false;
            roomStep = false;
            prevIO = 256; // 256 is a junk default value
            events = new List<Event>();
        }

        public void Reset() {
            Init();
        }

        // Composite Vars. TODO: Use static functions and Enums for these.
        public bool ToOrb => ShiftTo(io, 3);
        public bool ToGoal => ShiftTo(io, 4);
        public bool ToKey => ShiftTo(io, 7);
        public bool GotOrb => Curr(io) == 3;
        public bool GotGoal => Curr(io) == 4;
        public bool GotKey => Curr(io) == 7;
        public bool GotFadeout => Curr(io) == 8;
        public bool BossUndead => Curr(bossDefeat) == 0;
        public bool GmFadeToLevel => ShiftTo(gameMode, 15);
        public bool GmFadeToLevelBlack => ShiftTo(gameMode, 16);
        public bool GmLoadLevel => ShiftTo(gameMode, 17);
        public bool GmPrepareLevel => ShiftTo(gameMode, 18);
        public bool GmLevelFadeIn => ShiftTo(gameMode, 19);
        public bool GmLevel => ShiftTo(gameMode, 20);
        public bool DiedNow => ShiftTo(playerAnimation, 9);
        public bool NewEvent => Stepped(eventsTriggered);
        public bool ToExit => ShiftFrom(exitMode, 0) && !ShiftTo(exitMode, 128);
        public bool EnteredPipe => Shifted(pipe) && Curr(pipe) < 4 && (Curr(playerAnimation) == 5 || Curr(playerAnimation) == 6);

        // TODO: Should these rely on gmPrepareLevel even tho it isn't accurate?
        // It is consistent, but does Mario get placed after gmPrepareLevel after a CP, especially a 2nd CP?
        public bool Put => GmPrepareLevel && !died;
        public bool Spawn => GmPrepareLevel && died;

        public List<string> debugInfo;

        public void Update(MemoryWatcherList watchers) {
            debugInfo = new List<string>();

            fileSelect = (MemoryWatcher<byte>)watchers["fileSelect"];
            submap = (MemoryWatcher<byte>)watchers["submap"];
            fanfare = (MemoryWatcher<byte>)watchers["fanfare"];
            victory = (MemoryWatcher<byte>)watchers["victory"];
            bossDefeat = (MemoryWatcher<byte>)watchers["bossDefeat"];
            io = (MemoryWatcher<byte>)watchers["io"];
            yellowSwitch = (MemoryWatcher<byte>)watchers["yellowSwitch"];
            greenSwitch = (MemoryWatcher<byte>)watchers["greenSwitch"];
            blueSwitch = (MemoryWatcher<byte>)watchers["blueSwitch"];
            redSwitch = (MemoryWatcher<byte>)watchers["redSwitch"];
            roomCounter = (MemoryWatcher<byte>)watchers["roomCounter"];
            peach = (MemoryWatcher<byte>)watchers["peach"];
            checkpointTape = (MemoryWatcher<byte>)watchers["checkpointTape"];
            pipe = (MemoryWatcher<byte>)watchers["pipe"];
            playerAnimation = (MemoryWatcher<byte>)watchers["playerAnimation"];
            yoshiCoin = (MemoryWatcher<byte>)watchers["yoshiCoin"];
            levelStart = (MemoryWatcher<byte>)watchers["levelStart"];
            weirdLevVal = (MemoryWatcher<byte>)watchers["weirdLevVal"];
            eventsTriggered = (MemoryWatcher<byte>)watchers["eventsTriggered"];
            overworldPortal = (MemoryWatcher<byte>)watchers["overworldPortal"];
            levelNum = (MemoryWatcher<byte>)watchers["levelNum"];
            roomNum = (MemoryWatcher<byte>)watchers["roomNum"];
            overworldExitEvent = (MemoryWatcher<byte>)watchers["overworldExitEvent"];
            exitMode = (MemoryWatcher<byte>)watchers["exitMode"];
            playerX = (MemoryWatcher<short>)watchers["playerX"];
            playerY = (MemoryWatcher<short>)watchers["playerY"];

            // Temporary Test properties
            gameMode = (MemoryWatcher<byte>)watchers["gameMode"];
            levelMode = (MemoryWatcher<byte>)watchers["levelMode"];
            player = (MemoryWatcher<byte>)watchers["player"];
            cp1up = (MemoryWatcher<byte>)watchers["cp1up"];

            // Stateful Vars
            // Only roomStep if didn't just die. Assumes every death sets the roomCount to 1.
            died = died || DiedNow;
            roomStep = false;
            if (Stepped(roomCounter)) {
                roomStep = Curr(roomCounter) != 1 || !died;
            }
            // PrevIO is basically Current IO except when a P-Switch or Star shifts the io to 0
            if (Curr(io) != 0) {
                prevIO = Curr(io);
            }

            Track(Spawn, "Spawn");
            if (Spawn) died = false;
        }

        public bool Shift(MemoryWatcher w, ushort o, ushort c) {
            return Prev(w) == o && Curr(w) == c;
        }

        public bool ShiftTo(MemoryWatcher w, ushort c) {
            return Prev(w) != c && Curr(w) == c;
        }

        public bool ShiftFrom(MemoryWatcher w, ushort o) {
            return Prev(w) == o && Curr(w) != o;
        }

        public bool Shifted(MemoryWatcher w) {
            return Prev(w) != Curr(w);
        }

        public bool StepTo(MemoryWatcher w, ushort c) {
            return Curr(w) == c && Prev(w) + 1 == Curr(w);
        }

        public bool Stepped(MemoryWatcher w) {
            return Prev(w) + 1 == Curr(w);
        }

        // Split Conditions
        public bool OverworldPortal => Shift(overworldPortal, 1, 0);
        public bool SubmapShift => Shifted(submap);
        public bool LevelExit => ToExit;
        public bool IntroExit => Shift(weirdLevVal, 233, 0);
        public bool Goal => StepTo(fanfare, 1) && BossUndead && !GotOrb;
        public bool Key => ToKey;
        public bool Orb => ToOrb && BossUndead;
        public bool Palace => StepTo(yellowSwitch, 1) || StepTo(greenSwitch, 1) || StepTo(blueSwitch, 1) || StepTo(redSwitch, 1);
        public bool Boss => StepTo(fanfare, 1) && Curr(bossDefeat) != 0;
        public bool Start => StepTo(levelStart, 1);
        public bool PeachRelease => StepTo(peach, 1);
        public bool Tape => StepTo(checkpointTape, 1) && !GotOrb && !GotGoal && !GotKey && !GotFadeout;
        public bool Room => roomStep;
        public bool CoinFlag => false;
        public bool Credits => false;

        // Construct high level split conditions
        // TODO: Only split on these if in or out of the overworld
        public bool LevelFinish => Goal || Key || Orb || Palace || Boss;
        public bool Flag => CoinFlag;
        public bool RunDone => PeachRelease || Credits;
        public bool Overworld => OverworldPortal || SubmapShift;

        public void Dbg(string msg) {
            debugInfo.Add(msg);
        }

        public void Monitor(MemoryWatcher w) {
            if (Prev(w) != Curr(w)) {
                Dbg(w.Name + ": " + Prev(w) + "->" + Curr(w));
            }
        }

        public List<Event> events = new List<Event>();
        public void Track(bool condition, string name) {
            if (condition) {
                events.Add(new Event(name, new Place(Curr(submap), Curr(levelNum), Curr(roomNum), Curr(playerX), Curr(playerY))));
            }
        }

        public string SplitReasons() {
            string reasons = "";
            reasons += IntroExit ? " IntroExit" : "";
            reasons += Start ? " Start" : "";
            reasons += Goal ? " Goal" : "";
            reasons += Key ? " Key" : "";
            reasons += Orb ? " Orb" : "";
            reasons += Palace ? " Palace" : "";
            reasons += Boss ? " Boss" : "";
            reasons += Tape ? " Tape" : "";
            reasons += Room ? " Room" : "";
            reasons += CoinFlag ? " CoinFlag" : "";
            reasons += PeachRelease ? " PeachRelease" : "";
            reasons += Credits ? " Credits" : "";
            reasons += SubmapShift ? " SubmapShift" : "";
            reasons += OverworldPortal ? " OverworldPortal" : "";
            return reasons;
        }

        public ushort Prev(MemoryWatcher w) {
            return Convert.ToUInt16(w.Old);
        }

        public ushort Curr(MemoryWatcher w) {
            return Convert.ToUInt16(w.Current);
        }

        public void WriteRun(string path, int num) {
            List<string> eventStrs = new List<string>();
            foreach (Event e in events) {
                eventStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/run" + num + ".txt", eventStrs);
            List<string> routeStrs = new List<string>();
            foreach (Event e in BuildRoute()) {
                routeStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/route" + num + ".txt", routeStrs);
        }

        private Event numEvent(bool clinched, int num, Event e) {
            string name;
            if (clinched) {
                name = "-" + num + ") " + e.name;
            } else {
                name = "~" + num + ") " + e.name;
            }
            return new Event(name, e.place);
        }

        public List<Event> BuildRoute() {
            List<Event> route = new List<Event>();
            List<Event> candidates = new List<Event>();
            Event lastSpawn = null;
            int splitNum = 0;
            foreach (Event e in events) {
                switch (e.name) {
                case "Spawn":
                    if (!e.Equals(lastSpawn)) {
                        if (candidates.Count != 0) {
                            splitNum++;
                            foreach (Event c in candidates) {
                                route.Add(numEvent(false, splitNum, c));
                            }
                        }
                    }
                    lastSpawn = e;
                    candidates = new List<Event>();
                    break;
                case "Intro":
                case "Event":
                case "Key":
                case "Start":
                case "Tape":
                    if (candidates.Count != 0) {
                        splitNum++;
                        foreach (Event c in candidates) {
                            route.Add(numEvent(false, splitNum, c));
                        }
                    }
                    splitNum++;
                    route.Add(numEvent(true, splitNum, e));
                    candidates = new List<Event>();
                    break;
                default:
                    candidates.Add(e);
                    break;
                }
            }
            return route;
        }

        public void Skip(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.SkipSplit();
        }

        public void Undo(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.UndoSplit();
        }
    }
}
