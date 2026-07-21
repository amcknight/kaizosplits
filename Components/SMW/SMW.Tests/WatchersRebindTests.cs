using System.Collections.Generic;
using Xunit;

namespace SMW.Tests {
    // Reconnect path: SetMemoryOffset runs once per discovery, and a process
    // reconnect discovers again with a new offset. The list must hold exactly
    // one generation — MemoryWatcherList's string indexer returns the FIRST
    // name match, so a retained stale generation permanently shadows the
    // rebound watchers (silent dead watchers, dead Start; seen live 2026-07-20).
    public class WatchersRebindTests {

        [Fact]
        public void SetMemoryOffset_Twice_KeepsSingleGeneration() {
            var ws = new Watchers();
            ws.Init(new[] { "levelNum", "io" });
            var ranges = new Dictionary<int, int> { { 0x10, 0x14 } };

            ws.SetMemoryOffset(0x1000, ranges);
            int count = ws.Count;
            int xsCount = ws.xs.Count;
            var firstGen = ws.levelNum;

            ws.SetMemoryOffset(0x2000, ranges);

            Assert.Equal(count, ws.Count);
            Assert.Equal(xsCount, ws.xs.Count);
            Assert.NotSame(firstGen, ws.levelNum);
        }
    }
}
