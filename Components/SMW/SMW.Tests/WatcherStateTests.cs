using System;
using LiveSplit.ComponentUtil;
using Xunit;

namespace SMW.Tests {
    // Exercises the named-watcher derived booleans on Watchers
    // (GotOrb, InLevel, ToFanfare, Goal, CPEntrance, LevelFinish, etc.)
    // by populating a real Watchers list with named in-memory MemoryWatcher<T>s.
    // These conditions are the load-bearing surface that Settings/Kaizo.asl
    // consume to decide whether to split, so regressions here are critical.
    public class WatcherStateTests {

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

        // Build a Watchers populated with everything the conditions in this file touch.
        // Defaults: all zero. Override specific names via mutators after construction.
        private static Watchers BuildAllZero() {
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

        // --- Ongoing state ---

        [Theory]
        [InlineData(0, false)]
        [InlineData(2, false)]
        [InlineData(3, true)]
        [InlineData(4, false)]
        public void GotOrb_OnlyWhenIoIs3(byte io, bool expected) {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, io);
            Assert.Equal(expected, ws.GotOrb);
        }

        [Theory]
        [InlineData(3, false)]
        [InlineData(4, true)]
        [InlineData(7, false)]
        public void GotGoal_OnlyWhenIoIs4(byte io, bool expected) {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, io);
            Assert.Equal(expected, ws.GotGoal);
        }

