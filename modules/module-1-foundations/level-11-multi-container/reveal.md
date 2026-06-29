## What went wrong

The sidecar container runs `tail -f /var/log/nonexistent.log`. The `logs` directory is an emptyDir volume — it starts empty. There is no `nonexistent.log` file, so `tail` exits immediately with an error. The container crashes, Kubernetes restarts it, and the cycle repeats.

## Fix

Change the sidecar command to something that actually writes to the log directory:

```yaml
command: ["sh", "-c", "while true; do echo 'Logging...' >> /var/log/app.log; sleep 5; done"]
```

## Why this matters

In a multi-container pod, all containers must stay running — if one crashes, Kubernetes restarts the entire pod. A sidecar that crashes takes down the healthy main container with it.