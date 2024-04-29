using System.Collections.Generic;

namespace SMW {
    internal interface ISetting {}

    internal class Setting : ISetting {
        public string key;
        public string name;
        public string tooltip;
        public bool on;

        public Setting(string key, string name, string tooltip = null, bool on = true) {
            this.key = key;
            this.name = name;
            this.tooltip = tooltip;
            this.on = on;
        }
    }

    internal class Group : ISetting {
        public string name;
        public string tooltip;
        public bool on;
        public List<ISetting> kids;

        public Group(string name, string tooltip = null, bool on = true, List<ISetting> kids = null) {
            this.name = name;
            this.tooltip = tooltip;
            this.on = on;
            this.kids = kids;
        }
    }
}