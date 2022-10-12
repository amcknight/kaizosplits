# smw_romhack_autosplitter

A Super Mario World romhack autosplitter originally taken from [NecroSky90 on SMWCentral](https://www.smwcentral.net/?p=section&a=details&id=28606) and updated to work with snes9x-1.6.1 or some other bug that occurred right around when I installed that Core!

## Changelog

### v0

- Fixed an issue in the original splitter by NecroSky90 caused by snes9x-rr v1.6.1 (probably)
- Cleaned up the individual level logic
- Got checkpoint splitting working
- Added fine-grained splits to Quickie World 2
- Create a generic orb exit checker
- A setting for splitting on overworld changes, for subsplitting
- Split orbExits into actual orb exits vs unknown exits

## Roadmap

### v1

- Default settings, without CPs, works for a large number of hacks by default
- Get a bunch of fine-grained splits working to test the robustness of the setup
- Fix examples where 2nd CPs aren't triggering
- Get a proper handle on BossDefeat conditions
- Find a new way to split other than only "orb" shifts (e.g. roomCounter)
- Test and clean up unknown exits
- Explain a methodology for adding fine-grained splits for any new hack that anyone can follow

### v1.X

- Auto-skippable splits. e.g. if someone skips a CP that they usually get, and then get to the next split, it should auto-skip before auto-splitting
- Idmnpotent splits. e.g. if we want to split on every room in a 5 room castle, but dying in room 3 brings you back to 1, then going through rooms 1 and 2 again won't split again

### Beyond

- An automatic split generator that watches your first playthroughs for possible split events
- Use TAS tech to create little unit test equivalents to ensure changes are mostly backwards compatible
