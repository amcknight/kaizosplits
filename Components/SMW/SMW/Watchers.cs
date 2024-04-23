using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;
using System.Linq;

namespace SMW {
    public class Watchers : MemoryWatcherList {

        public bool died;
        public bool roomStep;
        public ushort prevIO;
        public ushort firstRoom;
        public Dictionary<int, int> yoshiCoinsPerLevel = new Dictionary<int, int>();
        public int totalYoshiCoins = 0;
        public bool totalYoshiCoinsStepped = false;
        public List<MemoryWatcher<byte>> xs = new List<MemoryWatcher<byte>>();

        public Watchers() {
            died = false;
            roomStep = false;
            prevIO = 256; // junk default value
            firstRoom = 0; // junk default value
        }

        public void SetMemoryOffset(long memoryOffset, Dictionary<int, int> ranges) {
            foreach (KeyValuePair<int, string> entry in Memory.intMap) {
                Add(new MemoryWatcher<uint>((IntPtr)memoryOffset + entry.Key) { Name = entry.Value });
            }
            foreach (KeyValuePair<int, string> entry in Memory.shortMap) {
                Add(new MemoryWatcher<ushort>((IntPtr)memoryOffset + entry.Key) { Name = entry.Value });
            }
            foreach (KeyValuePair<int, string> entry in Memory.byteMap) {
                Add(new MemoryWatcher<byte>((IntPtr)memoryOffset + entry.Key) { Name = entry.Value });
            }
            foreach (KeyValuePair<int, int> entry in ranges) {
                for (int i = entry.Key; i < entry.Value; i++) {
                    MemoryWatcher<byte> x = new MemoryWatcher<byte>((IntPtr)memoryOffset + i) { Name = "i" + i.ToString("X4") };
                    xs.Add(x);
                    Add(x);
                }
            }
        }
        
        public MemoryWatcher<byte> fileSelect => (MemoryWatcher<byte>)this["fileSelect"];
        public MemoryWatcher<byte> marioLives => (MemoryWatcher<byte>)this["marioLives"];
        public MemoryWatcher<byte> luigiLives => (MemoryWatcher<byte>)this["luigiLives"];
        public MemoryWatcher<byte> submap => (MemoryWatcher<byte>)this["submap"];
        public MemoryWatcher<byte> fanfare => (MemoryWatcher<byte>)this["fanfare"];
        public MemoryWatcher<byte> victory => (MemoryWatcher<byte>)this["victory"];
        public MemoryWatcher<byte> bossDefeat => (MemoryWatcher<byte>)this["bossDefeat"];
        public MemoryWatcher<byte> io => (MemoryWatcher<byte>)this["io"];
        public MemoryWatcher<byte> yellowSwitch => (MemoryWatcher<byte>)this["yellowSwitch"];
        public MemoryWatcher<byte> greenSwitch => (MemoryWatcher<byte>)this["greenSwitch"];
        public MemoryWatcher<byte> blueSwitch => (MemoryWatcher<byte>)this["blueSwitch"];
        public MemoryWatcher<byte> redSwitch => (MemoryWatcher<byte>)this["redSwitch"];
        public MemoryWatcher<byte> roomCounter => (MemoryWatcher<byte>)this["roomCounter"];
        public MemoryWatcher<byte> peach => (MemoryWatcher<byte>)this["peach"];
        public MemoryWatcher<byte> midway => (MemoryWatcher<byte>)this["midway"];
        public MemoryWatcher<byte> cpEntrance => (MemoryWatcher<byte>)this["cpEntrance"];
        public MemoryWatcher<byte> pipe => (MemoryWatcher<byte>)this["pipe"];
        public MemoryWatcher<byte> playerAnimation => (MemoryWatcher<byte>)this["playerAnimation"];
        public MemoryWatcher<byte> yoshiCoin => (MemoryWatcher<byte>)this["yoshiCoin"];
        public MemoryWatcher<byte> levelStart => (MemoryWatcher<byte>)this["levelStart"];
        public MemoryWatcher<byte> weirdLevVal => (MemoryWatcher<byte>)this["weirdLevVal"];
        public MemoryWatcher<byte> eventsTriggered => (MemoryWatcher<byte>)this["eventsTriggered"];
        public MemoryWatcher<byte> overworldPortal => (MemoryWatcher<byte>)this["overworldPortal"];
        public MemoryWatcher<byte> levelNum => (MemoryWatcher<byte>)this["levelNum"];
        public MemoryWatcher<byte> roomNum => (MemoryWatcher<byte>)this["roomNum"];
        public MemoryWatcher<byte> overworldExitEvent => (MemoryWatcher<byte>)this["overworldExitEvent"];
        public MemoryWatcher<byte> exitMode => (MemoryWatcher<byte>)this["exitMode"];
        public MemoryWatcher<byte> player => (MemoryWatcher<byte>)this["player"];
        public MemoryWatcher<ushort> playerX => (MemoryWatcher<ushort>)this["playerX"];
        public MemoryWatcher<ushort> playerY => (MemoryWatcher<ushort>)this["playerY"];

