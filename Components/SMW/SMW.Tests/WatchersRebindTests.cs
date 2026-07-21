using System.Collections.Generic;
using Xunit;

namespace SMW.Tests {
    // SetMemoryOffset runs again whenever the emulator process changes.
    // The name indexer returns the first match, so old watchers must be
    // removed or they permanently hide the new ones.
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
