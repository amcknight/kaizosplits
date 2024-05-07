using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Tracker {

        private List<string> debugInfo = new List<string>();
        private Dictionary<object, string> prevMsg = new Dictionary<object, string>();

        private bool showDebug = false;
        private bool showHist = true;
        private int numBuckets = 10;
        private int bucketSize = 10;
        private int[] histEnd;
        private int[] histMid;
        private long prevMs;
        private int ticks = 0;
        private int numTicksUntilShow = 500;

        public Tracker() {
            histEnd = new int[numBuckets];
            histMid = new int[numBuckets];
        }

        public void Update(Watchers ws) {
            if (showDebug) {
                foreach (MemoryWatcher<byte> w in ws.xs) {
                    Monitor(w, ws);
                }
            }
            if (showHist) {
                UpdateHist();
            }
        }

        public void HistNow() {
            if (ticks <= 1) return;

            long ms = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            int durMs = (int)(ms - prevMs);
            int hindex = durMs / bucketSize;
            if (hindex >= numBuckets) {
                hindex = numBuckets - 1;
            }

            histMid[hindex]++;
        }

        public bool HasLines() {
            return debugInfo.Count > 0;
        }

        public string ClearLines() {
            string lines = string.Join("\n", debugInfo);
            debugInfo.Clear();
            return lines;
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

        public void Monitor(MemoryWatcher<byte> w, Watchers ws) {
            if (!showDebug) return;
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }

        public void Monitor(MemoryWatcher<ushort> w, Watchers ws) {
            if (!showDebug) return;
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }

        public void Monitor(MemoryWatcher<uint> w, Watchers ws) {
            if (!showDebug) return;
            if (ws.Shifted(w)) {
                Dbg(w.Name + ": " + ws.Prev(w) + "->" + ws.Curr(w));
            }
        }

        private void UpdateHist() {
            long ms = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            int durMs = (int)(ms - prevMs);
            prevMs = ms;

            ticks++;
            if (ticks <= 1) return;

            int hindex = durMs / bucketSize;
            if (hindex >= numBuckets) {
                hindex = numBuckets - 1;
                Dbg("LAG: " + durMs);
            }

            histEnd[hindex]++;

            if (ticks % numTicksUntilShow == 0) {
                debugInfo.Add("MIDS: " + string.Join(" ", histMid));
                debugInfo.Add("ENDS: " + string.Join(" ", histEnd));
            }
        }
    }
}
