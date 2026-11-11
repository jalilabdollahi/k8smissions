## Reading `kubectl logs` without `-c` and concluding the pod is healthy

Without `-c`, kubectl shows the default container (or the first one), which is the sidecar here. Always name the container that is restarting, or ask for all of them.

## Reading only the current log of the crashing container

The app has just restarted, so its current log holds only the first startup line. The error is in `--previous`.

## Deleting the sidecar to make the crash stop

The restarts stop, but the metrics-proxy exists for a reason and the validator requires it to keep serving its own port. Move one of the two processes instead of removing one.
