using System.Collections.Generic;

namespace SMW {
    public class Settings {
        public bool playersSelect;
        public bool livesSet;
        public bool playersUnselect;
        public bool livesUnset;
        public bool exits;
        public bool introExit;
        public bool worlds;
        public bool midways;
        public bool cpEntrances;
        public bool starts;
        public bool goals;
        public bool orbs;
        public bool keys;
        public bool bosses;
        public bool palaces;
        public bool rooms;
        public bool recording;
        public bool autoskipOnLag;
        public bool other;
        public bool credits;

        public long maxLag;
        public long minStartDuration;

        private bool prevFinished = false;
        private Watchers w;

        public Settings() { }

        public void Init(long maxLag, long minStartDuration) {
            this.maxLag = maxLag;
            this.minStartDuration = minStartDuration;
        }

        public void Update(Dictionary<string, bool> settings, Watchers ws) {
            playersSelect = settings["playersSelect"];
            livesSet = settings["livesSet"];
            playersUnselect = settings["playersUnselect"];
            livesUnset = settings["livesUnset"];
            exits = settings["exits"];
            introExit = settings["introExit"];
            worlds = settings["worlds"];
            midways = settings["midways"];
            cpEntrances = settings["cpEntrances"];
            starts = settings["starts"];
            goals = settings["goals"];
            orbs = settings["orbs"];
            keys = settings["keys"];
            bosses = settings["bosses"];
            palaces = settings["palaces"];
            rooms = settings["rooms"];
            recording = settings["recording"];
            autoskipOnLag = settings["autoskipOnLag"];
            w = ws;
        }

        public bool SplitStatus() {
            return !recording && (
                (exits && w.LevelExit) ||
                (introExit && w.Intro) ||
                (worlds && w.Overworld) ||
                (midways && w.Midway) ||
                (cpEntrances && w.CPEntrance) ||
                (starts && w.LevelStart) ||
                (goals && w.Goal) ||
                (orbs && w.Orb) ||
                (keys && w.Key) ||
                (palaces && w.Palace) ||
                (bosses && w.Boss) ||
                (rooms && w.Room) ||
                other ||
                credits
                );
        }

        public string SplitReasons() {
            List<string> reasons = new List<string>();
            if (w.Intro) reasons.Add("Intro");
            if (w.LevelExit) reasons.Add("Exit");
            if (w.LevelStart) reasons.Add("Start");
            if (w.Midway) reasons.Add("Midway");
            if (w.CPEntrance) reasons.Add("CPEntrance");
            if (w.Submap) reasons.Add("Submap");
            if (w.Portal) reasons.Add("Portal");
            if (w.Goal) reasons.Add("Goal");
            if (w.Orb) reasons.Add("Orb");
            if (w.Key) reasons.Add("Key");
            if (w.Boss) reasons.Add("Boss");
            if (w.Palace) reasons.Add("Palace");
            if (w.Room) reasons.Add("Room");
            if (other) reasons.Add("Other");
            if (credits) reasons.Add("Credits");
            return string.Join(" ", reasons);
        }

        public bool StartStatus(long sinceMemFound) {
            return sinceMemFound > minStartDuration && (
                (playersSelect && w.ToFileSelect) ||
                (livesSet && w.FromOneLuigiLife)
                );
        }

        public string StartReasons() {
            List<string> reasons = new List<string>();
            if (w.ToFileSelect) reasons.Add("FileSelect");
            if (w.FromOneLuigiLife) reasons.Add("OneLife");
            return string.Join(" ", reasons);
        }

        public bool ResetStatus(bool memOffsetKnown) {
            return !memOffsetKnown || 
                (playersUnselect && w.FromFileSelect) ||
                (livesUnset && w.ToOneLuigiLife)
                ;
        }

        public string ResetReasons(bool memOffsetKnown) {
            List<string> reasons = new List<string>();
            if (!memOffsetKnown) reasons.Add("LostMemoryOffset");
            if (w.FromFileSelect) reasons.Add("FileUnselected");
            if (w.ToOneLuigiLife) reasons.Add("OneLife");
            return string.Join(" ", reasons);
        }

        public bool UndoStatus() {
            // TODO: Does it make sense to check key or palace?
            if ((goals && w.Goal) ||
                (orbs && w.Orb) ||
                (keys && w.Key) ||
                (bosses && w.Boss) ||
                (palaces && w.Palace)
            ) {
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


        public bool SkipStatus(long lag) {
            return autoskipOnLag && lag > maxLag && !credits;
        }

        public string SkipReasons(long lag) {
            List<string> reasons = new List<string>();
            if (lag > maxLag) reasons.Add("LAG "+lag);
            return string.Join(" ", reasons);
        }
    }
}
