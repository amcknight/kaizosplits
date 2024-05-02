# Kaizosplits

A Super Mario World romhack autosplitter with ambitions to make all SNES emulator autosplitting easier.

Should work for most normal splits out of the box but I like fine-grained splits so there's support for checkpoints, room transitions, and more. Unforutunately SMW romhacks can be weird, so you will need to add a couple custom splits (or disable a couple splits) if using fine-grained splits and there is some rudimentary custom split support for this.

## Installation

Go to Releases and download the zip. Instructions are in the README.

Customize splits in the Scriptable Autosplitter settings once it's installed.

## Debugging

You'll need to be able to debug to customize splits, add new emulators, or for development in general.

[DebugView](https://learn.microsoft.com/en-us/sysinternals/downloads/debugview) is a program for viewing debug statements. All errors from all your Windows programs go there, but LiveSplit and the LiveSplit autosplitter plugin, and kaizosplits will have useful messages there if you're stuck.

## Custom Splits

If you end up wanting more fine-grained splits, such as removing some checkpoint splits, custom credits split, or room splits for only one level, then this gets a bit complicated. Here's how:

Open your `Kaizo.asl` which is defines the whole autosplitter and take a look at the `split {}` section for the switch cases.

To add custom splits to a run, add a case for your run name which you can see in Livesplit or by using the DebugViewer debugging program.

Add a credits split, add regular splits, or suppress splits like this:
```
s.credits = CONDITION;
s.other = CONDITION || CONDITION || ... || CONDITION;
s.block = CONDITION || CONDITION || ... || CONDITION;
```

These `CONDITION`s are usually:

`w.SHIFT_CONDITION` or `(w.ONGOING_CONDITION && w.SHIFT_CONDITION)`

The list of `ONGOING_CONDITION`s and `SHIFT_CONDITION`s are in [Watchers.cs](Components/SMW/SMW/Watchers.cs#L183) relative to this README file. You'll need to find specific room numbers or other values to fill in these conditions. Check the Debugging above for how to monitor values.

This is generic C# code, but if you follow the examples that exist there already, you shouldn't need to learn any programming.

Note that these custom splits depend heavily on your settings config, but currently you can't have different cases per settings config, so you'll probably need to change your custom splits if you change your settings config.
    
If you're trying to add custom splits for, say, a specific level, you'll need to know the level number. Same for or room numbers or whatever.
- Go to the `update{}` section of `Kaizo.asl` and find the `MONITOR HERE` comment
- Below it, add a line for each memory item you want to monitor.

```
t.Monitor(w.A_MEMORY_WATCHER_NAME, w);
t.Monitor(w.ANOTHER_MEMORY_WATCHER_NAME, w);
```

The list of `MEMORY_WATCHER_NAME`s are in [Watchers.cs](Components/SMW/SMW/Watchers.cs#L42). Some examples are `levelNum`, `roomNum`, or `io`.
