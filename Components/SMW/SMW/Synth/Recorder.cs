using LiveSplit.ComponentUtil;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Recorder {
        
        public List<Event> events = new List<Event>();
        private string path;
        private int runNum = 1;

        public Recorder() {}

        public void Reset() {
            events = new List<Event>();
            runNum++;
        }

        public void Init(string path) {
            this.path = path;
        }

        public void Update(Watchers ws) {
            Track(ws.Spawn, "Spawn", ws);
        }

        public void Track(bool condition, string name, Watchers ws) {
            if (condition) {
                events.Add(BuildEvent(name, ws));
            }
        }

        public void StartReasons(string reason) { }
        public void ResetReasons(string reason) { }
        public void SplitReasons(string reason) { }
        public void UndoReasons(string reason) { }

        public Event BuildEvent(string name, Watchers ws) {
            return new Event(name, new Place(ws.Curr(ws.submap), ws.Curr(ws.levelNum), ws.Curr(ws.roomNum), ws.Curr(ws.playerX), ws.Curr(ws.playerY)));
        }

        public void WriteRun() {
            List<string> eventStrs = new List<string>();
            foreach (Event e in events) {
                eventStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/run-" + runNum + ".txt", eventStrs);
            List<string> routeStrs = new List<string>();
            foreach (Event e in BuildRoute()) {
                routeStrs.Add(e.ToString());
            }
            File.WriteAllLines(path + "/route-" + runNum + ".txt", routeStrs);

            Reset();
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
                case "Midway":
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
