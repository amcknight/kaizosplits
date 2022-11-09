using LiveSplit.Model;

namespace SMW {
    class Action {
        public static void Skip(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.SkipSplit();
        }

        public static void Undo(LiveSplitState timer) {
            new TimerModel { CurrentState = timer }.UndoSplit();
        }
    }
}
