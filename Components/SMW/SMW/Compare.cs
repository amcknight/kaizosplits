namespace SMW {
    // Pure value-comparison helpers used by the Watchers state-shift API.
    // Kept type-erased (ulong) so byte/ushort/uint watchers share one implementation.
    public static class Compare {
        public static bool Shift(ulong prev, ulong curr, ulong from, ulong to) {
            return prev == from && curr == to;
        }

        public static bool ShiftTo(ulong prev, ulong curr, ulong to) {
            return prev != to && curr == to;
        }

        public static bool ShiftFrom(ulong prev, ulong curr, ulong from) {
            return prev == from && curr != from;
        }

        public static bool Shifted(ulong prev, ulong curr) {
            return prev != curr;
        }

        public static bool StepTo(ulong prev, ulong curr, ulong to) {
            return curr == to && prev + 1 == curr;
        }

        public static bool Stepped(ulong prev, ulong curr) {
            return prev + 1 == curr;
        }

        public static bool Crossed(ulong prev, ulong curr, ulong threshold) {
            return prev < threshold && curr >= threshold;
        }
    }
}
