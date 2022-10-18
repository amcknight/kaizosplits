# Kaizosplits

A Super Mario World romhack autosplitter heavily updated from [NecroSky90 on SMWCentral](https://www.smwcentral.net/?p=section&a=details&id=28606)'s version from a couple years ago.

The current plan is to create a v1 decent autosplitter that works as well as possible by default and then an ambitious v2 split manager that can robustly handle fine-grained and custom autosplits and that will help you to create initial split files by watching your runs.

## Changelog

### v0
- Fixed an issue in the original splitter by NecroSky90 caused by snes9x-rr v1.6.1 (probably)
- Got checkpoint splitting working for first CP
- Created a generic orb exit check
- A setting for splitting on overworld changes, for subsplitting
- Split orbExits into actual orb exits vs unknown exits
- Made roomCounter reliable
- Found a post-level exit counter
- Found a level start counter
- Got good default overworld and intro splitting

### v1
- Got basically everything working somewhat ok

## Roadmap

### v1.1
- Fix examples where CPs aren't triggering after 1st (Multiple Midway Points Tool makes this complicated)
- Get a clear signal of whether a room change is a CP, if possible
- Use Exit and other signals to detect and not split until we know there isn't a post-orb or post-goal or bost-boss-defeat death
- Get better BossDefeat conditions which include non-level-ending bosses

### v2
- A separate kaizo plug-in
- Watches your run and uses it to create a file that represents the possible split-points of that run
- A split generator that uses run representations to generate aligned empty split files and a custom autosplitter for that split file
- Pull names of the levels from the ROM values
- Use overworld directions to add flags to the titles (e.g. secrets as "*" or turn back as "<--" or H vs P vs D vs R for cp Tape vs pipe vs door vs room splits)
- Auto-skip and auto-undo splits
- Make generic placement splits (every door, pipe, room, etc, even in same room#)
- Add idempotent split mechanisms
- Add more possibilities for custom fine-grained splits
- Add mergable split-points
- Specific split options that only apply to specific levels. (e.g. yoshi coins, grabbed key, etc, but only in the final castle, say)

### Beyond
- Use TAS tech and save states to create unit test runs to ensure changes are mostly backwards compatible
