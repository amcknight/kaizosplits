## Kaizosplits

A Super Mario World romhack autosplitter heavily updated from [NecroSky90 on SMWCentral](https://www.smwcentral.net/?p=section&a=details&id=28606)'s version from a 2021.

Their's a v1 decent autosplitter that's supposed to work as well as possible by default but it's a all kind of a mess right now. This is the file you probably want to use. If you just want level splits, this is the one.

However, there's also an ambitious v2 split manager that will robustly handle fine-grained and custom autosplits and that will create initial split files by watching your runs. By having a mechanism to make sure your splits and autosplitter are exactly in sync, we can do some cool stuff. If you skip a checkpoint or die and go back before a split, the autosplitter can see this and skip a split or undo a split accordingly. v2 is a Work in Progress and will likely be forked into it's own project!

### Development Setup Log

This is how I got it working last time. Next time re-setting up, improve these instructions.

1) Install Visual Studio 2022 (can try latest but I used this one)

2) Build LiveSplit for its components
```
git clone https://github.com/LiveSplit/LiveSplit.git
cd LiveSplit
git submodule update --init --recursive
```
Open the solution in VS2022 and build it
- needs .net 4.6.1
- needs netstandard2.0 (I think)
- Try to do this through Visual Studio, but if can't, download carefully... sorry, improve these instructions next time.
- This is for LiveSplit.Core. Could possibly get it built alone.

3) Build kaizosplits SMW dll
```
git clone https://github.com/amcknight/kaizosplits.git
```
Open the solution in VS2022 and build it

4) Reinstall SMW dll every time it builds:
- Exit LiveSplit
- Copy "kaizosplits\Components\SMW\SMW\bin\Debug\netstandard2.0\SMW.dll" to  "LiveSplit/Components/" 
- I simplify this by creating a symlink by running PowerShell in Administrator mode and using `cmd /c mklink 'C:\PATH\TO\LIVESPLIT\Components\SMW.dll' 'C:\PATH\TO\KAIZOSPLITS\Components\SMW\SMW\bin\Debug\netstandard2.0\SMW.dll'`
- Don't need to recopy it if only changed the .asl file
- Start LiveSplit

5) DebugView is useful for seeing print statements

### Installation

You're gonna need to build it like the above, for now, sorry.

### Adding new Emulators

- Install Cheat Engine and Debug View
- Change init to write out "modSize" `modules.First().ModuleMemorySize`
- Run DbgView, livesplit, and the new emulator
- DbgView should show the modSize and errors
- Add a line to `memoryOffsets` like `{ modSize you found, ??? } // emulator name`
- Run a hack with a value you know how to change. I use roomNum `r.Monitor(w.roomNum, w);` to the split function.
- Use Cheat Engine to isolate the roomNum memory address
- Close the emulator and do it again so you have two memory addresses
- Do a pointer scan, comparing the two addresses
- Double click the first Base Address to add it as variable
- Back in Cheat ENgine main screen, double click the new variable's address
- Copy the `"emu.exe"+00blah` section into comment and the address after the arrow into the value for the modSize key
- Save and should see the room number changing in DbgView without errors