        // Temporary Test Watchers TODO keep or drop these
        public MemoryWatcher<byte> gameMode => (MemoryWatcher<byte>)this["gameMode"];
        public MemoryWatcher<byte> fadeOut => (MemoryWatcher<byte>)this["fadeOut"];
        public MemoryWatcher<byte> levelMode => (MemoryWatcher<byte>)this["levelMode"];
        public MemoryWatcher<uint> layer1Pointer => (MemoryWatcher<uint>)this["layer1Pointer"];

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
        public bool GmFadeToLevel => ShiftTo(gameMode, 15);
        public bool GmFadeToLevelBlack => ShiftTo(gameMode, 16);
        public bool GmLoadLevel => ShiftTo(gameMode, 17);
        public bool GmPrepareLevel => ShiftTo(gameMode, 18);
        public bool GmLevelFadeIn => ShiftTo(gameMode, 19);
        public bool GmLevel => ShiftTo(gameMode, 20);
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
        public bool ToExit => ShiftFrom(exitMode, 0) && !ShiftTo(exitMode, 128);
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
        public bool CPEntrance => Shifted(cpEntrance) && !ShiftTo(cpEntrance, firstRoom);
        public bool CP => Midway || CPEntrance;
        public bool Room => roomStep;
        public bool Submap => SubmapShift;
        public bool Portal => ToOverworldPortal;

        // Highest level conditions
        public bool LevelFinish => Goal || Key || Orb || Palace || Boss;
        public bool Overworld => !InLevel && (Portal || Submap);

        public bool RoomShiftInLevel(ushort level, ushort fromRoom, ushort toRoom) {
            return Shift(roomNum, fromRoom, toRoom) && Curr(levelNum) == level;
        }

        public bool RoomShiftsInLevel(ushort level) {
            return Shifted(roomNum) && Curr(roomCounter) > 0 && Curr(levelNum) == level;
        }

        public bool ShiftIn(MemoryWatcher<byte> inW, byte inVal, MemoryWatcher<byte> shiftW, byte from, byte to) {
            return Shift(shiftW, from, to) && Curr(inW) == inVal;
        }

        public bool ShiftsIn(MemoryWatcher<byte> inW, byte inVal, MemoryWatcher<byte> shiftW) {
            return Shifted(shiftW) && Curr(inW) == inVal;
        }

        public void UpdateState() {
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
            // Yoshi Coin Maximum watching
            var levNum = Curr(levelNum);
            if (Stepped(yoshiCoin) && levNum != 0) {
                if (!yoshiCoinsPerLevel.ContainsKey(levNum))
                    yoshiCoinsPerLevel.Add(levNum, 0);
                if (Curr(yoshiCoin) > yoshiCoinsPerLevel[levNum]) {
                    yoshiCoinsPerLevel[levNum] = Curr(yoshiCoin);
                    totalYoshiCoinsStepped = true;
                }
                totalYoshiCoins = yoshiCoinsPerLevel.Sum(x => x.Value);
            } else {
                totalYoshiCoinsStepped = false;
            }
            // Saving first roomNum when entering level to ignore the first cpEntrance
            if (Shifted(levelNum)) {
                firstRoom = Curr(roomNum);
            } else if (CP) {
                firstRoom = 0;
            }

            if (Spawn) died = false;
        }

