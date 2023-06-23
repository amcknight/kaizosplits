using System.Collections.Generic;

namespace SMW {
    public class Settings {
        public bool recording;
        public bool autoskipOnLag;
        public bool worlds;
        public bool uworlds;
        public bool levelExits;
        public bool ulevelExits;
        public bool introExits;
        public bool levelStarts;
        public bool ulevelStarts;
        public bool levelFinishes;
        public bool ulevelFinishes;
        public bool firstTapes;
        public bool rooms;
        public bool urooms;
        public bool other;
        public bool credits;
        private bool prevFinished = false;
        private Watchers w;

        public Settings() { }

        public void Update(Dictionary<string, bool> settings, Watchers ws) {
            recording = settings["recording"];
            autoskipOnLag = settings["autoskipOnLag"];
            worlds = settings["worlds"];
            uworlds = settings["uworlds"];
            levelExits = settings["levelExits"];
            ulevelExits = settings["ulevelExits"];
            introExits = settings["introExits"];
            levelStarts = settings["levelStarts"];
            ulevelStarts = settings["ulevelStarts"];
            levelFinishes = settings["levelFinishes"];
            ulevelFinishes = settings["ulevelFinishes"];
            firstTapes = settings["firstTapes"];
            rooms = settings["rooms"];
            urooms = settings["urooms"];
            w = ws;
        }

        public bool SplitStatus() {
            return !recording && (
                (worlds && w.Overworld) ||
                (uworlds && w.Overworld) ||
                (levelExits && w.LevelExit) ||
                (ulevelExits && w.LevelExit) ||
                (introExits && w.Intro) ||
                (levelStarts && w.LevelStart) ||
                (ulevelStarts && w.LevelStart) ||
                (levelFinishes && w.LevelFinish) ||
                (ulevelFinishes && w.LevelFinish) ||
                (firstTapes && w.Tape) ||
                (rooms && w.Room) ||
                (urooms && w.Room) ||
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