        [Fact]
        public void GotKey_OnlyWhenIoIs7() {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, 7);
            Assert.True(ws.GotKey);
            SetByte(ws, "io", 0, 6);
            Assert.False(ws.GotKey);
        }

        [Fact]
        public void GotFadeout_OnlyWhenIoIs8() {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, 8);
            Assert.True(ws.GotFadeout);
        }

        [Fact]
        public void BossUndead_TrueWhenBossDefeatZero() {
            var ws = BuildAllZero();
            Assert.True(ws.BossUndead);
            SetByte(ws, "bossDefeat", 0, 1);
            Assert.False(ws.BossUndead);
        }

        [Fact]
        public void InLevel_OnlyWhenLevelStartOne() {
            var ws = BuildAllZero();
            Assert.False(ws.InLevel);
            SetByte(ws, "levelStart", 0, 1);
            Assert.True(ws.InLevel);
        }

        [Fact]
        public void Player_MarioVsLuigi() {
            var ws = BuildAllZero();
            Assert.True(ws.IsMario);
            Assert.False(ws.IsLuigi);
            SetByte(ws, "player", 0, 1);
            Assert.False(ws.IsMario);
            Assert.True(ws.IsLuigi);
        }

        // --- Changed state ---

        [Fact]
        public void ToFileSelect_FiresWhenLeavingFileSelectZero() {
            var ws = BuildAllZero();
            SetByte(ws, "fileSelect", 0, 1);
            Assert.True(ws.ToFileSelect);
        }

        [Fact]
        public void FromFileSelect_FiresWhenEnteringFileSelectZero() {
            var ws = BuildAllZero();
            SetByte(ws, "fileSelect", 1, 0);
            Assert.True(ws.FromFileSelect);
        }

        [Fact]
        public void GameMode_PerStateTransitions() {
            var ws = BuildAllZero();
            // GmFileSelect = ShiftTo(gameMode, 8)
            SetByte(ws, "gameMode", 0, 8);
            Assert.True(ws.GmFileSelect);
            SetByte(ws, "gameMode", 0, 20);
            Assert.True(ws.GmLevel);
            SetByte(ws, "gameMode", 23, 0);
            Assert.True(ws.GmGameOver);
            SetByte(ws, "gameMode", 14, 15);
            Assert.True(ws.GmFadeToLevel);
        }

        [Fact]
        public void IntroExit_FiresOnly233To0() {
            var ws = BuildAllZero();
            SetByte(ws, "weirdLevVal", 233, 0);
            Assert.True(ws.IntroExit);
            SetByte(ws, "weirdLevVal", 233, 1);
            Assert.False(ws.IntroExit);
        }

        [Fact]
        public void SwitchPalaces_StepToOne() {
            var ws = BuildAllZero();
            SetByte(ws, "yellowSwitch", 0, 1);
            Assert.True(ws.ToYellowSwitch);
            SetByte(ws, "greenSwitch", 0, 1);
            Assert.True(ws.ToGreenSwitch);
            SetByte(ws, "blueSwitch", 0, 1);
            Assert.True(ws.ToBlueSwitch);
            SetByte(ws, "redSwitch", 0, 1);
            Assert.True(ws.ToRedSwitch);
            // Jump (not step) should not trigger
            SetByte(ws, "yellowSwitch", 0, 2);
            Assert.False(ws.ToYellowSwitch);
        }

        [Fact]
        public void PlayerAnimation_PowerupAndDeath() {
            var ws = BuildAllZero();
            SetByte(ws, "playerAnimation", 0, 9);
            Assert.True(ws.DiedNow);
            SetByte(ws, "playerAnimation", 0, 1);
            Assert.True(ws.LosingPowerup);
            SetByte(ws, "playerAnimation", 0, 2);
            Assert.True(ws.GotMushroom);
            SetByte(ws, "playerAnimation", 0, 3);
            Assert.True(ws.GotFeather);
            SetByte(ws, "playerAnimation", 0, 4);
            Assert.True(ws.GotFlower);
        }

        [Fact]
        public void Doors_BothDirections() {
            var ws = BuildAllZero();
            SetByte(ws, "playerAnimation", 0, 13);
            Assert.True(ws.EnterDoor);
            Assert.False(ws.ExitDoor);
            SetByte(ws, "playerAnimation", 13, 0);
            Assert.True(ws.ExitDoor);
            Assert.False(ws.EnterDoor);
        }

        // --- Composite conditions ---

        [Fact]
        public void ToExit_RequiresShiftToNonZeroNon128() {
            var ws = BuildAllZero();
            SetByte(ws, "exitMode", 0, 1);
            Assert.True(ws.ToExit);
            SetByte(ws, "exitMode", 0, 128);
            Assert.False(ws.ToExit);     // explicit 128 exclusion
            SetByte(ws, "exitMode", 0, 0);
            Assert.False(ws.ToExit);     // no actual shift
            SetByte(ws, "exitMode", 1, 0);
            Assert.False(ws.ToExit);     // shifted but to 0
        }

        [Fact]
        public void EnteredPipe_RequiresShiftAndAnimation() {
            var ws = BuildAllZero();
            SetByte(ws, "pipe", 4, 1);            // shifted, curr<4
            SetByte(ws, "playerAnimation", 0, 5); // pipe animation
            Assert.True(ws.EnteredPipe);

            SetByte(ws, "playerAnimation", 0, 6); // other valid pipe animation
            Assert.True(ws.EnteredPipe);

            SetByte(ws, "playerAnimation", 0, 7); // wrong animation
            Assert.False(ws.EnteredPipe);

            SetByte(ws, "pipe", 4, 4);            // curr not < 4
            SetByte(ws, "playerAnimation", 0, 5);
            Assert.False(ws.EnteredPipe);

            SetByte(ws, "pipe", 1, 1);            // not shifted
            Assert.False(ws.EnteredPipe);
        }

        [Fact]
        public void Goal_RequiresFanfareStepBossUndeadAndNoOrb() {
            var ws = BuildAllZero();
            SetByte(ws, "fanfare", 0, 1);  // StepTo(fanfare, 1)
            Assert.True(ws.Goal);

            // Boss defeated -> not a Goal
            SetByte(ws, "bossDefeat", 0, 1);
            Assert.False(ws.Goal);

            // Reset, then orb present -> not a Goal
            ws = BuildAllZero();
            SetByte(ws, "fanfare", 0, 1);
            SetByte(ws, "io", 0, 3);
            Assert.False(ws.Goal);
        }

        [Fact]
        public void Boss_RequiresFanfareStepAndBossDefeat() {
            var ws = BuildAllZero();
            SetByte(ws, "fanfare", 0, 1);
            SetByte(ws, "bossDefeat", 0, 1);
            Assert.True(ws.Boss);

            // Without fanfare step, no Boss split
            SetByte(ws, "fanfare", 1, 1);
            Assert.False(ws.Boss);
        }

        [Fact]
        public void Orb_RequiresIoShiftToThreeAndBossUndead() {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, 3);
            Assert.True(ws.Orb);

            SetByte(ws, "bossDefeat", 0, 1);
            Assert.False(ws.Orb); // boss defeated suppresses Orb credit
        }

        [Fact]
        public void Midway_RequiresMidwayStepAndNoIoFlag() {
            var ws = BuildAllZero();
            SetByte(ws, "midway", 0, 1);
            Assert.True(ws.Midway);

            // Any IO flag suppresses Midway
            foreach (byte ioVal in new byte[] { 3, 4, 7, 8 }) {
                ws = BuildAllZero();
                SetByte(ws, "midway", 0, 1);
                SetByte(ws, "io", 0, ioVal);
                Assert.False(ws.Midway);
            }
        }

        [Fact]
        public void Palace_AnySwitchStep() {
            foreach (var sw in new[] { "yellowSwitch", "greenSwitch", "blueSwitch", "redSwitch" }) {
                var ws = BuildAllZero();
                SetByte(ws, sw, 0, 1);
                Assert.True(ws.Palace);
            }
        }

        [Fact]
        public void LevelFinish_FiresOnAnyFinishType() {
            // Goal
            var ws = BuildAllZero();
            SetByte(ws, "fanfare", 0, 1);
            Assert.True(ws.LevelFinish);

            // Orb
            ws = BuildAllZero();
            SetByte(ws, "io", 0, 3);
            Assert.True(ws.LevelFinish);

            // Key
            ws = BuildAllZero();
            SetByte(ws, "io", 0, 7);
            Assert.True(ws.LevelFinish);

            // Palace
            ws = BuildAllZero();
            SetByte(ws, "yellowSwitch", 0, 1);
            Assert.True(ws.LevelFinish);

            // Boss
            ws = BuildAllZero();
            SetByte(ws, "fanfare", 0, 1);
            SetByte(ws, "bossDefeat", 0, 1);
            Assert.True(ws.LevelFinish);

            // Nothing
            ws = BuildAllZero();
            Assert.False(ws.LevelFinish);
        }

        [Fact]
        public void CPEntrance_RequiresInLevelAndShiftAndNotFirstRoomAndNoIoFlag() {
            var ws = BuildAllZero();
            SetByte(ws, "levelStart", 0, 1);     // InLevel
            SetByte(ws, "cpEntrance", 0, 5);     // shifted, not to firstRoom (firstRoom default 0)
            // firstRoom default is 0, ShiftTo(cpEntrance, 0) would require curr==0, but curr==5
            // BUT cpEntrance shifted 0->5, so !ShiftTo(cp, 0) is true
            // Wait: firstRoom=0, ShiftTo(cp, 0) checks Prev!=0 && Curr==0 => false here
            // so !ShiftTo(cp, firstRoom) is true. Good.
            Assert.True(ws.CPEntrance);

            // Suppressed when not in level
            SetByte(ws, "levelStart", 0, 0);
            Assert.False(ws.CPEntrance);

            // Suppressed by io flag
            ws = BuildAllZero();
            SetByte(ws, "levelStart", 0, 1);
            SetByte(ws, "cpEntrance", 0, 5);
            SetByte(ws, "io", 0, 3);
            Assert.False(ws.CPEntrance);
        }

        // --- UpdateState() side effects ---

        [Fact]
        public void UpdateState_SetsDiedOnDeath() {
            var ws = BuildAllZero();
            SetByte(ws, "playerAnimation", 0, 9); // DiedNow
            ws.UpdateState();
            Assert.True(ws.died);
        }

        [Fact]
        public void UpdateState_DiedPersistsUntilSpawn() {
            var ws = BuildAllZero();
            SetByte(ws, "playerAnimation", 0, 9);
            ws.UpdateState();
            Assert.True(ws.died);

            // Time passes, no death this tick
            SetByte(ws, "playerAnimation", 9, 9);
            ws.UpdateState();
            Assert.True(ws.died);

            // Spawn = GmPrepareLevel && died -> ShiftTo(gameMode, 18) with died true
            SetByte(ws, "gameMode", 0, 18);
            ws.UpdateState();
            Assert.False(ws.died);
        }

        [Fact]
        public void UpdateState_GameOveredPersistsAndClearsOnOverworldFadeIn() {
            var ws = BuildAllZero();
            SetByte(ws, "gameMode", 23, 0); // GmGameOver = ShiftFrom(gameMode, 23)
            ws.UpdateState();
            Assert.True(ws.gameOvered);

            SetByte(ws, "gameMode", 0, 13); // GmOverworldFadeIn = ShiftTo(gameMode, 13)
            ws.UpdateState();
            Assert.False(ws.gameOvered);
        }

        [Fact]
        public void UpdateState_RoomStepTrueExceptOnDeathRoomReset() {
            var ws = BuildAllZero();
            SetByte(ws, "roomCounter", 4, 5); // Stepped
            ws.UpdateState();
            Assert.True(ws.roomStep);

            // After death, roomCounter resetting to 1 is suppressed
            ws = BuildAllZero();
            SetByte(ws, "playerAnimation", 0, 9); // sets died true
            ws.UpdateState();
            SetByte(ws, "playerAnimation", 9, 9); // hold animation so it's not toggled
            SetByte(ws, "roomCounter", 0, 1); // step from 0 -> 1
            ws.UpdateState();
            Assert.False(ws.roomStep);
        }

        [Fact]
        public void UpdateState_PrevIoTracksLastNonZero() {
            var ws = BuildAllZero();
            SetByte(ws, "io", 0, 3);
            ws.UpdateState();
            Assert.Equal(3u, ws.prevIO);

            // io drops to 0 (P-switch / star scenario) — prevIO should stick
            SetByte(ws, "io", 3, 0);
            ws.UpdateState();
            Assert.Equal(3u, ws.prevIO);

            SetByte(ws, "io", 0, 4);
            ws.UpdateState();
            Assert.Equal(4u, ws.prevIO);
        }

        [Fact]
        public void UpdateState_FirstRoomCapturedWhenLevelChanges() {
            var ws = BuildAllZero();
            SetByte(ws, "levelNum", 0, 5);
            SetByte(ws, "roomNum", 0, 42);
            ws.UpdateState();
            Assert.Equal(42u, ws.firstRoom);
        }
    }
}
