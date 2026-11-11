**What was broken.** Two bad upgrades stacked on top of each other. Revision 3 renamed the ConfigMap key that the application reads (`payload` became `body`), so every new pod exited at start-up and crash-looped. Revision 4 (built on revision 3's values with `--reuse-values`) added an impossible CPU request and timed out, so Helm marked it `failed`. The earlier `helm rollback webapp` with no revision went to "the previous revision", which is revision 3, the other broken one.

**The evidence.** `helm history` shows status per revision, but `superseded` only means a newer one replaced it. The pod logs said which config key was missing, and `helm get manifest --revision 2` and `--revision 3` side by side showed the renamed key.

**Why Helm behaved this way.** A rollback is a new revision (5) that re-applies an old revision's stored manifest and values. The target defaults to the revision before the current one, and Helm never judges whether that one was healthy. The history is kept so the audit trail survives.

**The fix.** `helm rollback webapp 2 --wait`. Uninstalling and reinstalling would also bring pods back but throws away the history you need for the post-mortem.

**In production.** Use `helm upgrade --atomic --timeout ...` so a failed upgrade rolls itself back, set `--history-max` to something sensible, and check the rollback target's manifest first: a rollback only restores what Helm rendered, not data or other objects the release does not own.

**Commands worth remembering.**
- `helm history RELEASE`
- `helm get manifest RELEASE --revision N` and `helm get values RELEASE --revision N`
- `helm rollback RELEASE N --wait`
