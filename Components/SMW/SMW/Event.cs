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
}
