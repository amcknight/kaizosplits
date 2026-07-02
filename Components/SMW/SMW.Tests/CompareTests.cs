using SMW;
using Xunit;

namespace SMW.Tests {
    public class CompareTests {

        // --- Shift(prev, curr, from, to) ---

        [Fact]
        public void Shift_TrueOnExactTransition() {
            Assert.True(Compare.Shift(3, 5, 3, 5));
        }

        [Fact]
        public void Shift_FalseWhenPrevDiffers() {
            Assert.False(Compare.Shift(2, 5, 3, 5));
        }

        [Fact]
        public void Shift_FalseWhenCurrDiffers() {
            Assert.False(Compare.Shift(3, 6, 3, 5));
        }

        [Fact]
        public void Shift_AcceptsZeroToZeroOnlyIfBothMatch() {
            Assert.True(Compare.Shift(0, 0, 0, 0));
            Assert.False(Compare.Shift(0, 0, 0, 1));
        }

        // --- ShiftTo(prev, curr, to) ---

        [Fact]
        public void ShiftTo_FalseWhenAlreadyAtTarget() {
            Assert.False(Compare.ShiftTo(4, 4, 4));
        }

        [Fact]
        public void ShiftTo_TrueOnArrivalFromAnyOtherValue() {
            Assert.True(Compare.ShiftTo(0, 4, 4));
            Assert.True(Compare.ShiftTo(99, 4, 4));
            Assert.True(Compare.ShiftTo(5, 4, 4));
        }

        // --- ShiftFrom(prev, curr, from) ---

        [Fact]
        public void ShiftFrom_TrueWhenLeavingValue() {
            Assert.True(Compare.ShiftFrom(0, 1, 0));
            Assert.True(Compare.ShiftFrom(0, 99, 0));
        }

        [Fact]
        public void ShiftFrom_FalseWhenStaying() {
            Assert.False(Compare.ShiftFrom(0, 0, 0));
        }

        [Fact]
        public void ShiftFrom_FalseWhenWasNotAtValue() {
            Assert.False(Compare.ShiftFrom(1, 2, 0));
        }

        // --- Shifted(prev, curr) ---

        [Fact]
        public void Shifted_TrueWhenChanged() {
            Assert.True(Compare.Shifted(1, 2));
            Assert.True(Compare.Shifted(0, 1));
        }

        [Fact]
        public void Shifted_FalseWhenSame() {
            Assert.False(Compare.Shifted(0, 0));
            Assert.False(Compare.Shifted(42, 42));
        }

        // --- StepTo(prev, curr, to) ---

        [Fact]
        public void StepTo_TrueOnPlusOneIntoTarget() {
            Assert.True(Compare.StepTo(0, 1, 1));
            Assert.True(Compare.StepTo(4, 5, 5));
        }

        [Fact]
        public void StepTo_FalseOnJump() {
            Assert.False(Compare.StepTo(0, 5, 5));
            Assert.False(Compare.StepTo(3, 5, 5));
        }

        [Fact]
        public void StepTo_FalseWhenLandsOnWrongValue() {
            Assert.False(Compare.StepTo(4, 5, 6));
        }

        // --- Stepped(prev, curr) ---

        [Fact]
        public void Stepped_TrueOnPlusOne() {
            Assert.True(Compare.Stepped(0, 1));
            Assert.True(Compare.Stepped(254, 255));
        }

        [Fact]
        public void Stepped_FalseOnSame() {
            Assert.False(Compare.Stepped(5, 5));
        }

        [Fact]
        public void Stepped_FalseOnDecrement() {
            Assert.False(Compare.Stepped(5, 4));
        }

        [Fact]
        public void Stepped_FalseOnJumpForward() {
            Assert.False(Compare.Stepped(5, 7));
        }

        [Fact]
        public void Stepped_FalseAtByteWrapAround() {
            // Behavior parity with original: prev=255, curr=0 should NOT step (no wrap).
            Assert.False(Compare.Stepped(255, 0));
        }

        [Fact]
        public void Stepped_FalseAtUshortWrapAround() {
            Assert.False(Compare.Stepped(65535, 0));
        }

        [Fact]
        public void Stepped_FalseAtUintWrapAround() {
            Assert.False(Compare.Stepped(uint.MaxValue, 0));
        }

        // --- Crossed(prev, curr, threshold) ---

        [Fact]
        public void Crossed_TrueWhenJustReachingThreshold() {
            Assert.True(Compare.Crossed(4, 5, 5));
        }

        [Fact]
        public void Crossed_TrueWhenJumpingPastThreshold() {
            Assert.True(Compare.Crossed(0, 100, 5));
        }

        [Fact]
        public void Crossed_FalseWhenAlreadyPastThreshold() {
            Assert.False(Compare.Crossed(5, 6, 5));
            Assert.False(Compare.Crossed(10, 20, 5));
        }

        [Fact]
        public void Crossed_FalseWhenStillBelow() {
            Assert.False(Compare.Crossed(0, 4, 5));
        }

        [Fact]
        public void Crossed_FalseWhenDescending() {
            Assert.False(Compare.Crossed(10, 3, 5));
        }

        [Fact]
        public void Crossed_ThresholdZeroIsAlwaysFalseFromZero() {
            // prev=0 < threshold=0 is false, so even arriving at 0 doesn't count
            Assert.False(Compare.Crossed(0, 0, 0));
        }
    }
}