        public ushort Prev(MemoryWatcher<byte> w) {
            return Convert.ToUInt16(w.Old);
        }

        public ushort Prev(MemoryWatcher<ushort> w) {
            return Convert.ToUInt16(w.Old);
        }

        public uint Prev(MemoryWatcher<uint> w) {
            return Convert.ToUInt32(w.Old);
        }

        public ushort Curr(MemoryWatcher<byte> w) {
            return Convert.ToUInt16(w.Current);
        }

        public ushort Curr(MemoryWatcher<ushort> w) {
            return Convert.ToUInt16(w.Current);
        }

        public uint Curr(MemoryWatcher<uint> w) {
            return Convert.ToUInt32(w.Current);
        }

        public bool Shift(MemoryWatcher<byte> w, ushort o, ushort c) {
            return Prev(w) == o && Curr(w) == c;
        }
        public bool Shift(MemoryWatcher<ushort> w, ushort o, ushort c) {
            return Prev(w) == o && Curr(w) == c;
        }
        public bool Shift(MemoryWatcher<uint> w, ushort o, ushort c) {
            return Prev(w) == o && Curr(w) == c;
        }

        public bool ShiftTo(MemoryWatcher<byte> w, ushort c) {
            return Prev(w) != c && Curr(w) == c;
        }
        public bool ShiftTo(MemoryWatcher<ushort> w, ushort c) {
            return Prev(w) != c && Curr(w) == c;
        }
        public bool ShiftTo(MemoryWatcher<uint> w, ushort c) {
            return Prev(w) != c && Curr(w) == c;
        }

        public bool ShiftFrom(MemoryWatcher<byte> w, ushort o) {
            return Prev(w) == o && Curr(w) != o;
        }
        public bool ShiftFrom(MemoryWatcher<ushort> w, ushort o) {
            return Prev(w) == o && Curr(w) != o;
        }
        public bool ShiftFrom(MemoryWatcher<uint> w, ushort o) {
            return Prev(w) == o && Curr(w) != o;
        }

        public bool Shifted(MemoryWatcher<byte> w) {
            return Prev(w) != Curr(w);
        }
        public bool Shifted(MemoryWatcher<ushort> w) {
            return Prev(w) != Curr(w);
        }
        public bool Shifted(MemoryWatcher<uint> w) {
            return Prev(w) != Curr(w);
        }

        public bool StepTo(MemoryWatcher<byte> w, ushort c) {
            return Curr(w) == c && Prev(w) + 1 == Curr(w);
        }
        public bool StepTo(MemoryWatcher<ushort> w, ushort c) {
            return Curr(w) == c && Prev(w) + 1 == Curr(w);
        }
        public bool StepTo(MemoryWatcher<uint> w, ushort c) {
            return Curr(w) == c && Prev(w) + 1 == Curr(w);
        }

        public bool Stepped(MemoryWatcher<byte> w) {
            return Prev(w) + 1 == Curr(w);
        }
        public bool Stepped(MemoryWatcher<ushort> w) {
            return Prev(w) + 1 == Curr(w);
        }
        public bool Stepped(MemoryWatcher<uint> w) {
            return Prev(w) + 1 == Curr(w);
        }

        public bool Crossed(MemoryWatcher<byte> w, ushort c) {
            return Prev(w) < c && Curr(w) >= c;
        }
        public bool Crossed(MemoryWatcher<ushort> w, ushort c) {
            return Prev(w) < c && Curr(w) >= c;
        }
        public bool Crossed(MemoryWatcher<uint> w, ushort c) {
            return Prev(w) < c && Curr(w) >= c;
        }
    }
}
