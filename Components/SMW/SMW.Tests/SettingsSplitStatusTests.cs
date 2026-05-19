using System;
using System.Collections.Generic;
using LiveSplit.ComponentUtil;
using Xunit;

namespace SMW.Tests {
    // Pins Settings.SplitStatus() / SplitReasons() behavior. This is the core
    // decision surface Kaizo.asl consumes to decide whether to fire a split;
    // the user has flagged it as DELICATE, so these tests intentionally cover
    // the happy path of every enabled condition AND every blocker.
    public class SettingsSplitStatusTests {

        private static MemoryWatcher<byte> NamedByte(string name, byte old, byte curr) {
            var w = new MemoryWatcher<byte>(IntPtr.Zero) { Name = name };
            w.Current = curr;
            w.Old = old;
            return w;
        }

        private static MemoryWatcher<ushort> NamedUShort(string name, ushort old, ushort curr) {
            var w = new MemoryWatcher<ushort>(IntPtr.Zero) { Name = name };
            w.Current = curr;
            w.Old = old;
            return w;
        }

        private static MemoryWatcher<uint> NamedUInt(string name, uint old, uint curr) {
            var w = new MemoryWatcher<uint>(IntPtr.Zero) { Name = name };
            w.Current = curr;
            w.Old = old;
            return w;
        }

        // Same watcher list as WatcherStateTests.BuildAllZero, so the two
        // suites stay consistent. Defaults: all zero. Mutate per-test.
        private static Watchers BuildAllZeroWatchers() {
            var ws = new Watchers();
            var bytes = new[] {
                "fileSelect", "marioLives", "luigiLives", "submap", "fanfare",
                "victory", "bossDefeat", "io", "yellowSwitch", "greenSwitch",
                "blueSwitch", "redSwitch", "roomCounter", "peach", "midway",
                "cpEntrance", "pipe", "playerAnimation", "yoshiCoin", "levelStart",
                "weirdLevVal", "eventsTriggered", "overworldPortal", "levelNum",
                "roomNum", "exitMode", "player", "gameMode", "overworldTile",
                "buttonsHeld1", "buttonsPress1", "buttonsHeld2", "buttonsPress2",
                "levelMode", "inWater", "moonCounter",
            };
            foreach (var name in bytes) ws.Add(NamedByte(name, 0, 0));

            var shorts = new[] {
                "playerX", "playerY", "marioOverworldX", "marioOverworldY",
            };
            foreach (var name in shorts) ws.Add(NamedUShort(name, 0, 0));

            ws.Add(NamedUInt("layer1Pointer", 0, 0));
            return ws;
        }

        private static void SetByte(Watchers ws, string name, byte old, byte curr) {
            var w = (MemoryWatcher<byte>)ws[name];
            w.Old = old;
            w.Current = curr;
        }

        private static Dictionary<string, bool> AllFalseSettingsDict() {
            return new Dictionary<string, bool> {
                ["playersSelect"] = false,
                ["livesSet"] = false,
                ["playersUnselect"] = false,
                ["livesUnset"] = false,
                ["gameChanged"] = false,
                ["exits"] = false,
                ["introExit"] = false,
                ["worlds"] = false,
                ["midways"] = false,
                ["cpEntrances"] = false,
                ["starts"] = false,
                ["goals"] = false,
                ["orbs"] = false,
                ["keyholes"] = false,
                ["bosses"] = false,
                ["palaces"] = false,
                ["rooms"] = false,
                ["skipOnLag"] = false,
                ["splitCooldown"] = false,
            };
        }

        private static (Settings s, Watchers ws) Wire() {
            var s = new Settings();
            s.Init(maxLag: 100, minStartDuration: 1000, minSplitCooldown: 500);
            var ws = BuildAllZeroWatchers();
            return (s, ws);
        }

        // --- Quiet state: no triggers, no split ---

        [Fact]
        public void SplitStatus_AllOff_NoSplit() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            Assert.False(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_ConditionFiresButSettingOff_NoSplit() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            s.Update(AllFalseSettingsDict(), ws);
            Assert.False(s.SplitStatus());
        }

        // --- Per-condition happy paths ---

