using LiveSplit.ComponentUtil;
using LiveSplit.Model;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class SMW {
        // TODO: These 3 probably don't need to be here
        public Dictionary<int, long> States => Locator.offsets;
        public Dictionary<int, string> ByteMemoryMap => Memory.byteMap;
        public Dictionary<int, string> ShortMemoryMap => Memory.shortMap;

        // Stateful Vars
        public bool died;
        public bool roomStep;
        public ushort prevIO;

        public State s;

        public SMW() {
            Init();
        }

        public void Reset() {
            Init();
        }

        public void Init() {
            s = new State();
            events = new List<Event>();
        }

        public void Skip(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.SkipSplit();
        }

        public void Undo(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.UndoSplit();
        }

        public List<string> debugInfo;

        public void Update(MemoryWatcherList watchers) {
            debugInfo = new List<string>();

            s.Update(watchers);

            Track(s.Spawn, "Spawn");
        }

        // Split Conditions
        public bool Intro => s.IntroExit;
        public bool LevelExit => s.ToExit;
        public bool Goal => s.ToFanfare && s.BossUndead && !s.GotOrb;
        public bool Key => s.ToKey;
        public bool Orb => s.ToOrb && s.BossUndead;
        public bool Palace => s.ToYellowSwitch || s.ToGreenSwitch || s.ToBlueSwitch || s.ToRedSwitch;
        public bool Boss => s.ToFanfare && !s.BossUndead;
        public bool LevelStart => s.ToLevelStart;
        public bool PeachRelease => s.ToPeachRelease;
        public bool Tape => s.ToCheckpointTape && !s.GotOrb && !s.GotGoal && !s.GotKey && !s.GotFadeout;
        public bool Room => s.roomStep;
        public bool CoinFlag => false;
        public bool Credits => false;
        public bool Submap => s.SubmapShift;
        public bool Portal => s.ToOverworldPortal;

        // Construct high level split conditions
        // TODO: Only split on these if in or out of the overworld
        public bool LevelFinish => Goal || Key || Orb || Palace || Boss;
        public bool Flag => CoinFlag;
        public bool RunDone => PeachRelease || Credits;
        public bool Overworld => s.ToOverworldPortal || s.SubmapShift;

        public void Dbg(string msg) {
            debugInfo.Add(msg);
        }

        public void Monitor(MemoryWatcher w) {
            if (s.mem.Prev(w) != s.mem.Curr(w)) {
                Dbg(w.Name + ": " + s.mem.Prev(w) + "->" + s.mem.Curr(w));
            }
        }

        public List<Event> events = new List<Event>();
        public void Track(bool condition, string name) {
            if (condition) {
                events.Add(s.BuildEvent(name));
            }
        }

        // TODO: Move all splitting functionality to a separate file
        public string SplitReasons() {
            string reasons = "";
            reasons += Intro ? " Intro" : "";
            reasons += LevelStart ? " Start" : "";
            reasons += Goal ? " Goal" : "";
            reasons += Key ? " Key" : "";
            reasons += Orb ? " Orb" : "";
            reasons += Palace ? " Palace" : "";
            reasons += Boss ? " Boss" : "";
            reasons += Tape ? " Tape" : "";
            reasons += Room ? " Room" : "";
            reasons += CoinFlag ? " CoinFlag" : "";
            reasons += PeachRelease ? " PeachRelease" : "";
            reasons += Credits ? " Credits" : "";
            reasons += Submap ? " Submap" : "";
            reasons += Portal ? " Portal" : "";
            return reasons;
        }

        public void WriteRun(string path, int num) {
            List<string> eventStrs = new List<string>();
            foreach (Event e in events) {
                eventStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/run" + num + ".txt", eventStrs);
            List<string> routeStrs = new List<string>();
            foreach (Event e in BuildRoute()) {
                routeStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/route" + num + ".txt", routeStrs);
        }

        private Event NumEvent(bool clinched, int num, Event e) {
            string name;
            if (clinched) {
                name = "-" + num + ") " + e.name;
            } else {
                name = "~" + num + ") " + e.name;
            }
            return new Event(name, e.place);
        }

        public List<Event> BuildRoute() {
            List<Event> route = new List<Event>();
            List<Event> candidates = new List<Event>();
            Event lastSpawn = null;
            int splitNum = 0;
            foreach (Event e in events) {
                switch (e.name) {
                case "Spawn":
                    if (!e.Equals(lastSpawn)) {
                        if (candidates.Count != 0) {
                            splitNum++;
                            foreach (Event c in candidates) {
                                route.Add(NumEvent(false, splitNum, c));
                            }
                        }
                    }
                    lastSpawn = e;
                    candidates = new List<Event>();
                    break;
                case "Intro":
                case "Event":
                case "Key":
                case "Start":
                case "Tape":
                    if (candidates.Count != 0) {
                        splitNum++;
                        foreach (Event c in candidates) {
                            route.Add(NumEvent(false, splitNum, c));
                        }
                    }
                    splitNum++;
                    route.Add(NumEvent(true, splitNum, e));
                    candidates = new List<Event>();
                    break;
                default:
                    candidates.Add(e);
                    break;
                }
            }
            return route;
        }
    }
}
