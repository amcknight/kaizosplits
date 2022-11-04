using System.Collections.Generic;

namespace SMW {
    public class Locator {
        public static Dictionary<int, long> offsets = new Dictionary<int, long> {
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
    }
}
