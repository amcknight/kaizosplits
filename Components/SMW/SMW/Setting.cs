using System.Collections.Generic;

namespace SMW {
    internal class Setting {
        
        string description;
        string tooltip;
        bool on;
        List<Setting> kids;

        public Setting(string description, string tooltip = null, bool on = true, List<Setting> kids = null) {
            this.description = description;
            this.tooltip = tooltip;
            this.on = on;
            this.kids = kids;
        }
    }
}