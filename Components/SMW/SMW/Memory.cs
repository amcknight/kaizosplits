using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;

namespace SMW {
    public class Memory {
        
        public static Dictionary<int, string> shortMap = new Dictionary<int, string> {
          {0x00D1, "playerX"},
          {0x00D3, "playerY"},
        };

        public static Dictionary<int, string> byteMap = new Dictionary<int, string> {
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

        public void Update(MemoryWatcherList watchers) {
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
        }

        public static ushort Prev(MemoryWatcher w) {
            return Convert.ToUInt16(w.Old);
        }

        public static ushort Curr(MemoryWatcher w) {
            return Convert.ToUInt16(w.Current);
        }
    }
}
