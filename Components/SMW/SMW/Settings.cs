using System.Collections.Generic;
using System.Text;

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
        public bool keyholes;
        public bool bosses;
        public bool palaces;
        public bool rooms;
        public bool skipOnLag;

        public bool other = false;
        public bool credits = false;
        public bool block = false;

        public long maxLag;
        public long minStartDuration;

        private bool prevFinished = false;
        private Watchers w;
        private int newKey = 0;

        private List<ISetting> settings = new List<ISetting>{
            new Group("Start when", "Start splits when...", kids: new List<ISetting>{
                new Setting("playersSelect", "Players Selected", "Start when the number of players is selected"),
                new Setting("livesSet", "Luigi >1 Life", "Start when Luigi's lives is set to more than 1. Good for one player speedruns when Players Selected is broken"),
            }),
            new Group("Reset when", "Reset splits when...", kids: new List<ISetting>{
                new Setting("playersUnselect", "# Players not Selected", "Reset when the number of players is not selected and so probably back in the menu"),
                new Setting("livesUnset", "Luigi 1 Life", "Reset when Luigi has one life. Good for one player speedruns when Players not Selected is broken"),
                new Setting("gameChanged", "Game Change", "Reset when changed game. Turn this off for multi-game runs"),
            }),
            new Group("Split when", "Split when...", kids: new List<ISetting>{
                new Setting("exits", "Level Exit", "leaving a level by beating it"),
                new Setting("introExit", "Intro Exit", "at the end of the intro level"),
                new Setting("worlds", "Overworld Change", "switching overworlds. Good to use with subsplits", on: false),
                new Group("Checkpoint", "getting a Checkpoints", kids: new List<ISetting> {
                    new Setting("midways", "Midway", "getting the first midway checkpoint tape in the level"),
                    new Setting("cpEntrances", "CP Entrance Change", "entrance to appear at on death changes, excluding when entering a level"),
                }),
                new Setting("starts", "Start", "Split at the start of each level", on: false),
                new Group("Finish", "Goals, Orbs, Bosses, Keys, and Palaces", on: false, kids: new List<ISetting> {
                    new Setting("goals", "Goal Tape", "getting the big goal tape"),
                    new Setting("orbs", "Orb", "getting an orb"),
                    new Setting("bosses", "Boss", "defeating a boss"),
                    new Setting("keyholes", "Key", "activating a key hole with a key"),
                    new Setting("palaces", "Palace", "hitting a switch palace"),
                }),
                new Setting("rooms", "Room Change", "your room transitions", on: false),
            }),
            new Setting("skipOnLag", "Autoskip Lag Splits", "Autoskip splits that might have had more than 100ms of lag"),
        };

        public List<string> keys = new List<string> {};
        public Dictionary<string, (bool, string, string, string)> entries = new Dictionary<string, (bool, string, string, string)>();

        public Settings() { }

        public void Init(long maxLag, long minStartDuration) {
            this.maxLag = maxLag;
            this.minStartDuration = minStartDuration;
            BuildEntries(settings);
        }

        private void BuildEntries(List<ISetting> ss, string parent = null) {
            foreach (var i in ss) {
                switch (i) {
                    case Group g:
                        var k = NewKey();
                        entries.Add(k, (g.on, g.name, g.tooltip, parent));
                        BuildEntries(g.kids, k);
                        break;
                    case Setting s:
                        entries.Add(s.key, (s.on, s.name, s.tooltip, parent));
                        keys.Add(s.key);
                        break;
                }
            }
        }


        public string[] UsedMemory() {
            return new string[] {
                "fileSelect", "luigiLives", "submap", "fanfare", "bossDefeat", "io", "yellowSwitch", "greenSwitch", "blueSwitch", "redSwitch",
                "roomCounter", "midway", "cpEntrance", "pipe", "playerAnimation", "levelStart", "weirdLevVal", "overworldPortal",
                "levelNum", "roomNum", "exitMode", "gameMode", "overworldTile"
            };
        }

        private string NewKey() {
            return "K" + newKey++;
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
            keyholes = settings["keyholes"];
            bosses = settings["bosses"];
            palaces = settings["palaces"];
            rooms = settings["rooms"];
            skipOnLag = settings["skipOnLag"];
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
                (keyholes && w.Key) ||
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
                (playersUnselect && w.FromFileSelect && !w.gameOvered) ||
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
            if ((goals && w.Goal) ||
                (orbs && w.Orb) ||
                (keyholes && w.Key) ||
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
            return skipOnLag && lag > maxLag && !credits;
        }

        public string SkipReasons(long lag) {
            List<string> reasons = new List<string>();
            if (lag > maxLag) reasons.Add("LAG "+lag);
            return string.Join(" ", reasons);
        }
    }
}
