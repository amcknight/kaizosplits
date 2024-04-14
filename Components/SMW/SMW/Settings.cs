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

        public string SplitReasons() {
            List<string> reasons = new List<string>();
            if (w.Intro) reasons.Add("Intro");
            if (w.LevelExit) reasons.Add("Exit");
            if (w.LevelStart) reasons.Add("Start");
            if (w.Tape) reasons.Add("Tape");
            if (w.CPEntranceInLevel) reasons.Add("CPEntrance");
            if (w.Palace) reasons.Add("Palace");
            if (w.Submap) reasons.Add("Submap");
            if (w.Portal) reasons.Add("Portal");
            if (w.Boss) reasons.Add("Boss");
            if (w.Orb) reasons.Add("Orb");
            if (w.Key) reasons.Add("Key");
            if (w.Goal) reasons.Add("Goal");
            if (w.Room) reasons.Add("Room");
            if (other) reasons.Add("Other");
            if (credits) reasons.Add("Credits");
            return string.Join(" ", reasons);
        }
    }
}
