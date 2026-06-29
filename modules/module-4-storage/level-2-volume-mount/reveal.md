## What went wrong

The init container mounts the volume at `/data` and writes the config file there. The main container also mounts at `/data` — but looks for the file at `/app/config/app.conf`. The file exists at `/data/app.conf`, not where the app expects it.

## Fix

In manifest.yaml, change mountPath in both the init container and the main container:

```yaml
volumeMount:
  name: config-volume
  mountPath: /app/config
```

Apply this to both the initContainer and the main container's volumeMounts.

## Why this matters

A volume is just a directory that Kubernetes mounts at a path you choose. If the mount path does not match what the application expects, the files are invisible to the app — even though they are right there on the same volume.