# kaizosplits — project instructions

## No git add / commit

Do not `git add` or `git commit` in this repo. Leave all changes in the
working tree and hand them back to Andrew for inspection.

## SNES.dll is ours — but hands off from here

SNES.dll's source of truth is the sibling repo `../snes_offsets`. Agents
working in kaizosplits must NOT edit that repo — there may be work in
progress there, and cross-repo edits bypass its process. We are its most
valued customer, and customers ask: when work here reveals friction below
the WRAM seam — attach, liveness, ROM identity, raw reads — write it up as
a concrete request for Andrew to hand over (the "Open requests" section of
`docs/snes-dll-consumer-notes.md`, or brainstorm a short task with him),
and/or leave a `TODO(snes_offsets):` marker here. Don't silently absorb
workarounds on this side either.

Boundary: **SNES.dll owns** "where is this game's WRAM right now, across any
emulator/core/version — reliable bytes and liveness/identity signals."
**kaizosplits owns** watcher construction, split semantics, timer policy, and
LiveSplit deployment.

## SNES.dll changes: merge gate

Any change that bumps the consumed SNES.dll (or this repo's contract with it)
goes through `docs/merge-gate.md` before merging to main. The .asl reflection
contract is pinned by `Components/SMW/SMW.Tests/ContractTests.cs` — edit an
.asl call site and that file together.

## Synth.asl is peripheral (for now)

Kaizo.asl is the main show. Synth.asl is an experiment riding along — keep it
in sync when a change is cheap to mirror (e.g. the shared DLL-load block), but
don't let it drive design decisions or block Kaizo.asl work.

## Delicate split logic

Preserve behavior exactly when refactoring `Kaizo.asl` and the Settings/
Watchers split path; suspicious ordering is often load-bearing.

## Version pinning: deliberately deferred

kaizosplits consumes SNES.dll via sibling-checkout ProjectReference (fluid,
unpinned) while both repos are ours and userless. Revisit when a consumer
outside these two repos appears, or the repos need to move independently —
then pick ONE mechanism (likely a pinned built artifact), not layered safety.
(Decision record: docs/superpowers/specs/2026-07-14-snes-dll-trust-and-adoption-design.md §6.)
