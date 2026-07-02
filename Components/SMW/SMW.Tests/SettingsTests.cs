using System.Collections.Generic;
using System.Linq;
using Xunit;

namespace SMW.Tests {
    public class SettingsTests {

        private static Settings NewInited(long maxLag = 100, long minStart = 1000, long minCooldown = 500) {
            var s = new Settings();
            s.Init(maxLag, minStart, minCooldown);
            return s;
        }

        [Fact]
        public void Init_StoresTimingValues() {
            var s = NewInited(maxLag: 42, minStart: 9999, minCooldown: 7);
            Assert.Equal(42, s.maxLag);
            Assert.Equal(9999, s.minStartDuration);
            Assert.Equal(7, s.minSplitCooldown);
        }

        [Fact]
        public void Init_DefaultsLastSplitTimeToSentinel() {
            var s = NewInited();
            Assert.Equal(-1, s.lastSplitTime);
        }

        [Fact]
        public void Keys_ContainsAllExpectedLeafSettings() {
            var s = NewInited();
            var expected = new[] {
                "playersSelect", "livesSet",
                "playersUnselect", "livesUnset", "gameChanged",
                "exits", "introExit", "worlds",
                "midways", "cpEntrances",
                "starts",
                "goals", "orbs", "bosses", "keyholes", "palaces",
                "rooms",
                "skipOnLag", "splitCooldown",
            };
            Assert.Equal(expected.Length, s.keys.Count);
            foreach (var k in expected) {
                Assert.Contains(k, s.keys);
            }
        }

        [Fact]
        public void Entries_ContainsAllLeafKeysPlusGroupSyntheticKeys() {
            var s = NewInited();
            // 19 leaves + 5 groups (Start/Reset/Split/Checkpoint/Finish) = 24 entries
            Assert.Equal(19, s.keys.Count);
            Assert.Equal(s.keys.Count + 5, s.entries.Count);
            foreach (var k in s.keys) {
                Assert.Contains(k, s.entries.Keys);
            }
        }

        [Fact]
        public void Entries_TopLevelLeafSettingsHaveNullParent() {
            var s = NewInited();
            Assert.Null(s.entries["skipOnLag"].Item4);
            Assert.Null(s.entries["splitCooldown"].Item4);
        }

        [Fact]
        public void Entries_GroupedSettingsHaveNonNullParent() {
            var s = NewInited();
            var grouped = new[] {
                "playersSelect", "livesSet",
                "playersUnselect", "livesUnset", "gameChanged",
                "exits", "introExit", "worlds", "starts", "rooms",
                "midways", "cpEntrances",
                "goals", "orbs", "bosses", "keyholes", "palaces",
            };
            foreach (var k in grouped) {
                Assert.False(string.IsNullOrEmpty(s.entries[k].Item4),
                    $"Expected '{k}' to have a non-null parent group key");
            }
        }

        [Fact]
        public void Entries_SiblingsShareSameParentKey() {
            var s = NewInited();
            // Anything in the Start when group
            Assert.Equal(s.entries["playersSelect"].Item4, s.entries["livesSet"].Item4);
            // Anything in the Reset when group
            Assert.Equal(s.entries["playersUnselect"].Item4, s.entries["livesUnset"].Item4);
            Assert.Equal(s.entries["playersUnselect"].Item4, s.entries["gameChanged"].Item4);
            // Checkpoint group leaves
            Assert.Equal(s.entries["midways"].Item4, s.entries["cpEntrances"].Item4);
            // Finish group leaves
            Assert.Equal(s.entries["goals"].Item4, s.entries["orbs"].Item4);
            Assert.Equal(s.entries["goals"].Item4, s.entries["palaces"].Item4);
        }

        [Fact]
        public void Entries_NestedGroupsDistinctParentsFromOuterGroup() {
            var s = NewInited();
            // exits is directly in the Split when group
            // midways is inside Checkpoint which is inside Split when
            var splitWhenLeafParent = s.entries["exits"].Item4;
            var checkpointLeafParent = s.entries["midways"].Item4;
            var finishLeafParent = s.entries["goals"].Item4;
            Assert.NotEqual(splitWhenLeafParent, checkpointLeafParent);
            Assert.NotEqual(splitWhenLeafParent, finishLeafParent);
            Assert.NotEqual(checkpointLeafParent, finishLeafParent);
        }

        [Fact]
        public void Entries_DisplayNamesAndDefaultsMatch() {
            var s = NewInited();
            // On-by-default leaf
            Assert.True(s.entries["exits"].Item1);
            Assert.Equal("Level Exit", s.entries["exits"].Item2);
            // Off-by-default leaf (worlds explicit on:false)
            Assert.False(s.entries["worlds"].Item1);
            Assert.Equal("Overworld Change", s.entries["worlds"].Item2);
            // Off-by-default leaf inside Finish group, which itself is off
            Assert.True(s.entries["goals"].Item1);
        }

        [Fact]
        public void GroupSyntheticKeys_AreNotInLeafKeysList() {
            var s = NewInited();
            // Any entry key whose value's parent equals it would be a synthetic group key
            var syntheticKeys = s.entries
                .Where(kv => s.entries.Values.Any(v => v.Item4 == kv.Key))
                .Select(kv => kv.Key)
                .ToList();
            foreach (var groupKey in syntheticKeys) {
                Assert.DoesNotContain(groupKey, s.keys);
            }
            // Sanity: we expect 5 group keys
            Assert.Equal(5, syntheticKeys.Count);
        }

        // --- SkipStatus / BlockedReasons --- pure boolean logic, doesn't need Watchers

        [Fact]
        public void SkipStatus_FalseWhenSkipOnLagOff() {
            var s = NewInited(maxLag: 100);
            s.skipOnLag = false;
            Assert.False(s.SkipStatus(99999));
        }

        [Fact]
        public void SkipStatus_TrueWhenLagOverThreshold() {
            var s = NewInited(maxLag: 100);
            s.skipOnLag = true;
            s.credits = false;
            Assert.True(s.SkipStatus(101));
        }

        [Fact]
        public void SkipStatus_FalseWhenLagAtOrBelowThreshold() {
            var s = NewInited(maxLag: 100);
            s.skipOnLag = true;
            s.credits = false;
            Assert.False(s.SkipStatus(100));
            Assert.False(s.SkipStatus(0));
        }

        [Fact]
        public void SkipStatus_FalseWhenCreditsSet() {
            var s = NewInited(maxLag: 100);
            s.skipOnLag = true;
            s.credits = true;
            Assert.False(s.SkipStatus(9999));
        }

        [Fact]
        public void SkipReasons_IncludesLagAndValue() {
            var s = NewInited(maxLag: 100);
            var reasons = s.SkipReasons(250);
            Assert.Contains("LAG", reasons);
            Assert.Contains("250", reasons);
        }

        [Fact]
        public void SkipReasons_EmptyWhenUnderThreshold() {
            var s = NewInited(maxLag: 100);
            Assert.Equal(string.Empty, s.SkipReasons(50));
        }
    }
}
