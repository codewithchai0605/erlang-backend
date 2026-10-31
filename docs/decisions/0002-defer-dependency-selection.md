# 0002 - Defer dependency version selection to Milestone 1

Status: accepted

Context: the Milestone 0 sandbox had no network access and no Erlang/Flutter toolchain, so Cowboy, epgsql, gpb, password-hashing, migration and Flutter package versions could not be verified.
Decision: no versions are pinned yet. They are chosen and locked (rebar.lock, pubspec.lock) in Milestones 1 and 2 after checking compatibility with the installed OTP and Flutter.
Consequences: Milestones 0-4 are written without having been compiled; see docs/operations.md for the first-compile checklist.
