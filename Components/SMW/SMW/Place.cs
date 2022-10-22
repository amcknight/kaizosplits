public class Place {
    private readonly ushort submap;
    private readonly ushort level;
    private readonly ushort room;
    private readonly ushort x;
    private readonly ushort y;
    public Place(ushort submap, ushort level, ushort room, ushort x, ushort y) {
        this.submap = submap;
        this.level = level;
        this.room = room;
        this.x = x;
        this.y = y;
    }

    public override string ToString() {
        return "Map " + submap + ", Level " + level + ", Room " + room + ", Pos (" + x + ", " + y + ")";
    }
}
