# Kaizosplits

A Super Mario World romhack autosplitter heavily updated from [NecroSky90 on SMWCentral](https://www.smwcentral.net/?p=section&a=details&id=28606)'s version from a couple years ago.

Their's a v1 decent autosplitter that works as well as possible by default. This is the simple file you probably want to use in many cases, especially if you don't care about splitting after every event that you "should" split on. If you just want level splits, this is the one.

However, there's also an ambitious v2 split manager that will robustly handles fine-grained and custom autosplits and that will create initial split files by watching your runs. By having a mechanism to make sure your splits and autosplitter are exactly in sync, we can do some cool stuff. If you skip a checkpoint or die and go back before a split, the autosplitter can see this and skip a split or undo a split accordingly. v2 is a Work in Progress!

## Roadmap

### v1.1
- Use the SMW class in v1
- Switch Exits from using different finish types to the simple exit mode
- Fix examples where CPs aren't triggering after 1st (Multiple Midway Points Tool makes this complicated)
- Get a clear signal of whether a room change is a CP, if possible

### v2
- Need a well defined run representation file that contains all info for representing autosplit preferences, splits, skips, undos, merges
- Monitor a run to create a file that represents that run
- Allow for easy mod of the representation to the user's preference
- A split generator that uses run representations to generate empty split files
- An autosplitter config that is based on your run representation
- Pull names of the levels from the ROM values
- Use overworld directions to add flags to the titles (e.g. secrets as "*" or turn back as "<--" or H vs P vs D vs R for cp Tape vs pipe vs door vs room splits)
- Auto-skip splits
- Make generic placement splits (every door, pipe, room, etc, even in same room#)
- Add idempotent split mechanisms
- Add more possibilities for custom fine-grained splits
- Add mergable split-points
- Specific split options that only apply to specific levels. (e.g. yoshi coins, grabbed key, etc, but only in the final castle, say)

### Beyond
- Use TAS tech and save states to create unit test runs to ensure changes are mostly backwards compatible
