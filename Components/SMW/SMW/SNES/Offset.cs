using LiveSplit.ComponentUtil;
using System.Collections.Generic;

namespace SNES {
    public class Offset {
        public static Dictionary<int, string> version = new Dictionary<int, string> {
            { 15675392, "1.9.4"  }, // retroarch
            { 16793600, "1.16.0" }, // retroarch
            { 17264640, "1.17.0" }, // retroarch
            { 18350080, "1.21.0" }, // retroarch
            {  6991872, "1.57"   }, // snes9x
            {  9027584, "1.60"   }, // snes9x
            {  9158656, "1.61"   }, // snes9x
            { 10399744, "1.62.3" }, // snes9x
            { 12537856, "1.59.2" }, // snes9x x64
            { 12836864, "1.60"   }, // snes9x x64
            { 12955648, "1.61"   }, // snes9x x64
            { 29069312, "1.62"   }, // snes9x x64
            { 15474688, "1.62.3" }, // snes9x x64 (also 1.62.2)
            {  9646080, "1.60"   }, // snes9x-rr
            { 13565952, "1.60"   }, // snes9x-rr x64
            { 10096640, "107"    }, // bsnes
            { 10338304, "107.1"  }, // bsnes
            { 47230976, "107.2"  }, // bsnes (also 107.3)
            {131543040, "110"    }, // bsnes
            { 51924992, "111"    }, // bsnes
            { 52056064, "112"    }, // bsnes
		    { 52477952, "115"    }, // bsnes
            { 16019456, "106"    }, // higan
            { 15360000, "106.112"}, // higan
		    { 22388736, "107"    }, // higan
		    { 23142400, "108"    }, // higan
		    { 23166976, "109"    }, // higan
		    { 23224320, "110"    }, // higan
            {  7061504, "2.3"    }, // BizHawk
            {  7249920, "2.3.1"  }, // BizHawk
            {  6938624, "2.3.2"  }, // BizHawk
        };
        // x comments means I didn't test the offset. picked up from prior splitters
        // If using a direct address, use this
        public static Dictionary<string, long> mem = new Dictionary<string, long> {
            { "higan 106",    0x94D144 }, // x
            { "higan 106.112",0x8AB144 }, // x
		    { "higan 107",    0xB0ECC8 }, // x
		    { "higan 108",    0xBC7CC8 }, // x
		    { "higan 109",    0xBCECC8 }, // x
		    { "higan 110",    0xBDBCC8 }, // x
            { "bsnes 107",    0x72BECC }, // x
            { "bsnes 107.1",  0x762F2C }, // x
            { "bsnes 107.2",  0x765F2C }, // x
            { "bsnes 107.3",  0x765F2C }, // x
            { "bsnes 110",    0xA9BD5C }, // x
            { "bsnes 111",    0xA9DD5C }, // x
            { "bsnes 112",    0xAAED7C }, // x
		    { "bsnes 115",    0xB16D7C },
            { "emuhawk 2.3",  0x36F11500240 }, // x
            { "emuhawk 2.3.1",0x36F11500240 }, // x
            { "emuhawk 2.3.2",0x36F11500240 }, // x
        };
        // if using a pointer, use this. Without the 0x0 offset, it doesn't dereference properly...
        public static Dictionary<string, DeepPointer> memPtr = new Dictionary<string, DeepPointer> {
            { "snes9x 1.60",   new DeepPointer("snes9x.exe", 0x54DB54, 0x0) },
            { "snes9x 1.61",   new DeepPointer("snes9x.exe", 0x507BC4, 0x0) },
            { "snes9x 1.62.3", new DeepPointer("snes9x.exe",  0x12698, 0x0) },
            { "snes9x-x64 1.59.2", new DeepPointer("snes9x-x64.exe",  0x8D86F8, 0x0) },
            { "snes9x-x64 1.60",   new DeepPointer("snes9x-x64.exe",  0x8D86F8, 0x0) },
            { "snes9x-x64 1.61",   new DeepPointer("snes9x-x64.exe",  0x883158, 0x0) },
            { "snes9x-x64 1.62",   new DeepPointer("snes9x-x64.exe", 0x1758D40, 0x0) },
            { "snes9x-x64 1.62.2", new DeepPointer("snes9x-x64.exe",  0xA62390, 0x0) },
            { "snes9x-x64 1.62.3", new DeepPointer("snes9x-x64.exe",  0xA62390, 0x0) },
        };
        public static Dictionary<string, DeepPointer> smcPathPtr = new Dictionary<string, DeepPointer> {
            { "snes9x 1.60",   new DeepPointer("snes9x.exe", 0x557B7D) },
            { "snes9x 1.61",   new DeepPointer("snes9x.exe",  0xE162C, 0x1) },
            { "snes9x 1.62.3", new DeepPointer("snes9x.exe", 0x5C14D4, 0x0) },
            { "snes9x-x64 1.59.2", new DeepPointer("snes9x-x64.exe",  0x8EA749) },
            { "snes9x-x64 1.60",   new DeepPointer("snes9x-x64.exe",  0x8EAC39) },
            { "snes9x-x64 1.61",   new DeepPointer("snes9x-x64.exe",  0x8951CF) },
            { "snes9x-x64 1.62",   new DeepPointer("snes9x-x64.exe", 0x176AD48, 0x0) },
            { "snes9x-x64 1.62.2", new DeepPointer("snes9x-x64.exe",  0xA74398, 0x0) },
            { "snes9x-x64 1.62.3", new DeepPointer("snes9x-x64.exe",  0xA74398, 0x0) },
            { "bsnes 115", new DeepPointer("bsnes.exe", 0x31FC528, 0x0, 0xE8) },
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD69926) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8E80F) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEFF8A9) },
            { "retroarch 1.21.0", new DeepPointer("retroarch.exe", 0xFB5BD1) },
        }; 
        public static Dictionary<string, DeepPointer> corePathPtr = new Dictionary<string, DeepPointer> {
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD6A900) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8F7E9) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEEB59A) },
            { "retroarch 1.21.0", new DeepPointer("retroarch.exe", 0xFB157C) },
        };
        public static Dictionary<string, DeepPointer> coreVersionPtr = new Dictionary<string, DeepPointer> {
            { "retroarch 1.9.4",  new DeepPointer("retroarch.exe", 0xD67600) },
            { "retroarch 1.16.0", new DeepPointer("retroarch.exe", 0xE8C4E9) },
            { "retroarch 1.17.0", new DeepPointer("retroarch.exe", 0xEFD5A9) },
            { "retroarch 1.21.0", new DeepPointer("retroarch.exe", 0xFBE399) },
        };
        public static Dictionary<string, int> coreMem = new Dictionary<string, int> {
            { "snes9x_libretro.dll 1.62.3 ec4ebfc", 0x3BA164 },
            { "snes9x_libretro.dll 1.63 49f4845",   0x3BB164 },
            { "bsnes_libretro.dll 115",             0x7D39DC },
        };
        public static Dictionary<string, DeepPointer> coreMemPtr = new Dictionary<string, DeepPointer> {
            { "snes9x2010_libretro.dll 1.52.4 d8b10c4", new DeepPointer("retroarch.exe", 0xEF9FF8, 0x8, 0x0) },
        };
    }
}
