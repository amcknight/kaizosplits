public class Event {

    public readonly string name;
    public readonly Place place;

    public Event(string name, Place place) {
        this.name = name;
        this.place = place;
    }

    public override string ToString() {
        return name + ": " + place.ToString();
    }

    public override bool Equals(object obj) {
        if ((obj == null) || !GetType().Equals(obj.GetType())) {
            return false;
        } else {
            Event e = (Event)obj;
            return name.Equals(e.name) && place.Equals(e.place);
        }
    }
}
