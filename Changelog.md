## Changelog

### v2
- Has basic run watching for some events but doesn't do anything with them
- Detecting Deaths and Spawns and Events
- Writing out initial runs and routes
- Functionality for Undo and Skip exit but are unused
- Found a better Exit detector using exit modes
- Skip instead of split if final split call is 50ms later than the last one
- Auto-undo if die after finishing

### v1
- Got basically everything working somewhat ok
- Cleared out custom game splits

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
