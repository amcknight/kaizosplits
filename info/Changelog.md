## Changelog


### v0.9.0
- Split recorder functionality into WIP Synth.asl
- Added CP entrance change splitting
- Create start and reset settings
- Added start split for when luigi's lives get set
- Split out an SNES emu dll that could work with other games and splitters
- Moved Settings definition into Settings class because fundamentally tied to update conditions

### v0.2
- Has basic run watching for some events but doesn't do anything with them
- Detecting Deaths and Spawns and Events
- Writing out initial runs and routes
- Functionality for Undo and Skip exit but are unused
- Found a better Exit detector using exit modes
- Skip instead of split if final split call is X ms later than the last one
- Auto-undo if die after finishing

### v0.0
- Fixed an issue in the original splitter by NecroSky90
- Got midway splitting working
- Created a generic orb exit check
- A setting for splitting on overworld changes, for subsplitting
- Split orbExits into actual orb exits vs unknown exits
- Made roomCounter reliable
- Found a post-level exit counter
- Found a level start counter
- Got good default overworld and intro splitting
