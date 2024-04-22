using LiveSplit.ComponentUtil;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Recorder {
        
        public List<Event> events = new List<Event>();
        private bool recording;

        public Recorder() {
            Init();
        }

        public void Reset() {
            Init();
        }

        public void Init() {
            events = new List<Event>();
        }

        public void Update(bool r, Watchers ws) {
            recording = r;
            Track(ws.Spawn, "Spawn", ws);
        }

        public void Track(bool condition, string name, Watchers ws) {
            if (recording && condition) {
                events.Add(BuildEvent(name, ws));
            }
        }

        public Event BuildEvent(string name, Watchers ws) {
            return new Event(name, new Place(ws.Curr(ws.submap), ws.Curr(ws.levelNum), ws.Curr(ws.roomNum), ws.Curr(ws.playerX), ws.Curr(ws.playerY)));
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
