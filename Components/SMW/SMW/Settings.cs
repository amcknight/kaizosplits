using System.Collections.Generic;

namespace SMW {
    public class Settings {
        public bool recording;
        public bool autoskipOnLag;
        public bool worlds;
        public bool levelExits;
        public bool introExits;
        public bool levelStarts;
        public bool levelFinishes;
        public bool firstTapes;
        public bool cpEntrances;
        public bool rooms;
        public bool other;
        public bool credits;
        private bool prevFinished = false;
        private Watchers w;

        public Settings() { }

        public void Update(Dictionary<string, bool> settings, Watchers ws) {
            recording = settings["recording"];
            autoskipOnLag = settings["autoskipOnLag"];
            worlds = settings["worlds"];
            levelExits = settings["levelExits"];
            introExits = settings["introExits"];
            levelStarts = settings["levelStarts"];
            levelFinishes = settings["levelFinishes"];
            firstTapes = settings["firstTapes"];
            cpEntrances = settings["cpEntrances"];
            rooms = settings["rooms"];
            w = ws;
        }

        public bool SplitStatus() {
            return !recording && (
                (worlds && w.Overworld) ||
                (levelExits && w.LevelExit) ||
                (introExits && w.Intro) ||
                (levelStarts && w.LevelStart) ||
                (levelFinishes && w.LevelFinish) ||
                (firstTapes && w.Tape) ||
                (cpEntrances && w.CPEntranceInLevel) ||
                (rooms && w.Room) ||
                other ||
                credits
                );
        }

        public bool UndoStatus() {
            if (levelFinishes && w.LevelFinish) {
                prevFinished = true;
            }
            if (w.LevelExit) {
                prevFinished = false;
            }
            if (w.DiedNow && prevFinished) {
                prevFinished = false;
                return true;
            }
            return false;
        }
    }
}
