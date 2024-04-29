using LiveSplit.ComponentUtil;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Tracker {

        private List<string> debugInfo = new List<string>();
        private Dictionary<object, string> prevMsg = new Dictionary<object, string>();

        public Tracker() { }

        public void Update(Watchers ws) {
            foreach (MemoryWatcher<byte> w in ws.xs) {
                Monitor(w, ws);
            }
        }

        public bool HasLines() {
            return debugInfo.Count > 0;
        }

        public string ClearLines() {
            string lines = string.Join("\n", debugInfo);
            debugInfo = new List<string>();
            return lines;
        }

        public void Dbg(string msg) {
            debugInfo.Add(msg);
        }

        public bool DbgOnce(string msg, object tag) {
            if (!prevMsg.ContainsKey(tag)) {
                prevMsg[tag] = null;
            }
            bool changed = msg != prevMsg[tag];
            if (changed) {
                debugInfo.Add(msg);
                prevMsg[tag] = msg;
            }
            return changed;
        }

        public void Monitor(MemoryWatcher<byte> w, Watchers ws) {
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }

        public void Monitor(MemoryWatcher<ushort> w, Watchers ws) {
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }

        public void Monitor(MemoryWatcher<uint> w, Watchers ws) {
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }
    }
}
