﻿using System.Collections.Generic;

namespace SMW {
    public class Memory {

        public static Dictionary<int, string> intMap = new Dictionary<int, string> {
            {0x0065, "layer1Pointer"},
        };

        public static Dictionary<int, string> shortMap = new Dictionary<int, string> {
            {0x00D1, "playerX"},
            {0x00D3, "playerY"},
            {0x1F17, "marioOverworldX"},
            {0x1F19, "marioOverworldY"},
            {0x1F1B, "luigiOverworldX"},
            {0x1F1D, "luigiOverworldY"},
        };

        public static Dictionary<int, string> byteMap = new Dictionary<int, string> {
            {0x0DB4, "marioLives"},
            {0x0DB5, "luigiLives"},
            {0x0906, "fanfare"},
            {0x1ED2, "fileSelect"},
            {0x1B99, "victory"},
            {0x1DFB, "io"}, // SPC700 I/0 Ports. Related to music
            {0x1f28, "yellowSwitch"},
            {0x1f27, "greenSwitch"},
            {0x1f29, "blueSwitch"},
            {0x1f2a, "redSwitch"},
            {0x141A, "roomCounter"},
            {0x13C6, "bossDefeat"},
            {0x190D, "peach"},
            {0x13CE, "midway"},
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
            {0x0DD5, "exitMode"},
            {0x0DB3, "player"},
            {0x1935, "levelStart"},
            {0x1B403,"cpEntrance"},

            {0x0015, "buttonsHeld1"},
            {0x0016, "buttonsPress1"},
            {0x0017, "buttonsHeld2"},
            {0x0018, "buttonsPress2"},
            {0x13C1, "overworldTile"},
            {0x0075, "inWater"},
            {0x13C5, "moonCounter"},

            // 049AC5 Level names (460 bytes)
            // 04A0FC How to put level names together (186 bytes, 16 bytes at a time)
        };
    }
}
