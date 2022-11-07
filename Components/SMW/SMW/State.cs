using LiveSplit.ComponentUtil;

namespace SMW {
    public class State {

        public readonly Memory mem;
        public bool died;
        public bool roomStep;
        public ushort prevIO;

        public State() {
            mem = new Memory();
            died = false;
            roomStep = false;
            prevIO = 256; // 256 is a junk default value
        }
        
        public bool ToOrb => ShiftTo(mem.io, 3);
        public bool ToGoal => ShiftTo(mem.io, 4);
        public bool ToKey => ShiftTo(mem.io, 7);
        public bool GotOrb => mem.Curr(mem.io) == 3;
        public bool GotGoal => mem.Curr(mem.io) == 4;
        public bool GotKey => mem.Curr(mem.io) == 7;
        public bool GotFadeout => mem.Curr(mem.io) == 8;
        public bool BossUndead => mem.Curr(mem.bossDefeat) == 0;
        public bool GmFadeToLevel => ShiftTo(mem.gameMode, 15);
        public bool GmFadeToLevelBlack => ShiftTo(mem.gameMode, 16);
        public bool GmLoadLevel => ShiftTo(mem.gameMode, 17);
        public bool GmPrepareLevel => ShiftTo(mem.gameMode, 18);
        public bool GmLevelFadeIn => ShiftTo(mem.gameMode, 19);
        public bool GmLevel => ShiftTo(mem.gameMode, 20);
        public bool DiedNow => ShiftTo(mem.playerAnimation, 9);
        public bool NewEvent => Stepped(mem.eventsTriggered);
        public bool ToExit => ShiftFrom(mem.exitMode, 0) && !ShiftTo(mem.exitMode, 128);
        public bool EnteredPipe => Shifted(mem.pipe) && mem.Curr(mem.pipe) < 4 && (mem.Curr(mem.playerAnimation) == 5 || mem.Curr(mem.playerAnimation) == 6);
        public bool Put => GmPrepareLevel && !died;
        public bool Spawn => GmPrepareLevel && died;
        public bool ToOverworldPortal => Shift(mem.overworldPortal, 1, 0);
        public bool SubmapShift => Shifted(mem.submap);
        public bool ToFanfare => StepTo(mem.fanfare, 1);
        public bool IntroExit => Shift(mem.weirdLevVal, 233, 0);
        public bool ToYellowSwitch => StepTo(mem.yellowSwitch, 1);
        public bool ToGreenSwitch => StepTo(mem.greenSwitch, 1);
        public bool ToBlueSwitch => StepTo(mem.blueSwitch, 1);
        public bool ToRedSwitch => StepTo(mem.redSwitch, 1);
        public bool ToLevelStart => StepTo(mem.levelStart, 1);
        public bool ToPeachRelease => StepTo(mem.peach, 1);
        public bool ToCheckpointTape => StepTo(mem.checkpointTape, 1);

        public void Update(MemoryWatcherList watchers) {
            mem.Update(watchers);
            
            // Only roomStep if didn't just die. Assumes every death sets the roomCount to 1.
            died = died || DiedNow;
            roomStep = false;
            if (Stepped(mem.roomCounter)) {
                roomStep = mem.Curr(mem.roomCounter) != 1 || !died;
            }
            // PrevIO is basically Current IO except when a P-Switch or Star shifts the io to 0
            if (mem.Curr(mem.io) != 0) {
                prevIO = mem.Curr(mem.io);
            }

            if (Spawn) died = false;
        }

        public bool Shift(MemoryWatcher w, ushort o, ushort c) {
            return mem.Prev(w) == o && mem.Curr(w) == c;
        }

        public bool ShiftTo(MemoryWatcher w, ushort c) {
            return mem.Prev(w) != c && mem.Curr(w) == c;
        }

        public bool ShiftFrom(MemoryWatcher w, ushort o) {
            return mem.Prev(w) == o && mem.Curr(w) != o;
        }

        public bool Shifted(MemoryWatcher w) {
            return mem.Prev(w) != mem.Curr(w);
        }

        public bool StepTo(MemoryWatcher w, ushort c) {
            return mem.Curr(w) == c && mem.Prev(w) + 1 == mem.Curr(w);
        }

        public bool Stepped(MemoryWatcher w) {
            return mem.Prev(w) + 1 == mem.Curr(w);
        }

        public Event BuildEvent(string name) {
            return new Event(name, new Place(mem.Curr(mem.submap), mem.Curr(mem.levelNum), mem.Curr(mem.roomNum), mem.Curr(mem.playerX), mem.Curr(mem.playerY)));
        }
    }
}
