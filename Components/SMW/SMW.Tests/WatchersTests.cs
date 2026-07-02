using System;
using LiveSplit.ComponentUtil;
using Xunit;

namespace SMW.Tests {
    public class WatchersTests {

        private static MemoryWatcher<byte> Byte(byte old, byte curr) {
            var w = new MemoryWatcher<byte>(IntPtr.Zero);
            w.Current = curr;
            w.Old = old;
            return w;
        }

        private static MemoryWatcher<ushort> UShort(ushort old, ushort curr) {
            var w = new MemoryWatcher<ushort>(IntPtr.Zero);
            w.Current = curr;
            w.Old = old;
            return w;
        }

        private static MemoryWatcher<uint> UInt(uint old, uint curr) {
            var w = new MemoryWatcher<uint>(IntPtr.Zero);
            w.Current = curr;
            w.Old = old;
            return w;
        }

        private readonly Watchers ws = new Watchers();

        // --- Curr / Prev round-trips ---

        [Fact]
        public void Curr_Byte_ReturnsCurrentAsUint() {
            Assert.Equal(7u, ws.Curr(Byte(3, 7)));
        }

        [Fact]
        public void Prev_Byte_ReturnsOldAsUint() {
            Assert.Equal(3u, ws.Prev(Byte(3, 7)));
        }

        [Fact]
        public void Curr_UShort_ReturnsCurrent() {
            Assert.Equal(1000u, ws.Curr(UShort(50, 1000)));
        }

        [Fact]
        public void Curr_UInt_ReturnsCurrent() {
            Assert.Equal(0xABCDEFu, ws.Curr(UInt(0, 0xABCDEF)));
        }

        // --- Shift(w, o, c) ---

        [Fact]
        public void Shift_TrueOnExactOldToCurr() {
            Assert.True(ws.Shift(Byte(3, 5), 3, 5));
        }

        [Fact]
        public void Shift_FalseWhenOldDiffers() {
            Assert.False(ws.Shift(Byte(2, 5), 3, 5));
        }

        [Fact]
        public void Shift_FalseWhenCurrDiffers() {
            Assert.False(ws.Shift(Byte(3, 6), 3, 5));
        }

        [Fact]
        public void Shift_FalseOnNoChange() {
            // Old==Curr==5 doesn't satisfy a 3->5 transition
            Assert.False(ws.Shift(Byte(5, 5), 3, 5));
        }

        // --- ShiftTo(w, c) ---

        [Fact]
        public void ShiftTo_TrueOnAnyTransitionInto() {
            Assert.True(ws.ShiftTo(Byte(0, 4), 4));
            Assert.True(ws.ShiftTo(Byte(255, 4), 4));
        }

        [Fact]
        public void ShiftTo_FalseWhenAlreadyAtTarget() {
            Assert.False(ws.ShiftTo(Byte(4, 4), 4));
        }

        [Fact]
        public void ShiftTo_FalseWhenLeavingNotEntering() {
            Assert.False(ws.ShiftTo(Byte(4, 0), 4));
        }

        // --- ShiftFrom(w, o) ---

        [Fact]
        public void ShiftFrom_TrueOnAnyTransitionOutOf() {
            Assert.True(ws.ShiftFrom(Byte(0, 1), 0));
        }

        [Fact]
        public void ShiftFrom_FalseWhenStaying() {
            Assert.False(ws.ShiftFrom(Byte(0, 0), 0));
        }

        [Fact]
        public void ShiftFrom_FalseWhenEntering() {
            Assert.False(ws.ShiftFrom(Byte(1, 0), 0));
        }

        // --- Shifted(w) ---

        [Fact]
        public void Shifted_TrueWhenChanged() {
            Assert.True(ws.Shifted(Byte(1, 2)));
        }

        [Fact]
        public void Shifted_FalseWhenSame() {
            Assert.False(ws.Shifted(Byte(2, 2)));
            Assert.False(ws.Shifted(UShort(0, 0)));
            Assert.False(ws.Shifted(UInt(99, 99)));
        }

        // --- StepTo(w, c) ---

        [Fact]
        public void StepTo_TrueOnIncrementToTarget() {
            Assert.True(ws.StepTo(Byte(4, 5), 5));
        }

        [Fact]
        public void StepTo_FalseOnJumpToTarget() {
            Assert.False(ws.StepTo(Byte(0, 5), 5));
        }

        [Fact]
        public void StepTo_FalseOnDecrementToTarget() {
            Assert.False(ws.StepTo(Byte(6, 5), 5));
        }

        [Fact]
        public void StepTo_FalseWhenLandsOnWrongValue() {
            Assert.False(ws.StepTo(Byte(4, 5), 6));
        }

        // --- Stepped(w) ---

        [Fact]
        public void Stepped_TrueOnPlusOne() {
            Assert.True(ws.Stepped(Byte(9, 10)));
        }

        [Fact]
        public void Stepped_FalseOnSame() {
            Assert.False(ws.Stepped(Byte(5, 5)));
        }

        [Fact]
        public void Stepped_FalseOnDecrement() {
            Assert.False(ws.Stepped(Byte(5, 4)));
        }

        [Fact]
        public void Stepped_FalseOnJump() {
            Assert.False(ws.Stepped(Byte(5, 7)));
        }

        // --- Crossed(w, c) ---

        [Fact]
        public void Crossed_TrueWhenPrevBelowAndCurrAtOrAbove() {
            Assert.True(ws.Crossed(Byte(2, 5), 5));
            Assert.True(ws.Crossed(Byte(2, 6), 5));
        }

        [Fact]
        public void Crossed_FalseWhenPrevAlreadyAtOrAbove() {
            Assert.False(ws.Crossed(Byte(5, 6), 5));
        }

        [Fact]
        public void Crossed_FalseWhenCurrBelow() {
            Assert.False(ws.Crossed(Byte(2, 4), 5));
        }

        // --- ShiftIn / ShiftToIn / ShiftFromIn / ShiftsIn ---

        [Fact]
        public void ShiftIn_RequiresBothInValueAndShift() {
            var io = Byte(0, 3);          // inW: current==3
            var anim = Byte(0, 9);        // shiftW: transitions 0->9

            Assert.True(ws.ShiftIn(io, 3, anim, 0, 9));
            Assert.False(ws.ShiftIn(io, 4, anim, 0, 9));         // wrong inVal
            Assert.False(ws.ShiftIn(io, 3, anim, 1, 9));         // wrong from
            Assert.False(ws.ShiftIn(io, 3, anim, 0, 10));        // wrong to
        }

        [Fact]
        public void ShiftToIn_GuardsOnInValue() {
            var io = Byte(0, 3);
            var anim = Byte(0, 9);

            Assert.True(ws.ShiftToIn(io, 3, anim, 9));
            Assert.False(ws.ShiftToIn(io, 4, anim, 9));
        }

        [Fact]
        public void ShiftFromIn_GuardsOnInValue() {
            var io = Byte(0, 3);
            var anim = Byte(9, 0);  // transitions from 9

            Assert.True(ws.ShiftFromIn(io, 3, anim, 9));
            Assert.False(ws.ShiftFromIn(io, 4, anim, 9));
        }

        [Fact]
        public void ShiftsIn_RequiresAnyChangeAndInValue() {
            var io = Byte(0, 3);
            var anim = Byte(0, 9);
            var quiet = Byte(5, 5);

            Assert.True(ws.ShiftsIn(io, 3, anim));
            Assert.False(ws.ShiftsIn(io, 3, quiet));
            Assert.False(ws.ShiftsIn(io, 4, anim));
        }
    }
}
