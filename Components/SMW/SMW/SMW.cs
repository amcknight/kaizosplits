using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;

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
          {0x0071, "cutScene"},
          {0x1420, "yoshiCoin"},
          {0x0109, "weirdLevVal"},
          {0x1F2E, "eventsTriggered"},
          {0x010B, "roomNum"},
          {0x13BF, "levelNum"},
          {0x1F11, "submap"},
          {0x1B9C, "overworldPortal"},
          // STILL TESTING
          {0x0100, "gameMode"},
          {0x0DB3, "player"},
          {0x1925, "levelMode"},
          {0x1935, "levelStart"},
          {0x1DEA, "overworldExitEvent"},
          // OTHER THINGS TO TEST
            // Screen Width 005E
            // Screen height 005F
            // In Water 0075
            // 0100 Game Mode
            // 0109 weird level value
            // 010B 245 bytes stack, but first two bytes are usually level num
            // 0D9B IRQ or whatever for game modes
            // 0DB3 Player in play
            // 13C1 Overworld tile number
            // 13C5 Moon counter
            // 141C Goal flag type
            // 1935 Used by Mario start
            // 19B8 32byte exit table
            // 19D8 32byte exit table flags
            // 1B95 Yoshi wings to the sky flag
            // 1B96 Side exits enabled
            // 1B99 Mario peace sign
            // 1DEA Overworld event to run at level end
            // 1EA2 First 12 beaten level, next 12 midway, then a bunch more
            // 1F2E Events triggered / Levels beaten
            // 0DD5 How a level was exited
            // 13BF Status of level (beaten, midway, directions enabled)
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
        public MemoryWatcher<byte> cutScene;
        public MemoryWatcher<byte> yoshiCoin;
        public MemoryWatcher<byte> levelStart;
        public MemoryWatcher<byte> weirdLevVal;
        public MemoryWatcher<byte> eventsTriggered;
        public MemoryWatcher<byte> overworldPortal;
        public MemoryWatcher<byte> levelNum;
        public MemoryWatcher<byte> roomNum;
        public MemoryWatcher<short> playerX;
        public MemoryWatcher<short> playerY;
        // Temporary Test Watchers
        public MemoryWatcher<byte> gameMode;
        public MemoryWatcher<byte> levelMode;
        public MemoryWatcher<byte> player;
        public MemoryWatcher<byte> overworldExitEvent;

        // Stateful Vars
        public bool died = false;
        public bool roomStep = false;
        public ushort prevIO = 256; // 256 is a junk default value

        public List<string> debugInfo;

        // Composite Vars
        public bool enteredPipe => shifted(pipe) && curr(pipe) < 4 && (curr(cutScene) == 5 || curr(cutScene) == 6);
        public bool toOrb => shiftTo(io, 3);
        public bool toGoal => shiftTo(io, 4);
        public bool toKey => shiftTo(io, 7);
        public bool gotOrb => curr(io) == 3;
        public bool gotGoal => curr(io) == 4;
        public bool gotKey => curr(io) == 7;
        public bool gotFadeout => curr(io) == 8;
        public bool bossUndead => curr(bossDefeat) == 0;
        public bool placed => shiftTo(gameMode, 20);
        public bool diedNow => shift(cutScene, 9, 6);

        public void update(MemoryWatcherList watchers) {
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
            cutScene = (MemoryWatcher<byte>)watchers["cutScene"];
            yoshiCoin = (MemoryWatcher<byte>)watchers["yoshiCoin"];
            levelStart = (MemoryWatcher<byte>)watchers["levelStart"];
            weirdLevVal = (MemoryWatcher<byte>)watchers["weirdLevVal"];
            eventsTriggered = (MemoryWatcher<byte>)watchers["eventsTriggered"];
            overworldPortal = (MemoryWatcher<byte>)watchers["overworldPortal"];
            levelNum = (MemoryWatcher<byte>)watchers["levelNum"];
            roomNum = (MemoryWatcher<byte>)watchers["roomNum"];
            playerX = (MemoryWatcher<short>)watchers["playerX"];
            playerY = (MemoryWatcher<short>)watchers["playerY"];

            // Temporary Test properties
            gameMode = (MemoryWatcher<byte>)watchers["gameMode"];
            levelMode = (MemoryWatcher<byte>)watchers["levelMode"];
            player = (MemoryWatcher<byte>)watchers["player"];
            overworldExitEvent = (MemoryWatcher<byte>)watchers["overworldExitEvent"];

            // Stateful Vars
            // Only roomStep if didn't just die. Assumes every death sets the roomCount to 1.
            died = died || diedNow;
            roomStep = false;
            if (stepped(roomCounter)) {
                roomStep = curr(roomCounter) != 1 || !died;
                died = false;
            }
            // PrevIO is basically Current IO except when a P-Switch or Star shifts the io to 0
            if (curr(io) != 0) {
                prevIO = curr(io);
            }
        }


        public bool shift(MemoryWatcher w, ushort o, ushort c) {
            return prev(w) == o && curr(w) == c;
        }

        public bool shiftTo(MemoryWatcher w, ushort c) {
            return prev(w) != c && curr(w) == c;
        }

        public bool shiftFrom(MemoryWatcher w, ushort o) {
            return prev(w) == o && curr(w) != o;
        }

        public bool shifted(MemoryWatcher w) {
            return prev(w) != curr(w);
        }

        public bool stepTo(MemoryWatcher w, ushort c) {
            return curr(w) == c && prev(w) + 1 == curr(w);
        }

        public bool stepped(MemoryWatcher w) {
            return prev(w) + 1 == curr(w);
        }

        // Default Split Conditions
        public bool start => stepTo(levelStart, 1);
        public bool goalExit => stepTo(fanfare, 1) && bossUndead && !gotOrb;  // didn't defeat boss already or get an Orb TODO: Mix "victory" into this condition
        public bool keyExit => toKey;
        public bool orbExit => toOrb && bossUndead;
        public bool palaceExit => stepTo(yellowSwitch, 1) || stepTo(greenSwitch, 1) || stepTo(blueSwitch, 1) || stepTo(redSwitch, 1);
        public bool bossExit => stepTo(fanfare, 1) && curr(bossDefeat) != 0;
        public bool peachReleased => stepTo(peach, 1);
        public bool tape => stepTo(checkpointTape, 1) && !gotOrb && !gotGoal && !gotKey && !gotFadeout;
        public bool room => roomStep;
        public bool coinFlag => false;
        public bool credits => false;
        public bool introExit => shift(weirdLevVal, 233, 0);
        public bool exitOverworldPortal => shift(overworldPortal, 1, 0);
        public bool submapShift => shifted(submap);

        // Construct high level split conditions
        public bool levelExit => goalExit || keyExit || orbExit || palaceExit || bossExit || introExit;
        public bool bossDefeated => false;
        public bool flag => coinFlag;
        public bool runDone => peachReleased || credits;
        public bool overworld => exitOverworldPortal || submapShift;

        public void dbg(string msg) {
            debugInfo.Add(msg);
        }

        public void monitor(MemoryWatcher w) {
            if (prev(w) != curr(w)) {
                dbg(w.Name + ": " + prev(w) + "->" + curr(w));
            }
        }

        public List<string> splitPoints = new List<string>();
        public void track(bool condition, string name) {
            if (condition) {
                splitPoints.Add(name + ": " + string.Join(", ", new List<string> {
                    "Map " + curr(submap),
                    "Level " + curr(levelNum),
                    "Room " + curr(roomNum),
                    "Pos (" + curr(playerX) + ", " + curr(playerY) + ")"
                    }
                ));
            }
        }

        public string splitReasons() {
            string reasons = "";
            reasons += start ? " levelStart" : "";
            reasons += goalExit ? " goalExit" : "";
            reasons += keyExit ? " keyExit" : "";
            reasons += orbExit ? " orbExit" : "";
            reasons += palaceExit ? " palaceExit" : "";
            reasons += bossExit ? " bossExit" : "";
            reasons += tape ? " tape" : "";
            reasons += room ? " room" : "";
            reasons += coinFlag ? " coinFlag" : "";
            reasons += peachReleased ? " peachReleased" : "";
            reasons += credits ? " credits" : "";
            reasons += submapShift ? " submapShift" : "";
            reasons += exitOverworldPortal ? " exitOverworldPortal" : "";
            return reasons;
        }

        public ushort prev(MemoryWatcher w) {
            return Convert.ToUInt16(w.Old);
        }

        public ushort curr(MemoryWatcher w) {
            return Convert.ToUInt16(w.Current);
        }
    }
}
