**What was broken.** `video-transcoder` replaced pods in the middle of a job. Its container started with `sh -c "...; python worker.py; ..."`, and its grace period was 15 seconds while clips take up to 25.

**The evidence.** Deleting a pod on purpose showed the symptom: it stayed in Terminating for exactly 15 seconds, and its log never printed the worker's `SIGTERM: draining` line. `/proc/1/cmdline` showed `sh`, not `python`. The collector listed clips as started with no matching finish and no clean-shutdown report from the dead pods.

**Why Kubernetes behaved this way.** The kubelet signals PID 1 of the container with SIGTERM and, after the grace period, SIGKILL. PID 1 is special on Linux: a process there gets no default signal actions, so a shell that did not install a handler just ignores SIGTERM. The worker was a child of the shell and never knew it should drain. Raising only the grace period would have made pods wait longer, then die the same way; fixing only the signal would still lose any clip needing more than 15 seconds.

**The fix.** Make the worker PID 1 (exec form, or `exec` in the wrapper) and set the grace period above the longest job.

**In production.** The grace period should cover the longest job plus the time for the endpoint removal to reach clients (see the preStop level in module 7). For work that can take minutes, prefer a queue with acknowledgements so a killed worker's job is redelivered, and treat the grace period as an optimisation, not the only protection. Tools like `tini` or `dumb-init` as PID 1 forward signals for programs that do not handle them.

**Worth remembering.**
- `kubectl exec <pod> -- cat /proc/1/cmdline | tr '\0' ' '`
- `kubectl explain pod.spec.terminationGracePeriodSeconds`
- `kubectl delete pod <pod> --grace-period=<n>`
