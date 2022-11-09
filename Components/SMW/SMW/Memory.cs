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
          {0x0DD5, "exitMode"},
          // STILL TESTING
          {0x0DB3, "player"},
          {0x1925, "levelMode"},
          {0x1935, "levelStart"},
          {0x1421, "cp1up"},

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
    }
}
