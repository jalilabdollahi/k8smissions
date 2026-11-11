**Lengthening the existing `exec: sleep` hook or raising `terminationGracePeriodSeconds`.** The command cannot run, because the image has no `sleep` binary, so a longer value changes nothing. Look for the `FailedPreStopHook` event instead of guessing at numbers.

**Setting `maxUnavailable: 0`.** It lowers how many pods terminate at once, which can hide the problem on a quiet test, but each terminating pod still gets traffic after SIGTERM. The check measures failed requests across a full restart, and the race remains.

**Swapping the image for one that has a shell.** It makes `exec sleep` work, but it changes the workload for no reason and the objective is not about the image. The native `sleep` action needs nothing in the container.
