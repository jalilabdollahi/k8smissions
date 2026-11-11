**Replacing the PVC or switching the run to `volumeClaimTemplate`.** That would isolate the runs, but the platform creates the runs and binds `build-scratch` by name, and the objective keeps that claim. The change belongs in the Pipeline.

**Using a subPath on only one Task.** If `build` writes to `<run>/shop.tar` and `verify` still reads the claim root, `verify` finds no file or a stale one. Both mappings need the same subPath.

**Serialising with a bigger `sleep` or a lock file.** More waiting only makes the window longer; a lock turns a correctness problem into a queue. Separate directories remove the sharing altogether.
