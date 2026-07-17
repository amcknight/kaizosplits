# kaizosplits — project instructions

- Never `git add`/`git commit` here; leave changes in the working tree for
  Andrew to review.
- SNES.dll comes from the sibling repo `../snes_offsets` and owns everything
  below the WRAM seam: attach, liveness, ROM identity, raw reads. kaizosplits
  owns watchers, split semantics, timer policy, and LiveSplit deployment.
- Never edit sibling repos from here. Upstream friction becomes a written
  request handed to Andrew, or a `TODO(snes_offsets):` marker.
- Any change to the consumed SNES.dll or its contract passes
  `docs/merge-gate.md` before merging. The .asl call surface is pinned by
  `Components/SMW/SMW.Tests/ContractTests.cs` — edit an .asl call site and
  that file together.
- Kaizo.asl is the only .asl. The run-recording experiment survives as
  SMW.Recorder (contract-pinned); regenerate a shell from Kaizo.asl if
  revived.
- Preserve behavior exactly when refactoring Kaizo.asl and the Settings/
  Watchers split path; ordering is often load-bearing.
- SNES.dll is deliberately consumed unpinned (sibling ProjectReference) while
  both repos are ours; when an outside consumer appears, pick one pinning
  mechanism.
