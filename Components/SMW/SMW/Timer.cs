using LiveSplit.ComponentUtil;
using System;
using System.Collections.Generic;
using System.IO;

namespace SMW {
    public class Timer {
        private int numBuckets = 20;
        private int bucketSize = 10;
        private int[] histEnd;
        private int[] histMid;
        private long prevMs;
        private bool hasUpdated = false;

        public Timer() {
            histEnd = new int[numBuckets];
            histMid = new int[numBuckets];
        }

        public void HistNow() {
            if (!hasUpdated) return;

            long ms = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            int durMs = (int)(ms - prevMs);
            int hindex = durMs / bucketSize;
            if (hindex >= numBuckets) {
                hindex = numBuckets - 1;
            }

            histMid[hindex]++;
        }

        public void Update() {
            long ms = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            int durMs = (int)(ms - prevMs);
            prevMs = ms;

            if (!hasUpdated) {
                hasUpdated = true;
                return;
            }

            int hindex = durMs / bucketSize;
            if (hindex >= numBuckets) {
                hindex = numBuckets - 1;
            }

            histEnd[hindex]++;
        }

        public override string ToString() {
            return string.Join("\n",
                "MIDS: " + string.Join(" ", histMid),
                "ENDS: " + string.Join(" ", histEnd)
                );
        }
    }
}
