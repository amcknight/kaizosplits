using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Debugger {

        private List<string> debugInfo = new List<string>();
        private Dictionary<object, string> prevMsg = new Dictionary<object, string>();

        private bool showDebug = true;

        public Debugger() {}

        public void Update(Watchers ws) {
            if (showDebug)
                foreach (MemoryWatcher w in ws.xs)
                    Monitor(w, ws);
        }

        public bool HasLines() {
            return debugInfo.Count > 0;
        }

        public string ClearLines() {
            string lines = string.Join("\n", debugInfo);
            debugInfo.Clear();
            return lines;
        }

        // New process connection = new conversation: forget per-tag dedup state
        // so the first status line of a session is never eaten by the last one.
        public void ClearOnce() {
            prevMsg.Clear();
        }

        public void Dbg(string msg) {
            if (!showDebug) return;
            debugInfo.Add(msg);
        }

        public bool DbgOnce(Exception ex) {
            if (!showDebug) return false;
            return DbgOnce(ex.Message, ex.GetType());
        }

        public bool DbgOnce(string msg, object tag) {
            if (!showDebug) return false;
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

        public void Monitor(MemoryWatcher w, Watchers ws) {
            if (!showDebug) return;
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }
    }
}
