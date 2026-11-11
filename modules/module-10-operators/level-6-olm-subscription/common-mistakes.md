## Jumping straight to 1.4.0

It is the version you want, so it is the first thing most people try. The pod crash-loops: 1.4.0 checks at start that every Widget is on schema 2 and exits otherwise. Go back one step to 1.3.0, let it migrate, then come forward.

## Moving on before the migration has finished

Switching to 1.4.0 the moment 1.3.0 is Running can still crash-loop, because the migration takes a few reconcile passes. Check `status.schemaVersion` on all three Widgets first.

## Editing the bundle to skip the check

Removing the refusal from `bundle-1.4.0` makes it start, but the old Widgets then have no `spec.sizing` and no ConfigMap, and the validator looks for the migrated data, not just for a Running pod.
