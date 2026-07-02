using System.Collections.Generic;

namespace SMW {
    public enum MemSize { Byte, Short, Int }

    public class MemEntry {
        public int Offset;
        public string Name;
        public MemSize Size;

        public MemEntry(int offset, string name, MemSize size) {
            Offset = offset;
            Name = name;
            Size = size;
        }
    }

    public class Memory {
        public static List<MemEntry> entries = new List<MemEntry> {
            // ints (uint, 4 bytes)
            new MemEntry(0x0065, "layer1Pointer", MemSize.Int),

            // shorts (ushort, 2 bytes)
            new MemEntry(0x00D1, "playerX",          MemSize.Short),
            new MemEntry(0x00D3, "playerY",          MemSize.Short),
            new MemEntry(0x1F17, "marioOverworldX",  MemSize.Short),
            new MemEntry(0x1F19, "marioOverworldY",  MemSize.Short),
            new MemEntry(0x1F1B, "luigiOverworldX",  MemSize.Short),
            new MemEntry(0x1F1D, "luigiOverworldY",  MemSize.Short),

            // bytes
            new MemEntry(0x0DB4, "marioLives",       MemSize.Byte),
            new MemEntry(0x0DB5, "luigiLives",       MemSize.Byte),
            new MemEntry(0x0906, "fanfare",          MemSize.Byte),
            new MemEntry(0x1ED2, "fileSelect",       MemSize.Byte),
            new MemEntry(0x1B99, "victory",          MemSize.Byte),
            new MemEntry(0x1DFB, "io",               MemSize.Byte), // SPC700 I/0 Ports. Related to music
            new MemEntry(0x1f28, "yellowSwitch",     MemSize.Byte),
            new MemEntry(0x1f27, "greenSwitch",      MemSize.Byte),
            new MemEntry(0x1f29, "blueSwitch",       MemSize.Byte),
            new MemEntry(0x1f2a, "redSwitch",        MemSize.Byte),
            new MemEntry(0x141A, "roomCounter",      MemSize.Byte),
            new MemEntry(0x13C6, "bossDefeat",       MemSize.Byte),
            new MemEntry(0x190D, "peach",            MemSize.Byte),
            new MemEntry(0x13CE, "midway",           MemSize.Byte),
            new MemEntry(0x0089, "pipe",             MemSize.Byte),
            new MemEntry(0x0071, "playerAnimation",  MemSize.Byte),
            new MemEntry(0x1420, "yoshiCoin",        MemSize.Byte),
            new MemEntry(0x0109, "weirdLevVal",      MemSize.Byte),
            new MemEntry(0x1F2E, "eventsTriggered",  MemSize.Byte),
            new MemEntry(0x010B, "roomNum",          MemSize.Byte),
            new MemEntry(0x13BF, "levelNum",         MemSize.Byte),
            new MemEntry(0x1F11, "submap",           MemSize.Byte),
            new MemEntry(0x1B9C, "overworldPortal",  MemSize.Byte),
            new MemEntry(0x0100, "gameMode",         MemSize.Byte),
            new MemEntry(0x0DD5, "exitMode",         MemSize.Byte),
            new MemEntry(0x0DB3, "player",           MemSize.Byte),
            new MemEntry(0x1935, "levelStart",       MemSize.Byte),
            new MemEntry(0x1B403,"cpEntrance",       MemSize.Byte),

            new MemEntry(0x0015, "buttonsHeld1",     MemSize.Byte),
            new MemEntry(0x0016, "buttonsPress1",    MemSize.Byte),
            new MemEntry(0x0017, "buttonsHeld2",     MemSize.Byte),
            new MemEntry(0x0018, "buttonsPress2",    MemSize.Byte),
            new MemEntry(0x13C1, "overworldTile",    MemSize.Byte),
            new MemEntry(0x0075, "inWater",          MemSize.Byte),
            new MemEntry(0x13C5, "moonCounter",      MemSize.Byte),

            // 049AC5 Level names (460 bytes)
            // 04A0FC How to put level names together (186 bytes, 16 bytes at a time)
        };
    }
}
