namespace SMW {

    using System.Collections.Generic;
    public class SMW {
        public string hello = "WORLD";

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
          {0x1434, "keyholeTimer"},
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
    }
}