        [Fact]
        public void SplitStatus_Exits_TriggersOnLevelExit() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["exits"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_IntroExit_TriggersOnWeirdLevValShift() {
            var (s, ws) = Wire();
            SetByte(ws, "weirdLevVal", 233, 0);
            var dict = AllFalseSettingsDict();
            dict["introExit"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Midways_TriggersOnMidwayStep() {
            var (s, ws) = Wire();
            SetByte(ws, "midway", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["midways"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_CPEntrances_TriggersInLevelOnShiftAwayFromFirstRoom() {
            var (s, ws) = Wire();
            SetByte(ws, "levelStart", 0, 1);
            SetByte(ws, "cpEntrance", 0, 5);
            var dict = AllFalseSettingsDict();
            dict["cpEntrances"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Starts_TriggersOnLevelStartStep() {
            var (s, ws) = Wire();
            SetByte(ws, "levelStart", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["starts"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Goals_TriggersOnFanfareWithBossUndead() {
            var (s, ws) = Wire();
            SetByte(ws, "fanfare", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["goals"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Goals_SuppressedByBossDefeated() {
            var (s, ws) = Wire();
            SetByte(ws, "fanfare", 0, 1);
            SetByte(ws, "bossDefeat", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["goals"] = true;
            s.Update(dict, ws);
            Assert.False(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Bosses_TriggersOnFanfareWithBossDefeated() {
            var (s, ws) = Wire();
            SetByte(ws, "fanfare", 0, 1);
            SetByte(ws, "bossDefeat", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["bosses"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Orbs_TriggersOnIoShiftToThree() {
            var (s, ws) = Wire();
            SetByte(ws, "io", 0, 3);
            var dict = AllFalseSettingsDict();
            dict["orbs"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Keyholes_TriggersOnIoShiftToSeven() {
            var (s, ws) = Wire();
            SetByte(ws, "io", 0, 7);
            var dict = AllFalseSettingsDict();
            dict["keyholes"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Theory]
        [InlineData("yellowSwitch")]
        [InlineData("greenSwitch")]
        [InlineData("blueSwitch")]
        [InlineData("redSwitch")]
        public void SplitStatus_Palaces_TriggersOnAnySwitchStep(string switchName) {
            var (s, ws) = Wire();
            SetByte(ws, switchName, 0, 1);
            var dict = AllFalseSettingsDict();
            dict["palaces"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Rooms_TriggersOnRoomStepAfterUpdateState() {
            var (s, ws) = Wire();
            SetByte(ws, "roomCounter", 4, 5);
            ws.UpdateState();
            var dict = AllFalseSettingsDict();
            dict["rooms"] = true;
            s.Update(dict, ws);
            Assert.True(s.SplitStatus());
        }

        // --- Blockers ---

        [Fact]
        public void SplitStatus_Block_SuppressesEverything() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["exits"] = true;
            s.Update(dict, ws);
            s.block = true;
            Assert.False(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_GameOvered_SuppressesEverything() {
            var (s, ws) = Wire();
            SetByte(ws, "gameMode", 23, 0); // ShiftFrom(gameMode, 23) -> GmGameOver
            ws.UpdateState();
            SetByte(ws, "exitMode", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["exits"] = true;
            s.Update(dict, ws);
            Assert.True(ws.gameOvered);
            Assert.False(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Cooldown_SuppressesWhenSplitCooldownEnabled() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["exits"] = true;
            dict["splitCooldown"] = true;
            s.Update(dict, ws);
            s.lastSplitTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            Assert.False(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Cooldown_IgnoredWhenSplitCooldownDisabled() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            var dict = AllFalseSettingsDict();
            dict["exits"] = true;
            // splitCooldown stays false
            s.Update(dict, ws);
            s.lastSplitTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            Assert.True(s.SplitStatus());
        }

        // --- Credits / other escape hatches ---

        [Fact]
        public void SplitStatus_Credits_AloneTriggersSplit() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            s.credits = true;
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Other_AloneTriggersSplit() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            s.other = true;
            Assert.True(s.SplitStatus());
        }

        [Fact]
        public void SplitStatus_Block_BeatsCredits() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            s.credits = true;
            s.block = true;
            Assert.False(s.SplitStatus());
        }

        // --- SplitReasons surface ---

        [Fact]
        public void SplitReasons_EmptyWhenNothingTriggered() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            Assert.Equal(string.Empty, s.SplitReasons());
        }

        [Fact]
        public void SplitReasons_ListsTriggeredConditions() {
            var (s, ws) = Wire();
            SetByte(ws, "exitMode", 0, 1);
            SetByte(ws, "fanfare", 0, 1);
            s.Update(AllFalseSettingsDict(), ws);
            var reasons = s.SplitReasons();
            Assert.Contains("Exit", reasons);
            Assert.Contains("Goal", reasons);
        }

        [Fact]
        public void SplitReasons_OtherAndCreditsAppearAsReasons() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            s.other = true;
            s.credits = true;
            var reasons = s.SplitReasons();
            Assert.Contains("Other", reasons);
            Assert.Contains("Credits", reasons);
        }

        // --- BlockedReasons surface ---

        [Fact]
        public void BlockedReasons_EmptyWhenNoBlockers() {
            var (s, ws) = Wire();
            s.Update(AllFalseSettingsDict(), ws);
            Assert.Equal(string.Empty, s.BlockedReasons());
        }

        [Fact]
        public void BlockedReasons_ListsBlockGameOverAndCooldown() {
            var (s, ws) = Wire();
            SetByte(ws, "gameMode", 23, 0);
            ws.UpdateState();
            var dict = AllFalseSettingsDict();
            dict["splitCooldown"] = true;
            s.Update(dict, ws);
            s.block = true;
            s.lastSplitTime = DateTimeOffset.Now.ToUnixTimeMilliseconds();
            var reasons = s.BlockedReasons();
            Assert.Contains("Block", reasons);
            Assert.Contains("GameOver", reasons);
            Assert.Contains("Cooldown", reasons);
        }
    }
}
