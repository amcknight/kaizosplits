## Kaizosplits

A Super Mario World romhack autosplitter heavily updated from [NecroSky90 on SMWCentral](https://www.smwcentral.net/?p=section&a=details&id=28606)'s version from a 2021.

Their's a v1 decent autosplitter that's supposed to work as well as possible by default but it's a all kind of a mess right now. This is the file you probably want to use. If you just want level splits, this is the one.

However, there's also an ambitious v2 split manager that will robustly handle fine-grained and custom autosplits and that will create initial split files by watching your runs. By having a mechanism to make sure your splits and autosplitter are exactly in sync, we can do some cool stuff. If you skip a checkpoint or die and go back before a split, the autosplitter can see this and skip a split or undo a split accordingly. v2 is a Work in Progress and will likely be forked into it's own project!

### Development Setup Log

This is how I got it working last time. Next time re-setting up, improve these instructions.

1) Install Visual Studio 2022 (can try latest but I used this one)

2) Build LiveSplit for its components
- `git clone --recursive https://github.com/LiveSplit/LiveSplit.git`
- Open the solution in VS2022 as a Solution
- CTRL+Shift+B to build it
- Don't move on until this builds properly
-- needs .net 4.6.1 and netstandard 2.0 (I think)
-- This is for getting a reference to LiveSplit.Core and possibly other modules. Could possibly get these built alone but having the whole project allows for some stepthrough debugging in worst case scenarios.

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

- Find your LiveSplit folder and copy or move the two DLLs into the `Components` folder inside
- Put the `Kaizo.asl` somewhere. I keep it where I keep my splits files but it can be anywhere.
- Open LiveSplit and `Edit Layout...` press `+` and then choose `Control > Scriptable Auto Splitter`
- Now click `Layout Settings` and the `Scripable Auto Splitter` tab
- Click `Browse` and go find your `Kaizo.asl` file

If all went well you should see a bunch of settings, with some checked. You're set!

### Adding new Emulators

- Install Cheat Engine and Debug View
- Change init to write out "modSize" `modules.First().ModuleMemorySize`
- Run DbgView, livesplit, and the new emulator
- DbgView should show the modSize and errors
- Add a line to `memoryOffsets` like `{ modSize you found, ??? } // emulator name`
- Run a hack with a value you know how to change. I use roomNum `t.Monitor(w.roomNum, w);` to the split function.
- Use Cheat Engine to isolate the roomNum memory address
- Close the emulator and do it again so you have two memory addresses
- Do a pointer scan, comparing the two addresses
- Double click the first Base Address to add it as variable
- Back in Cheat ENgine main screen, double click the new variable's address
- Copy the `"emu.exe"+00blah` section into comment and the address after the arrow into the value for the modSize key
- Save and should see the room number changing in DbgView without errors

### Custom Splits (Advanced)

If you end up wanting more fine-grained splits, such as removing some checkpoint splits, custom credits split, or room splits for only one level, you're in the right place.

Open your `Kaizo.asl` which is defines the whole autosplitter and take a look at the `split {}` section for the switch cases.

To add custom splits to a run, add a case for your run name which you can see in Livesplit or by using the DebugViewer debugging program.

Add credits split: `s.credits = CONDITION;`
Add splits: `s.other = CONDITION || CONDITION || ... || CONDITION;`
Suppress splits: `s.block = CONDITION || CONDITION || ... || CONDITION;`

These CONDITIONS are usually:
`w.SHIFT_CONDITION`
`(w.ONGOING_CONDITION && w.SHIFT_CONDITION)`
The list of `ONGOING_CONDITION`s and `SHIFT_CONDITION`s are in [Watchers.cs](Components/SMW/SMW/Watchers.cs#184) relative to this README file. You'll need to find specific room numbers or other values to fill in these conditions. Check the Debugging section for how.

This is generic C# code, but if you follow the examples that exist there already, you shouldn't need to learn any programming.

Note that these custom splits depend heavily on your settings config, but currently you can't have different cases per settings config, so you'll probably need to change your custom splits if you change your settings config.
    
### Debugging

[DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) is a program for debugging Windows programs generally. All errors from all your programs go there, but LiveSplit and the LiveSplit autosplitter plugin, and kaizosplits will have useful messages there if you're stuck.

If you're trying to add custom splits but need level numbers or room numbers or whatever, then go to the `update{}` section of `Kaizo.asl` and find the `MONITOR HERE` comment. Below it, add a line for each memory item you want to monitor.

```
t.Monitor(w.A_MEMORY_WATCHER_NAME, w);
t.Monitor(w.ANOTHER_MEMORY_WATCHER_NAME, w);
```

The list of `MEMORY_WATCHER_NAME`s are in [Watchers.cs](Components/SMW/SMW/Watchers.cs#43) and an example would be `roomNum`.