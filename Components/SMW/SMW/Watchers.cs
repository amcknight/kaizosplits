using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SMW {
    public class Watchers : MemoryWatcherList {

        public bool died;
        public bool gameOvered;
        public bool roomStep;
        public uint prevIO;
        public uint firstRoom;
        public List<MemoryWatcher> xs = new List<MemoryWatcher>();

        private string[] enabledMemory;

        public Watchers() {
            died = false;
            gameOvered = false;
            roomStep = false;
            prevIO = 256; // junk default value
            firstRoom = 0; // junk default value
        }

        public void Init(string[] enabledMemory) {
            this.enabledMemory = enabledMemory;
        }

        public void SetMemoryOffset(long memoryOffset, Dictionary<int, int> ranges) {
            foreach (MemEntry entry in Memory.entries) {
                if (!enabledMemory.Contains(entry.Name)) continue;
                IntPtr addr = (IntPtr)memoryOffset + entry.Offset;
                MemoryWatcher mw;
                switch (entry.Size) {
                    case MemSize.Byte:  mw = new MemoryWatcher<byte>(addr)   { Name = entry.Name }; break;
                    case MemSize.Short: mw = new MemoryWatcher<ushort>(addr) { Name = entry.Name }; break;
                    case MemSize.Int:   mw = new MemoryWatcher<uint>(addr)   { Name = entry.Name }; break;
                    default: throw new ArgumentOutOfRangeException();
                }
                Add(mw);
            }
            foreach (KeyValuePair<int, int> entry in ranges) {
                for (int i = entry.Key; i < entry.Value; i++) {
                    MemoryWatcher x = new MemoryWatcher<byte>((IntPtr)memoryOffset + i) { Name = "i" + i.ToString("X4") };
                    xs.Add(x);
                    Add(x);
                }
            }
        }

        public MemoryWatcher fileSelect => this["fileSelect"];
        public MemoryWatcher marioLives => this["marioLives"];
        public MemoryWatcher luigiLives => this["luigiLives"];
        public MemoryWatcher submap => this["submap"];
        public MemoryWatcher fanfare => this["fanfare"];
        public MemoryWatcher victory => this["victory"];
        public MemoryWatcher bossDefeat => this["bossDefeat"];
        public MemoryWatcher io => this["io"];
        public MemoryWatcher yellowSwitch => this["yellowSwitch"];
        public MemoryWatcher greenSwitch => this["greenSwitch"];
        public MemoryWatcher blueSwitch => this["blueSwitch"];
        public MemoryWatcher redSwitch => this["redSwitch"];
        public MemoryWatcher roomCounter => this["roomCounter"];
        public MemoryWatcher peach => this["peach"];
        public MemoryWatcher midway => this["midway"];
        public MemoryWatcher cpEntrance => this["cpEntrance"];
        public MemoryWatcher pipe => this["pipe"];
        public MemoryWatcher playerAnimation => this["playerAnimation"];
        public MemoryWatcher yoshiCoin => this["yoshiCoin"];
        public MemoryWatcher levelStart => this["levelStart"];
        public MemoryWatcher weirdLevVal => this["weirdLevVal"];
        public MemoryWatcher eventsTriggered => this["eventsTriggered"];
        public MemoryWatcher overworldPortal => this["overworldPortal"];
        public MemoryWatcher levelNum => this["levelNum"];
        public MemoryWatcher roomNum => this["roomNum"];
        public MemoryWatcher exitMode => this["exitMode"];
        public MemoryWatcher player => this["player"];
        public MemoryWatcher gameMode => this["gameMode"];
        public MemoryWatcher overworldTile => this["overworldTile"];
        public MemoryWatcher buttonsHeld1 => this["buttonsHeld1"];
        public MemoryWatcher buttonsPress1 => this["buttonsPress1"];
        public MemoryWatcher buttonsHeld2 => this["buttonsHeld2"];
        public MemoryWatcher buttonsPress2 => this["buttonsPress2"];

        public MemoryWatcher playerX => this["playerX"];
        public MemoryWatcher playerY => this["playerY"];
        public MemoryWatcher marioOverworldX => this["marioOverworldX"];
        public MemoryWatcher marioOverworldY => this["marioOverworldY"];

        // Temporary Test Watchers. keep or drop these
        public MemoryWatcher levelMode => this["levelMode"];
        public MemoryWatcher inWater => this["inWater"];
        public MemoryWatcher moonCounter => this["moonCounter"];
        public MemoryWatcher layer1Pointer => this["layer1Pointer"];


        // Ongoing state
        public bool GotOrb => Curr(io) == 3;
        public bool GotGoal => Curr(io) == 4;
        public bool GotKey => Curr(io) == 7;
        public bool GotFadeout => Curr(io) == 8;
        public bool BossUndead => Curr(bossDefeat) == 0;
        public bool InLevel => Curr(levelStart) == 1;
        public bool IsMario => Curr(player) == 0;
        public bool IsLuigi => Curr(player) == 1;

        // Changed state
        public bool ToFileSelect => ShiftFrom(fileSelect, 0);
        public bool FromFileSelect => ShiftTo(fileSelect, 0);
        public bool FromOneMarioLife => ShiftFrom(marioLives, 0);
        public bool FromOneLuigiLife => ShiftFrom(luigiLives, 0);
        public bool ToOneMarioLife => ShiftTo(marioLives, 0);
        public bool ToOneLuigiLife => ShiftTo(luigiLives, 0);
        public bool ToOrb => ShiftTo(io, 3);
        public bool ToGoal => ShiftTo(io, 4);
        public bool ToKey => ShiftTo(io, 7);
        public bool GmFileSelect => ShiftTo(gameMode, 8);
        public bool GmPlayerSelect => ShiftTo(gameMode, 10);
        public bool GmOverworldFadeIn => ShiftTo(gameMode, 13);
        public bool GmFadeToLevel => ShiftTo(gameMode, 15);
        public bool GmFadeToLevelBlack => ShiftTo(gameMode, 16);
        public bool GmLoadLevel => ShiftTo(gameMode, 17);
        public bool GmPrepareLevel => ShiftTo(gameMode, 18);
        public bool GmLevelFadeIn => ShiftTo(gameMode, 19);
        public bool GmLevel => ShiftTo(gameMode, 20);
        public bool GmGameOver => ShiftFrom(gameMode, 23);
        public bool NewEvent => Stepped(eventsTriggered);
        public bool ToOverworldPortal => Shift(overworldPortal, 1, 0);
        public bool SubmapShift => Shifted(submap);
        public bool ToFanfare => StepTo(fanfare, 1);
        public bool IntroExit => Shift(weirdLevVal, 233, 0);
        public bool ToYellowSwitch => StepTo(yellowSwitch, 1);
        public bool ToGreenSwitch => StepTo(greenSwitch, 1);
        public bool ToBlueSwitch => StepTo(blueSwitch, 1);
        public bool ToRedSwitch => StepTo(redSwitch, 1);
        public bool ToLevelStart => StepTo(levelStart, 1);
        public bool ToPeachRelease => StepTo(peach, 1);
        public bool ToMidway => StepTo(midway, 1);
        public bool DiedNow => ShiftTo(playerAnimation, 9);
        public bool LosingPowerup => ShiftTo(playerAnimation, 1);
        public bool GotMushroom => ShiftTo(playerAnimation, 2);
        public bool GotFeather => ShiftTo(playerAnimation, 3);
        public bool GotFlower => ShiftTo(playerAnimation, 4);
        public bool EnterDoor => Shift(playerAnimation, 0, 13);
        public bool ExitDoor => Shift(playerAnimation, 13, 0);

        // Composite Conditions
        // public bool ToExit => ShiftFrom(exitMode, 0) && !ShiftTo(exitMode, 128);
        public bool ToExit => Shifted(exitMode) && Curr(exitMode) != 0 && Curr(exitMode) != 128;
        public bool EnteredPipe => Shifted(pipe) && Curr(pipe) < 4 && (Curr(playerAnimation) == 5 || Curr(playerAnimation) == 6);
        public bool Put => GmPrepareLevel && !died;
        public bool Spawn => GmPrepareLevel && died;
        public bool Intro => IntroExit;
        public bool LevelExit => ToExit;
        public bool Goal => ToFanfare && BossUndead && !GotOrb;
        public bool Key => ToKey;
        public bool Orb => ToOrb && BossUndead;
        public bool Palace => ToYellowSwitch || ToGreenSwitch || ToBlueSwitch || ToRedSwitch;
        public bool Boss => ToFanfare && !BossUndead;
        public bool GotPowerup => GotMushroom || GotFeather || GotFlower;
        public bool LevelStart => ToLevelStart;
        public bool PeachRelease => ToPeachRelease;
        public bool Midway => ToMidway && !GotOrb && !GotGoal && !GotKey && !GotFadeout;
        public bool CPEntrance => InLevel && Shifted(cpEntrance) && !ShiftTo(cpEntrance, firstRoom) && !GotOrb && !GotGoal && !GotKey && !GotFadeout;
        public bool CP => Midway || CPEntrance;
        public bool Room => roomStep;
        public bool Submap => SubmapShift;
        public bool Portal => ToOverworldPortal;

        // Highest level conditions
        public bool LevelFinish => Goal || Key || Orb || Palace || Boss;
        public bool Overworld => !InLevel && (Portal || Submap);

        public void UpdateState() {
            // Maintain these until "shut off"
            died = died || DiedNow;
            gameOvered = gameOvered || GmGameOver;

            // Only roomStep if didn't just die. Assumes every death sets the roomCount to 1.
            roomStep = false;
            if (Stepped(roomCounter)) {
                roomStep = Curr(roomCounter) != 1 || !died;
            }
            // Track whether in post-gameover restart state
            if (GmOverworldFadeIn) {
                gameOvered = false;
            }
            // PrevIO is basically Current IO except when a P-Switch or Star shifts the io to 0
            if (Curr(io) != 0) {
                prevIO = Curr(io);
            }
            // Saving first roomNum when entering level to ignore the first cpEntrance
            if (Shifted(levelNum)) {
                firstRoom = Curr(roomNum);
            } else if (CP) {
                firstRoom = 0;
            }

            if (Spawn) died = false;
        }

        // Type-erased accessors. Reads the boxed object on the abstract base
        // class — works for any MemoryWatcher<byte|ushort|uint>. Returns uint
        // because that's wide enough for every value we read from SNES memory.
        public uint Prev(MemoryWatcher w) {
            return Convert.ToUInt32(w.Old ?? (uint)0);
        }

        public uint Curr(MemoryWatcher w) {
            return Convert.ToUInt32(w.Current ?? (uint)0);
        }

        public bool Shift(MemoryWatcher w, uint o, uint c) {
            return Compare.Shift(Prev(w), Curr(w), o, c);
        }

        public bool ShiftTo(MemoryWatcher w, uint c) {
            return Compare.ShiftTo(Prev(w), Curr(w), c);
        }

        public bool ShiftFrom(MemoryWatcher w, uint o) {
            return Compare.ShiftFrom(Prev(w), Curr(w), o);
        }

        public bool Shifted(MemoryWatcher w) {
            return Compare.Shifted(Prev(w), Curr(w));
        }

        public bool StepTo(MemoryWatcher w, uint c) {
            return Compare.StepTo(Prev(w), Curr(w), c);
        }

        public bool Stepped(MemoryWatcher w) {
            return Compare.Stepped(Prev(w), Curr(w));
        }

        public bool Crossed(MemoryWatcher w, uint c) {
            return Compare.Crossed(Prev(w), Curr(w), c);
        }

        public bool ShiftIn(MemoryWatcher inW, uint inVal, MemoryWatcher shiftW, uint from, uint to) {
            return Shift(shiftW, from, to) && Curr(inW) == inVal;
        }
        public bool ShiftToIn(MemoryWatcher inW, uint inVal, MemoryWatcher shiftW, uint to) {
            return ShiftTo(shiftW, to) && Curr(inW) == inVal;
        }
        public bool ShiftFromIn(MemoryWatcher inW, uint inVal, MemoryWatcher shiftW, uint from) {
            return ShiftFrom(shiftW, from) && Curr(inW) == inVal;
        }
        public bool ShiftsIn(MemoryWatcher inW, uint inVal, MemoryWatcher shiftW) {
            return Shifted(shiftW) && Curr(inW) == inVal;
        }
    }
}
