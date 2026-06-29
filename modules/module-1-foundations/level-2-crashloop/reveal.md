## What went wrong

`args: [/scripts/start.sh]` tells the container to execute a script that does not exist inside the image. The container exits with code 127 (command not found). Kubernetes restarts it, the same thing happens, and the loop continues.

## Fix

Remove `args` and add a valid `command` that keeps the container alive:

```yaml
command:
- /bin/sh
- -c
- sleep 3600
```

## Why this matters

If you only remove `args` without adding `command`, busybox has no default process to run — it exits with code 0 immediately, which also causes restarts. A container must have a long-running foreground process to stay alive.