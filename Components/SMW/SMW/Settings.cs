using System;
using System.Collections.Generic;

namespace SMW {
    public class Settings {
        public bool playersSelect;
        public bool livesSet;
        public bool playersUnselect;
        public bool livesUnset;
        public bool gameChanged;
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
        public bool autoskipOnLag;

        public bool other = false;
        public bool credits = false;
        public bool block = false;

        public long maxLag;
        public long minStartDuration;

        private bool prevFinished = false;
        private Watchers w;

        private List<Setting> settings = new List<Setting> {
            new Setting("Start when", "Start splits when below conditions hold", kids : new List<Setting>{
                new Setting("Players Selected", "Start when the number of players is selected"),
                new Setting("Luigi >1 Life", "Start when Luigi's lives is set to more than 1. Good for one player speedruns when Players Selected is broken"),
            }),
            new Setting("Reset when", "Reset splits when below conditions hold", kids : new List<Setting>{
                new Setting("# Players not Selected", "Reset when the number of players is not selected and so probably back in the menu"),
                new Setting("Luigi 1 Life", "Reset when Luigi has one life. Good for one player speedruns when Players not Selected is broken"),
                new Setting("Changed Game", "Reset when changed game. Turn this off for multi-game runs"),
            }),
            new Setting("Split when", "Split when...", kids : new List<Setting>{
                new Setting("Level Exit", "leaving a level by beating it"),
                new Setting("Intro Exit", "at the end of the intro level"),
                new Setting("Overworld Change", "switching overworlds. Good to use with subsplits"),
                new Setting("Level Event", "these in-level events", kids : new List<Setting>{
                    new Setting("Checkpoint", "getting a Checkpoints", kids : new List<Setting> {
                        new Setting("Midway", "getting the first midway checkpoint tape in the level"),
                        new Setting("CP Entrance Change", "entrance to appear at on death changes, excluding when entering a level"),
                    }),
                    new Setting("Start", "Split at the start of each level"),
                    new Setting("Finish", "Goals, Orbs, Bosses, Keys, and Palaces", on : false, kids : new List<Setting> {
                        new Setting("Goal Tape", "getting the big goal tape"),
                        new Setting("Orb", "getting an orb"),
                        new Setting("Boss", "defeating a boss"),
                        new Setting("Keyhole", "activating a key hole"),
                        new Setting("Palace", "hitting a switch palace"),
                    }),
                    new Setting("Room Change", "your room transitions", on : false),
                }),
            }),
            new Setting("Autoskip Lag Splits", "Autoskip splits that might have had more than 100ms of lag"),
        };

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
            gameChanged = settings["gameChanged"];
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
            autoskipOnLag = settings["autoskipOnLag"];
            w = ws;
        }

        public bool SplitStatus() {
            return (!block && !w.gameOvered && (
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
                ));
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

        public bool ResetStatus(bool memOffsetKnown, bool isGameChanged) {
            return !memOffsetKnown ||
                (gameChanged && isGameChanged) ||
                (playersUnselect && w.FromFileSelect && !w.gameOvered) || // TODO: Maybe roll these gameOvered checks into Watchers to reduce logic here
                (livesUnset && w.ToOneLuigiLife && !w.gameOvered)
                ;
        }

        public string ResetReasons(bool memOffsetKnown, bool isGameChanged) {
            List<string> reasons = new List<string>();
            if (!memOffsetKnown) reasons.Add("LostMemoryOffset");
            if (isGameChanged) reasons.Add("GameChanged");
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
